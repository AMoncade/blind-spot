--!strict
-- The group a lobby lift sends to a Night server (Adrien, 8 Nov 2026), as Break a Gem's RunRules: the TeleportData
-- { party = {userId...}, leader = userId, night = n, mode = id } read on arrival, and the wait for the whole party.
-- TeleportData passes through the clients: the night server only takes it as a wish. It checks the night against the
-- leader's own save and the mode against content/modes.csv, counts the guards who really came, and computes the pay
-- itself (Logic/Difficulty). Pure: tests/Party.spec.luau.
local Party = {}

export type Data = { party: { number }, leader: number, night: number, mode: string }

local MAX = 8 -- never more userIds than this from a TeleportData

function Party.data(party: { number }, leader: number, night: number, mode: string): Data
	return { party = party, leader = leader, night = night, mode = mode }
end

-- The TeleportData made safe, or nil when it isn't a party.
function Party.read(raw: unknown): Data?
	if type(raw) ~= "table" then
		return nil
	end
	local t = raw :: any
	if type(t.party) ~= "table" then
		return nil
	end
	local party: { number } = {}
	for _, id in t.party do
		if type(id) == "number" and id == id and id > 0 and #party < MAX and not table.find(party, math.floor(id)) then
			table.insert(party, math.floor(id))
		end
	end
	if #party == 0 then
		return nil
	end
	local leader = if type(t.leader) == "number" and table.find(party, t.leader) then t.leader :: number else party[1]
	local night = if type(t.night) == "number" and t.night == t.night then math.max(1, math.floor(t.night)) else 1
	local mode = if type(t.mode) == "string" and #t.mode <= 20 then t.mode :: string else ""
	return { party = party, leader = leader, night = night, mode = mode }
end

-- Someone of the party has not arrived yet, and the first arrival was less than maxWait seconds ago.
function Party.waiting(party: { number }, seen: { [number]: boolean }, sinceFirst: number, maxWait: number): boolean
	if sinceFirst >= maxWait then
		return false
	end
	for _, id in party do
		if not seen[id] then
			return true
		end
	end
	return false
end

-- May this player stay in the night server? Only the party, and nobody once the night has started.
function Party.mayEnter(data: Data?, userId: number, started: boolean): boolean
	return data ~= nil and not started and table.find(data.party, userId) ~= nil
end

return Party
