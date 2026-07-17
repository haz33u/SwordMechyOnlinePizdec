--!strict
--[[
	Responsive HUD — chips top, icon rail left, action bar bottom.
	Sizes from Layout metrics (viewport-aware).
]]

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)
local Layout = require(script.Parent.Layout)

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
	top.ZIndex = 10
	top.Parent = root
	local topList = UIKit.List(top, 8, true, Enum.HorizontalAlignment.Left)
	topList.VerticalAlignment = Enum.VerticalAlignment.Center

	local chipPower = UIKit.Chip({ Parent = top, Title = "СИЛА", Value = "—", Accent = T.Chip.Power, Order = 1 })
	local chipCps = UIKit.Chip({ Parent = top, Title = "CPS", Value = "—", Accent = T.Chip.Cps, Order = 2 })
	local chipDps = UIKit.Chip({ Parent = top, Title = "DPS", Value = "—", Accent = T.Chip.Dps, Order = 3 })
	local chipCoins = UIKit.Chip({ Parent = top, Title = "МОНЕТЫ", Value = "—", Accent = T.Chip.Coins, Order = 4 })
	local chipClicks = UIKit.Chip({ Parent = top, Title = "КЛИКИ", Value = "—", Accent = T.Chip.Clicks, Order = 5 })
	local chipLoc = UIKit.Chip({ Parent = top, Title = "ЛОКАЦИЯ", Value = "—", Accent = T.Chip.Loc, Order = 6 })
	local chipR = UIKit.Chip({ Parent = top, Title = "REBIRTH", Value = "—", Accent = T.Chip.Rebirth, Order = 7 })
	local chips = { chipPower, chipCps, chipDps, chipCoins, chipClicks, chipLoc, chipR }

	---------------------------------------------------------------- left rail
	local rail = UIKit.Glass({
		Name = "Rail",
		Parent = root,
		Radius = T.R.lg,
		Z = 10,
		Deep = true,
	})
	local railPad = UIKit.Pad(rail, 8)
	local railList = UIKit.List(rail, 8, false, Enum.HorizontalAlignment.Center)
	railList.VerticalAlignment = Enum.VerticalAlignment.Top

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
		Anchor = Vector2.new(0.5, 1),
		Radius = T.R.lg,
		Z = 12,
		Deep = true,
		AccentBar = true,
	})
	local actPad = UIKit.Pad(actions, 12)
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 1, 0)
	row.ZIndex = 13
	row.Parent = actions
	local rowList = UIKit.List(row, 12, true, Enum.HorizontalAlignment.Center)
	rowList.VerticalAlignment = Enum.VerticalAlignment.Center

	local autoBtn = UIKit.Button({
		Name = "Auto",
		Parent = row,
		Text = "АВТО",
		Color = T.AutoOff,
		Color2 = T.AutoOffDeep,
		SizePx = 15,
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
		Color = T.Click,
		Color2 = T.ClickDeep,
		SizePx = 22,
		Radius = T.R.md,
		Order = 2,
		Z = 14,
		OnClick = function()
			Net.Swing("manual")
		end,
	})
	clickBtn.Font = T.Font.Num

	local rebBtn = UIKit.Button({
		Name = "Rebirth",
		Parent = row,
		Text = "R↑",
		Color = T.AccentDeep,
		Color2 = Color3.fromRGB(120, 88, 30),
		TextColor = T.Text, -- bright on gold, not dark gold-on-brown
		SizePx = 18,
		Radius = T.R.md,
		Order = 3,
		Z = 14,
		OnClick = function()
			openModal("rebirth", nil)
		end,
	})

	local rbHost = Instance.new("Frame")
	rbHost.Name = "RebirthProg"
	rbHost.BackgroundTransparency = 1
	rbHost.AnchorPoint = Vector2.new(0.5, 1)
	rbHost.ZIndex = 11
	rbHost.Parent = root
	local rbTrack, rbFill = UIKit.Bar(rbHost, 0, T.Accent, 7)

	local questBadge = UIKit.Label({
		Name = "QuestBadge",
		Parent = railBtns.quests,
		Text = "",
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -4, 0, -4),
		Anchor = Vector2.new(1, 0),
		Color = T.Text,
		SizePx = 11,
		Font = T.Font.Num,
		X = Enum.TextXAlignment.Center,
		Z = 20,
	})
	questBadge.BackgroundColor3 = T.Bad
	questBadge.BackgroundTransparency = 0
	questBadge.TextColor3 = Color3.new(1, 1, 1)
	questBadge.Visible = false
	UIKit.Corner(questBadge, 99)

	local function applyMetrics(m: Layout.Metrics)
		top.Size = UDim2.new(1, -(m.railW + m.pad * 2), 0, m.topH)
		top.Position = UDim2.fromOffset(m.railW + m.pad, m.pad)
		topList.Padding = UDim.new(0, m.chipGap)

		-- chip widths flex a bit by content role
		local chipWs = {
			math.floor(118 * m.scale),
			math.floor(96 * m.scale),
			math.floor(112 * m.scale),
			math.floor(118 * m.scale),
			math.floor(104 * m.scale),
			math.floor(148 * m.scale),
			math.floor(112 * m.scale),
		}
		for i, chip in ipairs(chips) do
			chip.Size = UDim2.fromOffset(chipWs[i] or math.floor(110 * m.scale), m.chipH)
			local val = chip:FindFirstChild("Value")
			if val and val:IsA("TextLabel") then
				val.TextSize = m.fontMd + 1
			end
		end

		rail.Size = UDim2.new(0, m.railW, 1, -(m.topH + m.actionH + m.pad * 3))
		rail.Position = UDim2.fromOffset(m.pad, m.topH + m.pad * 2)
		railPad.PaddingTop = UDim.new(0, m.pad * 0.7)
		railPad.PaddingBottom = UDim.new(0, m.pad * 0.7)
		railPad.PaddingLeft = UDim.new(0, m.pad * 0.55)
		railPad.PaddingRight = UDim.new(0, m.pad * 0.55)
		railList.Padding = UDim.new(0, m.railGap)

		for _, b in railBtns do
			b.Size = UDim2.fromOffset(m.railBtn, m.railBtn)
			b.TextSize = m.fontMd
		end

		actions.Size = UDim2.fromOffset(m.actionW, m.actionH)
		actions.Position = UDim2.new(0.5, 0, 1, -m.pad)
		actPad.PaddingTop = UDim.new(0, m.pad * 0.75)
		actPad.PaddingBottom = UDim.new(0, m.pad * 0.75)
		actPad.PaddingLeft = UDim.new(0, m.pad)
		actPad.PaddingRight = UDim.new(0, m.pad)
		rowList.Padding = UDim.new(0, m.actionGap)

		autoBtn.Size = UDim2.fromOffset(m.btnAutoW, m.btnH)
		autoBtn.TextSize = m.fontMd + 1
		clickBtn.Size = UDim2.fromOffset(m.btnClickW, m.clickH)
		clickBtn.TextSize = m.fontXl
		rebBtn.Size = UDim2.fromOffset(m.btnRebW, m.btnH)
		rebBtn.TextSize = m.fontLg

		rbHost.Size = UDim2.fromOffset(m.actionW, 10)
		rbHost.Position = UDim2.new(0.5, 0, 1, -(m.actionH + m.pad + 8))
		rbTrack.Size = UDim2.new(1, 0, 0, math.max(6, math.floor(7 * m.scale)))
	end

	Layout.Bind(applyMetrics)

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
				g.Color = ColorSequence.new(T.AutoOn, T.AutoOnDeep)
			end
		else
			autoBtn.Text = "АВТО"
			autoBtn.TextColor3 = T.Text -- always bright
			local g = autoBtn:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOff, T.AutoOffDeep)
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
		questBadge.Visible = ready > 0
		if ready > 0 then
			questBadge.Text = tostring(ready)
		end

		local panel = store:PeekPanel()
		for id, b in railBtns do
			local active = id == panel
			local g = b:FindFirstChildOfClass("UIGradient")
			if g then
				if active then
					g.Color = ColorSequence.new(T.AccentDeep, Color3.fromRGB(120, 88, 30))
					b.TextColor3 = T.Text
				else
					g.Color = ColorSequence.new(T.Glass3, T.Glass2)
					b.TextColor3 = T.Text
				end
			end
		end
	end

	return api
end

return Hud
