--!strict
-- The P3 grey box (plan section 12, phase 0: "le P3 en blocs gris"), built from Config.Map at server start, plus the
-- security cameras from Config.Cameras, the task spots from Config.Spots and the lighting from Config.C.
-- Parts are allowed here only because this is the grey version (CLAUDE.md, "Blender d'abord"): the final art replaces
-- each kind with Blender MeshParts and keeps these boxes as invisible collisions.
--
-- What the clients read:
--   workspace.P3.Lights: tubes (Kind = "tube", Zone), the booth lamp (Kind = "post"), exit signs (Kind = "exit")
--   workspace.P3.Cameras.<Id>: Model with Head (turns, has the LED) and attributes Id, Zone, Always
--   workspace.P3.Spots.<Id>: the task spots with their ProximityPrompt (TaskService answers them)
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Watch = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Logic"):WaitForChild("Watch"))

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
	floor = "p3_floor_color",
	ceiling = "p3_ceiling_color",
	wall = "p3_wall_color",
	pillar = "grey_pillar",
	car = "grey_car",
	desk = "grey_desk",
	-- stand-ins until their Blender model is in ServerStorage.LevelModels
	crates = "grey_desk",
	boiler = "grey_pillar",
	plaster = "plaster_color",
	firedoor = "grey_car",
	elevator = "grey_car",
	deskmodel = "grey_desk",
	bench = "grey_desk",
	couch = "grey_car",
}

-- kinds drawn by a Blender model from ServerStorage.LevelModels (a missing model falls back to the grey box)
local MODEL_FOR: { [string]: string } = {
	pillar = "Pillar",
	car = "Sedan",
	crates = "Crates",
	boiler = "Boiler",
	plaster = "PlasterWall",
	firedoor = "FireDoor",
	elevator = "Lobby:Elevator",
	deskmodel = "Lobby:SecurityDesk",
	bench = "Workbench",
	couch = "Couch",
}

-- the floor a world position is on (content/floors.csv: each floor is moved along x), and its offset
World.floorAt = Config.floorAt

local function levelModel(name: string): Model?
	local folderName = "LevelModels"
	if string.sub(name, 1, 6) == "Lobby:" then
		folderName, name = "LobbyModels", string.sub(name, 7)
	end
	local source = ServerStorage:FindFirstChild(folderName)
	local model = source and source:FindFirstChild(name)
	if model and model:IsA("Model") then
		return model:Clone()
	end
	return nil
end

local function stringHash(s: string): number
	local h = 0
	for k = 1, #s do
		h = (h * 31 + string.byte(s, k)) % 1000003
	end
	return h
end

local OSWALD = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)

