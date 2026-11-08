--!strict
-- The loading screen (Adrien, 7 Nov: "les lumières sont noires au début puis s'allument : mets un loading screen").
-- It covers the game from the first frame the client runs until what the first minute needs is there: the lobby and
-- the floors streamed in, the lights collected (Atmosphere.ready), the Unseen's models, the UI art, the sounds, and the
-- guard's profile. At least loading_min seconds (no flash), at most loading_max (it never blocks the game). Then it
-- fades out. A tip from the night shift turns under the bar.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	"A flare is a camera that lasts twenty-five seconds.",
}

function Loading.start()
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
		task.wait(0.7)
		gui:Destroy()
	end)
end

return Loading
