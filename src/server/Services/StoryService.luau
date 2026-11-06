--!strict
-- The story's pieces during a shift (plan section 6, "Comment l'histoire se raconte"):
--   the dispatcher's radio (content/radio.csv): night 1 is the tutorial, later nights grow strange; lines fire on the
--     shift's start and on its moments (first flicker, first blackout, first cut line, 3 AM, 5 AM, a catch, 6 AM);
--   one hidden tape a night (content/tapes.csv) in a deep blind spot (spots of kind "collect"): whoever finds it, every
--     guard on the shift keeps it in their profile and can play it in the lobby (TAPES);
--   the booth's log book (content/logbook.csv): the client opens it from its prompt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Rng = require(Shared:WaitForChild("Logic"):WaitForChild("Rng"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))

local StoryService = {}

-- NightService sets it: the guards on this shift
StoryService.guards = nil :: (() -> { Player })?

local night = 0
local fired: { [string]: boolean } = {}
local shift = 0
local tapeId: string? = nil
local tapeSpot: string? = nil
local hidden: { [string]: Model } = {} -- collect spot id -> its model

local function guards(): { Player }
	return if StoryService.guards then StoryService.guards() else {}
end

local function say(text: string)
	for _, player in guards() do
		Net.event():FireClient(player, "Radio", text)
	end
end

-- a moment of the night: every radio line for it (this night's, or any night's) once, after its delay
function StoryService.trigger(trigger: string)
	if night == 0 or fired[trigger] then
		return
	end
	fired[trigger] = true
	local thisShift = shift
	for _, line in Config.Radio do
		if line.trigger == trigger and (line.night == 0 or line.night == night) then
			-- a night with its own line for this moment doesn't also play the generic one
			if line.night == 0 then
				local own = false
				for _, other in Config.Radio do
					if other.trigger == trigger and other.night == night then
						own = true
					end
				end
				-- (at 3 AM a night's own line comes after the generic one: night 4's radio speaking on its own)
				if own and trigger ~= "half" then
					continue
				end
			end
			if line.delay <= 0 then
				say(line.text) -- now: the night may end right after (the 6 AM line)
			else
				task.delay(line.delay, function()
					if shift == thisShift and night ~= 0 then
						say(line.text)
					end
				end)
			end
		end
	end
end

local function showTape(spotId: string?, visible: boolean)
	for id, model in hidden do
		local on = visible and id == spotId
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Item") then
				d.Transparency = if on then 0 else 1
			elseif d:IsA("ProximityPrompt") then
				d.Enabled = on
				d.ActionText = "Take old tape"
			end
		end
	end
end

function StoryService.begin(n: number, seed: number)
	night = n
	shift += 1
	table.clear(fired)
	-- tonight's hidden tape: the first one the shift's first guard hasn't found yet
	tapeId, tapeSpot = nil, nil
	local first = guards()[1]
	local profile = first and Data.get(first)
	for _, tape in Config.Tapes do
		if not (profile and profile.tapes[tape.id]) then
			tapeId = tape.id
			break
		end
	end
	if tapeId then
		local ids = {}
		for id in hidden do
			table.insert(ids, id)
		end
		table.sort(ids)
		if #ids > 0 then
			tapeSpot = Rng.new(seed + 13).pick(ids)
		end
	end
	showTape(tapeSpot, tapeId ~= nil)
	StoryService.trigger("start")
end

function StoryService.finish(outcome: string)
	if outcome == "cleared" then
		StoryService.trigger("cleared")
	end
	night = 0
	shift += 1
	showTape(nil, false)
end

local function onTape(player: Player)
	if not tapeId or night == 0 then
		return
	end
	local tape = Config.tapeById[tapeId]
	for _, guard in guards() do
		local profile = Data.get(guard)
		if profile then
			profile.tapes[tape.id] = true
			Data.changed(guard)
		end
		Net.event():FireClient(guard, "Notice", "TAPE FOUND: " .. tape.title, true)
	end
	Net.event():FireClient(player, "TapeFound", tape.id)
	tapeId = nil
	showTape(nil, false)
end

-- Studio debug: as if this guard found tonight's tape
function StoryService.debugTake(player: Player)
	onTape(player)
end

-- where tonight's tape lies (nil when there is none)
function StoryService.tapeSpot(): string?
	return if tapeId then tapeSpot else nil
end

function StoryService.start()
	local root = World.root :: Model
	local spots = root:WaitForChild("Spots") :: Folder
	for _, spot in spots:GetChildren() do
		local kind = spot:GetAttribute("Kind")
		if kind == "collect" and spot:IsA("Model") then
			hidden[spot.Name] = spot
			local prompt = spot:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function(player)
					if spot.Name == tapeSpot then
						onTape(player)
					end
				end)
			end
		elseif kind == "logbook" then
			local prompt = spot:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.ActionText = "Read the log"
				prompt.HoldDuration = 0
				prompt.Enabled = true
			end
		end
	end
	showTape(nil, false)
	PowerDirector.changed.Event:Connect(function(seg: any)
		if seg.phase == "FLICKER" then
			StoryService.trigger("first_flicker")
		elseif seg.phase == "BLACKOUT" then
			StoryService.trigger("first_blackout")
		end
	end)
	-- 3 AM and 5 AM
	while true do
		task.wait(1)
		local t, _, tl = PowerDirector.now()
		if tl and night ~= 0 then
			if t >= tl.length * 0.5 then
				StoryService.trigger("half")
			end
			if t >= tl.length * 5 / 6 then
				StoryService.trigger("last_hour")
			end
		end
	end
end

return StoryService
