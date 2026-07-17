--!strict
--[[
	Harmonized cool-slate palette + one warm accent.
	No rainbow chips, no muddy red/green clash with gold.
]]

local Theme = {}

-- Base: neutral cool slate (slightly blue-gray, not purple-black)
Theme.Bg = Color3.fromRGB(12, 14, 18)
Theme.Glass = Color3.fromRGB(20, 23, 30)
Theme.Glass2 = Color3.fromRGB(26, 30, 38)
Theme.Glass3 = Color3.fromRGB(34, 39, 50)
Theme.GlassHover = Color3.fromRGB(44, 50, 64)

-- Soft white stroke (not pure white neon)
Theme.Stroke = Color3.fromRGB(200, 210, 230)
Theme.StrokeA = 0.82

Theme.Text = Color3.fromRGB(242, 244, 248)
Theme.TextSoft = Color3.fromRGB(168, 176, 192)
Theme.TextDim = Color3.fromRGB(112, 120, 136)

-- Brand: soft gold (numbers / primary CTAs only)
Theme.Accent = Color3.fromRGB(220, 178, 88)
Theme.AccentDeep = Color3.fromRGB(92, 70, 32)
Theme.AccentGlow = Color3.fromRGB(236, 200, 120)
Theme.AccentMute = Color3.fromRGB(160, 140, 96)

-- Semantic — desaturated so they don't fight gold
Theme.Good = Color3.fromRGB(96, 176, 132)
Theme.GoodDeep = Color3.fromRGB(36, 88, 58)
Theme.Bad = Color3.fromRGB(196, 88, 88)
Theme.BadDeep = Color3.fromRGB(96, 36, 36)
Theme.Info = Color3.fromRGB(120, 160, 196)
Theme.InfoDeep = Color3.fromRGB(40, 60, 88)

-- Click = warm brick that sits next to gold without screaming
Theme.Click = Color3.fromRGB(188, 78, 68)
Theme.ClickDeep = Color3.fromRGB(112, 42, 38)

Theme.AutoOn = Color3.fromRGB(72, 148, 108)
Theme.AutoOnDeep = Color3.fromRGB(32, 78, 52)
Theme.AutoOff = Color3.fromRGB(52, 48, 54)
Theme.AutoOffDeep = Color3.fromRGB(32, 30, 36)

-- Chip accents: all within slate family + soft tints (no rainbow)
Theme.Chip = {
	Power = Color3.fromRGB(220, 178, 88),
	Cps = Color3.fromRGB(140, 170, 200),
	Dps = Color3.fromRGB(190, 170, 140),
	Coins = Color3.fromRGB(228, 196, 110),
	Clicks = Color3.fromRGB(168, 176, 192),
	Loc = Color3.fromRGB(120, 170, 150),
	Rebirth = Color3.fromRGB(170, 160, 200),
}

Theme.R = {
	sm = 8,
	md = 12,
	lg = 16,
	xl = 20,
	pill = 999,
}

Theme.Pad = { xs = 4, sm = 8, md = 12, lg = 16, xl = 20 }

-- Base design sizes (scaled at runtime via Layout metrics)
Theme.TopH = 56
Theme.RailW = 72
Theme.ActionH = 88
Theme.RailBtn = 56
Theme.Gap = 10

Theme.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Num = Enum.Font.GothamBlack,
	Ui = Enum.Font.Gotham,
}

return Theme
