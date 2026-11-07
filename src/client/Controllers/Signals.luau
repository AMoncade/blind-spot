--!strict
-- Coop without chat (SignalService): the signal wheel (G, or the SIGNAL button above the camcorder on a phone; the
-- number keys pick while it is open) and what the squad's signals leave: a marker in the world with the sender's name
-- and distance, and a line in the feed under the watch, for signal_seconds. A ping (OVER HERE, HE'S THERE) marks the
-- point the sender looked at; the others follow the sender. Solo: no wheel (nobody to tell).
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local FirstPerson = require(script.Parent:WaitForChild("FirstPerson"))

local C = Config.C
local player = Players.LocalPlayer
local STUD_METRES = 0.28 -- plan section 7: 1 stud is about 0.28 m
local KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
}

local Signals = {}

type Marker = {
	from: number,
	gui: BillboardGui,
	sub: TextLabel,
	name: string,
	attachment: Attachment?,
	untilT: number,
}

local markers: { Marker } = {}
local feedLines: { { label: TextLabel, untilT: number } } = {}
local screen: ScreenGui
local wheel: Frame
local button: ImageButton
local feed: Frame
local isOpen = false

local function rgb(hex: string): Color3
	return Color3.fromRGB(Config.rgb(hex))
end

local function canSignal(): boolean
	local squad = State.squad
	return State.shift and squad ~= nil and not squad.solo and not State.dead
end

-- the point the guard looks at (an OVER HERE marker), within reach of the server's check
local function lookPoint(): Vector3
	local camera = workspace.CurrentCamera
	local origin = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { camera }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local zones = workspace:FindFirstChild("SafeZones")
	if zones then
		table.insert(ignore, zones)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(origin, look * (C.signal_range - 4), params)
	return if hit then hit.Position + hit.Normal * 0.5 else origin + look * 20
end

local function setOpen(open: boolean)
	isOpen = open and canSignal()
	wheel.Visible = isOpen
	-- the cursor comes back while the wheel is open (first person keeps it hidden otherwise)
	FirstPerson.cursorWanted = isOpen
	if isOpen then
		for k, key in KEYS do
			ContextActionService:BindAction("BlindSpotSignal" .. k, function(_, inputState)
				if inputState == Enum.UserInputState.Begin then
					local signal = Config.Signals[k]
					if signal then
						Signals.send(signal.id)
					end
				end
				return Enum.ContextActionResult.Sink
			end, false, key)
		end
	else
		for k in KEYS do
			ContextActionService:UnbindAction("BlindSpotSignal" .. k)
		end
	end
end

function Signals.send(id: string)
	local signal = Config.signalById[id]
	if not signal or not canSignal() then
		return
	end
	local at = if signal.kind == "ping" then lookPoint() else Vector3.zero
	Net.send("Signal", id, at.X, at.Y, at.Z)
	setOpen(false)
end

local function build()
	screen = Kit.new("ScreenGui", {
		Name = "Signals",
		ResetOnSpawn = false,
		DisplayOrder = 3,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	-- the wheel: the signals around the centre of the screen, 48 px tall (44 minimum on a phone)
	wheel = Kit.new("Frame", {
		Name = "Wheel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 290),
		Visible = false,
		Parent = screen,
	}) :: Frame
	local n = #Config.Signals
	for k, signal in Config.Signals do
		local a = -math.pi / 2 + (k - 1) * 2 * math.pi / n
		local b, label = Kit.button(wheel, Kit.ART.DarkButton, signal.text, {
			Name = signal.id,
			Size = UDim2.fromOffset(150, 48),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * 125, 0.5, math.sin(a) * 105),
			TextSize = 22,
		})
		label.TextColor3 = rgb(signal.color)
		b.Modal = true -- frees the mouse in first person while the wheel shows
		local key = Kit.text(b, tostring(k), {
			FontFace = Kit.FONT.mono,
			TextColor3 = Kit.COLOR.dim,
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.fromOffset(8, 4),
			Max = 12,
			Visible = UserInputService.KeyboardEnabled,
		})
		key.Name = "Key"
		b.Activated:Connect(function()
			Signals.send(signal.id)
		end)
	end
	local close = Kit.button(wheel, Kit.ART.DarkButton, "CLOSE", {
		Name = "Close",
		Size = UDim2.fromOffset(96, 44),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		TextSize = 16,
	})
	close.Activated:Connect(function()
		setOpen(false)
	end)

	-- the phone button, above the camcorder's (which sits above the jump button)
	local b, label = Kit.button(screen, Kit.ART.DarkButton, "SIGNAL", {
		Name = "Open",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -244),
		Size = UDim2.fromOffset(84, 48),
		TextSize = 18,
	})
	button = b
	label.Text = if UserInputService.KeyboardEnabled then "SIGNAL  G" else "SIGNAL"
	button.Activated:Connect(function()
		setOpen(not isOpen)
	end)

	-- the feed, under the watch and the floor
	feed = Kit.new("Frame", {
		Name = "Feed",
		Position = UDim2.fromOffset(16, 106),
		Size = UDim2.fromOffset(260, C.signal_feed * 20),
		Parent = screen,
	}) :: Frame
	Kit.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = feed })
	screen.Parent = player:WaitForChild("PlayerGui")
