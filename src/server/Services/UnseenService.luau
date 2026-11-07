--!strict
-- The Unseen (plan section 4). The server holds his position and enforces his rules, which never change:
--   1. never in a field: if his cell becomes filmed he stops existing there and comes back in shadow, out of reach;
--   2. your eyes don't count (the clients draw him; nothing here depends on who looks);
--   3. never on screen (the clients hide him in every camera view);
--   4. he travels by shadow: he only walks through cells that are neither solid nor filmed (Logic/Shadow);
--   5. he kills on contact, and only a player who has been off camera for the whole grace.
-- The director (Logic/Hunt) picks his mode and his target per phase, and gives the players a break after a kill or a
-- long chase. It sets the pressure, never the rules.
-- The floors (content/floors.csv) are separate islands of one grid: he walks on one floor at a time. When the guards
-- he wants are on another floor, he takes the stairs out of sight: after unseen_floor_delay he is gone from his floor
-- and comes back in shadow near their stairwell door, out of everyone's reach (rule 1 holds through it).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Logic = Shared:WaitForChild("Logic")
local Grid = require(Logic:WaitForChild("Grid"))
local Shadow = require(Logic:WaitForChild("Shadow"))
local Hunt = require(Logic:WaitForChild("Hunt"))
local Rng = require(Logic:WaitForChild("Rng"))

local WatchService = require(script.Parent:WaitForChild("WatchService"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))

local C = Config.C

local UnseenService = {}

-- NightService sets these (it owns deaths and the night)
UnseenService.onKill = nil :: ((player: Player) -> ())?
UnseenService.speedScale = 1 -- the night's difficulty and the number of guards (NightService)
UnseenService.isPlaying = nil :: ((player: Player) -> boolean)? -- on shift and not in a death

local g = WatchService.grid
local rng = Rng.new(os.time())

local present = false
local x, z = 0, 0
local yaw = 0
local goal: number? = nil
local path: { number }? = nil
local pathAt = 0 -- index of the next cell in path
local repathIn = 0
local relief = 0
local chase = 0
local lastTarget: number? = nil
local lastMode: Hunt.Mode? = nil
-- the far sighting (plan section 4, his signs: "On le voit de loin"): who he stares at, and until when
local stare: { player: Player, untilT: number }? = nil
local nextSighting = 0
local hushed: { [Player]: boolean } = {}
local offTime: { [Player]: number } = {}
local exposure: { [Player]: number } = {} -- the signal bar, 1 full (Hunt.exposure)
local marked: { [Player]: boolean } = {}
local sentExposure: { [Player]: number } = {}
local toFilmed: { [number]: number } = {}
local toFilmedVersion = -1
local floorWait = 0 -- seconds the guards he wants have been on another floor

local function minPlayerDistance(px: number, pz: number): number
	local best = math.huge
	for _, player in Players:GetPlayers() do
		local root = WatchService.rootOf(player)
		if root then
			best = math.min(best, math.sqrt((root.Position.X - px) ^ 2 + (root.Position.Z - pz) ^ 2))
		end
	end
	return best
end

local function free(i: number): boolean
	return Shadow.free(g, WatchService.filmed(), i)
end

-- back in shadow, near where he was but out of every player's reach (rule 1)
local function reappear(fromX: number, fromZ: number): boolean
	local from = Grid.at(g, fromX, fromZ) or 1
	local cell = Shadow.nearest(g, from, function(i)
		if not free(i) then
			return false
		end
		local cx, cz = Grid.center(g, i)
		return minPlayerDistance(cx, cz) >= C.unseen_return_min_distance
	end)
	if not cell then
		present = false
		return false
	end
	x, z = Grid.center(g, cell)
	present = true
	path, goal = nil, nil
	repathIn = 0
	return true
end

local function vanish()
	if present then
		-- the camcorders show a VHS trace at the edge of the frame where he was (plan section 4, his signs)
		Net.event():FireAllClients("Vanish", x, z)
	end
	present = false
	reappear(x, z)
end

local function unhush(except: Player?)
	for player in hushed do
		if player ~= except then
			hushed[player] = nil
			Net.event():FireClient(player, "Hush", false)
		end
	end
end

-- the cells of the island of shadow he stands on, sorted (so a seed replays the same)
local function islandCells(): { number }
	local mine = Grid.at(g, x, z)
	local cells = {}
	if mine then
		for i in Shadow.island(g, WatchService.filmed(), mine) do
			table.insert(cells, i)
		end
		table.sort(cells)
	end
	return cells
