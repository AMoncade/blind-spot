--!strict
-- "La caméra te suit" (plan section 3): a camera that films you turns slowly toward you, never more than
-- camera_turn_max from where it is aimed, and goes back to rest when you leave its field. Which cameras film the
-- player comes from the server (State.seenBy); the turning is only drawn here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Level = require(script.Parent.Parent:WaitForChild("Level"))
local SoundDirector = require(script.Parent:WaitForChild("SoundDirector"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local C = Config.C
local player = Players.LocalPlayer

local CameraHeads = {}

type Head = { id: string, head: BasePart, rest: CFrame, current: CFrame }

local heads: { Head } = {}
-- cameras the Unseen broke tonight (event Smash): their head drops at once and they spark now and then
local smashed: { [string]: { sparks: ParticleEmitter, next: number } } = {}

-- sparks at a camera head (a burst when it breaks, a few now and then after)
local function sparksAt(head: BasePart): ParticleEmitter
	local at = Instance.new("Attachment")
	at.Name = "Sparks"
	at.Parent = head
	local p = Instance.new("ParticleEmitter")
	p.Enabled = false
	p.Color = ColorSequence.new(Color3.fromRGB(255, 236, 190), Color3.fromRGB(255, 150, 60))
	p.LightEmission = 1
	p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0) })
	p.Lifetime = NumberRange.new(0.3, 0.7)
	p.Speed = NumberRange.new(8, 18)
	p.SpreadAngle = Vector2.new(70, 70)
	p.Acceleration = Vector3.new(0, -40, 0)
	p.Drag = 2
	p.EmissionDirection = Enum.NormalId.Bottom
	p.Parent = at
	return p
end

-- the Unseen broke this camera (server UnseenService rule 6): glass, a short circuit, a burst of sparks, one flash
local function smash(id: string)
	for _, h in heads do
		if h.id ~= id then
			continue
		end
		local sparks = sparksAt(h.head)
		sparks:Emit(40)
		smashed[id] = { sparks = sparks, next = os.clock() + 2 + math.random() * 3 }
		-- its head drops at once, with a jolt
		h.current = h.rest * CFrame.Angles(math.rad(-48), 0, math.rad(26))
		h.head.CFrame = h.current
		local flash = Instance.new("PointLight")
		flash.Color = Color3.fromRGB(200, 228, 255)
		flash.Brightness = 5
		flash.Range = 12
		flash.Shadows = false
		flash.Parent = h.head
		task.delay(0.12, function()
			flash:Destroy() -- one flash (well under 3 a second)
		end)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - h.head.Position).Magnitude <= C.smash_hear then
			SoundDirector.play("cam_smash")
			SoundDirector.play("cam_spark")
		end
	end
end

-- the rotation from a to b, capped at maxAngle
local function capped(rest: CFrame, wanted: CFrame, maxAngle: number): CFrame
	local delta = rest:ToObjectSpace(wanted)
	local axis, angle = delta:ToAxisAngle()
	if angle <= maxAngle then
		return wanted
	end
	return rest * CFrame.fromAxisAngle(axis, maxAngle)
end

function CameraHeads.start()
	for _, model in Level.folder("Cameras"):GetChildren() do
		local head = model:FindFirstChild("Head")
		local rest = model:GetAttribute("RestAim")
		if head and head:IsA("BasePart") and typeof(rest) == "CFrame" then
			table.insert(heads, { id = model.Name, head = head, rest = rest, current = rest })
		end
	end
	local maxAngle = math.rad(C.camera_turn_max)
	State.on("Smash", smash)
	State.on("Shift", function(onShift: boolean)
		if not onShift then
			for _, s in smashed do
				local at = s.sparks.Parent
				if at then
					at:Destroy()
				end
			end
			table.clear(smashed)
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		local character = player.Character
		local target = character and character:FindFirstChild("Head")
		local seen: { [string]: boolean } = {}
		for _, id in State.seenBy do
			seen[id] = true
		end
		local step = math.rad(C.camera_turn_speed) * dt
		for _, h in heads do
			local model = h.head.Parent
			local offset = model and model:GetAttribute("AimOffset") or 0
			local rest = if offset ~= 0
				then CFrame.new(h.rest.Position) * CFrame.Angles(0, offset :: number, 0) * h.rest.Rotation
				else h.rest
			local wanted = rest
			local broken = State.tasks and State.tasks.brokenCams
			local s = smashed[h.id]
			if s and State.shift then
				-- broken by him: hanging low, sparking now and then
				wanted = rest * CFrame.Angles(math.rad(-48), 0, math.rad(26))
				if os.clock() >= s.next then
					s.next = os.clock() + 2 + math.random() * 4
					s.sparks:Emit(math.random(4, 9))
				end
			elseif broken and broken[h.id] and State.shift then
				-- a dead camera hangs from its torn line
				wanted = rest * CFrame.Angles(math.rad(-35), 0, math.rad(18))
			end
			if seen[h.id] and target and target:IsA("BasePart") and not State.dead and wanted == rest then
				wanted = capped(rest, CFrame.lookAt(rest.Position, target.Position), maxAngle)
			end
			local delta = h.current:ToObjectSpace(wanted)
			local axis, angle = delta:ToAxisAngle()
			if angle > 1e-3 then
				h.current = h.current * CFrame.fromAxisAngle(axis, math.min(angle, step))
				h.head.CFrame = h.current
			end
		end
	end)
end

return CameraHeads
