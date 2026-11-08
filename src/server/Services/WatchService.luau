--!strict
-- Knows at every moment which cells are filmed (plan section 11). The fixed cameras' fields are computed once at start
-- from the map config (Logic/Watch); the filmed set is the union of the active cameras (PowerDirector) and the
-- camcorders that film (CamcorderService). Only the server decides: a client can never say "I am filmed".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Logic = Shared:WaitForChild("Logic")
local Watch = require(Logic:WaitForChild("Watch"))
local Grid = require(Logic:WaitForChild("Grid"))

local C = Config.C

local WatchService = {}

WatchService.level = Watch.level(Config.Map, C)
WatchService.grid = WatchService.level.grid
WatchService.fields = {} :: { [string]: Watch.Set }
WatchService.ready = false
WatchService.version = 0 -- bumps every time the filmed set changes
WatchService.changed = Instance.new("BindableEvent") -- fires after every change

local active: { string } = {}
local rangeScale = 1 -- the shift's mode shortens every camera's field (content/modes.csv, cam_range)
local cached: { [number]: { [string]: Watch.Set } } = {} -- the fields at each range already computed
local camcorders: { [Player]: Watch.Set } = {}
local extras: { [string]: Watch.Set } = {} -- other fields for a while: a burning flare (SkillService)
local filmed: Watch.Set = {}
local lastSent: { [Player]: string } = {}

local function rebuild()
	local sets = {}
	for _, id in active do
		local f = WatchService.fields[id]
		if f then
			table.insert(sets, f)
		end
	end
	for _, s in camcorders do
		table.insert(sets, s)
	end
	for _, s in extras do
		table.insert(sets, s)
	end
	filmed = Watch.union(sets)
	WatchService.version += 1
	WatchService.changed:Fire()
end

