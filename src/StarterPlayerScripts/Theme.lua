--!strict
--[[
	High-contrast idle HUD palette.
	Solid mid panels + pure white glyphs. Gold only for numbers.
]]

local Theme = {}

-- Lighter panels so white text always pops over 3D world too
Theme.Bg = Color3.fromRGB(18, 20, 28)
Theme.Glass = Color3.fromRGB(42, 46, 60)
Theme.Glass2 = Color3.fromRGB(52, 58, 74)
Theme.Glass3 = Color3.fromRGB(64, 72, 92)
Theme.GlassHover = Color3.fromRGB(78, 88, 112)

Theme.Stroke = Color3.fromRGB(255, 255, 255)
Theme.StrokeA = 0.55

-- Pure readable text
Theme.Text = Color3.fromRGB(255, 255, 255)
Theme.TextSoft = Color3.fromRGB(230, 235, 245)
Theme.TextDim = Color3.fromRGB(200, 208, 222)
Theme.TextOnAccent = Color3.fromRGB(20, 16, 8)

Theme.Accent = Color3.fromRGB(255, 210, 90)
Theme.AccentDeep = Color3.fromRGB(180, 130, 40)
Theme.AccentGlow = Color3.fromRGB(255, 230, 140)
Theme.AccentMute = Color3.fromRGB(220, 180, 100)

Theme.Good = Color3.fromRGB(90, 220, 140)
Theme.GoodDeep = Color3.fromRGB(40, 130, 80)
Theme.Bad = Color3.fromRGB(255, 100, 100)
Theme.BadDeep = Color3.fromRGB(150, 50, 50)
Theme.Info = Color3.fromRGB(120, 190, 255)
Theme.InfoDeep = Color3.fromRGB(50, 100, 160)

Theme.Click = Color3.fromRGB(240, 85, 75)
Theme.ClickDeep = Color3.fromRGB(170, 45, 40)

Theme.AutoOn = Color3.fromRGB(60, 190, 120)
Theme.AutoOnDeep = Color3.fromRGB(35, 120, 75)
Theme.AutoOff = Color3.fromRGB(80, 86, 105)
Theme.AutoOffDeep = Color3.fromRGB(55, 60, 75)

-- Number colors (bright on dark chip body)
Theme.Chip = {
	Power = Color3.fromRGB(255, 220, 100),
	Cps = Color3.fromRGB(140, 210, 255),
	Dps = Color3.fromRGB(255, 200, 150),
	Coins = Color3.fromRGB(255, 230, 120),
	Clicks = Color3.fromRGB(240, 245, 255),
	Loc = Color3.fromRGB(140, 235, 180),
	Rebirth = Color3.fromRGB(220, 190, 255),
}

Theme.R = { sm = 8, md = 12, lg = 16, xl = 20, pill = 999 }
Theme.Pad = { xs = 4, sm = 8, md = 12, lg = 16, xl = 20 }

Theme.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Num = Enum.Font.GothamBlack,
	Ui = Enum.Font.Gotham,
}

return Theme
