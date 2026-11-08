--!strict
-- The watcher (plan section 3, co-op): a guard taken while teammates are still up looks through the security
-- cameras from the booth. One camera at a time; CAM < > cycles them, TURN < > turns the one you look through toward a
-- teammate (the server moves its field, camera_turn_max at most). Rule 3: the Unseen is never on a camera screen, so
-- UnseenView hides him while State.down. A dead camera (blackout, cut line) shows NO SIGNAL.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

local Watcher = {}

local ids: { string } = {}
for _, cam in Config.Cameras do
	table.insert(ids, cam.id)
end

local index = 1
local badge = true

local function isLive(id: string): boolean
	local broken = State.tasks and State.tasks.brokenCams or {}
	if broken[id] then
		return false
	end
	local _, seg = State.now()
	if not seg then
		return true
	end
	return table.find(Timeline.active(seg, Config.Cameras), id) ~= nil
end

function Watcher.start()
	local gui = Kit.new("ScreenGui", {
		Name = "Watcher",
		ResetOnSpawn = false,
		DisplayOrder = 6,
		IgnoreGuiInset = true,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local safe = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), Parent = gui })
	Kit.new("UIPadding", {
		PaddingTop = UDim.new(0, 44),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = safe,
	})
	-- the monitor's frame: camera name, REC, the clock
	local camLabel = Kit.text(safe, "CAM 01", {
		FontFace = FONT.mono,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.5, 0, 0, 26),
		Max = 24,
	})
	local rec = Kit.text(safe, "● REC", {
		FontFace = FONT.mono,
		TextColor3 = COLOR.red,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.3, 0, 0, 26),
		Max = 24,
	})
	local noSignal = Kit.text(safe, "NO SIGNAL", {
		FontFace = FONT.mono,
		Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.5, 0, 0, 48),
		Max = 48,
		Visible = false,
	})
	local black = Kit.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(6, 7, 7),
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Visible = false,
		Parent = gui,
	}) :: Frame
	local info = Kit.text(safe, "", {
		FontFace = FONT.paper,
		TextColor3 = COLOR.ink,
		Position = UDim2.new(0.5, 0, 0, 34),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.8, 0, 0, 22),
		Max = 18,
	})
	-- the controls
	local bar = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(470, 52),
		Parent = safe,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = bar,
	})
	local function control(label: string, order: number, red: boolean, fn: () -> ())
		local b = Kit.button(bar, if red then ART.PlayButton else ART.DarkButton, label, {
			Size = UDim2.fromOffset(110, 52),
			LayoutOrder = order,
			TextSize = 20,
		})
		b.Activated:Connect(fn)
	end
	control("< CAM", 1, false, function()
		index = (index - 2) % #ids + 1
	end)
	control("CAM >", 2, false, function()
		index = index % #ids + 1
	end)
	control("TURN <", 3, true, function()
		Net.send("TurnCamera", ids[index], 1)
	end)
	control("TURN >", 4, true, function()
		Net.send("TurnCamera", ids[index], -1)
	end)
	gui.Parent = player:WaitForChild("PlayerGui")

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "Monitor"
	grade.Saturation = -0.7
	grade.Contrast = 0.25
	grade.TintColor = Color3.fromRGB(205, 225, 210)
	grade.Enabled = false

	local function stop()
		gui.Enabled = false
		grade.Enabled = false
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = Settings.get("FieldOfView")
		Lighting:SetAttribute("Watching", nil)
	end

	State.on("Down", function(payload: any)
		badge = payload and payload.badge == true
		info.Text = if badge
			then "YOU WERE TAKEN. TURN A CAMERA TOWARD YOUR TEAM. A TEAMMATE'S SYRINGE CAN BRING YOU BACK."
			else "YOU WERE TAKEN. NO SYRINGE LEFT: WATCH OVER YOUR TEAM UNTIL 6 AM."
		gui.Enabled = true
		grade.Parent = workspace.CurrentCamera
		grade.Enabled = true
		Lighting:SetAttribute("Watching", true)
	end)
	State.on("Respawn", stop)
	State.on("Shift", function(onShift: boolean)
		if not onShift then
			stop()
		end
	end)

	RunService:BindToRenderStep("BlindSpotWatcher", Enum.RenderPriority.Camera.Value + 2, function()
		if not State.down then
			return
		end
		local id = ids[index]
		local cam = Config.cameraById[id]
		local root = workspace:FindFirstChild("P3")
		local model = root and root:FindFirstChild("Cameras") and (root :: any).Cameras:FindFirstChild(id)
		local head = model and model:FindFirstChild("Head")
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		if head and head:IsA("BasePart") then
			camera.CFrame = head.CFrame * CFrame.new(0, 0, -1.3)
		end
		camera.FieldOfView = cam.vfov
		local live = isLive(id)
		black.Visible = not live
		noSignal.Visible = not live
		local offset = model and model:GetAttribute("AimOffset") or 0
		camLabel.Text = string.format(
			"CAM %s  ·  %s%s",
			string.sub(id, 2),
			string.upper(cam.zone),
			if offset ~= 0 then string.format("  ·  %+d°", math.floor(math.deg(offset :: number) + 0.5)) else ""
		)
		rec.Visible = live and math.floor(os.clock() * C.rec_blink_hz * 2) % 2 == 0
	end)
end

return Watcher
