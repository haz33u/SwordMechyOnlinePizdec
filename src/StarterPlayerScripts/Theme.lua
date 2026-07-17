--!strict
--[[
	Bright soft game UI — warm dark glass, juicy accents, never metallic grey.
]]

local Theme = {}

-- Warm charcoal (slight purple-brown warmth, not cold steel)
Theme.Bg = Color3.fromRGB(22, 18, 32)
Theme.Glass = Color3.fromRGB(48, 36, 58)
Theme.Glass2 = Color3.fromRGB(62, 46, 74)
Theme.Glass3 = Color3.fromRGB(78, 58, 92)
Theme.GlassHover = Color3.fromRGB(96, 72, 112)

Theme.Stroke = Color3.fromRGB(255, 240, 255)
Theme.StrokeA = 0.45

Theme.Text = Color3.fromRGB(255, 255, 255)
Theme.TextSoft = Color3.fromRGB(245, 235, 255)
Theme.TextDim = Color3.fromRGB(220, 205, 235)
Theme.TextOnAccent = Color3.fromRGB(40, 24, 8)

-- Juicy gold / neon-soft accents
Theme.Accent = Color3.fromRGB(255, 214, 72)
Theme.AccentDeep = Color3.fromRGB(230, 150, 40)
Theme.AccentGlow = Color3.fromRGB(255, 236, 120)
Theme.AccentMute = Color3.fromRGB(255, 190, 100)

Theme.Good = Color3.fromRGB(80, 240, 150)
Theme.GoodDeep = Color3.fromRGB(30, 160, 90)
Theme.Bad = Color3.fromRGB(255, 95, 110)
Theme.BadDeep = Color3.fromRGB(180, 40, 60)
Theme.Info = Color3.fromRGB(100, 210, 255)
Theme.InfoDeep = Color3.fromRGB(40, 120, 200)

Theme.Click = Color3.fromRGB(255, 90, 100)
Theme.ClickDeep = Color3.fromRGB(200, 40, 70)
Theme.ClickGlow = Color3.fromRGB(255, 150, 160)

Theme.AutoOn = Color3.fromRGB(70, 230, 140)
Theme.AutoOnDeep = Color3.fromRGB(30, 150, 85)
Theme.AutoOff = Color3.fromRGB(100, 80, 120)
Theme.AutoOffDeep = Color3.fromRGB(70, 55, 90)

Theme.Chip = {
	Power = Color3.fromRGB(255, 220, 80),
	Cps = Color3.fromRGB(120, 220, 255),
	Dps = Color3.fromRGB(255, 180, 120),
	Coins = Color3.fromRGB(255, 230, 90),
	Clicks = Color3.fromRGB(255, 255, 255),
	Loc = Color3.fromRGB(120, 255, 180),
	Rebirth = Color3.fromRGB(220, 160, 255),
}

Theme.Pop = {
	Normal = Color3.fromRGB(255, 255, 255),
	Crit = Color3.fromRGB(255, 220, 60),
	Auto = Color3.fromRGB(140, 255, 200),
}

Theme.R = { sm = 10, md = 14, lg = 18, xl = 22, pill = 999 }
Theme.Pad = { xs = 4, sm = 8, md = 12, lg = 16, xl = 20 }

Theme.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Num = Enum.Font.GothamBlack,
	Ui = Enum.Font.Gotham,
}

return Theme
