--!strict
-- K&V SUPPLY (Adrien, 8 Nov): the little shop east of the lobby hall. Its counter and its four stands have prompts
-- (World builds them from content/shop_stations.csv); using one opens the upgrade screen on the guard's client (event
-- OpenUpgrades). Buying a level (action Upgrade) costs the pay of the shifts: the server checks the level and the pay,
-- raises the level in the profile, and the services read it (UnseenService: SIGNAL; SkillService: SPRINT, FLARES;
-- CamcorderService: CAMCORDER).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Upgrades = require(Shared:WaitForChild("Logic"):WaitForChild("Upgrades"))

local Server = script.Parent.Parent
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local Analytics = require(Server:WaitForChild("Core"):WaitForChild("Analytics"))
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))

local UpgradeService = {}

UpgradeService.onShift = nil :: ((player: Player) -> boolean)? -- NightService: no shopping during a shift

local function notify(player: Player, text: string, good: boolean?)
	Net.event():FireClient(player, "Notice", text, good == true)
end

local function buy(player: Player, id: string)
	local def = Config.upgradeById[id]
	local profile = Data.get(player)
	if not def or not profile then
		return
	end
	if UpgradeService.onShift and UpgradeService.onShift(player) then
		return
	end
	local level = Upgrades.level(profile, id)
	local cost = Upgrades.cost(def, level)
	if not cost then
		notify(player, def.name .. " IS AT ITS BEST")
		return
	end
	if profile.pay < cost then
		notify(player, "NOT ENOUGH PAY")
		return
	end
	profile.pay -= cost
	profile.upgrades = profile.upgrades or {}
	profile.upgrades[id] = level + 1
	Data.changed(player)
	Analytics.pay(player, -cost, profile.pay, Enum.AnalyticsEconomyTransactionType.Shop, "upgrade_" .. id)
	notify(player, `{def.name}  LEVEL {level + 1}`, true)
end

function UpgradeService.init()
	Actions.on("Upgrade", function(player: Player, id: unknown)
		if type(id) == "string" then
			buy(player, id)
		end
	end)
end

function UpgradeService.start()
	local lobby = World.lobby
	local shop = lobby and lobby:WaitForChild("Shop", 10)
	if not shop then
		warn("[UpgradeService] no shop in the lobby")
		return
	end
	for _, anchor in shop:GetChildren() do
		local prompt = anchor:FindFirstChildWhichIsA("ProximityPrompt")
		if prompt then
			local upgrade = anchor:GetAttribute("Upgrade")
			prompt.Triggered:Connect(function(player)
				Net.event():FireClient(player, "OpenUpgrades", upgrade)
			end)
		end
	end
end

return UpgradeService
