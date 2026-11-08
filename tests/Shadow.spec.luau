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

function spec.heIsAfterTheLowestBar()
	local list = {
		{ id = 1, filmed = false, exposure = 0.6 },
		{ id = 2, filmed = false, exposure = 0.3 },
		{ id = 3, filmed = true, exposure = 0.1 },
	}
	eq(Hunt.target(list), 2, "the lowest bar off camera")
	eq(Hunt.target({ list[3] }), 3, "a filmed guard when nobody else is out")
	eq(Hunt.target({}), nil, "nobody")
	eq(
		Hunt.target({ { id = 9, filmed = false, exposure = 0.5 }, { id = 4, filmed = false, exposure = 0.5 } }),
		4,
		"ties: lower id"
	)
end

function spec.signalDrainsAndEmpties()
	local level, empty = 1, false
	-- off camera in LIVE for the whole drain time: empty
	for _ = 1, math.ceil(C.exposure_drain_live * 10) + 1 do
		level, empty = Hunt.exposure(level, empty, false, "LIVE", 0.1, C)
	end
	eq(level, 0, "empty")
	ok(empty, "empty is reported")
	level, empty = Hunt.exposure(level, empty, true, "LIVE", C.exposure_refill, C)
	eq(level, 1, "full again under a camera")
	ok(not empty, "not empty")
	-- a blackout drains faster than LIVE, and a harder night too
	local live = Hunt.exposure(1, false, false, "LIVE", 1, C)
	local dark = Hunt.exposure(1, false, false, "BLACKOUT", 1, C)
	ok(dark < live, "faster in a blackout")
	local hard = Hunt.exposure(1, false, false, "LIVE", 1, C, 1.3)
	ok(hard < live, "faster on a harder night")
end

function spec.heComesCloserAsTheBarDrops()
	eq(Hunt.stalkDistance(1, C), C.stalk_far, "full: far")
	eq(Hunt.stalkDistance(0, C), C.stalk_near, "empty: on you")
	local last = math.huge
	for k = 10, 0, -1 do
		local d = Hunt.stalkDistance(k / 10, C)
		ok(d <= last, "never farther as the bar drops")
		last = d
	end
	-- and he jumps more often when the power fails and when the bar is low
	ok(Hunt.jumpDelay("BLACKOUT", 1, 1, 0.5, C) < Hunt.jumpDelay("LIVE", 1, 1, 0.5, C), "blackout: sooner")
	ok(Hunt.jumpDelay("LIVE", 0.1, 1, 0.5, C) < Hunt.jumpDelay("LIVE", 1, 1, 0.5, C), "low bar: sooner")
	ok(Hunt.jumpDelay("LIVE", 1, 1.3, 0.5, C) < Hunt.jumpDelay("LIVE", 1, 1, 0.5, C), "harder night: sooner")
end

function spec.youCantWalkUpToHim()
	-- full bar: he stands far away; walk halfway to him and he is gone, further away
	local far = Hunt.stalkDistance(1, C)
	ok(not Hunt.flees(far, 1, C), "where he stands: he stays")
	ok(Hunt.flees(far * 0.4, 1, C), "much nearer: he jumps away")
	-- reaching him is a catch, whatever the bar
	ok(Hunt.touches(C.unseen_touch_distance * 0.9, C), "reached: caught")
	ok(not Hunt.touches(C.unseen_touch_distance * 2, C), "not reached")
	-- a nearly empty bar puts him so close that walking at him reaches him before he flees
	ok(Hunt.stalkDistance(0, C) * C.unseen_flee_share < C.unseen_touch_distance, "empty bar: walking at him is a catch")
end

function spec.theCatchNeedsAnEmptyBarInTheDark()
	ok(Hunt.catches(0, false, 1, C), "empty, off camera, past the grace")
	ok(not Hunt.catches(0.05, false, 5, C), "not empty yet")
	ok(not Hunt.catches(0, true, 5, C), "filmed")
	ok(not Hunt.catches(0, false, C.unwatched_grace / 2, C), "inside the grace")
end

function spec.theHushComesBeforeHim()
	ok(Hunt.shouldHush(C.hush_exposure - 0.01, false, C), "low bar: the sound dies")
	ok(not Hunt.shouldHush(C.hush_exposure + 0.1, false, C), "not yet")
	ok(not Hunt.shouldHush(0.05, true, C), "never under a camera")
end

return spec
