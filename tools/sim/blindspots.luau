--!strict
-- Lists open cells that no camera films in LIVE (every camera on), at least 2 cells from any solid cell:
-- candidate hiding places for tapes. lune run tools/sim/blindspots
local Config = require("../../src/shared/Config")
local Grid = require("../../src/shared/Logic/Grid")
local Watch = require("../../src/shared/Logic/Watch")

local C = Config.C
local level = Watch.level(Config.Map, C)
local g = level.grid
local sets = {}
for _, cam in Config.Cameras do
	table.insert(sets, Watch.coverage(level, Watch.cameraView(cam), C.sample_heights, C.sample_inset))
end
local filmed = Watch.union(sets)
local out = {}
for i = 1, Grid.count(g) do
	if not g.blocked[i] and not filmed[i] then
		local x, z = Grid.center(g, i)
		local clear = true
		for _, n in Grid.near(g, x, z, 2.5) do
			if g.blocked[n] or filmed[n] then
				clear = false
				break
			end
		end
		if clear then
			table.insert(out, string.format("(%d, %d)", x, z))
		end
	end
end
print(#out .. " deep blind cells")
print(table.concat(out, " "))
