--!strict
-- One ProfileStore profile per player (CLAUDE.md). If it can't load, the player doesn't play: they are kicked with a
-- message, never started on an empty save. The profile goes to its client (event "Profile") after every change,
-- throttled. Real DataStores are "to check on the published game": in an unpublished Studio place ProfileStore runs
-- on its mock store.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Daily = require(Shared:WaitForChild("Logic"):WaitForChild("Daily"))
local ProfileStore = require(script.Parent.Parent:WaitForChild("Packages"):WaitForChild("ProfileStore"))

local C = Config.C
local STORE_NAME = "BlindSpot_v1"

export type Profile = {
	pay: number,
	owned: { [string]: boolean },
	viewfinder: string,
	daily: { streak: number, lastDay: number },
	codes: { [string]: boolean },
	settings: { [string]: any },
	nights: number,
	deaths: number,
	bestNight: number, -- the highest night cleared (its round done before 6 AM)
	tapes: { [string]: boolean }, -- the hidden tapes found (content/tapes.csv)
}

local TEMPLATE: Profile = {
	pay = 0,
	owned = { vf_classic = true },
	viewfinder = "vf_classic",
	daily = { streak = 0, lastDay = 0 },
	codes = {},
	settings = {},
	nights = 0,
	deaths = 0,
	bestNight = 0,
	tapes = {},
}

local Data = {}

type Entry = { profile: any, dirty: boolean, released: boolean }

local store: any
local entries: { [Player]: Entry } = {}
local loadedListeners: { (Player, Profile) -> () } = {}

function Data.get(player: Player): Profile?
	local entry = entries[player]
	return if entry and not entry.released then entry.profile.Data else nil
end

function Data.changed(player: Player)
	local entry = entries[player]
	if entry then
		entry.dirty = true
	end
end

function Data.onLoaded(fn: (Player, Profile) -> ())
	table.insert(loadedListeners, fn)
end

-- the highest night this guard may start: the one after their best, up to the last night
function Data.unlockedNight(player: Player): number
	local profile = Data.get(player)
	local best = if profile then profile.bestNight else 0
	return math.clamp(best + 1, 1, #Config.Nights)
end

function Data.addPay(player: Player, amount: number)
	local profile = Data.get(player)
	if profile and amount > 0 then
		profile.pay += math.floor(amount)
		Data.changed(player)
	end
end

-- what the client sees
local function snapshot(profile: Profile): { [string]: any }
	local now = os.time()
	local state = profile.daily
	local streak, slot = Daily.nextStreak(state, now, C.daily_day_seconds, #Config.Daily)
	return {
		pay = profile.pay,
		owned = profile.owned,
		viewfinder = profile.viewfinder,
		settings = profile.settings,
		nights = profile.nights,
		bestNight = profile.bestNight,
		tapes = profile.tapes,
		daily = {
			canClaim = Daily.canClaim(state, now, C.daily_day_seconds),
			streak = streak,
			slot = slot,
			lastStreak = state.streak,
			secondsLeft = Daily.secondsLeft(state, now, C.daily_day_seconds),
		},
	}
end

local function release(player: Player)
	local entry = entries[player]
	if not entry or entry.released then
		return
	end
	entry.released = true
	entries[player] = nil
	entry.profile:EndSession()
end

local function load(player: Player)
	local ok, profile = pcall(function()
		return store:StartSessionAsync("player_" .. player.UserId, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)
	if not ok then
		warn(`[Data] StartSessionAsync failed for {player.UserId}: {profile}`)
		profile = nil
	end
	if player.Parent ~= Players then
		if profile then
			profile:EndSession()
		end
		return
	end
	if not profile then
		player:Kick("Your save couldn't load, so nothing was lost. Please rejoin in a minute.")
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	local entry: Entry = { profile = profile, dirty = true, released = false }
	entries[player] = entry
	profile.OnSessionEnd:Connect(function()
		if entries[player] == entry then
			entries[player] = nil
		end
		if not entry.released and player.Parent == Players then
			player:Kick("Your save was opened on another server. Please rejoin.")
		end
	end)
	for _, fn in loadedListeners do
		task.spawn(fn, player, profile.Data)
	end
end

function Data.init()
	store = ProfileStore.New(STORE_NAME, TEMPLATE)
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(release)
	game:BindToClose(function()
		for player in entries do
			release(player)
		end
	end)
end

-- re-sends the profile to one client now (it just asked)
function Data.send(player: Player)
	local profile = Data.get(player)
	if profile then
		Net.event():FireClient(player, "Profile", snapshot(profile))
	end
end

function Data.start()
	while true do
		task.wait(C.profile_send_every)
		for player, entry in entries do
			if entry.dirty and not entry.released then
				entry.dirty = false
				Net.event():FireClient(player, "Profile", snapshot(entry.profile.Data))
			end
		end
	end
end

return Data
