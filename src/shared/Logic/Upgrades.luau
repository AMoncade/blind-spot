--!strict
-- The guard's upgrades (Adrien, 8 Nov: the K&V SUPPLY shop in the lobby; content/upgrades.csv): each has levels from 1
-- (what every new guard starts with: hard on purpose) to its max, a value per level (and a second one for some), and a
-- price to reach the next level that grows each time. Pure: the shop screen, the server and the specs read the same.
local Upgrades = {}

export type Def = {
	id: string,
	name: string,
	max: number,
	costBase: number,
	costGrowth: number,
	values: { number },
	values2: { number },
	unit: string,
	unit2: string,
	art: string,
	blurb: string,
}

-- a guard's level in an upgrade (1 when they never bought it)
function Upgrades.level(profile: any, id: string): number
	local levels = profile and profile.upgrades
	local level = levels and levels[id]
	return if type(level) == "number" then level else 1
end

-- the upgrade's value at a level, and its second value (nil when it has none)
function Upgrades.value(def: Def, level: number): (number, number?)
	local k = math.clamp(level, 1, #def.values)
	local second = if #def.values2 > 0 then def.values2[math.clamp(level, 1, #def.values2)] else nil
	return def.values[k], second
end

-- the price to go from `level` to the next one (nil at the max), rounded to 10
function Upgrades.cost(def: Def, level: number): number?
	if level >= def.max then
		return nil
	end
	return math.floor(def.costBase * def.costGrowth ^ (level - 1) / 10 + 0.5) * 10
end

return Upgrades
