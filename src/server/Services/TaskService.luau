--!strict
-- The night's tasks (plan section 3, "La ronde"), on the server: the list is drawn at the shift's start (Logic/Tasks);
-- the spots in workspace.P3.Spots get ProximityPrompts; a guard carries one item at a time; using it at its target
-- finishes the task and lifts its effect (a dead camera comes back, the corridor lights return). A guard caught by the
-- Unseen drops what they carried: it goes back where it was found. Every guard on shift gets the list and who carries
-- what (event "Tasks").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Tasks = require(Shared:WaitForChild("Logic"):WaitForChild("Tasks"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))

local C = Config.C

local TaskService = {}

-- NightService sets it: is this guard on shift and alive?
TaskService.isPlaying = nil :: ((player: Player) -> boolean)?

local list: { Tasks.Task } = {}
local carrying: { [Player]: string } = {} -- player -> task id of the item they hold
local prompts: { [string]: ProximityPrompt } = {} -- spot id -> its prompt
local dirty = true

local function playing(player: Player): boolean
	return TaskService.isPlaying ~= nil and TaskService.isPlaying(player)
end

local function taskById(id: string): Tasks.Task?
	for _, t in list do
		if t.id == id then
			return t
		end
	end
	return nil
end

local function holder(taskId: string): Player?
	for player, id in carrying do
		if id == taskId then
			return player
		end
	end
	return nil
end

local function notify(player: Player, text: string, good: boolean?)
	Net.event():FireClient(player, "Notice", text, good == true)
end

-- the item's look on its pickup spot: shown while it waits there
local function showItem(spotId: string, visible: boolean)
	local root = World.root :: Model
	local spots = root:FindFirstChild("Spots")
	local spot = spots and spots:FindFirstChild(spotId)
	if spot then
		for _, d in spot:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Item") then
				d.LocalTransparencyModifier = 0
				d.Transparency = if visible then (d:GetAttribute("BaseTransparency") or 0) :: number else 1
			end
		end
	end
end

-- which prompts are on, and what they say
local function refreshPrompts()
	for _, prompt in prompts do
		prompt.Enabled = false
	end
	for _, t in list do
		if t.done then
			continue
		end
		local target = prompts[t.target]
		if t.kind == "scan" and target then
			target.ActionText = "Scan"
			target.HoldDuration = t.hold
			target.Enabled = true
		elseif t.kind == "fetch" then
			local itemName = Config.itemById[t.item :: string].name
			local pickup = t.pickup and prompts[t.pickup]
			if pickup and not holder(t.id) then
				pickup.ActionText = "Take " .. string.lower(itemName)
				pickup.HoldDuration = C.pickup_hold
				pickup.Enabled = true
			end
			if target then
				target.ActionText = "Use " .. string.lower(itemName)
				target.HoldDuration = t.hold
				target.Enabled = true
			end
		end
	end
	for _, t in list do
		if t.kind == "fetch" and t.pickup then
			showItem(t.pickup, not t.done and holder(t.id) == nil)
		end
	end
end

local function applyEffects()
	local cams, lights = Tasks.broken(list)
	PowerDirector.setBroken(cams)
	return cams, lights
end

local function payload(): any
	local cams, lights = Tasks.broken(list)
	local held = {}
	for player, id in carrying do
		local t = taskById(id)
		if t and t.item then
			held[tostring(player.UserId)] = t.item
		end
	end
	local out = {}
	for _, t in list do
		local target = Config.spotById[t.target]
		local pickup = t.pickup and Config.spotById[t.pickup]
		local h = holder(t.id)
		table.insert(out, {
			id = t.id,
			kind = t.kind,
			label = t.label,
			item = t.item,
			done = t.done,
			carriedBy = if h then h.UserId else nil,
			target = { target.x, target.y, target.z },
			pickup = if pickup then { pickup.x, pickup.y, pickup.z } else nil,
		})
	end
	return { tasks = out, held = held, brokenCams = cams, brokenLights = lights }
end

local function changed()
	dirty = true
	refreshPrompts()
	applyEffects()
end

-- a new night: a new list, every item back on its spot
function TaskService.reset(seed: number, extraScans: number)
	table.clear(carrying)
	list = Tasks.build(Config.Tasks, function(id)
		return Config.spotById[id].label
	end, C.scan_count + extraScans, seed)
	changed()
end

-- the shift is over: no list, every dead camera and dark zone back to normal
function TaskService.clear()
	table.clear(carrying)
	list = {}
	changed()
end

function TaskService.allDone(): boolean
	for _, t in list do
		if not t.done then
			return false
		end
	end
	return #list > 0
end

function TaskService.summary(): (number, number, number)
	local pay, done = Tasks.pay(list)
	return done, #list, pay
end

-- a guard caught or gone: what they carried goes back where it was found
function TaskService.drop(player: Player)
	if carrying[player] then
		carrying[player] = nil
		changed()
	end
end

local function onTriggered(spotId: string, player: Player)
	if not playing(player) then
		return
	end
	for _, t in list do
		if t.done then
			continue
		end
		if t.kind == "scan" and t.target == spotId then
			t.done = true
			notify(player, "CHECKPOINT LOGGED", true)
			changed()
			return
		elseif t.kind == "fetch" and t.pickup == spotId and not holder(t.id) then
			if carrying[player] then
				notify(player, "YOUR HANDS ARE FULL")
				return
			end
			carrying[player] = t.id
			notify(player, string.upper(Config.itemById[t.item :: string].name) .. " TAKEN", true)
			changed()
			return
		elseif t.kind == "fetch" and t.target == spotId then
			if carrying[player] ~= t.id then
				notify(player, "YOU NEED THE " .. string.upper(Config.itemById[t.item :: string].name))
				return
			end
			carrying[player] = nil
			t.done = true
			notify(player, string.upper(t.label) .. ": DONE", true)
			changed()
			return
		end
	end
end

-- Studio debug (DebugService): as if this guard used the spot's prompt
function TaskService.trigger(spotId: string, player: Player)
	onTriggered(spotId, player)
end

function TaskService.init()
	Players.PlayerRemoving:Connect(function(player)
		TaskService.drop(player)
	end)
end

function TaskService.start()
	local root = World.root :: Model
	local spots = root:WaitForChild("Spots") :: Folder
	for _, spot in spots:GetChildren() do
		local prompt = spot:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			prompts[spot.Name] = prompt
			prompt.Enabled = false
			prompt.Triggered:Connect(function(player)
				onTriggered(spot.Name, player)
			end)
		end
	end
	refreshPrompts()
	while true do
		task.wait(C.task_broadcast)
		if dirty then
			dirty = false
			local data = payload()
			for _, player in Players:GetPlayers() do
				Net.event():FireClient(player, "Tasks", data)
			end
		end
	end
end

-- a client just arrived: send it the list now
function TaskService.send(player: Player)
	Net.event():FireClient(player, "Tasks", payload())
end

return TaskService
