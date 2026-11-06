--!strict
-- The grid, the camera fields of the real P3 config, and the rules that depend on them (plan sections 4 and 11).
local Config = require("../src/shared/Config")
local Grid = require("../src/shared/Logic/Grid")
local Look = require("../src/shared/Logic/Look")
local Watch = require("../src/shared/Logic/Watch")
local Shadow = require("../src/shared/Logic/Shadow")

local C = Config.C

local function eq(a: any, b: any, what: string?)
	if a ~= b then
		error(`{what or "value"}: expected {tostring(b)}, got {tostring(a)}`, 2)
	end
end

local function ok(v: any, what: string)
	if not v then
		error(what, 2)
	end
end

local level = Watch.level(Config.Map, C)
local g = level.grid
local fields: { [string]: Watch.Set } = {}
for _, cam in Config.Cameras do
	fields[cam.id] = Watch.coverage(level, Watch.cameraView(cam), C.sample_heights, C.sample_inset)
end

local function filmedBy(ids: { string }): Watch.Set
	local sets = {}
	for _, id in ids do
		table.insert(sets, fields[id])
	end
	return Watch.union(sets)
end

local allIds = {}
local alwaysIds = {}
for _, cam in Config.Cameras do
	table.insert(allIds, cam.id)
	if cam.always then
		table.insert(alwaysIds, cam.id)
	end
end

local spec = {}

function spec.gridIndexRoundTrips()
	for _, i in { 1, 2, g.w, g.w + 1, Grid.count(g) } do
		local ix, iz = Grid.coords(g, i)
		eq(Grid.index(g, ix, iz), i, "index")
		local x, z = Grid.center(g, i)
		eq(Grid.at(g, x, z), i, "at(center)")
	end
	eq(Grid.at(g, g.ox - 0.1, g.oz + 1), nil, "west of the grid")
end

function spec.gridCoversTheMap()
	-- every solid box of the map sits inside the grid
	for _, b in Config.Map do
		if b.blocks then
			ok(
				b.x - b.sx / 2 >= g.ox - 1 and b.x + b.sx / 2 <= g.ox + g.w * g.cell + 1,
				b.id .. " outside the grid (x)"
			)
			ok(
				b.z - b.sz / 2 >= g.oz - 1 and b.z + b.sz / 2 <= g.oz + g.d * g.cell + 1,
				b.id .. " outside the grid (z)"
			)
		end
	end
end

function spec.pillarsAndCarsAreBlocked()
	for _, b in Config.Map do
		if b.kind == "pillar" or b.kind == "car" then
			eq(g.blocked[Grid.at(g, b.x, b.z) :: number], true, b.id .. " centre blocked")
		end
	end
	eq(g.blocked[Grid.at(g, 0, 0) :: number], nil, "aisle centre open")
end

function spec.lookTowardAndContains()
	local yaw, pitch = Look.toward(0, 0, 0, 0, 0, -10)
	ok(math.abs(yaw) < 1e-9 and math.abs(pitch) < 1e-9, "looking at -Z is yaw 0")
	local lx, _, lz = Look.dir(Look.toward(0, 0, 0, 10, 0, 0))
	ok(math.abs(lx - 1) < 1e-9 and math.abs(lz) < 1e-9, "looking at +X")
	local v = Look.view(0, 5, 0, 0, 0, 60, 40, 20)
	ok(Look.contains(v, 0, 5, -10), "straight ahead")
	ok(not Look.contains(v, 0, 5, 10), "behind")
	ok(not Look.contains(v, 0, 5, -25), "out of range")
	ok(not Look.contains(v, 10, 5, -10), "45 degrees right is outside a 60 degree cone")
	ok(Look.contains(v, 5, 5, -10), "27 degrees right is inside")
end

