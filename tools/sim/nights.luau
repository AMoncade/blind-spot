--!strict
-- The 1,000-night simulator (plan section 11: "Un simulateur de 1 000 nuits avec des joueurs-robots règle la
-- difficulté"). It plays whole solo nights, a bot guard against the Unseen, with the game's own logic: the same grid
-- and camera fields (Logic/Watch), power timeline (Logic/Timeline), task lists (Logic/Tasks) and director
-- (Logic/Hunt), and the rules of UnseenService (shadow paths, gone when filmed, kill on contact after the grace,
-- the stairs between floors). What it can't copy is a human: the bots are two profiles, careful and casual (PROFILES),
-- with reaction times and habits; half the nights are played by each.
--   lune run tools/sim/nights [runs per night = 200] [nights = 1,2,3,4,5,6] [seed = 1] [N3.flickerStart=5 C.x=1 ...]
-- Prints, per night: caught at least once (the plan's "morts": targets under 5 % on night 1, about 30 % on night 3,
-- about 50 % on night 5), catches per night, nights lost (3 catches), rounds cleared, when the round was done.
-- Approximations: the Unseen repaths every REPATH s (server 0.3 s), a camcorder field is computed every CAM_EVERY s
-- (server 0.1 s), no far sightings, no fire doors used.
local process = require("@lune/process")

local Config = require("../../src/shared/Config")
local Grid = require("../../src/shared/Logic/Grid")
local Watch = require("../../src/shared/Logic/Watch")
local Shadow = require("../../src/shared/Logic/Shadow")
local Timeline = require("../../src/shared/Logic/Timeline")
local Tasks = require("../../src/shared/Logic/Tasks")
local Hunt = require("../../src/shared/Logic/Hunt")
local Look = require("../../src/shared/Logic/Look")
local Rng = require("../../src/shared/Logic/Rng")

local C = Config.C
local DT = 0.2
local REPATH = 0.6
local CAM_EVERY = 0.5
local STAND_OUT = 2.5 -- studs in front of a wall spot where the bot stands to use it

-- The bots. reactFlicker: seconds before running to a red light once the lights stutter. refillBelow: back under a
-- camera when the signal bar drops below this (0: only once marked), until refillTo. camReact / camChance: raising
-- the camcorder at the Unseen when he is in sight. sight: how far they notice him (times the phase's range).
-- finishHold: a prompt this far along is finished even when the lights go. misjudge: the chance, each power failure,
-- to run under a camera whose red light is off (it won't hold); reactBlackout: seconds standing in the dark before
-- they see their mistake and run to a field that still glows. blackoutWork: the chance, each blackout, to stop hiding
-- once safe and go on with the round through the dark (a 45 s blackout is long).
local PROFILES = {
	careful = {
		reactFlicker = 1.5,
		misjudge = 0.12,
		reactBlackout = 1.2,
		refillBelow = 0.35,
		refillTo = 0.85,
		camReact = 0.7,
		camChance = 0.9,
		sight = 1,
		finishHold = 0.5,
		blackoutWork = 0.15,
	},
	casual = {
		reactFlicker = 3.0,
		misjudge = 0.35,
		reactBlackout = 2.2,
		refillBelow = 0,
		refillTo = 0.5,
		camReact = 1.4,
		camChance = 0.55,
		sight = 0.7,
		finishHold = 0.8,
		blackoutWork = 0.4,
	},
}
local SIGHT = { LIVE = 60, FLICKER = 35, BLACKOUT = 16 }

-- the world: the grid and every camera's field, with the plaster whole and broken (night 5)
local function makeWorld(states: { [string]: boolean }?): any
	local level = Watch.level(Config.Map, C, states)
	local fields = {}
	for _, cam in Config.Cameras do
		fields[cam.id] = Watch.coverage(level, Watch.cameraView(cam), C.sample_heights, C.sample_inset)
	end
	return { level = level, g = level.grid, fields = fields }
end

local t0 = os.clock()
local WHOLE = makeWorld(nil)
local OPENED = makeWorld({ P4_Plaster = false })
print(string.format("worlds ready in %.1f s", os.clock() - t0))

local floorOrder: { [string]: number } = {}
for k, f in Config.Floors do
	floorOrder[f.id] = k
end

local function dist(ax: number, az: number, bx: number, bz: number): number
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
end

local function floorOf(x: number): string
	return (Config.floorAt(x))
end

-- the open cell where a guard stands to use a spot (in front of it), or the spot's own cell
local function standCell(g: any, x: number, z: number, yaw: number, out: number): number?
	local fx, fz = x + math.sin(math.rad(yaw)) * out, z + math.cos(math.rad(yaw)) * out
	local i = Grid.at(g, fx, fz)
	if i and not g.blocked[i] then
		return i
	end
	-- in front of a big prop (the generator): the nearest open cell around that point
	for r = 2, 10, 2 do
		local best, bestD = nil, math.huge
		for _, c in Grid.near(g, fx, fz, r) do
			if not g.blocked[c] then
				local cx, cz = Grid.center(g, c)
				local d = dist(cx, cz, fx, fz)
				if d < bestD then
					best, bestD = c, d
				end
			end
		end
		if best then
			return best
		end
	end
	return nil
end

local function stairsOf(floor: string): any
	for _, row in Config.Stairs do
		if row.floor == floor then
			return row
		end
	end
	return nil
end

local function stairsExit(g: any, spotId: string): number
	local s = Config.spotById[spotId]
	return standCell(g, s.x, s.z, s.yaw, C.stairs_out) :: number
end

-- One night. Returns { catches, lost, cleared, doneAt, tasks, total }.
local function playNight(night: number, seed: number, profile: any): any
	local def = Config.nightByNumber[night]
	local rng = Rng.new(seed * 7919 + night)
	local world = WHOLE
	local g = world.g
	local tl = Timeline.build(def, Config.Cameras, seed)
	local list = Tasks.build(Config.Tasks, function(id)
		return Config.spotById[id].label
	end, C.scan_count + def.extraScans, seed, night, def.length / (C.night_clock_end - C.night_clock_start))
	local spots: { [string]: any } = table.clone(Config.spotById) -- plus tonight's cut lines' junction boxes

	-- the cut lines (TaskService.reset)
	local cuts = {}
	local cutRng = Rng.new(seed + 77)
	for k = 1, def.cables do
		local f = C.cable_cut_margin + (1 - 2 * C.cable_cut_margin) * k / (def.cables + 1)
		table.insert(cuts, def.length * f + cutRng.int(-20, 20))
	end
	table.sort(cuts)

	-- what is filmed: the running cameras' fields (minus the dead ones), plus the bot's camcorder
	local baseFilmed: Watch.Set = {}
	local camSet: Watch.Set? = nil
	local filmedAll: Watch.Set = {}
	local safeSet: Watch.Set = {} -- the cells of the cameras that hold through the coming BLACKOUT
	local filmedKey = ""
	local camUnion: Watch.Set? = nil -- the camcorder field and the base filmedAll was last built from
	local camBase: Watch.Set? = nil
	local function refreshFilmed(seg: any, now: number)
		local broken = Tasks.broken(list, now)
		local key = seg.phase .. tostring(seg.t0) .. tostring(world == OPENED)
		for id in broken do
			key ..= id
		end
		if key ~= filmedKey then
			filmedKey = key
			local sets, safe = {}, {}
			local hold: { [string]: boolean } = {}
			for _, id in seg.holdouts or {} do
				hold[id] = true
			end
			for _, id in Timeline.active(seg, Config.Cameras) do
				if not broken[id] then
					table.insert(sets, world.fields[id])
				end
			end
			for _, cam in Config.Cameras do
				if not broken[cam.id] and (cam.always or hold[cam.id]) then
					table.insert(safe, world.fields[cam.id])
				end
			end
			baseFilmed = Watch.union(sets)
			safeSet = Watch.union(safe)
		end
		if camSet then
			if camUnion ~= camSet or camBase ~= baseFilmed then
				camUnion, camBase = camSet, baseFilmed
				filmedAll = Watch.union({ baseFilmed, camSet :: Watch.Set })
			end
		else
			filmedAll = baseFilmed
		end
	end
	local function free(i: number): boolean
		return not g.blocked[i] and not filmedAll[i]
	end

	-- the bot
	local spawnBlock
	for _, b in Config.Map do
		if b.id == C.spawn_marker then
			spawnBlock = b
		end
	end
	local bot = {
		x = spawnBlock.x,
		z = spawnBlock.z,
		yaw = 0,
		exposure = 1,
		marked = false,
		offTime = 0,
		filmed = true,
		dead = 0,
		lives = C.solo_lives,
		catches = 0,
		carrying = nil :: string?,
		path = nil :: { number }?,
		pathAt = 1,
		dest = nil :: number?,
		hold = 0,
		stairsReady = 0,
		dangerSince = nil :: number?,
		blackoutSince = nil :: number?,
		misjudge = false,
		bold = false, -- this blackout, it goes on with the round once it is safe
		wrongFor = nil :: Watch.Set?,
		wrong = {} :: Watch.Set,
		refilling = false,
		battery = C.camcorder_battery,
		camUntil = 0,
		camNext = 0,
		camSeenAt = nil :: number?,
		camRoll = nil :: boolean?,
		filming = 0,
	}

	-- the Unseen
	local u = {
		present = false,
		x = Config.floorById[C.unseen_start_floor].offsetX + C.unseen_start_x,
		z = C.unseen_start_z,
		path = nil :: { number }?,
		pathAt = 2,
		goal = nil :: number?,
		repathIn = 0,
		relief = 0,
		chase = 0,
		lastMode = nil :: string?,
		floorWait = 0,
	}

	local function botCell(): number?
		return Grid.at(g, bot.x, bot.z)
	end

	local function reappear(fx: number, fz: number)
		local from = Grid.at(g, fx, fz) or 1
		local cell = Shadow.nearest(g, from, function(i)
			if not free(i) then
				return false
			end
			local cx, cz = Grid.center(g, i)
			return bot.dead > 0 or dist(cx, cz, bot.x, bot.z) >= C.unseen_return_min_distance
		end)
		if not cell then
			u.present = false
			return
		end
		u.x, u.z = Grid.center(g, cell)
		u.present = true
		u.path, u.goal, u.repathIn = nil, nil, 0
	end

	local islandFor: Watch.Set? = nil
	local islandSet: { [number]: number } = {}
	local islandList: { number } = {}
	local function islandCells(): { number }
		local mine = Grid.at(g, u.x, u.z)
		if not mine then
			return {}
		end
		if islandFor == filmedAll and islandSet[mine] then
			return islandList
		end
		islandFor = filmedAll
		islandSet = Shadow.island(g, filmedAll, mine)
		islandList = {}
		for i in islandSet do
			table.insert(islandList, i)
		end
		table.sort(islandList)
		return islandList
	end

	local function farthestCell(): number?
		local cells = islandCells()
		if #cells == 0 then
			return nil
		end
		local best, bestD = nil, -1
		for _ = 1, 24 do
			local i = rng.pick(cells)
			local cx, cz = Grid.center(g, i)
			local d = dist(cx, cz, bot.x, bot.z)
			if d > bestD then
				best, bestD = i, d
			end
		end
		return best
	end

	local function unseenTick(phase: string, dt: number): string?
		if not u.present then
			reappear(u.x, u.z)
			if not u.present then
				return nil
			end
		end
		local mine = Grid.at(g, u.x, u.z)
		if not mine or not free(mine) then
			reappear(u.x, u.z) -- rule 1: filmed, he is gone from here
			if not u.present then
				return nil
			end
			mine = Grid.at(g, u.x, u.z)
		end
		u.relief = math.max(0, u.relief - dt)
		local alive = bot.dead <= 0
		local anyMarked = alive and bot.marked and not bot.filmed
		local mode = Hunt.mode(phase :: any, u.relief, anyMarked)
		local targetId = nil
		if alive then
			targetId = Hunt.target({
				{ id = 1, filmed = bot.filmed, offTime = bot.offTime, fieldSteps = 0, marked = bot.marked },
			}, mode, C.hunt_distance_weight)
		end
		local hasTarget = targetId ~= nil
		if mode == "hunt" and hasTarget then
			u.chase += dt
			if u.chase >= C.unseen_chase_max then
				u.relief, u.chase = C.unseen_relief_seconds, 0
				mode, hasTarget = "retreat", false
			end
		else
			u.chase = 0
		end
		-- the stairs: the guard he wants is on another floor
		local want = if hasTarget then floorOf(bot.x) elseif alive and not bot.filmed then floorOf(bot.x) else nil
		if want and want ~= floorOf(u.x) then
			u.floorWait += dt
			if u.floorWait >= C.unseen_floor_delay then
				u.floorWait = 0
				local row = stairsOf(want)
				local s = Config.spotById[row.spot]
				u.present = false
				reappear(s.x, s.z)
				return mode
			end
		else
			u.floorWait = 0
		end
		if mode == "prowl" and alive and dist(u.x, u.z, bot.x, bot.z) < C.unseen_corner_distance then
			u.present = false
			reappear(u.x, u.z)
			return mode
		end
		if u.lastMode ~= mode then
			u.lastMode = mode
			u.goal, u.path, u.repathIn = nil, nil, 0
		end
		u.repathIn -= dt
		local reached = u.path == nil or u.pathAt > #(u.path :: { number })
		local stopAt = 0
		local keep = dist(u.x, u.z, bot.x, bot.z)
		if hasTarget then
			if u.repathIn <= 0 then
				local tcell = botCell()
				if tcell and not free(tcell) then
					tcell = Shadow.nearest(g, tcell, free) or tcell
				end
				u.goal = tcell
			end
			if mode == "approach" then
				stopAt = math.ceil(C.unseen_hold_distance_flicker / g.cell)
			end
		elseif mode == "retreat" then
			if reached or u.repathIn <= 0 and u.goal == nil then
				u.goal = farthestCell()
			end
		else
			local tooClose = alive and keep < C.unseen_keep_distance_live
			if reached or tooClose and u.repathIn <= 0 then
				if tooClose then
					u.goal = farthestCell()
				else
					local cells = islandCells()
					u.goal = nil
					for _ = 1, 12 do
						if #cells == 0 then
							break
						end
						local i = rng.pick(cells)
						local cx, cz = Grid.center(g, i)
						if not alive or dist(cx, cz, bot.x, bot.z) >= C.unseen_keep_distance_live then
							u.goal = i
							break
						end
					end
				end
			end
		end
		if u.repathIn <= 0 or reached then
			u.repathIn = REPATH
			u.path = if u.goal and mine then Shadow.path(g, filmedAll, mine :: number, u.goal :: number) else nil
			if not u.path and u.goal and mine and hasTarget then
				local gx, gz = Grid.center(g, u.goal :: number)
				local best, bestD = nil, math.huge
				for _, i in islandCells() do
					local cx, cz = Grid.center(g, i)
					local d = (cx - gx) ^ 2 + (cz - gz) ^ 2
					if d < bestD then
						best, bestD = i, d
					end
				end
				if best and best ~= mine then
					u.path = Shadow.path(g, filmedAll, mine :: number, best)
				end
			end
			u.pathAt = 2
		end
		local speed = Hunt.speed(mode :: any, C) * def.unseenSpeed
		if mode == "prowl" and alive and keep < C.unseen_keep_distance_live and u.goal == nil then
			speed = 0
		end
		local path = u.path
		if path then
			local budget = speed * dt
			while budget > 0 and u.pathAt <= #path do
				local tx, tz = Grid.center(g, path[u.pathAt])
				local dx, dz = tx - u.x, tz - u.z
				local d = math.sqrt(dx * dx + dz * dz)
				if d < 1e-3 then
					u.pathAt += 1
					continue
				end
				local move = math.min(budget, d)
				u.x += dx / d * move
				u.z += dz / d * move
				budget -= move
				if stopAt > 0 and #path - u.pathAt + 1 <= stopAt then
					break
				end
			end
		end
		return mode
	end

	-- the bot's next destination and what it does there
	local doneAt: number? = nil
	local function taskDest(now: number): (number?, string?, any)
		-- the nearest task leg (floors cost a detour), nil when the round is done
		local bestCell, bestKind, bestInfo, bestCost = nil, nil, nil, math.huge
		local here = floorOf(bot.x)
		for _, t in list do
			if t.done or not Tasks.released(t, now) then
				continue
			end
			local spotId, kind, holdNeed
			if t.kind == "fetch" then
				if bot.carrying == t.id then
					spotId, kind, holdNeed = t.target, "use", t.hold
				elseif bot.carrying == nil then
					spotId, kind, holdNeed = t.pickup, "take", C.pickup_hold
				end
			elseif t.kind == "film" then
				spotId, kind, holdNeed = t.target, "film", t.hold
			else
				spotId, kind, holdNeed = t.target, "scan", t.hold
			end
			if spotId then
				local s = spots[spotId]
				local cell = if kind == "film" then Grid.at(g, s.x, s.z) else standCell(g, s.x, s.z, s.yaw, STAND_OUT)
				if cell then
					if kind == "film" and g.blocked[cell] then
						continue
					end
					local cx, cz = Grid.center(g, cell)
					local f = floorOf(cx)
					local cost = if f == here
						then dist(bot.x, bot.z, cx, cz)
						else 80 * math.abs(floorOrder[f] - floorOrder[here]) + 60
					if kind == "film" and world ~= OPENED then
						cost = math.huge -- the room is sealed until the plaster is broken
					end
					if cost < bestCost then
						bestCell, bestKind, bestCost = cell, kind, cost
						bestInfo = { task = t, hold = holdNeed, spot = s }
					end
				end
			end
		end
		return bestCell, bestKind, bestInfo
	end

	-- where to stand to get on camera: the nearest cell of `set` on this floor (the current destination while it is
	-- still in the set: no new search every step)
	local function nearestIn(set: Watch.Set): number?
		if bot.dest and set[bot.dest] and bot.path then
			return bot.dest
		end
		local from = botCell()
		if not from then
			return nil
		end
		local here = floorOf(bot.x)
		return Shadow.nearest(g, from, function(i)
			if not set[i] then
				return false
			end
			local cx = Grid.center(g, i)
			return floorOf(cx) == here
		end)
	end

	local function setDest(cell: number?)
		if cell == bot.dest and bot.path then
			return
		end
		bot.dest = cell
		bot.hold = 0
		local from = botCell()
		bot.path = if cell and from then Shadow.path(g, {}, from, cell) else nil
		bot.pathAt = 2
	end

	-- a route to a cell on another floor goes through the stairs: the stairwell door of this floor
	local function routeTo(cell: number): (number, boolean)
		local cx = Grid.center(g, cell)
		local there, here = floorOf(cx), floorOf(bot.x)
		if there == here then
			return cell, false
		end
		local row = stairsOf(here)
		return stairsExit(g, row.spot), true
	end

	local function takeStairs(towardFloor: string)
		local row = stairsOf(floorOf(bot.x))
		local up = floorOrder[towardFloor] < floorOrder[row.floor]
		local target = if up then row.up else row.down
		if target == "" then
			return
		end
		local cell = stairsExit(g, target)
		bot.x, bot.z = Grid.center(g, cell)
		bot.stairsReady = 0
		bot.path, bot.dest = nil, nil
	end

	local function finish(t: any)
		t.done = true
		for _, e in t.effect do
			if e == "open:P4_Plaster" then
				world = OPENED
				g = world.g
				filmedKey = ""
			end
		end
	end

	local function sees(phase: string): boolean
		if not u.present or floorOf(u.x) ~= floorOf(bot.x) then
			return false
		end
		local d = dist(u.x, u.z, bot.x, bot.z)
		if d > SIGHT[phase] * profile.sight then
			return false
		end
		return not Grid.segmentHits(world.level.occluders, bot.x, 4.5, bot.z, u.x, C.unseen_height * 0.5, u.z)
	end

	local function camcorder(t: number, phase: string, filmYaw: number?)
		-- raise it at him (or at the room's opening while filming), lower it when he's gone
		local want = false
		local yaw, pitch = 0, -0.15
		if filmYaw then
			want, yaw = true, filmYaw
		elseif sees(phase) then
			bot.camSeenAt = bot.camSeenAt or t
			if bot.camRoll == nil then
				bot.camRoll = rng.next() < profile.camChance
			end
			if bot.camRoll and t - (bot.camSeenAt :: number) >= profile.camReact then
				want = true
				yaw, pitch = Look.toward(bot.x, 4.5, bot.z, u.x, C.unseen_height * 0.4, u.z)
			end
		else
			bot.camSeenAt, bot.camRoll = nil, nil
		end
		if want and bot.battery > 0 then
			bot.battery -= DT
			if t >= bot.camNext then
				bot.camNext = t + CAM_EVERY
				local view =
					Look.view(bot.x, 4.5, bot.z, yaw, pitch, C.camcorder_hfov, C.camcorder_vfov, C.camcorder_range)
				camSet = Watch.coverage(world.level, view, C.camcorder_samples, 0)
			end
		else
			camSet = nil
		end
	end

	-- the night
	local causes: { string } = {} -- where and how each catch happened
	local t = 0
	local cutAt = 1
	local lost = false
	while t < tl.length do
		local seg = Timeline.at(tl, t)
		local phase = seg.phase
		-- a cut line
		if cuts[cutAt] and t >= cuts[cutAt] then
			cutAt += 1
			local broken = Tasks.broken(list, t)
			local candidates = {}
			for id in string.gmatch(C.cuttable_cameras, "[^;]+") do
				if not broken[id] and not spots["Line_" .. id] then
					table.insert(candidates, id)
				end
			end
			if #candidates > 0 then
				local id = cutRng.pick(candidates)
				local cam = Config.cameraById[id]
				spots["Line_" .. id] = {
					x = cam.x,
					z = cam.z,
					yaw = math.deg(math.atan2(cam.tx - cam.x, cam.tz - cam.z)),
				}
				table.insert(list, {
					id = "splice:" .. id,
					kind = "scan",
					label = "",
					target = "Line_" .. id,
					effect = { "cam:" .. id },
					pay = C.pay_splice,
					hold = C.splice_hold,
					at = t,
					done = false,
				})
			end
		end
		refreshFilmed(seg, t)

		-- the bot
		if bot.dead > 0 then
			bot.dead -= DT
			if bot.dead <= 0 then
				bot.x, bot.z = spawnBlock.x, spawnBlock.z
				bot.exposure, bot.marked, bot.offTime = 1, false, 0
				bot.path, bot.dest = nil, nil
			end
		else
			bot.filmed = Watch.circleFilmed(g, filmedAll, bot.x, bot.z, C.player_radius + C.edge_margin)
			bot.offTime = if bot.filmed then 0 else bot.offTime + DT
			bot.exposure, bot.marked = Hunt.exposure(bot.exposure, bot.marked, bot.filmed, phase, DT, C)

			-- what it wants now
			local danger = phase ~= "LIVE"
			if danger then
				if not bot.dangerSince then
					bot.dangerSince = t
					bot.misjudge = rng.next() < profile.misjudge
				end
			else
				bot.dangerSince = nil
			end
			if phase == "BLACKOUT" then
				if not bot.blackoutSince then
					bot.blackoutSince = t
					bot.bold = rng.next() < profile.blackoutWork
				end
			else
				bot.blackoutSince = nil
				bot.bold = false
			end
			local reacting = danger and t - (bot.dangerSince :: any or t) >= profile.reactFlicker
			-- a bold guard goes on with the round through the blackout (once past the first moments)
			if
				reacting
				and bot.bold
				and phase == "BLACKOUT"
				and t - (bot.blackoutSince :: number) >= profile.reactBlackout + 2
			then
				reacting = false
			end
			if bot.marked or bot.exposure < profile.refillBelow then
				bot.refilling = true
			elseif bot.refilling and bot.exposure >= profile.refillTo then
				bot.refilling = false
			end
			local cell, kind, info = taskDest(t)
			local holding = bot.hold > 0 and info and bot.hold / info.hold >= profile.finishHold
			local filmYaw: number? = nil
			local fooled = bot.misjudge
				and (phase == "FLICKER" or t - (bot.blackoutSince :: any or t) < profile.reactBlackout)
			if reacting and not holding and fooled then
				-- under the wrong camera: one that won't hold (and, once it's dark, frozen there a moment)
				if phase == "FLICKER" then
					if bot.wrongFor ~= baseFilmed then
						bot.wrongFor = baseFilmed
						bot.wrong = {}
						for i in baseFilmed do
							if not safeSet[i] then
								bot.wrong[i] = true
							end
						end
					end
					local wrong = bot.wrong
					if not Watch.circleFilmed(g, wrong, bot.x, bot.z, C.player_radius) then
						setDest(nearestIn(wrong))
					end
				else
					setDest(nil)
				end
			elseif reacting and not holding then
				-- under a red light until the power is back
				if Watch.circleFilmed(g, safeSet, bot.x, bot.z, C.player_radius) then
					setDest(nil)
				else
					local safe = nearestIn(safeSet)
					if safe then
						setDest(safe)
					else
						-- nothing holds on this floor: up toward the post
						setDest(stairsExit(g, stairsOf(floorOf(bot.x)).spot))
						if bot.dest == botCell() and floorOf(bot.x) ~= "P1" then
							takeStairs("P1")
						end
					end
				end
			elseif bot.refilling and not bot.filmed and not holding then
				setDest(nearestIn(filmedAll))
			elseif cell then
				local dest, viaStairs = routeTo(cell)
				setDest(dest)
				if bot.dest == botCell() then
					if viaStairs then
						bot.stairsReady += DT
						if bot.stairsReady >= C.stairs_hold then
							takeStairs(floorOf((Grid.center(g, cell))))
						end
					else
						-- at the spot: hold the prompt (the film task: the camcorder up at the opening)
						if kind == "film" then
							filmYaw = 0 -- facing south (Look: yaw 0 looks along -z), toward the broken plaster
						end
						bot.hold += DT
						if bot.hold >= info.hold then
							bot.hold = 0
							if kind == "take" then
								bot.carrying = info.task.id
							else
								if kind == "use" then
									bot.carrying = nil
								end
								finish(info.task)
							end
							setDest(nil)
						end
					end
				end
			else
				-- nothing to do now (the round is done, or the next task isn't there yet): back to the post
				local all = true
				for _, task in list do
					if not task.done then
						all = false
					end
				end
				if all then
					-- the round is done: back to the post until six
					doneAt = doneAt or t
					local post = Grid.at(g, spawnBlock.x, spawnBlock.z) :: number
					local dest, viaStairs = routeTo(post)
					setDest(dest)
					if viaStairs and bot.dest == botCell() then
						takeStairs("P1")
					end
				elseif not bot.filmed then
					-- waiting for the next task: on camera where they are
					local near = nearestIn(filmedAll)
					if near then
						setDest(near)
					else
						setDest(stairsExit(g, stairsOf(floorOf(bot.x)).spot))
						if bot.dest == botCell() and floorOf(bot.x) ~= "P1" then
							takeStairs("P1")
						end
					end
				else
					setDest(nil)
				end
			end
			camcorder(t, phase, filmYaw)

			-- walk
			local path = bot.path
			if path then
				local budget = C.player_walk_speed * DT
				while budget > 0 and bot.pathAt <= #path do
					local tx, tz = Grid.center(g, path[bot.pathAt])
					local dx, dz = tx - bot.x, tz - bot.z
					local d = math.sqrt(dx * dx + dz * dz)
					if d < 1e-3 then
						bot.pathAt += 1
						continue
					end
					local move = math.min(budget, d)
					bot.x += dx / d * move
					bot.z += dz / d * move
					budget -= move
				end
			end
		end

		-- the Unseen
		local mode = unseenTick(phase, DT)
		if bot.dead <= 0 and u.present and mode then
			local d = dist(bot.x, bot.z, u.x, u.z)
			if Hunt.canKill(d, bot.filmed, bot.offTime, C, mode :: any) then
				local doing = if bot.refilling then "refill" elseif bot.dangerSince then "shelter" else "task"
				table.insert(
					causes,
					string.format("%s %s %s%s", floorOf(bot.x), phase, doing, if bot.marked then " marked" else "")
				)
				bot.catches += 1
				bot.lives -= 1
				bot.dead = C.death_seconds
				bot.carrying = nil
				bot.hold = 0
				camSet = nil
				u.relief, u.chase = C.unseen_relief_seconds, 0
				bot.offTime = 0
				if bot.lives <= 0 then
					lost = true
					break
				end
			end
		end
		t += DT
	end
	local done, total = 0, #list
	for _, task in list do
		if task.done then
			done += 1
		end
	end
	return {
		catches = bot.catches,
		lost = lost,
		cleared = not lost and done == total,
		doneAt = doneAt,
		tasks = done,
		total = total,
		causes = causes,
	}
end

-- the runs
local args = process.args
local runs = tonumber(args[1]) or 200
local nights = {}
for n in string.gmatch(args[2] or "1,2,3,4,5,6", "%d+") do
	table.insert(nights, tonumber(n) :: number)
end
local seed0 = tonumber(args[3]) or 1
-- overrides to try a setting without touching the CSVs: N3.flickerStart=5 (a night's field), C.exposure_refill=4
for k = 4, #args do
	local night, field, value = string.match(args[k], "^N(%d+)%.(%w+)=([%d%.%-]+)$")
	if night then
		local def: any = Config.nightByNumber[tonumber(night) :: number]
		def[field] = tonumber(value)
	else
		local key, v = string.match(args[k], "^C%.([%w_]+)=([%d%.%-]+)$")
		assert(key, "bad override " .. args[k])
		local constants: any = C
		constants[key] = tonumber(v)
	end
	print("override " .. args[k])
end

print(string.format("%d runs per night, half careful and half casual bots", runs))
print("night  caught>=1  catches  lost   cleared  tasks   round done at   (careful / casual caught)")
for _, n in nights do
	local caught, catches, lost, cleared, tasks, doneSum, doneN = 0, 0, 0, 0, 0, 0, 0
	local byProfile = { careful = { 0, 0 }, casual = { 0, 0 } }
	local causeCount: { [string]: number } = {}
	local start = os.clock()
	for k = 1, runs do
		local name = if k % 2 == 0 then "careful" else "casual"
		local r = playNight(n, seed0 * 100000 + k, PROFILES[name])
		local p = byProfile[name]
		p[2] += 1
		if r.catches > 0 then
			caught += 1
			p[1] += 1
		end
		catches += r.catches
		for _, c in r.causes do
			causeCount[c] = (causeCount[c] or 0) + 1
		end
		lost += if r.lost then 1 else 0
		cleared += if r.cleared then 1 else 0
		tasks += r.tasks / r.total
		if r.doneAt then
			doneSum += r.doneAt
			doneN += 1
		end
	end
	print(
		string.format(
			"%5d  %8.1f%%  %7.2f  %5.1f%%  %6.1f%%  %5.0f%%  %8s   (%.0f%% / %.0f%%)  [%.0f s]",
			n,
			100 * caught / runs,
			catches / runs,
			100 * lost / runs,
			100 * cleared / runs,
			100 * tasks / runs,
			if doneN > 0 then string.format("%.0f s", doneSum / doneN) else "-",
			100 * byProfile.careful[1] / math.max(1, byProfile.careful[2]),
			100 * byProfile.casual[1] / math.max(1, byProfile.casual[2]),
			os.clock() - start
		)
	)
	local keys = {}
	for k in causeCount do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return causeCount[a] > causeCount[b]
	end)
	for _, k in keys do
		print(string.format("         %4d  %s", causeCount[k], k))
	end
end
