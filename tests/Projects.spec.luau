--!strict
-- Rojo first (Adrien, 11 Nov). Three project files, one job each: game.project.json is what `rojo serve` syncs live
-- (code only: Rojo's plugin cannot write MeshPart.MeshId, so models never go through serve), models.project.json is
-- what `rojo syncback` writes from a saved place (the models only, never src/), build.project.json is the gate's
-- `rojo build` (both). Written by hand, so this spec keeps them from drifting apart.
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local function ok(v: any, what: string)
	if not v then
		error(what, 2)
	end
end

local function read(path: string): any
	return serde.decode("json", fs.readFile(path))
end

-- every node that carries a $path, as "Parent.Child" -> its path (an optional path counts as its path)
local function paths(tree: any): { [string]: string }
	local out: { [string]: string } = {}
	local function walk(node: any, at: string)
		for key, child in node do
			if type(child) == "table" and string.sub(key, 1, 1) ~= "$" then
				local here = if at == "" then key else at .. "." .. key
				local p = child["$path"]
				if type(p) == "table" then
					p = p.optional
				end
				if p then
					out[here] = p
				end
				walk(child, here)
			end
		end
	end
	walk(tree, "")
	return out
end

local function count(t: { [string]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local game = paths(read("game.project.json").tree)
local models = paths(read("models.project.json").tree)
local build = paths(read("build.project.json").tree)

local spec = {}

function spec.theBuildHasAllTheCodeAndAllTheModels()
	for node, p in game do
		ok(build[node] == p, `build.project.json lacks {node} -> {p} from game.project.json`)
	end
	for node, p in models do
		ok(build[node] == p, `build.project.json lacks {node} -> {p} from models.project.json`)
	end
	ok(count(build) == count(game) + count(models), "build.project.json has a node in neither of the other two")
end

function spec.serveSyncsNoModels()
	for node, p in game do
		ok(string.sub(p, 1, 4) == "src/", `game.project.json syncs {node} from {p}: live sync is for code only`)
	end
end

function spec.syncbackNeverWritesCode()
	for node, p in models do
		ok(string.sub(p, 1, 12) == "assets/rbxm/", `models.project.json would write {node} into {p}`)
	end
end

function spec.modelsAreOptionalInTheBuild()
	-- the gate stays green before the first export and on a fresh clone
	local tree = read("build.project.json").tree
	for node in models do
		local at: any = tree
		for part in string.gmatch(node, "[^.]+") do
			at = at[part]
		end
		ok(type(at["$path"]) == "table" and at["$path"].optional, `{node} must use an optional $path in the build`)
	end
end

return spec
