--!strict
-- The Night place's door (Adrien, 8 Nov 2026): a reserved server for one group from the lobby, as Break a Gem's mine
-- (RunState.join). It reads the group from the first arrival's TeleportData (Logic/Party), waits for all of them
-- (party_wait at most), then starts the night with whoever came: the night checked against the leader's own save
-- (Data.unlockedNight), the mode against content/modes.csv, the pay computed here (Logic/Difficulty), one life each.
-- Anyone not in the group, or late, goes back up to the lobby (LaunchService.toLobby). Only in a Night server
-- (Config.Places): in Studio, the workspace attribute ForcePlaceRole = "night" tries it with the players there.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = Shared:WaitForChild("Logic")
local Party = require(Logic:WaitForChild("Party"))
local Difficulty = require(Logic:WaitForChild("Difficulty"))
local Server = script.Parent.Parent
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local LaunchService = require(script.Parent:WaitForChild("LaunchService"))
local NightService = require(script.Parent:WaitForChild("NightService"))

local C = Config.C
local Places = Config.Places

local ArrivalService = {}

local party: Party.Data? = nil
local seen: { [number]: boolean } = {}
local firstAt = 0
local started = false

local function join(player: Player)
	if not party then
		local ok, joinData = pcall(function()
			return player:GetJoinData()
		end)
		party = if ok then Party.read((joinData :: any).TeleportData) else nil
		if not party and RunService:IsStudio() then
			-- Studio (ForcePlaceRole): the players there are the group
			local ids = {}
			for _, p in Players:GetPlayers() do
				table.insert(ids, p.UserId)
			end
			party = Party.data(ids, player.UserId, 1, C.mode_default)
		end
	end
	if not Party.mayEnter(party, player.UserId, started) then
		print(`[ArrivalService] {player.Name} is not in this night's group: back to the lobby`)
		LaunchService.toLobby({ player })
		return
	end
	seen[player.UserId] = true
	if firstAt == 0 then
		firstAt = os.clock()
	end
end

-- everyone came (or party_wait ran out): the night starts with the guards whose save is open
local function begin(group: Party.Data)
	started = true
	local guards = {}
	for _, id in group.party do
		local player = Players:GetPlayerByUserId(id)
		if player and Data.waitFor(player, C.profile_wait) then
			table.insert(guards, player)
		end
	end
	if #guards == 0 then
		started = false -- nobody's save opened: wait for the next arrival
		return
	end
	local leader = Players:GetPlayerByUserId(group.leader) or guards[1]
	local night = math.clamp(group.night, 1, Data.unlockedNight(leader))
	local mode = if Config.modeById[group.mode] then group.mode else C.mode_default
	local multiplier = Difficulty.payMultiplier(
		{ night = night, guards = #guards, lives = C.shift_lives, mode = mode },
		Config.nightByNumber,
		C,
		Config.modeById
	)
	print(`[ArrivalService] night {night} ({mode}) for {#guards}/{#group.party} guard(s)`)
	NightService.launch(guards, night, { lives = C.shift_lives, multiplier = multiplier, mode = mode })
end

function ArrivalService.start()
	if Places.current() ~= "night" then
		return
	end
	workspace:SetAttribute("PlaceRole", "night")
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		task.spawn(join, player)
	end
	-- the night ended and its guards went up: a later arrival (a RETRY needs nobody new) goes up too
	while true do
		task.wait(0.5)
		local group = party
		if not started and group and firstAt > 0 then
			if not Party.waiting(group.party, seen, os.clock() - firstAt, C.party_wait) then
				begin(group)
			end
		end
	end
end

return ArrivalService
