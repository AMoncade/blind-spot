--!strict
-- The shift setup in the lobby: harder settings pay more (Logic/Difficulty).
local Config = require("../src/shared/Config")
local Difficulty = require("../src/shared/Logic/Difficulty")

local C = Config.C

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

function spec.aSetupIsAlwaysValid()
	local s = Difficulty.clean({ night = 9, guards = 0, lives = 7 }, 3, C) :: Difficulty.Setup
	eq(s.night, 3, "night capped at the unlocked one")
	eq(s.guards, 1, "at least one guard")
	eq(s.lives, #C.lives_reward, "lives capped")
	eq(Difficulty.clean("solo", 3, C), nil, "not a table")
	local d = Difficulty.clean({}, 2, C) :: Difficulty.Setup
	eq(d.night, 2, "default: the furthest night")
	eq(d.lives, C.shift_lives, "default lives")
end

function spec.harderPaysMore()
	local easy = Difficulty.payMultiplier({ night = 1, guards = 4, lives = 3 }, Config.nightByNumber, C)
	eq(easy, 1, "night 1, four guards, three lives: base pay")
	local fewerLives = Difficulty.payMultiplier({ night = 1, guards = 4, lives = 1 }, Config.nightByNumber, C)
	local alone = Difficulty.payMultiplier({ night = 1, guards = 1, lives = 3 }, Config.nightByNumber, C)
	local later = Difficulty.payMultiplier({ night = 5, guards = 4, lives = 3 }, Config.nightByNumber, C)
	ok(fewerLives > easy and alone > easy and later > easy, "each harder setting pays more")
	local hardest = Difficulty.payMultiplier({ night = #Config.Nights, guards = 1, lives = 1 }, Config.nightByNumber, C)
	ok(hardest > later and hardest > fewerLives, "everything at once pays the most")
	local name, step = Difficulty.label(hardest, C)
	eq(step, 5, "the hardest setup is the last step")
	eq(name, string.split(C.difficulty_names, ";")[5], "its name")
	local calm, first = Difficulty.label(easy, C)
	eq(first, 1, "the easiest is the first step")
	ok(calm ~= name, "different names")
end

return spec
