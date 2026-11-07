--!strict
-- The night's task list (plan section 3, "La ronde": 4 to 6 tasks drawn from the place's list). Built once per night
-- from Config.Tasks and a seed: scan_count checkpoints to scan, then every fetch task (take an item at one of its
-- pickup spots, use it at its target). The round comes through the night ("le cycle du courant tourne pendant toute la
-- ronde"): each task shows up at its hour (tasks.csv, hours; the checkpoints spread over theirs), and its effect (a
-- dead camera, a dark zone) starts then and lasts until it is done. Pure.
local Rng = require(if script then script.Parent:WaitForChild("Rng") else "./Rng")

local Tasks = {}

export type Def = {
	id: string,
	kind: string, -- "scan" | "fetch"
	label: string,
	item: string,
	pickup: { string },
	target: { string },
	effect: { string },
	pay: number,
	hold: number,
	nights: { number }?, -- only these nights (empty: every night)
	hours: { number }?, -- the night hour it shows up (scan: one per checkpoint, in turn); empty: at the start
}

export type Task = {
	id: string, -- unique in the night: "scan:R2", "generator"
	kind: string, -- "scan" | "fetch" | "film" (stand in the target's room with the camcorder raised for hold s)
	label: string,
	item: string?, -- fetch: the item to carry
	pickup: string?, -- fetch: the spot where the item lies
	target: string, -- the spot to scan or to use the item at
	effect: { string },
	pay: number,
	hold: number,
	at: number, -- seconds into the night when it shows up on the clipboard
	done: boolean,
}

local function hourOf(def: Def, k: number): number
	local hours = def.hours
	if not hours or #hours == 0 then
		return 0
	end
	return hours[(k - 1) % #hours + 1]
end

function Tasks.build(
	defs: { Def },
	spotLabel: (string) -> string,
	scanCount: number,
	seed: number,
	night: number?,
	hourLength: number? -- seconds per night hour (nil: every task at the start)
): { Task }
	local hourSeconds = hourLength or 0
	local rng = Rng.new(seed)
	local out: { Task } = {}
	for _, def in defs do
		if night and def.nights and #def.nights > 0 and not table.find(def.nights, night) then
			continue
		end
		if def.kind == "scan" and #def.target > 1 then
			local spots = rng.shuffle(def.target)
			for k = 1, math.min(scanCount, #spots) do
				local spot = spots[k]
				table.insert(out, {
					id = "scan:" .. spot,
					kind = "scan",
					label = (string.gsub(def.label, "{label}", spotLabel(spot))),
					target = spot,
					effect = def.effect,
					pay = def.pay,
					hold = def.hold,
					at = hourOf(def, k) * hourSeconds,
					done = false,
				})
			end
		elseif def.kind ~= "fetch" then
			-- a single scan (the breakers) or a film task: its own target
			table.insert(out, {
				id = def.id,
				kind = def.kind,
				label = def.label,
				target = def.target[1],
				effect = def.effect,
				pay = def.pay,
				hold = def.hold,
				at = hourOf(def, 1) * hourSeconds,
				done = false,
			})
		else
			table.insert(out, {
				id = def.id,
				kind = "fetch",
				label = def.label,
				item = def.item,
				pickup = rng.pick(def.pickup),
				target = def.target[1],
				effect = def.effect,
				pay = def.pay,
				hold = def.hold,
				at = hourOf(def, 1) * hourSeconds,
				done = false,
			})
		end
	end
	return out
end

-- Has this task shown up yet, `now` seconds into the night? (nil: yes)
function Tasks.released(t: Task, now: number?): boolean
	return now == nil or t.at <= now
end

-- The effects in force `now` (tasks shown up and not done; nil: every task not done): dead cameras, dark light zones.
function Tasks.broken(list: { Task }, now: number?): ({ [string]: boolean }, { [string]: boolean })
	local cams: { [string]: boolean } = {}
	local lights: { [string]: boolean } = {}
	for _, t in list do
		if not t.done and Tasks.released(t, now) then
			for _, e in t.effect do
				local kind, id = string.match(e, "^(%w+):(.+)$")
				if kind == "cam" then
					cams[id :: string] = true
				elseif kind == "lights" then
					lights[id :: string] = true
				end
			end
		end
	end
	return cams, lights
end

function Tasks.pay(list: { Task }): (number, number)
	local pay, done = 0, 0
	for _, t in list do
		if t.done then
			pay += t.pay
			done += 1
		end
	end
	return pay, done
end

return Tasks