-- painted text on a surface: a transparent carrier part whose +Z face (Back) holds the text
local function paint(
	parent: Instance,
	name: string,
	cf: CFrame,
	w: number,
	h: number,
	text: string,
	color: Color3,
	alpha: number
)
	local p = part(parent, name, cf, Vector3.new(w, h, 0.05), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 1
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Size = UDim2.fromScale(1, 1)
	l.FontFace = OSWALD
	l.Text = text
	l.TextColor3 = color
	l.TextTransparency = alpha
	l.TextScaled = true
	l.Parent = gui
	gui.Parent = p
end

-- the pillar's painted name (P3 · S1) on its four faces
local function pillarLabel(parent: Instance, b: typeof(Config.Map[1]), cf: CFrame, size: Vector3)
	local row = string.match(b.id, "Pillar(%a)") or ""
	local name = (if b.floor ~= "" then b.floor else "P3") .. " · " .. row .. (string.match(b.id, "%d+$") or "")
	for k = 0, 3 do
		local face = cf * CFrame.Angles(0, math.rad(90 * k), 0) * CFrame.new(0, 1.2, size.Z / 2 + 0.03)
		paint(parent, b.id .. "Label" .. k, face, 2.2, 0.9, name, rgb("#1c1c1c"), 0.1)
	end
end

local function buildBlock(root: Model, folders: { [string]: Folder }, b: typeof(Config.Map[1]))
	local cf = CFrame.new(b.x, b.y, b.z)
	local size = Vector3.new(b.sx, b.sy, b.sz)
	local colorKey = GEOMETRY_COLOR[b.kind]
	local modelName = MODEL_FOR[b.kind]
	local model = modelName and levelModel(modelName)
	if model then
		-- the Blender model stands where the box was; the box stays as its invisible collision and camera blocker
		local p = part(folders.Geometry, b.id, cf, size, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p.CastShadow = false
		p:SetAttribute("Kind", b.kind)
		local index = tonumber(string.match(b.id, "%d+$")) or 0
		local yaw = b.yaw
		if b.kind == "car" then
			-- nose in or nose out; a car across the aisle (wider than long) turns a quarter
			yaw = (if (index + #b.id) % 2 == 0 then 180 else 0) + (if b.sx > b.sz then 90 else 0)
		end
		if Watch.DYNAMIC[b.kind] ~= nil then
			-- a fire door or the plaster: DoorService moves it and its collision with its state
			p:SetAttribute("Dynamic", true)
			p.CanCollide = Watch.DYNAMIC[b.kind]
			model:SetAttribute("Block", b.id)
		end
		World.placeModel(model, Vector3.new(b.x, b.y - b.sy / 2, b.z), yaw)
		if b.kind == "car" then
			local color = rgb(Config.CarColors[(stringHash(b.id) % #Config.CarColors) + 1])
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and (d.Name == "Body" or d.Name == "Roof") then
					d.Color = color
				end
			end
		elseif b.kind == "pillar" then
			pillarLabel(folders.Dressing, b, cf, size)
		end
		model.Name = b.id
		model.Parent = folders.Dressing
	elseif b.kind == "pipes" then
		local runs = levelModel("PipeRun")
		if runs then
			World.placeModel(runs, Vector3.new(b.x, b.y, b.z), 90)
			runs.Name = b.id
			runs.Parent = folders.Dressing
		end
	elseif b.kind == "stalls" or b.kind == "dash" then
		local p = part(
			folders.Dressing,
			b.id,
			cf,
			size,
			rgb(if b.kind == "stalls" then C.stall_line_color else C.dash_color),
			Enum.Material.SmoothPlastic
		)
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = false
		p.Transparency = 0.15
	elseif b.kind == "band" then
		-- the painted lower band of a wall, with its yellow line on top
		local p = part(folders.Dressing, b.id, cf, size, rgb(C.p3_band_color), Enum.Material.Concrete)
		p.CanCollide = false
		p.CanQuery = false
		local line = part(
			folders.Dressing,
			b.id .. "Line",
			cf * CFrame.new(0, b.sy / 2 + 0.12, 0),
			Vector3.new(b.sx, 0.24, b.sz),
			rgb(C.p3_band_line_color),
			Enum.Material.SmoothPlastic
		)
		line.CanCollide = false
		line.CanQuery = false
	elseif colorKey then
		local p = part(folders.Geometry, b.id, cf, size, rgb((C :: any)[colorKey]), Enum.Material.Concrete)
		p:SetAttribute("Kind", b.kind)
		if Watch.DYNAMIC[b.kind] ~= nil then
			p:SetAttribute("Dynamic", true)
			p.CanCollide = Watch.DYNAMIC[b.kind]
		end
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
		-- light zones per floor: P3:corridor, P2:west... (a task's effect can darken one: lights:P3:corridor)
		local floor, offset = World.floorAt(b.x)
		p:SetAttribute(
			"Zone",
			floor .. ":" .. (if b.z < -32 then "corridor" elseif b.x - offset < 0 then "west" else "east")
		)
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
	elseif b.kind == "hidden" then
		-- an invisible collision under a Blender model (generator, locker): it also stops camera rays
		local p = part(folders.Geometry, b.id, cf, size, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p.CastShadow = false
	elseif b.kind == "spawn" then
		-- where a guard wakes up in the booth: a marker, not a SpawnLocation (everyone spawns in the lobby)
		local s = part(root, b.id, cf, size, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
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
		aim * CFrame.new(0.28, 0.36, -0.8),
		Vector3.one * C.rec_led_size,
		rgb(C.rec_color),
		Enum.Material.Neon
	)
	led.Shape = Enum.PartType.Ball
	led.CanCollide = false
	led.CastShadow = false
	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Color = rgb(C.rec_color)
	glow.Range = C.rec_glow_range
	glow.Brightness = C.rec_glow_brightness
	glow.Shadows = false
	glow.Enabled = false -- the client lights it on the cameras that hold (Atmosphere)
	glow.Parent = led
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

-- The task spots (Config.Spots): the Blender model of their kind from ServerStorage.LevelModels when it is there
-- (bottom centre on the spot, turned by yaw; a model faces +Z), else a stand-in box. Each spot has an invisible
-- Anchor with the ProximityPrompt TaskService drives. Parts of a carried item have the attribute Item.
local SPOT_LOOK: { [string]: { model: string, size: Vector3, color: Color3, item: boolean } } = {
	checkpoint = {
		model = "Checkpoint",
		size = Vector3.new(1, 1.6, 0.35),
		color = Color3.fromRGB(60, 70, 64),
		item = false,
	},
	fuelcan = { model = "FuelCan", size = Vector3.new(1.2, 1.6, 0.8), color = Color3.fromRGB(170, 30, 24), item = true },
	generator = {
		model = "Generator",
		size = Vector3.new(5, 3.5, 2.4),
		color = Color3.fromRGB(70, 82, 60),
		item = false,
	},
	locker = { model = "Locker", size = Vector3.new(2.4, 7, 1.6), color = Color3.fromRGB(80, 86, 92), item = false },
	fusebox = {
		model = "FuseBox",
		size = Vector3.new(1.6, 2, 0.5),
		color = Color3.fromRGB(150, 150, 140),
		item = false,
	},
	stairs = { model = "StairDoor", size = Vector3.new(4, 8, 0.4), color = Color3.fromRGB(70, 76, 82), item = false },
	breakers = {
		model = "BreakerPanel",
		size = Vector3.new(4, 6, 0.8),
		color = Color3.fromRGB(120, 124, 120),
		item = false,
	},
	hammer = {
		model = "Sledgehammer",
		size = Vector3.new(2.6, 0.3, 0.5),
		color = Color3.fromRGB(90, 60, 40),
		item = true,
	},
	plaster = { model = "", size = Vector3.new(0.4, 0.4, 0.4), color = Color3.new(1, 1, 1), item = false },
	sealed = { model = "", size = Vector3.new(0.4, 0.4, 0.4), color = Color3.new(1, 1, 1), item = false },
	tape = { model = "VHSTape", size = Vector3.new(0.9, 0.2, 0.55), color = Color3.fromRGB(20, 20, 22), item = true },
	vcr = { model = "VCR", size = Vector3.new(2, 0.5, 1.5), color = Color3.fromRGB(30, 30, 32), item = false },
	collect = { model = "VHSTape", size = Vector3.new(0.9, 0.2, 0.55), color = Color3.fromRGB(20, 20, 22), item = true },
	logbook = {
		model = "LogBookModel",
		size = Vector3.new(1.3, 0.25, 1),
		color = Color3.fromRGB(30, 40, 70),
		item = false,
	},
	junction = {
		model = "FuseBox",
		size = Vector3.new(1.6, 2, 0.5),
		color = Color3.fromRGB(150, 150, 140),
		item = false,
	},
	signin = {
		model = "SignInBook",
		size = Vector3.new(1.2, 0.2, 0.9),
		color = Color3.fromRGB(90, 22, 18),
		item = false,
	},
}

local function buildSpot(parent: Folder, spot: typeof(Config.Spots[1]))
	local look = SPOT_LOOK[spot.kind]
	if not look then
		warn(`[World] unknown spot kind {spot.kind} ({spot.id})`)
		return
	end
	local m = Instance.new("Model")
	m.Name = spot.id
	m:SetAttribute("Kind", spot.kind)
	m:SetAttribute("Label", spot.label)
	local base = CFrame.new(spot.x, spot.y, spot.z) * CFrame.Angles(0, math.rad(spot.yaw), 0)
	local source = ServerStorage:FindFirstChild("LevelModels")
	local model = source and source:FindFirstChild(look.model)
	local height = look.size.Y
	if model and model:IsA("Model") then
		local clone = model:Clone()
		World.placeModel(clone, Vector3.new(spot.x, spot.y, spot.z), spot.yaw)
		height = clone:GetExtentsSize().Y
		for _, d in clone:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				if look.item then
					d:SetAttribute("Item", true)
					d:SetAttribute("BaseTransparency", d.Transparency)
					d.CanCollide = false
				end
			end
		end
		clone.Name = "Model"
		clone.Parent = m
	elseif look.model ~= "" then
		local p =
			part(m, "StandIn", base * CFrame.new(0, look.size.Y / 2, 0), look.size, look.color, Enum.Material.Metal)
		if look.item then
			p:SetAttribute("Item", true)
			p:SetAttribute("BaseTransparency", 0)
			p.CanCollide = false
		end
	end
	local anchor = part(
		m,
		"Anchor",
		base * CFrame.new(0, math.min(height, 4) / 2 + 0.2, 0.6),
		Vector3.new(0.4, 0.4, 0.4),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic
	)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = spot.label
	prompt.ActionText = "Use"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = anchor
	-- the camera a fuse box or a junction box feeds, painted on its label frame
	local camNumber = string.match(spot.label, "C(%d%d)")
	if camNumber and (spot.kind == "fusebox" or spot.kind == "junction") then
		paint(m, "CamLabel", base * CFrame.new(0, 0.59, 0.27), 1.0, 0.3, "CAM " .. camNumber, rgb("#1c1c1c"), 0)
	end
	m.PrimaryPart = anchor
	m.Parent = parent
end

-- A spot added during the night (a cut line's junction box, TaskService). Same shape as a Config.Spots row.
function World.addSpot(spot: any): Model
	local root = World.root :: Model
	local spots = root:FindFirstChild("Spots") :: Folder
	local old = spots:FindFirstChild(spot.id)
	if old then
		old:Destroy()
	end
	buildSpot(spots, spot)
	return spots:FindFirstChild(spot.id) :: Model
end

function World.removeSpot(id: string)
	local root = World.root :: Model
	local spots = root:FindFirstChild("Spots")
	local old = spots and spots:FindFirstChild(id)
	if old then
		old:Destroy()
	end
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
		l.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
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
		Dressing = folder(root, "Dressing"),
	}
	for _, b in Config.Map do
		buildBlock(root, folders, b)
	end
	for _, s in Config.Signs do
		local cf = CFrame.new(s.x, s.y, s.z) * CFrame.Angles(0, math.rad(s.yaw), 0)
		if s.flat then
			cf *= CFrame.Angles(math.rad(-90), 0, 0) -- lying on the floor, text up
		end
		paint(folders.Dressing, s.id, cf, s.w, s.h, s.text, rgb(s.color), s.alpha)
	end
	-- the floor's stall numbers, at the aisle end of each stall
	local stall = 0
	for _, b in Config.Map do
		if b.kind == "stalls" then
			local nextX = b.x + C.stall_width
			if nextX <= C.grid_origin_x + C.grid_width * C.grid_cell then
				stall += 1
				local side = if b.z > 0 then -1 else 1
				local cf = CFrame.new(b.x + C.stall_width / 2, 0.03, b.z + side * (b.sz / 2 - 1.6))
					* CFrame.Angles(0, if side < 0 then math.rad(180) else 0, 0) -- read from the aisle
					* CFrame.Angles(math.rad(-90), 0, 0)
				paint(
					folders.Dressing,
					"Stall" .. stall,
					cf,
					3,
					1.6,
					string.format("%02d", stall),
					rgb(C.stall_line_color),
					0.3
				)
			end
		end
	end
	local cams = folder(root, "Cameras")
	for _, cam in Config.Cameras do
		buildCamera(cams, cam)
	end
	local spots = folder(root, "Spots")
	for _, spot in Config.Spots do
		buildSpot(spots, spot)
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
	local spawn = root:FindFirstChild(C.spawn_marker) :: BasePart
	return spawn.CFrame + Vector3.new(0, 3, 0)
end

return World
