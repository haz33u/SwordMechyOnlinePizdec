--!strict
--[[
	UI primitives: glass panels, CTAs, metric chips with hierarchy + constraints.
]]

local TweenService = game:GetService("TweenService")
local T = require(script.Parent.Theme)

local UIKit = {}

local function tween(inst: Instance, props: { [string]: any }, dur: number?)
	TweenService:Create(inst, TweenInfo.new(dur or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

function UIKit.Corner(parent: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or T.R.md)
	c.Parent = parent
	return c
end

function UIKit.Stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or T.Stroke
	s.Thickness = thickness or 1.5
	s.Transparency = transparency ~= nil and transparency or T.StrokeA
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
end

function UIKit.Gradient(parent: Instance, c0: Color3, c1: Color3, rot: number?)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c0),
		ColorSequenceKeypoint.new(1, c1),
	})
	g.Rotation = rot or 90
	g.Parent = parent
	return g
end

function UIKit.Pad(parent: Instance, all: number?, l: number?, t: number?, r: number?, b: number?)
	local p = Instance.new("UIPadding")
	if all then
		p.PaddingTop = UDim.new(0, all)
		p.PaddingBottom = UDim.new(0, all)
		p.PaddingLeft = UDim.new(0, all)
		p.PaddingRight = UDim.new(0, all)
	else
		p.PaddingLeft = UDim.new(0, l or 0)
		p.PaddingTop = UDim.new(0, t or 0)
		p.PaddingRight = UDim.new(0, r or 0)
		p.PaddingBottom = UDim.new(0, b or 0)
	end
	p.Parent = parent
	return p
end

function UIKit.List(parent: Instance, gap: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, gap or 8)
	l.FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.Parent = parent
	return l
end

function UIKit.Scale(parent: Instance, s: number?): UIScale
	local sc = Instance.new("UIScale")
	sc.Scale = s or 1
	sc.Parent = parent
	return sc
end

function UIKit.SizeConstraint(parent: Instance, min: Vector2?, max: Vector2?)
	local c = Instance.new("UISizeConstraint")
	if min then
		c.MinSize = min
	end
	if max then
		c.MaxSize = max
	end
	c.Parent = parent
	return c
end

function UIKit.Aspect(parent: Instance, ratio: number?)
	local a = Instance.new("UIAspectRatioConstraint")
	a.AspectRatio = ratio or 1
	a.Parent = parent
	return a
end

function UIKit.TextConstraint(parent: Instance, minPx: number?, maxPx: number?)
	local c = Instance.new("UITextSizeConstraint")
	c.MinTextSize = minPx or 10
	c.MaxTextSize = maxPx or 28
	c.Parent = parent
	return c
end

function UIKit.Glass(props: {
	Name: string?,
	Parent: Instance?,
	Size: UDim2?,
	Position: UDim2?,
	Anchor: Vector2?,
	Radius: number?,
	Z: number?,
	Deep: boolean?,
	AccentBar: boolean?,
}): Frame
	local f = Instance.new("Frame")
	f.Name = props.Name or "Glass"
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	f.Size = props.Size or UDim2.fromScale(0.2, 0.1)
	if props.Position then
		f.Position = props.Position
	end
	if props.Anchor then
		f.AnchorPoint = props.Anchor
	end
	f.ZIndex = props.Z or 1
	f.ClipsDescendants = true
	if props.Parent then
		f.Parent = props.Parent
	end

	UIKit.Corner(f, props.Radius or T.R.md)
	UIKit.Stroke(f, T.Stroke, 1.5, T.StrokeA)
	if props.Deep then
		UIKit.Gradient(f, T.Surface2, T.Bg, 100)
	else
		UIKit.Gradient(f, T.Surface3, T.Surface2, 105)
	end

	if props.AccentBar then
		local bar = Instance.new("Frame")
		bar.Name = "AccentBar"
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = T.Gold
		bar.Size = UDim2.new(1, 0, 0, 3)
		bar.ZIndex = (props.Z or 1) + 1
		bar.Parent = f
		UIKit.Gradient(bar, T.GoldGlow, T.GoldDeep, 0)
	end

	return f
