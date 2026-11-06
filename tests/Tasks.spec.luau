--!strict
-- The night's task list (plan section 3).
local Config = require("../src/shared/Config")
local Tasks = require("../src/shared/Logic/Tasks")
local Grid = require("../src/shared/Logic/Grid")
local Watch = require("../src/shared/Logic/Watch")

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

local function label(id: string): string
	return Config.spotById[id].label
end

local spec = {}

function spec.everyNightHasTheSameShape()
	for seed = 1, 50 do
		local list = Tasks.build(Config.Tasks, label, C.scan_count, seed)
		local scans, fetches = 0, 0
		for _, t in list do
			if t.kind == "scan" then
				scans += 1
			else
				fetches += 1
				ok(t.item and t.pickup, t.id .. " has an item and a pickup")
			end
			ok(Config.spotById[t.target], t.id .. " target exists")
		end
		eq(scans, C.scan_count, "scans")
		eq(fetches, 3, "fetch tasks")
	end
end

function spec.labelsAreFilled()
	local list = Tasks.build(Config.Tasks, label, C.scan_count, 3)
	for _, t in list do
		ok(not string.find(t.label, "{", 1, true), "label filled: " .. t.label)
	end
end

function spec.effectsLastUntilDone()
	local list = Tasks.build(Config.Tasks, label, C.scan_count, 1)
	local cams, lights = Tasks.broken(list)
	ok(cams.C07 and cams.C10 and cams.C11, "dead cameras at the start")
	ok(lights.corridor, "the corridor is dark at the start")
	for _, t in list do
		if t.id == "generator" then
			t.done = true
		end
	end
	cams, lights = Tasks.broken(list)
	ok(not cams.C10 and not lights.corridor, "the generator brings the corridor back")
	ok(cams.C07, "camera 07 still waits for its fuse")
end

function spec.everySpotIsOnTheMapAndReachable()
	local level = Watch.level(Config.Map, C)
	for _, spot in Config.Spots do
		local i = Grid.at(level.grid, spot.x, spot.z)
		ok(i, spot.id .. " is on the grid")
		-- walls sit on their face: the cell in front of a wall spot must be open
		local fx, fz = spot.x + math.sin(math.rad(spot.yaw)) * 3, spot.z + math.cos(math.rad(spot.yaw)) * 3
		local front = Grid.at(level.grid, fx, fz) :: number
		ok(not level.grid.blocked[front], spot.id .. ": the cell in front of it is open")
	end
end

function spec.payAddsUp()
	local list = Tasks.build(Config.Tasks, label, C.scan_count, 9)
	list[1].done = true
	list[#list].done = true
	local pay, done = Tasks.pay(list)
	eq(done, 2, "done")
	eq(pay, list[1].pay + list[#list].pay, "pay")
end

return spec
