--!strict
-- The single entry to every number of the game (CLAUDE.md, "Tous les chiffres viennent de la config"): Config.Content
-- holds the modules generated from content/*.csv (scripts/make_config.py), Config.C the constants, and the lookups
-- below are built once from them. In Lune, init.luau resolves "@self" to its own folder.
local Content = require(if script then script:WaitForChild("Content") else "@self/Content")

local Config = {}
Config.Content = Content
Config.C = Content.Constants
Config.Cameras = Content.Cameras
Config.Map = Content.Map
Config.Nights = Content.Nights
Config.Rounds = Content.Rounds

Config.cameraById = {} :: { [string]: typeof(Content.Cameras[1]) }
for _, cam in Content.Cameras do
	Config.cameraById[cam.id] = cam
end

Config.nightByNumber = {} :: { [number]: typeof(Content.Nights[1]) }
for _, night in Content.Nights do
	Config.nightByNumber[night.night] = night
end

-- "#rrggbb" -> r, g, b in 0..255 (Color3.fromRGB on the Roblox side, plain numbers in Lune)
function Config.rgb(hex: string): (number, number, number)
	local r, g, b = string.match(hex, "^#(%x%x)(%x%x)(%x%x)$")
	assert(r and g and b, "Config.rgb: bad colour " .. hex)
	return tonumber(r, 16) :: number, tonumber(g, 16) :: number, tonumber(b, 16) :: number
end

return Config
