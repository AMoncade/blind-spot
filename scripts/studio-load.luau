-- Loads the game's code into the open Studio place without Rojo, as in Break a Gem and Roll an Anomaly. Run in Edit
-- (the Studio MCP or Ropilot), after `py scripts/manifest.py` and `py scripts/serve.py` (port 34896):
--   return loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34896/scripts/studio-load.luau?t=" .. os.clock(), true))()
-- Replaces whatever an earlier load created. Turns HttpEnabled on only for the load, then puts it back.

local HttpService = game:GetService("HttpService")
if _G.BS_LOADING and os.clock() - _G.BS_LOADING < 60 then
	return "a load is already running: wait for it"
end
_G.BS_LOADING = os.clock()

local wasEnabled = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local BASE = "http://127.0.0.1:34896/"
local function get(path)
	return HttpService:GetAsync(BASE .. path .. "?t=" .. os.clock(), true)
end

local ok, result = pcall(function()
	local manifest = HttpService:JSONDecode(get("build/manifest.json"))

	local function find(path, upTo)
		local node = game:GetService(path[1])
		for i = 2, upTo do
			node = node and node:FindFirstChild(path[i])
		end
		return node
	end

	for _, root in manifest.roots do
		local node = find(root, #root)
		if node then
			node:Destroy()
		end
	end

	local count = 0
	for _, entry in manifest.entries do
		local parent = find(entry.path, #entry.path - 1)
		assert(parent, "parent not found for " .. table.concat(entry.path, "."))
		if entry.class == "Folder" and parent:FindFirstChild(entry.path[#entry.path]) then
			continue -- a game container (StarterPlayerScripts): keep the real one
		end
		local inst = Instance.new(entry.class)
		inst.Name = entry.path[#entry.path]
		if entry.source then
			inst.Source = get(entry.source)
		end
		inst.Parent = parent
		count += 1
	end
	return count .. " instances"
end)

HttpService.HttpEnabled = wasEnabled
_G.BS_LOADING = nil
if not ok then
	error("studio-load: " .. tostring(result))
end
print("loaded blind-spot: " .. result)
return "loaded blind-spot: " .. result
