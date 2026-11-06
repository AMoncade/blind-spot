--!strict
-- First person, locked (plan section 11, FirstPersonController): the body stays visible, the head bob follows the
-- walk and the setting (0 to 1), the field of view is a setting (70 to 90). Touch works with Roblox's own controls.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local C = Config.C
local player = Players.LocalPlayer

local FirstPerson = {}

FirstPerson.frozen = false -- the death freezes the view

local walked = 0
local bob = 0

local function showBody(character: Model)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Head" then
			d.LocalTransparencyModifier = 0
		end
	end
end

function FirstPerson.start()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5

	RunService:BindToRenderStep("BlindSpotFirstPerson", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local camera = workspace.CurrentCamera
		camera.FieldOfView = math.clamp(Settings.get("FieldOfView"), 1, C.fov_max)
		local character = player.Character
		if not character or FirstPerson.frozen or State.dead then
			return
		end
		showBody(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local speed = (humanoid.MoveDirection * humanoid.WalkSpeed).Magnitude
		local amount = math.clamp(Settings.get("HeadBob"), 0, 1) * C.headbob_amount
		if speed > 0.5 and humanoid.FloorMaterial ~= Enum.Material.Air then
			walked += speed * dt
		end
		local target = if speed > 0.5 then math.sin(walked * C.headbob_freq * math.pi * 2) * amount else 0
		bob += (target - bob) * math.min(1, dt * 12)
		if math.abs(bob) > 1e-4 then
			camera.CFrame *= CFrame.new(0, bob, 0)
		end
	end)
end

return FirstPerson
