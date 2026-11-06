--!strict
-- The night (plan section 3): it starts once a player is in, runs the power cycle to 6 h, counts the round checkpoints
-- and handles deaths. Phase 0 plays Config.C.night_test on a loop; tasks, pay and saves come in phase 1.
-- A death (plan section 4, "La mort"): the player freezes, the client plays the tape tear for death_seconds, then they
-- wake up in the security booth and the night goes on.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))
local UnseenService = require(script.Parent:WaitForChild("UnseenService"))
local CamcorderService = require(script.Parent:WaitForChild("CamcorderService"))

local C = Config.C

local NightService = {}

local dead: { [Player]: boolean } = {}
local done: { [string]: boolean } = {}
local deaths = 0
local running = false
local nightNumber = C.night_test

local function roundsPayload(): (number, number, { string })
	local ids = {}
	for id in done do
		table.insert(ids, id)
	end
	table.sort(ids)
	return #ids, #Config.Rounds, ids
end

local function sendRounds(player: Player?)
	local n, total, ids = roundsPayload()
	if player then
		Net.event():FireClient(player, "Rounds", n, total, ids)
	else
		Net.event():FireAllClients("Rounds", n, total, ids)
	end
end

function NightService.isDead(player: Player): boolean
	return dead[player] == true
end

function NightService.kill(player: Player)
	if dead[player] or not running then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	dead[player] = true
	deaths += 1
	CamcorderService.block(player, true)
	root.Anchored = true
	Net.event():FireClient(player, "Death", C.death_seconds)
	task.delay(C.death_seconds, function()
		if player.Parent and root.Parent then
			root.CFrame = World.spawnCFrame()
			root.Anchored = false
		end
		dead[player] = nil
		CamcorderService.block(player, false)
		if player.Parent then
			Net.event():FireClient(player, "Respawn")
		end
	end)
end

function NightService.startNight(night: number)
	nightNumber = night
	table.clear(done)
	deaths = 0
	running = true
	CamcorderService.reset()
	PowerDirector.startNight(night, os.time())
	sendRounds()
	print(`[NightService] night {night} started`)
end

local function endNight()
	running = false
	PowerDirector.stop()
	local n, total = roundsPayload()
	Net.event():FireAllClients("NightEnd", { night = nightNumber, rounds = n, total = total, deaths = deaths })
	print(`[NightService] night {nightNumber} ended: {n}/{total} rounds, {deaths} deaths`)
end

function NightService.init()
	UnseenService.onKill = NightService.kill
	UnseenService.isDead = NightService.isDead

	Actions.on("Ready", function(player: Player)
		PowerDirector.broadcast(player)
		sendRounds(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.WalkSpeed = C.player_walk_speed
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		dead[player] = nil
	end)
end

local function wireRounds()
	local root = World.root :: Model
	for _, p in (root:WaitForChild("Rounds") :: Folder):GetChildren() do
		local prompt = p:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				if not running or dead[player] or done[p.Name] then
					return
				end
				done[p.Name] = true
				prompt.Enabled = false
				sendRounds()
			end)
		end
	end
end

local function resetRounds()
	local root = World.root :: Model
	for _, p in (root:WaitForChild("Rounds") :: Folder):GetChildren() do
		local prompt = p:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = true
		end
	end
end

function NightService.start()
	wireRounds()
	while true do
		-- wait for someone to play
		while #Players:GetPlayers() == 0 do
			task.wait(0.5)
		end
		task.wait(C.night_start_delay)
		resetRounds()
		NightService.startNight(nightNumber)
		repeat
			task.wait(0.5)
			local t, _, tl = PowerDirector.now()
		until not tl or t >= tl.length or #Players:GetPlayers() == 0
		endNight()
		task.wait(C.night_restart_delay)
	end
end

-- Studio debug: play another night now
function NightService.restart(night: number)
	if Config.nightByNumber[night] then
		nightNumber = night
		resetRounds()
		NightService.startNight(night)
	end
end

return NightService
