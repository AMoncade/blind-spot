--!strict
-- The lights of the power cycle (plan sections 2, 3 and 11, AtmosphereController), drawn from the night's timeline and
-- the server clock, so every player sees the same tube die at the same moment:
--   LIVE: the tubes hum, every camera shows its REC LED;
--   FLICKER: the tubes stutter (never more than 3 flashes a second; with Reduce flashes they dim instead) and only the
--     cameras that will hold keep their LED;
--   BLACKOUT: the tubes are dead; the exit signs, the booth and the holdouts' blinking LEDs are the only glows.
-- Tubes also sputter when the Unseen passes under them (plan section 4, his signs).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Level = require(script.Parent.Parent:WaitForChild("Level"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local C = Config.C

local Atmosphere = {}

Atmosphere.ready = false -- the tubes and the camera LEDs are collected (the loading screen waits for it)

local OFF_COLOR = Color3.fromRGB(70, 74, 78)
local SPUTTER_RADIUS = 9

type Tube = { part: BasePart, light: SurfaceLight, zone: string, state: number, hash: number }
type Cam = { id: string, led: BasePart, glow: PointLight?, always: boolean, state: string? }

local tubes: { Tube } = {}
local cams: { Cam } = {}
local onColor: Color3

-- a fixed pseudo-random number in [0, 1) for (a, b, c): the same on every client
local function noise(a: number, b: number, c: number): number
	local v = math.sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453
	return v - math.floor(v)
end

local function stringHash(s: string): number
	local h = 0
	for k = 1, #s do
		h = (h * 31 + string.byte(s, k)) % 1000003
	end
	return h
end

-- 1 = on, 0 = off, between = dimmed
local function setTube(t: Tube, level: number)
	if t.state == level then
		return
	end
	t.state = level
	t.light.Enabled = level > 0
	t.light.Brightness = C.tube_brightness * level
	t.part.Material = if level > 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	t.part.Color = if level > 0 then onColor:Lerp(OFF_COLOR, 1 - level) else OFF_COLOR
end

-- glow: the holdouts' LEDs light the wall around them in FLICKER and BLACKOUT, so they can be found from afar
local function setLed(cam: Cam, on: boolean, glow: boolean)
	local key = (if on then "1" else "0") .. (if glow then "1" else "0")
	if cam.state == key then
		return
	end
	cam.state = key
	cam.led.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	cam.led.Color = if on then Color3.fromRGB(Config.rgb(C.rec_color)) else Color3.fromRGB(30, 10, 10)
	if cam.glow then
		cam.glow.Enabled = on and glow
	end
end

-- a stutter step: on or off for a slot of at least flicker_min_interval seconds (3 flashes a second at most)
local function stutter(seed: number, key: number, t: number): boolean
	local slot = math.floor(t / C.flicker_min_interval)
	return noise(seed, key, slot) > 0.45
end

-- The lobby's ceiling panels (Adrien, 8 Nov: "une lumière beaucoup plus tamisée, inquiétante"): a few dead
-- (lobby_lamps_dead), a few weak ones that drop out now and then (lobby_lamps_dim; at most 3 flashes a second, a steady
-- dim glow with Reduce flashes), the rest on, pale and low. Client side: the server builds them all alike.
type Lamp = { part: BasePart, light: SurfaceLight, mood: string, hash: number, state: number }
local lamps: { Lamp } = {}

local function names(list: string): { [string]: boolean }
	local set = {}
	for _, n in string.split(list, ";") do
		if n ~= "" then
			set[n] = true
		end
	end
	return set
end

local function collectLobby()
	local lobby = workspace:WaitForChild("Lobby", 30)
	local folder = lobby and lobby:WaitForChild("Lights", 10)
	if not folder then
		return
	end
	local dead, dim = names(C.lobby_lamps_dead), names(C.lobby_lamps_dim)
	for _, p in folder:GetChildren() do
		local light = p:FindFirstChildOfClass("SurfaceLight")
		if p:IsA("BasePart") and light then
			table.insert(lamps, {
				part = p,
				light = light,
				mood = if dead[p.Name] then "dead" elseif dim[p.Name] then "dim" else "on",
				hash = stringHash(p.Name),
				state = -1,
			})
		end
	end
end

local function updateLobby()
	local reduce = Settings.get("ReduceFlashes") == true
	local t = os.clock()
	for _, lamp in lamps do
		local level = 1
		if lamp.mood == "dead" then
			level = 0
		elseif lamp.mood == "dim" then
			level = C.lobby_lamp_dim
			-- now and then it drops out for a slot (never shorter than flicker_min_interval)
			if
				not reduce
				and noise(91, lamp.hash % 13, math.floor(t / C.flicker_min_interval)) < C.lobby_lamp_dropout
			then
				level = 0
			end
		end
		if lamp.state ~= level then
			lamp.state = level
			lamp.light.Enabled = level > 0
			lamp.light.Brightness = C.lobby_lamp_brightness * level
			lamp.part.Material = if level > 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic
			lamp.part.Color = if level > 0
				then OFF_COLOR:Lerp(Color3.fromRGB(Config.rgb(C.lobby_lamp_color)), 0.35 + 0.65 * level)
				else OFF_COLOR
		end
	end
end

local function collect()
	for _, p in Level.folder("Lights"):GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("Kind") == "tube" then
			local light = p:FindFirstChildOfClass("SurfaceLight")
			if light then
				table.insert(tubes, {
					part = p,
					light = light,
					zone = p:GetAttribute("Zone") or "",
					state = -1,
					hash = stringHash(p.Name),
				})
			end
		end
	end
	for _, model in Level.folder("Cameras"):GetChildren() do
		local head = model:FindFirstChild("Head")
		local led = model:FindFirstChild("Led")
		if head and led and led:IsA("BasePart") then
			table.insert(cams, {
				id = model.Name,
				led = led,
				glow = led:FindFirstChildOfClass("PointLight"),
				always = model:GetAttribute("Always") == true,
			})
		end
	end
end

-- The base light per zone and phase (plan section 2: "Jamais un noir total"; section 7: readable without shadows on a
-- low graphics level). Local lights alone go black on a weak device or a low quality level, so the ambient carries a
-- floor of light: warm in the lobby, cold in the P3, lower in a BLACKOUT but never zero. Client side, eased.
type Grade = { ambient: Color3, outdoor: Color3, exposure: number }

local function grade(prefix: string): Grade
	local c = C :: any
	return {
		ambient = Color3.fromRGB(Config.rgb(c[prefix .. "_ambient"])),
		outdoor = Color3.fromRGB(Config.rgb(c[prefix .. "_outdoor"])),
		exposure = c[prefix .. "_exposure"],
	}
end

local GRADES: { [string]: Grade } = {}
local current: Grade? = nil

local function applyGrade(name: string, dt: number)
	local target = GRADES[name]
	if not current then
		current = { ambient = target.ambient, outdoor = target.outdoor, exposure = target.exposure }
	end
	local g = current :: Grade
	local a = math.min(1, dt / math.max(C.grade_ease_seconds, 0.01))
	g.ambient = g.ambient:Lerp(target.ambient, a)
	g.outdoor = g.outdoor:Lerp(target.outdoor, a)
	g.exposure += (target.exposure - g.exposure) * a
	Lighting.Ambient = g.ambient
	Lighting.OutdoorAmbient = g.outdoor
	-- the camcorder raises the exposure on top (Camcorder.luau); this is the base it returns to
	Lighting:SetAttribute("BaseExposure", g.exposure)
	if not Lighting:GetAttribute("CamcorderRaised") then
		Lighting.ExposureCompensation = g.exposure
	end
end

local function update(dt: number)
	if not State.shift then
		updateLobby()
	end
	local t, seg = State.now()
	local phase = if seg then seg.phase else "LIVE"
	applyGrade(
		if not State.shift
			then "lobby"
			elseif phase == "BLACKOUT" then "blackout"
			elseif phase == "FLICKER" then "flicker"
			else "live",
		dt
	)
	local holdouts: { [string]: boolean } = {}
	if seg and seg.holdouts then
		for _, id in seg.holdouts do
			holdouts[id] = true
		end
	end
	local seed = if State.night then State.night.seed % 100000 else 0
	local reduce = Settings.get("ReduceFlashes") == true
	local u = State.unseen
	local blink = math.floor(os.clock() * C.rec_blink_hz * 2) % 2 == 0

	local darkZones: { [string]: boolean } = (State.tasks and State.tasks.brokenLights) or {}
	local deadCams: { [string]: boolean } = (State.tasks and State.tasks.brokenCams) or {}
	for _, tube in tubes do
		local level = 1
		-- BLACKOUT, or a zone whose generator isn't running yet: dark
		if phase == "BLACKOUT" or (darkZones[tube.zone] and State.shift) then
			level = 0
		elseif phase == "FLICKER" then
			if reduce then
				level = C.flicker_reduced_dim
			else
				level = if stutter(seed, tube.hash % 7, t) then 1 else 0
			end
		end
		if level > 0 and u.present then
			local p = tube.part.Position
			if (p.X - u.x) ^ 2 + (p.Z - u.z) ^ 2 < SPUTTER_RADIUS * SPUTTER_RADIUS then
				if reduce then
					level = math.min(level, C.flicker_reduced_dim)
				elseif not stutter(seed + 17, tube.hash, os.clock()) then
					level = 0
				end
			end
		end
		setTube(tube, level)
	end

	for _, cam in cams do
		local on = true
		local holds = cam.always or holdouts[cam.id] == true
		if deadCams[cam.id] and State.shift then
			on = false
		elseif phase == "FLICKER" then
			on = holds
		elseif phase == "BLACKOUT" then
			on = holds and (blink or reduce)
		end
		setLed(cam, on, phase ~= "LIVE" and holds)
	end
end

function Atmosphere.start()
	GRADES.lobby = grade("lobby")
	GRADES.live = grade("p3_live")
	GRADES.flicker = grade("p3_flicker")
	GRADES.blackout = grade("p3_blackout")
	onColor = Color3.fromRGB(Config.rgb(C.tube_color))
	-- the base light at once (it used to wait for the level to stream in: the first seconds were black), the tubes
	-- and the camera LEDs as soon as they are there
	applyGrade(if State.shift then "live" else "lobby", 1)
	RunService.Heartbeat:Connect(update)
	task.spawn(collectLobby)
	collect()
	Atmosphere.ready = true
end

return Atmosphere
