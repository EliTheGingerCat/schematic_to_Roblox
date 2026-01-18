-- https://minecraft.wiki/w/Schematic_file_format

local named_binary_tag = require("./named_binary_tag")
local progress_signal = require("./progress_signal")
local zip = require("./zip")

local prototype = {}

--[=[
	@class Schematic

	A Minecraft world fit with blocks and entities.
]=]
local Schematic = {
	prototype = prototype
}

local metatable = {
	__index = prototype
}

--[=[
	@within Schematic
	@prop Width number
	@readonly
	@since v0.1.0
	The size on the x axis.
]=]
--[=[
	@within Schematic
	@prop Height number
	@readonly
	@since v0.1.0
	The size on the y axis.
]=]
--[=[
	@within Schematic
	@prop Length number
	@readonly
	@since v0.1.0
	The size on the z axis.
]=]
--[=[
	@within Schematic
	@prop Blocks {[number]: properties}
	@readonly
	@since v0.1.0
	Each index corresponds to the table of properties that describes the block, taken from the palette.
]=]
--[=[
	@within Schematic
	@prop DataVersion tagInt
	@readonly
	@since v0.1.0
]=]
--[=[
	@within Schematic
	@prop BlockEntities tagList<tagCompound>
	@readonly
	@since v0.1.0
]=]
--[=[
	@within Schematic
	@prop Metadata tagCompound
	@readonly
	@since v0.1.0
]=]
--[=[
	@within Schematic
	@prop Offset tagIntArray
	@readonly
	@since v0.1.0
]=]
--[=[
	@within Schematic
	@prop Version tagInt
	@readonly
	@since v0.1.0
]=]
local _

export type Schematic = typeof(setmetatable({} :: {
	Width: number,
	Height: number,
	Length: number,
	Blocks: {
		[number]: properties
	}
}, metatable))

--[=[
	@within Schematic
	@interface cuboid
	.position vector
	.size vector
	.properties string
]=]
export type cuboid = {
	position: {number},
	size: {number},
	properties: properties
}

--[[
	@within Schematic
	@interface properties
	.name string
	.axis nil | "x" | "y" | "z"
	.distance number
	.facing nil | "north" | "east" | "south" | "west"
	.half nil | "bottom" | "top"
	.hinge nil | "left" | "right"
	.occupied nil | boolean
	.open nil | boolean
	.part nil | "foot" | "head"
	.powered nil | boolean
	.shape nil | "inner_left" | "inner_right" | "outer_left" | "outer_right" | "straight"
	.type nil | "bottom" | "top" | "double"
	.waterlogged nil | boolean
]]
export type properties = {
	name: string,
	
	axis: nil | "x" | "y" | "z",
	distance: number,
	facing: nil | "north" | "east" | "south" | "west",
	half: nil | "bottom" | "lower" | "top" | "upper",
	hinge: nil | "left" | "right",
	occupied: nil | boolean,
	open: nil | boolean,
	part: nil | "foot" | "head",
	powered: nil | boolean,
	shape: nil | "inner_left" | "inner_right" | "outer_left" | "outer_right" | "straight",
	type: nil | "bottom" | "top" | "double",
	waterlogged: nil | boolean
}

type schematic_tag_simple = {
	BlockData: {number},
	BlockEntities: {},
	DataVersion: number,
	Entities: {},
	Height: number,
	Length: number,
	Palette: {[string]: number},
	PaletteMax: number,
	Version: number,
	Width: number,
}

type schematic_tag_nested = {
	Schematic: {
		Blocks: {
			Data: {number},
			Palette: {
				[string]: number
			}
		},
		Height: number,
		Length: number,
		Version: number,
		Width: number
	}
}

type normalised = {
	Blocks: {number},
	Height: number,
	Length: number,
	Palette: {[string]: number},
	Width: number,
}

type mess = {
	indexPalette: number,
	properties: properties
}

type same = {
	indexMess: number,
	indexPalette: number
}

local properties_remove = {
	"distance", -- how far leaf is from log (affects decaying)
	"persistent" -- whether leaf was placed by player (will not decay)
}

local function table_simple_equal<K, V>(t1: {[K]: V}, t2: {[K]: V}): boolean
	for i1, vi in t1 do
		if t2[i1] ~= vi then
			return false
		end
	end
	for i2, v2 in t2 do
		-- t2 might have keys that t1 does not have
		if t1[i2] == nil then
			return false
		end
	end
	return true
end

