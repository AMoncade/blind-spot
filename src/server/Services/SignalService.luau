--!strict
-- Coop without chat (plan section 3: "coop de 1 à 4"; Adrien's list, step 5): a guard sends one of a few signals
-- (content/signals.csv) from the wheel. A ping (OVER HERE, HE'S THERE) marks the point they look at, a self signal
-- (FILM ME, HELP...) marks the guard. The server checks who may send, how often and how far, then tells every guard on
-- the shift (the dead and the watchers too: they see the marker through the cameras).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local Actions = require(Server:WaitForChild("Core"):WaitForChild("Actions"))

local C = Config.C

local SignalService = {}

SignalService.onShift = nil :: ((player: Player) -> boolean)? -- NightService: on tonight's shift
SignalService.isPlaying = nil :: ((player: Player) -> boolean)? -- NightService: up and walking (a ping needs eyes)

local nextSend: { [Player]: number } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- where the marker goes: the point a ping names (near the guard, on their floor), or the guard
local function place(player: Player, kind: string, x: unknown, y: unknown, z: unknown): Vector3?
	local root = rootOf(player)
	if not root then
		return nil
	end
	if kind ~= "ping" then
		return root.Position
	end
	local px = Actions.number(x, -1e4, 1e4)
	local py = Actions.number(y, -1e3, 1e3)
	local pz = Actions.number(z, -1e4, 1e4)
	if not px or not py or not pz then
		return nil
	end
	local at = Vector3.new(px, py, pz)
	if (at - root.Position).Magnitude > C.signal_range or Config.floorAt(px) ~= Config.floorAt(root.Position.X) then
		return nil
	end
	return at
end

function SignalService.init()
	Actions.on("Signal", function(player: Player, id: unknown, x: unknown, y: unknown, z: unknown)
		if type(id) ~= "string" then
			return
		end
		local signal = Config.signalById[id]
		if not signal or not SignalService.onShift or not SignalService.onShift(player) then
			return
		end
		-- a ping needs a guard up and looking; the others can come from a watcher too
		if signal.kind == "ping" and not (SignalService.isPlaying and SignalService.isPlaying(player)) then
			return
		end
		local now = os.clock()
		if now < (nextSend[player] or 0) then
			return
		end
		local at = place(player, signal.kind, x, y, z)
		if not at then
			return
		end
		nextSend[player] = now + C.signal_cooldown
		local data = {
			id = signal.id,
			from = player.UserId,
			name = player.DisplayName,
			x = at.X,
			y = at.Y,
			z = at.Z,
			follow = signal.kind ~= "ping",
		}
		for _, other in Players:GetPlayers() do
			if SignalService.onShift(other) then
				Net.event():FireClient(other, "Signal", data)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		nextSend[player] = nil
	end)
end

return SignalService
