--!strict
-- The remotes of the game (CLAUDE.md, "Le serveur décide"):
--   Action (client -> server): an intention, `Net.send("Camcorder", true, yaw, pitch, x, y, z)`. The server routes each
--     action name to one handler (server Core/Actions), which checks its arguments and rate-limits it.
--   Event (server -> client): something that happens: the night's timeline, the filmed state, a death, the hush.
--   Unseen (server -> clients, unreliable): the Unseen's position, 10 times a second.
-- Every action name the client may send is listed in ACTIONS with its rate limit (per second).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

Net.ACTIONS = {
	Ready = 2, -- the client listens: send it the night
	Camcorder = 14,
	TurnCamera = 6, -- (camera id, -1 | 0 | 1): a watcher turns the camera they look through
	Lift = 4, -- ("start" | "leave"): only for the guard standing in that lift -- (raised, yaw, pitch): 10 Hz while filming, plus raise and lower
	Play = 2, -- ("group" | "solo"): into the best open lift, or an empty one that leaves at once
	Profile = 2, -- send me my profile again
	ClaimDaily = 2,
	Buy = 4, -- (shop id)
	Equip = 6, -- (shop id)
	Redeem = 2, -- (code)
	Skill = 4, -- ("sprint" | "flare")
	Signal = 2, -- (signal id, x, y, z): a coop signal; x, y, z = where the guard looks (OVER HERE)
	SetSetting = 10, -- (name, value)
	Debug = 10, -- Studio only (Core/Actions refuses it in a live server)
}

local FOLDER = "Remotes"

local function folder(): Folder
	if RunService:IsServer() then
		local f = ReplicatedStorage:FindFirstChild(FOLDER)
		if not f then
			f = Instance.new("Folder")
			f.Name = FOLDER
			f.Parent = ReplicatedStorage
		end
		return f :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER) :: Folder
end

local function remote(name: string, className: string): Instance
	local f = folder()
	local found = f:FindFirstChild(name)
	if found then
		return found
	end
	if RunService:IsServer() then
		local made = Instance.new(className)
		made.Name = name
		made.Parent = f
		return made
	end
	return f:WaitForChild(name)
end

function Net.action(): RemoteEvent
	return remote("Action", "RemoteEvent") :: RemoteEvent
end

function Net.event(): RemoteEvent
	return remote("Event", "RemoteEvent") :: RemoteEvent
end

function Net.unseen(): UnreliableRemoteEvent
	return remote("Unseen", "UnreliableRemoteEvent") :: UnreliableRemoteEvent
end

-- Client: send an intention.
function Net.send(name: string, ...: any)
	assert(Net.ACTIONS[name], "Net.send: unknown action " .. name)
	Net.action():FireServer(name, ...)
end

return Net
