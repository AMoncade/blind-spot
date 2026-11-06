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

local ServerStorage = game:GetService("ServerStorage")

local World = {}

World.root = nil :: Model?
World.lobby = nil :: Model?

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
		-- where a guard wakes up in the booth: a marker, not a SpawnLocation (everyone spawns in the lobby)
		local s = part(root, "Spawn", cf, size, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		s.Transparency = 1
		s.CanCollide = false
		s.CanQuery = false
		s.CanTouch = false
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

-- The lobby (the Halloway's ground floor at night): its shell is plain slabs from Config.LobbyMap, its furniture and
-- lifts are the Blender models kept in ServerStorage.LobbyModels (CLAUDE.md: a copy of every model stays in the place),
-- placed from Config.LobbyProps and Config.Lifts. A model in LobbyModels faces +Z and rests on its bounds' bottom.
local LOBBY_LOOK = {
	lobbyfloor = { "lobby_color_floor", Enum.Material.Marble },
	lobbyceiling = { "lobby_color_wall", Enum.Material.SmoothPlastic },
	lobbywall = { "lobby_color_wall", Enum.Material.Plaster },
	trim = { "lobby_color_trim", Enum.Material.Metal },
	street = { "street_color", Enum.Material.Asphalt },
}

-- Places a model so the bottom centre of its bounds sits at `at`, turned yaw degrees.
function World.placeModel(model: Model, at: Vector3, yaw: number)
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		return
	end
	if not model.PrimaryPart then
		model.PrimaryPart = primary :: BasePart
	end
	local box, size = model:GetBoundingBox()
	local bottom = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	local offset = bottom:ToObjectSpace((primary :: BasePart).CFrame)
	model:SetPrimaryPartCFrame(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0) * offset)
end

local function lobbyModel(name: string): Model?
	local source = ServerStorage:FindFirstChild("LobbyModels")
	local model = source and source:FindFirstChild(name)
	if model and model:IsA("Model") then
		return model:Clone()
	end
	warn(`[World] ServerStorage.LobbyModels.{name} is missing: the lobby shows a stand-in`)
	return nil
end

-- a dark sign face with lines of text: { text, height as a fraction, colour }
local function signGui(p: BasePart, lines: { { string } })
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = Enum.NormalId.Back -- +Z: toward the hall
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = gui
	for k, line in lines do
		local l = Instance.new("TextLabel")
		l.Name = "Line" .. k
		l.BackgroundTransparency = 1
		l.BorderSizePixel = 0
		l.Size = UDim2.new(0.94, 0, tonumber(line[2]) or 0.5, 0)
		l.Font = Enum.Font.GothamBold
		l.Text = line[1]
		l.TextColor3 = rgb(line[3] or "#e8e2d6")
		l.TextScaled = true
		l.LayoutOrder = k
		l.Parent = gui
	end
	gui.Parent = p
end

local function buildLobbyBlock(root: Model, folders: { [string]: Folder }, b: typeof(Config.LobbyMap[1]))
	local cf = CFrame.new(b.x, b.y, b.z)
	local size = Vector3.new(b.sx, b.sy, b.sz)
	local look = LOBBY_LOOK[b.kind]
	if look then
		part(folders.Shell, b.id, cf, size, rgb((C :: any)[look[1]]), look[2])
	elseif b.kind == "glass" then
		local p = part(folders.Shell, b.id, cf, size, rgb(C.lobby_glass_color), Enum.Material.Glass)
		p.Transparency = C.lobby_glass_transparency
		p.CastShadow = false
	elseif b.kind == "streetglow" then
		local p = part(folders.Lights, b.id, cf, size, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Front -- toward -Z: through the glass into the hall
		light.Color = rgb(C.street_glow_color)
		light.Brightness = 0.6
		light.Range = 40
		light.Angle = 70
		light.Shadows = true
		light.Parent = p
	elseif b.kind == "lobbylamp" then
		local p = part(folders.Lights, b.id, cf, size, rgb(C.lobby_lamp_color), Enum.Material.Neon)
		p.CanCollide = false
		p.CastShadow = false
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Color = rgb(C.lobby_lamp_color)
		light.Brightness = C.lobby_lamp_brightness
		light.Range = C.lobby_lamp_range
		light.Angle = 170 -- wide: the panels also wash the walls
		light.Shadows = false
		light.Parent = p
	elseif b.kind == "sign" then
		local p = part(folders.Shell, b.id, cf, size, rgb(C.lobby_color_trim), Enum.Material.Metal)
		signGui(p, { { "KESTREL & VANE", "0.62" }, { "NIGHT SECURITY  ·  THE HALLOWAY", "0.3", "#c9a46a" } })
	elseif b.kind == "lobbyspawn" then
		local s = Instance.new("SpawnLocation")
		s.Name = "LobbySpawn"
		s.Anchored = true
		s.CFrame = cf
		s.Size = size
		s.Transparency = 1
		s.CanCollide = false
		s.CanQuery = false
		s.Duration = 0
		s.Neutral = true
		s.Parent = root
	else
		warn(`[World] unknown lobby kind {b.kind} ({b.id})`)
	end
end

-- A stand-in when the Blender lift is missing: two grey doors in the opening, so the lift still works.
local function liftStandIn(lift: typeof(Config.Lifts[1])): Model
	local m = Instance.new("Model")
	m.Name = "Elevator"
	local w = C.lift_door_travel
	for k, side in { -1, 1 } do
		part(
			m,
			if k == 1 then "DoorL" else "DoorR",
			CFrame.new(lift.x + side * w / 2, 4, 117.5),
			Vector3.new(w, 8, 0.3),
			Color3.fromRGB(150, 152, 155),
			Enum.Material.Metal
		)
	end
	m.PrimaryPart = m:FindFirstChild("DoorL") :: BasePart
	return m
end

local function buildLift(parent: Folder, lift: typeof(Config.Lifts[1]))
	local m = Instance.new("Model")
	m.Name = lift.id
	m:SetAttribute("Label", lift.label)
	local zone = part(
		m,
		"Zone",
		CFrame.new(lift.x, lift.y + C.lift_zone_height / 2, lift.z),
		Vector3.new(C.lift_zone_width, C.lift_zone_height, C.lift_zone_depth),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic
	)
	zone.Transparency = 1
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false
	local display = part(
		m,
		"Display",
		CFrame.new(lift.x, C.lift_display_y, 118.12),
		Vector3.new(3.4, 1.1, 0.12),
		Color3.fromRGB(12, 12, 13),
		Enum.Material.SmoothPlastic
	)
	display.CanCollide = false
	signGui(display, { { lift.label, "0.45", "#c9a46a" }, { "P3  ·  0/" .. C.lift_capacity, "0.45", "#ff5a3c" } })
	local elevator = lobbyModel("Elevator")
	if elevator then
		World.placeModel(elevator, Vector3.new(lift.x, lift.y, lift.z + C.lift_model_dz), 0)
	else
		elevator = liftStandIn(lift)
	end
	local e = elevator :: Model
	e.Name = "Elevator"
	e.Parent = m
	m.PrimaryPart = zone
	m.Parent = parent
end

function World.buildLobby()
	local old = workspace:FindFirstChild("Lobby")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "Lobby"
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local folders = {
		Shell = folder(root, "Shell"),
		Lights = folder(root, "Lights"),
		Props = folder(root, "Props"),
		Lifts = folder(root, "Lifts"),
	}
	for _, b in Config.LobbyMap do
		buildLobbyBlock(root, folders, b)
	end
	for _, prop in Config.LobbyProps do
		local model = lobbyModel(prop.model)
		if model then
			model.Name = prop.id
			World.placeModel(model, Vector3.new(prop.x, prop.y, prop.z), prop.yaw)
			-- a street lamp's head lights the sidewalk below it
			local glow = model:FindFirstChild("LampGlow", true)
			if glow and glow:IsA("BasePart") then
				glow.Material = Enum.Material.Neon
				local light = Instance.new("SpotLight")
				light.Face = Enum.NormalId.Bottom
				light.Color = rgb(C.street_lamp_color)
				light.Brightness = C.street_lamp_brightness
				light.Range = C.street_lamp_range
				light.Angle = 100
				light.Shadows = true
				light.Parent = glow
			end
			model.Parent = folders.Props
		end
	end
	for _, lift in Config.Lifts do
		buildLift(folders.Lifts, lift)
	end
	root:SetAttribute("Lifts", #Config.Lifts)
	root.Parent = workspace
	World.lobby = root
end

function World.lobbyCFrame(): CFrame
	local root = World.lobby :: Model
	local spawn = root:FindFirstChild("LobbySpawn") :: BasePart
	return spawn.CFrame + Vector3.new(math.random(-3, 3), 3, math.random(-2, 2))
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
	World.buildLobby()
	setLighting()
end

function World.spawnCFrame(): CFrame
	local root = World.root :: Model
	local spawn = root:FindFirstChild("Spawn") :: BasePart
	return spawn.CFrame + Vector3.new(0, 3, 0)
end

return World
