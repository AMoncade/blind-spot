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
	eq(s.lives, 1, "one life, whatever was sent")
	eq(Difficulty.clean("solo", 3, C), nil, "not a table")
	local d = Difficulty.clean({}, 2, C) :: Difficulty.Setup
	eq(d.night, 2, "default: the furthest night")
	eq(d.lives, 1, "one life")
end

function spec.harderPaysMore()
	local easy = Difficulty.payMultiplier({ night = 1, guards = 4, lives = 3 }, Config.nightByNumber, C)
	eq(easy, 1, "night 1, four guards, three lives: base pay")
	local alone = Difficulty.payMultiplier({ night = 1, guards = 1, lives = 3 }, Config.nightByNumber, C)
	local later = Difficulty.payMultiplier({ night = 5, guards = 4, lives = 3 }, Config.nightByNumber, C)
	ok(alone > easy and later > easy, "each harder setting pays more")
	local hardest = Difficulty.payMultiplier({ night = #Config.Nights, guards = 1, lives = 1 }, Config.nightByNumber, C)
	ok(hardest > later and hardest > alone, "everything at once pays the most")
	local name, step = Difficulty.label(C.difficulty_steps[#C.difficulty_steps] + 0.5, C)
	eq(step, 5, "past the last threshold: the last step")
	eq(name, string.split(C.difficulty_names, ";")[5], "its name")
	local calm, first = Difficulty.label(easy, C)
	eq(first, 1, "the easiest is the first step")
	ok(calm ~= name, "different names")
end

function spec.theModeSetsTheNight()
	local M = Config.modeById
	eq((Difficulty.clean({}, 1, C, M) :: Difficulty.Setup).mode, C.mode_default, "no mode: the default")
	eq((Difficulty.clean({ mode = "impossible" }, 1, C, M) :: Difficulty.Setup).mode, C.mode_default, "unknown mode")
	eq((Difficulty.clean({ mode = "hard" }, 1, C, M) :: Difficulty.Setup).mode, "hard", "a known mode")
	local function pay(mode: string): number
		return Difficulty.payMultiplier({ night = 1, guards = 1, lives = 3, mode = mode }, Config.nightByNumber, C, M)
	end
	ok(pay("easy") < pay("normal") and pay("normal") < pay("hard"), "a harder mode pays more")
	-- and it is harder: fewer cameras, shorter fields, a faster bar, more dead tubes, more smashed cameras
	ok(M.easy.deadCams <= M.normal.deadCams and M.normal.deadCams < M.hard.deadCams, "more dead cameras")
	ok(M.easy.camRange >= M.normal.camRange and M.normal.camRange > M.hard.camRange, "shorter fields")
	ok(
		M.easy.drain < M.normal.drain and M.normal.drain < M.hard.drain and M.hard.drain < M.nightmare.drain,
		"a faster bar"
	)
	-- Adrien, 8 Nov: NORMAL twice EASY (1.5x upgraded), HARD twice NORMAL, NIGHTMARE five times HARD
	eq(M.normal.drain, M.easy.drain * 2, "NORMAL: twice EASY")
	ok(math.abs(M.normal.drainMax - M.easy.drain * 1.5) < 1e-9, "NORMAL upgraded: 1.5x EASY")
	eq(M.hard.drain, M.normal.drain * 2, "HARD: twice NORMAL")
	eq(M.nightmare.drain, M.hard.drain * 5, "NIGHTMARE: five times HARD")
	ok(not M.hard.sprint and not M.nightmare.sprint and M.easy.sprint and M.normal.sprint, "no SPRINT in HARD")
	eq(M.normal.smashEvery, 60, "NORMAL: a camera every minute")
	eq(M.nightmare.smashEvery, 20, "NIGHTMARE: a camera every 20 s")
	eq(M.easy.flares, 1, "EASY: one more flare")
	ok(M.easy.darkTubes < M.normal.darkTubes and M.normal.darkTubes < M.hard.darkTubes, "more dead tubes")
end

return spec