end

local function clearMarker(m: Marker)
	m.gui:Destroy()
	if m.attachment then
		m.attachment:Destroy()
	end
end

local function onSignal(data: any)
	local signal = Config.signalById[data.id]
	if not signal then
		return
	end
	-- one marker per guard: a new signal replaces their last one
	for k = #markers, 1, -1 do
		if markers[k].from == data.from then
			clearMarker(markers[k])
			table.remove(markers, k)
		end
	end
	local adornee: Instance? = nil
	local attachment: Attachment? = nil
	if data.follow then
		local sender = Players:GetPlayerByUserId(data.from)
		local character = sender and sender.Character
		adornee = character and character:FindFirstChild("HumanoidRootPart")
	end
	if not adornee then
		local a = Instance.new("Attachment")
		a.WorldPosition = Vector3.new(data.x, data.y, data.z)
		a.Parent = workspace.Terrain
		attachment, adornee = a, a
	end
	local gui = Kit.new("BillboardGui", {
		Name = "Signal",
		Adornee = adornee,
		AlwaysOnTop = true,
		LightInfluence = 0,
		Size = UDim2.fromOffset(150, 50),
		StudsOffset = Vector3.new(0, if data.follow then 3.6 else 1.2, 0),
		MaxDistance = 600,
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	}) :: BillboardGui
	local plate = Kit.plate(gui, { Size = UDim2.new(1, 0, 0, 28) })
	plate.UIStroke.Color = rgb(signal.color)
	Kit.text(plate, signal.text, {
		FontFace = Kit.FONT.title,
		TextColor3 = rgb(signal.color),
		Size = UDim2.new(0.9, 0, 0.8, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Max = 20,
	})
	local sub = Kit.text(gui, string.upper(data.name), {
		FontFace = Kit.FONT.mono,
		TextColor3 = Kit.COLOR.ink,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 31),
		Max = 13,
	})
	table.insert(markers, {
		from = data.from,
		gui = gui,
		sub = sub,
		name = string.upper(data.name),
		attachment = attachment,
		untilT = os.clock() + C.signal_seconds,
	})
	-- the feed line
	local line = Kit.text(feed, `{string.upper(data.name)}: {signal.text}`, {
		FontFace = Kit.FONT.label,
		TextColor3 = rgb(signal.color),
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = math.floor(os.clock() * 10),
		Max = 16,
	})
	table.insert(feedLines, { label = line, untilT = os.clock() + C.signal_seconds })
	while #feedLines > C.signal_feed do
		feedLines[1].label:Destroy()
		table.remove(feedLines, 1)
	end
end

local function clearAll()
	for _, m in markers do
		clearMarker(m)
	end
	table.clear(markers)
	for _, l in feedLines do
		l.label:Destroy()
	end
	table.clear(feedLines)
end

function Signals.start()
	build()
	ContextActionService:BindAction("BlindSpotSignalWheel", function(_, inputState)
		if inputState == Enum.UserInputState.Begin and canSignal() then
			setOpen(not isOpen)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.G, Enum.KeyCode.ButtonL1)
	State.on("Signal", onSignal)
	local function refresh()
		local on = canSignal()
		button.Visible = on
		feed.Visible = State.shift
		if not on then
			setOpen(false)
		end
		if not State.shift then
			clearAll()
		end
	end
	State.on("Shift", refresh)
	State.on("Squad", refresh)
	State.on("Death", refresh)
	State.on("Respawn", refresh)
	State.on("Down", refresh)
	refresh()

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		for k = #markers, 1, -1 do
			local m = markers[k]
			if now >= m.untilT or not m.gui.Adornee or not m.gui.Adornee.Parent then
				clearMarker(m)
				table.remove(markers, k)
			elseif root and root:IsA("BasePart") then
				local adornee = m.gui.Adornee :: Instance
				local at = if adornee:IsA("Attachment")
					then adornee.WorldPosition
					elseif adornee:IsA("BasePart") then adornee.Position
					else root.Position
				local d = (at - root.Position).Magnitude * STUD_METRES
				m.sub.Text = string.format("%s · %d m", m.name, math.floor(d + 0.5))
			end
		end
		for k = #feedLines, 1, -1 do
			if now >= feedLines[k].untilT then
				feedLines[k].label:Destroy()
				table.remove(feedLines, k)
			end
		end
	end)
end

return Signals
