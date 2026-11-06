--!strict
-- The camcorder (plan section 3, CamcorderController): raise it with F, the gamepad's R2 or the on-screen button.
-- Raised, the screen is its viewfinder: infrared night vision, REC, the tape clock and the battery. The client only
-- sends "raised, looking this way" 10 times a second; the server films, and runs the battery.
-- The price: through the screen the Unseen is never visible (UnseenView hides him while Camcorder.raised).
local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Timeline = require(Shared:WaitForChild("Logic"):WaitForChild("Timeline"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local C = Config.C
local player = Players.LocalPlayer

local Camcorder = {}

Camcorder.raised = false

local gui: ScreenGui
local recLabel: TextLabel
local clockLabel: TextLabel
local batteryFill: Frame
local emptyLabel: TextLabel
local trace: Frame
local grade: ColorCorrectionEffect
local irPart: Part
local baseExposure = 0
local sendIn = 0
local traceUntil = 0
local traceY = 0

local function rgb(hex: string): Color3
	return Color3.fromRGB(Config.rgb(hex))
end

local function label(parent: Instance, name: string, text: string, pos: UDim2, anchor: Vector2): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.4
	l.TextScaled = true
	l.Size = UDim2.new(0.22, 0, 0.06, 0)
	l.Position = pos
	l.AnchorPoint = anchor
	l.Text = text
	l.TextXAlignment = if anchor.X > 0.5 then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function corner(parent: Instance, ax: number, ay: number)
	-- an L bracket in each corner of the viewfinder
	for _, horizontal in { true, false } do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.AnchorPoint = Vector2.new(ax, ay)
		f.Position = UDim2.new(0.04 + ax * 0.92, 0, 0.06 + ay * 0.88, 0)
		f.Size = if horizontal then UDim2.new(0.06, 0, 0, 3) else UDim2.new(0, 3, 0.1, 0)
		f.Parent = parent
	end
end

local function buildGui()
	gui = Instance.new("ScreenGui")
	gui.Name = "Camcorder"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Enabled = false
	for _, a in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
		corner(gui, a[1], a[2])
	end
	recLabel = label(gui, "Rec", "● REC", UDim2.new(0.06, 0, 0.08, 0), Vector2.new(0, 0))
	recLabel.TextColor3 = rgb(C.rec_color)
	clockLabel = label(gui, "Clock", "00:00", UDim2.new(0.06, 0, 0.92, 0), Vector2.new(0, 1))
	emptyLabel = label(gui, "Empty", "BATTERY EMPTY", UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))
	emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
	emptyLabel.Visible = false
	local battery = Instance.new("Frame")
	battery.Name = "Battery"
	battery.AnchorPoint = Vector2.new(1, 0)
	battery.Position = UDim2.new(0.94, 0, 0.09, 0)
	battery.Size = UDim2.new(0.08, 0, 0.035, 0)
	battery.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = battery
	batteryFill = Instance.new("Frame")
	batteryFill.BorderSizePixel = 0
	batteryFill.BackgroundColor3 = Color3.new(1, 1, 1)
	batteryFill.Size = UDim2.new(1, 0, 1, 0)
	batteryFill.Parent = battery
	battery.Parent = gui
	-- the VHS trace where he just vanished (plan section 4, his signs)
	trace = Instance.new("Frame")
	trace.Name = "Trace"
	trace.BorderSizePixel = 0
	trace.BackgroundColor3 = Color3.new(1, 1, 1)
	trace.BackgroundTransparency = 0.5
	trace.Size = UDim2.new(1.1, 0, 0, 5)
	trace.Visible = false
	trace.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "NightVision"
	grade.Enabled = false
	grade.Saturation = -1
	grade.TintColor = rgb(C.nv_tint)
	grade.Brightness = C.nv_brightness
	grade.Contrast = C.nv_contrast

	-- the infrared lamp: a shadowless narrow SpotLight, client only (plan section 7)
	irPart = Instance.new("Part")
	irPart.Name = "CamcorderIR"
	irPart.Anchored = true
	irPart.CanCollide = false
	irPart.CanQuery = false
	irPart.CanTouch = false
	irPart.Transparency = 1
	irPart.Size = Vector3.new(0.2, 0.2, 0.2)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Range = C.nv_light_range
	spot.Angle = C.nv_light_angle
	spot.Brightness = C.nv_light_brightness
	spot.Color = rgb(C.nv_tint)
	spot.Shadows = false
	spot.Enabled = false
	spot.Parent = irPart
end

local function setRaised(raised: boolean)
	if raised and (State.dead or State.battery <= 0) then
		if State.battery <= 0 and not State.dead then
			-- the viewfinder shows BATTERY EMPTY for a moment, without filming
			gui.Enabled = true
			emptyLabel.Visible = true
			task.delay(1.5, function()
				emptyLabel.Visible = false
				gui.Enabled = Camcorder.raised
			end)
		end
		return
	end
	if raised == Camcorder.raised then
		return
	end
	Camcorder.raised = raised
	gui.Enabled = raised
	grade.Parent = workspace.CurrentCamera
	grade.Enabled = raised
	irPart.Parent = if raised then workspace.CurrentCamera else nil
	local spot = irPart:FindFirstChildOfClass("SpotLight") :: SpotLight
	spot.Enabled = raised
	if raised then
		baseExposure = Lighting.ExposureCompensation
		Lighting.ExposureCompensation = baseExposure + C.nv_exposure
		sendIn = 0
	else
		Lighting.ExposureCompensation = baseExposure
		Net.send("Camcorder", false)
	end
end

function Camcorder.toggle()
	if not State.shift and not Camcorder.raised then
		return -- the camcorder is handed out in the booth, not in the lobby
	end
	setRaised(not Camcorder.raised)
end

local function aim(): (number, number)
	local look = workspace.CurrentCamera.CFrame.LookVector
	return math.atan2(-look.X, -look.Z), math.asin(math.clamp(look.Y, -1, 1))
end

local function touchButton()
	local screen = Instance.new("ScreenGui")
	screen.Name = "CamcorderButton"
	screen.ResetOnSpawn = false
	local button = Instance.new("TextButton")
	button.Name = "Raise"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -24, 1, -150)
	button.Size = UDim2.new(0, 64, 0, 64) -- 44 px minimum (CLAUDE.md, phone first)
	button.BackgroundColor3 = Color3.fromRGB(20, 22, 24)
	button.BackgroundTransparency = 0.3
	button.Text = "REC"
	button.Font = Enum.Font.Code
	button.TextColor3 = rgb(C.rec_color)
	button.TextScaled = true
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = button
	button.Parent = screen
	button.Activated:Connect(Camcorder.toggle)
	screen.Enabled = State.shift
	State.on("Shift", function(onShift: boolean)
		screen.Enabled = onShift
		if not onShift then
			setRaised(false)
		end
	end)
	screen.Parent = player:WaitForChild("PlayerGui")
