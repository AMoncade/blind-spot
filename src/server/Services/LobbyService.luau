--!strict
-- The lobby's service lifts (plan section 3, "Coop de 1 à 4"): platforms for 1 to 4 guards. A guard who walks into an
-- empty lift gets the shift setup (PLAY's screen); START there takes that lift; others join its group (up to its
-- size). A countdown runs; the group's leader (the first guard in) may press GO to leave now, anyone may LEAVE. At
-- zero the doors close and the group goes down; alone on it, a solo night. QUICK PLAY (lifts.csv quick) gathers
-- strangers: anyone walks in, quick_countdown from the first, up to 4, NORMAL, the group's lowest unlocked night.
-- Where the night plays (Config.Places, Adrien, 8 Nov: "un lobby de 20, des nuits de 4"): from the lobby place, the
-- group is teleported to a reserved Night server of its own (Services/LaunchService; to check on the published game,
-- teleports can't be proven in Studio). With no Night place yet, and in Studio, the shift plays in this server, one
-- at a time: while it runs, the lifts show SHIFT IN PROGRESS and stay closed.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local NightService = require(script.Parent:WaitForChild("NightService"))
local LaunchService = require(script.Parent:WaitForChild("LaunchService"))
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local Difficulty = require(Shared:WaitForChild("Logic"):WaitForChild("Difficulty"))

local C = Config.C

local LobbyService = {}

type Door = { part: BasePart, closed: CFrame, open: CFrame }

type Lift = {
	id: string,
	label: string,
	model: Model,
	zone: BasePart,
	status: TextLabel?,
	doors: { Door },
	guards: { Player }, -- in the order they stepped in
	solo: Player?, -- SOLO: this lift is one guard's, it leaves at once
	night: number, -- the night this lift goes down to: its first guard picks it (up to their unlocked night)
	size: number, -- how many guards it waits for (the shift setup; lift_capacity for guards walking in)
	lives: number, -- the team's lives (the shift setup)
	mode: string, -- the shift's mode (content/modes.csv)
	quick: boolean, -- QUICK PLAY: strangers gather, no setup
	deadline: number?, -- os.clock() when the doors close
	state: "open" | "leaving" | "closed",
}

local lifts: { Lift } = {}
-- a guard who walked into an empty lift: the shift setup was opened for them (Adrien, 8 Nov: the lift shows the PLAY
-- menu); once per visit, until they step out of every lift
local asked: { [Player]: string } = {}

local function inside(zone: BasePart, position: Vector3): boolean
	local p = zone.CFrame:PointToObjectSpace(position)
	local h = zone.Size / 2
	return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function setDoors(lift: Lift, open: boolean)
	for _, d in lift.doors do
		TweenService:Create(
			d.part,
			TweenInfo.new(C.lift_door_seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ CFrame = if open then d.open else d.closed }
		):Play()
	end
end

-- The doors of a lift: every part named DoorL or DoorR. The Blender import welds them to the model; they are freed
-- and anchored here so they can slide. They are modelled closed; open slides each one outward along the lift's x.
local function collectDoors(model: Model): { Door }
	local doors = {}
	local right = model:GetPivot().RightVector
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "DoorL" or d.Name == "DoorR") then
			for _, j in d:GetJoints() do
				if j:IsA("WeldConstraint") or j:IsA("Weld") then
					j:Destroy()
				end
			end
			d.Anchored = true
			local side = if d.Name == "DoorL" then -1 else 1
			table.insert(doors, { part = d, closed = d.CFrame, open = d.CFrame + right * side * C.lift_door_travel })
		end
	end
	return doors
end

local function display(lift: Lift, text: string)
	if lift.status and lift.status.Text ~= text then
		lift.status.Text = text
	end
end

local function sendLift(player: Player, lift: Lift?)
	if lift then
		local left = if lift.deadline then math.max(0, lift.deadline - os.clock()) else C.lift_countdown
		local night = Config.nightByNumber[lift.night]
		local owner = lift.guards[1]
		Net.event():FireClient(player, "Lift", {
			id = lift.id,
			label = lift.label,
			night = lift.night,
			nightName = night.name,
			lives = lift.lives,
			multiplier = Difficulty.payMultiplier(
				{ night = lift.night, guards = lift.size, lives = lift.lives, mode = lift.mode },
				Config.nightByNumber,
				C,
				Config.modeById
			),
			owner = owner == player,
			maxNight = if owner then Data.unlockedNight(owner) else 1,
			count = #lift.guards,
			capacity = lift.size,
			closesAt = workspace:GetServerTimeNow() + left,
			leaving = lift.state ~= "open",
		})
	else
		Net.event():FireClient(player, "Lift", nil)
	end
end

local function liftOf(player: Player): Lift?
	for _, lift in lifts do
		if table.find(lift.guards, player) then
			return lift
		end
	end
	return nil
end

local function remove(lift: Lift, player: Player)
	local k = table.find(lift.guards, player)
	if k then
		table.remove(lift.guards, k)
		if player.Parent then
			sendLift(player, nil)
		end
	end
	if #lift.guards == 0 then
		lift.deadline = nil
		lift.solo = nil
	end
	for _, other in lift.guards do
		sendLift(other, lift)
	end
