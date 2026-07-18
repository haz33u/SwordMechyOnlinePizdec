--!strict

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local COLORS = {
	green = T.Good,
	red = T.Bad,
	gold = T.Accent,
	purple = Color3.fromRGB(180, 120, 255),
	cyan = T.Info,
	pink = Color3.fromRGB(255, 140, 200),
	default = T.AccentGlow,
}

local Toast = {}

function Toast.Mount(gui: ScreenGui)
	-- Top inset: Theme has no TopH (was nil + 18 → arithmetic error)
	local topPad = 56

	local host = UIKit.Glass({
		Name = "ToastLayer",
		Parent = gui,
		Size = UDim2.fromOffset(320, 0),
		Position = UDim2.new(0.5, 0, 0, topPad),
		Anchor = Vector2.new(0.5, 0),
		Radius = T.R.sm,
		Z = 90,
		Deep = true,
	})
	host.AutomaticSize = Enum.AutomaticSize.Y
	host.BackgroundTransparency = 1
	host.Visible = false
	UIKit.Pad(host, 12)

	local label = UIKit.Label({
		Parent = host,
		Text = "",
		Size = UDim2.new(1, 0, 0, 0),
		SizePx = 14,
		Font = T.Font.Title,
		X = Enum.TextXAlignment.Center,
		Wrap = true,
		Z = 91,
	})
	label.AutomaticSize = Enum.AutomaticSize.Y

	local token = 0
	local api = {}
	function api.Show(text: string, colorKey: string?)
		if type(text) ~= "string" or text == "" then
			return
		end
		token += 1
		local my = token
		local key = if type(colorKey) == "string" then colorKey else "default"
		local col = COLORS[key] or COLORS.default
		host.Visible = true
		host.BackgroundTransparency = 0
		label.Text = text
		label.TextColor3 = col
		local stroke = host:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = col
			stroke.Transparency = 0.45
		end
		task.delay(2.5, function()
			if token == my then
				label.Text = ""
				host.Visible = false
			end
		end)
	end
	return api
end

return Toast
