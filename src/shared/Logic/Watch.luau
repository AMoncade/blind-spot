--!strict
-- What is filmed (plan section 11, WatchService). A camera's field is the set of grid cells it sees: a cell counts as
-- filmed when any of its sample points (centre and inset corners, at a few heights) is inside the camera's frustum
-- with no solid box in between. The doubt goes to the player (CLAUDE.md): one visible sample is enough.
-- The fixed cameras' fields are computed once; the filmed set is the union of the active ones plus the camcorders.
local Grid = require(if script then script.Parent:WaitForChild("Grid") else "./Grid")
local Look = require(if script then script.Parent:WaitForChild("Look") else "./Look")

local Watch = {}

export type Set = { [number]: boolean }

export type Level = {
	grid: Grid.Grid,
	occluders: { Grid.Box }, -- what stops a camera ray
}

export type MapBlock = {
	id: string,
	kind: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	occludes: boolean,
	blocks: boolean,
}

export type CameraDef = {
	id: string,
	x: number,
	y: number,
	z: number,
	tx: number,
	ty: number,
	tz: number,
	hfov: number,
	vfov: number,
	range: number,
}

-- The level's grid and occluders from the map config (Config.Map) and the constants (Config.C).
-- The blocks that change during a night (DYNAMIC kinds): a fire door that opens and closes, the plaster wall that
-- is broken on night 5. Their state is solid (true) or not; by default a fire door stands open and the plaster holds.
Watch.DYNAMIC = { firedoor = false, plaster = true }

local function isSolid(b: MapBlock, states: { [string]: boolean }?): (boolean, boolean)
	local default = Watch.DYNAMIC[b.kind]
	if default == nil then
		return b.occludes, b.blocks
	end
	local solid = default
	if states and states[b.id] ~= nil then
		solid = states[b.id]
	end
	return solid, solid
end

-- Fills a level's grid and occluders from the map (and the dynamic blocks' states), in place.
function Watch.relevel(level: Level, map: { MapBlock }, C: any, states: { [string]: boolean }?)
	local grid = level.grid
	table.clear(grid.blocked)
	table.clear(level.occluders)
	local solids = {}
	for _, b in map do
		local box = Grid.box(b.x, b.y, b.z, b.sx, b.sy, b.sz)
		local occludes, blocks = isSolid(b, states)
		if occludes then
			table.insert(level.occluders, box)
		end
		if blocks then
			table.insert(solids, box)
		end
	end
	Grid.block(grid, solids, C.block_pad)
	-- the cells between the floors (laid side by side, content/floors.csv) are nowhere: solid
	local slabs = {}
	for _, b in map do
		if b.kind == "floor" then
			table.insert(slabs, Grid.box(b.x, b.y, b.z, b.sx, b.sy, b.sz))
		end
	end
	if #slabs > 0 then
		for i = 1, Grid.count(grid) do
			local cx, cz = Grid.center(grid, i)
			local inside = false
			for _, s in slabs do
				if cx > s.minX and cx < s.maxX and cz > s.minZ and cz < s.maxZ then
					inside = true
					break
				end
			end
			if not inside then
				grid.blocked[i] = true
			end
		end
	end
end

-- The level's grid and occluders from the map config (Config.Map) and the constants (Config.C).
function Watch.level(map: { MapBlock }, C: any, states: { [string]: boolean }?): Level
	local level: Level = {
		grid = Grid.new(C.grid_origin_x, C.grid_origin_z, C.grid_cell, C.grid_width, C.grid_depth, C.floor_y),
		occluders = {},
	}
	Watch.relevel(level, map, C, states)
	return level
end

-- a fixed camera's view from its config row (it aims at its target), turned by yawOffset radians when a watcher
-- turns it (plan section 3, the dead guard at the security booth)
-- rangeScale: the shift's mode shortens every field (content/modes.csv)
function Watch.cameraView(cam: CameraDef, yawOffset: number?, rangeScale: number?): Look.View
	local yaw, pitch = Look.toward(cam.x, cam.y, cam.z, cam.tx, cam.ty, cam.tz)
	return Look.view(
		cam.x,
		cam.y,
		cam.z,
		yaw + (yawOffset or 0),
		pitch,
		cam.hfov,
		cam.vfov,
		cam.range * (rangeScale or 1)
	)
end

local function sees(level: Level, view: Look.View, px: number, py: number, pz: number): boolean
	return Look.contains(view, px, py, pz) and not Grid.segmentHits(level.occluders, view.x, view.y, view.z, px, py, pz)
end

-- The cells a view films. heights: above the floor; inset: how far inside the corners the corner samples sit (0 or
-- nil = the centre only). pause, when given, is called every few hundred cells (task.wait on the server).
function Watch.coverage(level: Level, view: Look.View, heights: { number }, inset: number?, pause: (() -> ())?): Set
	local g = level.grid
	local out: Set = {}
	local reach = view.range + g.cell
	local ix0 = math.floor((view.x - reach - g.ox) / g.cell)
	local ix1 = math.floor((view.x + reach - g.ox) / g.cell)
	local iz0 = math.floor((view.z - reach - g.oz) / g.cell)
	local iz1 = math.floor((view.z + reach - g.oz) / g.cell)
	local half = g.cell / 2 - (inset or 0)
	local offsets = { { 0, 0 } }
	if inset and inset > 0 then
		table.insert(offsets, { -half, -half })
		table.insert(offsets, { half, -half })
		table.insert(offsets, { -half, half })
		table.insert(offsets, { half, half })
	end
	local done = 0
	for iz = iz0, iz1 do
		for ix = ix0, ix1 do
			local i = Grid.index(g, ix, iz)
			if i and not g.blocked[i] then
				local cx, cz = Grid.center(g, i)
				local seen = false
				for _, h in heights do
					for _, o in offsets do
						if sees(level, view, cx + o[1], g.floorY + h, cz + o[2]) then
							seen = true
							break
						end
					end
					if seen then
						break
					end
				end
				if seen then
					out[i] = true
				end
				done += 1
				if pause and done % 1500 == 0 then
					pause()
				end
			end
		end
	end
	return out
end

function Watch.union(sets: { Set }): Set
	local out: Set = {}
	for _, s in sets do
		for i in s do
			out[i] = true
		end
	end
	return out
end

function Watch.size(s: Set): number
	local n = 0
	for _ in s do
		n += 1
	end
	return n
end

-- Is anyone standing at (x, z) with radius r filmed? Any filmed cell under them is enough (the doubt goes to the
-- player); r should include the lag margin.
function Watch.circleFilmed(g: Grid.Grid, filmed: Set, x: number, z: number, r: number): boolean
	for _, i in Grid.near(g, x, z, r) do
		if filmed[i] then
			return true
		end
	end
	return false
end

-- The fixed cameras (among ids) whose field covers the circle: they turn toward the player (plan section 3).
function Watch.seenBy(
	g: Grid.Grid,
	fields: { [string]: Set },
	ids: { string },
	x: number,
	z: number,
	r: number
): { string }
	local out = {}
	local cells = Grid.near(g, x, z, r)
	for _, id in ids do
		local field = fields[id]
		if field then
			for _, i in cells do
				if field[i] then
					table.insert(out, id)
					break
				end
			end
		end
	end
	return out
end

return Watch