function spec.segmentHitsBox()
	local boxes = { Grid.box(0, 5, 0, 2, 10, 2) }
	ok(Grid.segmentHits(boxes, -5, 5, 0, 5, 5, 0), "through the pillar")
	ok(not Grid.segmentHits(boxes, -5, 5, 3, 5, 5, 3), "beside the pillar")
	ok(not Grid.segmentHits(boxes, -5, 12, 0, 5, 12, 0), "over the pillar")
	ok(not Grid.segmentHits(boxes, 1, 5, 0, 5, 5, 0), "starting on its face")
end

function spec.everyCameraFilmsSomething()
	for _, cam in Config.Cameras do
		ok(Watch.size(fields[cam.id]) >= 20, cam.id .. " films fewer than 20 cells")
		-- its target (or the nearest open cell to it) is in its field
		local t = Grid.at(g, cam.tx, cam.tz) :: number
		local near = Shadow.nearest(g, t, function(_)
			return true
		end) :: number
		ok(fields[cam.id][near] or fields[cam.id][t], cam.id .. " doesn't film its own target")
	end
end

function spec.wallsHideTheCorridor()
	-- the aisle cameras don't see through the south wall into the service corridor
	local corridor = Grid.at(g, 0, -37.5) :: number
	for _, id in { "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C12" } do
		eq(fields[id][corridor], nil, id .. " sees through the wall")
	end
	ok(fields.C10[corridor] or fields.C11[corridor], "the corridor cameras film the corridor")
end

function spec.theBoothIsAlwaysFilmed()
	-- spawn and every open booth cell are filmed by the always-on cameras (plan section 3: the one place always filmed)
	local always = filmedBy(alwaysIds)
	for x = -59, -49, 2 do
		for z = 17, 31, 2 do
			local i = Grid.at(g, x, z) :: number
			if not g.blocked[i] then
				eq(always[i], true, `booth cell ({x}, {z})`)
			end
		end
	end
end

function spec.liveLeavesSomeBlindSpots()
	-- LIVE: almost everything is filmed, but the Unseen has rare blind spots to roam (plan section 3)
	local filmed = filmedBy(allIds)
	local open, dark = 0, 0
	for i = 1, Grid.count(g) do
		if not g.blocked[i] then
			open += 1
			if not filmed[i] then
				dark += 1
			end
		end
	end
	local share = dark / open
	print(`  LIVE: {dark} of {open} open cells in blind spots ({math.floor(share * 100)}%)`)
	ok(share > 0.03, "LIVE has almost no blind spot")
	ok(share < 0.45, "LIVE is mostly dark")
end

function spec.blackoutWithOneCameraPerZoneIsMostlyDark()
	local filmed = filmedBy({ "C01", "C02", "C03", "C10" })
	local open, dark = 0, 0
	for i = 1, Grid.count(g) do
		if not g.blocked[i] then
			open += 1
			if not filmed[i] then
				dark += 1
			end
		end
	end
	print(`  BLACKOUT (C03, C10): {math.floor(dark / open * 100)}% dark`)
	ok(dark / open > 0.4, "a blackout should leave most of the level dark")
end

function spec.playerAtTheEdgeCountsAsFilmed()
	local filmed = fields.C03
	-- find an open cell just outside C03's field next to a filmed one
	for i = 1, Grid.count(g) do
		if not g.blocked[i] and not filmed[i] then
			local x, z = Grid.center(g, i)
			for _, n in Grid.near(g, x, z, g.cell) do
				if filmed[n] then
					ok(
						Watch.circleFilmed(g, filmed, x, z, C.player_radius + C.edge_margin),
						"a player one cell from a field must count as filmed"
					)
					return
				end
			end
		end
	end
	error("no field edge found")
end

function spec.seenByListsTheCameras()
	local x, z = Grid.center(g, next(fields.C04) :: number)
	local ids = Watch.seenBy(g, fields, allIds, x, z, C.player_radius)
	ok(table.find(ids, "C04") ~= nil, "C04 films its own cell")
end

return spec
