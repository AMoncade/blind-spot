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

function Hud.fillReport(parts: Parts, summary: any)
	parts.reportRows[1].Text = `TASKS DONE  {summary.tasks or 0}/{summary.total or 0}`
	parts.reportRows[2].Text = `GUARDS LOST  {summary.deaths or 0}`
	parts.reportPay.Text = "+" .. Kit.money(summary.pay or 0)
	parts.reportFoot.Text = `BACK TO THE LOBBY IN {C.lobby_return_delay} SECONDS.`
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

	State.on("Night", function(night: any)
		if night and State.shift then
			show("NIGHT " .. night.night, "STAY ON CAMERA.", 4)
		end
	end)
	State.on("Shift", function(onShift: boolean)
		if onShift and State.night then
			show("NIGHT " .. State.night.night, "STAY ON CAMERA.", 4)
		end
		if not onShift then
			parts.report.Visible = false
		end
	end)
	State.on("NightEnd", function(summary: any)
		Hud.fillReport(parts, summary)
		Kit.show(parts.report, true)
	end)

	local lastFilmed: boolean? = nil
	RunService.RenderStepped:Connect(function()
		local onShift = State.shift
		local t = State.now()
		if State.night then
			local h, m = Timeline.clock(State.night, t, C.night_clock_start, C.night_clock_end)
			parts.clock.Text = string.format("%d:%02d AM", if h == 0 then 12 else h, m)
		end
		local watch = parts.clock.Parent :: GuiObject
		watch.Visible = onShift
		parts.status.Visible = onShift and not State.dead and Settings.get("RecDot") ~= false
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