end

-- step a guard back out of the cabin, into the hall
local function stepOut(lift: Lift, player: Player)
	local root = rootOf(player)
	if root then
		local front = lift.zone.CFrame * CFrame.new(0, 0, lift.zone.Size.Z / 2 + 4)
		root.CFrame = CFrame.new(front.Position.X, root.Position.Y, front.Position.Z)
	end
end

local function launch(lift: Lift)
	local guards = table.clone(lift.guards)
	lift.state = "leaving"
	setDoors(lift, false)
	for _, player in guards do
		sendLift(player, lift)
		Net.event():FireClient(player, "LiftDown", C.lift_door_seconds + C.lift_ride_seconds)
	end
	task.wait(C.lift_door_seconds + C.lift_ride_seconds)
	local stillHere = {}
	for _, player in guards do
		if player.Parent then
			table.insert(stillHere, player)
		end
	end
	table.clear(lift.guards)
	lift.deadline = nil
	lift.solo = nil
	local setup = {
		lives = lift.lives,
		mode = lift.mode,
		multiplier = Difficulty.payMultiplier(
			{ night = lift.night, guards = lift.size, lives = lift.lives, mode = lift.mode },
			Config.nightByNumber,
			C,
			Config.modeById
		),
	}
	if #stillHere > 0 then
		-- QUICK PLAY: the group's lowest unlocked night, NORMAL
		local night = lift.night
		if lift.quick then
			for _, player in stillHere do
				night = math.min(night, Data.unlockedNight(player))
			end
		end
		local leader = if table.find(stillHere, guards[1]) then guards[1] else stillHere[1]
		-- from the lobby place: the group's own Night server; otherwise (no Night place yet, Studio) here
		local sent = Config.Places.current() == "lobby" and LaunchService.toNight(stillHere, leader, night, setup.mode)
		if not sent then
			NightService.launch(stillHere, night, setup)
		end
	end
	for _, player in stillHere do
		sendLift(player, nil)
	end
	lift.state = "closed"
end

local function scan()
	local shiftRunning = NightService.running() and Config.Places.current() ~= "lobby"
	-- out of every lift: the setup opens again on the next visit
	for player, id in asked do
		local root = rootOf(player)
		local still = false
		for _, lift in lifts do
			if lift.id == id and root and inside(lift.zone, root.Position) then
				still = true
			end
		end
		if not still then
			asked[player] = nil
		end
	end
	for _, lift in lifts do
		if lift.state == "leaving" then
			display(lift, "GOING DOWN")
			continue
		end
		-- doors: closed while a shift runs in this place, open otherwise
		local wantOpen = not shiftRunning
		if wantOpen and lift.state == "closed" then
			lift.state = "open"
			setDoors(lift, true)
		elseif not wantOpen and lift.state == "open" then
			for _, player in table.clone(lift.guards) do
				remove(lift, player)
				stepOut(lift, player)
			end
			lift.state = "closed"
			setDoors(lift, false)
		end
		if lift.state == "closed" then
			display(lift, "SHIFT IN PROGRESS")
			continue
		end

		-- who is inside now
		for _, player in table.clone(lift.guards) do
			local root = rootOf(player)
			if not root or not inside(lift.zone, root.Position) then
				remove(lift, player)
			end
		end
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if
				root
				and not liftOf(player)
				and not NightService.isPlaying(player)
				and inside(lift.zone, root.Position)
			then
				if #lift.guards == 0 and not lift.quick then
					-- an empty lift: the shift setup opens; START on it takes this lift (play)
					if asked[player] ~= lift.id then
						asked[player] = lift.id
						Net.event():FireClient(player, "OpenSetup")
					end
				elseif #lift.guards >= lift.size or (lift.solo and lift.solo ~= player) then
					stepOut(lift, player) -- full, or one guard's SOLO lift
				else
					table.insert(lift.guards, player)
					if #lift.guards == 1 then
						-- walked in: the first guard's furthest night, a full lift, the default lives
						lift.night = Data.unlockedNight(player)
						lift.size = C.lift_capacity
						lift.lives = C.shift_lives
						lift.mode = if lift.quick then C.quick_mode else C.mode_default
					end
					if not lift.deadline then
						lift.deadline = os.clock() + (if lift.quick then C.quick_countdown else C.lift_countdown)
					end
					for _, p in lift.guards do
						sendLift(p, lift)
					end
				end
			end
		end

		if lift.deadline then
			local left = math.max(0, math.ceil(lift.deadline - os.clock()))
			display(lift, `NIGHT {lift.night}  ·  {#lift.guards}/{lift.size}  ·  {left}`)
			if os.clock() >= lift.deadline then
				task.spawn(launch, lift)
			end
		else
			display(lift, `{C.lift_floor}  ·  0/{C.lift_capacity}`)
		end
	end
end

