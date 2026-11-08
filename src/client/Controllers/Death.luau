--!strict
-- The catch (plan section 4, "La mort" : « L'image se fige, la bande VHS déraille, une main entre dans le cadre, noir.
-- Pas de sang, pas de gore. »), on the client: a short cutscene, then the kill screen (Adrien, 8 Nov, with a picture:
-- his blank head tilted, his long clawed hands reaching from both sides, the garage's cold tubes behind, red at the
-- edges, REC, SIGNAL LOST, YOU WERE CAUGHT, RETRY and LOBBY). He has no face in chapter 1 (docs/UNSEEN.md).
--   the view whips around: his blank head, right there at the guard's eyes, lit cold from above, rimmed in red;
--   the view pushes in while his head tilts slowly, trembling more and more, his voice low;
--   the tape skips: he is bent down to the guard, both long hands reaching around their head, closer (catch_reach);
--   he grabs: the hands rush at the lens, a shriek and a boom, the view punches out and shakes, one red pulse;
--   the image freezes on his hands and his head, the tape crawls, red at the edges: SIGNAL LOST, YOU WERE CAUGHT.
-- A life left: the lives left, then black and the post (the server's Respawn after death_seconds). The night's last
-- life (the Death event says so): RETRY plays the same night again, LOBBY goes up (server NightService; after
-- retry_window everyone goes up). No blood. Reduce Flashes: no red pulse, small shakes. His models:
-- ReplicatedStorage.ClientModels.Unseen and UnseenReach (Blender, tools/blender/unseen.py), framed on their attribute
-- Eyes (where his face is from the PrimaryPart).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Settings = require(Client:WaitForChild("Settings"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local FirstPerson = require(script.Parent:WaitForChild("FirstPerson"))
local SoundDirector = require(script.Parent:WaitForChild("SoundDirector"))

local C = Config.C
local player = Players.LocalPlayer

local Death = {}

Death.final = false -- the kill screen of a lost night is up (RETRY / LOBBY): the 6 AM report stays away

local gui: ScreenGui
local black: Frame
local bars: { Frame } = {}
local pulse: Frame
local catchId = 0
local cleanup: (() -> ())? = nil -- what the current catch made in the world

type Screen = {
	root: Frame,
	rec: TextLabel,
	title: TextLabel,
	sub: TextLabel,
	lives: TextLabel,
	buttons: Frame,
	retry: TextButton,
	lobby: TextButton,
	fades: { GuiObject },
}
local screen: Screen

local INK = Color3.fromRGB(236, 232, 224)

-- a kill screen button: dark, a thin coloured edge, mono capitals (the picture's RETRY and LOBBY)
local function button(parent: Instance, name: string, text: string, edge: Color3, x: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.AutoButtonColor = false
	b.BackgroundColor3 = Color3.fromRGB(10, 8, 8)
	b.BackgroundTransparency = 0.25
	b.BorderSizePixel = 0
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.new(0.5, x, 0.5, 0)
	b.Size = UDim2.fromOffset(200, 46)
	b.FontFace = Kit.FONT.mono
	b.Text = text
	b.TextColor3 = INK
	b.TextSize = 20
	b.ZIndex = 9
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = edge
	stroke.Thickness = 2
	stroke.Parent = b
	b.Parent = parent
	return b
end

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
		bar.BackgroundTransparency = 0.7
		bar.Size = UDim2.new(1.2, 0, 0.012 + k * 0.004, 0)
		bar.Visible = false
		bar.ZIndex = 3
		bar.Parent = gui
		table.insert(bars, bar)
	end
	pulse = Instance.new("Frame")
	pulse.Name = "Pulse"
	pulse.BorderSizePixel = 0
	pulse.BackgroundColor3 = Color3.fromRGB(Config.rgb(C.rec_color))
	pulse.Size = UDim2.new(1, 0, 1, 0)
	pulse.BackgroundTransparency = 1
	pulse.ZIndex = 4
	pulse.Parent = gui

	-- the kill screen
	local root = Instance.new("Frame")
	root.Name = "Screen"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = 5
	root.Visible = false
	root.Parent = gui
	local fades: { GuiObject } = {}
	-- red at the edges over a dark vignette (the picture's red borders): four bands, each fading toward the middle
	local sides = {
		{ UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3), 90 },
		{ UDim2.fromScale(0, 0.7), UDim2.fromScale(1, 0.3), 270 },
		{ UDim2.fromScale(0, 0), UDim2.fromScale(0.22, 1), 0 },
		{ UDim2.fromScale(0.78, 0), UDim2.fromScale(0.22, 1), 180 },
	}
	for k, side in sides do
		for _, layer in
			{
				{ "Dark", Color3.new(0, 0, 0), C.kill_dark_edge },
				{ "Red", Color3.fromRGB(150, 14, 12), C.kill_red_edge },
			}
		do
			local edge = Instance.new("Frame")
			edge.Name = layer[1] .. k
			edge.BorderSizePixel = 0
			edge.BackgroundColor3 = layer[2] :: Color3
			edge.BackgroundTransparency = 0
			edge.Position = side[1] :: UDim2
			edge.Size = side[2] :: UDim2
			edge.ZIndex = 5
			local g = Instance.new("UIGradient")
			g.Rotation = side[3] :: number
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, layer[3] :: number),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = edge
			edge.Parent = root
			table.insert(fades, edge)
		end
	end
	-- the tape's lines
	for k = 1, C.kill_scanlines do
		local line = Instance.new("Frame")
		line.Name = "Scan" .. k
		line.BorderSizePixel = 0
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BackgroundTransparency = 0.82
		line.Position = UDim2.fromScale(0, (k - 0.5) / C.kill_scanlines)
		line.Size = UDim2.new(1, 0, 0, 1)
		line.ZIndex = 6
		line.Parent = root
		table.insert(fades, line)
	end
	local rec = Kit.text(root, "● REC", {
		Name = "Rec",
		FontFace = Kit.FONT.mono,
		TextColor3 = INK,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 28, 0, 20),
		Size = UDim2.new(0.3, 0, 0, 24),
		ZIndex = 8,
		Max = 22,
	})
	local dot = Instance.new("Frame") -- the red dot (a red ● in the text would take the text's colour)
	dot.Name = "Dot"
	dot.BorderSizePixel = 0
	dot.BackgroundColor3 = Color3.fromRGB(Config.rgb(C.rec_color))
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 0, 0.5, 0)
	dot.Size = UDim2.fromOffset(16, 16)
	dot.ZIndex = 9
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	dot.Parent = rec
	rec.Text = "     REC"
	local title = Kit.text(root, "SIGNAL LOST", {
		Name = "Title",
		FontFace = Kit.FONT.mono,
		TextColor3 = INK,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.73),
		Size = UDim2.new(0.8, 0, 0, 62),
		ZIndex = 8,
		Max = 60,
	})
	local sub = Kit.text(root, "YOU WERE CAUGHT", {
		Name = "Sub",
		FontFace = Kit.FONT.mono,
		TextColor3 = Color3.fromRGB(150, 145, 136),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.81),
		Size = UDim2.new(0.6, 0, 0, 24),
		ZIndex = 8,
		Max = 22,
	})
	local lives = Kit.text(root, "", {
		Name = "Lives",
		FontFace = Kit.FONT.mono,
		TextColor3 = Color3.fromRGB(Config.rgb(C.rec_color)),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.89),
		Size = UDim2.new(0.6, 0, 0, 22),
		ZIndex = 8,
		Max = 18,
	})
	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.BackgroundTransparency = 1
	buttons.AnchorPoint = Vector2.new(0.5, 0.5)
	buttons.Position = UDim2.fromScale(0.5, 0.9)
	buttons.Size = UDim2.new(1, 0, 0, 50)
	buttons.ZIndex = 8
	buttons.Visible = false
	buttons.Parent = root
	local retry = button(buttons, "Retry", "RETRY", Color3.fromRGB(Config.rgb(C.rec_color)), -120)
	local lobby = button(buttons, "Lobby", "LOBBY", Color3.fromRGB(150, 145, 136), 120)
	retry.Activated:Connect(function()
		retry.Text = "..."
		Net.send("Retry")
	end)
	lobby.Activated:Connect(function()
		lobby.Text = "..."
		Net.send("ToLobby")
	end)
	screen = {
		root = root,
		rec = rec,
		title = title,
		sub = sub,
		lives = lives,
		buttons = buttons,
		retry = retry,
		lobby = lobby,
		fades = fades,
	}

	black = Instance.new("Frame")
	black.Name = "Black"
	black.BorderSizePixel = 0
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.Size = UDim2.new(1, 0, 1, 0)
	black.BackgroundTransparency = 1
	black.ZIndex = 10
	black.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	-- REC blinks once a second while the screen is up
	RunService.RenderStepped:Connect(function()
		if root.Visible then
			dot.Visible = math.floor(os.clock() * C.rec_blink_hz * 2) % 2 == 0
		end
	end)
