--!strict
-- The co-op after a death (plan section 3, "Coop de 1 à 4"): a guard taken while others are still on shift wakes up
-- in the security booth as a watcher. They look through the cameras (the client's Watcher view, where the Unseen is
-- never seen) and may turn one camera at a time toward a teammate, within camera_turn_max (WatchService recomputes
-- its field). Their badge lies where they were taken: a teammate who brings it to the booth's sign-in book brings
-- them back, once per night per guard. NightService decides who is down; this keeps the badges and the watchers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local WatchService = require(script.Parent:WaitForChild("WatchService"))
local TaskService = require(script.Parent:WaitForChild("TaskService"))

local C = Config.C

local CoopService = {}

-- NightService sets these
CoopService.isPlaying = nil :: ((player: Player) -> boolean)?
CoopService.onRevive = nil :: ((player: Player) -> ())?

type Badge = { owner: Player, part: BasePart, carrier: Player? }

local badges: { [Player]: Badge } = {} -- owner -> their badge on the floor or in someone's hand
local revived: { [Player]: boolean } = {} -- already brought back once tonight
local watching: { [Player]: string } = {} -- watcher -> the camera they turn

local function playing(player: Player): boolean
	return CoopService.isPlaying ~= nil and CoopService.isPlaying(player)
end

local function notify(player: Player, text: string, good: boolean?)
	Net.event():FireClient(player, "Notice", text, good == true)
end

local function carried(player: Player): Badge?
	for _, b in badges do
		if b.carrier == player then
			return b
		end
	end
	return nil
end

local function broadcast()
	local list = {}
	for owner, b in badges do
		local p = b.part.Position
		table.insert(list, {
			id = owner.UserId,
			name = string.upper(owner.DisplayName),
			pos = { p.X, p.Y, p.Z },
			carriedBy = if b.carrier then b.carrier.UserId else nil,
		})
	end
	Net.event():FireAllClients("Badges", list)
end

local function badgeFolder(): Folder
	local root = World.root :: Model
	local f = root:FindFirstChild("Badges")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Badges"
		f.Parent = root
	end
	return f :: Folder
end

local function removeBadge(owner: Player)
	local b = badges[owner]
	if b then
		b.part:Destroy()
		badges[owner] = nil
	end
end

-- A guard is down: they become a watcher; their badge drops where they were taken, unless they were already brought
-- back tonight (then they watch until 6 AM).
function CoopService.down(player: Player, at: Vector3)
	watching[player] = nil
	if revived[player] then
		Net.event():FireClient(player, "Down", { badge = false })
		broadcast()
		return
	end
	removeBadge(player)
	local part = Instance.new("Part")
	part.Name = "Badge_" .. player.UserId
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Size = Vector3.new(0.7, 0.06, 0.9)
	part.Color = Color3.fromRGB(Config.rgb(C.badge_color))
	part.Material = Enum.Material.Metal
	part.CFrame = CFrame.new(at.X, C.floor_y + 0.05, at.Z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	local glow = Instance.new("PointLight")
	glow.Color = part.Color
	glow.Range = 5
	glow.Brightness = 0.8
	glow.Parent = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take badge"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = C.pickup_hold
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	part.Parent = badgeFolder()
	local badge: Badge = { owner = player, part = part, carrier = nil }
	badges[player] = badge
	prompt.Triggered:Connect(function(taker)
		if not playing(taker) or badge.carrier then
			return
		end
		if carried(taker) or TaskService.isCarrying(taker) then
			notify(taker, "YOUR HANDS ARE FULL")
			return
		end
		badge.carrier = taker
		part.Transparency = 1
		prompt.Enabled = false
		glow.Enabled = false
		notify(taker, string.upper(player.DisplayName) .. "'S BADGE TAKEN", true)
		broadcast()
	end)
	Net.event():FireClient(player, "Down", { badge = true })
	broadcast()
end

-- the carrier was taken: the badge lies where they fell
function CoopService.drop(carrier: Player, at: Vector3)
	local b = carried(carrier)
	if b then
		b.carrier = nil
		b.part.Position = Vector3.new(at.X, C.floor_y + 0.05, at.Z)
		b.part.Transparency = 0
		local prompt = b.part:FindFirstChildOfClass("ProximityPrompt")
		local glow = b.part:FindFirstChildOfClass("PointLight")
		if prompt then
			prompt.Enabled = true
		end
		if glow then
			glow.Enabled = true
		end
		broadcast()
	end
end

-- a new shift, or its end: no badge, no watcher, every camera back to its rest aim
function CoopService.reset()
	for owner in badges do
		removeBadge(owner)
	end
	table.clear(revived)
	table.clear(watching)
	WatchService.resetAims()
	broadcast()
end

function CoopService.watcherLeft(player: Player)
	if watching[player] then
		WatchService.setAimOffset(watching[player], 0)
		watching[player] = nil
	end
end

local function signIn(player: Player)
	local b = carried(player)
	if not b then
		notify(player, "BRING A GUARD'S BADGE HERE")
		return
	end
	local owner = b.owner
	removeBadge(owner)
	revived[owner] = true
	CoopService.watcherLeft(owner)
	broadcast()
	if owner.Parent and CoopService.onRevive then
		CoopService.onRevive(owner)
	end
	notify(player, string.upper(owner.DisplayName) .. " IS BACK ON SHIFT", true)
end

function CoopService.init()
	-- a watcher turns the camera they look through (step: -1 or 1, camera_turn_step degrees)
	Actions.on("TurnCamera", function(player: Player, camId: unknown, step: unknown)
		if type(camId) ~= "string" or (step ~= 1 and step ~= -1 and step ~= 0) then
			return
		end
		local cam = Config.cameraById[camId]
		if not cam or cam.always or playing(player) or not CoopService.isDown(player) then
			return
		end
		local previous = watching[player]
		if previous and previous ~= camId then
			WatchService.setAimOffset(previous, 0)
		end
		-- one watcher per camera
		for other, id in watching do
			if other ~= player and id == camId then
				notify(player, "ANOTHER GUARD HOLDS THIS CAMERA")
				return
			end
		end
		watching[player] = camId
		local offset = WatchService.aimOffset(camId) + (step :: number) * math.rad(C.camera_turn_step)
		local limit = math.rad(C.camera_turn_max)
		WatchService.setAimOffset(camId, math.clamp(offset, -limit, limit))
	end)
	Players.PlayerRemoving:Connect(function(player)
		removeBadge(player)
		local b = carried(player)
		if b then
			CoopService.drop(player, b.part.Position)
		end
		CoopService.watcherLeft(player)
		broadcast()
	end)
end

-- NightService tells: down and not yet brought back
CoopService.isDown = function(_player: Player): boolean
	return false
end

function CoopService.start()
	local root = World.root :: Model
	local spot = (root:WaitForChild("Spots") :: Folder):WaitForChild("SignIn")
	local prompt = spot:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.ActionText = "Sign a guard back in"
		prompt.Enabled = true
		prompt.Triggered:Connect(function(player)
			if playing(player) then
				signIn(player)
			end
		end)
	end
end

return CoopService
