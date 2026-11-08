--!strict
-- Boots the client: the settings and the State listeners first (so no event is missed), then the controllers. Each one
-- starts in its own pcall, so one broken controller never takes the others down.
local Controllers = script:WaitForChild("Controllers")
local Ui = script:WaitForChild("Ui")

local Settings = require(script:WaitForChild("Settings"))
local State = require(script:WaitForChild("State"))

-- background: the controller waits for the streamed level, so it starts in its own thread
local function start(name: string, background: boolean?, container: Instance?)
	local function run()
		local ok, err = pcall(function()
			local mod = require((container or Controllers):WaitForChild(name) :: ModuleScript) :: any
			mod.start()
		end)
		if not ok then
			warn(`[boot] client {name} failed: {err}`)
		end
	end
	if background then
		task.spawn(run)
	else
		run()
	end
end

Settings.start()
start("Loading") -- first: it covers the screen while the rest loads
start("FirstPerson")
start("Camcorder")
start("Viewmodel", true)
start("Atmosphere", true)
start("CameraHeads", true)
start("SafeZones", true)
start("UnseenView")
start("Death")
start("Watcher")
start("Story")
start("SoundDirector")
start("Hud")
start("Tasks")
start("Signals")
start("Skills")
start("Lobby")
start("Menu", false, Ui)
State.start() -- last: the controllers are listening when the server answers Ready
print("[boot] BLIND SPOT client")
