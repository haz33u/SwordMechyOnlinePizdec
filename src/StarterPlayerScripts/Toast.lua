--!strict
--[[
	Toast notifications — bottom-left stack, large pixel font.
	Used for all Remotes.Notify (loot, kills, unlocks, errors, etc.).
]]

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local COLORS = {
	green = T.Good,
	red = T.Bad,
	gold = T.Accent,
	orange = Color3.fromRGB(255, 160, 60),
	purple = Color3.fromRGB(180, 120, 255),
	cyan = T.Info,
	pink = Color3.fromRGB(255, 140, 200),
	yellow = Color3.fromRGB(255, 220, 80),
	default = T.AccentGlow,
}

local Toast = {}

function Toast.Mount(gui: ScreenGui)
	local host = Instance.new("Frame")
	host.Name = "ToastLayer"
	host.BackgroundTransparency = 1
	host.BorderSizePixel = 0
	-- Bottom-left corner (above mobile safe / jump buttons area)
	host.Size = UDim2.new(0, 420, 0, 0)
	host.Position = UDim2.new(0, 16, 1, -24)
	host.AnchorPoint = Vector2.new(0, 1)
	host.AutomaticSize = Enum.AutomaticSize.Y
	host.ZIndex = 200
	host.Parent = gui

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = host

	local order = 0
	local api = {}

	function api.Show(text: string, colorKey: string?)
		if type(text) ~= "string" or text == "" then
			return
		end
		order += 1
		local key = if type(colorKey) == "string" then colorKey else "default"
		local col = COLORS[key] or COLORS.default

		local card = Instance.new("Frame")
		card.Name = "Toast"
		card.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		card.BackgroundTransparency = 0.08
		card.BorderSizePixel = 0
		card.Size = UDim2.fromOffset(400, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.LayoutOrder = order
		card.ZIndex = 201
		card.Parent = host
		UIKit.Corner(card, 6)
		local stroke = UIKit.Stroke(card, col, 1.5, 0.35)
		UIKit.Pad(card, 12)

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Font = T.Font.Title
		label.TextSize = 18
		label.TextColor3 = col
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextWrapped = true
		label.Text = text
		label.ZIndex = 202
		label.Parent = card

		-- slide-ish appear
		card.BackgroundTransparency = 1
		label.TextTransparency = 1
		if stroke then
			stroke.Transparency = 1
		end
		task.spawn(function()
			for i = 1, 6 do
				local a = 1 - i / 6
				card.BackgroundTransparency = 0.08 + a * 0.5
				label.TextTransparency = a
				if stroke then
					stroke.Transparency = 0.35 + a * 0.5
				end
				task.wait(0.02)
			end
			card.BackgroundTransparency = 0.08
			label.TextTransparency = 0
			if stroke then
				stroke.Transparency = 0.35
			end
		end)

		task.delay(3.2, function()
			if card.Parent then
				for i = 1, 8 do
					local a = i / 8
					card.BackgroundTransparency = 0.08 + a * 0.9
					label.TextTransparency = a
					if stroke then
						stroke.Transparency = 0.35 + a * 0.65
					end
					task.wait(0.02)
				end
				card:Destroy()
			end
		end)
	end

	return api
end

return Toast
