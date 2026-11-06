--!strict
-- The power cycle of one night (plan section 3): LIVE, FLICKER, BLACKOUT, again, faster as the night goes on. Built
-- once from the night's config and a seed, sent to every client with the server start time, so four players see the
-- same tube die at the same moment (plan section 11). Pure: the specs and the simulator build the same nights.
local Rng = require(if script then script.Parent:WaitForChild("Rng") else "./Rng")

local Timeline = {}

export type Phase = "LIVE" | "FLICKER" | "BLACKOUT"

export type Segment = {
	phase: Phase,
	t0: number, -- seconds since the night started
	t1: number,
	holdouts: { string }?, -- FLICKER and BLACKOUT: the cameras that keep their REC LED and stay on
	falseAlarm: boolean?, -- FLICKER only: the lights come back, no blackout
}

export type Timeline = {
	night: number,
	seed: number,
	length: number,
	segments: { Segment },
}

export type NightDef = {
	night: number,
	length: number,
	flicker: boolean,
	blackout: boolean,
	liveStart: number,
	liveEnd: number,
	flickerStart: number,
	flickerEnd: number,
	blackoutStart: number,
	blackoutEnd: number,
	falseAlarmEvery: number,
	holdoutsMin: number,
	holdoutsMax: number,
}

export type CameraDef = { id: string, zone: string, always: boolean }

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- Per zone, between holdoutsMin and holdoutsMax cameras keep running (never more than the zone has). Cameras marked
-- always (the security booth) never go dark and are never drawn.
function Timeline.pickHoldouts(cameras: { CameraDef }, def: NightDef, rng: Rng.Rng): { string }
	local zones: { [string]: { string } } = {}
	local order = {}
	for _, cam in cameras do
		if not cam.always then
			if not zones[cam.zone] then
				zones[cam.zone] = {}
				table.insert(order, cam.zone)
			end
			table.insert(zones[cam.zone], cam.id)
		end
	end
	table.sort(order)
	local out = {}
	for _, zone in order do
		local ids = zones[zone]
		table.sort(ids)
		local n = math.min(#ids, rng.int(def.holdoutsMin, def.holdoutsMax))
		local shuffled = rng.shuffle(ids)
		for k = 1, n do
			table.insert(out, shuffled[k])
		end
	end
	table.sort(out)
	return out
end

function Timeline.build(def: NightDef, cameras: { CameraDef }, seed: number): Timeline
	local rng = Rng.new(seed)
	local segments: { Segment } = {}
	local t = 0
	local function push(seg: Segment)
		table.insert(segments, seg)
	end
	if not def.flicker then
		push({ phase = "LIVE", t0 = 0, t1 = def.length })
		return { night = def.night, seed = seed, length = def.length, segments = segments }
	end
	while t < def.length do
		local p = t / def.length
		local live = lerp(def.liveStart, def.liveEnd, p)
		push({ phase = "LIVE", t0 = t, t1 = math.min(t + live, def.length) })
		t += live
		if t >= def.length then
			break
		end
		p = t / def.length
		local flicker = lerp(def.flickerStart, def.flickerEnd, p)
		local holdouts = Timeline.pickHoldouts(cameras, def, rng)
		local falseAlarm = not def.blackout or rng.next() < 1 / def.falseAlarmEvery
		local blackout = lerp(def.blackoutStart, def.blackoutEnd, p)
		-- a flicker or a blackout that wouldn't fit before 6 h is not started: the night ends on a LIVE
		if t + flicker + (if falseAlarm then 0 else blackout) > def.length then
			break
		end
		push({ phase = "FLICKER", t0 = t, t1 = t + flicker, holdouts = holdouts, falseAlarm = falseAlarm })
		t += flicker
		if not falseAlarm then
			push({ phase = "BLACKOUT", t0 = t, t1 = t + blackout, holdouts = holdouts })
			t += blackout
		end
	end
	-- the last LIVE runs to the end of the night
	local last = segments[#segments]
	if last.phase == "LIVE" then
		last.t1 = def.length
	elseif last.t1 < def.length then
		push({ phase = "LIVE", t0 = last.t1, t1 = def.length })
	end
	return { night = def.night, seed = seed, length = def.length, segments = segments }
end

-- the segment playing at t (seconds since the start), and its index; the last one after the end
function Timeline.at(tl: Timeline, t: number): (Segment, number)
	for k, seg in tl.segments do
		if t < seg.t1 then
			return seg, k
		end
	end
	return tl.segments[#tl.segments], #tl.segments
end

-- The cameras running during a segment: every camera in LIVE and FLICKER, the holdouts and the always-on ones in
-- BLACKOUT.
function Timeline.active(seg: Segment, cameras: { CameraDef }): { string }
	local out = {}
	local keep: { [string]: boolean } = {}
	if seg.holdouts then
		for _, id in seg.holdouts do
			keep[id] = true
		end
	end
	for _, cam in cameras do
		if seg.phase ~= "BLACKOUT" or cam.always or keep[cam.id] then
			table.insert(out, cam.id)
		end
	end
	return out
end

-- the night clock shown on the watch: hours from clockStart to clockEnd over the night
function Timeline.clock(tl: Timeline, t: number, clockStart: number, clockEnd: number): (number, number)
	local hours = clockStart + (clockEnd - clockStart) * math.clamp(t / tl.length, 0, 1)
	local h = math.floor(hours)
	return h, math.floor((hours - h) * 60)
end

return Timeline
