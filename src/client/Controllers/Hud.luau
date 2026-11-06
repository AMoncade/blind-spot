--!strict
-- Almost no interface (plan section 2): the hour on the guard's watch, the round count, the night's title and its end,
-- and the optional REC dot (plan section 3, accessibility) when the server says the player is filmed.
-- Phase 0 draws the watch and the round as text; the watch on the wrist and the clipboard come with the Blender hands.
-- In Studio: F6 paints the floor (green filmed, red blind), F7 skips to the next phase, F8 plays the next night.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Timeline = require(Shared:WaitForChild("Logic"):WaitForChild("Timeline"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local C = Config.C
local player = Players.LocalPlayer

local Hud = {}

local function text(parent: Instance, name: string, pos: UDim2, size: UDim2, anchor: Vector2): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextColor3 = Color3.fromRGB(220, 226, 230)
	l.TextStrokeTransparency = 0.5
	l.TextScaled = true
	l.Position = pos
	l.Size = size
	l.AnchorPoint = anchor
	l.Text = ""
	l.Parent = parent
	return l
end

function Hud.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1

	local watch = text(gui, "Watch", UDim2.new(0, 16, 1, -16), UDim2.new(0, 120, 0, 28), Vector2.new(0, 1))
	watch.TextXAlignment = Enum.TextXAlignment.Left
	local rounds = text(gui, "Rounds", UDim2.new(0, 16, 1, -48), UDim2.new(0, 160, 0, 22), Vector2.new(0, 1))
	rounds.TextXAlignment = Enum.TextXAlignment.Left
	local title = text(gui, "Title", UDim2.new(0.5, 0, 0.4, 0), UDim2.new(0.6, 0, 0.09, 0), Vector2.new(0.5, 0.5))
	local sub = text(gui, "Sub", UDim2.new(0.5, 0, 0.49, 0), UDim2.new(0.6, 0, 0.045, 0), Vector2.new(0.5, 0.5))

	local dot = Instance.new("Frame")
	dot.Name = "RecDot"
	dot.AnchorPoint = Vector2.new(1, 0)
	dot.Position = UDim2.new(1, -20, 0, 20)
	dot.Size = UDim2.new(0, 14, 0, 14)
	dot.BorderSizePixel = 0
	dot.BackgroundColor3 = Color3.fromRGB(Config.rgb(C.rec_color))
	dot.Visible = false
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = dot
	dot.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	local titleUntil = 0
	local function show(main: string, detail: string, seconds: number)
		title.Text, sub.Text = main, detail
		titleUntil = os.clock() + seconds
	end

	State.on("Night", function(night: any)
		if night then
			show("NIGHT " .. night.night, "Stay on camera.", 4)
		end
	end)
	State.on("NightEnd", function(summary: any)
		show("6:00 AM", `Rounds {summary.rounds}/{summary.total}   Lost {summary.deaths}`, 8)
	end)
	State.on("Rounds", function(n: number, total: number)
		rounds.Text = `Rounds {n}/{total}`
	end)

	RunService.RenderStepped:Connect(function()
		local t = State.now()
		if State.night then
			local h, m = Timeline.clock(State.night, t, C.night_clock_start, C.night_clock_end)
			watch.Text = string.format("%d:%02d AM", if h == 0 then 12 else h, m)
		end
		local showTitle = os.clock() < titleUntil
		title.Visible, sub.Visible = showTitle, showTitle
		dot.Visible = Settings.get("RecDot") == true and State.filmed and not State.dead
	end)

	if RunService:IsStudio() then
		local commands = { [Enum.KeyCode.F6] = "floor", [Enum.KeyCode.F7] = "skip", [Enum.KeyCode.F8] = "night" }
		ContextActionService:BindAction("BlindSpotDebug", function(_, inputState, input)
			if inputState == Enum.UserInputState.Begin then
				Net.send("Debug", commands[input.KeyCode])
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.F6, Enum.KeyCode.F7, Enum.KeyCode.F8)
	end
end

return Hud
