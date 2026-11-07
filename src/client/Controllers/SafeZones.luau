--!strict
-- Shows where the cameras keep you safe (Adrien, Nov 6: "affiche clairement où sont les caméras où t'es safe"): the
-- floor every running camera films glows, cell for cell, from the same fields the server uses (Logic/Watch on the
-- config), so the glow never lies. LIVE: a faint cold light. FLICKER: the cameras that will hold turn red, the others
-- stay faint; that's where to run. BLACKOUT: only the red fields are left. Dead cameras (a task not done) show nothing.
-- The field drawn is the cells themselves; a guard counts as filmed a little beyond it (the doubt goes to the player),
-- so the glow is on the safe side. Settings: SafeZones off hides it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = Shared:WaitForChild("Logic")
local Watch = require(Logic:WaitForChild("Watch"))
local Grid = require(Logic:WaitForChild("Grid"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local C = Config.C

local SafeZones = {}

local level = Watch.level(Config.Map, C)
local g = level.grid
local fields: { [string]: Watch.Set } = {}
local folder: Folder
local lastKey = ""
local aims: { [string]: number } = {} -- a watcher's turn of a camera
local states: { [string]: boolean } = {} -- the fire doors and the plaster (Watch.DYNAMIC), from their attribute Solid

-- Greedy rectangles over a cell set: few parts instead of one per cell.
local function rectangles(cells: Watch.Set): { { number } }
	local used: { [number]: boolean } = {}
	local out = {}
	for iz = 0, g.d - 1 do
		for ix = 0, g.w - 1 do
			local i = Grid.index(g, ix, iz) :: number
			if cells[i] and not used[i] then
				local w = 1
				while ix + w < g.w do
					local j = Grid.index(g, ix + w, iz) :: number
					if not cells[j] or used[j] then
						break
					end
					w += 1
				end
				local h = 1
				while iz + h < g.d do
					local full = true
					for dx = 0, w - 1 do
						local j = Grid.index(g, ix + dx, iz + h) :: number
						if not cells[j] or used[j] then
							full = false
							break
						end
					end
					if not full then
						break
					end
					h += 1
				end
				for dz = 0, h - 1 do
					for dx = 0, w - 1 do
						used[Grid.index(g, ix + dx, iz + dz) :: number] = true
					end
				end
				table.insert(out, { ix, iz, w, h })
			end
		end
	end
	return out
end

local function draw(cells: Watch.Set, color: Color3, alpha: number)
	for _, r in rectangles(cells) do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = alpha
		p.Size = Vector3.new(r[3] * g.cell, 0.04, r[4] * g.cell)
		p.CFrame =
			CFrame.new(g.ox + (r[1] + r[3] / 2) * g.cell, g.floorY + C.zone_height, g.oz + (r[2] + r[4] / 2) * g.cell)
		p.Parent = folder
	end
end

local function rebuild(phase: string, holdouts: { [string]: boolean }, broken: { [string]: boolean })
	folder:ClearAllChildren()
	if not State.shift or Settings.get("SafeZones") == false then
		return
	end
	local strong, faint = {}, {}
	for _, cam in Config.Cameras do
		if broken[cam.id] then
			continue
		end
		local holds = cam.always or holdouts[cam.id] == true
		if phase == "BLACKOUT" then
			if holds then
				table.insert(strong, fields[cam.id])
			end
		elseif phase == "FLICKER" and holds then
			table.insert(strong, fields[cam.id])
		else
			table.insert(faint, fields[cam.id])
		end
	end
	local strongSet = Watch.union(strong)
	local faintSet = Watch.union(faint)
	for i in strongSet do
		faintSet[i] = nil
	end
	draw(faintSet, Color3.fromRGB(Config.rgb(C.zone_color)), C.zone_live_alpha)
	draw(strongSet, Color3.fromRGB(Config.rgb(C.zone_hold_color)), C.zone_dark_alpha)
end

function SafeZones.start()
	folder = Instance.new("Folder")
	folder.Name = "SafeZones"
	folder.Parent = workspace
	for _, cam in Config.Cameras do
		fields[cam.id] = Watch.coverage(level, Watch.cameraView(cam), C.sample_heights, C.sample_inset)
		task.wait()
	end
	-- a watcher turned a camera: its field moves
	local root = workspace:WaitForChild("P3"):WaitForChild("Cameras")
	for _, cam in Config.Cameras do
		local model = root:WaitForChild(cam.id, 10)
		if model then
			model:GetAttributeChangedSignal("AimOffset"):Connect(function()
				local offset = model:GetAttribute("AimOffset") or 0
				aims[cam.id] = offset :: number
				fields[cam.id] =
					Watch.coverage(level, Watch.cameraView(cam, offset :: number), C.sample_heights, C.sample_inset)
				lastKey = ""
			end)
		end
	end
	-- a fire door closed or the plaster broken: the grid changes, the cameras near it see again (as on the server)
	local geometry = workspace:WaitForChild("P3"):WaitForChild("Geometry")
	for _, b in Config.Map do
		if Watch.DYNAMIC[b.kind] == nil then
			continue
		end
		local box = geometry:WaitForChild(b.id, 10)
		if not box then
			continue
		end
		local function apply()
			local solid = box:GetAttribute("Solid")
			if type(solid) ~= "boolean" then
				return
			end
			local current = states[b.id]
			if current == nil then
				current = Watch.DYNAMIC[b.kind]
			end
			states[b.id] = solid
			if current == solid then
				return
			end
			Watch.relevel(level, Config.Map, C, states)
			for _, cam in Config.Cameras do
				local d = math.sqrt((cam.x - b.x) ^ 2 + (cam.z - b.z) ^ 2)
				if d <= cam.range + math.max(b.sx, b.sz) then
					fields[cam.id] =
						Watch.coverage(level, Watch.cameraView(cam, aims[cam.id]), C.sample_heights, C.sample_inset)
				end
			end
			lastKey = ""
		end
		box:GetAttributeChangedSignal("Solid"):Connect(apply)
		apply()
	end
	RunService.Heartbeat:Connect(function()
		local _, seg = State.now()
		local phase = if seg then seg.phase else "LIVE"
		local holdouts: { [string]: boolean } = {}
		local key = { phase, tostring(State.shift), tostring(Settings.get("SafeZones")) }
		if seg and seg.holdouts and phase ~= "LIVE" then
			for _, id in seg.holdouts do
				holdouts[id] = true
				table.insert(key, id)
			end
		end
		local broken: { [string]: boolean } = (State.tasks and State.tasks.brokenCams) or {}
		table.insert(key, "|")
		for id in broken do
			table.insert(key, id)
		end
		table.sort(key)
		local k = table.concat(key, ",")
		if k ~= lastKey then
			lastKey = k
			rebuild(phase, holdouts, broken)
		end
	end)
end

return SafeZones
