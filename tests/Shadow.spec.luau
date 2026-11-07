--!strict
-- The Unseen's paths through shadow and his director (plan section 4).
local Config = require("../src/shared/Config")
local Grid = require("../src/shared/Logic/Grid")
local Shadow = require("../src/shared/Logic/Shadow")
local Hunt = require("../src/shared/Logic/Hunt")

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

-- a 10 x 10 room, cells of 1 stud
local function room(): Grid.Grid
	return Grid.new(0, 0, 1, 10, 10, 0)
end

local function wall(g: Grid.Grid, x: number, z0: number, z1: number): { [number]: boolean }
	local s = {}
	for z = z0, z1 do
		s[Grid.index(g, x, z) :: number] = true
	end
	return s
end

local spec = {}

function spec.pathGoesAroundAField()
	local g = room()
	local filmed = wall(g, 5, 0, 8) -- a field across the room with a gap at the top
	local from, to = Grid.index(g, 1, 1) :: number, Grid.index(g, 8, 1) :: number
	local path = Shadow.path(g, filmed, from, to)
	ok(path, "a path through the gap")
	for _, i in path :: { number } do
		ok(not filmed[i], "the path crosses a field")
	end
	ok(#(path :: { number }) > 8, "the path detours")
end

function spec.anIslandCannotBeReached()
	local g = room()
	local filmed = wall(g, 5, 0, 9) -- a field all the way across: two islands
	eq(Shadow.path(g, filmed, Grid.index(g, 1, 1) :: number, Grid.index(g, 8, 1) :: number), nil, "path")
	local island = Shadow.island(g, filmed, Grid.index(g, 1, 1) :: number)
	eq(island[Grid.index(g, 8, 1) :: number], nil, "other side")
	ok(island[Grid.index(g, 4, 9) :: number] ~= nil, "own side")
end

function spec.noCornerCutting()
	local g = room()
	g.blocked[Grid.index(g, 1, 0) :: number] = true
	g.blocked[Grid.index(g, 0, 1) :: number] = true
	-- (0,0) is boxed in by two solids: the diagonal to (1,1) is not allowed
	eq(Shadow.path(g, {}, Grid.index(g, 0, 0) :: number, Grid.index(g, 1, 1) :: number), nil, "diagonal past corners")
end

function spec.nearestSkipsFields()
	local g = room()
	local filmed = wall(g, 0, 0, 9)
	local from = Grid.index(g, 0, 4) :: number
	local found = Shadow.nearest(g, from, function(i)
		return Shadow.free(g, filmed, i)
	end) :: number
	local x = Grid.coords(g, found)
	eq(x, 1, "the nearest free cell is next column")
end

function spec.toFilmedCountsSteps()
	local g = room()
	local filmed = { [Grid.index(g, 0, 0) :: number] = true }
	local d = Shadow.toFilmed(g, filmed)
	eq(d[Grid.index(g, 3, 0) :: number], 3, "three steps along x")
	eq(d[Grid.index(g, 3, 3) :: number], 3, "three diagonal steps")
end

function spec.modesFollowThePhase()
	eq(Hunt.mode("LIVE", 0), "prowl", "LIVE")
	eq(Hunt.mode("FLICKER", 0), "approach", "FLICKER")
	eq(Hunt.mode("BLACKOUT", 0), "hunt", "BLACKOUT")
	eq(Hunt.mode("BLACKOUT", 3), "retreat", "relief wins")
end

function spec.huntPicksTheMostExposed()
	local list = {
		{ id = 1, filmed = false, offTime = 5, fieldSteps = 1 },
		{ id = 2, filmed = false, offTime = 4, fieldSteps = 12 },
		{ id = 3, filmed = true, offTime = 0, fieldSteps = 0 },
	}
	eq(Hunt.target(list, "approach", C.hunt_distance_weight), 1, "approach: longest off camera")
	eq(Hunt.target(list, "hunt", C.hunt_distance_weight), 2, "hunt: far from any field")
	eq(Hunt.target(list, "prowl", C.hunt_distance_weight), nil, "prowl has no target")
	eq(Hunt.target({ list[3] }, "hunt", 1), nil, "filmed players are never targets")
end

function spec.signalDrainsAndMarks()
	local level, marked = 1, false
	-- off camera in LIVE for the whole drain time: empty and marked
	for _ = 1, math.ceil(C.exposure_drain_live * 10) + 1 do
		level, marked = Hunt.exposure(level, marked, false, "LIVE", 0.1, C)
	end
	eq(level, 0, "empty")
	ok(marked, "marked when empty")
	-- back on camera: marked until the bar passes exposure_safe
	level, marked = Hunt.exposure(level, marked, true, "LIVE", C.exposure_refill * (C.exposure_safe / 2), C)
	ok(marked, "still marked under the safe level")
	level, marked = Hunt.exposure(level, marked, true, "LIVE", C.exposure_refill, C)
	eq(level, 1, "full again")
	ok(not marked, "safe again")
	-- a blackout drains faster than LIVE
	local live = Hunt.exposure(1, false, false, "LIVE", 1, C)
	local dark = Hunt.exposure(1, false, false, "BLACKOUT", 1, C)
	ok(dark < live, "faster in a blackout")
end

function spec.aMarkedGuardIsHuntedFirst()
	eq(Hunt.mode("LIVE", 0, true), "hunt", "hunted in LIVE when marked")
	eq(Hunt.mode("LIVE", 0, false), "prowl", "prowl otherwise")
	local list = {
		{ id = 1, filmed = false, offTime = 30, fieldSteps = 20 },
		{ id = 2, filmed = false, offTime = 2, fieldSteps = 1, marked = true },
	}
	eq(Hunt.target(list, "hunt", C.hunt_distance_weight), 2, "the marked guard")
end

function spec.killOnlyInABlindSpot()
	ok(Hunt.canKill(1, false, 1, C), "off camera, close, past the grace")
	ok(not Hunt.canKill(1, true, 1, C), "filmed")
	ok(not Hunt.canKill(1, false, C.unwatched_grace / 2, C), "inside the grace")
	ok(not Hunt.canKill(C.unseen_contact + 0.1, false, 5, C), "out of reach")
end

function spec.hushComesBeforeReach()
	local speed = C.unseen_speed_hunt
	ok(Hunt.shouldHush(C.unseen_contact + speed * C.unseen_hush_lead - 0.01, speed, C), "just inside the lead")
	ok(not Hunt.shouldHush(C.unseen_contact + speed * C.unseen_hush_lead + 1, speed, C), "too far yet")
end

return spec
