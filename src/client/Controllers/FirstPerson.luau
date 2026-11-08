--!strict
-- First person, locked (plan section 11, FirstPersonController): the head bob follows the walk and the setting (0 to
-- 1), the field of view is a setting (70 to 90). Touch works with Roblox's own controls. The guard's own body is
-- hidden from their eyes, all of it (Adrien, 8 Nov: "on voit notre propre corps", a look down showed the inside of the
-- shoulders and the vest): the hands and the camcorder (Viewmodel.luau) are the body in first person. Other guards
-- still see it. The eyes sit a little forward (fp_camera_forward). No mouse cursor during a shift (the view is the aim).
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

FirstPerson.cursorWanted = false -- another controller needs the cursor for a moment (the signal wheel)

FirstPerson.frozen = false -- the death freezes the view

local walked = 0
local bob = 0
local shake = 0 -- the threat's shake (0 calm, 1 the bar is empty), eased

local function hideBody(character: Model, hidden: boolean)
	local value = if hidden then 1 else 0
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			if d.LocalTransparencyModifier ~= value then
				d.LocalTransparencyModifier = value
			end
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
		local cursor = not State.shift or State.down or FirstPerson.cursorWanted
		if UserInputService.MouseIconEnabled ~= cursor then
			UserInputService.MouseIconEnabled = cursor
		end
		if State.down then
			return -- the watcher looks through a security camera (Watcher.luau)
		end
		local camera = workspace.CurrentCamera
		camera.FieldOfView = math.clamp(Settings.get("FieldOfView"), 1, C.fov_max)
		local character = player.Character
		if not character then
			return
		end
		-- hidden while the eyes are the guard's: the whole shift, the death's turn too (the lobby is third person)
		hideBody(character, State.shift)
		if FirstPerson.frozen or State.dead or not State.shift then
			return
		end
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
		-- the threat (Adrien, 8 Nov): the view shakes more as the signal bar runs out off camera
		local want = if not State.filmed
			then math.clamp((C.threat_start - State.exposure) / C.threat_start, 0, 1)
			else 0
		shake += (want - shake) * math.min(1, dt * 4)
		if shake > 0.01 then
			local t = os.clock()
			local tremble = C.threat_shake * shake ^ 1.5 * (if Settings.get("ReduceFlashes") == true then 0.3 else 1)
			camera.CFrame *= CFrame.Angles(
				math.rad(math.noise(t * 9, 11) * tremble),
				math.rad(math.noise(t * 9, 12) * tremble),
				math.rad(math.noise(t * 6, 13) * tremble * 0.5)
			)
		end
	end)
end

return FirstPerson
