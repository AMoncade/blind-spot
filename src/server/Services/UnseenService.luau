--!strict
-- The Unseen (plan section 4, reworked with Adrien on 7 November 2026). He never walks. He stands in a blind spot,
-- always facing the guard he is after (the one whose signal bar is lowest), and every few seconds he is somewhere
-- else: another blind spot, as near to that guard as their bar is low (Logic/Hunt.stalkDistance), most often where
-- they can see him. When the bar is empty he is on them, behind them: the catch (NightService.kill,
-- Controllers/Death). His rules still hold, the server enforces them:
--   1. never in a field: he only appears in shadow cells, and a field that touches his cell (a camera, a camcorder)
--      sends him away at once (the camcorders show a VHS trace where he was);
--   2. your eyes don't count (the clients draw him; nothing here depends on who looks);
--   3. never on screen (the clients hide him in every camera view, the camcorder included);
--   4. after a catch the director gives the guards a break (unseen_relief_seconds);
--   6. now and then he breaks a camera in front of his guard (Adrien, 8 Nov: "que le monstre puisse casser des
--      caméras devant toi"): he stands right under one the guard can see, outside its field, and it shatters; it
--      stays dead for the night (TaskService.smash). As many as the mode and the night allow (smashes);
--   5. you can't walk up to him (Adrien, 8 Nov: "tu peux pas lui foncer dedans, ça gâche l'horreur"): a guard who
--      comes much nearer than their bar puts him (Hunt.flees) finds him gone, further away; one who still reaches him
--      (Hunt.touches: a sprint, a corner, a bar nearly empty) is caught.
-- The signal bar of every guard on shift is kept here (Hunt.exposure) and sent to its guard (event Exposure).
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
local Upgrades = require(Logic:WaitForChild("Upgrades"))
local Data = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("Data"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))

local C = Config.C

local UnseenService = {}

-- NightService sets these (it owns deaths and the night)
UnseenService.onKill = nil :: ((player: Player) -> ())?
UnseenService.speedScale = 1 -- the night's difficulty and the number of guards: the bars drain faster, he jumps sooner
UnseenService.mode = nil :: any -- the shift's mode (content/modes.csv): the bar's speed, the smashes
UnseenService.smashes = 0 -- cameras he may still smash tonight (the mode and the night)
UnseenService.onSmash = nil :: ((cameraId: string) -> ())? -- NightService: the camera dies for the night
UnseenService.isPlaying = nil :: ((player: Player) -> boolean)? -- on shift and not in a death

local g = WatchService.grid
local rng = Rng.new(os.time())

local present = false
local x, z = 0, 0
local yaw = 0
local target: Player? = nil
local nextJump = 0
local relief = 0
local hushed: { [Player]: boolean } = {}
local nextSmash = 0 -- os.clock() of his next try at a camera
local smashing: { id: string, at: number }? = nil -- he stands under this camera; it breaks at `at`
local offTime: { [Player]: number } = {}
local exposure: { [Player]: number } = {} -- the signal bar, 1 full
local sentExposure: { [Player]: number } = {}

local function free(i: number): boolean
	return Shadow.free(g, WatchService.filmed(), i)
end

local function unhush(except: Player?)
	for player in hushed do
		if player ~= except then
			hushed[player] = nil
			Net.event():FireClient(player, "Hush", false)
		end
	end
end

type Status = { player: Player, root: BasePart, filmed: boolean }

