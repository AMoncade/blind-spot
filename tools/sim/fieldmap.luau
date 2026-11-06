--!strict
-- Prints the P3 grid: '#' solid, '.' filmed, ' ' blind spot, digits = a camera position. lune run tools/sim/fieldmap [ids]
local process = require("@lune/process")
local Config = require("../../src/shared/Config")
local Grid = require("../../src/shared/Logic/Grid")
local Watch = require("../../src/shared/Logic/Watch")

local C = Config.C
local level = Watch.level(Config.Map, C)
local g = level.grid
local ids = {}
for k = 1, #process.args do
	table.insert(ids, process.args[k])
end
if #ids == 0 then
	for _, cam in Config.Cameras do
		table.insert(ids, cam.id)
	end
end
local sets = {}
for _, id in ids do
	table.insert(sets, Watch.coverage(level, Watch.cameraView(Config.cameraById[id]), C.sample_heights, C.sample_inset))
end
local filmed = Watch.union(sets)
local marks: { [number]: string } = {}
for _, cam in Config.Cameras do
	local i = Grid.at(g, math.clamp(cam.x, g.ox + 0.1, g.ox + g.w * g.cell - 0.1), cam.z)
	if i then
		marks[i] = string.sub(cam.id, -1)
	end
end
for iz = g.d - 1, 0, -1 do
	local row = {}
	for ix = 0, g.w - 1 do
		local i = Grid.index(g, ix, iz) :: number
		table.insert(row, marks[i] or (if g.blocked[i] then "#" elseif filmed[i] then "." else " "))
	end
	print(table.concat(row))
end
