--!strict
-- The co-op after a death (plan section 3, "Coop de 1 à 4"): a guard taken while others are still on shift wakes up
-- in the security booth as a watcher. They look through the cameras (the client's Watcher view, where the Unseen is
-- never seen) and may turn one camera at a time toward a teammate, within camera_turn_max (WatchService recomputes
-- its field). Their badge lies where they were taken: a teammate who holds a syringe over it for revive_seconds brings
-- them back there (Adrien, 8 Nov: "un teammate peut te revive mais ça prend du temps, avec une seringue"). Each guard
-- has the mode's syringes for the night (EASY 3, NORMAL 2, HARD 1, NIGHTMARE 0). NightService decides who is down;
-- this keeps the badges, the syringes and the watchers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local WatchService = require(script.Parent:WaitForChild("WatchService"))

local C = Config.C

local CoopService = {}

-- NightService sets these
CoopService.isPlaying = nil :: ((player: Player) -> boolean)?
CoopService.onRevive = nil :: ((player: Player, at: Vector3) -> ())?

type Badge = { owner: Player, part: BasePart, carrier: Player? }

local badges: { [Player]: Badge } = {} -- owner -> their badge on the floor or in someone's hand
local syringes: { [Player]: number } = {} -- each guard's syringes left tonight
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

-- the syringes, to each guard (and whether a teammate can still bring someone back)
local function sendSyringes()
	for player, n in syringes do
		if player.Parent then
			Net.event():FireClient(player, "Syringes", n)
		end
	end
end

local function anyLeft(except: Player?): boolean
	for player, n in syringes do
		if player ~= except and n > 0 and playing(player) then
			return true
		end
	end
	return false
end

local function refreshPrompts()
	for _, b in badges do
		local prompt = b.part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = anyLeft(b.owner)
		end
	end
end

-- a new shift: every guard's syringes for the night (the mode); none in a solo shift
function CoopService.giveSyringes(guards: { Player }, count: number)
	table.clear(syringes)
	for _, player in guards do
		syringes[player] = if #guards > 1 then count else 0
	end
	if #guards > 1 then
		sendSyringes()
	end
end

-- A guard is down: they become a watcher; their badge drops where they were taken, and a teammate's syringe can bring
-- them back there.
function CoopService.down(player: Player, at: Vector3)
	watching[player] = nil
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
	prompt.ActionText = "Revive (syringe)"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = C.revive_seconds
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	part.Parent = badgeFolder()
	local badge: Badge = { owner = player, part = part, carrier = nil }
	badges[player] = badge
	prompt.Triggered:Connect(function(medic)
		if medic == player or not playing(medic) or badges[player] ~= badge then
			return
		end
		if (syringes[medic] or 0) <= 0 then
			notify(medic, "NO SYRINGE LEFT")
			return
		end
		syringes[medic] -= 1
		local where = part.Position
		removeBadge(player)
		CoopService.watcherLeft(player)
		sendSyringes()
		refreshPrompts()
		broadcast()
		if player.Parent and CoopService.onRevive then
			CoopService.onRevive(player, where)
		end
		notify(medic, string.upper(player.DisplayName) .. " IS BACK ON SHIFT", true)
	end)
	prompt.Enabled = anyLeft(player)
	Net.event():FireClient(player, "Down", { badge = anyLeft(player) })
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
	table.clear(syringes)
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
	-- the sign-in book no longer signs anyone back in (the syringes do): its prompt stays off
	local root = World.root :: Model
	local spot = (root:WaitForChild("Spots") :: Folder):WaitForChild("SignIn")
	local prompt = spot:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Enabled = false
	end
end

return CoopService
