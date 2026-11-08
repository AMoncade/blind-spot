--!strict
-- The guard's skills (Adrien, 7 Nov: "que ce soit pas juste toujours attendre ta barre qui se reset"). Each is a
-- choice about the dark, not a way out of the rules:
--   SPRINT: a short burst of speed (sprint_multiplier; how long and how often: the SPRINT upgrade) to cross a blind
--     zone before the bar empties;
--   FLARE: a road flare dropped a few steps ahead. While it burns it is a camera: the floor it lights (flare_radius,
--     what it can see) counts as filmed for everyone (the bar fills back up there, he can't stand in it), so a guard
--     can make a safe island in a blind spot to work in. How many a night and how long they burn: the FLARES upgrade.
-- The server decides: the client only asks (action Skill), on shift and alive; each guard learns what they have left
-- (event Skills).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Logic = Shared:WaitForChild("Logic")
local Grid = require(Logic:WaitForChild("Grid"))
local Watch = require(Logic:WaitForChild("Watch"))

local Server = script.Parent.Parent
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local WatchService = require(script.Parent:WaitForChild("WatchService"))
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local Upgrades = require(Logic:WaitForChild("Upgrades"))

local C = Config.C

local SkillService = {}

SkillService.mode = nil :: any -- the shift's mode (NightService): SPRINT locked, extra flares

SkillService.isPlaying = nil :: ((player: Player) -> boolean)? -- NightService: on shift and alive

local flaresLeft: { [Player]: number } = {}
local sprintReady: { [Player]: number } = {} -- os.clock() when SPRINT can go again
local lit: { [string]: Instance } = {} -- the flares burning: their id -> their model
local nextId = 0

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- what this guard's levels give: SPRINT (burst, cooldown) and FLARES (a night, burn seconds)
local function sprintOf(player: Player): (number, number)
	local burst, cooldown = Upgrades.value(Config.upgradeById.sprint, Upgrades.level(Data.get(player), "sprint"))
	return burst, cooldown or 20
end

local function flaresOf(player: Player): (number, number)
	local count, burn = Upgrades.value(Config.upgradeById.flares, Upgrades.level(Data.get(player), "flares"))
	-- the mode's extra flares (EASY: one more)
	return count + (if SkillService.mode then SkillService.mode.flares else 0), burn or 20
end

-- SPRINT is locked in HARD and NIGHTMARE (content/modes.csv)
local function sprintLocked(): boolean
	return SkillService.mode ~= nil and not SkillService.mode.sprint
end

local function send(player: Player)
	Net.event():FireClient(player, "Skills", {
		flares = flaresLeft[player] or 0,
		flareMax = (flaresOf(player)),
		sprintReady = workspace:GetServerTimeNow() + math.max(0, (sprintReady[player] or 0) - os.clock()),
		sprintCooldown = select(2, sprintOf(player)),
		sprintLocked = sprintLocked(),
	})
end

local function sprint(player: Player)
	if sprintLocked() then
		return
	end
	local now = os.clock()
	if now < (sprintReady[player] or 0) then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local burst, cooldown = sprintOf(player)
	sprintReady[player] = now + cooldown
	humanoid.WalkSpeed = C.player_walk_speed * C.sprint_multiplier
	task.delay(burst, function()
		if humanoid.Parent and humanoid.WalkSpeed > C.player_walk_speed then
			humanoid.WalkSpeed = C.player_walk_speed
		end
	end)
	send(player)
end

-- the floor a flare lights: the open cells within flare_radius it can see (a pillar still casts its shadow)
local function flareCells(x: number, z: number): Watch.Set
	local g = WatchService.grid
	local cells: Watch.Set = {}
	local y = C.floor_y + 1
	for _, i in Grid.near(g, x, z, C.flare_radius) do
		if not g.blocked[i] then
			local cx, cz = Grid.center(g, i)
			if not Grid.segmentHits(WatchService.level.occluders, x, y, z, cx, y, cz) then
				cells[i] = true
			end
		end
	end
	return cells
end

-- what burns: the flare itself (Blender model), its red light, sparks and smoke, and the disc of floor it keeps safe
local function flareModel(at: Vector3, yaw: number): Model
	local folder = workspace:FindFirstChild("Flares") or Instance.new("Folder")
	folder.Name = "Flares"
	folder.Parent = workspace
	local source = ServerStorage:FindFirstChild("LevelModels")
	local template = source and source:FindFirstChild("Flare")
	local m: Model
	if template and template:IsA("Model") then
		m = template:Clone()
		World.placeModel(m, at, yaw)
	else
		m = Instance.new("Model")
		local p = Instance.new("Part")
		p.Name = "Tip"
		p.Size = Vector3.new(1.4, 0.25, 0.25)
		p.CFrame = CFrame.new(at + Vector3.new(0, 0.13, 0))
		p.Color = Color3.fromRGB(160, 20, 15)
		p.Anchored = true
		p.CanCollide = false
		p.Parent = m
		m.PrimaryPart = p
	end
	m.Name = "Flare"
	local tip = (m:FindFirstChild("Tip", true) or m.PrimaryPart) :: BasePart
	tip.Material = Enum.Material.Neon
	tip.Color = Color3.fromRGB(Config.rgb(C.flare_color))
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(Config.rgb(C.flare_color))
	light.Brightness = C.flare_brightness
	light.Range = C.flare_radius * 1.6
	light.Shadows = true
	light.Parent = tip
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 200, 150), Color3.fromRGB(255, 60, 40))
	sparks.LightEmission = 1
	sparks.Rate = 40
	sparks.Lifetime = NumberRange.new(0.3, 0.7)
	sparks.Speed = NumberRange.new(4, 9)
	sparks.SpreadAngle = Vector2.new(35, 35)
	sparks.Acceleration = Vector3.new(0, -18, 0)
	sparks.Size = NumberSequence.new(0.12, 0)
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Parent = tip
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Color = ColorSequence.new(Color3.fromRGB(150, 70, 70))
	smoke.Rate = 6
	smoke.Lifetime = NumberRange.new(2, 3)
	smoke.Speed = NumberRange.new(1, 2)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 3) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = tip
	-- the safe floor, as a faint red disc (the safe zones of the cameras are drawn by the clients)
	local disc = Instance.new("Part")
	disc.Name = "Safe"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.05, C.flare_radius * 2, C.flare_radius * 2)
	disc.CFrame = CFrame.new(at.X, C.floor_y + C.zone_height + 0.01, at.Z) * CFrame.Angles(0, 0, math.rad(90))
	disc.Material = Enum.Material.Neon
	disc.Color = Color3.fromRGB(Config.rgb(C.flare_color))
	disc.Transparency = C.flare_disc_alpha
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc.CastShadow = false
	disc.Parent = m
	m.Parent = folder
	return m
