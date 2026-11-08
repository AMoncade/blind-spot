--!strict
-- The loading screen (Adrien, 7 Nov: "les lumières sont noires au début puis s'allument : mets un loading screen").
-- It covers the game from the first frame the client runs until what the first minute needs is there: the lobby and
-- the floors streamed in, the lights collected (Atmosphere.ready), the Unseen's models, the UI art, the sounds, and the
-- guard's profile. At least loading_min seconds (no flash), at most loading_max (it never blocks the game). Then it
-- fades out. A tip from the night shift turns under the bar.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local C = Config.C
local player = Players.LocalPlayer

local Loading = {}

local TIPS = {
	"Stay where a camera can see you.",
	"When the lights stutter, look for the red lights that stay on.",
	"Your signal bar drains in the dark. Under a camera it fills back up.",
	"He never walks. He is just closer every time you look.",
	"Through the camcorder, he is not there.",
	"A flare is a camera you drop on the floor.",
	"K&V SUPPLY, east of the hall: upgrades for your nerve, your legs, your camcorder and your flares.",
}

-- ---------------------------------------------------------------- the descent

-- Adrien, 8 Nov: "un loading screen dans le vibe du jeu, inquiétant, qui charge la map : sinon quand t'arrives y a
-- pas de lumière et tu vois les assets qui load". The lift goes down: a dark tape screen covers the ride and the
-- arrival (the garage's photo barely there behind tracking lines, the floors counting down, a whisper) until the
-- level is ready: the night's state in, the lights set, its meshes and textures loaded. At least shift_loading_min
-- seconds from the arrival, at most shift_loading_max. No flash: the glitches only shift the text.
Loading.covering = false -- a loading screen is over the game (the night's title waits for it)
local waiting: { () -> () } = {}

-- run fn once nothing covers the screen
function Loading.whenClear(fn: () -> ())
	if Loading.covering then
		table.insert(waiting, fn)
	else
		task.spawn(fn)
	end
end

local function release()
	Loading.covering = false
	local list = table.clone(waiting)
	table.clear(waiting)
	for _, fn in list do
		task.spawn(fn)
	end
end

local WHISPERS = {
	"Someone worked this shift before you.",
	"Don't stay where the cameras can't see you.",
	"He is closer every time you look.",
	"The lift never stops at P2. Tonight it might.",
	"Count the cameras. Then count them again.",
	"The tapes from last night are missing.",
}

type Descent = {
	gui: ScreenGui,
	back: Frame,
	photo: ImageLabel,
	title: TextLabel,
	sub: TextLabel,
	whisper: TextLabel,
	rec: TextLabel,
	fill: Frame,
	track: Frame,
	lines: { Frame },
}
local descent: Descent? = nil
local shownAt = 0
local token = 0 -- a newer descent or arrival cancels the older one

local function buildDescent(): Descent
	local gui = Kit.new("ScreenGui", {
		Name = "Descent",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 99,
		Enabled = false,
	}) :: ScreenGui
	local back = Kit.new("Frame", {
		Name = "Back",
		BackgroundColor3 = Color3.fromRGB(3, 4, 4),
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		Parent = gui,
	}) :: Frame
	-- the garage, barely there, drifting closer
	local photo = Kit.image(back, (Kit.ART :: any).MapHalloway or "", {
		Name = "Photo",
		ScaleType = Enum.ScaleType.Crop,
		ImageColor3 = Color3.fromRGB(70, 84, 78),
		ImageTransparency = C.descent_photo_alpha,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.1, 1.1),
	})
	-- tracking lines rolling down the tape
	local lines = {}
	for k = 1, 3 do
		lines[k] = Kit.new("Frame", {
			Name = "Track" .. k,
			BackgroundColor3 = Color3.fromRGB(220, 230, 225),
			BackgroundTransparency = 0.9,
			Size = UDim2.new(1, 0, 0, 2 + k * 2),
			Parent = back,
		}) :: Frame
	end
	local rec = Kit.text(back, "● REC", {
		Name = "Rec",
		FontFace = Kit.FONT.mono,
		TextColor3 = Color3.fromRGB(Config.rgb(C.rec_color)),
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 28, 0, 22),
		Size = UDim2.new(0.3, 0, 0, 22),
		Max = 20,
	})
	local title = Kit.text(back, "GOING DOWN", {
		Name = "Title",
		FontFace = Kit.FONT.mono,
		TextColor3 = Kit.COLOR.ink,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0.7, 0, 0, 54),
		Max = 54,
	})
	local sub = Kit.text(back, "", {
		Name = "Sub",
		FontFace = Kit.FONT.mono,
		TextColor3 = Kit.COLOR.dim,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.new(0.6, 0, 0, 18),
		Max = 15,
	})
	local track = Kit.new("Frame", {
		Name = "Bar",
		BackgroundColor3 = Kit.COLOR.plateEdge,
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.new(0.28, 0, 0, 3),
		Parent = back,
	}) :: Frame
	local fill = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = Color3.fromRGB(Config.rgb(C.rec_color)),
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	}) :: Frame
	local whisper = Kit.text(back, "", {
		Name = "Whisper",
		FontFace = Kit.FONT.paper,
		TextColor3 = Color3.fromRGB(150, 146, 136),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -36),
		Size = UDim2.new(0.7, 0, 0, 20),
		Max = 17,
	})
	gui.Parent = player:WaitForChild("PlayerGui")
	local d: Descent = {
		gui = gui,
		back = back,
		photo = photo,
		title = title,
		sub = sub,
		whisper = whisper,
		rec = rec,
		fill = fill,
		track = track,
		lines = lines,
	}
	-- the tape runs while it shows: lines roll, REC blinks, the photo drifts, the title slips now and then
	RunService.RenderStepped:Connect(function()
		if not gui.Enabled then
			return
		end
		local t = os.clock()
		for k, line in lines do
			local y = ((t * (0.07 + k * 0.045) + k * 0.31) % 1.15) - 0.075
			line.Position = UDim2.fromScale(0, y)
		end
		rec.Visible = math.floor(t * C.rec_blink_hz * 2) % 2 == 0
		local s = 1.1 + math.min(t - shownAt, 20) * 0.006
		photo.Size = UDim2.fromScale(s, s)
		local slip = math.floor(t / 0.12)
		local glitch = (slip * 7919) % 23 == 0
		title.Position = UDim2.new(0.5, if glitch then 6 else 0, 0.42, 0)
	end)
	return d
