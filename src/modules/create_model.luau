local assets = script.Parent.Parent.assets
local block_properties = require("./block_properties")
local progress_signal = require("./progress_signal")
local schematic = require("./schematic")

type cuboid = schematic.cuboid
type properties = block_properties.properties

local block_size = 3
local directions = {
	bottom = {
		east = Vector3.new(0, 90, 0),
		south = Vector3.new(0, 0, 0),
		west = Vector3.new(0, -90, 0),
		north = Vector3.new(0, -180, 0),
		up = Vector3.new(0, 0, 0),
		down = Vector3.new(0, 0, 0),
	},
	top = {
		east = Vector3.new(0, 90, 180),
		south = Vector3.new(0, 0, 180),
		west = Vector3.new(-90, -90, 0),
		north = Vector3.new(0, 180, 180),
		up = Vector3.new(0, 0, 0),
		down = Vector3.new(0, 0, 0),
	},
}

local blocks_warned: {[string]: true} = {}

local function is_stair(block: cuboid): boolean
	return string.find(block.properties.name, "stair") ~= nil
end

local function is_corner_stair(block: cuboid): boolean
	-- assuming block is a stair
	return block.properties.shape ~= "straight"
end

local function is_inner_corner_stair(block: cuboid): boolean
	local shape = block.properties.shape
	return shape == "inner_left" or shape == "inner_right"
end

local function is_slab(block: cuboid): boolean
	return string.find(block.properties.name, "slab") ~= nil
end

local function get_part(block: cuboid): BasePart
	if is_stair(block) then
		if is_corner_stair(block) then
			if is_inner_corner_stair(block) then
				return assets.corner_stair_inner:Clone()
			else
				return assets.corner_stair_outer:Clone()
			end
		else
			return assets.stair:Clone()
		end
	elseif is_slab(block) then
		return assets.slab:Clone()
	else
		return Instance.new("Part")
	end
end

local function create_model(data: buffer, name: string?): ()
	local user_schematic = schematic.decode(data)

	local blocks = user_schematic:greedy_mesh()

	local total = #blocks

	local destination = Instance.new("Model")
	if name ~= nil then
		destination.Name = `Ported schematic - {name}`
	else
		destination.Name = "Ported schematic"
	end
	destination.Parent = workspace
	
	progress_signal:FireSync("model", 0)
	
	for count, block in blocks do
		-- props_m = properties Minecraft
		local block_name, props_m = block.properties.name, block.properties
		
		local part = get_part(block)
		if is_slab(block) then
			if props_m.type == "bottom" then
				part.Position = Vector3.new(block.position[1] * 3, block.position[2] * 3 - 0.75, block.position[3] * 3)
			else
				part.Position = Vector3.new(block.position[1] * 3, block.position[2] * 3 + 0.75, block.position[3] * 3)
			end
			block.size[2] = 0.5
		else
			part.Position = Vector3.new(block.position[1] * 3, block.position[2] * 3, block.position[3] * 3)
		end
		part.Anchored = true
		part.Name = block_name
		part.Size = Vector3.new(table.unpack(block.size)) * block_size
		
		-- props_R = properties_Roblox
		local props_R = block_properties[block_name] :: properties?
		if props_R ~= nil then
			part.Color = props_R.colour
			part.Transparency = props_R.transparency

			if props_R.material ~= nil then
				part.Material = props_R.material
			end
		elseif blocks_warned[block_name] == nil then
			blocks_warned[block_name] = true
			print(`[Schematic to Roblox] Block "{block_name}" does not have any Roblox properties and will appear gray.`)
		end
		
		if is_stair(block) and is_corner_stair(block) then
			local orientation = CFrame.new()
			
			if props_m.facing == "east" then
				orientation *= CFrame.Angles(0, math.rad(90), 0)
			elseif props_m.facing == "south" then
				orientation *= CFrame.Angles(0, math.rad(180), 0)
			elseif props_m.facing == "west" then
				orientation *= CFrame.Angles(0, math.rad(-90), 0)
			end

			if props_m.shape ~= "inner_right" and props_m.shape ~= "outer_right" then
				orientation *= CFrame.Angles(0, math.rad(90), 0)
			end
			
			if props_m.half == "top" then
				orientation *= CFrame.Angles(0, math.rad(-90), math.rad(180))
			end
			
			if props_m.shape == "inner_right" and props_m.facing ~= "east" and props_m.facing ~= "west" then
				orientation *= CFrame.Angles(0, math.rad(180), 0)
			end
			
			part.CFrame *= orientation
		elseif props_m.half and props_m.facing then
			part.Orientation = directions[props_m.half][props_m.facing]
		end

		part.Parent = destination
		
		if count % 1000 == 0 then
			progress_signal:FireSync("model", count / total)
		end
	end
end

return create_model
