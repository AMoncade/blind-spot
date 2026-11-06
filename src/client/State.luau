--!strict
-- What the client knows, from the server's events (Net). The controllers read it and subscribe with State.on(name, fn).
-- The client never decides anything here: it draws and listens (CLAUDE.md, "Le serveur décide").
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("Config"))
local Timeline = require(Shared:WaitForChild("Logic"):WaitForChild("Timeline"))

local State = {}

State.night = nil :: any -- { night, seed, length, start (server time), segments } or nil between nights
State.filmed = true
State.seenBy = {} :: { string }
State.battery = Config.C.camcorder_battery
State.batteryMax = Config.C.camcorder_battery
State.hushed = false
State.dead = false
State.rounds = { done = 0, total = #Config.Rounds, ids = {} :: { string } }
State.unseen = { present = false, x = 0, z = 0, yaw = 0, at = 0 }

local listeners: { [string]: { (...any) -> () } } = {}

function State.on(name: string, fn: (...any) -> ())
	listeners[name] = listeners[name] or {}
	table.insert(listeners[name], fn)
end

local function emit(name: string, ...: any)
	local list = listeners[name]
	if list then
		for _, fn in list do
			task.spawn(fn, ...)
		end
	end
end

-- seconds since 0 h of the running night, and its segment (nil between nights)
function State.now(): (number, Timeline.Segment?)
	local night = State.night
	if not night then
		return 0, nil
	end
	local t = workspace:GetServerTimeNow() - night.start
	return t, (Timeline.at(night, t))
end

function State.start()
	Net.event().OnClientEvent:Connect(function(name: string, ...)
		if name == "Night" then
			State.night = ...
		elseif name == "Watch" then
			local filmed, ids = ...
			State.filmed = filmed
			State.seenBy = ids
		elseif name == "Battery" then
			local battery, max = ...
			State.battery, State.batteryMax = battery, max
		elseif name == "Hush" then
			State.hushed = ...
		elseif name == "Death" then
			State.dead = true
		elseif name == "Respawn" then
			State.dead = false
			State.hushed = false
		elseif name == "Rounds" then
			local n, total, ids = ...
			State.rounds = { done = n, total = total, ids = ids }
		end
		emit(name, ...)
	end)
	Net.unseen().OnClientEvent:Connect(function(present: boolean, x: number, z: number, yaw: number)
		local u = State.unseen
		u.present, u.x, u.z, u.yaw, u.at = present, x, z, yaw, os.clock()
	end)
	Net.send("Ready")
end

return State
