type properties = {
	colour: Color3,
	material: Enum.Material,
	transparency: number,
}

local block_properties: {[string]: properties} = {
	birch_slab = {
		colour = Color3.new(0.83, 0.78, 0.55),
		material = Enum.Material.WoodPlanks,
		transparency = 0,
	},
	birch_stairs = {
		colour = Color3.new(0.83, 0.78, 0.55),
		material = Enum.Material.WoodPlanks,
		transparency = 0,
	},
	grass_block = {
		colour = Color3.new(0.31, 0.49, 0.27),
		material = Enum.Material.Grass,
		transparency = 0,
	},
	podzol = {
		colour = Color3.new(0.29, 0.18, 0.09),
		material = Enum.Material.Grass,
		transparency = 0,
	},
	sand = {
		colour = Color3.new(0.84, 0.80, 0.63),
		material = Enum.Material.Sand,
		transparency = 0,
	},
	sandstone = {
		colour = Color3.new(0.84, 0.80, 0.63),
		material = Enum.Material.Sandstone,
		transparency = 0,
	},
	sandstone_slab = {
		colour = Color3.new(0.84, 0.80, 0.63),
		material = Enum.Material.Sandstone,
		transparency = 0,
	},
	sandstone_stairs = {
		colour = Color3.new(0.84, 0.80, 0.63),
		material = Enum.Material.Sandstone,
		transparency = 0,
	},
	spruce_leaves = {
		colour = Color3.new(0.22, 0.34, 0.22),
		material = Enum.Material.Grass,
		transparency = 0.375,
	},
	spruce_slab = {
		colour = Color3.new(0.43, 0.32, 0.18),
		material = Enum.Material.Wood,
		transparency = 0,
	},
	spruce_stairs = {
		colour = Color3.new(0.43, 0.32, 0.18),
		material = Enum.Material.Wood,
		transparency = 0,
	},
	stone_brick_slab = {
		colour = Color3.new(0.49, 0.49, 0.49),
		material = Enum.Material.Brick,
		transparency = 0,
	},
	stone_brick_stairs = {
		colour = Color3.new(0.49, 0.49, 0.49),
		material = Enum.Material.Brick,
		transparency = 0,
	},
	stone_stairs = {
		colour = Color3.new(0.49, 0.49, 0.49),
		material = Enum.Material.Basalt,
		transparency = 0,
	},
	stripped_birch_wood = {
		colour = Color3.new(0.65, 0.59, 0.40),
		material = Enum.Material.Wood,
		transparency = 0,
	},
	suspicious_sand = {
		colour = Color3.new(0.70, 0.66, 0.53),
		material = Enum.Material.Sand,
		transparency = 0,
	},
	water = {
		colour = Color3.new(0.23, 0.39, 0.71),
		material = Enum.Material.Sand,
		transparency = 0.1,
	},
}

return block_properties
