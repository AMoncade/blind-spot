--!strict
-- The camcorder (plan section 3, CamcorderController): raise it with F, the gamepad's R2 or the on-screen button.
-- Raised, the hands hold it up in front of the face (Viewmodel.luau) and its flip-out screen shows the picture:
-- infrared night vision, REC, the tape clock and the battery, drawn exactly over the screen's corners every frame
-- (Adrien, 8 Nov: "tu regardes vraiment comme dans la cam dans tes mains"); around it, the dark garage, the camcorder
-- and the hands. Without the Viewmodel model, the picture fills the screen. The client only sends "raised, looking
-- this way" 10 times a second; the server films, and runs the battery.
-- The price: through the screen the Unseen is never visible (UnseenView hides him while Camcorder.raised).
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Timeline = require(Shared:WaitForChild("Logic"):WaitForChild("Timeline"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local C = Config.C
local player = Players.LocalPlayer

local Camcorder = {}

Camcorder.raised = false

local gui: ScreenGui
local lcd: CanvasGroup -- the camcorder's picture, laid over its flip-out screen
local surround: { Frame } = {} -- the garage around the screen, darker (the eyes are on the screen)
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
	l.FontFace = Kit.FONT.mono
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

local brackets: { Frame } = {}

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
		table.insert(brackets, f)
	end
end

local function buildGui()
	gui = Instance.new("ScreenGui")
	gui.Name = "Camcorder"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Enabled = false
	-- around the screen the garage is darker: the eyes are on the picture
	for k = 1, 4 do
		local f = Instance.new("Frame")
		f.Name = "Surround" .. k
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BackgroundTransparency = 1
		f.Visible = false
		f.Parent = gui
		surround[k] = f
	end
	-- the picture: a green, grainy night-vision screen (it sits over the flip-out screen of the camcorder in the hands)
	lcd = Instance.new("CanvasGroup")
	lcd.Name = "Screen"
	lcd.BackgroundTransparency = 1
	lcd.BorderSizePixel = 0
	lcd.Size = UDim2.fromScale(1, 1)
	lcd.Parent = gui
	local tint = Instance.new("Frame")
	tint.Name = "Tint"
	tint.BorderSizePixel = 0
	tint.BackgroundColor3 = rgb(C.nv_tint)
	tint.BackgroundTransparency = C.lcd_tint_alpha
	tint.Size = UDim2.fromScale(1, 1)
	tint.ZIndex = 0
	tint.Parent = lcd
	-- the screen's own light: it lifts the dark garage behind it (an LCD glows), brighter in the middle
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.BorderSizePixel = 0
	glow.BackgroundColor3 = rgb(C.nv_tint)
	glow.BackgroundTransparency = C.lcd_glow_alpha
	glow.Size = UDim2.fromScale(1, 1)
	glow.ZIndex = 0
	glow.Parent = lcd
	local falloff = Instance.new("UIGradient")
	falloff.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.7),
	})
	falloff.Rotation = 90
	falloff.Parent = glow
	for k = 1, C.lcd_scanlines do
		local line = Instance.new("Frame")
		line.Name = "Scan" .. k
		line.BorderSizePixel = 0
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BackgroundTransparency = 0.8
		line.Position = UDim2.fromScale(0, (k - 0.5) / C.lcd_scanlines)
		line.Size = UDim2.new(1, 0, 0, 1)
		line.ZIndex = 1
		line.Parent = lcd
	end
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 4)
	round.Parent = lcd
	for _, a in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
		corner(lcd, a[1], a[2])
	end
	recLabel = label(lcd, "Rec", "● REC", UDim2.new(0.06, 0, 0.08, 0), Vector2.new(0, 0))
	recLabel.TextColor3 = rgb(C.rec_color)
	clockLabel = label(lcd, "Clock", "00:00", UDim2.new(0.06, 0, 0.92, 0), Vector2.new(0, 1))
	emptyLabel = label(lcd, "Empty", "BATTERY EMPTY", UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))
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
	battery.Parent = lcd
	-- the VHS trace where he just vanished (plan section 4, his signs)
	trace = Instance.new("Frame")
	trace.Name = "Trace"
	trace.BorderSizePixel = 0
	trace.BackgroundColor3 = Color3.new(1, 1, 1)
	trace.BackgroundTransparency = 0.5
	trace.Size = UDim2.new(1.1, 0, 0, 5)
	trace.Visible = false
	trace.Parent = lcd
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
	if raised then
		-- the viewfinder bought in the supply room (content/shop.csv)
		local profile = State.profile
		local item = Config.shopById[profile and profile.viewfinder or "vf_classic"] or Config.shopById.vf_classic
		for _, f in brackets do
			f.BackgroundColor3 = rgb(item.frame)
		end
		recLabel.TextColor3 = rgb(item.rec)
		clockLabel.TextColor3 = rgb(item.text)
	end
	grade.Parent = workspace.CurrentCamera
	grade.Enabled = raised
	irPart.Parent = if raised then workspace.CurrentCamera else nil
	local spot = irPart:FindFirstChildOfClass("SpotLight") :: SpotLight
	spot.Enabled = raised
	if raised then
		baseExposure = Lighting:GetAttribute("BaseExposure") or Lighting.ExposureCompensation
		Lighting:SetAttribute("CamcorderRaised", true)
		-- the eyes adapt a little to the screen's glow; the full night vision is on the screen itself
		Lighting.ExposureCompensation = baseExposure + C.nv_exposure * C.lcd_exposure_share
		sendIn = 0
	else
		Lighting:SetAttribute("CamcorderRaised", nil)
		Lighting.ExposureCompensation = Lighting:GetAttribute("BaseExposure") or baseExposure
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
	screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	-- the camcorder you carry (the one equipped in the supply room), above the jump button: 84 px (44 minimum)
	local button = Kit.new("ImageButton", {
		Name = "Raise",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -140),
		Size = UDim2.fromOffset(84, 92),
		Image = "",
		AutoButtonColor = false,
		Parent = screen,
	}) :: ImageButton
	local art = Kit.image(button, Kit.ART.VfFactory, {
		Name = "Art",
		Size = UDim2.fromOffset(78, 78),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	local plate = Kit.new("ImageLabel", {
		Image = Kit.ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Kit.ART.DarkButton.Slice,
		SliceScale = 0.12,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(78, 22),
		Parent = button,
	})
	local hint = Kit.text(plate, "● REC", {
		FontFace = Kit.FONT.mono,
		TextColor3 = rgb(C.rec_color),
		Size = UDim2.new(0.86, 0, 0.74, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Max = 14,
	})
	local function look()
		local profile = State.profile
		local item = Config.shopById[profile and profile.viewfinder or "vf_classic"] or Config.shopById.vf_classic
		art.Image = (Kit.ART :: any)[item.art] or Kit.ART.VfFactory
		-- what is left of the battery (it charges back under the fixed cameras)
		local left = math.ceil(math.max(State.battery, 0))
		hint.Text = if UserInputService.KeyboardEnabled then `CLICK  ·  {left}s` else `● REC  {left}s`
	end
	look()
	State.on("Profile", look)
	State.on("Battery", look)
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
	-- a click puts you behind the viewfinder, another one lowers it (Adrien, 7 Nov); not a click on a button
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 and State.shift then
			Camcorder.toggle()
		end
	end)

	-- the picture follows the flip-out screen of the camcorder in the hands, every frame (after the Viewmodel moves it)
	RunService:BindToRenderStep("BlindSpotCamcorderScreen", Enum.RenderPriority.Camera.Value + 4, function()
		if not Camcorder.raised then
			return
		end
		local camera = workspace.CurrentCamera
		local model = camera:FindFirstChild("Viewmodel")
		local screen = model and model:FindFirstChild("LcdScreen", true)
		local placed = false
		if screen and screen:IsA("BasePart") then
			local half = screen.Size / 2
			local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
			placed = true
			for _, c in { Vector3.new(-1, -1, 0), Vector3.new(1, -1, 0), Vector3.new(-1, 1, 0), Vector3.new(1, 1, 0) } do
				local p = camera:WorldToViewportPoint(screen.CFrame:PointToWorldSpace(half * c))
				if p.Z <= 0 then
					placed = false
					break
				end
				x0, y0, x1, y1 = math.min(x0, p.X), math.min(y0, p.Y), math.max(x1, p.X), math.max(y1, p.Y)
			end
			if placed then
				-- whole pixels, so the screen and the dark around it meet without a seam
				x0, y0, x1, y1 = math.floor(x0), math.floor(y0), math.ceil(x1), math.ceil(y1)
				lcd.Position = UDim2.fromOffset(x0, y0)
				lcd.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
				-- it comes on as the hands bring it up (the glass clears at lcd_clear_at)
				local up = (model :: Instance):GetAttribute("Raise")
				local on =
					math.clamp(if type(up) == "number" then (up - C.lcd_clear_at) / (1 - C.lcd_clear_at) else 1, 0, 1)
				lcd.GroupTransparency = 1 - on
				-- the garage around it, darker: above, below, left, right
				local view = camera.ViewportSize
				local rects = {
					{ 0, 0, view.X, y0 },
					{ 0, y1, view.X, view.Y - y1 },
					{ 0, y0, x0, y1 - y0 },
					{ x1, y0, view.X - x1, y1 - y0 },
				}
				for k, r in rects do
					local f = surround[k]
					f.Visible = true
					f.Position = UDim2.fromOffset(r[1], r[2])
					f.Size = UDim2.fromOffset(math.max(r[3], 0), math.max(r[4], 0))
					f.BackgroundTransparency = 1 - (1 - C.lcd_surround_alpha) * on
				end
			end
		end
		if not placed then
			-- no camcorder in the hands: the picture fills the screen, the old way
			lcd.Position = UDim2.new()
			lcd.Size = UDim2.fromScale(1, 1)
			lcd.GroupTransparency = 0
			for _, f in surround do
				f.Visible = false
			end
		end
		-- the full-screen night vision only without the screen in the hands
		grade.Enabled = not placed
	end)

	State.on("Battery", function(battery: number, _max: number, serverRaised: boolean)
		if Camcorder.raised and not serverRaised and battery <= 0 then
			setRaised(false)
			setRaised(true) -- the battery is empty: this only shows BATTERY EMPTY
		end
	end)
	State.on("Death", function()
		setRaised(false)
	end)
	State.on("Down", function()
		setRaised(false)
		local b = player.PlayerGui:FindFirstChild("CamcorderButton")
		if b and b:IsA("ScreenGui") then
			b.Enabled = false
		end
	end)
	State.on("Respawn", function()
		local b = player.PlayerGui:FindFirstChild("CamcorderButton")
		if b and b:IsA("ScreenGui") then
			b.Enabled = State.shift
		end
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
			trace.Position = UDim2.new(-0.05, math.random(-6, 6), 0, traceY - lcd.Position.Y.Offset)
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
