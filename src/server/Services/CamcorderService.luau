--!strict
-- The camcorder (plan section 3): what it films is filmed, its battery runs out. The client only says "raised, looking
-- this way"; the server places the view at the player's own head, caps how fast it may turn and runs the battery.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Logic = Shared:WaitForChild("Logic")
local Look = require(Logic:WaitForChild("Look"))
local Watch = require(Logic:WaitForChild("Watch"))

local Server = script.Parent.Parent
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))
local WatchService = require(script.Parent:WaitForChild("WatchService"))

local C = Config.C

local CamcorderService = {}

type State = {
	raised: boolean,
	battery: number,
	yaw: number,
	pitch: number,
	wantYaw: number,
	wantPitch: number,
	lastSentBattery: number,
}

local states: { [Player]: State } = {}
local blocked: { [Player]: boolean } = {} -- dead players can't film

local function state(player: Player): State
	local s = states[player]
	if not s then
		s = {
			raised = false,
			battery = C.camcorder_battery,
			yaw = 0,
			pitch = 0,
			wantYaw = 0,
			wantPitch = 0,
			lastSentBattery = -1,
		}
		states[player] = s
	end
	return s
end

local function sendBattery(player: Player, s: State, force: boolean?)
	local whole = math.ceil(s.battery)
	if force or whole ~= s.lastSentBattery then
		s.lastSentBattery = whole
		Net.event():FireClient(player, "Battery", s.battery, C.camcorder_battery, s.raised)
	end
end

local function lower(player: Player, s: State)
	if s.raised then
		s.raised = false
		WatchService.setCamcorder(player, nil)
		sendBattery(player, s, true)
	end
end

-- a full battery for everyone (a new night)
function CamcorderService.reset()
	for player, s in states do
		lower(player, s)
		s.battery = C.camcorder_battery
		sendBattery(player, s, true)
	end
end

-- a dead player drops their camcorder until they respawn
function CamcorderService.block(player: Player, isBlocked: boolean)
	blocked[player] = if isBlocked then true else nil
	if isBlocked then
		lower(player, state(player))
	end
end

function CamcorderService.init()
	Actions.on("Camcorder", function(player: Player, raised: unknown, yaw: unknown, pitch: unknown)
		if type(raised) ~= "boolean" then
			return
		end
		local s = state(player)
		if not raised then
			lower(player, s)
			return
		end
		local y = Actions.number(yaw, -math.pi * 4, math.pi * 4)
		local p = Actions.number(pitch, -math.pi / 2, math.pi / 2)
		if not y or not p then
			return
		end
		s.wantYaw, s.wantPitch = y, p
		if not s.raised and s.battery > 0 and not blocked[player] then
			s.raised = true
			s.yaw, s.pitch = y, p
			sendBattery(player, s, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		blocked[player] = nil
	end)
end

function CamcorderService.start()
	local step = 1 / C.camcorder_rate
	local maxTurn = math.rad(C.camcorder_max_turn) * step
	while true do
		local dt = task.wait(step)
		for player, s in states do
			if not s.raised then
				continue
			end
			local root = WatchService.rootOf(player)
			if not root or blocked[player] then
				lower(player, s)
				continue
			end
			s.battery = math.max(0, s.battery - dt)
			if s.battery <= 0 then
				lower(player, s)
				continue
			end
			-- turn toward what the client asked, no faster than a hand can (anti cheat, plan section 11)
			s.yaw += math.clamp(Look.angleDiff(s.wantYaw, s.yaw), -maxTurn, maxTurn)
			s.pitch += math.clamp(s.wantPitch - s.pitch, -maxTurn, maxTurn)
			local eye = root.Position + Vector3.new(0, C.camcorder_eye_height, 0)
			local view =
				Look.view(eye.X, eye.Y, eye.Z, s.yaw, s.pitch, C.camcorder_hfov, C.camcorder_vfov, C.camcorder_range)
			WatchService.setCamcorder(player, Watch.coverage(WatchService.level, view, C.camcorder_samples, 0))
			sendBattery(player, s)
		end
	end
end

return CamcorderService
