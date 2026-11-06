--!strict
-- The Unseen (plan section 4). The server holds his position and enforces his rules, which never change:
--   1. never in a field: if his cell becomes filmed he stops existing there and comes back in shadow, out of reach;
--   2. your eyes don't count (the clients draw him; nothing here depends on who looks);
--   3. never on screen (the clients hide him in every camera view);
--   4. he travels by shadow: he only walks through cells that are neither solid nor filmed (Logic/Shadow);
--   5. he kills on contact, and only a player who has been off camera for the whole grace.
-- The director (Logic/Hunt) picks his mode and his target per phase, and gives the players a break after a kill or a
-- long chase. It sets the pressure, never the rules.
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
UnseenService.isDead = nil :: ((player: Player) -> boolean)?

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
local hushed: { [Player]: boolean } = {}
local offTime: { [Player]: number } = {}
local toFilmed: { [number]: number } = {}
local toFilmedVersion = -1

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

local function statuses(dt: number): { Status }
	local out = {}
	local filmed = WatchService.filmed()
	if toFilmedVersion ~= WatchService.version then
		toFilmed = Shadow.toFilmed(g, filmed)
		toFilmedVersion = WatchService.version
	end
	for _, player in Players:GetPlayers() do
		local root = WatchService.rootOf(player)
		local dead = UnseenService.isDead and UnseenService.isDead(player)
		if root and not dead then
			local isFilmed = WatchService.isFilmed(player)
			offTime[player] = if isFilmed then 0 else (offTime[player] or 0) + dt
			table.insert(out, {
				player = player,
				root = root,
				filmed = isFilmed,
				cell = Grid.at(g, root.Position.X, root.Position.Z),
			})
		else
			offTime[player] = 0
		end
	end
	return out
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
	local mode = Hunt.mode(phase, relief)
	local candidates = {}
	local byId: { [number]: Status } = {}
	for _, s in list do
		byId[s.player.UserId] = s
		table.insert(candidates, {
			id = s.player.UserId,
			filmed = s.filmed,
			offTime = offTime[s.player] or 0,
			fieldSteps = if s.cell then toFilmed[s.cell] or 0 else 0,
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
		pathAt = 2
	end

	local speed = Hunt.speed(mode, C)
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
	end)
	-- he starts in the far east of the level until the night places him
	x, z = Grid.center(g, Grid.index(g, g.w - 2, g.d // 2) :: number)
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
		end
	end
end

return UnseenService
