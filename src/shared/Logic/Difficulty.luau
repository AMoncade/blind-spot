--!strict
-- The shift a guard sets up in the lobby (Adrien, 7 Nov: "choisir le nombre de joueurs, la map, le chapitre, le
-- nombre de vies ... ça calcule la difficulté et donne plus de récompense si c'est plus difficile"). Harder settings
-- pay more: the night's own reward (nights.csv), fewer lives, fewer guards. Pure: the lobby screen shows it before
-- the start, the server uses the same numbers at 6 AM.
local Difficulty = {}

export type Setup = {
	night: number, -- 1 .. the guard's unlocked night
	guards: number, -- 1 to lift_capacity: how many guards the lift waits for
	lives: number, -- 1 to 3: catches the team survives (the last one ends a solo night, downs a co-op guard)
}

-- a setup from anything a client sent, made valid (nil: not a setup at all)
function Difficulty.clean(raw: unknown, maxNight: number, C: any): Setup?
	if type(raw) ~= "table" then
		return nil
	end
	local t = raw :: { [string]: unknown }
	local function int(v: unknown, lo: number, hi: number, default: number): number
		if type(v) ~= "number" or v ~= v then
			return default
		end
		return math.clamp(math.floor(v), lo, hi)
	end
	return {
		night = int(t.night, 1, maxNight, maxNight),
		guards = int(t.guards, 1, C.lift_capacity, 1),
		lives = int(t.lives, 1, #C.lives_reward, C.shift_lives),
	}
end

-- what the night pays, times this (rounded to 0.05)
function Difficulty.payMultiplier(setup: Setup, nights: { [number]: any }, C: any): number
	local night = nights[setup.night]
	local m = (if night then night.reward else 1)
		* C.lives_reward[setup.lives]
		* C.guards_reward[math.clamp(setup.guards, 1, #C.guards_reward)]
	return math.floor(m * 20 + 0.5) / 20
end

-- the difficulty's name and its step (1 to 5) for a pay multiplier
function Difficulty.label(multiplier: number, C: any): (string, number)
	local names = string.split(C.difficulty_names, ";")
	local step = 1
	for _, threshold in C.difficulty_steps do
		if multiplier >= threshold - 1e-9 then
			step += 1
		end
	end
	step = math.min(step, #names)
	return names[step], step
end

return Difficulty
