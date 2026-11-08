--!strict
-- The catch (plan section 4, "La mort" : « L'image se fige, la bande VHS déraille, une main entre dans le cadre, noir.
-- Pas de sang, pas de gore. »), on the client: a short cutscene (Adrien, 8 Nov: "qu'on ait vraiment la face du
-- monstre dans l'écran, puis ses mains, presque une cutscene de plusieurs secondes"). In play he has no face (he stays
-- a mystery); only here does it come out of his blank head: the eyes push out of their hollows, a grin tears open and
-- the jaw drops. Then he reaches for the guard with both hands, grabs, and the tape dies. Timed by the catch_*
-- constants inside death_seconds (see catch below); the server wakes the guard at the post after death_seconds (or
-- makes them a watcher in co-op). No blood. Reduce Flashes: no red pulse, small shakes. His models:
-- ReplicatedStorage.ClientModels.UnseenCatch and UnseenReach (Blender, tools/blender/unseen.py; without them the
-- faceless Unseen, or the rest alone).
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
local SoundDirector = require(script.Parent:WaitForChild("SoundDirector"))

local C = Config.C
local player = Players.LocalPlayer

local Death = {}

local gui: ScreenGui
local black: Frame
local lost: TextLabel
local bars: { Frame } = {}
local pulse: Frame
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
	pulse = Instance.new("Frame")
	pulse.Name = "Pulse"
	pulse.BorderSizePixel = 0
	pulse.BackgroundColor3 = Color3.fromRGB(Config.rgb(C.rec_color))
	pulse.Size = UDim2.new(1, 0, 1, 0)
	pulse.BackgroundTransparency = 1
	pulse.ZIndex = 4
	pulse.Parent = gui
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

-- One of his kill models (ClientModels.UnseenCatch, UnseenReach): a client copy, its face parts and where they sit
-- from its PrimaryPart, and where his eyes are (the shots are framed on them). Without the face parts, the body alone.
type Kill = {
	model: Model,
	primary: BasePart,
	eyes: Vector3,
	parts: { [string]: BasePart },
	offsets: { [string]: CFrame },
	sizes: { [string]: Vector3 },
}

local function killModel(name: string, fallback: string?): Kill?
	local folder = ReplicatedStorage:FindFirstChild("ClientModels")
	local template = folder and (folder:FindFirstChild(name) or (fallback and folder:FindFirstChild(fallback)))
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		return nil
	end
	local m = template:Clone()
	local primary = m.PrimaryPart :: BasePart
	local parts, offsets, sizes = {}, {}, {}
	for _, d in m:GetChildren() do
		if d:IsA("BasePart") and d ~= primary then
			parts[d.Name] = d
			offsets[d.Name] = primary.CFrame:ToObjectSpace(d.CFrame)
			sizes[d.Name] = d.Size
		end
	end
	local eyes = parts.Eyes
	local at = if eyes
		then primary.CFrame:PointToObjectSpace(eyes.Position)
		else primary.CFrame:PointToObjectSpace(primary.Position + Vector3.new(0, primary.Size.Y * 0.4, 0))
	return { model = m, primary = primary, eyes = at, parts = parts, offsets = offsets, sizes = sizes }
end

-- he faces the guard (his models face their +z), his eyes at `target`
local function byEyes(k: Kill, target: Vector3, dir: Vector3): CFrame
	local turn = CFrame.lookAt(Vector3.zero, dir) -- -z along dir: his +z back toward the guard
	return CFrame.new(target - turn:VectorToWorldSpace(k.eyes)) * turn
end