-- START on the shift setup (Logic/Difficulty): one guard takes an empty lift that leaves at once; a group joins an
-- open lift set up the same way (night, guards, lives) with room left, or an empty one it sets up. The lift leaves
-- when it is full, or at the end of its countdown.
local function play(player: Player, setup: Difficulty.Setup)
	if liftOf(player) or NightService.isPlaying(player) then
		return
	end
	local solo = setup.guards <= 1
	local best: Lift? = nil
	for _, lift in lifts do
		if lift.state == "open" and not lift.solo and not lift.quick then
			local same = #lift.guards > 0
				and lift.night == setup.night
				and lift.size == setup.guards
				and lift.lives == setup.lives
				and lift.mode == setup.mode
				and #lift.guards < lift.size
			if not solo and same and (not best or #best.guards == 0 or #lift.guards > #best.guards) then
				best = lift
			elseif #lift.guards == 0 and (not best or (solo and #best.guards > 0)) then
				best = best or lift
			end
		end
	end
	local root = rootOf(player)
	-- standing in a lift (it opened the setup): that one, if it is empty or set up the same way with room
	if root then
		for _, lift in lifts do
			if lift.state == "open" and not lift.solo and not lift.quick and inside(lift.zone, root.Position) then
				local fits = #lift.guards == 0
					or (
						not solo
						and lift.night == setup.night
						and lift.size == setup.guards
						and lift.lives == setup.lives
						and lift.mode == setup.mode
						and #lift.guards < lift.size
					)
				if fits then
					best = lift
				end
			end
		end
	end
	if not best or not root then
		Net.event():FireClient(player, "Notice", "ALL LIFTS ARE BUSY", false)
		return
	end
	local lift = best :: Lift
	if #lift.guards == 0 then
		lift.night, lift.size, lift.lives, lift.mode = setup.night, setup.guards, setup.lives, setup.mode
	end
	if solo then
		lift.solo = player
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.new(lift.zone.Position.X, root.Position.Y, lift.zone.Position.Z - 1)

	table.insert(lift.guards, player)
	-- alone, or the group is complete: the doors close now
	local full = solo or #lift.guards >= lift.size
	local closeAt = os.clock() + (if full then C.lift_start_now else C.lift_countdown)
	lift.deadline = if lift.deadline then math.min(lift.deadline, closeAt) else closeAt
	for _, p in lift.guards do
		sendLift(p, lift)
	end
end

function LobbyService.init()
	Actions.on("Play", function(player: Player, raw: unknown)
		-- the shift setup (old clients: "group" or "solo")
		local maxNight = Data.unlockedNight(player)
		if raw == "solo" or raw == "group" then
			raw = { night = maxNight, guards = if raw == "solo" then 1 else C.lift_capacity, lives = C.shift_lives }
		end
		local setup = Difficulty.clean(raw, maxNight, C, Config.modeById)
		if setup then
			play(player, setup)
		end
	end)
	Actions.on("Lift", function(player: Player, command: unknown)
		local lift = liftOf(player)
		if not lift or lift.state ~= "open" then
			return
		end
		if command == "start" and lift.guards[1] == player then
			-- GO: only the group's leader (the first guard in)
			local soon = os.clock() + C.lift_start_now
			if lift.deadline and lift.deadline > soon then
				lift.deadline = soon
				for _, p in lift.guards do
					sendLift(p, lift)
				end
			end
		elseif (command == "nightUp" or command == "nightDown") and lift.guards[1] == player then
			-- only the lift's first guard picks the night, between 1 and their unlocked one
			local step = if command == "nightUp" then 1 else -1
			lift.night = math.clamp(lift.night + step, 1, Data.unlockedNight(player))
			for _, p in lift.guards do
				sendLift(p, lift)
			end
		elseif command == "leave" then
			remove(lift, player)
			stepOut(lift, player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		asked[player] = nil
		local lift = liftOf(player)
		if lift then
			remove(lift, player)
		end
	end)
end

function LobbyService.start()
	local root = World.lobby
	if not root then
		warn("[LobbyService] no lobby")
		return
	end
	for _, model in (root:WaitForChild("Lifts") :: Folder):GetChildren() do
		if model:IsA("Model") then
			local zone = model:FindFirstChild("Zone") :: BasePart
			local sign = model:FindFirstChild("Display")
			local gui = sign and sign:FindFirstChild("Sign")
			local status = gui and gui:FindFirstChild("Line2")
			local elevator = model:FindFirstChild("Elevator") :: Model
			local lift: Lift = {
				id = model.Name,
				label = model:GetAttribute("Label") or model.Name,
				model = model,
				zone = zone,
				status = if status and status:IsA("TextLabel") then status else nil,
				doors = if elevator then collectDoors(elevator) else {},
				guards = {},
				solo = nil,
				night = 1,
				size = C.lift_capacity,
				lives = C.shift_lives,
				mode = C.mode_default,
				quick = model:GetAttribute("Quick") == true,
				deadline = nil,
				state = "closed", -- the first scan opens them
			}
			table.insert(lifts, lift)
		end
	end
	table.sort(lifts, function(a, b)
		return a.id < b.id
	end)
	while true do
		task.wait(C.lobby_scan)
		local ok, err = pcall(scan)
		if not ok then
			warn("[LobbyService] " .. tostring(err))
		end
	end
end

return LobbyService