end

function UIKit.Label(props: {
	Name: string?,
	Parent: Instance?,
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	Anchor: Vector2?,
	Color: Color3?,
	SizePx: number?,
	Font: Enum.Font?,
	X: Enum.TextXAlignment?,
	Y: Enum.TextYAlignment?,
	Z: number?,
	Wrap: boolean?,
	Order: number?,
	Scaled: boolean?,
	MinText: number?,
	MaxText: number?,
}): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = props.Name or "Label"
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Text = props.Text or ""
	l.Size = props.Size or UDim2.new(1, 0, 0, 18)
	if props.Position then
		l.Position = props.Position
	end
	if props.Anchor then
		l.AnchorPoint = props.Anchor
	end
	l.TextColor3 = props.Color or T.Text
	l.TextSize = props.SizePx or 14
	l.Font = props.Font or T.Font.Body
	l.TextXAlignment = props.X or Enum.TextXAlignment.Left
	l.TextYAlignment = props.Y or Enum.TextYAlignment.Center
	l.ZIndex = props.Z or 2
	l.TextWrapped = props.Wrap == true
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.LayoutOrder = props.Order or 0
	l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	l.TextStrokeTransparency = 0.3
	if props.Scaled then
		l.TextScaled = true
		UIKit.TextConstraint(l, props.MinText or 10, props.MaxText or 28)
	end
	if props.Parent then
		l.Parent = props.Parent
	end
	return l
end

function UIKit.Button(props: {
	Name: string?,
	Parent: Instance?,
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	Anchor: Vector2?,
	Color: Color3?,
	Color2: Color3?,
	TextColor: Color3?,
	SizePx: number?,
	Radius: number?,
	Z: number?,
	Order: number?,
	Primary: boolean?,
	OnClick: (() -> ())?,
}): TextButton
	local b = Instance.new("TextButton")
	b.Name = props.Name or "Btn"
	b.AutoButtonColor = false
	b.Text = props.Text or ""
	b.Size = props.Size or UDim2.fromOffset(120, 48)
	if props.Position then
		b.Position = props.Position
	end
	if props.Anchor then
		b.AnchorPoint = props.Anchor
	end
	b.BackgroundColor3 = Color3.new(1, 1, 1)
	b.TextColor3 = props.TextColor or T.Text
	b.TextSize = props.SizePx or 15
	b.Font = T.Font.Title
	b.BorderSizePixel = 0
	b.ZIndex = props.Z or 3
	b.LayoutOrder = props.Order or 0
	b.TextStrokeColor3 = Color3.new(0, 0, 0)
	b.TextStrokeTransparency = 0.25
	if props.Parent then
		b.Parent = props.Parent
	end

	local c0 = props.Color or T.Surface3
	local c1 = props.Color2 or T.Surface2
	UIKit.Corner(b, props.Radius or T.R.md)
	UIKit.Stroke(b, props.Primary and T.Gold or T.Stroke, props.Primary and 2 or 1.4, props.Primary and 0.25 or 0.4)
	UIKit.Gradient(b, c0, c1, 100)
	UIKit.SizeConstraint(b, Vector2.new(64, 36), Vector2.new(400, 96))

	local sc = UIKit.Scale(b, 1)
	b.MouseEnter:Connect(function()
		tween(sc, { Scale = 1.06 }, 0.1)
	end)
	b.MouseLeave:Connect(function()
		tween(sc, { Scale = 1 }, 0.1)
	end)
	b.MouseButton1Down:Connect(function()
		tween(sc, { Scale = 0.96 }, 0.06)
	end)
	b.MouseButton1Up:Connect(function()
		tween(sc, { Scale = 1.06 }, 0.08)
	end)
	if props.OnClick then
		b.MouseButton1Click:Connect(props.OnClick)
	end
	return b
