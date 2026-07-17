--!strict
--[[
	High-contrast dark UI: bright text always, mid-tone panels, clear CTAs.
]]

local Theme = {}

-- Panels slightly lifted so white text pops
Theme.Bg = Color3.fromRGB(14, 16, 22)
Theme.Glass = Color3.fromRGB(28, 32, 42)
Theme.Glass2 = Color3.fromRGB(36, 40, 54)
Theme.Glass3 = Color3.fromRGB(48, 54, 70)
Theme.GlassHover = Color3.fromRGB(60, 68, 88)

Theme.Stroke = Color3.fromRGB(220, 228, 245)
Theme.StrokeA = 0.72

-- TEXT: never dark-on-dark
Theme.Text = Color3.fromRGB(250, 252, 255) -- primary labels / buttons
Theme.TextSoft = Color3.fromRGB(210, 218, 232) -- secondary (still bright)
Theme.TextDim = Color3.fromRGB(168, 178, 196) -- captions only (readable)
Theme.TextOnAccent = Color3.fromRGB(18, 16, 12) -- rare: text on gold fill

-- Brand gold
Theme.Accent = Color3.fromRGB(240, 196, 96)
Theme.AccentDeep = Color3.fromRGB(160, 118, 40) -- lighter deep for gold buttons
Theme.AccentGlow = Color3.fromRGB(255, 220, 130)
Theme.AccentMute = Color3.fromRGB(200, 170, 110)

Theme.Good = Color3.fromRGB(110, 210, 150)
Theme.GoodDeep = Color3.fromRGB(48, 120, 78)
Theme.Bad = Color3.fromRGB(240, 110, 110)
Theme.BadDeep = Color3.fromRGB(140, 48, 48)
Theme.Info = Color3.fromRGB(140, 190, 240)
Theme.InfoDeep = Color3.fromRGB(50, 90, 140)

Theme.Click = Color3.fromRGB(230, 90, 78)
Theme.ClickDeep = Color3.fromRGB(160, 48, 42)

Theme.AutoOn = Color3.fromRGB(70, 180, 120)
Theme.AutoOnDeep = Color3.fromRGB(40, 110, 70)
Theme.AutoOff = Color3.fromRGB(70, 74, 90) -- mid slate, NOT near-black
Theme.AutoOffDeep = Color3.fromRGB(48, 52, 64)

Theme.Chip = {
	Power = Color3.fromRGB(255, 214, 110),
	Cps = Color3.fromRGB(170, 210, 255),
	Dps = Color3.fromRGB(230, 210, 170),
	Coins = Color3.fromRGB(255, 220, 120),
	Clicks = Color3.fromRGB(220, 228, 240),
	Loc = Color3.fromRGB(160, 230, 190),
	Rebirth = Color3.fromRGB(210, 190, 255),
}

Theme.R = {
	sm = 8,
	md = 12,
	lg = 16,
	xl = 20,
	pill = 999,
}

Theme.Pad = { xs = 4, sm = 8, md = 12, lg = 16, xl = 20 }

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
