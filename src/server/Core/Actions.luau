--!strict
-- Routes every client intention (Net.ACTIONS) to the one service that handles it, after a per-player rate limit
-- (CLAUDE.md: every remote checks its arguments and has a rate limit; the handlers check the arguments).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Actions = {}

type Handler = (player: Player, ...any) -> ()

local handlers: { [string]: Handler } = {}
-- player -> action -> { window start, count }
local budget: { [Player]: { [string]: { number } } } = {}

function Actions.on(name: string, handler: Handler)
	assert(Net.ACTIONS[name], "Actions.on: " .. name .. " is not in Net.ACTIONS")
	assert(not handlers[name], "Actions.on: two handlers for " .. name)
	handlers[name] = handler
end

local function allowed(player: Player, name: string): boolean
	local per = budget[player]
	if not per then
		per = {}
		budget[player] = per
	end
	local now = os.clock()
	local b = per[name]
	if not b or now - b[1] >= 1 then
		per[name] = { now, 1 }
		return true
	end
	b[2] += 1
	return b[2] <= Net.ACTIONS[name]
end

function Actions.init()
	-- every remote exists before the first client asks for it
	Net.event()
	Net.unseen()
	Net.action().OnServerEvent:Connect(function(player: Player, name: unknown, ...)
		if type(name) ~= "string" or not handlers[name] then
			return
		end
		if not allowed(player, name) then
			return
		end
		local ok, err = pcall(handlers[name], player, ...)
		if not ok then
			warn(`[Actions] {name} from {player.UserId}: {err}`)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		budget[player] = nil
	end)
end

-- a finite number in [lo, hi], or nil
function Actions.number(v: unknown, lo: number, hi: number): number?
	if type(v) ~= "number" or v ~= v or v < lo or v > hi then
		return nil
	end
	return v
end

return Actions
