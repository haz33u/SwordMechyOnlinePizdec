--!strict
--[[
	Visual tokens — Mixmaxed-style polish (Corner/Stroke/Gradient/Pad/Scale)
	Cristalix / dark RPG: glass panels, one accent, no neon soup.
]]

local Theme = {}

-- Surfaces: cool charcoal, not pure black, not blue-neon
Theme.Bg = Color3.fromRGB(8, 10, 14)
Theme.Glass = Color3.fromRGB(16, 18, 26)
Theme.Glass2 = Color3.fromRGB(22, 26, 36)
Theme.Glass3 = Color3.fromRGB(30, 34, 48)
Theme.GlassHover = Color3.fromRGB(38, 44, 62)

Theme.Stroke = Color3.fromRGB(255, 255, 255)
Theme.StrokeA = 0.88 -- high = subtle

Theme.Text = Color3.fromRGB(236, 240, 248)
Theme.TextSoft = Color3.fromRGB(160, 168, 186)
Theme.TextDim = Color3.fromRGB(100, 108, 128)

-- Single brand accent (amber gold for power/coins — Cristalix numbers vibe)
Theme.Accent = Color3.fromRGB(232, 184, 74)
Theme.AccentDeep = Color3.fromRGB(120, 88, 28)
Theme.AccentGlow = Color3.fromRGB(255, 210, 110)

-- Semantic
Theme.Good = Color3.fromRGB(74, 196, 128)
Theme.Bad = Color3.fromRGB(220, 72, 72)
Theme.Info = Color3.fromRGB(88, 168, 230)
Theme.Click = Color3.fromRGB(210, 64, 56)
Theme.ClickDeep = Color3.fromRGB(140, 36, 32)
Theme.AutoOn = Color3.fromRGB(48, 150, 96)
Theme.AutoOff = Color3.fromRGB(56, 40, 44)

Theme.R = {
	sm = 6,
	md = 10,
	lg = 14,
	xl = 18,
	pill = 999,
}

Theme.Pad = { xs = 4, sm = 8, md = 12, lg = 16, xl = 20 }

Theme.TopH = 52
Theme.RailW = 58
Theme.ActionH = 70

Theme.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Num = Enum.Font.GothamBlack,
	Ui = Enum.Font.Gotham,
}

return Theme
