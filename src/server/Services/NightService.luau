--!strict
-- The night (plan section 3). A shift starts when a lift leaves the lobby with its guards (LobbyService.launch): they
-- arrive in the P3's security booth, the power cycle runs to 6 h, the night's tasks (TaskService) are drawn, and at
-- 6 AM everyone is paid and goes back up to the lobby. Phase 0 plays Config.C.night_test.
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
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local TaskService = require(script.Parent:WaitForChild("TaskService"))

local C = Config.C

local NightService = {}

local dead: { [Player]: boolean } = {}
local playing: { [Player]: boolean } = {} -- the guards on this shift
local deaths = 0
local diedThisShift: { [Player]: boolean } = {}
local running = false
local shift = 0 -- counts shifts, so a late return to the lobby never touches the next one
local nightNumber = C.night_test

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
	diedThisShift[player] = true
	CamcorderService.block(player, true)
	TaskService.drop(player)
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

local function endNight()
	if not running then
		return
	end
	running = false
	PowerDirector.stop()
	local n, total, taskPay = TaskService.summary()
	TaskService.clear()
	local guards = {}
	for player in playing do
		table.insert(guards, player)
	end
	for _, player in guards do
		-- the night's pay (plan section 3): the shift, the team's tasks, and a bonus for never being caught
		local pay = C.pay_shift + taskPay + (if diedThisShift[player] then 0 else C.pay_no_death)
		Data.addPay(player, pay)
		local profile = Data.get(player)
		if profile then
			profile.nights += 1
			if diedThisShift[player] then
				profile.deaths += 1
			end
		end
		Net.event()
			:FireClient(
				player,
				"NightEnd",
				{ night = nightNumber, tasks = n, total = total, deaths = deaths, pay = pay }
			)
	end
	print(`[NightService] night {nightNumber} ended: {n}/{total} tasks, {deaths} deaths`)
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
	table.clear(playing)
	table.clear(dead)
	table.clear(diedThisShift)
	deaths = 0
	running = true
	shift += 1
	local seed = os.time()
	TaskService.reset(seed)
	for k, player in guards do
		playing[player] = true
		-- side by side in the booth
		moveTo(player, World.spawnCFrame() * CFrame.new((k - 2.5) * 1.6, 0, 0))
		Net.event():FireClient(player, "Shift", true)
	end
	CamcorderService.reset()
	PowerDirector.startNight(nightNumber, seed)
	print(`[NightService] night {nightNumber} started with {#guards} guard(s)`)
	return true
end

function NightService.init()
	UnseenService.onKill = NightService.kill
	UnseenService.isPlaying = NightService.isPlaying
	TaskService.isPlaying = NightService.isPlaying

	Actions.on("Ready", function(player: Player)
		PowerDirector.broadcast(player)
		TaskService.send(player)
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

function NightService.start()
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