end

local function flare(player: Player)
	if (flaresLeft[player] or 0) <= 0 then
		Net.event():FireClient(player, "Notice", "NO FLARES LEFT", false)
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
	-- a few steps ahead, unless a wall is there: then at the guard's feet
	local g = WatchService.grid
	local at = root.Position + flat * C.flare_throw
	local i = Grid.at(g, at.X, at.Z)
	if
		not i
		or g.blocked[i]
		or Grid.segmentHits(
			WatchService.level.occluders,
			root.Position.X,
			C.floor_y + 1,
			root.Position.Z,
			at.X,
			C.floor_y + 1,
			at.Z
		)
	then
		at = root.Position
	end
	flaresLeft[player] -= 1
	nextId += 1
	local id = "flare" .. nextId
	local spot = Vector3.new(at.X, C.floor_y, at.Z)
	local model = flareModel(spot, math.deg(math.atan2(flat.X, flat.Z)))
	lit[id] = model
	WatchService.setExtra(id, flareCells(spot.X, spot.Z))
	send(player)
	local _, burn = flaresOf(player)
	task.delay(burn, function()
		if lit[id] ~= model then
			return
		end
		lit[id] = nil
		WatchService.setExtra(id, nil)
		-- it gutters out
		for _, d in model:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				d.Enabled = false
			elseif d:IsA("PointLight") then
				TweenService:Create(d, TweenInfo.new(1), { Brightness = 0 }):Play()
			elseif d:IsA("BasePart") and d.Name == "Safe" then
				TweenService:Create(d, TweenInfo.new(1), { Transparency = 1 }):Play()
			end
		end
		task.delay(2.5, function()
			model:Destroy()
		end)
	end)
end

-- a new night: every guard's flares and SPRINT ready; no flare left burning
function SkillService.reset(guards: { Player })
	SkillService.clear()
	for _, player in guards do
		flaresLeft[player] = (flaresOf(player))
		sprintReady[player] = 0
		send(player)
	end
end

function SkillService.clear()
	for id, model in lit do
		WatchService.setExtra(id, nil)
		model:Destroy()
	end
	table.clear(lit)
end

function SkillService.init()
	Actions.on("Skill", function(player: Player, name: unknown)
		if not SkillService.isPlaying or not SkillService.isPlaying(player) then
			return
		end
		if name == "sprint" then
			sprint(player)
		elseif name == "flare" then
			flare(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		flaresLeft[player] = nil
		sprintReady[player] = nil
	end)
end

return SkillService
