--!strict
--[[
	Responsive HUD with root UIScale + packed rail + metric chips.
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

local METRICS = {
	{ key = "Power", title = "СИЛА" },
	{ key = "Cps", title = "CPS" },
	{ key = "Dps", title = "DPS" },
	{ key = "Coins", title = "МОНЕТЫ" },
	{ key = "Clicks", title = "КЛИКИ" },
	{ key = "Loc", title = "ЛОКАЦИЯ" },
	{ key = "Rebirth", title = "REBIRTH" },
}

function Hud.Mount(
	gui: ScreenGui,
	store: any,
	openModal: (string, any?) -> (),
	onManualClick: (() -> ())?
)
	local root = Instance.new("Folder")
	root.Name = "HUD"
	root.Parent = gui

	local nRail = #RAIL

	-- Root scale driver (applies to whole ScreenGui via App, but we also bind here if needed)
	-- Hud only positions; App owns UIScale on gui.

	---------------------------------------------------------------- RAIL — height packs to N
	local rail = UIKit.Glass({
		Name = "Rail",
		Parent = root,
		Size = UDim2.fromOffset(72, 420),
		Position = UDim2.fromScale(0, 0) + UDim2.fromOffset(12, 12),
		Radius = T.R.lg,
		Z = 10,
	})
	local railPad = UIKit.Pad(rail, 10)
	local railList = UIKit.List(rail, 8, false, Enum.HorizontalAlignment.Center)
	railList.VerticalAlignment = Enum.VerticalAlignment.Top
	UIKit.SizeConstraint(rail, Vector2.new(56, 200), Vector2.new(120, 900))

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

	---------------------------------------------------------------- STATS strip (above bottom CTA)
	local stats = Instance.new("Frame")
	stats.Name = "StatsStrip"
	stats.BackgroundTransparency = 1
	stats.Size = UDim2.new(0.85, 0, 0, 56)
	stats.Position = UDim2.new(0.5, 0, 1, -120)
	stats.AnchorPoint = Vector2.new(0.5, 1)
	stats.ZIndex = 11
	stats.Parent = root
	local statsList = UIKit.List(stats, 10, true, Enum.HorizontalAlignment.Center)
	statsList.VerticalAlignment = Enum.VerticalAlignment.Center

	local chips: { [string]: Frame } = {}
	for i, m in ipairs(METRICS) do
		local chip = UIKit.MetricChip({
			Parent = stats,
			Key = m.key,
			Title = m.title,
			Value = "—",
			Order = i,
			W = 120,
			H = 52,
		})
		chips[m.key] = chip
	end

	---------------------------------------------------------------- ACTIONS (primary CTAs)
	-- Clean container — NO AccentBar (was the thin gold strip under CTAs)
	local actions = UIKit.Glass({
		Name = "Actions",
		Parent = root,
		Size = UDim2.new(0.38, 0, 0, 88),
		Position = UDim2.new(0.5, 0, 1, -14),
		Anchor = Vector2.new(0.5, 1),
		Radius = T.R.xl,
		Z = 12,
		AccentBar = false,
		Deep = false,
	})
	UIKit.SizeConstraint(actions, Vector2.new(340, 72), Vector2.new(560, 120))
	UIKit.Stroke(actions, T.Stroke, 1.5, 0.5)
	local actPad = UIKit.Pad(actions, 14)

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.ZIndex = 13
	row.Parent = actions
	local rowList = UIKit.List(row, 12, true, Enum.HorizontalAlignment.Center)
	rowList.VerticalAlignment = Enum.VerticalAlignment.Center

	local autoBtn = UIKit.Button({
		Name = "Auto",
		Parent = row,
		Text = "АВТО",
		Size = UDim2.new(0.26, 0, 0, 58),
		Color = T.AutoOff,
		Color2 = T.AutoOffDeep,
		SizePx = 18,
		Radius = T.R.lg,
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
		Size = UDim2.new(0.4, 0, 0, 58),
		Color = T.Click,
		Color2 = T.ClickDeep,
		SizePx = 26,
		Radius = T.R.lg,
		Primary = true,
		Order = 2,
		Z = 14,
		OnClick = function()
			Net.Swing("manual")
			if onManualClick then
				onManualClick()
			end
		end,
	})

	local rebBtn = UIKit.Button({
		Name = "Rebirth",
		Parent = row,
		Text = "R↑",
		Size = UDim2.new(0.24, 0, 0, 58),
		Color = T.GoldDeep,
		Color2 = Color3.fromRGB(200, 120, 20),
		SizePx = 22,
		Radius = T.R.lg,
		Primary = true,
		Order = 3,
		Z = 14,
		OnClick = function()
			openModal("rebirth", nil)
		end,
	})

	-- Rebirth progress sits ABOVE the action panel (not under buttons)
	local rbHost = Instance.new("Frame")
	rbHost.Name = "RebirthProg"
	rbHost.BackgroundTransparency = 1
	rbHost.Size = UDim2.new(0.38, 0, 0, 8)
	rbHost.Position = UDim2.new(0.5, 0, 1, -170)
	rbHost.AnchorPoint = Vector2.new(0.5, 1)
	rbHost.ZIndex = 11
	rbHost.Parent = root
	local rbTrack, rbFill = UIKit.Bar(rbHost, 0, T.Gold, 8)

	local questBadge = UIKit.Label({
		Name = "QuestBadge",
		Parent = railBtns.quests,
		Text = "",
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -2, 0, -2),
		Anchor = Vector2.new(1, 0),
		Color = T.Text,
		SizePx = 11,
		Font = T.Font.Num,
		X = Enum.TextXAlignment.Center,
		Z = 20,
	})
	questBadge.BackgroundColor3 = T.Danger
	questBadge.BackgroundTransparency = 0
	questBadge.Visible = false
	UIKit.Corner(questBadge, 99)

	local function applyMetrics(m: Layout.Metrics)
		-- compact rail pack
		rail.Size = UDim2.fromOffset(m.railW, m.railH)
		rail.Position = UDim2.fromOffset(m.pad, m.pad)
		railPad.PaddingTop = UDim.new(0, m.railPad)
		railPad.PaddingBottom = UDim.new(0, m.railPad)
		railPad.PaddingLeft = UDim.new(0, m.railPad)
		railPad.PaddingRight = UDim.new(0, m.railPad)
		railList.Padding = UDim.new(0, m.railGap)

		for _, b in railBtns do
			b.Size = UDim2.fromOffset(m.railBtn, m.railBtn)
			b.TextSize = math.clamp(math.floor(m.railBtn * 0.34), 12, 18)
			b.TextColor3 = T.Text
		end

		-- scale-based action bar width
		actions.Size = UDim2.new(0, m.actionW, 0, m.actionH)
		actions.Position = UDim2.new(0.5, 0, 1, -m.pad)
		actPad.PaddingTop = UDim.new(0, m.pad)
		actPad.PaddingBottom = UDim.new(0, m.pad)
		actPad.PaddingLeft = UDim.new(0, m.pad)
		actPad.PaddingRight = UDim.new(0, m.pad)
		rowList.Padding = UDim.new(0, m.actionGap)

		autoBtn.Size = UDim2.fromOffset(m.btnAutoW, m.btnH)
		autoBtn.TextSize = m.fontMd + 1
		clickBtn.Size = UDim2.fromOffset(m.btnClickW, m.btnH)
		clickBtn.TextSize = m.fontXl + 2
		rebBtn.Size = UDim2.fromOffset(m.btnRebW, m.btnH)
		rebBtn.TextSize = m.fontLg + 1

		stats.Size = UDim2.new(1, -(m.railW + m.pad * 3), 0, m.statsH)
		stats.Position = UDim2.new(0.5, m.railW * 0.12, 1, -(m.actionH + m.pad + 8))
		statsList.Padding = UDim.new(0, m.chipGap)

		for key, chip in chips do
			local w = m.chipW
			if key == "Loc" then
				w = math.floor(m.chipW * 1.2)
			end
			chip.Size = UDim2.fromOffset(w, m.chipH)
		end

		rbHost.Size = UDim2.fromOffset(m.actionW, 8)
		rbHost.Position = UDim2.new(0.5, 0, 1, -(m.actionH + m.statsH + m.pad + 14))
		rbTrack.Size = UDim2.new(1, 0, 0, 8)
	end

	pcall(function()
		Layout.Bind(applyMetrics, nRail)
	end)

	local api: any = {}

	function api.Refresh()
		local st = store:PeekStats()
		local profile = store:PeekProfile()
		if not st then
			return
		end

		UIKit.SetChipValue(chips.Power, Format.Num(st.damagePerClick or st.totalPower))
		UIKit.SetChipValue(chips.Cps, string.format("%.1f", st.cps or 0))
		UIKit.SetChipValue(chips.Dps, Format.Num(st.dps))
		UIKit.SetChipValue(chips.Coins, Format.Num(st.coins))
		UIKit.SetChipValue(chips.Clicks, Format.Num(st.totalClicks))
		UIKit.SetChipValue(chips.Loc, LOC[st.location or 1] or ("#" .. tostring(st.location)))
		UIKit.SetChipValue(chips.Rebirth, string.format("R%d %s", st.rebirthLevel or 0, Format.Mult(st.rebirthMult)))

		local cost = st.nextRebirthCost or 1
		local dmg = st.lifetimeDamage or 0
		rbFill.Size = UDim2.new(cost > 0 and math.clamp(dmg / cost, 0, 1) or 0, 0, 1, 0)

		if st.autoClicker then
			autoBtn.Text = "АВТО ON"
			local g = autoBtn:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOn, T.AutoOnDeep)
			end
		else
			autoBtn.Text = "АВТО"
			local g = autoBtn:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOff, T.AutoOffDeep)
			end
		end
		-- force white labels (child Label from UIKit.Button)
		for _, btn in { autoBtn, clickBtn, rebBtn } do
			local lab = btn:FindFirstChild("Label")
			if lab and lab:IsA("TextLabel") then
				lab.TextColor3 = Color3.fromRGB(255, 255, 255)
				lab.TextStrokeTransparency = 0.45
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
					g.Color = ColorSequence.new(T.GoldDeep, Color3.fromRGB(200, 120, 20))
				else
					g.Color = ColorSequence.new(T.Surface3, T.Surface2)
				end
			end
			b.TextColor3 = T.Text
		end
	end

	function api.GetClickButton(): TextButton
		return clickBtn
	end

	return api
end

return Hud