end

function UIKit.IconBtn(props: {
	Name: string?,
	Parent: Instance?,
	Glyph: string?,
	Size: UDim2?,
	Active: boolean?,
	Order: number?,
	Z: number?,
	OnClick: (() -> ())?,
}): TextButton
	local b = UIKit.Button({
		Name = props.Name,
		Parent = props.Parent,
		Text = props.Glyph or "·",
		Size = props.Size or UDim2.fromOffset(52, 52),
		Color = props.Active and T.GoldDeep or T.Surface3,
		Color2 = props.Active and Color3.fromRGB(180, 110, 30) or T.Surface2,
		TextColor = T.Text,
		SizePx = 15,
		Radius = T.R.md,
		Order = props.Order,
		Z = props.Z or 5,
		OnClick = props.OnClick,
	})
	UIKit.Aspect(b, 1)
	return b
end

--- Metric chip: unique color, icon, muted title, bold value
function UIKit.MetricChip(props: {
	Parent: Instance?,
	Key: string, -- Power | Cps | ...
	Title: string?,
	Value: string?,
	Order: number?,
	W: number?,
	H: number?,
}): Frame
	local meta = T.Metric[props.Key] or T.Metric.Power
	local w = props.W or 120
	local h = props.H or 52

	local chip = Instance.new("Frame")
	chip.Name = props.Key
	chip.BackgroundColor3 = Color3.new(1, 1, 1)
	chip.BorderSizePixel = 0
	chip.Size = UDim2.fromOffset(w, h)
	chip.LayoutOrder = props.Order or 0
	chip.ZIndex = 5
	chip.ClipsDescendants = true
	if props.Parent then
		chip.Parent = props.Parent
	end

	UIKit.Corner(chip, T.R.md)
	UIKit.Stroke(chip, meta.accent, 1.8, 0.25)
	UIKit.Gradient(chip, meta.fill0, meta.fill1, 110)
	UIKit.SizeConstraint(chip, Vector2.new(88, 40), Vector2.new(220, 72))
	UIKit.Pad(chip, nil, 10, 6, 8, 6)

	-- accent strip
	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.BorderSizePixel = 0
	strip.BackgroundColor3 = meta.accent
	strip.Size = UDim2.new(0, 4, 1, -8)
	strip.Position = UDim2.fromOffset(0, 4)
	strip.ZIndex = 6
	strip.Parent = chip
	UIKit.Corner(strip, 2)

	local icon = UIKit.Label({
		Name = "Icon",
		Parent = chip,
		Text = meta.icon,
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(1, -26, 0, 4),
		SizePx = 14,
		X = Enum.TextXAlignment.Center,
		Z = 7,
	})

	UIKit.Label({
		Name = "Title",
		Parent = chip,
		Text = props.Title or props.Key,
		Size = UDim2.new(1, -30, 0, 14),
		Position = UDim2.fromOffset(10, 4),
		Color = T.TextMuted,
		SizePx = 11,
		Font = T.Font.Title,
		Z = 6,
	})

	local value = UIKit.Label({
		Name = "Value",
		Parent = chip,
		Text = props.Value or "—",
		Size = UDim2.new(1, -12, 0, 24),
		Position = UDim2.fromOffset(10, 20),
		Color = meta.accent,
		SizePx = 18,
		Font = T.Font.Num,
		Scaled = true,
		MinText = 12,
		MaxText = 22,
		Z = 6,
	})

	local sc = UIKit.Scale(chip, 1)
	chip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tween(sc, { Scale = 1.04 }, 0.1)
		end
	end)
	chip.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tween(sc, { Scale = 1 }, 0.1)
		end
	end)

	return chip
end

