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
		local list = Tasks.build(Config.Tasks, label, C.scan_count, seed, 3)
		local checkpoints, fetches = 0, 0
		for _, t in list do
			if string.sub(t.id, 1, 5) == "scan:" then
				checkpoints += 1
			elseif t.kind == "fetch" then
				fetches += 1
				ok(t.item and t.pickup, t.id .. " has an item and a pickup")
			end
			ok(Config.spotById[t.target], t.id .. " target exists")
		end
		eq(checkpoints, C.scan_count, "checkpoints")
		eq(fetches, 3, "fetch tasks on night 3")
	end
end

function spec.theFinaleIsOnlyOnNightFive()
	local function has(night: number, id: string): boolean
		for _, t in Tasks.build(Config.Tasks, label, C.scan_count, 1, night) do
			if t.id == id then
				return true
			end
		end
		return false
	end
	ok(not has(3, "plaster") and not has(3, "sealed"), "no finale on night 3")
	ok(has(5, "plaster") and has(5, "sealed"), "the finale on night 5")
	ok(has(3, "breakers") and has(5, "breakers"), "the P4 breakers every night")
end

function spec.theRoundComesThroughTheNight()
	local def = Config.nightByNumber[3]
	local hour = def.length / (C.night_clock_end - C.night_clock_start)
	local list = Tasks.build(Config.Tasks, label, C.scan_count + 1, 4, 3, hour)
	local first, last = math.huge, 0
	for _, t in list do
		first = math.min(first, t.at)
		last = math.max(last, t.at)
		ok(t.at >= 0 and t.at < def.length, t.id .. " shows up during the night")
	end
	eq(first, 0, "the first tasks are there at midnight")
	ok(last >= def.length / 2, "the last ones come in the second half of the night")
	-- an effect starts when its task shows up: the P4 breakers trip at their hour
	local breakers
	for _, t in list do
		if t.id == "breakers" then
			breakers = t
		end
	end
	ok(breakers and breakers.at > 0, "the breakers come later")
	local cams = Tasks.broken(list, 0)
	ok(not cams.C61, "P4 is lit before the breakers trip")
	cams = Tasks.broken(list, breakers.at)
	ok(cams.C61, "P4 goes dark when they trip")
	ok(not Tasks.released(breakers, breakers.at - 1) and Tasks.released(breakers, breakers.at), "released at its hour")
end

function spec.labelsAreFilled()
	local list = Tasks.build(Config.Tasks, label, C.scan_count, 3, 3)
	for _, t in list do
		ok(not string.find(t.label, "{", 1, true), "label filled: " .. t.label)
	end
end

function spec.effectsLastUntilDone()
	local list = Tasks.build(Config.Tasks, label, C.scan_count, 1, 3)
	local cams, lights = Tasks.broken(list)
	ok(cams.C07 and cams.C10 and cams.C11, "dead cameras at the start")
	ok(lights["P3:corridor"], "the corridor is dark at the start")
	for _, t in list do
		if t.id == "generator" then
			t.done = true
		end
	end
	cams, lights = Tasks.broken(list)
	ok(not cams.C10 and not lights["P3:corridor"], "the generator brings the corridor back")
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
	local list = Tasks.build(Config.Tasks, label, C.scan_count, 9, 3)
	list[1].done = true
	list[#list].done = true
	local pay, done = Tasks.pay(list)
	eq(done, 2, "done")
	eq(pay, list[1].pay + list[#list].pay, "pay")
end

return spec
