--!strict
-- The lobby's service lifts (plan section 3, "Coop de 1 à 4"): a guard who steps into a lift joins its group (up to
-- lift_capacity); a countdown starts; any guard inside may press START to shorten it, or LEAVE to step out. At zero the
-- doors close, the lift goes down and the group starts its shift. The server decides who is inside, from positions.
-- In a published universe with Config.C.game_place_id set, the group is teleported to a reserved game server instead
-- (to check on the published game: teleports can't be proven in Studio). Otherwise the shift plays in this place, one
-- at a time: while it runs, the lifts show SHIFT IN PROGRESS and stay closed.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local NightService = require(script.Parent:WaitForChild("NightService"))

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
	deadline: number?, -- os.clock() when the doors close
	state: "open" | "leaving" | "closed",
}

local lifts: { Lift } = {}

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
		Net.event():FireClient(player, "Lift", {
			id = lift.id,
			label = lift.label,
			count = #lift.guards,
			capacity = C.lift_capacity,
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
	if #stillHere > 0 then
		if C.game_place_id ~= 0 and not RunService:IsStudio() then
			-- to check on the published game: a reserved server of the game place for this group
			local options = Instance.new("TeleportOptions")
			options.ShouldReserveServer = true
			options:SetTeleportData({ night = C.night_test })
			local ok, err = pcall(function()
				TeleportService:TeleportAsync(C.game_place_id, stillHere, options)
			end)
			if not ok then
				warn("[LobbyService] teleport failed: " .. tostring(err))
			end
		else
			NightService.launch(stillHere, C.night_test)
		end
	end
	for _, player in stillHere do
		sendLift(player, nil)
	end
	lift.state = "closed"
end

local function scan()
	local shiftRunning = NightService.running() and C.game_place_id == 0
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
				if #lift.guards >= C.lift_capacity or (lift.solo and lift.solo ~= player) then
					stepOut(lift, player) -- full, or one guard's SOLO lift
				else
					table.insert(lift.guards, player)
					if not lift.deadline then
						lift.deadline = os.clock() + C.lift_countdown
					end
					for _, p in lift.guards do
						sendLift(p, lift)
					end
				end
			end
		end

		if lift.deadline then
			local left = math.max(0, math.ceil(lift.deadline - os.clock()))
			display(lift, `P3  ·  {#lift.guards}/{C.lift_capacity}  ·  {left}`)
			if os.clock() >= lift.deadline then
				task.spawn(launch, lift)
			end
		else
			display(lift, `P3  ·  0/{C.lift_capacity}`)
		end
	end
end

-- PLAY: into the open lift with the most guards (a group forms faster); SOLO: into an empty one that leaves at once.
local function play(player: Player, mode: string)
	if liftOf(player) or NightService.isPlaying(player) then
		return
	end
	local best: Lift? = nil
	for _, lift in lifts do
		if lift.state == "open" and not lift.solo and #lift.guards < C.lift_capacity then
			if mode == "solo" then
				if #lift.guards == 0 then
					best = lift
					break
				end
			elseif not best or #lift.guards > #best.guards then
				best = lift
			end
		end
	end
	local root = rootOf(player)
	if not best or not root then
		Net.event():FireClient(player, "Notice", "ALL LIFTS ARE BUSY", false)
		return
	end
	local lift = best :: Lift
	if mode == "solo" then
		lift.solo = player
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.new(lift.zone.Position.X, root.Position.Y, lift.zone.Position.Z - 1)

	table.insert(lift.guards, player)
	local closeAt = os.clock() + (if mode == "solo" then C.lift_start_now else C.lift_countdown)
	lift.deadline = if lift.deadline then math.min(lift.deadline, closeAt) else closeAt
	for _, p in lift.guards do
		sendLift(p, lift)
	end
end

function LobbyService.init()
	Actions.on("Play", function(player: Player, mode: unknown)
		if mode == "group" or mode == "solo" then
			play(player, mode)
		end
	end)
	Actions.on("Lift", function(player: Player, command: unknown)
		local lift = liftOf(player)
		if not lift or lift.state ~= "open" then
			return
		end
		if command == "start" then
			local soon = os.clock() + C.lift_start_now
			if lift.deadline and lift.deadline > soon then
				lift.deadline = soon
				for _, p in lift.guards do
					sendLift(p, lift)
				end
			end
		elseif command == "leave" then
			remove(lift, player)
			stepOut(lift, player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
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
