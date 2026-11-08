--!strict
-- The first shift's lessons (Adrien, 8 Nov: "explique au joueur quand c'est sa première partie : rester dans la zone
-- blanche, la caméra remet la barre, si la barre touche 0 il se fait attraper"). Only on a guard's very first shift
-- (profile.nights 0), once the descent's loading screen has lifted. One card at a time near the top of the screen; each
-- one waits for the guard to see it happen (leaving a white zone, the bar dropping, coming back under a camera), so it
-- teaches by doing; an arrow points at the signal bar when the card is about it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local Loading = require(script.Parent:WaitForChild("Loading"))

local C = Config.C
local player = Players.LocalPlayer

local Tutorial = {}

type Step = {
	text: string,
	bar: boolean?, -- point at the signal bar
	done: (since: number) -> boolean, -- seconds since the card showed
}

local function steps(): { Step }
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	return {
		{
			text = "THE WHITE ZONES ON THE FLOOR ARE WHAT THE CAMERAS SEE. THERE, YOU ARE SAFE.",
			done = function(since)
				return since > C.tutorial_min and (not State.filmed or since > C.tutorial_max)
			end,
		},
		{
			text = "OUT OF THE WHITE, NO CAMERA SEES YOU: YOUR SIGNAL BAR DRAINS.",
			bar = true,
			done = function(since)
				return since > C.tutorial_min and (State.exposure < 0.8 or State.filmed or since > C.tutorial_max)
			end,
		},
		{
			text = "IF THE BAR HITS ZERO OUT OF THE WHITE, HE TAKES YOU. GET BACK UNDER A CAMERA.",
			bar = true,
			done = function(since)
				return since > C.tutorial_min and (State.filmed or since > C.tutorial_max * 2)
			end,
		},
		{
			text = "UNDER A CAMERA THE BAR FILLS BACK UP.",
			bar = true,
			done = function(since)
				return since > C.tutorial_min and (State.exposure > 0.95 or since > C.tutorial_max)
			end,
		},
		{
			text = "YOUR ROUND IS ON THE CLIPBOARD, TOP RIGHT. FOLLOW THE MARKERS: SOME TASKS ARE IN THE DARK.",
			done = function(since)
				return since > C.tutorial_max
			end,
		},
		{
			text = if touch
				then "TAP THE CAMCORDER: WHAT IT FILMS IS SAFE TOO, FOR A FEW SECONDS OF TAPE."
				else "CLICK TO RAISE THE CAMCORDER: WHAT IT FILMS IS SAFE TOO, FOR A FEW SECONDS OF TAPE.",
			done = function(since)
				return since > C.tutorial_max
			end,
		},
	}
end

function Tutorial.start()
	local gui = Kit.new("ScreenGui", {
		Name = "Tutorial",
		ResetOnSpawn = false,
		DisplayOrder = 6,
		Enabled = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}) :: ScreenGui
	local card = Kit.plate(gui, {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.new(0.62, 0, 0, 62),
	})
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = Kit.COLOR.brass
		stroke.Thickness = 2
	end
	local text = Kit.text(card, "", {
		Name = "Text",
		FontFace = Kit.FONT.title,
		TextColor3 = Kit.COLOR.ink,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -60, 1, -12),
		Max = 20,
	})
	text.TextWrapped = true
	local count = Kit.text(card, "", {
		Name = "Count",
		FontFace = Kit.FONT.mono,
		TextColor3 = Kit.COLOR.brass,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 4),
		Size = UDim2.fromOffset(40, 14),
		Max = 12,
	})
	-- the arrow to the signal bar (bottom centre)
	local arrow = Kit.text(gui, "▼", {
		Name = "Arrow",
		FontFace = Kit.FONT.title,
		TextColor3 = Kit.COLOR.brass,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -64),
		Size = UDim2.fromOffset(40, 34),
		Max = 34,
	})
	arrow.Visible = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local running = 0 -- a newer shift cancels the old lessons
	local function teach()
		running += 1
		local mine = running
		local list = steps()
		for k, step in list do
			if mine ~= running or not State.shift then
				break
			end
			text.Text = step.text
			count.Text = `{k}/{#list}`
			arrow.Visible = step.bar == true
			gui.Enabled = true
			local t0 = os.clock()
			while mine == running and State.shift and not step.done(os.clock() - t0) do
				-- the arrow bobs (motion, not a flash)
				arrow.Position = UDim2.new(0.5, 0, 1, -64 - math.abs(math.sin(os.clock() * 3)) * 8)
				task.wait(0.05)
				-- caught or down: the lessons stop here
				if State.dead or State.down then
					break
				end
			end
		end
		if mine == running then
			gui.Enabled = false
		end
	end

	State.on("Shift", function(onShift: boolean)
		if not onShift then
			running += 1
			gui.Enabled = false
			return
		end
		local profile = State.profile :: any
		if not profile or (profile.nights or 0) > 0 then
			return
		end
		Loading.whenClear(function()
			task.delay(C.tutorial_delay, function()
				if State.shift then
					teach()
				end
			end)
		end)
	end)
	-- a card grows a little when it changes (no flash)
	local last = ""
	RunService.RenderStepped:Connect(function()
		if gui.Enabled and text.Text ~= last then
			last = text.Text
			card.Size = UDim2.new(0.62, 0, 0, 56)
			TweenService:Create(card, TweenInfo.new(0.2), { Size = UDim2.new(0.62, 0, 0, 62) }):Play()
		end
	end)
end

return Tutorial