end

-- One of his kill models (ClientModels.Unseen, UnseenReach): a client copy, and where his face is from its
-- PrimaryPart (its attribute Eyes; a face part named Eyes on a later model with a face)
type Kill = { model: Model, primary: BasePart, eyes: Vector3, offsets: { [BasePart]: CFrame } }

local function killModel(name: string): Kill?
	local folder = ReplicatedStorage:FindFirstChild("ClientModels")
	local template = folder and folder:FindFirstChild(name)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		return nil
	end
	local m = template:Clone()
	local primary = m.PrimaryPart :: BasePart
	local offsets = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d ~= primary then
			offsets[d] = primary.CFrame:ToObjectSpace(d.CFrame)
		end
	end
	local attr = m:GetAttribute("Eyes")
	local eyesPart = m:FindFirstChild("Eyes")
	local eyes = if typeof(attr) == "Vector3"
		then attr
		elseif eyesPart and eyesPart:IsA("BasePart") then primary.CFrame:PointToObjectSpace(eyesPart.Position)
		else Vector3.new(0, primary.Size.Y * 0.44, 0)
	return { model = m, primary = primary, eyes = eyes, offsets = offsets }
end

local function place(k: Kill, cf: CFrame)
	k.primary.CFrame = cf
	for part, offset in k.offsets do
		part.CFrame = cf * offset
	end
