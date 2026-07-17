--!strict
--[[
	Material-inspired high-contrast palette for Sword Masters HUD.
	WCAG-friendly bright text on mid-dark surfaces; unique metric accents.
]]

local Theme = {}

-- Surfaces (warm dark, not flat black)
Theme.Bg = Color3.fromRGB(18, 16, 28)
Theme.Surface = Color3.fromRGB(36, 32, 52)
Theme.Surface2 = Color3.fromRGB(48, 42, 68)
Theme.Surface3 = Color3.fromRGB(62, 54, 88)
Theme.Overlay = Color3.fromRGB(12, 10, 20)

Theme.Stroke = Color3.fromRGB(255, 255, 255)
Theme.StrokeA = 0.42

-- Text (white / near-white for AA on dark)
Theme.Text = Color3.fromRGB(255, 255, 255)
Theme.TextMuted = Color3.fromRGB(210, 200, 230)
Theme.TextDim = Color3.fromRGB(175, 165, 200)

-- Brand / CTA
Theme.Gold = Color3.fromRGB(255, 204, 51)
Theme.GoldDeep = Color3.fromRGB(230, 140, 20)
Theme.GoldGlow = Color3.fromRGB(255, 230, 120)

Theme.Click = Color3.fromRGB(255, 82, 82)
Theme.ClickDeep = Color3.fromRGB(198, 40, 40)
Theme.AutoOn = Color3.fromRGB(0, 200, 120)
Theme.AutoOnDeep = Color3.fromRGB(0, 140, 80)
Theme.AutoOff = Color3.fromRGB(90, 75, 120)
Theme.AutoOffDeep = Color3.fromRGB(60, 50, 90)

Theme.Success = Color3.fromRGB(76, 220, 140)
Theme.Danger = Color3.fromRGB(255, 90, 100)
Theme.Info = Color3.fromRGB(66, 165, 245)

-- Per-metric unique accents (Tailwind-ish)
Theme.Metric = {
	Power = {
		accent = Color3.fromRGB(255, 112, 67), -- deep orange
		fill0 = Color3.fromRGB(90, 40, 30),
		fill1 = Color3.fromRGB(55, 28, 24),
		icon = "⚔",
	},
	Cps = {
		accent = Color3.fromRGB(41, 182, 246), -- light blue
		fill0 = Color3.fromRGB(25, 55, 85),
		fill1 = Color3.fromRGB(18, 38, 60),
		icon = "⚡",
	},
	Dps = {
		accent = Color3.fromRGB(171, 71, 188), -- purple
		fill0 = Color3.fromRGB(55, 30, 70),
		fill1 = Color3.fromRGB(38, 22, 52),
		icon = "💥",
	},
	Coins = {
		accent = Color3.fromRGB(255, 213, 79), -- amber
		fill0 = Color3.fromRGB(80, 60, 20),
		fill1 = Color3.fromRGB(50, 38, 14),
		icon = "🪙",
	},
	Clicks = {
		accent = Color3.fromRGB(102, 187, 106), -- green
		fill0 = Color3.fromRGB(28, 55, 35),
		fill1 = Color3.fromRGB(20, 40, 26),
		icon = "👆",
	},
	Loc = {
		accent = Color3.fromRGB(77, 208, 225), -- cyan
		fill0 = Color3.fromRGB(22, 55, 60),
		fill1 = Color3.fromRGB(16, 40, 45),
		icon = "🗺",
	},
	Rebirth = {
		accent = Color3.fromRGB(240, 98, 146), -- pink
		fill0 = Color3.fromRGB(70, 30, 50),
		fill1 = Color3.fromRGB(48, 22, 38),
		icon = "♻",
	},
}

Theme.Pop = {
	Normal = Color3.fromRGB(255, 255, 255),
	Crit = Color3.fromRGB(255, 215, 64),
	Auto = Color3.fromRGB(105, 240, 174),
}

Theme.R = { sm = 10, md = 14, lg = 18, xl = 22, pill = 999 }

Theme.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Num = Enum.Font.GothamBlack,
	Ui = Enum.Font.Gotham,
}

-- aliases used by older modules
Theme.Glass = Theme.Surface
Theme.Glass2 = Theme.Surface2
Theme.Glass3 = Theme.Surface3
Theme.Accent = Theme.Gold
Theme.AccentDeep = Theme.GoldDeep
Theme.AccentGlow = Theme.GoldGlow
Theme.TextSoft = Theme.TextMuted
Theme.Good = Theme.Success
Theme.Bad = Theme.Danger
Theme.Chip = {
	Power = Theme.Metric.Power.accent,
	Cps = Theme.Metric.Cps.accent,
	Dps = Theme.Metric.Dps.accent,
	Coins = Theme.Metric.Coins.accent,
	Clicks = Theme.Metric.Clicks.accent,
	Loc = Theme.Metric.Loc.accent,
	Rebirth = Theme.Metric.Rebirth.accent,
}

return Theme
