--!strict
-- The catch (plan section 4, "La mort" : « L'image se fige, la bande VHS déraille, une main entre dans le cadre, noir.
-- Pas de sang, pas de gore. »), on the client, timed by the catch_* constants inside death_seconds:
--   the view snaps around to where he is (catch_turn);
--   he stands right there, too tall, his head bent over you; the view does a slow dolly zoom (the garage stretches
--     behind him, he doesn't move) and trembles a little;
--   at catch_lunge he lunges, both long arms out (his second Blender pose), and a hand comes into the frame;
--   the image freezes and loses its colour, the tape tears (bars that slide, never a flash), SIGNAL LOST, black;
--   the server wakes the guard at the post after death_seconds (or makes them a watcher in co-op).
-- Reduce Flashes: no tremble. His models: ReplicatedStorage.ClientModels.Unseen and UnseenLunge (without them, the
-- tape tear alone).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Settings = require(Client:WaitForChild("Settings"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local FirstPerson = require(script.Parent:WaitForChild("FirstPerson"))

local C = Config.C
local player = Players.LocalPlayer

local Death = {}

local gui: ScreenGui
local black: Frame
local lost: TextLabel
local bars: { Frame } = {}
local catchId = 0

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "Death"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Enabled = false
	for k = 1, 6 do
		local bar = Instance.new("Frame")
		bar.Name = "Tear" .. k
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		bar.BackgroundTransparency = 0.55
		bar.Size = UDim2.new(1.2, 0, 0.02 + k * 0.006, 0)
		bar.Visible = false
		bar.Parent = gui
		table.insert(bars, bar)
	end
	black = Instance.new("Frame")
	black.Name = "Black"
	black.BorderSizePixel = 0
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.Size = UDim2.new(1, 0, 1, 0)
	black.BackgroundTransparency = 1
	black.ZIndex = 5
	black.Parent = gui
	lost = Kit.text(gui, "SIGNAL LOST", {
		Name = "Lost",
		FontFace = Kit.FONT.mono,
		TextColor3 = Color3.fromRGB(Config.rgb(C.rec_color)),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0, 44),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Max = 40,
	})
	gui.Parent = player:WaitForChild("PlayerGui")
end

-- a client copy of one of his models, and where its PrimaryPart sits from the bottom centre of its bounds
local function model(name: string): (Model?, CFrame?)
	local folder = ReplicatedStorage:FindFirstChild("ClientModels")
	local template = folder and folder:FindFirstChild(name)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		return nil, nil
	end
	local m = template:Clone()
	local cf, size = m:GetBoundingBox()
	return m, (cf * CFrame.new(0, -size.Y / 2, 0)):ToObjectSpace((m.PrimaryPart :: BasePart).CFrame)
end

-- his model standing at `feet` (on the floor), facing the point `toward`, pushed `forward` studs along his facing
local function place(m: Model, offset: CFrame, feet: Vector3, toward: Vector3, forward: number)
	local flat = Vector3.new(toward.X, feet.Y, toward.Z)
	local base = CFrame.lookAt(feet, flat) * CFrame.new(0, 0, -forward)
	-- the models face their +z, a CFrame looks along its -z: half a turn
	m:SetPrimaryPartCFrame(base * CFrame.Angles(0, math.pi, 0) * offset)
end

local function ease(a: number): number
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

local function tear(seconds: number, id: number)
	for _, bar in bars do
		bar.Visible = true
	end
	local t0 = os.clock()
	while os.clock() - t0 < seconds and catchId == id and State.dead do
		for k, bar in bars do
			-- the tear slides down and jitters sideways: motion, not flashes
			local y = ((os.clock() - t0) * (0.25 + k * 0.07) + k * 0.17) % 1
			bar.Position = UDim2.new(-0.1 + math.random() * 0.06, 0, y, 0)
		end
		task.wait(1 / 15)
	end
end

local function catch(seconds: number, ux: number?, uz: number?)
	catchId += 1
	local id = catchId
	local camera = workspace.CurrentCamera
	FirstPerson.frozen = true
	camera.CameraType = Enum.CameraType.Scriptable
	gui.Enabled = true
	black.BackgroundTransparency = 1
	lost.TextTransparency = 1
	for _, bar in bars do
		bar.Visible = false
	end

	local start = camera.CFrame
	local eye = start.Position
	local fov0 = camera.FieldOfView
	-- where he comes from: his position (same floor, close), else straight ahead
	local look = Vector3.new(start.LookVector.X, 0, start.LookVector.Z)
	local dir = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	if ux and uz then
		local to = Vector3.new(ux - eye.X, 0, uz - eye.Z)
		if to.Magnitude > 0.5 and to.Magnitude < C.catch_max_distance then
			dir = to.Unit
		end
	end
	local floor = C.floor_y
	local feet = Vector3.new(eye.X, floor, eye.Z) + dir * C.catch_distance
	local head = feet + Vector3.new(0, C.unseen_height * 0.86, 0) - dir * 0.6
	local stand, standOffset = model("Unseen")
	local lunge, lungeOffset = model("UnseenLunge")
	if stand and standOffset then
		place(stand, standOffset, feet, eye, 0)
		stand.Parent = camera
	end
	-- the room loses its colour once the image freezes
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "Catch"
	grade.Parent = Lighting
	-- a dim cold light on him, so he reads in the dark garage
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(Config.rgb(C.catch_light_color))
	glow.Brightness = C.catch_light_brightness
	glow.Range = C.catch_light_range
	glow.Shadows = false
	local holder = Instance.new("Attachment")
	holder.Name = "CatchLight"
	holder.WorldPosition = eye + Vector3.new(0, 1, 0)
	holder.Parent = workspace.Terrain
	glow.Parent = holder

	local turned = CFrame.lookAt(eye, head)
	local backAway = -dir * C.catch_dolly
	local calm = Settings.get("ReduceFlashes") == true
	local t0 = os.clock()
	local lunged = false
	local frozen = false
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if catchId ~= id then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		if t < C.catch_turn then
			-- the view snaps around to him
			camera.CFrame = start:Lerp(turned, ease(t / C.catch_turn))
		elseif t < C.catch_lunge then
			-- he stands there; the dolly zoom: back away while narrowing the view, he keeps his size
			local a = ease((t - C.catch_turn) / (C.catch_lunge - C.catch_turn))
			local from = eye + backAway * a
			local shake = if calm
				then CFrame.identity
				else CFrame.Angles(math.rad(math.noise(t * 7, 1) * 0.8), math.rad(math.noise(t * 7, 2) * 0.8), 0)
			camera.CFrame = CFrame.lookAt(from, head) * shake
			camera.FieldOfView = fov0 + (C.catch_fov - fov0) * a
		elseif t < C.catch_freeze then
			-- he lunges: the second pose, his hands come right into the frame
			if not lunged then
				lunged = true
				if stand then
					stand:Destroy()
					stand = nil
				end
				if lunge and lungeOffset then
					lunge.Parent = camera
				end
				camera.FieldOfView = fov0
			end
			local a = ease((t - C.catch_lunge) / (C.catch_freeze - C.catch_lunge))
			-- he ends with his hands a hand's breadth from the view (catch_reach: his bounds' centre from the eye)
			local reach = Vector3.new(eye.X, floor, eye.Z) + dir * (C.catch_reach + C.catch_lunge_from)
			if lunge and lungeOffset then
				place(lunge, lungeOffset, reach, eye, C.catch_lunge_from * a)
			end
			local aim = Vector3.new(eye.X, floor + C.catch_aim_height, eye.Z) + dir * C.catch_reach
			camera.CFrame = CFrame.lookAt(eye + backAway, aim)
		elseif not frozen then
			-- the image freezes, the colour goes, the tape tears
			frozen = true
			TweenService:Create(grade, TweenInfo.new(0.25), { Saturation = -1, Contrast = 0.35 }):Play()
			task.spawn(tear, seconds - C.catch_freeze, id)
			TweenService:Create(black, TweenInfo.new(C.catch_black, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 0,
			}):Play()
			task.delay(C.catch_black * 0.6, function()
				if catchId == id then
					TweenService:Create(lost, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
				end
			end)
		end
	end)
	-- the end: the server's Respawn (or Down) takes over; clean up what the catch made
	task.delay(seconds + 0.2, function()
		if catchId ~= id then
			return
		end
		conn:Disconnect()
		if stand then
			stand:Destroy()
		end
		if lunge then
			lunge:Destroy()
		end
		grade:Destroy()
		holder:Destroy()
		camera.FieldOfView = fov0
	end)
end

function Death.start()
	build()
	State.on("Death", function(seconds: number, ux: number?, uz: number?)
		catch(seconds, ux, uz)
	end)
	State.on("Respawn", function()
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		FirstPerson.frozen = false
		for _, bar in bars do
			bar.Visible = false
		end
		-- awake at the post, looking straight ahead (not up where he was)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local at = root.Position + Vector3.new(0, 1.5, 0)
			camera.CFrame = CFrame.lookAt(at, at + root.CFrame.LookVector)
		end
		TweenService:Create(black, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lost, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.delay(0.8, function()
			if not State.dead then
				gui.Enabled = false
			end
		end)
	end)
end

return Death