end

-- he faces the guard (his models face their +z), his face at `target`, rolled by `tilt` radians and leaned back by
-- `pitch` radians around his face (in the hands shot his long arms then come up beside his head, as in the picture)
local function byEyes(k: Kill, target: Vector3, dir: Vector3, tilt: number, pitch: number?): CFrame
	local turn = CFrame.lookAt(Vector3.zero, dir) -- -z along dir: his +z back toward the guard
	local cf = CFrame.new(target - turn:VectorToWorldSpace(k.eyes)) * turn
	local right = dir:Cross(Vector3.new(0, 1, 0)).Unit
	return CFrame.new(target)
		* CFrame.fromAxisAngle(right, pitch or 0)
		* CFrame.fromAxisAngle(dir, tilt)
		* CFrame.new(-target)
		* cf
end

local function ease(a: number): number
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

local function between(t: number, from: number, length: number): number
	return math.clamp((t - from) / math.max(length, 0.01), 0, 1)
end

-- the tape crawls over the frozen image (motion, not flashes)
local function tear(id: number)
	for _, bar in bars do
		bar.Visible = true
	end
	local t0 = os.clock()
	while catchId == id and gui.Enabled do
		for k, bar in bars do
			local y = ((os.clock() - t0) * (0.06 + k * 0.025) + k * 0.17) % 1
			bar.Position = UDim2.new(-0.1 + math.random() * 0.03, 0, y, 0)
		end
		task.wait(1 / 15)
	end
