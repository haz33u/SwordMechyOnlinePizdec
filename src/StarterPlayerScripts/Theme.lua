--!strict
--[[
	Design tokens — SCREEENS reference style:
	flat charcoal panels, thin strokes, blue CTAs, red close, slot borders.
	Inspiration: mesh gradients / coolors for subtle depth only.
]]

local Theme = {
	Colors = {
		-- Primary actions = blue (as in reference)
		Primary = Color3.fromRGB(52, 120, 220),
		PrimaryDeep = Color3.fromRGB(32, 80, 170),
		PrimaryGlow = Color3.fromRGB(90, 160, 255),

		-- Coin / gold accents (currency only)
		Coin = Color3.fromRGB(255, 210, 60),
		CoinDeep = Color3.fromRGB(200, 150, 30),

		-- Flat dark panels
		Background = Color3.fromRGB(12, 12, 14),
		Surface = Color3.fromRGB(22, 22, 26),
		Surface2 = Color3.fromRGB(30, 30, 36),
		Surface3 = Color3.fromRGB(40, 40, 48),
		SurfaceElevated = Color3.fromRGB(48, 48, 56),
		Panel = Color3.fromRGB(18, 18, 22),
		PanelHeader = Color3.fromRGB(26, 26, 30),

		TextPrimary = Color3.fromRGB(240, 240, 245),
		TextSecondary = Color3.fromRGB(190, 190, 200),
		TextMuted = Color3.fromRGB(130, 130, 145),
		TextOnPrimary = Color3.fromRGB(255, 255, 255),

		Stroke = Color3.fromRGB(70, 70, 82),
		StrokeLight = Color3.fromRGB(110, 110, 125),
		StrokeMuted = 0.15,

		Success = Color3.fromRGB(70, 200, 100),
		SuccessDeep = Color3.fromRGB(35, 140, 60),
		Warning = Color3.fromRGB(255, 193, 7),
		Danger = Color3.fromRGB(220, 55, 55),
		DangerDeep = Color3.fromRGB(160, 30, 30),
		Info = Color3.fromRGB(52, 120, 220),
		Disabled = Color3.fromRGB(70, 70, 80),
		DisabledDeep = Color3.fromRGB(48, 48, 56),

		Click = Color3.fromRGB(52, 120, 220),
		ClickDeep = Color3.fromRGB(32, 80, 170),
		AutoOn = Color3.fromRGB(50, 200, 110),
		AutoOnDeep = Color3.fromRGB(30, 140, 75),
		AutoOff = Color3.fromRGB(70, 70, 82),
		AutoOffDeep = Color3.fromRGB(48, 48, 56),

		-- Upgrade tile colors (UIУлучшений)
		UpPower = Color3.fromRGB(170, 35, 40),
		UpBackpack = Color3.fromRGB(35, 140, 55),
		UpSpeed = Color3.fromRGB(40, 90, 190),
		UpCrit = Color3.fromRGB(200, 120, 30),
		UpLuck = Color3.fromRGB(90, 50, 180),
		UpClick = Color3.fromRGB(45, 140, 180),
	},

	Fonts = {
		Title = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Num = Enum.Font.GothamBold,
		Ui = Enum.Font.Gotham,
	},

	Radius = {
		sm = 4,
		md = 6,
		lg = 8,
		xl = 10,
		pill = 999,
	},

	Spacing = {
		xs = 4,
		sm = 8,
		md = 12,
		lg = 16,
		xl = 20,
	},

	Metric = {
		Power = {
			accent = Color3.fromRGB(220, 80, 70),
			fill0 = Color3.fromRGB(48, 28, 28),
			fill1 = Color3.fromRGB(28, 18, 18),
			icon = "⚔",
		},
		Cps = {
			accent = Color3.fromRGB(70, 150, 230),
			fill0 = Color3.fromRGB(24, 36, 52),
			fill1 = Color3.fromRGB(16, 24, 36),
			icon = "⚡",
		},
		Dps = {
			accent = Color3.fromRGB(170, 100, 210),
			fill0 = Color3.fromRGB(40, 28, 52),
			fill1 = Color3.fromRGB(26, 18, 36),
			icon = "💥",
		},
		Coins = {
			accent = Color3.fromRGB(255, 210, 60),
			fill0 = Color3.fromRGB(52, 42, 18),
			fill1 = Color3.fromRGB(34, 28, 12),
			icon = "🪙",
		},
		Clicks = {
			accent = Color3.fromRGB(80, 190, 100),
			fill0 = Color3.fromRGB(24, 42, 28),
			fill1 = Color3.fromRGB(16, 28, 18),
			icon = "👆",
		},
		Loc = {
			accent = Color3.fromRGB(70, 190, 200),
			fill0 = Color3.fromRGB(22, 40, 44),
			fill1 = Color3.fromRGB(14, 28, 30),
			icon = "🗺",
		},
		Rebirth = {
			accent = Color3.fromRGB(90, 150, 240),
			fill0 = Color3.fromRGB(28, 36, 56),
			fill1 = Color3.fromRGB(18, 24, 40),
			icon = "♻",
		},
	},

	UpgradeIcon = {
		RunSpeed = "👟",
		Backpack = "🎒",
		Power = "⚔",
		ClickSpeed = "⚡",
		CritChance = "🎯",
		Luck = "🍀",
	},

	UpgradeColor = {
		RunSpeed = Color3.fromRGB(40, 90, 190),
		Backpack = Color3.fromRGB(35, 140, 55),
		Power = Color3.fromRGB(170, 35, 40),
		ClickSpeed = Color3.fromRGB(45, 140, 180),
		CritChance = Color3.fromRGB(200, 120, 30),
		Luck = Color3.fromRGB(90, 50, 180),
	},

	WindowIcon = {
		character = "👤",
		weapons = "⚔",
		pets = "🐾",
		auras = "✨",
		cases = "📦",
		relics = "💎",
		quests = "📜",
		locations = "🗺",
		dungeons = "🏛",
		shop = "💎",
	},

	Pop = {
		Normal = Color3.fromRGB(255, 255, 255),
		Crit = Color3.fromRGB(255, 210, 60),
		Auto = Color3.fromRGB(80, 220, 120),
	},
}

