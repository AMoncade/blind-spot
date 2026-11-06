--!strict
-- The comfort and accessibility options (plan section 2): head bob and shake 0 to 1, field of view, fewer flashes, the
-- REC dot. Defaults from the config; phase 0 has no settings screen yet, so in Studio they are attributes on the local
-- player (HeadBob, FieldOfView, ReduceFlashes, RecDot) that the controllers read live. Saved in the profile in phase 1.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local C = Config.C

local Settings = {}

local DEFAULTS: { [string]: any } = {
	HeadBob = C.headbob_default,
	FieldOfView = C.fov_default,
	ReduceFlashes = false,
	RecDot = true, -- the ON CAMERA / BLIND SPOT tag
	SafeZones = true, -- the camera fields glow on the floor
}

function Settings.get(name: string): any
	local v = Players.LocalPlayer:GetAttribute(name)
	if v == nil then
		return DEFAULTS[name]
	end
	return v
end

function Settings.start()
	for name, value in DEFAULTS do
		if Players.LocalPlayer:GetAttribute(name) == nil then
			Players.LocalPlayer:SetAttribute(name, value)
		end
	end
end

return Settings
