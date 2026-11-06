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
local Rng = require(Shared:WaitForChild("Logic"):WaitForChild("Rng"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))

local C = Config.C

local TaskService = {}

-- NightService sets it: is this guard on shift and alive?
TaskService.isPlaying = nil :: ((player: Player) -> boolean)?

local list: { Tasks.Task } = {}
-- the cut lines (plan section 3, night 4: "les câbles de caméras arrachés"): when each is cut, and the spots added
local cuts: { number } = {}
local cutRng: any = nil
local dynamic: { [string]: any } = {} -- spot id -> its row (x, y, z, ...), for the spots added during the night
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

local function spotRow(id: string): any
	return Config.spotById[id] or dynamic[id]
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
		local target = spotRow(t.target)
		local pickup = t.pickup and spotRow(t.pickup)
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
local function clearDynamic()
	for id in dynamic do
		World.removeSpot(id)
		prompts[id] = nil
	end
	table.clear(dynamic)
	table.clear(cuts)
end

function TaskService.reset(seed: number, extraScans: number, cables: number?, length: number?)
	table.clear(carrying)
	clearDynamic()
	-- the night's cut lines, spread over it
	cutRng = Rng.new(seed + 77)
	local n = cables or 0
	for k = 1, n do
		local f = C.cable_cut_margin + (1 - 2 * C.cable_cut_margin) * k / (n + 1)
		table.insert(cuts, (length or 0) * f + cutRng.int(-20, 20))
	end
	table.sort(cuts)
	list = Tasks.build(Config.Tasks, function(id)
		return Config.spotById[id].label
	end, C.scan_count + extraScans, seed)
	changed()
end

-- the shift is over: no list, every dead camera and dark zone back to normal
function TaskService.clear()
	table.clear(carrying)
	clearDynamic()
	list = {}
	changed()
end

function TaskService.isCarrying(player: Player): boolean
	return carrying[player] ~= nil
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

local function register(spotId: string, model: Instance)
	local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompts[spotId] = prompt
		prompt.Enabled = false
		prompt.Triggered:Connect(function(player)
			TaskService.trigger(spotId, player)
		end)
	end
end

-- The Unseen cuts a camera's line: the camera dies, a junction box under it waits to be spliced (a task).
local function cutLine()
	local cams, _ = Tasks.broken(list)
	local candidates = {}
	for id in string.gmatch(C.cuttable_cameras, "[^;]+") do
		if not cams[id] and not dynamic["Line_" .. id] then
			table.insert(candidates, id)
		end
	end
	if #candidates == 0 then
		return
	end
	local id = cutRng.pick(candidates)
	local cam = Config.cameraById[id]
	local spot = {
		id = "Line_" .. id,
		kind = "junction",
		label = "Line " .. id,
		x = cam.x,
		y = C.junction_height,
		z = cam.z,
		yaw = math.deg(math.atan2(cam.tx - cam.x, cam.tz - cam.z)),
	}
	dynamic[spot.id] = spot
	register(spot.id, World.addSpot(spot))
	table.insert(list, {
		id = "splice:" .. id,
		kind = "scan",
		label = "Splice the line of cam " .. string.sub(id, 2),
		target = spot.id,
		effect = { "cam:" .. id },
		pay = C.pay_splice,
		hold = C.splice_hold,
		done = false,
	})
	for _, player in Players:GetPlayers() do
		if playing(player) then
			notify(player, "CAM " .. string.sub(id, 2) .. " LINE CUT")
		end
	end
	changed()
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
			notify(player, if string.sub(t.id, 1, 7) == "splice:" then "LINE SPLICED" else "CHECKPOINT LOGGED", true)
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

-- Studio debug: the whole round done at once
function TaskService.completeAll()
	for _, t in list do
		t.done = true
	end
	table.clear(carrying)
	changed()
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
		-- the sign-in book belongs to CoopService
		if spot:GetAttribute("Kind") ~= "signin" then
			register(spot.Name, spot)
		end
	end
	refreshPrompts()
	while true do
		task.wait(C.task_broadcast)
		local t, _, tl = PowerDirector.now()
		if tl and #cuts > 0 and t >= cuts[1] then
			table.remove(cuts, 1)
			cutLine()
		end
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
