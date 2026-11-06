--!strict
-- Plays the night's power cycle (plan section 3 and 11): builds the timeline from the night config and a seed, dates
-- it with the server clock and sends it to every client, so four players see the same tube die at the same moment.
-- At every segment change it tells WatchService which cameras run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Timeline = require(Shared:WaitForChild("Logic"):WaitForChild("Timeline"))

local WatchService = require(script.Parent:WaitForChild("WatchService"))

local PowerDirector = {}

PowerDirector.changed = Instance.new("BindableEvent") -- (segment) at every phase change

local timeline: Timeline.Timeline? = nil
local startTime = 0 -- workspace:GetServerTimeNow() at 0 h
local index = 0
local connection: RBXScriptConnection? = nil

local function payload(): any
	local tl = timeline :: Timeline.Timeline
	return { night = tl.night, seed = tl.seed, length = tl.length, start = startTime, segments = tl.segments }
end

function PowerDirector.broadcast(player: Player?)
	if not timeline then
		return
	end
	if player then
		Net.event():FireClient(player, "Night", payload())
	else
		Net.event():FireAllClients("Night", payload())
	end
end

-- seconds since 0 h, the segment playing and the timeline (nil when no night runs)
function PowerDirector.now(): (number, Timeline.Segment?, Timeline.Timeline?)
	if not timeline then
		return 0, nil, nil
	end
	local t = workspace:GetServerTimeNow() - startTime
	local seg = Timeline.at(timeline, t)
	return t, seg, timeline
end

function PowerDirector.phase(): string?
	local _, seg = PowerDirector.now()
	return seg and seg.phase
end

local function step()
	local t, seg, tl = PowerDirector.now()
	if not seg or not tl then
		return
	end
	local _, k = Timeline.at(tl, t)
	if k ~= index then
		index = k
		WatchService.setActive(Timeline.active(seg, Config.Cameras))
		PowerDirector.changed:Fire(seg)
	end
end

function PowerDirector.startNight(night: number, seed: number)
	local def = Config.nightByNumber[night]
	assert(def, "PowerDirector.startNight: no night " .. night)
	timeline = Timeline.build(def, Config.Cameras, seed)
	startTime = workspace:GetServerTimeNow()
	index = 0
	step()
	PowerDirector.broadcast()
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

function PowerDirector.stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	timeline = nil
	index = 0
	-- between nights every camera runs
	WatchService.setActive(Timeline.active({ phase = "LIVE", t0 = 0, t1 = 0 }, Config.Cameras))
	Net.event():FireAllClients("Night", nil)
end

-- Studio debug: jump to the start of the next segment
function PowerDirector.skip()
	local t, seg = PowerDirector.now()
	if seg then
		startTime -= seg.t1 - t + 0.01
		PowerDirector.broadcast()
		step()
	end
end

function PowerDirector.start()
	while not WatchService.ready do
		task.wait(0.1)
	end
	WatchService.setActive(Timeline.active({ phase = "LIVE", t0 = 0, t1 = 0 }, Config.Cameras))
end

return PowerDirector
