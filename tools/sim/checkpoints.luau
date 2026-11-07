--!strict
-- Finds pillar faces that look onto a deep blind spot (no camera films the cell in front of the face, nor its
-- neighbours, with every camera on): where the round's checkpoints go (Adrien, 7 Nov: "aller dans des blind spots
-- faire quelque chose pour quelques secondes"). Prints spots.csv rows, spread out, per floor.
--   lune run tools/sim/checkpoints [per floor = 5]
local process = require("@lune/process")
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
local want = tonumber(process.args[1]) or 5

-- the cell in front of the face is open and no camera films it, nor the cells right around it
local function deep(x: number, z: number): boolean
	local i = Grid.at(g, x, z)
	if not i or g.blocked[i] or filmed[i] then
		return false
	end
	for _, n in Grid.near(g, x, z, 1.2) do
		if filmed[n] then
			return false
		end
	end
	return true
end

local byFloor: { [string]: { any } } = {}
for _, b in Config.Map do
	if b.kind == "pillar" or b.kind == "wall" then
		for _, n in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			-- along the face, every 4 studs (a pillar: its middle)
			local along = if n[1] ~= 0 then b.sz else b.sx
			local steps = math.max(0, math.floor((along - 2) / 4))
			for k = -steps, steps do
				local fx = b.x + n[1] * (b.sx / 2 + 0.15) + (if n[1] == 0 then k * 2 else 0)
				local fz = b.z + n[2] * (b.sz / 2 + 0.15) + (if n[2] == 0 then k * 2 else 0)
				-- not in a corner: open floor on both sides along the face
				local sx, sz = fx + n[1] * 2.5, fz + n[2] * 2.5
				local left = Grid.at(g, sx + n[2] * 3, sz + n[1] * 3)
				local right = Grid.at(g, sx - n[2] * 3, sz - n[1] * 3)
				local open = left ~= nil and right ~= nil and not g.blocked[left] and not g.blocked[right]
				local floorId = Config.floorAt(b.x)
				if open and floorId ~= "P1" and floorId ~= "P4" and deep(sx, sz) then
					local floor, offset = Config.floorAt(b.x)
					byFloor[floor] = byFloor[floor] or {}
					table.insert(byFloor[floor], {
						x = fx,
						z = fz,
						lx = fx - offset,
						yaw = math.deg(math.atan2(n[1], n[2])),
						pillar = b.id,
					})
				end
			end
		end
	end
end
for floor, list in byFloor do
	-- spread: farthest-first from the first
	table.sort(list, function(a, b)
		return a.pillar < b.pillar
	end)
	local picked = { list[1] }
	while #picked < math.min(want, #list) do
		local best, bestD = nil, -1
		for _, c in list do
			local d = math.huge
			for _, p in picked do
				d = math.min(d, (c.x - p.x) ^ 2 + (c.z - p.z) ^ 2)
			end
			if d > bestD then
				best, bestD = c, d
			end
		end
		table.insert(picked, best)
	end
	print(`{floor}: {#list} candidate faces`)
	for _, p in picked do
		print(string.format("  %.2f,3.2,%.2f,%d  (%s)", p.lx, p.z, p.yaw, p.pillar))
	end
end
