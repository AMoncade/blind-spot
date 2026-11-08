--!strict
-- The shift's interface, in the lobby's style (Ui/Kit): the guard's watch top left, the camera status top centre
-- (ON CAMERA in REC red / BLIND SPOT), the night's title, and the shift report at 6 AM. The task list is Tasks.luau,
-- the camcorder button Camcorder.luau. Layout: nothing bottom left (touch thumbstick) or bottom right (jump).
-- In Studio: F6 paints the floor (green filmed, red blind), F7 skips to the next phase, F8 plays the next night.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Timeline = require(Shared:WaitForChild("Logic"):WaitForChild("Timeline"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Loading = require(script.Parent:WaitForChild("Loading"))
local Settings = require(Client:WaitForChild("Settings"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local C = Config.C
local ART = Kit.ART
local COLOR = Kit.COLOR
local FONT = Kit.FONT
local player = Players.LocalPlayer

local Hud = {}

local function plate(parent: Instance, name: string, props: { [string]: any }): ImageLabel
	local p: { [string]: any } = {
		Name = name,
		Image = ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.DarkButton.Slice,
		SliceScale = 0.18,
		Parent = parent,
	}
	for k, v in props do
		p[k] = v
	end
	return Kit.new("ImageLabel", p) :: ImageLabel
end

export type Parts = {
	vignetteEdges: { Frame },
	vignetteGradients: { UIGradient },
	threatEdges: { Frame },
	signal: ImageLabel,
	signalLabel: TextLabel,
	signalFill: Frame,
	signalWarning: TextLabel,
	hush: Frame,
	caption: TextLabel,
	squad: TextLabel,
	floor: TextLabel,
	clock: TextLabel,
	status: ImageLabel,
	statusText: TextLabel,
	title: TextLabel,
	sub: TextLabel,
	place: TextLabel,
	report: Frame,
	reportRows: { TextLabel },
	reportPay: TextLabel,
	reportFoot: TextLabel,
}

-- Builds the shift interface into gui (Studio previews it in Edit).
function Hud.build(gui: ScreenGui): Parts
	-- the watch
	local watch = plate(gui, "Watch", { Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(170, 50) })
	Kit.image(watch, ART.WatchIcon, {
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.new(0, -10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	local clock = Kit.text(watch, "12:00 AM", {
		Name = "Clock",
		FontFace = FONT.mono,
		TextColor3 = Color3.fromRGB(Config.rgb(C.nv_tint)),
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 54, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, -64, 0.56, 0),
		Max = 24,
	})

	-- the squad: solo lives, or how many guards are still up
	local squad = Kit.text(gui, "", {
		Name = "Squad",
		FontFace = FONT.title,
		TextColor3 = COLOR.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 64),
		Size = UDim2.fromOffset(200, 20),
		Max = 16,
	})

	-- the floor the guard is on (the floors lie side by side: Config.floorAt)
	local floor = Kit.text(gui, "", {
		Name = "Floor",
		FontFace = FONT.mono,
		TextColor3 = COLOR.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 84),
		Size = UDim2.fromOffset(200, 18),
		Max = 14,
	})

	-- the camera status
	local status = plate(gui, "Status", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(200, 40),
	})
	local statusText = Kit.text(status, "● ON CAMERA", {
		Name = "Text",
		FontFace = FONT.title,
		TextColor3 = COLOR.red,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.86, 0, 0.62, 0),
		Max = 22,
	})

	-- off camera, the screen's edges darken, more as the signal bar drains (Adrien, Nov 7)
	local vignette = Kit.new("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), Parent = gui })
	local vignetteEdges = {}
	local vignetteGradients = {}
	local threatEdges = {}
	for k, rotation in { 0, 90, 180, 270 } do
		local edge = Kit.new("Frame", {
			Name = "Edge" .. k,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = if rotation % 180 == 0 then UDim2.fromScale(1.2, 1.2) else UDim2.fromScale(1.2 * 0.5, 2.4),
			Rotation = rotation,
			Parent = vignette,
		}) :: Frame
		local gradient = Kit.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.32, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = edge,
		}) :: UIGradient
		table.insert(vignetteEdges, edge)
		table.insert(vignetteGradients, gradient)
		-- the threat (Adrien, 8 Nov): a red edge that beats like a heart as the bar runs out
		local red = Kit.new("Frame", {
			Name = "Threat" .. k,
			BackgroundColor3 = Color3.fromRGB(Config.rgb(C.rec_color)),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = edge.Size,
			Rotation = rotation,
			Parent = vignette,
		}) :: Frame
		Kit.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.22, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = red,
		})
		table.insert(threatEdges, red)
	end

	-- the signal bar, bottom centre (clear of the thumbstick and the jump button): full on camera, it drains off
	-- camera; empty, he knows where you are
	local bar = Kit.new("ImageLabel", {
		Name = "Signal",
		Image = ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.DarkButton.Slice,
		SliceScale = 0.12,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(320, 34),
		Parent = gui,
	}) :: ImageLabel
	local barLabel = Kit.text(bar, "SIGNAL", {
		Name = "Label",
		FontFace = FONT.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 64, 0, 16),
		Max = 14,
	})
	local track = Kit.new("Frame", {
		Name = "Track",
		BackgroundColor3 = Color3.fromRGB(10, 10, 11),
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 82, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, -96, 0, 12),
		Parent = bar,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0, 3), Parent = track })
	local fill = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = COLOR.ink,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = track,
	}) :: Frame
	Kit.new("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })
	local warning = Kit.text(gui, "HE IS CLOSE", {
		Name = "Warning",
		FontFace = FONT.title,
		TextColor3 = COLOR.red,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -44),
		Size = UDim2.fromOffset(320, 22),
		Max = 20,
		Visible = false,
	})

	-- the hush (plan section 4: the sound dies 1.5 s before he is in reach): until the sounds come, a darkening
	-- of the screen's edges and the caption of what would be heard
	local hush = Kit.new("Frame", { Name = "Hush", Size = UDim2.fromScale(1, 1), Visible = false, Parent = gui })
	for k, rotation in { 0, 90, 180, 270 } do
		local edge = Kit.new("Frame", {
			Name = "Edge" .. k,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = if rotation % 180 == 0 then UDim2.fromScale(1.2, 1.2) else UDim2.fromScale(1.2 * 0.5, 2.4),
			Rotation = rotation,
			Parent = hush,
		})
		Kit.new("UIGradient", {
			Rotation = 0,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(0.22, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = edge,
		})
	end
	local caption = Kit.text(gui, "[ THE HUM STOPS ]", {
		Name = "Caption",
		FontFace = FONT.paper,
		TextColor3 = COLOR.ink,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -116),
		Size = UDim2.new(0.5, 0, 0, 22),
		Max = 18,
		Visible = false,
	})

	-- the night's title
	local title = Kit.text(gui, "NIGHT 3", {
		Name = "Title",
		FontFace = FONT.title,
		TextColor3 = COLOR.brass,
		Position = UDim2.new(0.5, 0, 0.36, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0.12, 0),
		Max = 64,
		Visible = false,
	})
	local sub = Kit.text(gui, "STAY ON CAMERA.", {
		Name = "Sub",
		FontFace = FONT.paper,
		Position = UDim2.new(0.5, 0, 0.45, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0.055, 0),
		Max = 28,
		Visible = false,
	})
	local place = Kit.text(gui, "THE HALLOWAY  ·  LEVEL P3  ·  KESTREL & VANE", {
		Name = "Place",
		FontFace = FONT.mono,
		TextColor3 = COLOR.dim,
		Position = UDim2.new(0.5, 0, 0.51, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0.035, 0),
		Max = 16,
		Visible = false,
	})

	-- the shift report (6 AM)
	local report, body, close = Kit.window(gui, "Report", "SHIFT REPORT  ·  6:00 AM")
	close.Activated:Connect(function()
		report.Visible = false
	end)
	local rows = {}
	for k, icon in { ART.RoundsIcon, ART.WatchIcon } do
		local row = Kit.plate(body, { Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 0, (k - 1) * 52) })
		Kit.image(row, icon, { Size = UDim2.fromOffset(42, 42), Position = UDim2.fromOffset(4, 2) })
		rows[k] = Kit.text(row, "", {
			FontFace = FONT.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 56, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(1, -66, 0, 26),
			Max = 24,
		})
	end
	local payRow = Kit.plate(body, { Size = UDim2.new(1, 0, 0, 56), Position = UDim2.new(0, 0, 0, 104) })
	Kit.image(payRow, ART.PayIcon, { Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(2, 2) })
	local reportPay = Kit.text(payRow, "+$0", {
		FontFace = FONT.mono,
		TextColor3 = COLOR.green,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 64, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, -74, 0, 34),
		Max = 32,
	})
	local reportFoot = Kit.text(body, "", {
		FontFace = FONT.paper,
		TextColor3 = COLOR.dim,
		Position = UDim2.new(0, 0, 0, 170),
		Size = UDim2.new(1, 0, 0, 20),
		Max = 16,
	})
	return {
		vignetteEdges = vignetteEdges,
		vignetteGradients = vignetteGradients,
		threatEdges = threatEdges,
		signal = bar,
		signalLabel = barLabel,
		signalFill = fill,
		signalWarning = warning,
		hush = hush,
		caption = caption,
		squad = squad,
		floor = floor,
		clock = clock,
		status = status,
		statusText = statusText,
		title = title,
		sub = sub,
		place = place,
		report = report,
		reportRows = rows,
		reportPay = reportPay,
		reportFoot = reportFoot,
	}
