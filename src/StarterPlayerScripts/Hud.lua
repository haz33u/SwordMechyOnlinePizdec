--!strict
--[[
	Compact Cristalix-style HUD
	- top chips (not text wall)
	- left icon rail
	- bottom action cluster: Auto · CLICK · Rebirth
]]

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)

local Hud = {}

local RAIL = {
	{ id = "character", glyph = "UP" },
	{ id = "weapons", glyph = "SW" },
	{ id = "pets", glyph = "PT" },
	{ id = "auras", glyph = "AU" },
	{ id = "relics", glyph = "RL" },
	{ id = "quests", glyph = "QS" },
	{ id = "locations", glyph = "MP" },
	{ id = "dungeons", glyph = "DG" },
}

local LOC = {
	[1] = "Тёмный лес",
	[2] = "Пиратский берег",
	[3] = "Земли шиноби",
	[4] = "Полярная тундра",
}

function Hud.Mount(gui: ScreenGui, store: any, openModal: (string, any?) -> ())
	local root = Instance.new("Folder")
	root.Name = "HUD"
	root.Parent = gui

	---------------------------------------------------------------- top chips
	local top = Instance.new("Frame")
	top.Name = "TopChips"
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, -(T.RailW + 24), 0, T.TopH)
	top.Position = UDim2.fromOffset(T.RailW + 12, 10)
	top.ZIndex = 10
	top.Parent = root
	UIKit.List(top, 8, true, Enum.HorizontalAlignment.Left)

	local chipPower = UIKit.Chip({ Parent = top, Title = "СИЛА", Value = "—", Accent = T.Accent, Order = 1, W = 112 })
	local chipCps = UIKit.Chip({ Parent = top, Title = "CPS", Value = "—", Accent = T.Info, Order = 2, W = 90 })
	local chipDps = UIKit.Chip({ Parent = top, Title = "DPS", Value = "—", Accent = Color3.fromRGB(200, 120, 255), Order = 3, W = 112 })
	local chipCoins = UIKit.Chip({ Parent = top, Title = "МОНЕТЫ", Value = "—", Accent = T.AccentGlow, Order = 4, W = 112 })
	local chipClicks = UIKit.Chip({ Parent = top, Title = "КЛИКИ", Value = "—", Accent = T.TextSoft, Order = 5, W = 100 })
	local chipLoc = UIKit.Chip({ Parent = top, Title = "ЛОКАЦИЯ", Value = "—", Accent = T.Good, Order = 6, W = 140 })
	local chipR = UIKit.Chip({ Parent = top, Title = "REBIRTH", Value = "—", Accent = Color3.fromRGB(180, 140, 255), Order = 7, W = 100 })

	---------------------------------------------------------------- left rail
	local rail = UIKit.Glass({
		Name = "Rail",
		Parent = root,
		Size = UDim2.fromOffset(T.RailW, 0),
		Position = UDim2.fromOffset(10, T.TopH + 18),
		Radius = T.R.lg,
		Z = 10,
		Deep = true,
	})
	rail.Size = UDim2.new(0, T.RailW, 1, -(T.TopH + T.ActionH + 40))
	UIKit.Pad(rail, 7)
	UIKit.List(rail, 6, false, Enum.HorizontalAlignment.Center)

	local railBtns: { [string]: TextButton } = {}
	for i, item in ipairs(RAIL) do
		local b = UIKit.IconBtn({
			Name = item.id,
			Parent = rail,
			Glyph = item.glyph,
			Order = i,
			OnClick = function()
				store:OpenPanel(item.id)
			end,
		})
		railBtns[item.id] = b
	end

	---------------------------------------------------------------- bottom actions
	local actions = UIKit.Glass({
		Name = "Actions",
		Parent = root,
		Size = UDim2.fromOffset(360, T.ActionH),
		Position = UDim2.new(0.5, 0, 1, -14),
		Anchor = Vector2.new(0.5, 1),
		Radius = T.R.lg,
		Z = 12,
		Deep = true,
		AccentBar = true,
	})
	UIKit.Pad(actions, 10)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 1, -14)
	row.ZIndex = 13
	row.Parent = actions
	UIKit.List(row, 10, true, Enum.HorizontalAlignment.Center)

	local autoBtn = UIKit.Button({
		Name = "Auto",
		Parent = row,
		Text = "АВТО",
		Size = UDim2.fromOffset(88, 44),
		Color = T.AutoOff,
		Color2 = Color3.fromRGB(40, 28, 30),
		SizePx = 13,
		Radius = T.R.md,
		Order = 1,
		Z = 14,
		OnClick = function()
			Net.ToggleAuto()
		end,
	})

	local clickBtn = UIKit.Button({
		Name = "Click",
		Parent = row,
		Text = "КЛИК",
		Size = UDim2.fromOffset(140, 48),
		Color = T.Click,
		Color2 = T.ClickDeep,
		SizePx = 20,
		Radius = T.R.md,
		Order = 2,
		Z = 14,
		OnClick = function()
			Net.Swing("manual")
		end,
	})
	clickBtn.Font = T.Font.Num

	UIKit.Button({
		Name = "Rebirth",
		Parent = row,
		Text = "R↑",
		Size = UDim2.fromOffset(72, 44),
		Color = T.AccentDeep,
		Color2 = Color3.fromRGB(70, 50, 16),
		TextColor = T.Accent,
		SizePx = 16,
		Radius = T.R.md,
		Order = 3,
		Z = 14,
		OnClick = function()
			openModal("rebirth", nil)
		end,
	})

	-- rebirth progress under actions
	local rbHost = Instance.new("Frame")
	rbHost.Name = "RebirthProg"
	rbHost.BackgroundTransparency = 1
	rbHost.Size = UDim2.fromOffset(360, 10)
	rbHost.Position = UDim2.new(0.5, 0, 1, -T.ActionH - 22)
	rbHost.AnchorPoint = Vector2.new(0.5, 1)
	rbHost.ZIndex = 11
	rbHost.Parent = root
	local _, rbFill = UIKit.Bar(rbHost, 0, T.Accent, 6)
	rbFill.Parent.Size = UDim2.new(1, 0, 0, 6)

	local questBadge = UIKit.Label({
		Name = "QuestBadge",
		Parent = railBtns.quests,
		Text = "",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -6, 0, -4),
		Anchor = Vector2.new(1, 0),
		Color = T.Text,
		SizePx = 10,
		Font = T.Font.Num,
		X = Enum.TextXAlignment.Center,
		Z = 20,
	})
	questBadge.BackgroundColor3 = T.Bad
	questBadge.BackgroundTransparency = 0
	questBadge.TextColor3 = Color3.new(1, 1, 1)
	questBadge.Visible = false
	UIKit.Corner(questBadge, 99)

	local api = {}
	function api.Refresh()
		local stats = store:PeekStats()
		local profile = store:PeekProfile()
		if not stats then
			return
		end

		UIKit.SetChipValue(chipPower, Format.Num(stats.damagePerClick or stats.totalPower))
		UIKit.SetChipValue(chipCps, string.format("%.1f", stats.cps or 0))
		UIKit.SetChipValue(chipDps, Format.Num(stats.dps))
		UIKit.SetChipValue(chipCoins, Format.Num(stats.coins))
		UIKit.SetChipValue(chipClicks, Format.Num(stats.totalClicks))
		UIKit.SetChipValue(chipLoc, LOC[stats.location or 1] or ("#" .. tostring(stats.location)))
		UIKit.SetChipValue(chipR, string.format("R%d %s", stats.rebirthLevel or 0, Format.Mult(stats.rebirthMult)))

		local cost = stats.nextRebirthCost or 1
		local dmg = stats.lifetimeDamage or 0
		local pct = cost > 0 and math.clamp(dmg / cost, 0, 1) or 0
		rbFill.Size = UDim2.new(pct, 0, 1, 0)

		if stats.autoClicker then
			autoBtn.Text = "АВТО ON"
			autoBtn.TextColor3 = T.Text
			local g = autoBtn:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOn, Color3.fromRGB(28, 90, 56))
			end
		else
			autoBtn.Text = "АВТО"
			autoBtn.TextColor3 = T.Text
			local g = autoBtn:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOff, Color3.fromRGB(40, 28, 30))
			end
		end

		local ready = 0
		if profile and profile.quests then
			for _, q in pairs(profile.quests) do
				if q.completed and not q.claimed then
					ready += 1
				end
			end
		end
		if ready > 0 then
			questBadge.Visible = true
			questBadge.Text = tostring(ready)
		else
			questBadge.Visible = false
		end

		local panel = store:PeekPanel()
		for id, b in railBtns do
			local active = id == panel
			local g = b:FindFirstChildOfClass("UIGradient")
			if g then
				if active then
					g.Color = ColorSequence.new(T.AccentDeep, Color3.fromRGB(70, 52, 18))
					b.TextColor3 = T.Accent
				else
					g.Color = ColorSequence.new(T.Glass3, T.Glass)
					b.TextColor3 = T.TextSoft
				end
			end
		end
	end

	return api
end

return Hud
