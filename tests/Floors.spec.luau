--!strict
-- Chapter 1's floors (content/floors.csv): the stairwell joins them, the fire doors and the plaster change the map.
local Config = require("../src/shared/Config")
local Grid = require("../src/shared/Logic/Grid")
local Watch = require("../src/shared/Logic/Watch")
local Shadow = require("../src/shared/Logic/Shadow")

local C = Config.C

local function ok(v: any, what: string)
	if not v then
		error(what, 2)
	end
end

local function eq(a: any, b: any, what: string?)
	if a ~= b then
		error(`{what or "value"}: expected {tostring(b)}, got {tostring(a)}`, 2)
	end
end

local function blockById(id: string): any
	for _, b in Config.Map do
		if b.id == id then
			return b
		end
	end
	error("no block " .. id)
end

-- where a guard comes out of a stairwell door (StairsService.exitCFrame)
local function exitCell(level: Watch.Level, spotId: string): number
	local spot = Config.spotById[spotId]
	local yaw = math.rad(spot.yaw)
	local x, z = spot.x + math.sin(yaw) * C.stairs_out, spot.z + math.cos(yaw) * C.stairs_out
	return Grid.at(level.grid, x, z) :: number
end

local spec = {}

function spec.theStairsJoinTheFloorsInOrder()
	local order = {}
	for k, f in Config.Floors do
		order[f.id] = k
	end
	local level = Watch.level(Config.Map, C)
	for _, row in Config.Stairs do
		local spot = Config.spotById[row.spot]
		ok(spot and spot.kind == "stairs", row.spot .. " is a stairwell door")
		eq(spot.floor, row.floor, row.spot .. " floor")
		eq((Config.floorAt(spot.x)), row.floor, row.spot .. " lies on its floor")
		local i = exitCell(level, row.spot)
		ok(not level.grid.blocked[i], row.spot .. ": a guard comes out on an open cell")
		for _, other in { row.up, row.down } do
			if other ~= "" then
				local back = Config.stairsBySpot[other]
				ok(back, other .. " has a stairwell row")
				eq(
					math.abs(order[back.floor] - order[row.floor]),
					1,
					row.spot .. " -> " .. other .. " is the next floor"
				)
				ok(back.up == row.spot or back.down == row.spot, other .. " leads back to " .. row.spot)
			end
		end
	end
end

function spec.theFloorsAreIslands()
	-- he can never walk from one floor to another: he takes the stairs out of sight (UnseenService)
	local level = Watch.level(Config.Map, C)
	local p2 = exitCell(level, "P2_Stairs")
	local p3 = exitCell(level, "Stairs")
	local p4 = exitCell(level, "P4_Stairs")
	eq(Shadow.path(level.grid, {}, p3, p2), nil, "P3 to P2 on foot")
	eq(Shadow.path(level.grid, {}, p3, p4), nil, "P3 to P4 on foot")
end

function spec.aClosedFireDoorBlocksAndHides()
	local door = blockById("DoorW")
	local open = Watch.level(Config.Map, C)
	local i = Grid.at(open.grid, door.x, door.z) :: number
	ok(not open.grid.blocked[i], "an open fire door lets him through")
	local closed = Watch.level(Config.Map, C, { DoorW = true })
	ok(closed.grid.blocked[i], "a closed fire door blocks his way")
	-- and back: relevel in place
	Watch.relevel(closed, Config.Map, C, { DoorW = false })
	ok(not closed.grid.blocked[i], "opened again")
end

function spec.theSealedRoomOpensWithThePlaster()
	local room = Config.spotById.SealedRoom
	local whole = Watch.level(Config.Map, C)
	local inside = Grid.at(whole.grid, room.x, room.z) :: number
	local stairs = exitCell(whole, "P4_Stairs")
	ok(not whole.grid.blocked[inside], "the room's centre is open")
	eq(Shadow.path(whole.grid, {}, stairs, inside), nil, "no way in while the plaster stands")
	local broken = Watch.level(Config.Map, C, { P4_Plaster = false })
	ok(Shadow.path(broken.grid, {}, stairs, inside), "a way in once it is broken")
	-- the room is out of every camera, even with all of them on and the wall down
	for _, cam in Config.Cameras do
		local field = Watch.coverage(broken, Watch.cameraView(cam), C.sample_heights, C.sample_inset)
		ok(not field[inside], cam.id .. " can't see into the sealed room")
	end
end

function spec.theFilmTaskBoxIsTheRoom()
	-- TaskService: film_half_x by film_half_z around the target spot, inside the room's walls
	local room = Config.spotById.SealedRoom
	local west, east, north = blockById("P4_RoomW"), blockById("P4_RoomE"), blockById("P4_RoomN")
	local plaster = blockById("P4_Plaster")
	ok(room.x - C.film_half_x >= west.x + west.sx / 2 - 1, "west edge inside")
	ok(room.x + C.film_half_x <= east.x - east.sx / 2 + 1, "east edge inside")
	ok(room.z + C.film_half_z <= north.z - north.sz / 2 + 1, "north edge inside")
	ok(room.z - C.film_half_z >= plaster.z + plaster.sz / 2 - 0.5, "south edge behind the plaster")
end

function spec.theFirstFloorIsAlwaysFilmed()
	-- P1, the post and the lift hall: the safe floor, filmed by its always-on cameras
	local level = Watch.level(Config.Map, C)
	local sets = {}
	for _, cam in Config.Cameras do
		if cam.always and Config.floorAt(cam.x) == "P1" then
			table.insert(sets, Watch.coverage(level, Watch.cameraView(cam), C.sample_heights, C.sample_inset))
		end
	end
	local filmed = Watch.union(sets)
	local spawn = blockById(C.spawn_marker)
	local i = Grid.at(level.grid, spawn.x, spawn.z) :: number
	ok(filmed[i], "the spawn is filmed")
	local open, dark = 0, 0
	local offset = Config.floorById.P1.offsetX
	for k = 1, Grid.count(level.grid) do
		local x = Grid.center(level.grid, k)
		if not level.grid.blocked[k] and math.abs(x - offset) < 45 then
			open += 1
			if not filmed[k] then
				dark += 1
			end
		end
	end
	ok(open > 0, "P1 has open cells")
	ok(dark / open < 0.05, `P1 blind cells: {dark} of {open}`)
end

return spec
