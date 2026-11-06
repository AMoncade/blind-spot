--!strict
-- A small seeded generator (Park-Miller, 48271), the same in Studio and in the Lune specs, so a night built from a
-- seed is the same night everywhere (the timeline, the simulator, a replay).
local Rng = {}

export type Rng = {
	next: () -> number, -- [0, 1)
	int: (a: number, b: number) -> number, -- a..b inclusive
	pick: <T>(list: { T }) -> T,
	shuffle: <T>(list: { T }) -> { T }, -- a shuffled copy
}

local M = 2147483647

function Rng.new(seed: number): Rng
	local state = math.floor(math.abs(seed)) % (M - 1) + 1
	local self = {} :: Rng
	function self.next(): number
		state = (state * 48271) % M
		return (state - 1) / (M - 1)
	end
	function self.int(a: number, b: number): number
		return math.min(b, a + math.floor(self.next() * (b - a + 1)))
	end
	function self.pick<T>(list: { T }): T
		return list[self.int(1, #list)]
	end
	function self.shuffle<T>(list: { T }): { T }
		local out = table.clone(list)
		for i = #out, 2, -1 do
			local j = self.int(1, i)
			out[i], out[j] = out[j], out[i]
		end
		return out
	end
	return self
end

return Rng
