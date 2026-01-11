local fs = require("@lune/fs")
local stdio = require("@lune/stdio")

local schematic = require("./src/modules/schematic")

local function fail(name: string): ()
	error(`Test "{name}" failed.`)
end

for _, case in fs.readDir("./tests/data") do
	local input_string = fs.readFile(`./tests/data/{case}/input.schem`)
	local input = buffer.fromstring(input_string)
	local schematic_object = schematic.decode(input)
	local cuboids = schematic_object:greedy_mesh()
	local output = stdio.format(cuboids)
	
	local path_expected = `./tests/data/{case}/expected.txt`
	if fs.metadata(path_expected).exists == true then
		local expected = fs.readFile(path_expected)
		if output ~= expected then
			fail(case)
		end
	else
		fs.writeFile(path_expected, output)
		print(`Added new case "{case}".`)
	end
end

print("Success.")
