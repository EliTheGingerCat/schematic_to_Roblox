local StudioService = game:GetService("StudioService")

local button = require("./button")
local create_model = require("../modules/create_model")
local Fusion = require(script.Parent.Parent.roblox_packages.fusion)
local progress_signal = require("../modules/progress_signal")
local text = require("./text")

type real_composition_section = {
	name: string,
	elapsed: number,
}

-- This is based on anecdotal evidence.
-- This is what fraction of the time is spent up to that point.
type composition_section = {
	name: string,
	fraction: number,
	description: string,
}
local composition: {composition_section} = {
	{
		name = "unzip",
		fraction = 0.000,
		description = "Unzipping.",
	},
	{
		name = "nbt",
		fraction = 0.023,
		description = "Decoding named-binary-tag.",
	},
	{
		name = "schematic",
		fraction = 0.024,
		description = "Decoding schematic.",
	},
	{
		name = "palette",
		fraction = 0.025,
		description = "Moving palette information directly to blocks.",
	},
	{
		name = "greedy",
		fraction = 0.744,
		description = "Greedy meshing.",
	},
	{
		name = "model",
		fraction = 0.758,
		description = "Creating the Roblox model.",
	},
}
local name_to_index: {[string]: number} = {}
for index, section in composition do
	name_to_index[section.name] = index
end

local do_output_composition = true -- Should be a setting.

local colour_green = Color3.fromRGB(191, 255, 117)
local colour_gray = Color3.fromRGB(56, 56, 56)
local colour_purple = Color3.new(0.3, 0.1, 0.4)

local function main(scope: Fusion.Scope<typeof(Fusion)>)
	local current_file_name = scope:Value("None")
	local progress_fraction = scope:Value(0)
	local progress_description = scope:Value("")
	local estimated_time_remaining = scope:Value(0)

	local progress_fraction_spring = scope:Spring(progress_fraction, 25)
	
	local is_loading = false
	local current_file: File?
	
	return scope:New "Frame" {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Fusion.Children] = {
			scope:New "UIListLayout" {
				SortOrder = Enum.SortOrder.LayoutOrder
			},
			button(scope, {
				Text = "Select file",
				Size = UDim2.new(1, 0, 0, 50),
				AutoButtonColor = true,
				on_click = function()
					local success, result = pcall(StudioService.PromptImportFile, StudioService, {"schematic", "schem"})
					if success and result then
						current_file = result
						current_file_name:set(result.Name)
					end
				end
			}),
			button(scope, {
				Text = "Convert",
				Size = UDim2.new(1, 0, 0, 50),
				AutoButtonColor = true,
				on_click = function()
					if is_loading then
						return
					end
					if current_file == nil then
						return
					end
					is_loading = true

					local time_start = os.clock()
					local real_composition_elapsed: {real_composition_section} = {}
					local last_section: string? = nil

					local function on_progress(section_name: string, sub_progress: number?): ()
						local time_now = os.clock()
						local time_elapsed = time_now - time_start
						if section_name ~= last_section then
							table.insert(real_composition_elapsed, {
								name = section_name,
								elapsed = time_elapsed,
							})
						end
						if sub_progress == 1 then
							table.insert(real_composition_elapsed, {
								name = section_name .. " done",
								elapsed = time_elapsed,
							})
						end
						last_section = section_name

						local section_index = name_to_index[section_name]
						local section: composition_section? = composition[section_index]

						if section == nil then
							print(`[Schematic to Roblox] Unknown reason "{section_name}".`)
							return
						end

						local fraction = section.fraction
						local fraction_precise: number
						if sub_progress ~= nil then
							local next_section_index = section_index + 1
							local next_section: composition_section? = composition[next_section_index]
							local next_fraction: number
							if next_section ~= nil then
								next_fraction = next_section.fraction
							else
								next_fraction = 1
							end
							local fraction_difference = next_fraction - fraction

							fraction_precise = fraction + fraction_difference * sub_progress
						else
							fraction_precise = fraction
						end

						-- time total * fraction precise = time elapsed
						-- time total = time elapsed / fraction precise

						-- time remaining = time total - time elapsed
						-- time remaining = time elapsed / fraction precise - time elapsed
						local time_remaining = time_elapsed / fraction_precise - time_elapsed

						progress_fraction:set(fraction_precise)
						progress_description:set(section.description)
						estimated_time_remaining:set(time_remaining)
						task.wait()
					end

					table.insert(scope, progress_signal:Connect(on_progress))
					
					create_model(buffer.fromstring(current_file:GetBinaryContents()), current_file.Name)

					local time_end = os.clock()
					local total_elapsed = time_end - time_start
					local real_composition_fraction: {string} = {}
					for _, data in real_composition_elapsed do
						table.insert(real_composition_fraction, `{data.name}: {data.elapsed / total_elapsed}`)
					end

					if do_output_composition == true then
						print("composition:", real_composition_fraction)
						print("total time (s):", total_elapsed)
					end

					progress_fraction:set(0)
					progress_description:set("")
					estimated_time_remaining:set(0)
					is_loading = false
				end
			}),
			text(scope, {
				BackgroundColour = colour_gray,
				Size = UDim2.new(1, 0, 0, 50),
				Text = scope:Computed(function(use)
					return `Selected: {use(current_file_name)}`
				end)
			}),
			text(scope, {
				BackgroundColour = colour_purple,
				Size = UDim2.new(1, 0, 0, 40),
				Text = scope:Computed(function(use)
					local description = use(progress_description)
					if description == "" then
						return ""
					end

					return "Current operation: " .. description
				end),
				Visible = scope:Computed(function(use)
					return use(progress_fraction) ~= 0
				end),
			}),
			text(scope, {
				BackgroundColour = colour_purple,
				Size = UDim2.new(1, 0, 0, 20),
				Text = scope:Computed(function(use)
					local fraction = use(progress_fraction)
					if fraction == 0 then
						return ""
					end

					return string.format("Estimated progress (fraction): %0.2f", fraction)
				end),
				Visible = scope:Computed(function(use)
					return use(progress_fraction) ~= 0
				end),
			}),
			text(scope, {
				BackgroundColour = colour_purple,
				Size = UDim2.new(1, 0, 0, 20),
				Text = scope:Computed(function(use)
					local remaining = use(estimated_time_remaining)
					if remaining == 0 then
						return ""
					end

					return string.format("Estimated time remaining (s): %0.2f", remaining)
				end),
				Visible = scope:Computed(function(use)
					return use(progress_fraction) ~= 0
				end),
			}),
			scope:New "Frame" {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = colour_purple,
				LayoutOrder = 2,
				Visible = scope:Computed(function(use)
					return use(progress_fraction) ~= 0
				end),
				[Fusion.Children] = {
					scope:New "UIPadding" {
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 5),
						PaddingBottom = UDim.new(0, 5)
					},
					scope:New "Frame" {
						Size = scope:Computed(function(use)
							return UDim2.fromScale(use(progress_fraction_spring), 1)
						end),
						BackgroundColor3 = colour_green,
					}
				}
			},
		}
	}
end

return main
