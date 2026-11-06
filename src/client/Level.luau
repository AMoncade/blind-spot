--!strict
-- The P3 the server builds (server Core/World), as the client sees it. With StreamingEnabled its children can arrive
-- after the model: Level.folder waits until a folder holds as many children as the server wrote in the model's
-- attribute (Lights, Cameras), or gives up after a few seconds with what is there.
local Level = {}

local TIMEOUT = 10

function Level.root(): Model
	return workspace:WaitForChild("P3") :: Model
end

function Level.folder(name: string): Instance
	local root = Level.root()
	local f = root:WaitForChild(name)
	local expected = root:GetAttribute(name)
	local t0 = os.clock()
	while type(expected) == "number" and #f:GetChildren() < expected and os.clock() - t0 < TIMEOUT do
		task.wait(0.1)
	end
	return f
end

return Level
