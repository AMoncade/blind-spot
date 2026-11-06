--!strict
-- Boots the server: the Core modules in a fixed order, then the Services in a fixed order. Each module may have init()
-- (wire up, no yielding) and start() (loops, connections); every init runs before the first start. One broken module
-- never stops the others.
local Core = script:WaitForChild("Core")
local Services = script:WaitForChild("Services")

local ORDER = {
	{ Core, "World" },
	{ Core, "Actions" },
	{ Core, "Data" },
	{ Services, "WatchService" },
	{ Services, "CamcorderService" },
	{ Services, "PowerDirector" },
	{ Services, "UnseenService" },
	{ Services, "TaskService" },
	{ Services, "NightService" },
	{ Services, "LobbyService" },
	{ Services, "MenuService" },
	{ Services, "DebugService" },
}

local modules: { { name: string, mod: any } } = {}
for _, entry in ORDER do
	local container, name = entry[1], entry[2]
	local ok, mod = pcall(require, container:WaitForChild(name) :: ModuleScript)
	if ok then
		table.insert(modules, { name = name, mod = mod })
	else
		warn(`[boot] {name} failed to load: {mod}`)
	end
end

for _, entry in modules do
	if type(entry.mod) == "table" and entry.mod.init then
		local ok, err = pcall(entry.mod.init)
		if not ok then
			warn(`[boot] {entry.name}.init failed: {err}`)
		end
	end
end
for _, entry in modules do
	if type(entry.mod) == "table" and entry.mod.start then
		task.spawn(function()
			local ok, err = pcall(entry.mod.start)
			if not ok then
				warn(`[boot] {entry.name}.start failed: {err}`)
			end
		end)
	end
end
print(`[boot] BLIND SPOT server: {#modules} modules`)
