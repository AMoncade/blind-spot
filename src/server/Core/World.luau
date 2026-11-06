--!strict
-- The P3 grey box (plan section 12, phase 0: "le P3 en blocs gris"), built from Config.Map at server start, plus the
-- security cameras from Config.Cameras, the round checkpoints from Config.Rounds and the lighting from Config.C.
-- Parts are allowed here only because this is the grey version (CLAUDE.md, "Blender d'abord"): the final art replaces
-- each kind with Blender MeshParts and keeps these boxes as invisible collisions.
--
-- What the clients read:
--   workspace.P3.Lights: tubes (Kind = "tube", Zone), the booth lamp (Kind = "post"), exit signs (Kind = "exit")
--   workspace.P3.Cameras.<Id>: Model with Head (turns, has the LED) and attributes Id, Zone, Always
--   workspace.P3.Rounds.<Id>: the checkpoint parts with their ProximityPrompt (NightService answers them)
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local C = Config.C

local World = {}

World.root = nil :: Model?

local function rgb(hex: string): Color3
	return Color3.fromRGB(Config.rgb(hex))
end

local function part(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local GEOMETRY_COLOR = {
	floor = "grey_concrete",
	ceiling = "grey_concrete",
	wall = "grey_concrete",
	pillar = "grey_pillar",
	car = "grey_car",
	desk = "grey_desk",
}

local function buildBlock(root: Model, folders: { [string]: Folder }, b: typeof(Config.Map[1]))
	local cf = CFrame.new(b.x, b.y, b.z)
	local size = Vector3.new(b.sx, b.sy, b.sz)
	local colorKey = GEOMETRY_COLOR[b.kind]
	if colorKey then
		local p = part(folders.Geometry, b.id, cf, size, rgb((C :: any)[colorKey]), Enum.Material.Concrete)
		p:SetAttribute("Kind", b.kind)
		if b.kind == "car" then
			p.Material = Enum.Material.SmoothPlastic
		elseif b.kind == "floor" or b.kind == "ceiling" then
			p.CastShadow = b.kind == "ceiling"
		end
	elseif b.kind == "tube" then
		local p = part(folders.Lights, b.id, cf, size, rgb(C.tube_color), Enum.Material.Neon)
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = false
		p:SetAttribute("Kind", "tube")
		p:SetAttribute("Zone", if b.z < -32 then "corridor" elseif b.x < 0 then "west" else "east")
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Color = rgb(C.tube_color)
		light.Brightness = C.tube_brightness
		light.Range = C.tube_range
		light.Angle = C.tube_angle
		light.Shadows = false -- plan section 7: tubes are shadowless SurfaceLights
		light.Parent = p
	elseif b.kind == "post" then
		local p = part(folders.Lights, b.id, cf, size, rgb(C.post_color), Enum.Material.Neon)
		p.CanCollide = false
		p.CastShadow = false
		p:SetAttribute("Kind", "post")
		local light = Instance.new("PointLight")
		light.Color = rgb(C.post_color)
		light.Brightness = C.post_brightness
		light.Range = C.post_range
		light.Shadows = true
		light.Parent = p
	elseif b.kind == "exit" then
		local p = part(folders.Lights, b.id, cf, size, rgb(C.exit_color), Enum.Material.Neon)
		p.CanCollide = false
		p.CastShadow = false
		p:SetAttribute("Kind", "exit")
		local light = Instance.new("PointLight")
		light.Color = rgb(C.exit_color)
		light.Brightness = C.exit_brightness
		light.Range = C.exit_range
		light.Shadows = false
		light.Parent = p
	elseif b.kind == "spawn" then
		local s = Instance.new("SpawnLocation")
		s.Name = "Spawn"
		s.Anchored = true
		s.CFrame = cf
		s.Size = size
		s.Transparency = 1
		s.CanCollide = false
		s.Duration = 0
		s.Neutral = true
		s.Parent = root
	else
		warn(`[World] unknown map kind {b.kind} ({b.id})`)
	end
end

local function buildCamera(parent: Folder, cam: typeof(Config.Cameras[1]))
	local model = Instance.new("Model")
	model.Name = cam.id
	model:SetAttribute("Id", cam.id)
	model:SetAttribute("Zone", cam.zone)
	model:SetAttribute("Always", cam.always)
	local pos = Vector3.new(cam.x, cam.y, cam.z)
	local aim = CFrame.lookAt(pos, Vector3.new(cam.tx, cam.ty, cam.tz))
	local dark = Color3.fromRGB(28, 30, 33)
	local mount = part(
		model,
		"Mount",
		CFrame.new(cam.x, cam.y + 0.6, cam.z),
		Vector3.new(0.4, 1.2, 0.4),
		dark,
		Enum.Material.Metal
	)
	mount.CanCollide = false
	local head =
		part(model, "Head", aim, Vector3.new(0.8, 0.8, 1.8), Color3.fromRGB(205, 208, 210), Enum.Material.SmoothPlastic)
	head.CanCollide = false
	head.CanQuery = false
	local lens =
		part(model, "Lens", aim * CFrame.new(0, 0, -0.92), Vector3.new(0.55, 0.55, 0.06), dark, Enum.Material.Glass)
	lens.CanCollide = false
	local led = part(
		model,
		"Led",
		aim * CFrame.new(0.28, 0.32, -0.8),
		Vector3.new(0.12, 0.12, 0.12),
		rgb(C.rec_color),
		Enum.Material.Neon
	)
	led.Shape = Enum.PartType.Ball
	led.CanCollide = false
	led.CastShadow = false
	-- the lens and the LED hang on the head, so a client turning the head turns them too
	for _, p in { lens, led } do
		p.Anchored = false
		p.CanQuery = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = p
		weld.Parent = p
	end
	model:SetAttribute("RestAim", aim)
	model.PrimaryPart = head
	model.Parent = parent
end

local function buildRound(parent: Folder, round: typeof(Config.Rounds[1]))
	-- a wall checkpoint box with a scan prompt; NightService answers the prompt
	local p = part(
		parent,
		round.id,
		CFrame.new(round.x, round.y, round.z),
		Vector3.new(1, 1.6, 1),
		Color3.fromRGB(60, 70, 64),
		Enum.Material.Metal
	)
	p:SetAttribute("Label", round.label)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Scan"
	prompt.ObjectText = round.label
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = p
end

local function setLighting()
	Lighting.Ambient = rgb(C.lighting_ambient)
	Lighting.OutdoorAmbient = rgb(C.lighting_outdoor)
	Lighting.Brightness = C.lighting_brightness
	Lighting.ExposureCompensation = C.lighting_exposure
	Lighting.EnvironmentSpecularScale = C.lighting_specular
	Lighting.EnvironmentDiffuseScale = C.lighting_diffuse
	Lighting.ClockTime = 0
	Lighting.GlobalShadows = true
	-- the template's sky effects don't belong underground; our grading replaces them (plan section 7)
	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "Grade"
	grade.TintColor = rgb(C.grade_tint)
	grade.Saturation = C.grade_saturation
	grade.Contrast = C.grade_contrast
	grade.Brightness = C.grade_brightness
	grade.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "Bloom"
	bloom.Intensity = C.bloom_intensity
	bloom.Size = C.bloom_size
	bloom.Threshold = C.bloom_threshold
	bloom.Parent = Lighting
end

function World.init()
	local old = workspace:FindFirstChild("P3")
	if old then
		old:Destroy()
	end
	-- the template baseplate would z-fight with the P3 floor (both tops at y = 0)
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "P3"
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local folders = {
		Geometry = folder(root, "Geometry"),
		Lights = folder(root, "Lights"),
	}
	for _, b in Config.Map do
		buildBlock(root, folders, b)
	end
	local cams = folder(root, "Cameras")
	for _, cam in Config.Cameras do
		buildCamera(cams, cam)
	end
	local rounds = folder(root, "Rounds")
	for _, round in Config.Rounds do
		buildRound(rounds, round)
	end
	-- the clients wait for every light and camera to stream in before they wire them (StreamingEnabled)
	root:SetAttribute("Lights", #folders.Lights:GetChildren())
	root:SetAttribute("Cameras", #cams:GetChildren())
	root.Parent = workspace
	World.root = root
	setLighting()
end

function World.spawnCFrame(): CFrame
	local root = World.root :: Model
	local spawn = root:FindFirstChild("Spawn") :: BasePart
	return spawn.CFrame + Vector3.new(0, 3, 0)
end

return World