end

function Camcorder.start()
	buildGui()
	touchButton()
	ContextActionService:BindAction("BlindSpotCamcorder", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			Camcorder.toggle()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonR2)

	State.on("Battery", function(battery: number, _max: number, serverRaised: boolean)
		if Camcorder.raised and not serverRaised and battery <= 0 then
			setRaised(false)
			setRaised(true) -- the battery is empty: this only shows BATTERY EMPTY
		end
	end)
	State.on("Death", function()
		setRaised(false)
	end)
	State.on("Vanish", function(x: number, z: number)
		if not Camcorder.raised then
			return
		end
		local camera = workspace.CurrentCamera
		local point, onScreen = camera:WorldToViewportPoint(Vector3.new(x, C.unseen_height / 2, z))
		if point.Z <= 0 then
			return
		end
		local y = if onScreen then point.Y else math.clamp(point.Y, 0, camera.ViewportSize.Y)
		traceY = y
		trace.Visible = true
		traceUntil = os.clock() + 1.2
	end)

	RunService.RenderStepped:Connect(function(dt)
		if not Camcorder.raised then
			return
		end
		local camera = workspace.CurrentCamera
		irPart.CFrame = camera.CFrame
		-- REC blinks once a second (rec_blink_hz), far under 3 flashes a second
		recLabel.Visible = math.floor(os.clock() * C.rec_blink_hz * 2) % 2 == 0
		local t, _ = State.now()
		if State.night then
			local h, m = Timeline.clock(State.night, t, C.night_clock_start, C.night_clock_end)
			clockLabel.Text = string.format("%02d:%02d", h, m)
		end
		batteryFill.Size = UDim2.new(math.clamp(State.battery / math.max(State.batteryMax, 1), 0, 1), 0, 1, 0)
		if trace.Visible then
			local left = traceUntil - os.clock()
			trace.Visible = left > 0
			trace.BackgroundTransparency = 1 - math.clamp(left / 1.2, 0, 1) * 0.6
			trace.Position = UDim2.new(-0.05, math.random(-6, 6), 0, traceY)
		end
		sendIn -= dt
		if sendIn <= 0 then
			sendIn = 1 / C.camcorder_rate
			local yaw, pitch = aim()
			Net.send("Camcorder", true, yaw, pitch)
		end
	end)
end

return Camcorder