local function statuses(dt: number, phase: string): { Status }
	local out = {}
	for _, player in Players:GetPlayers() do
		local root = WatchService.rootOf(player)
		local onShift = UnseenService.isPlaying == nil or UnseenService.isPlaying(player)
		if root and onShift then
			local isFilmed = WatchService.isFilmed(player)
			offTime[player] = if isFilmed then 0 else (offTime[player] or 0) + dt
			-- the night's difficulty times the guard's SIGNAL upgrade (level 1: the base speed, fast), times the mode's
			-- speed, which the same upgrade eases from drain (level 1) to drain_max (maxed) (Adrien, 8 Nov: NORMAL "2 fois
			-- plus vite que le facile, 1,5 si tu l'as améliorée, basé sur l'amélioration")
			local def = Config.upgradeById.signal
			local level = Upgrades.level(Data.get(player), "signal")
			local nerve = Upgrades.value(def, level)
			local mode = UnseenService.mode
			local modeScale = if mode
				then mode.drain + (mode.drainMax - mode.drain) * math.clamp(
					(level - 1) / math.max(def.max - 1, 1),
					0,
					1
				)
				else 1
			exposure[player] = Hunt.exposure(
				exposure[player] or 1,
				false,
				isFilmed,
				phase,
				dt,
				C,
				UnseenService.speedScale * nerve * modeScale
			)
			table.insert(out, { player = player, root = root, filmed = isFilmed })
		else
			offTime[player] = 0
			exposure[player] = 1
		end
	end
	return out
end

-- A shadow cell on the guard's floor, about `distance` from them (stalk_band of leeway, then wider), other guards
-- kept at a distance; most often (stalk_seen_chance) one the guard can see from where they stand.
local function pickCell(s: Status, distance: number, others: { Status }): number?
	local p = s.root.Position
	local floor = Config.floorAt(p.X)
	local seen, hidden = {}, {}
	for widen = 1, 4 do
		local band = C.stalk_band * widen
		for i = 1, Grid.count(g) do
			if free(i) then
				local cx, cz = Grid.center(g, i)
				local d = math.sqrt((cx - p.X) ^ 2 + (cz - p.Z) ^ 2)
				if math.abs(d - distance) <= band and Config.floorAt(cx) == floor then
					local clear = true
					for _, o in others do
						if
							o.player ~= s.player
							and (o.root.Position - Vector3.new(cx, o.root.Position.Y, cz)).Magnitude
								< distance * 0.6
						then
							clear = false
							break
						end
					end
					if clear then
						local blocked = Grid.segmentHits(
							WatchService.level.occluders,
							p.X,
							p.Y + 1.5,
							p.Z,
							cx,
							C.floor_y + C.unseen_height * 0.8,
							cz
						)
						table.insert(if blocked then hidden else seen, i)
					end
				end
			end
		end
		if #seen + #hidden > 0 then
			break
		end
	end
	if #seen > 0 and (#hidden == 0 or rng.next() < C.stalk_seen_chance) then
		return rng.pick(seen)
	elseif #hidden > 0 then
		return rng.pick(hidden)
	end
	return nil
end

-- A camera his guard can see in front of them, and a cell right under it out of every field (rule 6)
local function smashTarget(s: Status): (string?, number?)
	local p = s.root.Position
	local look = Vector3.new(s.root.CFrame.LookVector.X, 0, s.root.CFrame.LookVector.Z)
	if look.Magnitude < 0.01 then
		return nil, nil
	end
	look = look.Unit
	local floor = Config.floorAt(p.X)
	local best, bestCell, bestScore = nil, nil, -math.huge
	for _, id in WatchService.active() do
		local cam = Config.cameraById[id]
		if not cam or cam.always or Config.floorAt(cam.x) ~= floor then
			continue
		end
		local to = Vector3.new(cam.x - p.X, 0, cam.z - p.Z)
		local d = to.Magnitude
		if d < C.smash_min or d > C.smash_max or to.Unit:Dot(look) < C.smash_front then
			continue
		end
		if Grid.segmentHits(WatchService.level.occluders, p.X, p.Y + 1.5, p.Z, cam.x, cam.y - 0.6, cam.z) then
			continue
		end
		-- the nearest free cell under it
		local cell, near = nil, math.huge
		for _, i in Grid.near(g, cam.x, cam.z, C.smash_reach) do
			if free(i) then
				local cx, cz = Grid.center(g, i)
				local dd = (cx - cam.x) ^ 2 + (cz - cam.z) ^ 2
				if dd < near then
					cell, near = i, dd
				end
			end
		end
		-- the most in front of the guard
		local score = to.Unit:Dot(look) - d / 200
		if cell and score > bestScore then
			best, bestCell, bestScore = id, cell, score
		end
	end
	return best, bestCell
end

-- seconds to his next camera: the mode's period, else the default range
local function smashPeriod(): number
	local mode = UnseenService.mode
	if mode and mode.smashEvery > 0 then
		return mode.smashEvery
	end
	return C.smash_every[1] + rng.next() * (C.smash_every[2] - C.smash_every[1])
end

-- a camera to break out of sight: a running one (never the post's), on the guard's floor first
local function blindTarget(s: Status): string?
	local floor = Config.floorAt(s.root.Position.X)
	local here, elsewhere = {}, {}
	for _, id in WatchService.active() do
		local cam = Config.cameraById[id]
		if cam and not cam.always then
			table.insert(if Config.floorAt(cam.x) == floor then here else elsewhere, id)
		end
	end
	table.sort(here)
	table.sort(elsewhere)
	if #here > 0 then
		return rng.pick(here)
	elseif #elsewhere > 0 then
		return rng.pick(elsewhere)
	end
	return nil
end

local function jump(s: Status, list: { Status }, phase: string)
	local e = exposure[s.player] or 1
	local cell = pickCell(s, Hunt.stalkDistance(e, C), list)
	nextJump = os.clock() + Hunt.jumpDelay(phase, e, UnseenService.speedScale, rng.next(), C)
	if not cell then
		present = false -- nowhere dark enough near them: he waits
		return
	end
	x, z = Grid.center(g, cell)
	present = true
end

-- the catch: he is behind the guard, and they turn around (Controllers/Death)
local function catch(s: Status)
	local look = s.root.CFrame.LookVector
	local back = Vector3.new(look.X, 0, look.Z)
	back = if back.Magnitude > 0.01 then back.Unit else Vector3.new(0, 0, -1)
	x, z = s.root.Position.X - back.X * C.catch_distance, s.root.Position.Z - back.Z * C.catch_distance
	yaw = math.atan2(-(s.root.Position.X - x), -(s.root.Position.Z - z))
	present = true
	Net.unseen():FireAllClients(present, x, z, yaw)
	if UnseenService.onKill then
		UnseenService.onKill(s.player)
	end
	exposure[s.player], offTime[s.player] = 1, 0
	relief = C.unseen_relief_seconds
	unhush()
	present = false
end

local function tick(dt: number)
	local phase = PowerDirector.phase()
	if not phase then
		if present then
			present = false
			unhush()
		end
		target = nil
		return
	end
	local list = statuses(dt, phase)
	relief = math.max(0, relief - dt)

	-- the catch: an empty bar, off camera past the grace. He is behind them, and they turn around (Controllers/Death)
	for _, s in list do
		if Hunt.catches(exposure[s.player] or 1, s.filmed, offTime[s.player] or 0, C) then
			catch(s)
			return
		end
	end

	-- rule 5: nobody walks up to him. Reached: caught. Much nearer than their bar puts him: he is gone, further away
	local fled = false
	if present then
		for _, s in list do
			local p = s.root.Position
			local d = math.sqrt((p.X - x) ^ 2 + (p.Z - z) ^ 2)
			if Config.floorAt(p.X) == Config.floorAt(x) then
				if Hunt.touches(d, C) then
					catch(s)
					return
				elseif Hunt.flees(d, exposure[s.player] or 1, C) and not smashing then
					-- (not while he breaks a camera: that one is for the guard to see)
					fled = true
				end
			end
		end
	end

	-- the director's break after a catch: nowhere
	if relief > 0 then
		present = false
		target = nil
		return
	end

	-- whom he is after
	local candidates, byId = {}, {}
	for _, s in list do
		table.insert(candidates, { id = s.player.UserId, filmed = s.filmed, exposure = exposure[s.player] or 1 })
		byId[s.player.UserId] = s
	end
	local id = Hunt.target(candidates)
	local s: Status? = if id then byId[id] else nil
	if not s then
		present = false
		target = nil
		unhush()
		return
	end
	local status = s :: Status
	if target ~= status.player then
		target = status.player
		unhush(target)
		nextJump = 0
	end

	-- rule 1: a field on his cell sends him away (the camcorders see a trace where he was); rule 5 too
	local mine = Grid.at(g, x, z)
	if present and (fled or not mine or not free(mine)) then
		Net.event():FireAllClients("Vanish", x, z)
		present = false
		nextJump = 0
	end
	-- rule 6: a camera breaks in front of the guard
	if smashing then
		local sm = smashing :: { id: string, at: number }
		if os.clock() >= sm.at then
			smashing = nil
			if UnseenService.onSmash then
				UnseenService.onSmash(sm.id)
			end
			nextJump = os.clock() + C.smash_linger
		else
			nextJump = math.max(nextJump, sm.at + C.smash_linger)
		end
	elseif UnseenService.smashes > 0 and os.clock() >= nextSmash then
		local camId, cell = smashTarget(status)
		if camId and cell then
			x, z = Grid.center(g, cell)
			present = true
			smashing = { id = camId, at = os.clock() + C.smash_delay }
			UnseenService.smashes -= 1
			nextSmash = os.clock() + smashPeriod()
			nextJump = os.clock() + C.smash_delay + C.smash_linger
		elseif
			UnseenService.mode
			and UnseenService.mode.smashBlind
			and os.clock() >= nextSmash + C.smash_blind_after
		then
			-- none in front of the guard for a while: one dies out of sight (the mode's clock keeps running)
			local blind = blindTarget(status)
			if blind and UnseenService.onSmash then
				UnseenService.smashes -= 1
				UnseenService.onSmash(blind)
			end
			nextSmash = os.clock() + smashPeriod()
		end
	end
	-- another blind spot, nearer as the bar drops; soon when the guard went to another floor
	if Config.floorAt(x) ~= Config.floorAt(status.root.Position.X) and nextJump > os.clock() + 1 then
		nextJump = os.clock() + 1
	end
	if os.clock() >= nextJump then
		jump(status, list, phase)
	end
	-- he always faces his guard
	local p = status.root.Position
	yaw = math.atan2(-(p.X - x), -(p.Z - z))

	-- the hush: the guard's sound dies when he is about to come
	local hush = Hunt.shouldHush(exposure[status.player] or 1, status.filmed, C)
	if hush and not hushed[status.player] then
		hushed[status.player] = true
		Net.event():FireClient(status.player, "Hush", true)
	elseif not hush and hushed[status.player] then
		hushed[status.player] = nil
		Net.event():FireClient(status.player, "Hush", false)
	end
end

-- Studio debug: his next jump now
-- a new night: his first try at a camera comes after a while
function UnseenService.newNight()
	smashing = nil
	local mode = UnseenService.mode
	nextSmash = os.clock()
		+ (
			if mode and mode.smashEvery > 0
				then mode.smashEvery
				else C.smash_first[1] + rng.next() * (C.smash_first[2] - C.smash_first[1])
		)
end

-- Studio debug: his next try at a camera now
function UnseenService.forceSmash()
	nextSmash = 0
end

function UnseenService.forceSighting()
	nextJump = 0
end

-- whom he is after (nil when nobody)
function UnseenService.staring(): Player?
	return if present then target else nil
end

function UnseenService.position(): (boolean, number, number)
	return present, x, z
end

-- a guard's signal bar (1 full)
function UnseenService.exposureOf(player: Player): number
	return exposure[player] or 1
end

function UnseenService.start()
	while not WatchService.ready do
		task.wait(0.1)
	end
	Players.PlayerRemoving:Connect(function(player)
		hushed[player] = nil
		offTime[player] = nil
		exposure[player] = nil
		sentExposure[player] = nil
	end)
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
					Net.event():FireClient(player, "Exposure", e, e <= 0)
				end
			end
		end
	end
end

return UnseenService