function UIKit.Chip(props: {
	Parent: Instance?,
	Title: string?,
	Value: string?,
	Accent: Color3?,
	Order: number?,
	W: number?,
}): Frame
	-- legacy wrapper → map title to Metric key if possible
	local keyMap = {
		["СИЛА"] = "Power",
		["CPS"] = "Cps",
		["DPS"] = "Dps",
		["МОНЕТЫ"] = "Coins",
		["КЛИКИ"] = "Clicks",
		["ЛОКАЦИЯ"] = "Loc",
		["REBIRTH"] = "Rebirth",
	}
	local key = keyMap[props.Title or ""] or "Power"
	return UIKit.MetricChip({
		Parent = props.Parent,
		Key = key,
		Title = props.Title,
		Value = props.Value,
		Order = props.Order,
		W = props.W,
	})
end

function UIKit.SetChipValue(chip: Frame, text: string)
	local v = chip:FindFirstChild("Value")
	if v and v:IsA("TextLabel") then
		v.Text = text
	end
end

function UIKit.Scroll(parent: Instance, size: UDim2?, pos: UDim2?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Name = "Scroll"
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.Size = size or UDim2.fromScale(1, 1)
	if pos then
		s.Position = pos
	end
	s.ScrollBarThickness = 4
	s.ScrollBarImageColor3 = T.Gold
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.Parent = parent
	UIKit.List(s, 8, false)
	UIKit.Pad(s, 2)
	return s
end

function UIKit.Bar(parent: Instance, fill: number, color: Color3?, h: number?): (Frame, Frame)
	local track = Instance.new("Frame")
	track.Name = "BarTrack"
	track.BackgroundColor3 = T.Surface3
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, 0, 0, h or 8)
	track.Parent = parent
	UIKit.Corner(track, 99)
	UIKit.Stroke(track, T.Stroke, 1, 0.7)

	local bar = Instance.new("Frame")
	bar.Name = "Fill"
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(math.clamp(fill, 0, 1), 0, 1, 0)
	bar.Parent = track
	UIKit.Corner(bar, 99)
	UIKit.Gradient(bar, color or T.GoldGlow, color or T.GoldDeep, 0)
	return track, bar
end

function UIKit.Window(gui: Instance, title: string, onClose: () -> ()): (Frame, Frame)
	local root = UIKit.Glass({
		Name = "Window",
		Parent = gui,
		Size = UDim2.fromScale(0.5, 0.62),
		Position = UDim2.fromScale(0.5, 0.5),
		Anchor = Vector2.new(0.5, 0.5),
		Radius = T.R.lg,
		Z = 30,
		Deep = true,
		AccentBar = true,
	})
	root.Visible = false
	UIKit.Stroke(root, T.Gold, 1.5, 0.45)
	UIKit.SizeConstraint(root, Vector2.new(320, 280), Vector2.new(900, 800))

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 48)
	header.ZIndex = 31
	header.Parent = root

	UIKit.Label({
		Parent = header,
		Text = title,
		Size = UDim2.new(1, -56, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		SizePx = 18,
		Font = T.Font.Title,
		Z = 32,
	})

	UIKit.Button({
		Name = "Close",
		Parent = header,
		Text = "×",
		Size = UDim2.fromOffset(36, 32),
		Position = UDim2.new(1, -44, 0.5, 0),
		Anchor = Vector2.new(0, 0.5),
		Color = T.Surface3,
		Color2 = T.Surface2,
		TextColor = T.Text,
		SizePx = 20,
		Radius = T.R.sm,
		Z = 32,
		OnClick = onClose,
	})

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -24, 1, -60)
	body.Position = UDim2.fromOffset(12, 52)
	body.ZIndex = 31
	body.ClipsDescendants = true
	body.Parent = root

	return root, body
end

function UIKit.Clear(parent: Instance)
	for _, c in parent:GetChildren() do
		c:Destroy()
	end
end

return UIKit
