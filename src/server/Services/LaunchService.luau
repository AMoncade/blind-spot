--!strict
-- The teleports between the two places (Adrien, 8 Nov 2026: "un lobby de 20, des nuits de 4"), Break a Gem's
-- LaunchService and RunState.sendToHub (Config.Places):
--   toNight: a lift's group from the lobby to a fresh reserved Night server, one TeleportAsync for all of them with
--     ShouldReserveServer and the TeleportData Party.data { party, leader, night, mode }. The profiles end first (the
--     night server waits for their lock); a few tries, then a failure that opens them again and tells the guards.
--   toLobby: guards from a Night server back to the lobby (its public servers), the profiles saved and ended first
--     (the night's pay is in them); a few tries, then a kick so a save never stays locked.
-- STUDIO: TeleportService doesn't work there. The lobby never calls toNight (Studio plays both); toLobby is simulated
-- (the guards go up to this place's own lobby). To check on the published game, never "done" from Studio.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Party = require(Shared:WaitForChild("Logic"):WaitForChild("Party"))
local Server = script.Parent.Parent
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))

local C = Config.C
local Places = Config.Places

local LaunchService = {}

LaunchService.onFailed = nil :: ((players: { Player }) -> ())? -- LobbyService: the guards are back in the lobby
LaunchService.studioLobby = nil :: ((players: { Player }) -> ())? -- NightService: Studio's simulated trip up

local IS_STUDIO = RunService:IsStudio()
local leaving: { [Player]: "night" | "lobby" } = {} -- on their way (TeleportInitFailed answers for these)

local function stillHere(players: { Player }): { Player }
	local out = {}
	for _, player in players do
		if player.Parent == Players then
			table.insert(out, player)
		end
	end
	return out
end

local function notify(player: Player, text: string)
	Net.event():FireClient(player, "Notice", text, false)
end

-- the teleport didn't happen: the save opens again, the guard is told, the lobby takes them back
local function failed(players: { Player })
	local here = stillHere(players)
	for _, player in here do
		leaving[player] = nil
		Data.reload(player)
		notify(player, "THE LIFT IS STUCK. TRY AGAIN IN A MOMENT.")
		Net.event():FireClient(player, "LaunchFailed")
	end
	if LaunchService.onFailed then
		LaunchService.onFailed(here)
	end
end

local function teleport(placeId: number, players: { Player }, options: TeleportOptions?, what: string): boolean
	for attempt = 1, C.teleport_tries do
		local here = stillHere(players)
		if #here == 0 then
			return true
		end
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(placeId, here, options)
		end)
		if ok then
			return true
		end
		warn(`[LaunchService] {what}: TeleportAsync failed ({attempt}/{C.teleport_tries}): {err}`)
		if attempt < C.teleport_tries then
			task.wait(C.teleport_retry_delay)
		end
	end
	return false
end

-- A lift's group to its own Night server. True when the teleport started.
function LaunchService.toNight(players: { Player }, leader: Player, night: number, mode: string): boolean
	local here = stillHere(players)
	if #here == 0 or Places.Night == 0 or IS_STUDIO then
		return false
	end
	local party = {}
	for _, player in here do
		table.insert(party, player.UserId)
		leaving[player] = "night"
		Data.release(player) -- the night server waits for this lock
	end
	task.spawn(function()
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		options:SetTeleportData(Party.data(party, leader.UserId, night, mode))
		local ok = teleport(Places.Night, here, options, "to the night")
		options:Destroy()
		if not ok then
			warn("[LaunchService] the group could not reach a Night server")
			failed(here)
		end
	end)
	return true
end

-- Guards back up to the lobby (its public servers), their save ended first.
function LaunchService.toLobby(players: { Player })
	local here = stillHere(players)
	if #here == 0 then
		return
	end
	if IS_STUDIO then
		print(`[LaunchService] Studio: the trip up to the lobby is SIMULATED for {#here} guard(s)`)
		if LaunchService.studioLobby then
			LaunchService.studioLobby(here)
		end
		return
	end
	for _, player in here do
		leaving[player] = "lobby"
		Data.release(player)
	end
	task.spawn(function()
		if not teleport(Places.Lobby, here, nil, "to the lobby") then
			for _, player in stillHere(here) do
				player:Kick("The lift back up broke down. Your pay is saved: please rejoin.")
			end
		end
	end)
end

function LaunchService.start()
	if IS_STUDIO then
		return
	end
	-- a teleport can still fail after TeleportAsync returned
	TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
		local where = leaving[player]
		if not where then
			return
		end
		warn(`[LaunchService] TeleportInitFailed for {player.Name} ({result.Name}): {message}`)
		if where == "night" then
			failed({ player })
		else
			-- up to the lobby again in a moment (the save is ended before each try)
			leaving[player] = nil
			Data.reload(player)
			task.delay(C.teleport_retry_delay, function()
				LaunchService.toLobby({ player })
			end)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		leaving[player] = nil
	end)
end

return LaunchService
