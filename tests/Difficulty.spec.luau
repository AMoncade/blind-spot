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

function spec.theModeSetsTheNight()
	local M = Config.modeById
	eq((Difficulty.clean({}, 1, C, M) :: Difficulty.Setup).mode, C.mode_default, "no mode: the default")
	eq((Difficulty.clean({ mode = "nightmare" }, 1, C, M) :: Difficulty.Setup).mode, C.mode_default, "unknown mode")
	eq((Difficulty.clean({ mode = "hard" }, 1, C, M) :: Difficulty.Setup).mode, "hard", "a known mode")
	local function pay(mode: string): number
		return Difficulty.payMultiplier({ night = 1, guards = 1, lives = 3, mode = mode }, Config.nightByNumber, C, M)
	end
	ok(pay("easy") < pay("normal") and pay("normal") < pay("hard"), "a harder mode pays more")
	-- and it is harder: fewer cameras, shorter fields, a faster bar, more dead tubes, more smashed cameras
	ok(M.easy.deadCams <= M.normal.deadCams and M.normal.deadCams < M.hard.deadCams, "more dead cameras")
	ok(M.easy.camRange >= M.normal.camRange and M.normal.camRange > M.hard.camRange, "shorter fields")
	ok(M.easy.drain < M.normal.drain and M.normal.drain < M.hard.drain, "a faster bar")
	ok(M.easy.darkTubes < M.normal.darkTubes and M.normal.darkTubes < M.hard.darkTubes, "more dead tubes")
end

return spec
