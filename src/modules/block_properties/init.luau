local generated = require("@self/generated")
local manual = require("@self/manual")

export type properties = {
	colour: Color3,
	material: Enum.Material?, -- does not exist in generated
	transparency: number,
}

local block_properties: {[string]: properties} = table.clone(generated) :: any

for name, properties in manual do
	block_properties[name] = properties
end

return block_properties
