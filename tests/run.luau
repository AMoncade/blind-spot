--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")

local passed, failed = 0, 0

local function fail(name: string, err: any)
	failed += 1
	print(`FAIL {name}: {tostring(err)}`)
end

local specs: { string } = {}
for _, file in fs.readDir("tests") do
	if string.match(file, "%.spec%.luau$") then
		table.insert(specs, file)
	end
end
table.sort(specs)
if #specs == 0 then
	fail("tests", "no *.spec.luau files found (run from the repo root)")
end

for _, file in specs do
	local specName = string.gsub(file, "%.spec%.luau$", "")
	-- require is relative to this file: "./Name.spec" resolves to tests/Name.spec.luau
	local ok, spec = pcall(require, "./" .. string.gsub(file, "%.luau$", ""))
	if not ok then
		fail(specName .. " (load)", spec)
	elseif type(spec) ~= "table" then
		fail(specName .. " (load)", "spec must return a table")
	else
		local names: { string } = {}
		for name in spec do
			table.insert(names, name)
		end
		table.sort(names)
		if #names == 0 then
			fail(specName .. " (load)", "spec has no tests")
		end
		for _, name in names do
			local fn = spec[name]
			local full = `{specName}: {name}`
			if type(fn) ~= "function" then
				fail(full, "not a function")
			else
				local runOk, err = pcall(fn)
				if runOk then
					passed += 1
					print(`PASS {full}`)
				else
					fail(full, err)
				end
			end
		end
	end
end

print(`{passed} passed, {failed} failed`)
if failed > 0 then
	process.exit(1)
end
