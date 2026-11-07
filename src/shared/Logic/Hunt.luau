--!strict
-- The Unseen's director (plan section 4, reworked with Adrien on 7 November 2026): he doesn't walk. He waits in a
-- blind spot facing his guard, and every few seconds he is somewhere else, as near to them as their signal bar is low;
-- when the bar is empty he is on them (the catch). These choices set the pressure, never the rules: he only ever
-- stands in shadow (Logic/Shadow), and a field that touches him sends him away. Pure, for the specs and the simulator.
local Hunt = {}

export type Candidate = {
	id: number, -- user id
	filmed: boolean,
	exposure: number, -- the signal bar, 1 full
}

-- Whom he is after: the guard whose bar is lowest, the ones off camera first. Ties go to the lower user id, so a night
-- replays the same.
function Hunt.target(list: { Candidate }): number?
	local best: Candidate? = nil
	for _, c in list do
		local b = best
		if
			not b
			or (b.filmed and not c.filmed)
			or (b.filmed == c.filmed and (c.exposure < b.exposure or (c.exposure == b.exposure and c.id < b.id)))
		then
			best = c
		end
	end
	return if best then best.id else nil
end

-- The signal bar (Adrien, 7 Nov): 1 on camera, it drains off camera (faster when the power fails, and on harder nights:
-- drainScale) and fills up again under a camera. Empty: he is on the guard. Returns the new level and whether it is
-- empty.
function Hunt.exposure(
	level: number,
	_marked: boolean,
	filmed: boolean,
	phase: string,
	dt: number,
	C: any,
	drainScale: number?
): (number, boolean)
	if filmed then
		level = math.min(1, level + dt / C.exposure_refill)
	else
		local drain = if phase == "BLACKOUT"
			then C.exposure_drain_blackout
			elseif phase == "FLICKER" then C.exposure_drain_flicker
			else C.exposure_drain_live
		level = math.max(0, level - dt * (drainScale or 1) / drain)
	end
	return level, level <= 0
end

-- How far from his guard he appears: far when their bar is full, right behind them when it is almost empty.
function Hunt.stalkDistance(exposure: number, C: any): number
	local e = math.clamp(exposure, 0, 1) ^ C.stalk_curve
	return C.stalk_near + (C.stalk_far - C.stalk_near) * e
end

-- Seconds until his next jump: shorter when the power fails, on harder nights (scale) and as the bar drops.
-- roll: a number in [0, 1) (the night's Rng).
function Hunt.jumpDelay(phase: string, exposure: number, scale: number, roll: number, C: any): number
	local range = if phase == "BLACKOUT"
		then C.stalk_blackout
		elseif phase == "FLICKER" then C.stalk_flicker
		else C.stalk_live
	local d = range[1] + (range[2] - range[1]) * roll
	d *= 0.45 + 0.55 * math.clamp(exposure, 0, 1)
	return d / math.max(scale, 0.1)
end

-- The catch: the guard's bar is empty and no camera has seen them for the whole grace.
function Hunt.catches(exposure: number, filmed: boolean, offTime: number, C: any): boolean
	return exposure <= 0 and not filmed and offTime >= C.unwatched_grace
end

-- The hush (plan section 4, "Toujours une chance"): the guard's sound dies when he is about to come.
function Hunt.shouldHush(exposure: number, filmed: boolean, C: any): boolean
	return not filmed and exposure <= C.hush_exposure
end

return Hunt