end

-- the tape skips for a moment (the cut to his reach): bars across, then gone
local function skip(id: number)
	for k, bar in bars do
		bar.Visible = true
		bar.Position = UDim2.new(-0.1 + math.random() * 0.06, 0, (k * 0.17 + math.random() * 0.1) % 1, 0)
	end
	task.delay(C.catch_skip, function()
		if catchId == id then
			for _, bar in bars do
				bar.Visible = false
			end
		end
	end)
end

-- the kill screen comes in over the frozen image
local function showScreen(final: boolean, livesLeft: number)
	local s = screen
	s.root.Visible = true
	s.buttons.Visible = final
	s.retry.Text = "RETRY"
	s.lobby.Text = "LOBBY"
	s.lives.Visible = not final
	s.lives.Text = if livesLeft <= 0
		then "DOWN  ·  A TEAMMATE CAN BRING YOUR BADGE BACK"
		elseif livesLeft == 1 then "1 LIFE LEFT  ·  BACK AT THE POST"
		else `{livesLeft} LIVES LEFT  ·  BACK AT THE POST`
	local info = TweenInfo.new(C.kill_fade)
	for _, f in s.fades do
		local target = f:GetAttribute("Alpha")
		if target == nil then
			f:SetAttribute("Alpha", f.BackgroundTransparency)
			target = f.BackgroundTransparency
		end
		f.BackgroundTransparency = 1
		TweenService:Create(f, info, { BackgroundTransparency = target }):Play()
	end
	for _, l in { s.rec, s.title, s.sub, s.lives } do
		l.TextTransparency = 1
		TweenService:Create(l, info, { TextTransparency = 0 }):Play()
	end
	for _, b in { s.retry, s.lobby } do
		b.TextTransparency = 1
		b.BackgroundTransparency = 1
		TweenService:Create(b, info, { TextTransparency = 0, BackgroundTransparency = 0.25 }):Play()
	end
end

-- back to the game: the screen down, the camera to the guard
local function reset()
	catchId += 1
	if cleanup then
		cleanup()
		cleanup = nil
	end
	Death.final = false
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	FirstPerson.frozen = false
	for _, bar in bars do
		bar.Visible = false
	end
	screen.root.Visible = false
	pulse.BackgroundTransparency = 1
end