-- ── aliases for existing code ──────────────────────────────────
local C = Theme.Colors
Theme.Bg = C.Background
Theme.Surface = C.Surface
Theme.Surface2 = C.Surface2
Theme.Surface3 = C.Surface3
Theme.Glass = C.Panel
Theme.Glass2 = C.Surface2
Theme.Glass3 = C.Surface3
Theme.Stroke = C.Stroke
Theme.StrokeA = C.StrokeMuted
Theme.Text = C.TextPrimary
Theme.TextSoft = C.TextSecondary
Theme.TextMuted = C.TextMuted
Theme.TextDim = C.TextMuted
Theme.Accent = C.Primary
Theme.AccentDeep = C.PrimaryDeep
Theme.AccentGlow = C.PrimaryGlow
-- Gold kept as coin color for currency labels
Theme.Gold = C.Coin
Theme.GoldDeep = C.CoinDeep
Theme.GoldGlow = C.Coin
Theme.Click = C.Click
Theme.ClickDeep = C.ClickDeep
Theme.AutoOn = C.AutoOn
Theme.AutoOnDeep = C.AutoOnDeep
Theme.AutoOff = C.AutoOff
Theme.AutoOffDeep = C.AutoOffDeep
Theme.Success = C.Success
Theme.Good = C.Success
Theme.Danger = C.Danger
Theme.Bad = C.Danger
Theme.Info = C.Info
Theme.Disabled = C.Disabled
Theme.Font = Theme.Fonts
Theme.R = Theme.Radius
Theme.Pad = Theme.Spacing
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