end

local function show(fadeSeconds: number): Descent
	local d = descent or buildDescent()
	descent = d
	Loading.covering = true
	if not d.gui.Enabled then
		shownAt = os.clock()
		d.whisper.Text = WHISPERS[math.random(#WHISPERS)]
		d.fill.Size = UDim2.fromScale(0, 1)
		d.back.BackgroundTransparency = 1
		for _, l in { d.title, d.sub, d.whisper, d.rec } do
			l.TextTransparency = 1
		end
		d.gui.Enabled = true
	end
	local info = TweenInfo.new(math.max(fadeSeconds, 0.05))
	TweenService:Create(d.back, info, { BackgroundTransparency = 0 }):Play()
	for _, l in { d.title, d.sub, d.whisper, d.rec } do
		TweenService:Create(l, info, { TextTransparency = 0 }):Play()
	end
	return d
end

local function hide(d: Descent)
	local info = TweenInfo.new(C.descent_fade_out)
	TweenService:Create(d.back, info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(d.photo, info, { ImageTransparency = 1 }):Play()
	for _, l in { d.title, d.sub, d.whisper, d.rec } do
		TweenService:Create(l, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
	for _, line in d.lines do
		TweenService:Create(line, info, { BackgroundTransparency = 1 }):Play()
	end
	TweenService:Create(d.track, info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(d.fill, info, { BackgroundTransparency = 1 }):Play()
	local mine = token
	task.delay(C.descent_fade_out, function()
		if mine ~= token then
			return
		end
		d.gui.Enabled = false
		-- ready for the next descent
		d.photo.ImageTransparency = C.descent_photo_alpha
		for _, line in d.lines do
			line.BackgroundTransparency = 0.9
		end
		d.track.BackgroundTransparency = 0
		d.fill.BackgroundTransparency = 0
		for _, l in { d.title, d.sub, d.whisper, d.rec } do
			l.TextStrokeTransparency = 0.6
		end
		release()
	end)
end

-- the lift's doors close: the screen comes in, the floors count down through the ride
local function descend(seconds: number)
	token += 1
	local mine = token
	local d = show(math.min(1.2, math.max(seconds - 0.3, 0.2)))
	d.title.Text = "GOING DOWN"
	d.sub.Text = "LOBBY"
	local floors = { "P1", "P2", C.lift_floor }
	for k, name in floors do
		task.delay(seconds * k / (#floors + 1), function()
			if mine == token and d.gui.Enabled then
				d.sub.Text = name
			end
		end)
	end
end

-- the shift started: hold the screen until the level is ready, then let the guard see it
local function arrive()
	token += 1
	local mine = token
	local d = show(0.05)
	local t0 = os.clock()
	local function step(sub: string, share: number)
		d.title.Text = C.lift_floor
		d.sub.Text = sub
		TweenService:Create(d.fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(share, 1) }):Play()
	end
	local function waitFor(check: () -> boolean, upTo: number)
		while not check() and os.clock() - t0 < upTo and mine == token do
			task.wait(0.1)
		end
	end
	step("CONNECTING TO THE CAMERAS", 0.15)
	local Atmosphere = require(script.Parent:WaitForChild("Atmosphere")) :: any
	waitFor(function()
		return State.night ~= nil and State.tasks ~= nil and Atmosphere.ready == true
	end, C.shift_loading_max * 0.3)
	step("THE LIGHTS", 0.35)
	Atmosphere.snap()
	step("THE GARAGE", 0.55)
	local loaded = false
	task.spawn(function()
		local level = workspace:FindFirstChild("P3")
		if level then
			pcall(function()
				ContentProvider:PreloadAsync({ level })
			end)
		end
		loaded = true
	end)
	waitFor(function()
		return loaded
	end, C.shift_loading_max)
	step("REC", 1)
	waitFor(function()
		return os.clock() - t0 >= C.shift_loading_min
	end, C.shift_loading_max)
	if mine ~= token then
		return
	end
	Atmosphere.snap()
	hide(d)
end

-- a Night server, before the night: the tape screen waits for the rest of the group
local function waitTeam()
	token += 1
	local d = show(0.3)
	d.title.Text = C.lift_floor
	d.sub.Text = "WAITING FOR YOUR TEAM"
end

function Loading.startDescent()
	State.on("LiftDown", function(seconds: number)
		descend(seconds)
	end)
	-- the teleport to the night didn't happen: back to the lobby's view
	State.on("LaunchFailed", function()
		if descent then
			token += 1
			hide(descent)
		end
	end)
	State.on("Shift", function(onShift: boolean)
		if onShift then
			task.spawn(arrive)
		elseif descent and Loading.covering then
			token += 1
			hide(descent)
		end
	end)
end

function Loading.start()
	Loading.startDescent()
	Loading.covering = true
	local gui = Kit.new("ScreenGui", {
		Name = "Loading",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 100,
	}) :: ScreenGui
	local back = Kit.new("Frame", {
		Name = "Back",
		BackgroundColor3 = Color3.fromRGB(6, 6, 7),
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	}) :: Frame
	local title = Kit.text(back, "BLIND SPOT", {
		Name = "Title",
		FontFace = Kit.FONT.title,
		TextColor3 = Kit.COLOR.ink,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.new(0.6, 0, 0, 64),
		Max = 64,
	})
	local rec = Kit.text(back, "● REC", {
		Name = "Rec",
		FontFace = Kit.FONT.mono,
		TextColor3 = Color3.fromRGB(Config.rgb(C.rec_color)),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.3, 0, 0, 20),
		Max = 18,
	})
	local track = Kit.new("Frame", {
		Name = "Track",
		BackgroundColor3 = Kit.COLOR.plateEdge,
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.57),
		Size = UDim2.new(0.34, 0, 0, 6),
		Parent = back,
	}) :: Frame
	local fill = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = Kit.COLOR.brass,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	}) :: Frame
	local step = Kit.text(back, "LOADING THE TAPE", {
		Name = "Step",
		FontFace = Kit.FONT.mono,
		TextColor3 = Kit.COLOR.dim,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.new(0.5, 0, 0, 18),
		Max = 14,
	})
	local tip = Kit.text(back, TIPS[math.random(#TIPS)], {
		Name = "Tip",
		FontFace = Kit.FONT.paper,
		TextColor3 = Kit.COLOR.ink,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.new(0.7, 0, 0, 22),
		Max = 18,
	})
	gui.Parent = player:WaitForChild("PlayerGui")

	task.spawn(function()
		local t0 = os.clock()
		local done = 0
		local total = 5
		local function advance(text: string)
			done += 1
			step.Text = text
			TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(done / total, 1) }):Play()
		end
		local function waitFor(check: () -> boolean)
			while not check() and os.clock() - t0 < C.loading_max do
				rec.Visible = math.floor(os.clock() * 2) % 2 == 0 -- REC blinks once a second
				task.wait(0.1)
			end
		end
		-- 1. the building
		waitFor(function()
			local lobby = workspace:FindFirstChild("Lobby")
			local level = workspace:FindFirstChild("P3")
			return lobby ~= nil and level ~= nil
		end)
		advance("THE BUILDING")
		-- 2. the lights and the cameras
		local Atmosphere = require(script.Parent:WaitForChild("Atmosphere")) :: any
		waitFor(function()
			return Atmosphere.ready == true
		end)
		advance("THE LIGHTS")
		-- 3. the art, the models and the sounds
		local assets: { any } = {}
		for _, v in Kit.ART :: any do
			if type(v) == "string" then
				table.insert(assets, v)
			elseif type(v) == "table" and v.Image then
				table.insert(assets, v.Image)
			end
		end
		-- the sounds as their players (an id string would be loaded as an image: Studio warns "asset type does not
		-- match")
		local audio = game:GetService("SoundService"):WaitForChild("BlindSpotAudio", 5)
		if audio then
			table.insert(assets, audio)
		end
		local models = ReplicatedStorage:FindFirstChild("ClientModels")
		if models then
			table.insert(assets, models)
		end
		pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
		advance("THE TAPES")
		-- 4. the guard's file
		waitFor(function()
			return State.profile ~= nil
		end)
		advance("YOUR FILE")
		-- 5. at least a moment, so it never flashes by
		while os.clock() - t0 < C.loading_min do
			task.wait(0.1)
		end
		advance("READY")
		task.wait(0.3)
		local info = TweenInfo.new(0.6)
		TweenService:Create(back, info, { BackgroundTransparency = 1 }):Play()
		for _, l in { title, rec, step, tip } do
			TweenService:Create(l, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
		TweenService:Create(track, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(fill, info, { BackgroundTransparency = 1 }):Play()
		-- a Night server: the group gathers behind the tape screen (it lifts when the night starts)
		if Config.Places.current() == "night" and not State.shift then
			waitTeam()
		end
		task.wait(0.7)
		gui:Destroy()
		if not (descent and descent.gui.Enabled) then
			release()
		end
		-- the garage's meshes and textures, quietly, while the guard is in the lobby: the descent is quicker
		task.wait(2)
		local level = workspace:FindFirstChild("P3")
		if level then
			pcall(function()
				ContentProvider:PreloadAsync({ level })
			end)
		end
	end)
end

return Loading