local error_not_recognised = "The provided schematic format is not recognised. This can happen since there are multiple different schematic formats in use. Please create a GitHub issue and provide the schematic file, preferably using as small as an example as possible (such as a single block). In the meantime, you can try printing the root tag and investigating its structure to support this schematic's format."

local function assert_or_not_recognised<T>(value: T): T
	return assert(value, error_not_recognised)
end

local function normalise(root_any: any): normalised
	if root_any.BlockData ~= nil then
		local root: schematic_tag_simple = root_any

		return {
			Blocks = root.BlockData,
			Height = assert_or_not_recognised(root.Height),
			Length = assert_or_not_recognised(root.Length),
			Palette = assert_or_not_recognised(root.Palette),
			Width = assert_or_not_recognised(root.Width),
		}
	elseif root_any.Schematic ~= nil then
		local root: schematic_tag_nested = root_any

		return {
			Blocks = assert_or_not_recognised(root.Schematic.Blocks.Data),
			Height = assert_or_not_recognised(root.Schematic.Height),
			Length = assert_or_not_recognised(root.Schematic.Length),
			Palette = assert_or_not_recognised(root.Schematic.Blocks.Palette),
			Width = assert_or_not_recognised(root.Schematic.Width),
		}
	else
		error(error_not_recognised)
	end
end

--[=[
	@within Schematic
	@since v0.1.0
]=]
function Schematic.decode(data: buffer): Schematic
	local root = named_binary_tag.decode(
		zip.decode(data)
	).payload

	progress_signal:FireSync("schematic")

	local normalised = normalise(root)

	-- set palette to use property tables
	local palette = {}
	
	-- fix property tables that use blacklisted properties (these mess up greedy meshing)
	local messed_up: {mess} = {}
	
	for name_full, index in normalised.Palette do
		name_full = name_full:sub(11) -- remove "minecraft:"
		if name_full == "air" then
			continue
		end

		local properties = {} :: properties

		local index_bracket = name_full:find("%[")
		local name_main
		-- Not all blocks have properties.
		if index_bracket ~= nil then
			name_main = string.sub(name_full, 1, index_bracket - 1)
			-- Skip to parts in between [ and ]
			local pairs = string.split(
				string.sub(name_full, index_bracket + 1, -2),
				","
			)
			for _, pair in pairs do
				local split = pair:split("=")
				
				local key = split[1]
				if table.find(properties_remove, key) then
					-- Technically if there are multiple blacklisted properties then it will be inserted into messed_up multiple times, but the algorithm to fix these messes does not care.
					table.insert(messed_up, {
						indexPalette = index,
						properties = properties
					})
					continue
				end
				
				local value: string | boolean = split[2]
				if value == "true" then
					value = true
				elseif value == "false" then
					value = false
				end
				properties[key] = value
			end
		else
			name_main = name_full
		end

		properties.name = name_main

		palette[index] = properties
	end
	
	local same: {same} = {}
	while true do
		local m1 = messed_up[1]
		if m1 == nil then
			break
		end
		
		table.clear(same)
		
		for index, m2 in messed_up do
			if table_simple_equal(m1.properties, m2.properties) then
				table.insert(same, {
					indexMess = index,
					indexPalette = m2.indexPalette
				})
			end
		end
		
		local index = 0
		while true do
			index += 1
			local item: same? = same[index]
			if item == nil then
				break
			end
			
			table.remove(messed_up, item.indexMess - index + 1)
			-- If the property tables are equal once the blacklisted properties are removed, then make the palette point to the same table so that the blocks will be equal for greedy meshing.
			palette[item.indexPalette] = m1.properties
		end
	end

	-- Set blocks to their property table.
	local blocks = {}
	local total_blocks = #normalised.Blocks
	progress_signal:FireSync("palette", 0)
	for id, paintId in normalised.Blocks do
		blocks[id] = palette[paintId]

		if id % 1000 == 0 then
			progress_signal:FireSync("palette", id / total_blocks)
		end
	end
	progress_signal:FireSync("palette", 1)

	return setmetatable({
		Width = normalised.Width,
		Height = normalised.Height,
		Length = normalised.Length,
		Blocks = blocks
	}, metatable) :: any
end

--[=[
	@within Schematic
	@return -- The NBT index of the block.
	@since v0.1.0
]=]
function prototype.get_block_index(self: Schematic, x: number, y: number, z: number): number
	return ((y-1)*self.Length + (z-1)) * self.Width + (x-1) + 1
end

--[=[
	@within Schematic
	@param index -- The NBT index of the block.
	@return vector<3>
	@since v0.1.0
]=]
function prototype.get_block_position(self: Schematic, index: number): {number}
	index -= 1
	local x = index % self.Width + 1
	local y = math.floor(index / (self.Width * self.Length)) % self.Height + 1
	local z = math.floor(index / self.Width) % self.Length + 1
	return {x, y, z}
