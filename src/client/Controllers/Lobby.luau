--!strict
-- The lobby on the client: the lift panel while the guard stands in a service lift (who is in, when the doors close,
-- START to go now, LEAVE to step out), and the fade to black while the lift goes down. The server decides who is in a
-- lift and when it leaves (server Services/LobbyService); this only shows it and sends the two intentions.
-- Style: the game's UI kit (Ui/Kit: worn steel art, brass, Oswald), 48 px touch targets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("Config"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local C = Config.C
local player = Players.LocalPlayer

local Lobby = {}

local THEME = {
	panel = Color3.fromRGB(16, 17, 18),
	outline = Color3.fromRGB(201, 164, 106),
	text = Color3.fromRGB(232, 226, 214),
	dim = Color3.fromRGB(150, 144, 134),
}

local function text(parent: Instance, name: string, value: string, size: UDim2, pos: UDim2, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.FontFace = Kit.FONT.title
	l.Text = value
	l.TextColor3 = color
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = size
	l.Position = pos
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 10
	limit.MaxTextSize = 30
	limit.Parent = l
	l.Parent = parent
	return l
end

local function button(parent: Instance, name: string, label: string, red: boolean, pos: UDim2): ImageButton
	local b = Kit.button(parent, if red then Kit.ART.PlayButton else Kit.ART.DarkButton, label, {
		Name = name,
		AnchorPoint = Vector2.new(0, 1),
		Position = pos,
		Size = UDim2.new(0.5, -21, 0, 48), -- 48 px tall (CLAUDE.md: 44 px minimum)
		TextSize = 24,
	})
	return b
end

function Lobby.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Lobby"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 8
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	local panel = Instance.new("Frame")
	panel.Name = "LiftPanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -20)
	panel.Size = UDim2.new(0, 340, 0, 184)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Visible = false
	Kit.new("ImageLabel", {
		Name = "Plate",
		Image = Kit.ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Kit.ART.DarkButton.Slice,
		SliceScale = 0.3,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = panel,
	})
	panel.Parent = gui

	local title = text(
		panel,
		"Title",
		"LIFT A  ·  " .. C.lift_floor,
		UDim2.new(0.6, 0, 0, 22),
		UDim2.new(0, 14, 0, 10),
		THEME.outline
	)
	local count = text(panel, "Count", "1/4 GUARDS", UDim2.new(0.38, -14, 0, 22), UDim2.new(0.62, 0, 0, 10), THEME.text)
	count.TextXAlignment = Enum.TextXAlignment.Right
	-- the night: the lift's first guard picks it, up to their unlocked night
	local down = Kit.button(panel, Kit.ART.DarkButton, "<", {
		Name = "NightDown",
		Position = UDim2.new(0, 14, 0, 38),
		Size = UDim2.fromOffset(48, 44),
		TextSize = 24,
	})
	local up = Kit.button(panel, Kit.ART.DarkButton, ">", {
		Name = "NightUp",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 38),
		Size = UDim2.fromOffset(48, 44),
		TextSize = 24,
	})
	local nightLabel =
		text(panel, "Night", "NIGHT 1  ·  ORIENTATION", UDim2.new(1, -140, 0, 26), UDim2.new(0, 70, 0, 47), THEME.text)
	nightLabel.TextXAlignment = Enum.TextXAlignment.Center
	down.Activated:Connect(function()
		Net.send("Lift", "nightDown")
	end)
	up.Activated:Connect(function()
		Net.send("Lift", "nightUp")
	end)
	local timer =
		text(panel, "Timer", "DOORS CLOSE IN 15", UDim2.new(1, -28, 0, 26), UDim2.new(0, 14, 0, 90), THEME.dim)
	local startButton = button(panel, "Start", "START", true, UDim2.new(0, 14, 1, -12))
	local leaveButton = button(panel, "Leave", "LEAVE", false, UDim2.new(0.5, 7, 1, -12))

	local black = Instance.new("Frame")
	black.Name = "Fade"
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BackgroundTransparency = 1
	black.BorderSizePixel = 0
	black.Size = UDim2.new(1, 0, 1, 0)
	black.Visible = false
	local fadeGui = Instance.new("ScreenGui")
	fadeGui.Name = "LiftFade"
	fadeGui.IgnoreGuiInset = true
	fadeGui.ResetOnSpawn = false
	fadeGui.DisplayOrder = 30
	black.Parent = fadeGui

	gui.Parent = player:WaitForChild("PlayerGui")
	fadeGui.Parent = player:WaitForChild("PlayerGui")

	local current: any = nil
	startButton.Activated:Connect(function()
		Net.send("Lift", "start")
	end)
	leaveButton.Activated:Connect(function()
		Net.send("Lift", "leave")
	end)

	State.on("Lift", function(info: any)
		current = info
		panel.Visible = info ~= nil and not State.shift
		if info then
			title.Text = `{info.label}  ·  {C.lift_floor}`
			count.Text = `{info.count}/{info.capacity} GUARDS`
			startButton.Visible = not info.leaving
			leaveButton.Visible = not info.leaving
			nightLabel.Text = `NIGHT {info.night}  ·  {info.nightName}`
			-- only the first guard turns the night; the arrows grey out at the ends
			Kit.setEnabled(down, Kit.ART.DarkButton, info.owner and info.night > 1)
			Kit.setEnabled(up, Kit.ART.DarkButton, info.owner and info.night < info.maxNight)
			down.Visible = info.owner
			up.Visible = info.owner
		end
	end)
	State.on("LiftDown", function(seconds: number)
		black.Visible = true
		black.BackgroundTransparency = 1
		TweenService:Create(black, TweenInfo.new(math.max(seconds - 0.4, 0.2)), { BackgroundTransparency = 0 }):Play()
	end)
	State.on("Shift", function(onShift: boolean)
		panel.Visible = false
		if black.Visible then
			-- the lift arrived (or the shift ended): fade back in
			local tween = TweenService:Create(black, TweenInfo.new(0.9), { BackgroundTransparency = 1 })
			tween.Completed:Connect(function()
				black.Visible = false
			end)
			tween:Play()
		end
		if not onShift then
			black.Visible = false
		end
	end)

	RunService.RenderStepped:Connect(function()
		if current and panel.Visible then
			if current.leaving then
				timer.Text = "GOING DOWN..."
			else
				local left = math.max(0, math.ceil(current.closesAt - workspace:GetServerTimeNow()))
				timer.Text = `DOORS CLOSE IN {left}`
			end
		end
	end)
end

return Lobby
