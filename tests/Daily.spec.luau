--!strict
-- The daily reward streak and the config behind the lobby menus.
local Config = require("../src/shared/Config")
local Daily = require("../src/shared/Logic/Daily")

local DAY = Config.C.daily_day_seconds
local WEEK = #Config.Daily

local function eq(a: any, b: any, what: string?)
	if a ~= b then
		error(`{what or "value"}: expected {tostring(b)}, got {tostring(a)}`, 2)
	end
end

local spec = {}

function spec.firstClaimIsDayOne()
	local s, slot = Daily.claim({ streak = 0, lastDay = 0 }, 100 * DAY + 5, DAY, WEEK)
	eq(slot, 1, "slot")
	eq((s :: Daily.State).streak, 1, "streak")
	eq((s :: Daily.State).lastDay, 100, "day")
end

function spec.onceADay()
	local s = { streak = 1, lastDay = 100 }
	eq(Daily.claim(s, 100 * DAY + 80000, DAY, WEEK), nil, "same day")
	eq(Daily.secondsLeft(s, 100 * DAY + 80000, DAY), DAY - 80000, "time left")
end

function spec.streakContinuesAndLoops()
	local s: Daily.State = { streak = 0, lastDay = 0 }
	local slots = {}
	for d = 0, WEEK do
		local nextState, slot = Daily.claim(s, (200 + d) * DAY + 10, DAY, WEEK)
		s = nextState :: Daily.State
		table.insert(slots, slot)
	end
	eq(slots[WEEK], WEEK, "last day of the week")
	eq(slots[WEEK + 1], 1, "the week loops")
	eq(s.streak, WEEK + 1, "streak keeps counting")
end

function spec.missingADayResets()
	local s, slot = Daily.claim({ streak = 4, lastDay = 300 }, 302 * DAY + 1, DAY, WEEK)
	eq(slot, 1, "back to day 1")
	eq((s :: Daily.State).streak, 1, "streak")
end

function spec.shopConfigIsSane()
	local ids = {}
	for _, item in Config.Shop do
		eq(ids[item.id], nil, "unique id " .. item.id)
		ids[item.id] = true
		local kinds = { viewfinder = true, uniform = true, lamp = true, robux = true }
		assert(kinds[item.kind], "kind " .. item.kind)
		assert(item.unlock == "" or item.unlock == "group", "unlock " .. item.unlock)
		Config.rgb(item.frame)
		Config.rgb(item.rec)
		Config.rgb(item.text)
	end
	eq(Config.shopById.vf_classic.price, 0, "the factory viewfinder is free")
	-- what every new profile owns and wears (Core/Data, TEMPLATE)
	eq(Config.shopById.un_navy.price, 0, "the night shift jacket is free")
	eq(Config.shopById.lp_halogen.price, 0, "the halogen lamp is free")
	eq(Config.shopById.un_kv.unlock, "group", "the company uniform comes with the group")
end

return spec
