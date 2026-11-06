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
Config.Spots = Content.Spots
Config.Tasks = Content.Tasks
Config.Items = Content.Items
Config.Signs = Content.Signs
Config.Tapes = Content.Tapes
Config.Radio = Content.Radio
Config.Logbook = Content.Logbook
Config.CarColors = Content.CarColors
Config.LobbyMap = Content.LobbyMap
Config.Lifts = Content.Lifts
Config.LobbyProps = Content.LobbyProps
Config.Shop = Content.Shop
Config.Daily = Content.Daily
Config.Codes = Content.Codes

Config.spotById = {} :: { [string]: typeof(Content.Spots[1]) }
for _, spot in Content.Spots do
	Config.spotById[spot.id] = spot
end

Config.tapeById = {} :: { [string]: typeof(Content.Tapes[1]) }
for _, tape in Content.Tapes do
	Config.tapeById[tape.id] = tape
end

Config.itemById = {} :: { [string]: typeof(Content.Items[1]) }
for _, item in Content.Items do
	Config.itemById[item.id] = item
end

Config.shopById = {} :: { [string]: typeof(Content.Shop[1]) }
for _, item in Content.Shop do
	Config.shopById[item.id] = item
end

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