end

--[=[
	@within Schematic
	@since v0.1.0
]=]
function prototype.greedy_mesh(self: Schematic): {cuboid}
	progress_signal:FireSync("greedy")
	local cuboids: {cuboid} = {}
	local visited: {[number]: true} = {}
	for index, properties in self.Blocks do
		if visited[index] then
			continue
		end

		visited[index] = true
		local pos = self:get_block_position(index)
		local bounds = {
			{
				lower = pos[1],
				upper = pos[1],
			},
			{
				lower = pos[2],
				upper = pos[2],
			},
			{
				lower = pos[3],
				upper = pos[3],
			},
		}

		local extend = {true, true, true}
		if string.find(properties.name, "stair") then
			extend[2] = false
			if properties.facing == "east" or properties.facing == "west" then
				extend[3] = false
			else
				extend[1] = false
			end
		elseif string.find(properties.name, "slab") then
			if properties.type ~= "double" then
				extend[2] = false
			end
		end

		if extend[1] then
			for x = pos[1] + 1, self.Width do
				local index2 = self:get_block_index(x, pos[2], pos[3])
				if visited[index2] or self.Blocks[index2] ~= properties then
					break
				else
					visited[index2] = true
					bounds[1].upper += 1
				end
			end

			for x = pos[1] - 1, 1, -1 do
				local index2 = self:get_block_index(x, pos[2], pos[3])
				if visited[index2] or self.Blocks[index2] ~= properties then
					break
				else
					visited[index2] = true
					bounds[1].lower -= 1
				end
			end
		end

		-- x bounds have been attained

		if extend[2] then
			for y = pos[2] + 1, self.Height do
				local success = true
				local indices = {}
				for x = bounds[1].lower, bounds[1].upper do
					local index2 = self:get_block_index(x, y, pos[3])
					if visited[index2] or self.Blocks[index2] ~= properties then
						success = false
						break
					else
						table.insert(indices, index2)
					end
				end
				if not success then
					break
				end
				for _, index2 in indices do
					visited[index2] = true
				end
				bounds[2].upper += 1
			end

			for y = pos[2] - 1, 1, -1 do
				local success = true
				local indices = {}
				for x = bounds[1].lower, bounds[1].upper do
					local index2 = self:get_block_index(x, y, pos[3])
					if visited[index2] or self.Blocks[index2] ~= properties then
						success = false
						break
					else
						table.insert(indices, index2)
					end
				end
				if not success then
					break
				end
				for _, index2 in indices do
					visited[index2] = true
				end
				bounds[2].lower -= 1
			end
		end

		-- y bounds have been attained

		if extend[3] then
			for z = pos[3] + 1, self.Length do
				local success = true
				local indices = {}
				for y = bounds[2].lower, bounds[2].upper do
					for x = bounds[1].lower, bounds[1].upper do
						local index2 = self:get_block_index(x, y, z)
						if visited[index2] or self.Blocks[index2] ~= properties then
							success = false
							break
						else
							table.insert(indices, index2)
						end
					end
					if not success then
						break
					end
				end
				if not success then
					break
				end
				for _, index2 in indices do
					visited[index2] = true
				end
				bounds[3].upper += 1
			end

			for z = pos[3] - 1, 1, -1 do
				local success = true
				local indices = {}
				for y = bounds[2].lower, bounds[2].upper do
					for x = bounds[1].lower, bounds[1].upper do
						local index2 = self:get_block_index(x, y, z)
						if visited[index2] or self.Blocks[index2] ~= properties then
							success = false
							break
						else
							table.insert(indices, index2)
						end
					end
					if not success then
						break
					end
				end
				if not success then
					break
				end
				for _, index2 in indices do
					visited[index2] = true
				end
				bounds[3].lower -= 1
			end
		end

		-- all bounds have been attained
		
		local cuboid = {
			size = {
				bounds[1].upper - bounds[1].lower + 1,
				bounds[2].upper - bounds[2].lower + 1,
				bounds[3].upper - bounds[3].lower + 1,
			},
			position = {
				(bounds[1].lower + bounds[1].upper) / 2,
				(bounds[2].lower + bounds[2].upper) / 2,
				(bounds[3].lower + bounds[3].upper) / 2,
			},
			properties = properties,
		}
		table.insert(cuboids, cuboid)
	end

	-- all cuboids have been attained

	return cuboids
end

return Schematic
