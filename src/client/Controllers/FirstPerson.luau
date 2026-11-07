--!strict
-- First person, locked (plan section 11, FirstPersonController): the body stays visible, the head bob follows the
-- walk and the setting (0 to 1), the field of view is a setting (70 to 90). Touch works with Roblox's own controls.
-- Only the body shows: the head and every accessory (hair, hats) stay hidden, or they would sit in front of the eyes
-- (Adrien, Nov 7: "un peu derrière la tête, tu vois mal"); the eyes sit a little forward (fp_camera_forward) so a look
-- down shows the legs, not the inside of the chest. No mouse cursor during a shift (the view is the aim).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
		if d:IsA("BasePart") then
			local hidden = d.Name == "Head" or d:FindFirstAncestorWhichIsA("Accessory") ~= nil
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

function FirstPerson.start()
	-- the lobby is third person, so guards see each other; the shift is first person, locked
	-- (a watcher, down in the booth, looks through the cameras: third person rules, a free mouse for the buttons)
	local function apply()
		local onShift = State.shift and not State.down
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.CameraOffset = if onShift then Vector3.new(0, 0, -C.fp_camera_forward) else Vector3.zero
		end
		if onShift then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMinZoomDistance = 0.5
			player.CameraMaxZoomDistance = 0.5
		else
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMaxZoomDistance = C.lobby_zoom_max
			player.CameraMinZoomDistance = C.lobby_zoom_min
		end
	end
	apply()
	State.on("Shift", apply)
	State.on("Down", apply)
	State.on("Respawn", apply)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 5)
		apply()
	end)

	RunService:BindToRenderStep("BlindSpotFirstPerson", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		-- the cursor: hidden while the view is the aim (a shift, first person), back in the lobby and for a watcher
		local cursor = not State.shift or State.down
		if UserInputService.MouseIconEnabled ~= cursor then
			UserInputService.MouseIconEnabled = cursor
		end
		if State.down then
			return -- the watcher looks through a security camera (Watcher.luau)
		end
		local camera = workspace.CurrentCamera
		camera.FieldOfView = math.clamp(Settings.get("FieldOfView"), 1, C.fov_max)
		local character = player.Character
		if not character or FirstPerson.frozen or State.dead then
			return
		end
		if not State.shift then
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