end

-- a random cell of his island that `accept` takes (a few tries), or nil
local function pickInIsland(accept: (number) -> boolean, tries: number): number?
	local cells = islandCells()
	if #cells == 0 then
		return nil
	end
	for _ = 1, tries do
		local i = rng.pick(cells)
		if accept(i) then
			return i
		end
	end
	return nil
end

-- far from every player: the best of a few random cells of his island
local function farthestCell(): number?
	local cells = islandCells()
	if #cells == 0 then
		return nil
	end
	local best, bestD = nil, -1
	for _ = 1, 24 do
		local i = rng.pick(cells)
		local cx, cz = Grid.center(g, i)
		local d = minPlayerDistance(cx, cz)
		if d > bestD then
			best, bestD = i, d
		end
	end
	return best
end

type Status = { player: Player, root: BasePart, filmed: boolean, cell: number? }

local trySighting: (list: { any }) -> ()

local function statuses(dt: number): { Status }
	local out = {}
	local filmed = WatchService.filmed()
	if toFilmedVersion ~= WatchService.version then
		toFilmed = Shadow.toFilmed(g, filmed)
		toFilmedVersion = WatchService.version
	end
	for _, player in Players:GetPlayers() do
		local root = WatchService.rootOf(player)
		local onShift = UnseenService.isPlaying == nil or UnseenService.isPlaying(player)
		if root and onShift then
			local isFilmed = WatchService.isFilmed(player)
			offTime[player] = if isFilmed then 0 else (offTime[player] or 0) + dt
			exposure[player], marked[player] = Hunt.exposure(
				exposure[player] or 1,
				marked[player] == true,
				isFilmed,
				PowerDirector.phase() or "LIVE",
				dt,
				C
			)
			table.insert(out, {
				player = player,
				root = root,
				filmed = isFilmed,
				cell = Grid.at(g, root.Position.X, root.Position.Z),
			})
		else
			offTime[player] = 0
			exposure[player] = 1
			marked[player] = nil
		end
	end
	return out
end