local function catch(seconds: number, ux: number?, uz: number?, final: boolean, livesLeft: number)
	if cleanup then
		cleanup()
		cleanup = nil
	end
	catchId += 1
	local id = catchId
	local camera = workspace.CurrentCamera
	FirstPerson.frozen = true
	Death.final = final
	camera.CameraType = Enum.CameraType.Scriptable
	gui.Enabled = true
	black.BackgroundTransparency = 1
	pulse.BackgroundTransparency = 1
	screen.root.Visible = false
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
	local up = Vector3.new(0, 1, 0)
	local right = dir:Cross(up).Unit
	local stand = killModel("Unseen")
	local reach = killModel("UnseenReach")
	local function faceAt(distance: number, rise: number): Vector3
		return eye + dir * distance + up * rise
	end
	if stand then
		place(stand, byEyes(stand, faceAt(C.catch_face_distance, C.catch_face_rise), dir, 0))
		stand.model.Parent = camera
	end

	-- the look of the picture: the garage's cold tubes above him, red behind his hands
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "Catch"
	grade.TintColor = Color3.fromRGB(Config.rgb(C.catch_tint))
	grade.Contrast = C.catch_contrast
	grade.Saturation = C.catch_saturation
	grade.Parent = Lighting
	local blur = Instance.new("BlurEffect")
	blur.Name = "CatchBlur"
	blur.Size = C.catch_blur
	blur.Parent = Lighting
	local lights: { Attachment } = {}
	local function light(color: string, brightness: number, range: number): Attachment
		local a = Instance.new("Attachment")
		a.Name = "CatchLight"
		a.Parent = workspace.Terrain
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(Config.rgb(color))
		l.Brightness = brightness
		l.Range = range
		l.Shadows = false
		l.Parent = a
		table.insert(lights, a)
		return a
	end
	local key = light(C.catch_light_color, C.catch_light_brightness, C.catch_light_range)
	local rimL = light(C.rec_color, C.catch_rim_brightness, C.catch_light_range * 0.7)
	local rimR = light(C.rec_color, C.catch_rim_brightness, C.catch_light_range * 0.7)
	local function lightAround(face: Vector3)
		key.WorldPosition = face + up * 2.6 - dir * 1.2
		rimL.WorldPosition = face - right * 2.4 + dir * 0.6 - up * 0.8
		rimR.WorldPosition = face + right * 2.4 + dir * 0.6 - up * 0.8
	end

	cleanup = function()
		if stand then
			stand.model:Destroy()
			stand = nil
		end
		if reach then
			reach.model:Destroy()
			reach = nil
		end
		grade:Destroy()
		blur:Destroy()
		for _, a in lights do
			a:Destroy()
		end
		camera.FieldOfView = fov0
	end

	local calm = Settings.get("ReduceFlashes") == true
	local t0 = os.clock()
	local voiced, reached, grabbed, frozen = false, false, false, false
	local grabAt = 0
	SoundDirector.play("catch_whoosh")
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if catchId ~= id then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		if t < C.catch_reach then
			-- his blank head at the guard's eyes: the whip, then the push-in while his head tilts
			local push = ease(between(t, C.catch_turn, C.catch_reach - C.catch_turn))
			local face = faceAt(C.catch_face_distance - C.catch_push * push, C.catch_face_rise)
			if stand then
				place(stand, byEyes(stand, face, dir, math.rad(C.catch_tilt) * push))
			end
			lightAround(face)
			if not voiced and t >= C.catch_turn + 0.2 then
				voiced = true
				SoundDirector.play("catch_vocal")
			end
			local shake = CFrame.identity
			if t >= C.catch_turn then
				local amount = (if calm then 0.25 else 1) * C.catch_tremble * (0.3 + 0.7 * push)
				shake = CFrame.Angles(
					math.rad(math.noise(t * 14, 1) * amount),
					math.rad(math.noise(t * 14, 2) * amount),
					math.rad(math.noise(t * 9, 3) * amount * 0.5)
				)
			end
			local a = ease(between(t, 0, C.catch_turn))
			camera.CFrame = start:Lerp(CFrame.lookAt(eye, face), a) * shake
			blur.Size = C.catch_blur * (1 - a)
			camera.FieldOfView = fov0 + (C.catch_fov - fov0) * push
		elseif t < C.catch_grab then
			-- the tape skips: he is bent down to the guard, both hands reaching around their head, closer
			if not reached then
				reached = true
				skip(id)
				blur.Size = C.catch_blur * 0.8
				TweenService:Create(blur, TweenInfo.new(0.3), { Size = 0 }):Play()
				if stand then
					stand.model:Destroy()
					stand = nil
				end
				if reach then
					reach.model.Parent = camera
				end
				SoundDirector.play("catch_vocal")
			end
			local a = ease(between(t, C.catch_reach, C.catch_grab - C.catch_reach))
			local face = faceAt(C.catch_reach_from + (C.catch_reach_to - C.catch_reach_from) * a, C.catch_reach_rise)
			if reach then
				place(reach, byEyes(reach, face, dir, math.rad(C.catch_reach_tilt), math.rad(C.catch_pitch)))
			end
			lightAround(face)
			local amount = (if calm then 0.25 else 1) * C.catch_tremble * (1 + a)
			local shake = CFrame.Angles(
				math.rad(math.noise(t * 16, 4) * amount),
				math.rad(math.noise(t * 16, 5) * amount),
				math.rad(math.noise(t * 11, 6) * amount * 0.5)
			)
			camera.CFrame = CFrame.lookAt(eye, eye + dir + up * C.catch_aim_up) * shake
			camera.FieldOfView = C.catch_fov + (C.catch_reach_fov - C.catch_fov) * ease(between(t, C.catch_reach, 0.5))
		elseif t < C.catch_freeze then
			-- he grabs: the hands rush at the lens, a shriek and a boom, the view punches out and shakes hard
			if not grabbed then
				grabbed = true
				grabAt = t
				SoundDirector.play("catch_shriek")
				SoundDirector.play("catch_boom")
				blur.Size = C.catch_blur * 0.8
				if not calm then
					pulse.BackgroundTransparency = 0.5 -- one red pulse (well under 3 flashes a second)
					TweenService:Create(pulse, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
				end
				TweenService:Create(blur, TweenInfo.new(0.3), { Size = 0 }):Play()
			end
			local since = t - grabAt
			local a = math.clamp(since / C.catch_rush, 0, 1)
			local face = faceAt(C.catch_reach_to + (C.catch_grab_to - C.catch_reach_to) * (a * a), C.catch_reach_rise)
			if reach then
				place(reach, byEyes(reach, face, dir, math.rad(C.catch_reach_tilt), math.rad(C.catch_pitch)))
			end
			lightAround(face)
			camera.FieldOfView = C.catch_punch_fov
				+ (C.catch_freeze_fov - C.catch_punch_fov) * math.min(1, since / (C.catch_freeze - C.catch_grab))
			local hard = (if calm then 0.3 else 1) * C.catch_hit_shake * math.max(0, 1 - since / 0.4)
			local shake = CFrame.Angles(
				math.rad((math.random() * 2 - 1) * hard),
				math.rad((math.random() * 2 - 1) * hard),
				math.rad((math.random() * 2 - 1) * hard * 0.6)
			)
			camera.CFrame = CFrame.lookAt(eye, eye + dir + up * C.catch_aim_up) * shake
		elseif not frozen then
			-- the image freezes on his hands and his head, the tape crawls: the kill screen
			frozen = true
			blur.Size = 0
			camera.FieldOfView = C.catch_freeze_fov
			camera.CFrame = CFrame.lookAt(eye, eye + dir + up * C.catch_aim_up)
			SoundDirector.play("tear")
			task.spawn(tear, id)
			task.delay(C.catch_screen - C.catch_freeze, function()
				if catchId == id then
					showScreen(final, livesLeft)
				end
			end)
			if not final then
				-- a life left: black, then the post (the server's Respawn)
				task.delay(math.max(0, seconds - C.catch_freeze - C.kill_black), function()
					if catchId == id then
						TweenService:Create(black, TweenInfo.new(C.kill_black), { BackgroundTransparency = 0 }):Play()
					end
				end)
			end
			conn:Disconnect()
		end
	end)
end

function Death.start()
	build()
	State.on("Death", function(seconds: number, ux: number?, uz: number?, final: boolean?, livesLeft: number?)
		catch(seconds, ux, uz, final == true, livesLeft or 0)
	end)
	State.on("Respawn", function()
		reset()
		-- awake at the post, looking straight ahead (not up where he was)
		local camera = workspace.CurrentCamera
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local at = root.Position + Vector3.new(0, 1.5, 0)
			camera.CFrame = CFrame.lookAt(at, at + root.CFrame.LookVector)
		end
		TweenService:Create(black, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		task.delay(0.8, function()
			if not State.dead then
				gui.Enabled = false
			end
		end)
	end)
	-- co-op, down: the booth's cameras (Watcher) take over the view
	State.on("Down", function()
		reset()
		TweenService:Create(black, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		task.delay(0.6, function()
			if not State.dead then
				gui.Enabled = false
			end
		end)
	end)
	-- RETRY (a new shift) or LOBBY (the shift is over): the kill screen goes
	State.on("Shift", function()
		if gui.Enabled then
			reset()
			black.BackgroundTransparency = 1
			gui.Enabled = false
		end
	end)
end

return Death
