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
Config.Sounds = Content.Sounds
Config.CarColors = Content.CarColors
Config.LobbyMap = Content.LobbyMap
Config.Lifts = Content.Lifts
Config.LobbyProps = Content.LobbyProps
Config.Shop = Content.Shop
Config.Daily = Content.Daily
Config.Codes = Content.Codes
Config.Floors = Content.Floors
Config.Stairs = Content.Stairs
Config.Signals = Content.Signals
Config.Chapters = Content.Chapters
Config.Upgrades = Content.Upgrades
Config.Modes = Content.Modes
Config.ShopStations = Content.ShopStations

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

Config.floorById = {} :: { [string]: typeof(Content.Floors[1]) }
for _, floor in Content.Floors do
	Config.floorById[floor.id] = floor
end

Config.signalById = {} :: { [string]: typeof(Content.Signals[1]) }
for _, signal in Content.Signals do
	Config.signalById[signal.id] = signal
end

Config.modeById = {} :: { [string]: typeof(Content.Modes[1]) }
for _, mode in Content.Modes do
	Config.modeById[mode.id] = mode
end

Config.upgradeById = {} :: { [string]: typeof(Content.Upgrades[1]) }
for _, upgrade in Content.Upgrades do
	Config.upgradeById[upgrade.id] = upgrade
end

Config.stairsBySpot = {} :: { [string]: typeof(Content.Stairs[1]) }
for _, row in Content.Stairs do
	Config.stairsBySpot[row.spot] = row
end

-- The floor a world x is on (content/floors.csv: the floors lie side by side along x), and its offset.
function Config.floorAt(x: number): (string, number)
	local best, bestOffset, bestD = "P3", 0, math.huge
	for _, f in Content.Floors do
		local d = math.abs(x - f.offsetX)
		if d < bestD then
			best, bestOffset, bestD = f.id, f.offsetX, d
		end
	end
	return best, bestOffset
end

-- "#rrggbb" -> r, g, b in 0..255 (Color3.fromRGB on the Roblox side, plain numbers in Lune)
function Config.rgb(hex: string): (number, number, number)
	local r, g, b = string.match(hex, "^#(%x%x)(%x%x)(%x%x)$")
	assert(r and g and b, "Config.rgb: bad colour " .. hex)
	return tonumber(r, 16) :: number, tonumber(g, 16) :: number, tonumber(b, 16) :: number
end

return Config
