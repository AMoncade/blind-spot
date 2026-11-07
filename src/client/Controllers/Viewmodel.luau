--!strict
-- The hands and the camcorder in first person (plan section 7: the most polished objects of the game, always on
-- screen during a shift). The Blender model (tools/blender/viewmodel.py, ReplicatedStorage.ClientModels.Viewmodel)
-- follows the camera, low on the right; it sways when the view turns, bobs with the walk, and comes up to the eye when
-- the camcorder is raised, where the viewfinder (Camcorder.luau) takes over. Its trim wears the equipped viewfinder's
-- colour. Hidden in the lobby, in a death and while watching the cameras.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Settings = require(Client:WaitForChild("Settings"))
local Camcorder = require(script.Parent:WaitForChild("Camcorder"))

local C = Config.C
local player = Players.LocalPlayer

local Viewmodel = {}

-- camera-space poses; the model's lens points to +Z, FLIP turns it to the camera's forward (-Z)
local FLIP = CFrame.Angles(0, math.pi, 0)

local function pose(p: { number }): CFrame
	return CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(math.rad(p[4]), math.rad(p[5]), math.rad(p[6]))
end

function Viewmodel.start()
	local source = ReplicatedStorage:WaitForChild("ClientModels", 10)
	local template = source and source:WaitForChild("Viewmodel", 10)
	if not (template and template:IsA("Model")) then
		warn("[Viewmodel] ReplicatedStorage.ClientModels.Viewmodel is missing")
		return
	end
	local model = template:Clone()
	local trim = model:FindFirstChild("Trim", true)
	-- a dim fill so the hands read in the dark garage (no shadow, a few studs)
	local fill = Instance.new("PointLight")
	fill.Brightness = C.vm_fill_brightness
	fill.Range = C.vm_fill_range
	fill.Color = Color3.fromRGB(220, 226, 235)
	fill.Shadows = false
	-- between the eye and the hands (the lens faces +Z here, the eye is behind, on -Z)
	local spot = Instance.new("Attachment")
	spot.Name = "Fill"
	spot.Position = Vector3.new(0, 0.5, -1.1)
	spot.Parent = model.PrimaryPart
	fill.Parent = spot
	local idle = pose(C.vm_idle)
	local raised = pose(C.vm_raised)

	local t = 0 -- 0 idle, 1 at the eye
	local swayX, swayY = 0, 0
	local lastLook: Vector3? = nil
	local walked = 0

	local function paint()
		local profile = State.profile
		local item = Config.shopById[profile and profile.viewfinder or "vf_classic"] or Config.shopById.vf_classic
		if trim and trim:IsA("BasePart") then
			trim.Color = Color3.fromRGB(Config.rgb(item.frame))
		end
	end
	paint()
	State.on("Profile", paint)

	RunService:BindToRenderStep("BlindSpotViewmodel", Enum.RenderPriority.Camera.Value + 3, function(dt: number)
		local camera = workspace.CurrentCamera
		local show = State.shift and not State.dead and not State.down and player.Character ~= nil
		-- up to the eye while filming; hidden once there (the viewfinder fills the view)
		local target = if Camcorder.raised then 1 else 0
		t += math.clamp(target - t, -dt / C.vm_raise_seconds, dt / C.vm_raise_seconds)
		if not show or (Camcorder.raised and t >= 0.99) then
			if model.Parent then
				model.Parent = nil
			end
			lastLook = nil
			return
		end
		if model.Parent ~= camera then
			model.Parent = camera
		end
		-- sway: the hands lag behind a turn of the view
		local look = camera.CFrame.LookVector
		if lastLook then
			local d = camera.CFrame:VectorToObjectSpace(look - lastLook)
			swayX = math.clamp(swayX - d.X * C.vm_sway, -0.12, 0.12)
			swayY = math.clamp(swayY - d.Y * C.vm_sway, -0.12, 0.12)
		end
		lastLook = look
		local ease = math.min(1, dt * 8)
		swayX -= swayX * ease
		swayY -= swayY * ease
		-- the walk's bob, scaled by the head bob setting
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local speed = if humanoid then (humanoid.MoveDirection * humanoid.WalkSpeed).Magnitude else 0
		if speed > 0.5 then
			walked += speed * dt
		end
		local amount = math.clamp(Settings.get("HeadBob"), 0, 1) * C.vm_bob * math.min(speed / 10, 1)
		local bob = CFrame.new(math.cos(walked * 0.9) * amount, math.abs(math.sin(walked * 0.9)) * amount, 0)
		local at = idle:Lerp(raised, t * t * (3 - 2 * t))
		model:SetPrimaryPartCFrame(
			camera.CFrame * at * bob * CFrame.new(swayX, swayY, 0) * CFrame.Angles(swayY, swayX, 0) * FLIP
		)
	end)
end

return Viewmodel
