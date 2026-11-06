--!strict
-- Draws the Unseen for the naked eye and hides him in every camera view (plan sections 4 and 11, UnseenView):
-- "visible à l'œil, jamais à l'écran". The server sends where he is; through the raised camcorder he is never there.
-- Phase 0 draws the grey silhouette (too tall, too thin, head tilted) from client-only parts; the rigged Blender
-- model replaces it in phase 1.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Camcorder = require(script.Parent:WaitForChild("Camcorder"))

local C = Config.C

local UnseenView = {}

local model: Model
local shown = false
local x, z, yaw = 0, 0, 0

-- part offsets from his feet, as fractions of his height: v = x, y, z, sx, sy, sz, tilt in degrees around z
local SHAPE = {
	{ name = "LegL", v = { -0.035, 0.22, 0, 0.045, 0.44, 0.05, 2 } },
	{ name = "LegR", v = { 0.035, 0.22, 0, 0.045, 0.44, 0.05, -2 } },
	{ name = "Torso", v = { 0, 0.6, 0.01, 0.12, 0.34, 0.06, 0 } },
	{ name = "ArmL", v = { -0.085, 0.5, 0.01, 0.03, 0.5, 0.035, 4 } },
	{ name = "ArmR", v = { 0.085, 0.5, 0.01, 0.03, 0.5, 0.035, -4 } },
	{ name = "Neck", v = { 0.01, 0.8, 0.02, 0.03, 0.06, 0.03, -15 } },
	{ name = "Head", v = { 0.035, 0.85, 0.03, 0.07, 0.1, 0.075, -32 } },
}

local function build(): Model
	local m = Instance.new("Model")
	m.Name = "Unseen"
	local h = C.unseen_height
	local color = Color3.fromRGB(Config.rgb(C.unseen_color))
	for _, s in SHAPE do
		local p = Instance.new("Part")
		p.Name = s.name
		local v = s.v
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = Vector3.new(v[4], v[5], v[6]) * h
		p:SetAttribute("Offset", CFrame.new(Vector3.new(v[1], v[2], v[3]) * h) * CFrame.Angles(0, 0, math.rad(v[7])))
		p.Parent = m
	end
	return m
end

local function place()
	local base = CFrame.new(x, C.floor_y, z) * CFrame.Angles(0, yaw, 0)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			p.CFrame = base * (p:GetAttribute("Offset") :: CFrame)
		end
	end
end

function UnseenView.start()
	model = build()
	RunService.RenderStepped:Connect(function(dt)
		local u = State.unseen
		-- rule 3: never on a screen, the camcorder's or a security camera's (the watcher)
		local visible = u.present and State.night ~= nil and not Camcorder.raised and not State.dead and not State.down
		if visible and not shown then
			-- he appears where he is, never sliding in from his last place
			x, z, yaw = u.x, u.z, u.yaw
		end
		if visible ~= shown then
			shown = visible
			model.Parent = if visible then workspace else nil
		end
		if not visible then
			return
		end
		local a = math.min(1, dt * 10)
		local jump = (u.x - x) ^ 2 + (u.z - z) ^ 2 > 36
		x = if jump then u.x else x + (u.x - x) * a
		z = if jump then u.z else z + (u.z - z) * a
		yaw = u.yaw
		place()
	end)
end

return UnseenView