-- A shadow cell far ahead of a guard (within sighting_cone of where they face, sighting_near to sighting_far away), in
-- plain sight of them: he stops existing where he is and stands there, staring (plan section 4: "il se montre au bout
-- d'un couloir sombre, immobile, puis n'y est plus"). Any shadow cell will do, not only his island: a sighting is
-- the one time he shows up somewhere; rule 1 still holds, the cell is in no field.
function trySighting(list: { Status })
	local occluders = WatchService.level.occluders
	for _, s in rng.shuffle(list) do
		local p = s.root.Position
		local look = s.root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.1 then
			continue
		end
		flat = flat.Unit
		local found = {}
		for i = 1, Grid.count(g) do
			if free(i) then
				local cx, cz = Grid.center(g, i)
				local to = Vector3.new(cx - p.X, 0, cz - p.Z)
				local d = to.Magnitude
				if d >= C.sighting_near and d <= C.sighting_far then
					local angle = math.deg(math.acos(math.clamp(to.Unit:Dot(flat), -1, 1)))
					if
						angle <= C.sighting_cone
						and not Grid.segmentHits(
							occluders,
							p.X,
							p.Y + 1.5,
							p.Z,
							cx,
							C.floor_y + C.unseen_height * 0.7,
							cz
						)
					then
						table.insert(found, i)
					end
				end
			end
		end
		if #found > 0 then
			x, z = Grid.center(g, rng.pick(found))
			present = true
			path, goal = nil, nil
			yaw = math.atan2(-(p.X - x), -(p.Z - z))
			stare = { player = s.player, untilT = os.clock() + C.sighting_stare }
			return
		end
	end
end

-- The floor he should be on: his target's, or (no target) the floor with the most guards off camera; nil: stay.
local function wantedFloor(list: { Status }, target: Status?): string?
	if target then
		return (Config.floorAt(target.root.Position.X))
	end
	local count: { [string]: number } = {}
	local best, bestN = nil, 0
	for _, s in list do
		if not s.filmed then
			local f = Config.floorAt(s.root.Position.X)
			count[f] = (count[f] or 0) + 1
			if count[f] > bestN or (count[f] == bestN and best ~= nil and f < best) then
				best, bestN = f, count[f]
			end
		end
	end
	return best
end

-- he takes the stairs to `floor`: gone from here, back in shadow near its stairwell door (or not at all for now)
local function changeFloor(floor: string)
	for _, row in Config.Stairs do
		if row.floor == floor then
			local spot = Config.spotById[row.spot]
			present = false
			stare = nil
			goal, path = nil, nil
			reappear(spot.x, spot.z)
			return
		end
	end
end

local function walk(dt: number, speed: number, stopAt: number)
	if not path then
		return
	end
	local budget = speed * dt
	while budget > 0 and pathAt <= #path do
		local tx, tz = Grid.center(g, path[pathAt])
		local dx, dz = tx - x, tz - z
		local d = math.sqrt(dx * dx + dz * dz)
		if d < 1e-3 then
			pathAt += 1
			continue
		end
		local move = math.min(budget, d)
		x += dx / d * move
		z += dz / d * move
		yaw = math.atan2(-dx, -dz)
		budget -= move
		if stopAt > 0 and #path - pathAt + 1 <= stopAt then
			break
		end
	end
end

local function remaining(): number
	if not path then
		return math.huge
	end
	local total = 0
	local px, pz = x, z
	for k = pathAt, #path do
		local cx, cz = Grid.center(g, path[k])
		total += math.sqrt((cx - px) ^ 2 + (cz - pz) ^ 2)
		px, pz = cx, cz
	end
	return total
end

local function tick(dt: number)
	local phase = PowerDirector.phase()
	if not phase then
		if present then
			present = false
			unhush()
		end
		stare = nil
		nextSighting = os.clock() + C.sighting_first
		return
	end
	if not present then
		if not reappear(x, z) then
			return
		end
	end

	-- rule 1: a field touched him, he is gone from here
	local mine = Grid.at(g, x, z)
	if not mine or not free(mine) then
		vanish()
		if not present then
			return
		end
		mine = Grid.at(g, x, z)
	end

	relief = math.max(0, relief - dt)
	local list = statuses(dt)
	local anyMarked = false
	for _, s in list do
		if marked[s.player] and not s.filmed then
			anyMarked = true
		end
	end
	local mode = Hunt.mode(phase, relief, anyMarked)

	-- he stands still and looks at the guard, then he isn't there any more
	local st = stare
	if st then
		local root = WatchService.rootOf(st.player)
		if os.clock() < st.untilT and phase == "LIVE" and root then
			yaw = math.atan2(-(root.Position.X - x), -(root.Position.Z - z))
			return
		end
		stare = nil
		vanish()
		return
	end
	if mode == "prowl" and relief <= 0 and os.clock() >= nextSighting then
		nextSighting = os.clock() + rng.int(C.sighting_min, C.sighting_max)
		trySighting(list)
		if stare then
			return
		end
	end
	local candidates = {}
	local byId: { [number]: Status } = {}
	for _, s in list do
		byId[s.player.UserId] = s
		table.insert(candidates, {
			id = s.player.UserId,
			filmed = s.filmed,
			offTime = offTime[s.player] or 0,
			fieldSteps = if s.cell then toFilmed[s.cell] or 0 else 0,
			marked = marked[s.player] == true,
		})
	end
	local targetId = Hunt.target(candidates, mode, C.hunt_distance_weight)
	local target = if targetId then byId[targetId] else nil

	-- the director: a long chase earns the players a break
	if mode == "hunt" and target then
		chase += dt
		if chase >= C.unseen_chase_max then
			relief, chase = C.unseen_relief_seconds, 0
			mode, target = "retreat", nil
		end
	else
		chase = 0
	end
	if lastTarget ~= targetId then
		lastTarget = targetId
		unhush(target and target.player)
	end

	-- the guards he wants are on another floor: after a while he is on theirs
	local want = wantedFloor(list, target)
	if want and want ~= (Config.floorAt(x)) then
		floorWait += dt
		if floorWait >= C.unseen_floor_delay then
			floorWait = 0
			changeFloor(want)
			return
		end
	else
		floorWait = 0
	end
	if lastMode ~= mode then
		-- a new mode forgets the old goal (after a kill he must not keep walking to where the player was)
		lastMode = mode
		goal, path = nil, nil
		repathIn = 0
	end

	-- where he goes
	repathIn -= dt
	local reached = path == nil or pathAt > #(path :: { number })
	local stopAt = 0
	if target and target.cell then
		if repathIn <= 0 then
			local tcell = target.cell :: number
			if not free(tcell) then
				tcell = Shadow.nearest(g, tcell, free) or tcell
			end
			goal = tcell
		end
		if mode == "approach" then
			stopAt = math.ceil(C.unseen_hold_distance_flicker / g.cell)
		end
	elseif mode == "retreat" then
		if reached or repathIn <= 0 and goal == nil then
			goal = farthestCell()
		end
	else
		-- prowl: wander his blind spots, never closer than keep_distance to a player
		local tooClose = minPlayerDistance(x, z) < C.unseen_keep_distance_live
		if reached or tooClose and repathIn <= 0 then
			goal = if tooClose
				then farthestCell()
				else pickInIsland(function(i)
					local cx, cz = Grid.center(g, i)
					return minPlayerDistance(cx, cz) >= C.unseen_keep_distance_live
				end, 12)
		end
	end
	if repathIn <= 0 or reached then
		repathIn = C.unseen_repath
		path = if goal and mine then Shadow.path(g, WatchService.filmed(), mine, goal) else nil
		if not path and goal and mine and target then
			-- a field stands between them (rule 4): he waits at the edge of his shadow, as close to the guard as it goes
			local gx, gz = Grid.center(g, goal)
			local best, bestD = nil, math.huge
			for _, i in islandCells() do
				local cx, cz = Grid.center(g, i)
				local d = (cx - gx) ^ 2 + (cz - gz) ^ 2
				if d < bestD then
					best, bestD = i, d
				end
			end
			if best and best ~= mine then
				path = Shadow.path(g, WatchService.filmed(), mine, best)
			end
		end
		pathAt = 2
	end

	local speed = Hunt.speed(mode, C) * UnseenService.speedScale
	if mode == "prowl" and minPlayerDistance(x, z) < C.unseen_keep_distance_live and goal == nil then
		speed = 0
	end
	walk(dt, speed, stopAt)

	-- the hush: the target's sound dies before he is in reach (plan section 4, "Toujours une chance")
	if mode == "hunt" and target and not hushed[target.player] then
		if Hunt.shouldHush(remaining(), speed, C) then
			hushed[target.player] = true
			Net.event():FireClient(target.player, "Hush", true)
		end
	end

	-- rule 5: contact in a blind spot
	for _, s in list do
		local d = math.sqrt((s.root.Position.X - x) ^ 2 + (s.root.Position.Z - z) ^ 2)
		if Hunt.canKill(d, s.filmed, offTime[s.player] or 0, C) then
			if UnseenService.onKill then
				UnseenService.onKill(s.player)
			end
			relief, chase = C.unseen_relief_seconds, 0
			offTime[s.player] = 0
			unhush()
			break
		end
	end
end

-- Studio debug: the next far sighting now; and whom he stares at (nil when he isn't)
function UnseenService.forceSighting()
	nextSighting = 0
end

function UnseenService.staring(): Player?
	return if stare then stare.player else nil
end

function UnseenService.position(): (boolean, number, number)
	return present, x, z
end

function UnseenService.start()
	while not WatchService.ready do
		task.wait(0.1)
	end
	Players.PlayerRemoving:Connect(function(player)
		hushed[player] = nil
		offTime[player] = nil
		exposure[player] = nil
		marked[player] = nil
		sentExposure[player] = nil
	end)
	-- he starts at the far end of his floor (unseen_start_*), and reappears in shadow from there
	x = Config.floorById[C.unseen_start_floor].offsetX + C.unseen_start_x
	z = C.unseen_start_z
	local sinceBroadcast = 0
	local last = os.clock()
	while true do
		task.wait(C.unseen_tick)
		local now = os.clock()
		local dt = math.min(now - last, 0.5)
		last = now
		local ok, err = pcall(tick, dt)
		if not ok then
			warn("[UnseenService] " .. tostring(err))
		end
		sinceBroadcast += dt
		if sinceBroadcast >= C.unseen_broadcast then
			sinceBroadcast = 0
			Net.unseen():FireAllClients(present, x, z, yaw)
			-- each guard's signal bar, when it moved
			for _, player in Players:GetPlayers() do
				local e = exposure[player] or 1
				if math.abs((sentExposure[player] or -1) - e) >= 0.01 or (e == 0) ~= (sentExposure[player] == 0) then
					sentExposure[player] = e
					Net.event():FireClient(player, "Exposure", e, marked[player] == true)
				end
			end
		end
	end
end

return UnseenService
