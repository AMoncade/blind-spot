--!strict
-- The Unseen's director (plan section 4, "Son comportement"): what he does in each phase and whom he goes after. The
-- director sets the pressure, never the rules: these choices only pick a target and a speed, the shadow and the
-- fields still decide where he can be. Pure, for the specs and the simulator.
local Hunt = {}

export type Mode = "prowl" | "approach" | "hunt" | "retreat"

export type Candidate = {
	id: number, -- user id
	filmed: boolean,
	offTime: number, -- seconds off camera in a row
	fieldSteps: number, -- cells to the nearest filmed cell
	marked: boolean?, -- their signal ran out: he knows where they are (Hunt.exposure)
}

-- LIVE: he roams and keeps his distance. FLICKER: he closes in on the most exposed player. BLACKOUT: he hunts.
-- After a kill or a long chase, the director gives the players a break (relief).
function Hunt.mode(phase: string, reliefLeft: number, anyMarked: boolean?): Mode
	if reliefLeft > 0 then
		return "retreat"
	elseif phase == "BLACKOUT" or anyMarked then
		-- a guard whose signal ran out is hunted in any phase
		return "hunt"
	elseif phase == "FLICKER" then
		return "approach"
	end
	return "prowl"
end

function Hunt.speed(mode: Mode, C: any): number
	if mode == "hunt" then
		return C.unseen_speed_hunt
	elseif mode == "approach" then
		return C.unseen_speed_approach
	elseif mode == "retreat" then
		return C.unseen_speed_retreat
	end
	return C.unseen_speed_prowl
end

-- Whom he goes after, or nil. Filmed players are never targets (he can't reach them). approach: the one longest off
-- camera; hunt: longest off camera plus farthest from a field (weight per cell). Ties go to the lower user id, so a
-- night replays the same.
function Hunt.target(list: { Candidate }, mode: Mode, weight: number): number?
	if mode ~= "approach" and mode ~= "hunt" then
		return nil
	end
	-- a marked guard comes first: he goes for them before anyone else
	local anyMarked = false
	for _, c in list do
		if c.marked and not c.filmed then
			anyMarked = true
		end
	end
	local best: number? = nil
	local bestScore = -math.huge
	for _, c in list do
		if not c.filmed and (c.marked or not anyMarked) then
			local score = c.offTime
			if mode == "hunt" then
				score += weight * c.fieldSteps
			end
			if score > bestScore or (score == bestScore and best ~= nil and c.id < best) then
				best, bestScore = c.id, score
			end
		end
	end
	return best
end

-- The signal bar (Adrien, Nov 7): 1 on camera, it drains off camera (faster when the power fails) and fills up again
-- under a camera. Empty, the guard is marked: he knows where they are and hunts them in any phase, until the bar is
-- back over exposure_safe. Returns the new level and whether the guard is marked.
function Hunt.exposure(
	level: number,
	marked: boolean,
	filmed: boolean,
	phase: string,
	dt: number,
	C: any
): (number, boolean)
	if filmed then
		level = math.min(1, level + dt / C.exposure_refill)
	else
		local drain = if phase == "BLACKOUT"
			then C.exposure_drain_blackout
			elseif phase == "FLICKER" then C.exposure_drain_flicker
			else C.exposure_drain_live
		level = math.max(0, level - dt / drain)
	end
	if level <= 0 then
		marked = true
	elseif marked and level >= C.exposure_safe then
		marked = false
	end
	return level, marked
end

-- Can he touch this player? Only in a blind spot (the player off camera for the whole grace), within reach, and only
-- when he is after someone (approach or hunt): prowling in LIVE he doesn't touch anyone (a marked guard turns his
-- prowl into a hunt), and he takes no one during the director's break. Simulator, Nov 7: on night 1, bots died
-- walking into his blind corner during their round; a guard who stumbles on him in LIVE sees him vanish instead.
function Hunt.canKill(distance: number, filmed: boolean, offTime: number, C: any, mode: Mode?): boolean
	if mode == "prowl" or mode == "retreat" then
		return false
	end
	return not filmed and offTime >= C.unwatched_grace and distance <= C.unseen_contact
end

-- Should the target's sound die now? Once the time for him to reach them along his path drops under the lead
-- (plan section 4: "le son meurt 1,5 s avant qu'il soit à portée").
function Hunt.shouldHush(pathLength: number, speed: number, C: any): boolean
	local toReach = math.max(pathLength - C.unseen_contact, 0)
	return speed > 0 and toReach / speed <= C.unseen_hush_lead
end

return Hunt
