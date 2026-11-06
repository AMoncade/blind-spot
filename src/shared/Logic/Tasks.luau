--!strict
-- The night's task list (plan section 3, "La ronde": 4 to 6 tasks drawn from the place's list). Built once per night
-- from Config.Tasks and a seed: scan_count checkpoints to scan, then every fetch task (take an item at one of its
-- pickup spots, use it at its target). A task's effect (a dead camera, a dark zone) lasts until it is done. Pure.
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
}

export type Task = {
	id: string, -- unique in the night: "scan:R2", "generator"
	kind: string,
	label: string,
	item: string?, -- fetch: the item to carry
	pickup: string?, -- fetch: the spot where the item lies
	target: string, -- the spot to scan or to use the item at
	effect: { string },
	pay: number,
	hold: number,
	done: boolean,
}

function Tasks.build(defs: { Def }, spotLabel: (string) -> string, scanCount: number, seed: number): { Task }
	local rng = Rng.new(seed)
	local out: { Task } = {}
	for _, def in defs do
		if def.kind == "scan" then
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
					done = false,
				})
			end
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
				done = false,
			})
		end
	end
	return out
end

-- The effects still in force (tasks not done): dead cameras and dark light zones.
function Tasks.broken(list: { Task }): ({ [string]: boolean }, { [string]: boolean })
	local cams: { [string]: boolean } = {}
	local lights: { [string]: boolean } = {}
	for _, t in list do
		if not t.done then
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
