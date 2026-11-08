--!strict
-- The K&V SUPPLY upgrades (Logic/Upgrades, content/upgrades.csv).
local Config = require("../src/shared/Config")
local Upgrades = require("../src/shared/Logic/Upgrades")

local function ok(v: any, what: string)
	if not v then
		error(what, 2)
	end
end

local function eq(a: any, b: any, what: string?)
	if a ~= b then
		error(`{what or "value"}: expected {tostring(b)}, got {tostring(a)}`, 2)
	end
end

local spec = {}

function spec.everyUpgradeIsWhole()
	for _, def in Config.Upgrades do
		eq(#def.values, def.max, def.id .. ": one value per level")
		ok(#def.values2 == 0 or #def.values2 == def.max, def.id .. ": its second values too")
		ok(Config.ShopStations ~= nil, "the shop has stations")
	end
	for _, station in Config.ShopStations do
		ok(station.upgrade == "" or Config.upgradeById[station.upgrade], station.id .. ": a known upgrade")
	end
end

function spec.aNewGuardStartsAtLevelOne()
	eq(Upgrades.level(nil, "signal"), 1, "no profile")
	eq(Upgrades.level({ upgrades = {} }, "signal"), 1, "never bought")
	eq(Upgrades.level({ upgrades = { signal = 4 } }, "signal"), 4, "bought")
end

function spec.levelsGetBetterAndDearer()
	local signal = Config.upgradeById.signal
	-- the signal bar: fast at level 1, slow at the top (Adrien, 8 Nov)
	eq(Upgrades.value(signal, 1), 1, "level 1 drains at the base speed")
	ok(Upgrades.value(signal, signal.max) < 0.5, "the last level drains less than half as fast")
	for _, def in Config.Upgrades do
		local last = Upgrades.cost(def, 1) :: number
		for level = 2, def.max - 1 do
			local cost = Upgrades.cost(def, level) :: number
			ok(cost > last, def.id .. ": each level costs more")
			last = cost
		end
		eq(Upgrades.cost(def, def.max), nil, def.id .. ": nothing to buy at the max")
	end
	local sprint = Config.upgradeById.sprint
	local burst1, cooldown1 = Upgrades.value(sprint, 1)
	local burst5, cooldown5 = Upgrades.value(sprint, sprint.max)
	ok(burst5 > burst1 and (cooldown5 :: number) < (cooldown1 :: number), "a better sprint: longer and sooner")
end

function spec.withoutUpgradesTheBarIsFast()
	-- no upgrade: the bar empties in a LIVE in under 20 s on the first night (Adrien: hard without upgrades)
	local first = Config.nightByNumber[1]
	ok(Config.C.exposure_drain_live / first.unseenSpeed < 20, "night 1, LIVE, no upgrade: under 20 s")
end

return spec
