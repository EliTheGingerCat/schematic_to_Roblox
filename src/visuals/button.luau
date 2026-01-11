local Fusion = require(script.Parent.Parent.roblox_packages.fusion)

type UsedAs<T> = Fusion.UsedAs<T>

type props = {
	AnchorPoint: UsedAs<Vector2>?,
	AutoButtonColor: UsedAs<boolean>?,
	Position: UsedAs<UDim2>?,
	Size: UsedAs<UDim2>?,
	Text: UsedAs<string>?,
	
	on_click: () -> ()?,
}

local function button(scope: Fusion.Scope<typeof(Fusion)>, props: props)
	return scope:New "TextButton" {
		Size = props.Size or UDim2.fromOffset(200, 50),
		BackgroundColor3 = Color3.fromRGB(191, 255, 117),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Text = props.Text,
		AutoButtonColor = props.AutoButtonColor,
		[scope.OnEvent "MouseButton1Click"] = function()
			if props.on_click then
				props.on_click()
			end
		end
	}
end

return button
