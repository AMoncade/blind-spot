--!strict
-- The skills on the shift (SkillService): SPRINT (Shift, or its button) and FLARE (Q, or its button), next to the
-- camcorder's button, out of the thumbstick's and the jump button's way. The server decides; this asks and shows what
-- is left: the SPRINT cooldown darkens its button, the flares left are counted on it.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local player = Players.LocalPlayer

local Skills = {}

type Button = { button: ImageButton, label: TextLabel, cover: Frame }

local function skillButton(parent: Instance, name: string, art: string, x: number): Button
	local b = Kit.new("ImageButton", {
		Name = name,
		Image = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, x, 1, -140),
		Size = UDim2.fromOffset(72, 80),
		Parent = parent,
	}) :: ImageButton
	Kit.image(b, art, {
		Name = "Art",
		Size = UDim2.fromOffset(64, 64),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	-- the cooldown: a dark cover that shrinks as the skill comes back
	local cover = Kit.new("Frame", {
		Name = "Cover",
		BackgroundColor3 = Kit.COLOR.shadow,
		BackgroundTransparency = 0.35,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = b,
	}) :: Frame
	local plate = Kit.new("ImageLabel", {
		Image = Kit.ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Kit.ART.DarkButton.Slice,
		SliceScale = 0.12,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(72, 22),
		Parent = b,
	})
	local label = Kit.text(plate, name, {
		FontFace = Kit.FONT.title,
		Size = UDim2.new(0.9, 0, 0.78, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Max = 14,
	})
	return { button = b, label = label, cover = cover }
end

function Skills.start()
	local screen = Kit.new("ScreenGui", {
		Name = "Skills",
		ResetOnSpawn = false,
		DisplayOrder = 3,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}) :: ScreenGui
	-- one row with the camcorder (Camcorder.luau, x -18), above the jump button, under the clipboard (Adrien, 8 Nov)
	local sprint = skillButton(screen, "SPRINT", Kit.ART.SkillSprint, -110)
	local flare = skillButton(screen, "FLARE", Kit.ART.SkillFlare, -190)
	screen.Parent = player:WaitForChild("PlayerGui")

	local info: any = nil
	local keys = UserInputService.KeyboardEnabled
	local function ask(name: string)
		if State.shift and not State.dead and not State.down then
			Net.send("Skill", name)
		end
	end
	sprint.button.Activated:Connect(function()
		ask("sprint")
	end)
	flare.button.Activated:Connect(function()
		ask("flare")
	end)
	ContextActionService:BindAction("BlindSpotSprint", function(_, inputState)
		if inputState == Enum.UserInputState.Begin and State.shift then
			ask("sprint")
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:BindAction("BlindSpotFlare", function(_, inputState)
		if inputState == Enum.UserInputState.Begin and State.shift then
			ask("flare")
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q, Enum.KeyCode.DPadUp)

	State.on("Skills", function(data: any)
		info = data
	end)
	RunService.RenderStepped:Connect(function()
		local live = State.shift and not State.dead and not State.down
		screen.Enabled = live
		if not live or not info then
			return
		end
		-- SPRINT: the cover shows the cooldown left
		local left = math.max(0, info.sprintReady - workspace:GetServerTimeNow())
		sprint.cover.Size = UDim2.new(1, 0, math.clamp(left / math.max(info.sprintCooldown, 0.1), 0, 1), 0)
		sprint.label.Text = if left > 0
			then string.format("%ds", math.ceil(left))
			elseif keys then "SPRINT ⇧"
			else "SPRINT"
		-- FLARE: how many are left tonight
		flare.cover.Size = UDim2.new(1, 0, if info.flares > 0 then 0 else 1, 0)
		flare.label.Text = if keys then `FLARE Q ×{info.flares}` else `FLARE ×{info.flares}`
	end)
end

return Skills
