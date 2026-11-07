--!strict
-- The power cycle of a night (plan section 3).
local Config = require("../src/shared/Config")
local Timeline = require("../src/shared/Logic/Timeline")
local Rng = require("../src/shared/Logic/Rng")

local function eq(a: any, b: any, what: string?)
	if a ~= b then
		error(`{what or "value"}: expected {tostring(b)}, got {tostring(a)}`, 2)
	end
end

local function ok(v: any, what: string)
	if not v then
		error(what, 2)
	end
end

local spec = {}

local function checkContinuous(tl: Timeline.Timeline)
	eq(tl.segments[1].t0, 0, "starts at 0")
	for k = 2, #tl.segments do
		ok(math.abs(tl.segments[k].t0 - tl.segments[k - 1].t1) < 1e-9, `segment {k} starts where {k - 1} ends`)
	end
	ok(math.abs(tl.segments[#tl.segments].t1 - tl.length) < 1e-9, "ends at 6 h")
	eq(tl.segments[#tl.segments].phase, "LIVE", "the night ends on a LIVE")
end

function spec.rngIsDeterministic()
	local a, b = Rng.new(42), Rng.new(42)
	for _ = 1, 50 do
		eq(a.next(), b.next(), "same seed, same draws")
	end
	local r = Rng.new(7)
	for _ = 1, 500 do
		local v = r.int(1, 3)
		ok(v >= 1 and v <= 3, "int in range")
	end
end

function spec.nightOneIsOneLongLive()
	local tl = Timeline.build(Config.nightByNumber[1], Config.Cameras, 1)
	eq(#tl.segments, 1, "segments")
	eq(tl.segments[1].phase, "LIVE", "phase")
	checkContinuous(tl)
end

function spec.nightTwoHasOnlyFalseAlarms()
	local tl = Timeline.build(Config.nightByNumber[2], Config.Cameras, 2)
	checkContinuous(tl)
	local flickers = 0
	for _, seg in tl.segments do
		ok(seg.phase ~= "BLACKOUT", "no blackout on night 2")
		if seg.phase == "FLICKER" then
			flickers += 1
			eq(seg.falseAlarm, true, "every flicker is a false alarm")
		end
	end
	ok(flickers >= 5, "night 2 has flickers")
end

function spec.everyNightIsContinuous()
	for _, def in Config.Nights do
		for seed = 1, 40 do
			checkContinuous(Timeline.build(def, Config.Cameras, seed))
		end
	end
end

function spec.blackoutsFollowTheirFlicker()
	local tl = Timeline.build(Config.nightByNumber[3], Config.Cameras, 3)
	for k, seg in tl.segments do
		if seg.phase == "BLACKOUT" then
			local before = tl.segments[k - 1]
			eq(before.phase, "FLICKER", "a blackout comes after a flicker")
			eq(before.falseAlarm, false, "and that flicker is real")
			-- the REC LEDs of the flicker announce exactly the cameras that hold
			eq(
				table.concat(before.holdouts :: { string }, ","),
				table.concat(seg.holdouts :: { string }, ","),
				"holdouts"
			)
		end
	end
end

function spec.phasesSpeedUpThroughTheNight()
	local def = Config.nightByNumber[3]
	local tl = Timeline.build(def, Config.Cameras, 11)
	local lives, blackouts = {}, {}
	for _, seg in tl.segments do
		if seg.phase == "LIVE" and seg.t1 < tl.length then
			table.insert(lives, seg.t1 - seg.t0)
		elseif seg.phase == "BLACKOUT" then
			table.insert(blackouts, seg.t1 - seg.t0)
		end
	end
	ok(#lives >= 3 and #blackouts >= 2, "enough cycles")
	ok(lives[1] > lives[#lives], "LIVE gets shorter")
	ok(blackouts[1] < blackouts[#blackouts], "BLACKOUT gets longer")
	ok(math.abs(lives[1] - def.liveStart) < 1e-9, "the first LIVE lasts live_start")
end

function spec.aboutOneFlickerInFiveIsFalse()
	local def = Config.nightByNumber[3]
	local flickers, falses = 0, 0
	for seed = 1, 300 do
		for _, seg in Timeline.build(def, Config.Cameras, seed).segments do
			if seg.phase == "FLICKER" then
				flickers += 1
				if seg.falseAlarm then
					falses += 1
				end
			end
		end
	end
	local share = falses / flickers
	ok(share > 0.13 and share < 0.27, `false alarms {share}`)
end

function spec.holdoutsPerZone()
	local def = Config.nightByNumber[3]
	local rng = Rng.new(5)
	for _ = 1, 200 do
		local ids = Timeline.pickHoldouts(Config.Cameras, def, rng)
		local perZone: { [string]: number } = {}
		for _, id in ids do
			local cam = Config.cameraById[id]
			ok(not cam.always, "the booth cameras are never drawn")
			perZone[cam.zone] = (perZone[cam.zone] or 0) + 1
		end
		for _, zone in { "west", "east", "corridor" } do
			local n = perZone[zone] or 0
			ok(n >= def.holdoutsMin and n <= def.holdoutsMax, `{zone}: {n} holdouts`)
		end
	end
end

function spec.activeCamerasPerPhase()
	local live = Timeline.active({ phase = "LIVE", t0 = 0, t1 = 1 }, Config.Cameras)
	eq(#live, #Config.Cameras, "LIVE: all")
	local dark = Timeline.active({ phase = "BLACKOUT", t0 = 0, t1 = 1, holdouts = { "C03" } }, Config.Cameras)
	local expected = {}
	for _, cam in Config.Cameras do
		if cam.always or cam.id == "C03" then
			table.insert(expected, cam.id)
		end
	end
	eq(table.concat(dark, ","), table.concat(expected, ","), "BLACKOUT: the always-on cameras and the holdouts")
end

function spec.clockRunsMidnightToSix()
	local tl = Timeline.build(Config.nightByNumber[1], Config.Cameras, 1)
	local h, m = Timeline.clock(tl, 0, 0, 6)
	eq(h * 60 + m, 0, "midnight")
	h, m = Timeline.clock(tl, tl.length / 2, 0, 6)
	eq(h * 60 + m, 180, "3 h")
	h = Timeline.clock(tl, tl.length * 2, 0, 6)
	eq(h, 6, "6 h after the end")
end

return spec
