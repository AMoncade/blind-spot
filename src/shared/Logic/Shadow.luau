--!strict
-- How the Unseen travels (plan section 4, rule 4: "il voyage par l'ombre"). He only walks through cells that are
-- neither solid nor filmed; a blind spot ringed by fields is an island he can't reach. Breadth-first searches over the
-- grid, 8 neighbours without cutting corners. Pure functions for the specs.
local Grid = require(if script then script.Parent:WaitForChild("Grid") else "./Grid")

local Shadow = {}

export type Set = { [number]: boolean }

-- a cell the Unseen may stand in
function Shadow.free(g: Grid.Grid, filmed: Set, i: number): boolean
	return not g.blocked[i] and not filmed[i]
end

-- Steps from the sources to every cell reachable through open cells (sources included at 0). maxSteps stops early.
function Shadow.flood(
	g: Grid.Grid,
	open: (number) -> boolean,
	sources: { number },
	maxSteps: number?
): { [number]: number }
	local dist: { [number]: number } = {}
	local queue = {}
	for _, s in sources do
		if dist[s] == nil then
			dist[s] = 0
			table.insert(queue, s)
		end
	end
	local head = 1
	while head <= #queue do
		local i = queue[head]
		head += 1
		local d = dist[i] + 1
		if maxSteps and d > maxSteps then
			continue
		end
		for _, n in Grid.neighbors(g, i, open) do
			if dist[n] == nil then
				dist[n] = d
				table.insert(queue, n)
			end
		end
	end
	return dist
end

-- The cells from `from` to `to` through shadow (both ends included), or nil when `to` is on another island.
function Shadow.path(g: Grid.Grid, filmed: Set, from: number, to: number): { number }?
	local function open(i: number): boolean
		return Shadow.free(g, filmed, i)
	end
	if not open(from) or not open(to) then
		return nil
	end
	local parent: { [number]: number } = { [from] = from }
	local queue = { from }
	local head = 1
	while head <= #queue do
		local i = queue[head]
		head += 1
		if i == to then
			local out = { to }
			local c = to
			while c ~= from do
				c = parent[c]
				table.insert(out, 1, c)
			end
			return out
		end
		for _, n in Grid.neighbors(g, i, open) do
			if parent[n] == nil then
				parent[n] = i
				table.insert(queue, n)
			end
		end
	end
	return nil
end

-- the length in studs of a path through cell centres
function Shadow.length(g: Grid.Grid, path: { number }): number
	local total = 0
	for k = 2, #path do
		local ax, az = Grid.center(g, path[k - 1])
		local bx, bz = Grid.center(g, path[k])
		total += math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
	end
	return total
end

-- The nearest cell to `from` (walking around solids, through fields too) that `accept` takes; nil if none.
function Shadow.nearest(g: Grid.Grid, from: number, accept: (number) -> boolean): number?
	local function open(i: number): boolean
		return not g.blocked[i]
	end
	local seen: { [number]: boolean } = { [from] = true }
	local queue = { from }
	local head = 1
	while head <= #queue do
		local i = queue[head]
		head += 1
		if accept(i) then
			return i
		end
		for _, n in Grid.neighbors(g, i, open) do
			if not seen[n] then
				seen[n] = true
				table.insert(queue, n)
			end
		end
	end
	return nil
end

-- Steps from every open cell to the nearest filmed one (filmed cells are 0). Used to rank who is farthest from a
-- camera (plan section 4, BLACKOUT).
function Shadow.toFilmed(g: Grid.Grid, filmed: Set): { [number]: number }
	local sources = {}
	for i in filmed do
		table.insert(sources, i)
	end
	table.sort(sources)
	return Shadow.flood(g, function(i)
		return not g.blocked[i]
	end, sources)
end

-- the island of shadow around `from` (every free cell he can walk to)
function Shadow.island(g: Grid.Grid, filmed: Set, from: number): { [number]: number }
	if not Shadow.free(g, filmed, from) then
		return {}
	end
	return Shadow.flood(g, function(i)
		return Shadow.free(g, filmed, i)
	end, { from })
end

return Shadow
