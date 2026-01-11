local plugin: Plugin = plugin

local Fusion = require(script.Parent.roblox_packages.fusion)
local main = require("./visuals/main")

local scope: Fusion.Scope<typeof(Fusion)>? = nil

local toolbar = plugin:CreateToolbar("Schematic to Roblox")
local button = toolbar:CreateButton("Schematic to Roblox", "Open the graphical user interface.", "")

local widget = plugin:CreateDockWidgetPluginGuiAsync("schematic_to_Roblox", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	false,
	false,
	200,
	200
	)
)
widget.Title = "Schematic to Roblox"
widget.Name = "schematic_to_Roblox"

if widget.Enabled and scope == nil then
	scope = Fusion:scoped()
	assert(scope, "analysis")
	local visual = main(scope)
	visual.Parent = widget
end

local function on_close(): ()
	button.Enabled = false
	button.Enabled = true
	if scope then
		Fusion.doCleanup(scope)
		scope = nil
	end
end

widget:BindToClose(on_close)

local function on_click(): ()
	if scope then
		Fusion.doCleanup(scope)
		widget.Enabled = false
		scope = nil
	else
		scope = Fusion:scoped()
		assert(scope, "analysis")
		local visual = main(scope)
		visual.Parent = widget
		widget.Enabled = true
	end
end

button.Click:Connect(on_click)
