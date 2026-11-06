--!strict
-- "La caméra te suit" (plan section 3): a camera that films you turns slowly toward you, never more than
-- camera_turn_max from where it is aimed, and goes back to rest when you leave its field. Which cameras film the
-- player comes from the server (State.seenBy); the turning is only drawn here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Level = require(script.Parent.Parent:WaitForChild("Level"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local C = Config.C
local player = Players.LocalPlayer

local CameraHeads = {}

type Head = { id: string, head: BasePart, rest: CFrame, current: CFrame }

local heads: { Head } = {}

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
			if broken and broken[h.id] and State.shift then
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
