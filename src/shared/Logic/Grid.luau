--!strict
-- The floor of a level cut into square cells (plan section 11, WatchService: 2 x 2 studs). A cell is an index
-- 1..w*d; ix runs along x, iz along z. Solid boxes (walls, pillars, cars) mark cells as blocked, the Unseen's walls,
-- and stop camera rays. Plain numbers only, for the Lune specs.
local Grid = {}

export type Box = {
	minX: number,
	minY: number,
	minZ: number,
	maxX: number,
	maxY: number,
	maxZ: number,
}

export type Grid = {
	ox: number, -- west edge (x)
	oz: number, -- south edge (z)
	cell: number,
	w: number,
	d: number,
	floorY: number,
	blocked: { [number]: boolean },
}

function Grid.new(ox: number, oz: number, cell: number, w: number, d: number, floorY: number): Grid
	return { ox = ox, oz = oz, cell = cell, w = w, d = d, floorY = floorY, blocked = {} }
end

function Grid.count(g: Grid): number
	return g.w * g.d
end

function Grid.index(g: Grid, ix: number, iz: number): number?
	if ix < 0 or iz < 0 or ix >= g.w or iz >= g.d then
		return nil
	end
	return iz * g.w + ix + 1
end

function Grid.coords(g: Grid, i: number): (number, number)
	local k = i - 1
	return k % g.w, k // g.w
end

-- the cell under a world position, nil outside the grid
function Grid.at(g: Grid, x: number, z: number): number?
	return Grid.index(g, math.floor((x - g.ox) / g.cell), math.floor((z - g.oz) / g.cell))
end

function Grid.center(g: Grid, i: number): (number, number)
	local ix, iz = Grid.coords(g, i)
	return g.ox + (ix + 0.5) * g.cell, g.oz + (iz + 0.5) * g.cell
end

-- every cell whose square touches the circle (x, z, r)
function Grid.near(g: Grid, x: number, z: number, r: number): { number }
	local out = {}
	local half = g.cell / 2
	local ix0 = math.floor((x - r - g.ox) / g.cell)
	local ix1 = math.floor((x + r - g.ox) / g.cell)
	local iz0 = math.floor((z - r - g.oz) / g.cell)
	local iz1 = math.floor((z + r - g.oz) / g.cell)
	for iz = iz0, iz1 do
		for ix = ix0, ix1 do
			local i = Grid.index(g, ix, iz)
			if i then
				local cx, cz = Grid.center(g, i)
				local qx = math.max(math.abs(x - cx) - half, 0)
				local qz = math.max(math.abs(z - cz) - half, 0)
				if qx * qx + qz * qz <= r * r then
					table.insert(out, i)
				end
			end
		end
	end
	return out
end

-- the 8 neighbours a walker can step to: diagonals only when both sides are open (no cutting a pillar's corner)
function Grid.neighbors(g: Grid, i: number, open: (number) -> boolean): { number }
	local ix, iz = Grid.coords(g, i)
	local out = {}
	local function at(dx: number, dz: number): number?
		local n = Grid.index(g, ix + dx, iz + dz)
		if n and open(n) then
			return n
		end
		return nil
	end
	local e, w, n, s = at(1, 0), at(-1, 0), at(0, 1), at(0, -1)
	for _, c in { e or 0, w or 0, n or 0, s or 0 } do
		if c ~= 0 then
			table.insert(out, c)
		end
	end
	if e and n then
		local c = at(1, 1)
		if c then
			table.insert(out, c)
		end
	end
	if e and s then
		local c = at(1, -1)
		if c then
			table.insert(out, c)
		end
	end
	if w and n then
		local c = at(-1, 1)
		if c then
			table.insert(out, c)
		end
	end
	if w and s then
		local c = at(-1, -1)
		if c then
			table.insert(out, c)
		end
	end
	return out
end

function Grid.box(x: number, y: number, z: number, sx: number, sy: number, sz: number): Box
	return {
		minX = x - sx / 2,
		minY = y - sy / 2,
		minZ = z - sz / 2,
		maxX = x + sx / 2,
		maxY = y + sy / 2,
		maxZ = z + sz / 2,
	}
end

-- marks every cell whose centre is inside a box grown by pad (the box's footprint, any height)
function Grid.block(g: Grid, boxes: { Box }, pad: number)
	for _, b in boxes do
		local ix0 = math.floor((b.minX - pad - g.ox) / g.cell)
		local ix1 = math.floor((b.maxX + pad - g.ox) / g.cell)
		local iz0 = math.floor((b.minZ - pad - g.oz) / g.cell)
		local iz1 = math.floor((b.maxZ + pad - g.oz) / g.cell)
		for iz = iz0, iz1 do
			for ix = ix0, ix1 do
				local i = Grid.index(g, ix, iz)
				if i then
					local cx, cz = Grid.center(g, i)
					if cx >= b.minX - pad and cx <= b.maxX + pad and cz >= b.minZ - pad and cz <= b.maxZ + pad then
						g.blocked[i] = true
					end
				end
			end
		end
	end
end

-- Does the segment from a to b pass through a box? Slab test; touching the ends doesn't count, so a camera on a
-- wall's face still sees.
function Grid.segmentHits(
	boxes: { Box },
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number
): boolean
	local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
	for _, b in boxes do
		local t0, t1 = 1e-4, 1 - 1e-4
		local hit = true
		for axis = 1, 3 do
			local o, d, lo, hi
			if axis == 1 then
				o, d, lo, hi = x1, dx, b.minX, b.maxX
			elseif axis == 2 then
				o, d, lo, hi = y1, dy, b.minY, b.maxY
			else
				o, d, lo, hi = z1, dz, b.minZ, b.maxZ
			end
			if math.abs(d) < 1e-9 then
				if o <= lo or o >= hi then
					hit = false
					break
				end
			else
				local ta, tb = (lo - o) / d, (hi - o) / d
				if ta > tb then
					ta, tb = tb, ta
				end
				t0 = math.max(t0, ta)
				t1 = math.min(t1, tb)
				if t0 >= t1 then
					hit = false
					break
				end
			end
		end
		if hit then
			return true
		end
	end
	return false
end

return Grid
