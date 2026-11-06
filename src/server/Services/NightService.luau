--!strict
-- The night (plan section 3). A shift starts when a lift leaves the lobby with its guards (LobbyService.launch): they
-- arrive in the P3's security booth, the power cycle runs to 6 h, the round checkpoints count, and at 6 AM everyone
-- goes back up to the lobby. Phase 0 plays Config.C.night_test; tasks, pay and saves come in phase 1.
-- A death (plan section 4, "La mort"): the guard freezes, the client plays the tape tear for death_seconds, then they
-- wake up in the booth and the night goes on.
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
local playing: { [Player]: boolean } = {} -- the guards on this shift
local done: { [string]: boolean } = {}
local deaths = 0
local running = false
local shift = 0 -- counts shifts, so a late return to the lobby never touches the next one
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

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function moveTo(player: Player, cf: CFrame)
	local root = rootOf(player)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = cf
	end
end

function NightService.isDead(player: Player): boolean
	return dead[player] == true
end

-- on this shift and not frozen in a death (the Unseen only sees these guards)
function NightService.isPlaying(player: Player): boolean
	return running and playing[player] == true and not dead[player]
end

function NightService.running(): boolean
	return running
end

function NightService.kill(player: Player)
	if dead[player] or not running or not playing[player] then
		return
	end
	local root = rootOf(player)
	if not root then
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

local function resetRounds()
	local root = World.root :: Model
	for _, p in (root:WaitForChild("Rounds") :: Folder):GetChildren() do
		local prompt = p:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = true
		end
	end
end

local function endNight()
	if not running then
		return
	end
	running = false
	PowerDirector.stop()
	local n, total = roundsPayload()
	local guards = {}
	for player in playing do
		table.insert(guards, player)
	end
	for _, player in guards do
		Net.event():FireClient(player, "NightEnd", { night = nightNumber, rounds = n, total = total, deaths = deaths })
	end
	print(`[NightService] night {nightNumber} ended: {n}/{total} rounds, {deaths} deaths`)
	local ended = shift
	task.delay(C.lobby_return_delay, function()
		-- back up to the lobby
		for _, player in guards do
			if player.Parent then
				moveTo(player, World.lobbyCFrame())
				Net.event():FireClient(player, "Shift", false)
			end
		end
		if shift == ended then
			table.clear(playing)
			table.clear(dead)
		end
	end)
end

-- A lift arrived at the P3 with these guards: the shift starts. Returns false when one is already running.
function NightService.launch(guards: { Player }, night: number?): boolean
	if running then
		return false
	end
	nightNumber = if night and Config.nightByNumber[night] then night else C.night_test
	table.clear(done)
	table.clear(playing)
	table.clear(dead)
	deaths = 0
	running = true
	shift += 1
	resetRounds()
	for k, player in guards do
		playing[player] = true
		-- side by side in the booth
		moveTo(player, World.spawnCFrame() * CFrame.new((k - 2.5) * 1.6, 0, 0))
		Net.event():FireClient(player, "Shift", true)
	end
	CamcorderService.reset()
	PowerDirector.startNight(nightNumber, os.time())
	sendRounds()
	print(`[NightService] night {nightNumber} started with {#guards} guard(s)`)
	return true
end

function NightService.init()
	UnseenService.onKill = NightService.kill
	UnseenService.isPlaying = NightService.isPlaying

	Actions.on("Ready", function(player: Player)
		PowerDirector.broadcast(player)
		sendRounds(player)
		Net.event():FireClient(player, "Shift", playing[player] == true)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.WalkSpeed = C.player_walk_speed
			-- a guard who respawns during their shift (a reset) goes back to the booth
			if running and playing[player] then
				task.defer(function()
					moveTo(player, World.spawnCFrame())
				end)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		dead[player] = nil
		playing[player] = nil
	end)
end

local function wireRounds()
	local root = World.root :: Model
	for _, p in (root:WaitForChild("Rounds") :: Folder):GetChildren() do
		local prompt = p:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				if not running or not playing[player] or dead[player] or done[p.Name] then
					return
				end
				done[p.Name] = true
				prompt.Enabled = false
				sendRounds()
			end)
		end
	end
end

function NightService.start()
	wireRounds()
	while true do
		task.wait(0.5)
		if running then
			local t, _, tl = PowerDirector.now()
			if not next(playing) or (tl and t >= tl.length) then
				endNight()
			end
		end
	end
end

-- Studio debug: play another night now, with the guards already on shift (or everyone)
function NightService.restart(night: number)
	if not Config.nightByNumber[night] then
		return
	end
	local guards = {}
	for player in playing do
		table.insert(guards, player)
	end
	if #guards == 0 then
		guards = Players:GetPlayers()
	end
	running = false
	PowerDirector.stop()
	NightService.launch(guards, night)
end

return NightService