-- His face coming out of the blank head (Adrien, 8 Nov: "des yeux lui sortent, une bouche, on la voit s'ouvrir"):
-- sockets 0..1 the hollows darken in; eyes 0..1 they push out of them and then glow; mouth 0..1 the grin tears open
-- from the middle; open 0..1 the jaw drops and the needles chatter.
local function pose(k: Kill, cf: CFrame, sockets: number, eyes: number, mouth: number, open: number, t: number)
	k.primary.CFrame = cf
	local p = k.parts
	for name, part in p do
		local base = cf * k.offsets[name]
		if name == "Sockets" then
			part.CFrame = base
			part.Transparency = 1 - sockets
		elseif name == "Eyes" then
			part.CFrame = base * CFrame.new(0, 0, -C.catch_eye_depth * (1 - eyes))
			part.Transparency = if eyes > 0 then math.max(0, 1 - eyes * 3) else 1
			part.Material = if eyes >= 0.7 then Enum.Material.Neon else Enum.Material.SmoothPlastic
		elseif name == "Mouth" then
			part.CFrame = base * CFrame.new(0, -C.catch_jaw * 0.45 * open, 0)
			part.Size = k.sizes.Mouth * Vector3.new(math.max(mouth, 0.02), 1 + C.catch_mouth_stretch * open, 1)
			part.Transparency = if mouth > 0 then 0 else 1
		elseif name == "TeethTop" or name == "TeethBottom" then
			local chatter = if open > 0.4 then math.sin(t * 34) * C.catch_chatter * open else 0
			local dy = if name == "TeethTop" then C.catch_jaw * 0.15 * open else -(C.catch_jaw * open + chatter)
			part.CFrame = base * CFrame.new(0, dy, 0)
			part.Size = k.sizes[name] * Vector3.new(math.max(mouth, 0.02), 1, 1)
			part.Transparency = if mouth > 0.2 then 0 else 1
		else
			part.CFrame = base
		end
	end
end

local function ease(a: number): number
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

local function between(t: number, from: number, length: number): number
	return math.clamp((t - from) / math.max(length, 0.01), 0, 1)
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