-- The dynamic blocks (Watch.DYNAMIC: fire doors, the plaster wall): their state now, and a change of it. The grid
-- and the occluders are rebuilt in place (the Unseen's paths change at once) and the cameras near the block see
-- again. The world model of the block (World) carries the attribute Solid for the clients.
WatchService.states = {} :: { [string]: boolean }
local aims: { [string]: number } = {} -- watchers' turns (below)

function WatchService.setSolid(id: string, solid: boolean)
	local block
	for _, b in Config.Map do
		if b.id == id then
			block = b
		end
	end
	local current = WatchService.states[id]
	if current == nil and block then
		current = Watch.DYNAMIC[block.kind]
	end
	WatchService.states[id] = solid
	if current == solid then
		return
	end
	Watch.relevel(WatchService.level, Config.Map, C, WatchService.states)
	if block and WatchService.ready then
		for _, cam in Config.Cameras do
			local d = math.sqrt((cam.x - block.x) ^ 2 + (cam.z - block.z) ^ 2)
			if d <= cam.range + math.max(block.sx, block.sz) then
				WatchService.fields[cam.id] = Watch.coverage(
					WatchService.level,
					Watch.cameraView(cam, aims[cam.id]),
					C.sample_heights,
					C.sample_inset
				)
			end
		end
	end
	rebuild()
end

-- A watcher turns a camera (CoopService): its field is computed again at the new aim, and the camera model carries
-- the offset (attribute AimOffset) so the clients turn its head and redraw its safe zone.

function WatchService.aimOffset(id: string): number
	return aims[id] or 0
end

function WatchService.setAimOffset(id: string, offset: number)
	local cam = Config.cameraById[id]
	if not cam or (aims[id] or 0) == offset then
		return
	end
	aims[id] = if offset ~= 0 then offset else nil
	WatchService.fields[id] =
		Watch.coverage(WatchService.level, Watch.cameraView(cam, offset, rangeScale), C.sample_heights, C.sample_inset)
	local root = workspace:FindFirstChild("P3")
	local model = root and root:FindFirstChild("Cameras") and (root :: any).Cameras:FindFirstChild(id)
	if model then
		model:SetAttribute("AimOffset", offset)
	end
	rebuild()
end

-- The shift's mode: every fixed camera sees `scale` times as far (computed once per scale, yielding, then cached)
function WatchService.setRangeScale(scale: number)
	if scale == rangeScale then
		return
	end
	rangeScale = scale
	local fields = cached[scale]
	if not fields then
		fields = {}
		for _, cam in Config.Cameras do
			fields[cam.id] = Watch.coverage(
				WatchService.level,
				Watch.cameraView(cam, nil, scale),
				C.sample_heights,
				C.sample_inset,
				function()
					task.wait()
				end
			)
		end
		cached[scale] = fields
	end
	for id, f in fields do
		WatchService.fields[id] = f
	end
	for id, offset in aims do
		local cam = Config.cameraById[id]
		WatchService.fields[id] =
			Watch.coverage(WatchService.level, Watch.cameraView(cam, offset, scale), C.sample_heights, C.sample_inset)
	end
	rebuild()
end

function WatchService.resetAims()
	for id in table.clone(aims) do
		WatchService.setAimOffset(id, 0)
	end
end

-- the cameras that run now (PowerDirector, at every phase change)
function WatchService.setActive(ids: { string })
	active = table.clone(ids)
	rebuild()
end

function WatchService.active(): { string }
	return active
end

-- a camcorder's field this frame, or nil when it stops filming (CamcorderService)
function WatchService.setCamcorder(player: Player, cells: Watch.Set?)
	if camcorders[player] == nil and cells == nil then
		return
	end
	camcorders[player] = cells
	rebuild()
end

-- a field that films for a while (a flare): set it, or nil to take it away
function WatchService.setExtra(id: string, cells: Watch.Set?)
	extras[id] = cells
	rebuild()
end

function WatchService.filmed(): Watch.Set
	return filmed
end

function WatchService.rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- Is this player filmed? Their footprint plus the lag margin: at the edge of a field, they count as filmed
-- (CLAUDE.md, "Le doute profite au joueur").
function WatchService.isFilmed(player: Player): boolean
	local root = WatchService.rootOf(player)
	if not root then
		return true
	end
	local p = root.Position
	return Watch.circleFilmed(WatchService.grid, filmed, p.X, p.Z, C.player_radius + C.edge_margin)
end

-- the active fixed cameras that film this player (they turn toward them, client side)
function WatchService.seenBy(player: Player): { string }
	local root = WatchService.rootOf(player)
	if not root then
		return {}
	end
	local p = root.Position
	return Watch.seenBy(WatchService.grid, WatchService.fields, active, p.X, p.Z, C.player_radius)
end

function WatchService.cellOf(position: Vector3): number?
	return Grid.at(WatchService.grid, position.X, position.Z)
end

function WatchService.start()
	local t0 = os.clock()
	for _, cam in Config.Cameras do
		WatchService.fields[cam.id] = Watch.coverage(
			WatchService.level,
			Watch.cameraView(cam),
			C.sample_heights,
			C.sample_inset,
			function()
				task.wait()
			end
		)
	end
	cached[1] = table.clone(WatchService.fields)
	WatchService.ready = true
	rebuild()
	print(`[WatchService] {#Config.Cameras} camera fields in {math.floor((os.clock() - t0) * 1000)} ms`)

	Players.PlayerRemoving:Connect(function(player)
		lastSent[player] = nil
		if camcorders[player] then
			WatchService.setCamcorder(player, nil)
		end
	end)

	-- each client learns whether it is filmed and by which cameras (the cameras turn toward it, the sound opens up)
	while true do
		task.wait(C.watch_broadcast)
		for _, player in Players:GetPlayers() do
			local isFilmed = WatchService.isFilmed(player)
			local ids = WatchService.seenBy(player)
			local key = (if isFilmed then "1" else "0") .. table.concat(ids, ",")
			if lastSent[player] ~= key then
				lastSent[player] = key
				Net.event():FireClient(player, "Watch", isFilmed, ids)
			end
		end
	end
end

return WatchService
