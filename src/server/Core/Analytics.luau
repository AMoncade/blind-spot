--!strict
-- What the Creator Dashboard learns (Adrien's list, step 6: deaths, quits, night length), through AnalyticsService.
-- Every call is wrapped: analytics never breaks a night. The numbers only show on the published game (Creator
-- Dashboard > Analytics > Custom events, Funnels, Economy): "à vérifier sur le jeu publié".
--   custom events: NightStarted (night), NightEnded (seconds), GuardCaught (seconds into the night), QuitDuringShift
--   (seconds into the night), with the night, the outcome or the floor and phase as fields;
--   onboarding funnel: 1 Joined, 2 FirstShift, 3 FirstNightEnded, 4 Night1Cleared;
--   economy: Pay earned (night pay, daily reward, codes) and spent (shop).
local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

local FIELDS = {
	Enum.AnalyticsCustomFieldKeys.CustomField01,
	Enum.AnalyticsCustomFieldKeys.CustomField02,
	Enum.AnalyticsCustomFieldKeys.CustomField03,
}

local function fields(list: { string }?): { [any]: string }?
	if not list then
		return nil
	end
	local out = {}
	for k, v in list do
		if FIELDS[k] then
			out[FIELDS[k].Name] = v
		end
	end
	return out
end

local function try(what: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn(`[Analytics] {what}: {err}`)
	end
end

-- a custom event: up to three text fields (keep their values few: the dashboard groups by them)
function Analytics.event(player: Player, name: string, value: number?, custom: { string }?)
	try(name, function()
		AnalyticsService:LogCustomEvent(player, name, value or 1, fields(custom) :: any)
	end)
end

local STEPS = { "Joined", "FirstShift", "FirstNightEnded", "Night1Cleared" }

-- an onboarding step (1 to 4): log it once per player, the caller knows when it's the first time
function Analytics.onboarding(player: Player, step: number)
	try("onboarding", function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, STEPS[step])
	end)
end

-- pay earned (source) or spent (sink); balance: the pay after the change; sku: what for (a night, a shop item)
function Analytics.pay(
	player: Player,
	amount: number,
	balance: number,
	kind: Enum.AnalyticsEconomyTransactionType,
	sku: string?
)
	if amount == 0 then
		return
	end
	try("economy", function()
		AnalyticsService:LogEconomyEvent(
			player,
			if amount > 0 then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink,
			"Pay",
			math.abs(amount),
			balance,
			kind.Name,
			sku
		)
	end)
end

return Analytics
