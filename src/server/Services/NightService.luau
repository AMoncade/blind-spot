--!strict
-- The night (plan section 3). A shift starts when a lift leaves the lobby with its guards (LobbyService.launch): they
-- arrive in the P3's security booth, the power cycle runs to 6 h, the night's tasks (TaskService) are drawn, and at
-- 6 AM everyone is paid and goes back up to the lobby. The night is cleared when the round is done by 6 AM:
-- that unlocks the next one (Data.unlockedNight).
-- A death (plan section 4, "La mort"): the guard freezes, the client plays the tape tear for death_seconds, then they
-- wake up in the booth and the night goes on.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local Analytics = require(Server:WaitForChild("Core"):WaitForChild("Analytics"))
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local PowerDirector = require(script.Parent:WaitForChild("PowerDirector"))
local UnseenService = require(script.Parent:WaitForChild("UnseenService"))
local WatchService = require(script.Parent:WaitForChild("WatchService"))
local CamcorderService = require(script.Parent:WaitForChild("CamcorderService"))
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local TaskService = require(script.Parent:WaitForChild("TaskService"))
local DoorService = require(script.Parent:WaitForChild("DoorService"))
local StairsService = require(script.Parent:WaitForChild("StairsService"))
local SignalService = require(script.Parent:WaitForChild("SignalService"))
local SkillService = require(script.Parent:WaitForChild("SkillService"))
local UpgradeService = require(script.Parent:WaitForChild("UpgradeService"))
local CoopService = require(script.Parent:WaitForChild("CoopService"))
local StoryService = require(script.Parent:WaitForChild("StoryService"))

local C = Config.C

local NightService = {}

local dead: { [Player]: boolean } = {}
local playing: { [Player]: boolean } = {} -- the guards on this shift
local deaths = 0
local diedThisShift: { [Player]: boolean } = {}
local down: { [Player]: boolean } = {} -- co-op: taken, watching from the booth until a teammate brings their badge back
local solo = true -- one guard on this shift
local lives = 0 -- the team's catches left tonight (the shift setup: 1 to 3)
local maxLives = 0
local payMultiplier = 1 -- the shift setup's reward (Logic/Difficulty)
local running = false
local shift = 0 -- counts shifts, so a late return to the lobby never touches the next one
local nightNumber = C.night_test
local startedAt = 0 -- os.clock() at the shift's start (analytics: the night's length)

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

-- on tonight's shift, alive, dead for a moment or down and watching (the coop signals reach all of them)
function NightService.onShift(player: Player): boolean
	return running and playing[player] == true
end

-- on this shift and not frozen in a death (the Unseen only sees these guards)
function NightService.isPlaying(player: Player): boolean
	return running and playing[player] == true and not dead[player] and not down[player]
end

-- the shift's squad on every guard's HUD: solo lives, or how many guards are still up
local function sendSquad()
	local up, total, names = 0, 0, {}
	for player in playing do
		total += 1
		if not down[player] and not dead[player] then
			up += 1
		else
			table.insert(names, string.upper(player.DisplayName))
		end
	end
	for player in playing do
		Net.event():FireClient(
			player,
			"Squad",
			{ solo = solo, lives = lives, maxLives = maxLives, up = up, total = total, down = names }
		)
	end
end

local function upCount(): number
	local n = 0
	for player in playing do
		if not down[player] then
			n += 1
		end
	end
	return n
end

function NightService.running(): boolean
	return running
end

-- defined below; kill and the departures need it first
local endNight: (outcome: string) -> ()

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
	do
		local t = PowerDirector.now() or 0
		Analytics.event(player, "GuardCaught", math.floor(t), {
			"N" .. nightNumber,
			(Config.floorAt(root.Position.X)),
			PowerDirector.phase() or "LIVE",
		})
	end
	CamcorderService.block(player, true)
	TaskService.drop(player)
	local at = root.Position
	CoopService.drop(player, at)
	root.Anchored = true
	-- one of the team's lives (the shift setup); the last one ends a solo night, or downs a co-op guard
	lives = math.max(0, lives - 1)
	-- where he is: the catch turns the guard's view to him (Controllers/Death)
	local _, ux, uz = UnseenService.position()
	Net.event():FireClient(player, "Death", C.death_seconds, ux, uz)
	StoryService.trigger("death")
	sendSquad()
	local thisShift = shift
	task.delay(C.death_seconds, function()
		if shift ~= thisShift or not running then
			return
		end
		dead[player] = nil
		if solo and lives <= 0 then
			endNight("lost")
			return
		end
		if player.Parent and root.Parent then
			root.CFrame = World.spawnCFrame()
		end
		if lives > 0 then
			-- a life left: back at the post, one life less (plan section 3: the night goes on)
			if root.Parent then
				root.Anchored = false
			end
			CamcorderService.block(player, false)
			Net.event():FireClient(player, "Respawn")
		else
			-- co-op: a watcher in the booth until someone brings the badge back
			down[player] = true
			CoopService.down(player, at)
			if upCount() == 0 then
				endNight("lost")
				return
			end
		end
		sendSquad()
	end)
