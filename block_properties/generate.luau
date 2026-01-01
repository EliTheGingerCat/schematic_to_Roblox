local fs = require("@lune/fs")

local png_luau = require("../vendor/png-luau")

local directory = "./block_properties/textures"

local text_pieces: {string} = {}

local function is_PNG(file_name: string): boolean
	return string.sub(file_name, -4, -1) == ".png"
end

for _, file_name in fs.readDir(directory) do
	if is_PNG(file_name) == false then
		continue
	end

	local block_name = string.sub(file_name, 1, -5)

	local path = `{directory}/{file_name}`
	local content = buffer.fromstring(fs.readFile(path))

	local image = png_luau.decode(content)
	local width = image.width
	local height = image.height

	-- It is not truly total since colour channels are multiplied by their transparency.
	local total_red = 0
	local total_green = 0
	local total_blue = 0
	local total_alpha = 0
	local total_pixel = width * height

	for c1 = 1, width do
		for c2 = 1, height do
			local pixel = image.readPixel(c1, c2)
			-- Multiply by alpha to make it proportional based on transparency. An opaque pixel should contribute more to average colour than a translucent one.
			local alpha_fraction = pixel.a / 255
			total_red += pixel.r * alpha_fraction
			total_green += pixel.g * alpha_fraction
			total_blue += pixel.b * alpha_fraction
			total_alpha += alpha_fraction
		end
	end

	-- Divide by 255 since the components were actually in the range [0, 255]. Alpha was already accounted for in the loop.
	local proportion_red = total_red / total_pixel / 255
	local proportion_green = total_green / total_pixel / 255
	local proportion_blue = total_blue / total_pixel / 255
	local proportion_alpha = total_alpha / total_pixel

	-- Can not use @lune/serde since Color3 is Roblox-specific. I have not checked, but if serde supports `__tostring`, perhaps creating a Color3 object would be worth it.
	local text = (
		           "\t" .. `{block_name} = \{`
		.. "\n" .. "\t" .. "\t" .. `colour = Color3.new({proportion_red}, {proportion_green}, {proportion_blue}),`
		.. "\n" .. "\t" .. "\t" .. `transparency = {proportion_alpha},`
		.. "\n" .. "\t" .. "},"
		.. "\n"
	)

	table.insert(text_pieces, text)
end

local text_final = (
	           "local block_properties = {"
	.. "\n" .. table.concat(text_pieces)
	..         "}" -- The text pieces add an extra newline.
	.. "\n"
	.. "\n" .. "return block_properties"
	.. "\n"
)

fs.writeFile("./block_properties/output.luau", text_final)
