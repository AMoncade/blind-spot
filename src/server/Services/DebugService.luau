--!strict
-- Studio only (plan section 5: "Un outil de débogage peint le sol"): paints every open cell of the floor green when
-- filmed and red in a blind spot, live, phase by phase. The client asks with the Debug action (F6 floor, F7 next
-- segment, F8 next night); a live server refuses everything.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Grid = require(Shared:WaitForChild("Logic"):WaitForChild("Grid"))

local Server = script.Parent.Parent
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local WatchService = require(script.Parent:WaitForChild("WatchService"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))
local NightService = require(script.Parent:WaitForChild("NightService"))
local TaskService = require(script.Parent:WaitForChild("TaskService"))

local DebugService = {}

local FILMED = Color3.fromRGB(40, 200, 90)
local BLIND = Color3.fromRGB(220, 40, 40)

local floor: Folder? = nil
local tiles: { [number]: Part } = {}
local painted = -1

local function paint()
	if not floor or painted == WatchService.version then
		return
	end
	painted = WatchService.version
	local filmed = WatchService.filmed()
	for i, tile in tiles do
		tile.Color = if filmed[i] then FILMED else BLIND
	end
end

local function toggleFloor()
	if floor then
		floor:Destroy()
		floor = nil
		table.clear(tiles)
		return
	end
	local g = WatchService.grid
	local f = Instance.new("Folder")
	f.Name = "DebugFloor"
	for i = 1, Grid.count(g) do
		if not g.blocked[i] then
			local x, z = Grid.center(g, i)
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Transparency = 0.55
			p.Size = Vector3.new(g.cell - 0.15, 0.05, g.cell - 0.15)
			p.CFrame = CFrame.new(x, g.floorY + 0.05, z)
			p.Parent = f
			tiles[i] = p
		end
	end
	f.Parent = workspace
	floor = f
	painted = -1
	paint()
end

function DebugService.init()
	Actions.on("Debug", function(player: Player, command: unknown, arg: unknown)
		if not RunService:IsStudio() or type(command) ~= "string" then
			return
		end
		if command == "task" and type(arg) == "string" then
			TaskService.trigger(arg, player) -- as if the guard used that spot's prompt
			return
		elseif command == "kill" then
			NightService.kill(player) -- as if the Unseen touched this guard
			return
		elseif command == "done" then
			TaskService.completeAll()
			return
		end
		if command == "floor" then
			toggleFloor()
		elseif command == "skip" then
			PowerDirector.skip()
		elseif command == "night" then
			local _, _, tl = PowerDirector.now()
			local current = if tl then tl.night else 0
			NightService.restart(current % 5 + 1)
		end
	end)
	WatchService.changed.Event:Connect(paint)
end

return DebugService