end

-- outcome: "cleared" (the round was done by 6 AM), "unfinished" (6 AM, tasks left), "lost" (every guard is out)
function endNight(outcome: string)
	if not running then
		return
	end
	running = false
	PowerDirector.stop()
	local n, total, taskPay = TaskService.summary()
	TaskService.clear()
	DoorService.reset()
	SkillService.clear()
	CoopService.reset()
	StoryService.finish(outcome)
	-- every guard stands up again in the booth for the report
	for player in playing do
		local root = rootOf(player)
		if root then
			root.Anchored = false
		end
		CamcorderService.block(player, false)
	end
	table.clear(down)
	local night = Config.nightByNumber[nightNumber]
	local guards = {}
	for player in playing do
		table.insert(guards, player)
	end
	for _, player in guards do
		-- the night's pay (plan section 3): the shift, the team's tasks, and a bonus for never being caught
		local pay = taskPay
		if outcome ~= "lost" then
			pay += C.pay_shift + (if diedThisShift[player] then 0 else C.pay_no_death)
		end
		if outcome == "cleared" then
			pay += C.pay_clear
		end
		pay = math.floor(pay * payMultiplier + 0.5)
		Data.addPay(player, pay)
		local profile = Data.get(player)
		Analytics.event(player, "NightEnded", math.floor(os.clock() - startedAt), { "N" .. nightNumber, outcome })
		if profile then
			Analytics.pay(
				player,
				pay,
				profile.pay,
				Enum.AnalyticsEconomyTransactionType.Gameplay,
				"night" .. nightNumber
			)
			if profile.nights == 0 then
				Analytics.onboarding(player, 3)
			end
			if nightNumber == 1 and outcome == "cleared" and profile.bestNight < 1 then
				Analytics.onboarding(player, 4)
			end
			profile.nights += 1
			if outcome == "cleared" then
				profile.bestNight = math.max(profile.bestNight, nightNumber)
			end
			if diedThisShift[player] then
				profile.deaths += 1
			end
		end
		Net.event():FireClient(player, "NightEnd", {
			night = nightNumber,
			name = night.name,
			outcome = outcome,
			tasks = n,
			total = total,
			deaths = deaths,
			pay = pay,
			multiplier = payMultiplier,
			unlocked = Data.unlockedNight(player),
		})
	end
	print(`[NightService] night {nightNumber} ended ({outcome}): {n}/{total} tasks, {deaths} deaths`)
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
-- setup: the lives and the reward the lift's guards chose in the lobby (Logic/Difficulty); nil: the defaults
function NightService.launch(
	guards: { Player },
	night: number?,
	setup: { lives: number, multiplier: number, mode: string? }?
): boolean
	if running then
		return false
	end
	nightNumber = if night and Config.nightByNumber[night] then night else C.night_test
	local def = Config.nightByNumber[nightNumber]
	-- more guards: more checkpoints and a faster Unseen (plan section 3, "Coop de 1 à 4")
	local extraGuards = math.max(#guards - 1, 0)
	UnseenService.speedScale = def.unseenSpeed * (1 + extraGuards * C.coop_speed_per_guard)
	-- the mode (content/modes.csv; Adrien, 8 Nov: "c'est relativement pas challengeant ... un mode facile, moins de
	-- caméras"): dead cameras on top of the night's, shorter camera fields, a faster bar, darker tubes, his smashes
	local mode = Config.modeById[setup and setup.mode or C.mode_default] or Config.modeById[C.mode_default]
	UnseenService.drainScale = mode.drain
	UnseenService.smashes = mode.smashes + math.floor((nightNumber - 1) / 2)
	workspace:SetAttribute("Mode", mode.id)
	workspace:SetAttribute("CamRange", mode.camRange)
	UnseenService.newNight()
	table.clear(playing)
	table.clear(dead)
	table.clear(down)
	table.clear(diedThisShift)
	CoopService.reset()
	deaths = 0
	running = true
	shift += 1
	local seed = os.time()
	DoorService.reset()
	-- the cameras' fields at the mode's range (computed once per range, then cached)
	WatchService.setRangeScale(mode.camRange)
	TaskService.reset(
		seed,
		def.extraScans + extraGuards * C.coop_scan_per_guard,
		def.cables,
		def.length,
		nightNumber,
		mode.deadCams
	)
	solo = #guards <= 1
	lives = if setup then setup.lives else C.shift_lives
	maxLives = lives
	payMultiplier = if setup then setup.multiplier else 1
	startedAt = os.clock()
	for k, player in guards do
		playing[player] = true
		Analytics.event(
			player,
			"NightStarted",
			nightNumber,
			{ "N" .. nightNumber, if #guards > 1 then "coop" else "solo" }
		)
		local profile = Data.get(player)
		if profile and profile.nights == 0 then
			Analytics.onboarding(player, 2)
		end
		-- side by side in the booth
		moveTo(player, World.spawnCFrame() * CFrame.new((k - 2.5) * 1.6, 0, 0))
		Net.event():FireClient(player, "Shift", true)
	end
	CamcorderService.reset()
	SkillService.reset(guards)
	PowerDirector.startNight(nightNumber, seed)
	StoryService.begin(nightNumber, seed)
	sendSquad()
	print(`[NightService] night {nightNumber} started with {#guards} guard(s)`)
	return true
end

function NightService.init()
	UnseenService.onKill = NightService.kill
	UnseenService.isPlaying = NightService.isPlaying
	TaskService.isPlaying = NightService.isPlaying
	DoorService.isPlaying = NightService.isPlaying
	StairsService.isPlaying = NightService.isPlaying
	SignalService.onShift = NightService.onShift
	SkillService.isPlaying = NightService.isPlaying
	UpgradeService.onShift = NightService.onShift
	StairsService.onTake = function()
		StoryService.trigger("first_floor") -- once a night: the first time a guard leaves their floor
	end
	SignalService.isPlaying = NightService.isPlaying
	-- a task done: the radio answers the ones it has a line for (night 5: the plaster, the sealed room)
	TaskService.onDone = function(taskId: string)
		StoryService.trigger(taskId)
		if TaskService.allDone() then
			for player in playing do
				Net.event():FireClient(player, "Notice", "ROUND DONE · CLOCK OUT AT THE POST (P1)", true)
			end
		end
	end
	UnseenService.onSmash = function(cameraId: string)
		TaskService.smash(cameraId)
		Net.event():FireAllClients("Smash", cameraId)
	end
	TaskService.onNew = function(taskId: string)
		StoryService.trigger("new:" .. taskId)
	end
	CoopService.isPlaying = NightService.isPlaying
	StoryService.guards = function(): { Player }
		local out = {}
		for player in playing do
			table.insert(out, player)
		end
		table.sort(out, function(a, b)
			return a.UserId < b.UserId
		end)
		return out
	end
	TaskService.onCut = function()
		StoryService.trigger("first_cut")
	end
	CoopService.isDown = function(player: Player): boolean
		return down[player] == true
	end
	CoopService.onRevive = function(player: Player)
		-- brought back by their badge: on their feet in the booth
		down[player] = nil
		local root = rootOf(player)
		if root then
			root.CFrame = World.spawnCFrame()
			root.Anchored = false
		end
		CamcorderService.block(player, false)
		Net.event():FireClient(player, "Respawn")
		sendSquad()
	end

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
		if running and playing[player] then
			Analytics.event(player, "QuitDuringShift", math.floor(PowerDirector.now() or 0), { "N" .. nightNumber })
		end
		dead[player] = nil
		down[player] = nil
		playing[player] = nil
		if running then
			sendSquad()
			if next(playing) and upCount() == 0 then
				endNight("lost")
			end
		end
	end)
end

function NightService.start()
	while true do
		task.wait(0.5)
		if running then
			local t, _, tl = PowerDirector.now()
			if not next(playing) then
				endNight("lost")
			elseif tl and t >= tl.length then
				endNight(if TaskService.allDone() then "cleared" else "unfinished")
			elseif TaskService.allDone() then
				-- the round is done: a guard back at the post clocks the team out (Adrien, 8 Nov: after the last task
				-- there was nothing left to do)
				local post = Config.spotById.SignIn
				for player in playing do
					local root = rootOf(player)
					if root and post and not dead[player] and not down[player] then
						local d = Vector3.new(post.x - root.Position.X, 0, post.z - root.Position.Z).Magnitude
						if d <= C.clockout_radius then
							endNight("cleared")
							break
						end
					end
				end
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
