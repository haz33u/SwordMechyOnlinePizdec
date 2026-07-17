--!strict
--[[
	Design tokens — single source for HUD + all modals/windows.
	Use Theme.Colors / Theme.Fonts / Theme.Radius / Theme.Spacing everywhere.
]]

local Theme = {
	Colors = {
		Primary = Color3.fromRGB(255, 204, 51),
		PrimaryDeep = Color3.fromRGB(230, 140, 20),
		PrimaryGlow = Color3.fromRGB(255, 230, 120),

		Background = Color3.fromRGB(16, 14, 26),
		Surface = Color3.fromRGB(38, 32, 56),
		Surface2 = Color3.fromRGB(50, 42, 72),
		Surface3 = Color3.fromRGB(64, 54, 90),
		SurfaceElevated = Color3.fromRGB(72, 60, 100),

		TextPrimary = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(220, 210, 240),
		TextMuted = Color3.fromRGB(180, 170, 200),
		TextOnPrimary = Color3.fromRGB(255, 255, 255),

		Stroke = Color3.fromRGB(255, 255, 255),
		StrokeMuted = 0.45,

		Success = Color3.fromRGB(56, 200, 120),
		SuccessDeep = Color3.fromRGB(28, 140, 80),
		Warning = Color3.fromRGB(255, 193, 7),
		Danger = Color3.fromRGB(255, 82, 82),
		DangerDeep = Color3.fromRGB(190, 40, 50),
		Info = Color3.fromRGB(66, 165, 245),
		Disabled = Color3.fromRGB(90, 85, 105),
		DisabledDeep = Color3.fromRGB(60, 56, 72),

		Click = Color3.fromRGB(255, 90, 100),
		ClickDeep = Color3.fromRGB(200, 45, 60),
		AutoOn = Color3.fromRGB(50, 210, 130),
		AutoOnDeep = Color3.fromRGB(25, 150, 85),
		AutoOff = Color3.fromRGB(95, 80, 125),
		AutoOffDeep = Color3.fromRGB(65, 55, 95),
	},

	Fonts = {
		Title = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Num = Enum.Font.GothamBlack,
		Ui = Enum.Font.Gotham,
	},

	Radius = {
		sm = 8,
		md = 12,
		lg = 16,
		xl = 20,
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
			accent = Color3.fromRGB(255, 112, 67),
			fill0 = Color3.fromRGB(95, 42, 32),
			fill1 = Color3.fromRGB(58, 30, 26),
			icon = "⚔",
		},
		Cps = {
			accent = Color3.fromRGB(41, 182, 246),
			fill0 = Color3.fromRGB(28, 58, 90),
			fill1 = Color3.fromRGB(20, 40, 64),
			icon = "⚡",
		},
		Dps = {
			accent = Color3.fromRGB(186, 104, 200),
			fill0 = Color3.fromRGB(58, 32, 72),
			fill1 = Color3.fromRGB(40, 24, 54),
			icon = "💥",
		},
		Coins = {
			accent = Color3.fromRGB(255, 213, 79),
			fill0 = Color3.fromRGB(85, 62, 22),
			fill1 = Color3.fromRGB(55, 40, 16),
			icon = "🪙",
		},
		Clicks = {
			accent = Color3.fromRGB(102, 187, 106),
			fill0 = Color3.fromRGB(30, 58, 38),
			fill1 = Color3.fromRGB(22, 42, 28),
			icon = "👆",
		},
		Loc = {
			accent = Color3.fromRGB(77, 208, 225),
			fill0 = Color3.fromRGB(24, 58, 64),
			fill1 = Color3.fromRGB(18, 42, 48),
			icon = "🗺",
		},
		Rebirth = {
			accent = Color3.fromRGB(240, 98, 146),
			fill0 = Color3.fromRGB(72, 32, 52),
			fill1 = Color3.fromRGB(50, 24, 40),
			icon = "♻",
		},
	},

	UpgradeIcon = {
		RunSpeed = "🏃",
		Backpack = "🎒",
		Power = "💪",
		ClickSpeed = "⚡",
		CritChance = "🎯",
		Luck = "🍀",
	},

	WindowIcon = {
		character = "👤",
		weapons = "⚔",
		pets = "🐾",
		auras = "✨",
		relics = "💎",
		quests = "📜",
		locations = "🗺",
		dungeons = "🏛",
	},

	Pop = {
		Normal = Color3.fromRGB(255, 255, 255),
		Crit = Color3.fromRGB(255, 215, 64),
		Auto = Color3.fromRGB(105, 240, 174),
	},
}

-- ── aliases for existing code ──────────────────────────────────
local C = Theme.Colors
Theme.Bg = C.Background
Theme.Surface = C.Surface
Theme.Surface2 = C.Surface2
Theme.Surface3 = C.Surface3
Theme.Glass = C.Surface
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
Theme.Gold = C.Primary
Theme.GoldDeep = C.PrimaryDeep
Theme.GoldGlow = C.PrimaryGlow
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
