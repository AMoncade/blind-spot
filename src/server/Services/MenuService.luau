--!strict
-- The lobby menus on the server (the client draws them in Ui/Menu): DAILY claims, the SHOP (viewfinders bought with
-- the pay earned on shifts, equipped; Robux items only prompt when Adrien has created their product), codes, and the
-- comfort settings (saved in the profile and copied to Player attributes the client's Settings reads).
-- Every action checks its arguments; prices and rewards come from the config (content/shop.csv, daily.csv, codes.csv).
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Daily = require(Shared:WaitForChild("Logic"):WaitForChild("Daily"))

local Server = script.Parent.Parent
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local Analytics = require(Server:WaitForChild("Core"):WaitForChild("Analytics"))

local C = Config.C

local MenuService = {}

-- the settings a client may save, with their allowed values
local SETTINGS: { [string]: (any) -> boolean } = {
	HeadBob = function(v)
		return type(v) == "number" and table.find(C.settings_bob_steps, v) ~= nil
	end,
	FieldOfView = function(v)
		return type(v) == "number" and table.find(C.settings_fov_steps, v) ~= nil
	end,
	ReduceFlashes = function(v)
		return type(v) == "boolean"
	end,
	RecDot = function(v)
		return type(v) == "boolean"
	end,
	SafeZones = function(v)
		return type(v) == "boolean"
	end,
}

local function notify(player: Player, text: string, good: boolean?)
	Net.event():FireClient(player, "Notice", text, good == true)
end

local function applySettings(player: Player, settings: { [string]: any })
	for name, value in settings do
		if SETTINGS[name] and SETTINGS[name](value) then
			player:SetAttribute(name, value)
		end
	end
end

-- the cosmetic kinds a guard wears one of (content/shop.csv, kind): the profile field of the same name
local COSMETIC = { viewfinder = true, uniform = true, lamp = true }

MenuService.onEquip = nil :: ((player: Player) -> ())? -- a guard changed what they wear (UniformService)

local function equip(profile: any, item: any): boolean
	if not COSMETIC[item.kind] then
		return false
	end
	profile[item.kind] = item.id
	return true
end

-- The group's reward (shop items with unlock "group"): a member of the game's Roblox group owns them. Checked when the
-- profile loads and when the guard asks for a group item (they may have joined meanwhile).
local function member(player: Player): boolean
	if C.group_id == 0 then
		return false
	end
	local ok, inGroup = pcall(function()
		return player:IsInGroup(C.group_id)
	end)
	return ok and inGroup == true
end

local function grantGroupItems(player: Player, profile: any): boolean
	if not member(player) then
		return false
	end
	local granted = false
	for _, item in Config.Shop do
		if item.unlock == "group" and not profile.owned[item.id] then
			profile.owned[item.id] = true
			granted = true
		end
	end
	if granted then
		Data.changed(player)
		notify(player, "KESTREL & VANE: YOUR UNIFORM IS IN THE SUPPLY ROOM", true)
	end
	return granted
end

function MenuService.init()
	Data.onLoaded(function(player, profile)
		applySettings(player, profile.settings)
		if profile.nights == 0 then
			Analytics.onboarding(player, 1)
		end
		task.spawn(grantGroupItems, player, profile)
		Data.send(player)
		if MenuService.onEquip then
			MenuService.onEquip(player)
		end
	end)

	Actions.on("Profile", function(player: Player)
		Data.send(player)
	end)

	Actions.on("ClaimDaily", function(player: Player)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local state, slot = Daily.claim(profile.daily, os.time(), C.daily_day_seconds, #Config.Daily)
		if not state or not slot then
			return
		end
		profile.daily = state
		local reward = Config.Daily[slot].pay
		profile.pay += reward
		Analytics.pay(player, reward, profile.pay, Enum.AnalyticsEconomyTransactionType.TimedReward, "daily" .. slot)
		Data.changed(player)
		notify(player, `DAY {slot}  +${reward}`, true)
	end)

	Actions.on("Buy", function(player: Player, id: unknown)
		local profile = Data.get(player)
		local item = type(id) == "string" and Config.shopById[id] or nil
		if not profile or not item then
			return
		end
		if item.kind == "robux" then
			if item.product ~= 0 then
				MarketplaceService:PromptProductPurchase(player, item.product)
			else
				notify(player, "COMING SOON")
			end
			return
		end
		if profile.owned[item.id] then
			return
		end
		if item.unlock == "group" then
			if grantGroupItems(player, profile) then
				equip(profile, item)
				Data.changed(player)
				if MenuService.onEquip then
					MenuService.onEquip(player)
				end
			else
				notify(player, "JOIN KESTREL & VANE SECURITY (THE GAME'S GROUP)")
			end
			return
		end
		if profile.pay < item.price then
			notify(player, "NOT ENOUGH PAY")
			return
		end
		profile.pay -= item.price
		profile.owned[item.id] = true
		Analytics.pay(player, -item.price, profile.pay, Enum.AnalyticsEconomyTransactionType.Shop, item.id)
		equip(profile, item)
		Data.changed(player)
		notify(player, `{string.upper(item.name)} EQUIPPED`, true)
		if MenuService.onEquip then
			MenuService.onEquip(player)
		end
	end)

	Actions.on("Equip", function(player: Player, id: unknown)
		local profile = Data.get(player)
		local item = type(id) == "string" and Config.shopById[id] or nil
		if profile and item and profile.owned[item.id] and equip(profile, item) then
			Data.changed(player)
			if MenuService.onEquip then
				MenuService.onEquip(player)
			end
		end
	end)

	Actions.on("Redeem", function(player: Player, code: unknown)
		local profile = Data.get(player)
		if not profile or type(code) ~= "string" or #code > 32 then
			return
		end
		local clean = string.upper((string.gsub(code, "%s", "")))
		for _, c in Config.Codes do
			if c.code == clean then
				if profile.codes[clean] then
					notify(player, "CODE ALREADY USED")
				else
					profile.codes[clean] = true
					profile.pay += c.pay
					Analytics.pay(player, c.pay, profile.pay, Enum.AnalyticsEconomyTransactionType.Gameplay, "code")
					Data.changed(player)
					notify(player, `CODE ACCEPTED  +${c.pay}`, true)
				end
				return
			end
		end
		notify(player, "UNKNOWN CODE")
	end)

	Actions.on("SetSetting", function(player: Player, name: unknown, value: unknown)
		local profile = Data.get(player)
		if not profile or type(name) ~= "string" or not SETTINGS[name] or not SETTINGS[name](value) then
			return
		end
		profile.settings[name] = value
		player:SetAttribute(name, value)
		Data.changed(player)
	end)
end

return MenuService
