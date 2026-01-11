local Fusion = require(script.Parent.Parent.roblox_packages.fusion)

type UsedAs<T> = Fusion.UsedAs<T>

type props = {
	AnchorPoint: UsedAs<Vector2>?,
	BackgroundColour: UsedAs<Color3>?,
	Position: UsedAs<UDim2>?,
	Size: UsedAs<UDim2>?,
	Text: UsedAs<string>?,
	Visible: UsedAs<boolean>?,
}

local function text(scope: Fusion.Scope<typeof(Fusion)>, props: props)
	return scope:New "TextLabel" {
		Size = props.Size or UDim2.fromOffset(200, 50),
		BackgroundColor3 = props.BackgroundColour or Color3.fromRGB(56, 56, 56),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Text = props.Text,
		TextWrapped = true,
		Visible = props.Visible,
	}
end

return text
