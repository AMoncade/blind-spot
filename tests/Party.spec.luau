--!strict
-- Two places (Adrien, 8 Nov): a lobby of 20, nights of 4 in reserved servers. Which server does what (Config.Places),
-- and the group a lift sends, read from a TeleportData that passes through the clients (Logic/Party).
local Places = require("../src/shared/Config/Places")
local Party = require("../src/shared/Logic/Party")

local function ok(v: any, what: string)
	if not v then
		error(what, 2)
	end
end

local function eq(a: any, b: any, what: string?)
	if a ~= b then
		error(`{what or "value"}: expected {tostring(b)}, got {tostring(a)}`, 2)
	end
end

local spec = {}

function spec.eachServerKnowsItsRole()
	-- Studio always plays both (no teleports there), or the night side when forced
	eq(Places.role(Places.Lobby, true, nil), "both", "Studio")
	eq(Places.role(Places.Lobby, true, "night"), "night", "Studio forced to the night side")
	eq(Places.role(Places.Lobby, true, "lobby"), "both", "only the night side can be forced")
	-- no Night place yet: the lobby plays the nights itself
	local saved = Places.Night
	Places.Night = 0
	eq(Places.role(Places.Lobby, false, nil), "both", "no Night place")
	Places.Night = 12345
	eq(Places.role(Places.Lobby, false, nil), "lobby", "the start place")
	eq(Places.role(12345, false, nil), "night", "the Night place")
	Places.Night = saved
end

function spec.aTeleportDataIsOnlyAWish()
	eq(Party.read(nil), nil, "nothing")
	eq(Party.read("solo"), nil, "not a table")
	eq(Party.read({ party = {} }), nil, "an empty party")
	eq(Party.read({ party = { "x", -3, 0 / 0 } }), nil, "no real userId")
	local d = Party.read({ party = { 11, 22, 22, 33.7 }, leader = 99, night = 4.6, mode = "hard" }) :: Party.Data
	eq(#d.party, 3, "the userIds, once each")
	eq(d.party[3], 33, "rounded down")
	eq(d.leader, 11, "a leader outside the party: the first one")
	eq(d.night, 4, "the night, whole")
	eq(d.mode, "hard", "the mode (checked against modes.csv by the server)")
	local many = {}
	for k = 1, 50 do
		many[k] = k
	end
	eq(#(Party.read({ party = many }) :: Party.Data).party, 8, "never more than 8")
	local plain = Party.read({ party = { 5 } }) :: Party.Data
	eq(plain.night, 1, "no night: 1")
	eq(plain.mode, "", "no mode: the server's default")
end

function spec.theNightWaitsForItsGroup()
	local party = { 1, 2, 3 }
	ok(Party.waiting(party, { [1] = true }, 2, 20), "two still on their way")
	ok(not Party.waiting(party, { [1] = true, [2] = true, [3] = true }, 2, 20), "everyone is here")
	ok(not Party.waiting(party, { [1] = true }, 25, 20), "not forever")
	local d = Party.read({ party = party }) :: Party.Data
	ok(Party.mayEnter(d, 2, false), "a member, before the start")
	ok(not Party.mayEnter(d, 9, false), "a stranger")
	ok(not Party.mayEnter(d, 2, true), "nobody once the night runs")
	ok(not Party.mayEnter(nil, 2, false), "no party at all")
end

return spec