end

local OUTCOME = {
	cleared = "NIGHT CLEARED",
	unfinished = "ROUND UNFINISHED",
	lost = "ALL GUARDS LOST",
}

function Hud.fillReport(parts: Parts, summary: any)
	local title = parts.report:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = `{OUTCOME[summary.outcome] or "SHIFT REPORT"}  ·  NIGHT {summary.night or "?"}`
		title.TextColor3 = if summary.outcome == "cleared" then COLOR.green else COLOR.brass
	end
	parts.reportRows[1].Text = `TASKS DONE  {summary.tasks or 0}/{summary.total or 0}`
	parts.reportRows[2].Text = `TIMES CAUGHT  {summary.deaths or 0}`
	parts.reportPay.Text = "+" .. Kit.money(summary.pay or 0)
	local unlockedNext = summary.outcome == "cleared" and summary.unlocked and summary.unlocked > (summary.night or 0)
	parts.reportFoot.Text = if unlockedNext
		then `NIGHT {summary.unlocked} UNLOCKED.  BACK TO THE LOBBY IN {C.lobby_return_delay} S.`
		else `BACK TO THE LOBBY IN {C.lobby_return_delay} SECONDS.`
end

function Hud.start()
	local gui = Kit.new("ScreenGui", {
		Name = "Hud",
		ResetOnSpawn = false,
		DisplayOrder = 1,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local parts = Hud.build(gui)
	gui.Parent = player:WaitForChild("PlayerGui")

	local titleUntil = 0
	local function show(main: string, detail: string, seconds: number)
		parts.title.Text, parts.sub.Text = main, detail
		titleUntil = os.clock() + seconds
	end

	local function nightTitle(n: number)
		local def = Config.nightByNumber[n]
		if def then
			show(`NIGHT {n}  ·  {def.name}`, string.upper(def.intro), 5)
		end
	end
	State.on("Night", function(night: any)
		if night and State.shift then
			-- once the descent's loading screen has lifted, so the guard reads it
			Loading.whenClear(function()
				nightTitle(night.night)
			end)
		end
	end)
	State.on("Shift", function(onShift: boolean)
		if onShift and State.night then
			nightTitle(State.night.night)
		end
		if not onShift then
			parts.report.Visible = false
		end
	end)
	State.on("Hush", function(on: boolean)
		parts.hush.Visible = on and State.shift
		parts.caption.Visible = on and State.shift
	end)
	State.on("Respawn", function()
		parts.hush.Visible = false
		parts.caption.Visible = false
	end)
	State.on("NightEnd", function(summary: any)
		Hud.fillReport(parts, summary)
		Kit.show(parts.report, true)
	end)

	local lastFilmed: boolean? = nil
	local darkness = 1 -- the vignette's edge transparency, eased
	local threat = 0 -- 0 safe, 1 the bar is empty (eased): red edges, black creeping in
	local beat = 0 -- the red edge's heartbeat phase
	RunService.RenderStepped:Connect(function(dt: number)
		-- the vignette and the signal bar
		local live = State.shift and not State.dead and not State.down
		local e = State.exposure
		local target = 1
		if live and not State.filmed then
			target = C.vignette_off + (C.vignette_max - C.vignette_off) * (1 - e)
		elseif live and State.marked then
			target = C.vignette_off
		end
		darkness += (target - darkness) * math.min(1, dt * 4)
		-- the threat: under threat_start (off camera), the black creeps in from the edges and a red edge beats,
		-- faster as the bar runs out (at most threat_beat_max a second: never a flash)
		local want = if live and not State.filmed then math.clamp((C.threat_start - e) / C.threat_start, 0, 1) else 0
		threat += (want - threat) * math.min(1, dt * 5)
		for k, edge in parts.vignetteEdges do
			edge.BackgroundTransparency = darkness
			parts.vignetteGradients[k].Offset = Vector2.new(threat * C.threat_creep, 0)
		end
		local calm = Settings.get("ReduceFlashes") == true
		beat += dt * (C.threat_beat_min + (C.threat_beat_max - C.threat_beat_min) * threat) * math.pi * 2
		local pulse = if calm then 0.6 else math.max(0, math.sin(beat)) ^ 2
		local redAlpha = 1 - threat * C.threat_red * (0.35 + 0.65 * pulse)
		for _, red in parts.threatEdges do
			red.BackgroundTransparency = redAlpha
		end
		parts.signal.Visible = live
		parts.signalFill.Size = UDim2.fromScale(e, 1)
		parts.signalFill.BackgroundColor3 = if State.marked or e < 0.25
			then COLOR.red
			elseif e < 0.6 then Color3.fromRGB(224, 160, 60)
			else COLOR.ink
		parts.signalLabel.Text = if State.filmed then "● SIGNAL" else "SIGNAL"
		parts.signalLabel.TextColor3 = if State.filmed then COLOR.red else COLOR.dim
		-- low: the warning blinks once a second (well under 3 flashes a second)
		parts.signalWarning.Visible = live
			and not State.filmed
			and e < C.signal_warn
			and math.floor(os.clock() * C.rec_blink_hz * 2) % 2 == 0
		local onShift = State.shift
		local t = State.now()
		if State.night then
			local h, m = Timeline.clock(State.night, t, C.night_clock_start, C.night_clock_end)
			parts.clock.Text = string.format("%d:%02d AM", if h == 0 then 12 else h, m)
		end
		local watch = parts.clock.Parent :: GuiObject
		watch.Visible = onShift
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		parts.floor.Visible = onShift and root ~= nil
		if onShift and root and root:IsA("BasePart") then
			parts.floor.Text = Config.floorById[(Config.floorAt(root.Position.X))].name
		end
		parts.status.Visible = onShift and not State.dead and not State.down and Settings.get("RecDot") ~= false
		if State.filmed ~= lastFilmed then
			lastFilmed = State.filmed
			parts.statusText.Text = if State.filmed then "● ON CAMERA" else "BLIND SPOT"
			parts.statusText.TextColor3 = if State.filmed then COLOR.red else COLOR.dim
			parts.status.ImageColor3 = if State.filmed then Color3.new(1, 1, 1) else Color3.fromRGB(150, 150, 150)
			if not State.filmed then
				-- a short shake of the tag when the guard leaves every field
				local s = parts.status
				local base = UDim2.new(0.5, 0, 0, 10)
				TweenService
					:Create(s, TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 3, true), {
						Position = base + UDim2.fromOffset(4, 0),
					})
					:Play()
			end
		end
		local s = State.squad
		parts.squad.Visible = onShift and s ~= nil
		if s then
			-- the team's lives (the shift setup), and in co-op how many guards are still up
			local hearts = "LIVES  "
				.. string.rep("■ ", math.max(s.lives, 0))
				.. string.rep("□ ", math.max((s.maxLives or C.shift_lives) - s.lives, 0))
			parts.squad.Text = if s.solo then hearts else `{hearts}·  UP {s.up}/{s.total}`
			parts.squad.TextColor3 = if s.lives <= 1 or s.up < s.total then COLOR.red else COLOR.ink
		end
		local showTitle = os.clock() < titleUntil and onShift
		parts.title.Visible, parts.sub.Visible, parts.place.Visible = showTitle, showTitle, showTitle
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