-- The catch, a short cutscene timed by the catch_* constants inside death_seconds:
--   the view whips around: his blank face, right there at the guard's eyes, lit from below and rimmed in red;
--   the view pushes in; the hollows of his eyes darken in, two pale eyes push out of them and glow (catch_eyes);
--   a grin tears open across his face, the jaw drops, the needles chatter, his voice (catch_mouth);
--   the tape skips: he is leaning in, both long hands reaching around the guard's head, closer (catch_reach);
--   he grabs: the hands rush past the lens, a shriek and a boom, the view punches out and shakes, one red pulse
--     (catch_grab);
--   the image freezes in black and white, the tape tears, SIGNAL LOST, black (catch_freeze).
local function catch(seconds: number, ux: number?, uz: number?)
	catchId += 1
	local id = catchId
	local camera = workspace.CurrentCamera
	FirstPerson.frozen = true
	camera.CameraType = Enum.CameraType.Scriptable
	gui.Enabled = true
	black.BackgroundTransparency = 1
	pulse.BackgroundTransparency = 1
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
	local up = Vector3.new(0, 1, 0)
	local stand = killModel("UnseenCatch", "Unseen")
	local reach = killModel("UnseenReach")
	local function faceAt(distance: number): Vector3
		return eye + dir * distance + up * C.catch_face_rise
	end
	if stand then
		pose(stand, byEyes(stand, faceAt(C.catch_face_distance), dir), 0, 0, 0, 0, 0)
		stand.model.Parent = camera
	end

	-- the look of it: colder and harder, a blur for the whip and the hit
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "Catch"
	grade.TintColor = Color3.fromRGB(Config.rgb(C.catch_tint))
	grade.Contrast = C.catch_contrast
	grade.Saturation = -0.35
	grade.Parent = Lighting
	local blur = Instance.new("BlurEffect")
	blur.Name = "CatchBlur"
	blur.Size = C.catch_blur
	blur.Parent = Lighting
	-- lit from below (a cold key from the guard's chest) and rimmed in red from behind his head
	local holder = Instance.new("Attachment")
	holder.Name = "CatchLight"
	holder.WorldPosition = eye - up + dir * 0.6
	holder.Parent = workspace.Terrain
	local key = Instance.new("PointLight")
	key.Color = Color3.fromRGB(Config.rgb(C.catch_light_color))
	key.Brightness = C.catch_light_brightness
	key.Range = C.catch_light_range
	key.Shadows = false
	key.Parent = holder
	local rimAt = Instance.new("Attachment")
	rimAt.Name = "CatchRim"
	rimAt.Parent = workspace.Terrain
	local rim = Instance.new("PointLight")
	rim.Color = Color3.fromRGB(Config.rgb(C.rec_color))
	rim.Brightness = C.catch_rim_brightness
	rim.Range = C.catch_light_range
	rim.Shadows = false
	rim.Parent = rimAt

	local calm = Settings.get("ReduceFlashes") == true
	local t0 = os.clock()
	local seenEyes, seenMouth, reached, grabbed, frozen = false, false, false, false, false
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
			-- his face: the whip, then the push-in while the eyes come out and the grin opens
			local push = ease(between(t, C.catch_turn, C.catch_reach - C.catch_turn))
			local distance = C.catch_face_distance - C.catch_push * push
			local face = faceAt(distance)
			local sockets = ease(between(t, C.catch_eyes, C.catch_emerge * 0.6))
			local eyes = ease(between(t, C.catch_eyes + C.catch_emerge * 0.35, C.catch_emerge))
			local mouth = ease(between(t, C.catch_mouth, C.catch_emerge))
			local open =
				ease(between(t, C.catch_mouth + C.catch_emerge, C.catch_reach - C.catch_mouth - C.catch_emerge))
			if stand then
				pose(stand, byEyes(stand, face, dir), sockets, eyes, mouth, open, t)
			end
			rimAt.WorldPosition = face + dir * 1.8 + up * 1.2
			if not seenEyes and t >= C.catch_eyes + C.catch_emerge * 0.35 then
				seenEyes = true
				SoundDirector.play("catch_vocal")
			end
			if not seenMouth and t >= C.catch_mouth then
				seenMouth = true
				SoundDirector.play("catch_whoosh")
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
			local turned = CFrame.lookAt(eye, face)
			local a = ease(between(t, 0, C.catch_turn))
			camera.CFrame = start:Lerp(turned, a) * shake
			blur.Size = C.catch_blur * (1 - a)
			camera.FieldOfView = fov0 + (C.catch_fov - fov0) * push
		elseif t < C.catch_grab then
			-- the tape skips: he leans in, both hands reaching around the guard's head, closer and closer
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
			local distance = C.catch_reach_from + (C.catch_reach_to - C.catch_reach_from) * a
			-- his face a little above the guard's: his hands (far ahead of it, lower) come at them in the frame
			local face = eye + dir * distance + up * C.catch_reach_rise
			if reach then
				pose(reach, byEyes(reach, face, dir), 1, 1, 1, 1, t)
			end
			rimAt.WorldPosition = face + dir * 1.8 + up * 1.2
			local amount = (if calm then 0.25 else 1) * C.catch_tremble * (1 + a)
			local shake = CFrame.Angles(
				math.rad(math.noise(t * 16, 4) * amount),
				math.rad(math.noise(t * 16, 5) * amount),
				math.rad(math.noise(t * 11, 6) * amount * 0.5)
			)
			camera.CFrame = CFrame.lookAt(eye, eye + dir) * shake
			camera.FieldOfView = C.catch_fov + (C.catch_reach_fov - C.catch_fov) * ease(between(t, C.catch_reach, 0.5))
		elseif t < C.catch_freeze then
			-- he grabs: the hands rush past the lens, a shriek and a boom, the view punches out and shakes hard
			if not grabbed then
				grabbed = true
				grabAt = t
				SoundDirector.play("catch_shriek")
				SoundDirector.play("catch_boom")
				blur.Size = C.catch_blur * 1.2
				if not calm then
					pulse.BackgroundTransparency = 0.45 -- one red pulse (well under 3 flashes a second)
					TweenService:Create(pulse, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
				end
				TweenService:Create(blur, TweenInfo.new(0.35), { Size = 4 }):Play()
			end
			local since = t - grabAt
			local a = math.clamp(since / C.catch_rush, 0, 1)
			local distance = C.catch_reach_to + (C.catch_grab_to - C.catch_reach_to) * (a * a)
			local face = eye + dir * distance + up * C.catch_reach_rise
			if reach then
				pose(reach, byEyes(reach, face, dir), 1, 1, 1, 1, t)
			end
			camera.FieldOfView = C.catch_punch_fov + (C.catch_reach_fov - C.catch_punch_fov) * math.min(1, since / 0.25)
			local hard = (if calm then 0.3 else 1) * C.catch_hit_shake * math.max(0, 1 - since / 0.4)
			local shake = CFrame.Angles(
				math.rad((math.random() * 2 - 1) * hard),
				math.rad((math.random() * 2 - 1) * hard),
				math.rad((math.random() * 2 - 1) * hard * 0.6)
			)
			-- the view lifts to his face as the hands rush past the lens
			camera.CFrame = CFrame.lookAt(eye, (eye + dir * 3):Lerp(face, 0.7 * a)) * shake
		elseif not frozen then
			-- the image freezes in black and white, the tape tears
			frozen = true
			SoundDirector.play("tear")
			blur.Size = 0
			TweenService:Create(grade, TweenInfo.new(0.2), { Saturation = -1, Contrast = 0.55 }):Play()
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
			stand.model:Destroy()
		end
		if reach then
			reach.model:Destroy()
		end
		grade:Destroy()
		blur:Destroy()
		holder:Destroy()
		rimAt:Destroy()
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
