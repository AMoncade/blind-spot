--!strict
-- The daily reward (the lobby's DAILY): one claim per UTC day; claiming the day after the last claim continues the
-- streak, missing a day starts it again at day 1; the reward follows Config.Daily and the week loops. Pure.
local Daily = {}

export type State = { streak: number, lastDay: number } -- lastDay: the UTC day index of the last claim, 0 = never

function Daily.dayIndex(now: number, daySeconds: number): number
	return math.floor(now / daySeconds)
end

function Daily.canClaim(state: State, now: number, daySeconds: number): boolean
	return Daily.dayIndex(now, daySeconds) > state.lastDay
end

-- the streak the next claim would give (1..), and the index into the reward list (1..#rewards)
function Daily.nextStreak(state: State, now: number, daySeconds: number, weekLength: number): (number, number)
	local today = Daily.dayIndex(now, daySeconds)
	local streak = if state.lastDay > 0 and today == state.lastDay + 1 then state.streak + 1 else 1
	if not Daily.canClaim(state, now, daySeconds) then
		streak = math.max(state.streak, 1)
	end
	return streak, (streak - 1) % weekLength + 1
end

-- claims: the new state and the reward index, or nil when today is already claimed
function Daily.claim(state: State, now: number, daySeconds: number, weekLength: number): (State?, number?)
	if not Daily.canClaim(state, now, daySeconds) then
		return nil, nil
	end
	local streak, slot = Daily.nextStreak(state, now, daySeconds, weekLength)
	return { streak = streak, lastDay = Daily.dayIndex(now, daySeconds) }, slot
end

-- seconds until the next claim opens
function Daily.secondsLeft(state: State, now: number, daySeconds: number): number
	if Daily.canClaim(state, now, daySeconds) then
		return 0
	end
	return (state.lastDay + 1) * daySeconds - now
end

return Daily
