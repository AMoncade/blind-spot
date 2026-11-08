--!strict
-- The two places of the experience (Adrien, 8 Nov 2026: "un lobby de 20, des nuits de 4"), as in Break a Gem
-- (Config.Places). The start place « BLIND SPOT » is the lobby (Kestrel & Vane's locker room and office, server size
-- 20); the place « Night » (server size 4, closed to direct joins) plays the shifts, each group in a reserved server of
-- its own. Both places run this same code: a server's role comes from its PlaceId (Places.role).
-- Night = 0: the place doesn't exist yet, so the lobby plays the nights itself, one at a time, as before. Studio always
-- does both (TeleportService doesn't work there); the workspace attribute ForcePlaceRole = "night" tries the night
-- server's side in Studio (the group comes from the players there).
local Places = {
	Lobby = 109730217990790, -- the start place « BLIND SPOT »
	Night = 0, -- Adrien creates it (docs/A-FAIRE-ADRIEN.md) and its id goes here
	lobbyMaxPlayers = 20,
	nightMaxPlayers = 4,
}

export type Role = "both" | "lobby" | "night"

-- What a server of this place does. studio: one server does both (or the night side when forced to).
function Places.role(placeId: number, studio: boolean, forced: unknown): Role
	if studio then
		return if forced == "night" then "night" else "both"
	end
	if Places.Night == 0 then
		return "both"
	end
	return if placeId == Places.Night then "night" else "lobby"
end

-- this game's role (not in Lune: it reads the running place)
function Places.current(): Role
	local RunService = game:GetService("RunService")
	return Places.role(game.PlaceId, RunService:IsStudio(), workspace:GetAttribute("ForcePlaceRole"))
end

return Places
