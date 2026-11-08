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
State.shift = false -- on a shift in the P3 (false: in the lobby)
State.exposure = 1 -- the signal bar: 1 full on camera, it drains off camera (event Exposure)
State.marked = false -- the bar ran out: he knows where you are
State.down = false -- co-op: taken, watching through the cameras from the booth
State.squad = nil :: any -- { solo, lives, up, total, down = names } (event Squad)
State.badges = {} :: { any } -- taken guards' badges: { id, name, pos, carriedBy } (event Badges)
State.syringes = nil :: number? -- co-op: this guard's syringes left tonight (event Syringes; nil in solo)
State.tasks = nil :: any -- the night's tasks (event Tasks: tasks, held, brokenCams, brokenLights)
State.profile = nil :: any -- the saved profile as the server sends it (event Profile)
State.profileAt = nil :: number? -- os.time() when it arrived (the daily countdown runs from it)
-- shows a short message; Ui/Menu replaces it with the real toast
function State.notice(_text: string, _good: boolean) end
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
			State.down = false
			State.hushed = false
		elseif name == "Down" then
			State.dead = false
			State.down = true
		elseif name == "Squad" then
			State.squad = ...
		elseif name == "Badges" then
			State.badges = ...
		elseif name == "Syringes" then
			State.syringes = ...
		elseif name == "Exposure" then
			local e, m = ...
			State.exposure, State.marked = e, m
		elseif name == "Tasks" then
			State.tasks = ...
		elseif name == "Profile" then
			State.profile = ...
			State.profileAt = os.time()
		elseif name == "Shift" then
			State.shift = ...
			State.dead = false -- a new shift (RETRY) or the lobby: no longer caught
			State.syringes = nil
			if not State.shift then
				State.down = false
			end
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
