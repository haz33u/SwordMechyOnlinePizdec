--!strict
--[[
	Bright idle HUD:
	- Left rail packs to N buttons (height = N×btn, not stretched full screen)
	- Stats above bottom dock
	- Juicy action bar (АВТО / КЛИК / R↑)
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

export type HudApi = {
	Refresh: (self: any) -> (),
	GetClickButton: (self: any) -> TextButton,
}

function Hud.Mount(gui: ScreenGui, store: any, openModal: (string, any?) -> (), onManualClick: (() -> ())?): HudApi
	local root = Instance.new("Folder")
	root.Name = "HUD"
	root.Parent = gui

	local nRail = #RAIL

	---------------------------------------------------------------- RAIL (compact pack)
	local rail = UIKit.Glass({
		Name = "Rail",
		Parent = root,
		Size = UDim2.fromOffset(68, 400),
		Position = UDim2.fromOffset(12, 12),
		Radius = T.R.lg,
		Z = 10,
		Deep = false,
	})
	rail.ClipsDescendants = false
	local railPad = UIKit.Pad(rail, 10)
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
		b.TextColor3 = T.Text
		railBtns[item.id] = b
	end

	---------------------------------------------------------------- STATS
	local stats = Instance.new("Frame")
	stats.Name = "StatsStrip"
	stats.BackgroundTransparency = 1
	stats.Size = UDim2.new(1, -100, 0, 52)
	stats.Position = UDim2.new(0.5, 10, 1, -110)
	stats.AnchorPoint = Vector2.new(0.5, 1)
	stats.ZIndex = 11
	stats.Parent = root
	local statsList = UIKit.List(stats, 8, true, Enum.HorizontalAlignment.Center)
	statsList.VerticalAlignment = Enum.VerticalAlignment.Center

	local chipPower = UIKit.Chip({ Parent = stats, Title = "СИЛА", Value = "—", Accent = T.Chip.Power, Order = 1 })
	local chipCps = UIKit.Chip({ Parent = stats, Title = "CPS", Value = "—", Accent = T.Chip.Cps, Order = 2 })
	local chipDps = UIKit.Chip({ Parent = stats, Title = "DPS", Value = "—", Accent = T.Chip.Dps, Order = 3 })
	local chipCoins = UIKit.Chip({ Parent = stats, Title = "МОНЕТЫ", Value = "—", Accent = T.Chip.Coins, Order = 4 })
	local chipClicks = UIKit.Chip({ Parent = stats, Title = "КЛИКИ", Value = "—", Accent = T.Chip.Clicks, Order = 5 })
	local chipLoc = UIKit.Chip({ Parent = stats, Title = "ЛОКАЦИЯ", Value = "—", Accent = T.Chip.Loc, Order = 6 })
	local chipR = UIKit.Chip({ Parent = stats, Title = "REBIRTH", Value = "—", Accent = T.Chip.Rebirth, Order = 7 })
	local chips = { chipPower, chipCps, chipDps, chipCoins, chipClicks, chipLoc, chipR }

	---------------------------------------------------------------- ACTIONS (juicy)
	local actions = UIKit.Glass({
		Name = "Actions",
		Parent = root,
		Size = UDim2.fromOffset(420, 80),
		Position = UDim2.new(0.5, 0, 1, -14),
		Anchor = Vector2.new(0.5, 1),
		Radius = T.R.xl,
		Z = 12,
		Deep = false,
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
		Size = UDim2.fromOffset(110, 54),
		Color = T.AutoOff,
		Color2 = T.AutoOffDeep,
		TextColor = T.Text,
		SizePx = 16,
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
		Size = UDim2.fromOffset(160, 54),
		Color = T.Click,
		Color2 = T.ClickDeep,
		TextColor = T.Text,
		SizePx = 24,
		Radius = T.R.lg,
		Order = 2,
		Z = 14,
		OnClick = function()
			Net.Swing("manual")
			if onManualClick then
				onManualClick()
			end
		end,
	})
	clickBtn.Font = T.Font.Num

	local rebBtn = UIKit.Button({
		Name = "Rebirth",
		Parent = row,
		Text = "R↑",
		Size = UDim2.fromOffset(100, 54),
		Color = T.AccentDeep,
		Color2 = Color3.fromRGB(200, 120, 30),
		TextColor = T.Text,
		SizePx = 20,
		Radius = T.R.lg,
		Order = 3,
		Z = 14,
		OnClick = function()
			openModal("rebirth", nil)
		end,
	})

	local rbHost = Instance.new("Frame")
	rbHost.Name = "RebirthProg"
	rbHost.BackgroundTransparency = 1
	rbHost.Size = UDim2.fromOffset(420, 8)
	rbHost.Position = UDim2.new(0.5, 0, 1, -150)
	rbHost.AnchorPoint = Vector2.new(0.5, 1)
	rbHost.ZIndex = 11
	rbHost.Parent = root
	local rbTrack, rbFill = UIKit.Bar(rbHost, 0, T.Accent, 8)

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
	questBadge.BackgroundColor3 = T.Bad
	questBadge.BackgroundTransparency = 0
	questBadge.TextColor3 = Color3.new(1, 1, 1)
	questBadge.Visible = false
	UIKit.Corner(questBadge, 99)

	local function applyMetrics(m: Layout.Metrics)
		-- Compact rail: fixed height for N buttons, top-left (not full stretch)
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

		actions.Size = UDim2.fromOffset(m.actionW, m.actionH)
		actions.Position = UDim2.new(0.5, 0, 1, -m.pad)
		actions.AnchorPoint = Vector2.new(0.5, 1)
		actPad.PaddingTop = UDim.new(0, m.pad)
		actPad.PaddingBottom = UDim.new(0, m.pad)
		actPad.PaddingLeft = UDim.new(0, m.pad)
		actPad.PaddingRight = UDim.new(0, m.pad)
		rowList.Padding = UDim.new(0, m.actionGap)

		autoBtn.Size = UDim2.fromOffset(m.btnAutoW, m.btnH)
		autoBtn.TextSize = m.fontMd + 1
		autoBtn.TextColor3 = T.Text
		clickBtn.Size = UDim2.fromOffset(m.btnClickW, m.btnH)
		clickBtn.TextSize = m.fontXl + 2
		clickBtn.TextColor3 = T.Text
		rebBtn.Size = UDim2.fromOffset(m.btnRebW, m.btnH)
		rebBtn.TextSize = m.fontLg + 1
		rebBtn.TextColor3 = T.Text

		stats.Size = UDim2.new(1, -(m.railW + m.pad * 3), 0, m.statsH)
		stats.Position = UDim2.new(0.5, m.railW * 0.15, 1, -(m.actionH + m.pad + 8))
		stats.AnchorPoint = Vector2.new(0.5, 1)
		statsList.Padding = UDim.new(0, m.chipGap)

		for i, chip in ipairs(chips) do
			local w = m.chipW
			if i == 6 then
				w = math.floor(m.chipW * 1.2)
			end
			chip.Size = UDim2.fromOffset(w, m.chipH)
			local val = chip:FindFirstChild("Value")
			if val and val:IsA("TextLabel") then
				val.TextSize = m.fontMd + 1
			end
			for _, d in chip:GetChildren() do
				if d:IsA("TextLabel") and d.Name ~= "Value" then
					d.TextColor3 = T.TextSoft
					d.TextSize = m.fontSm
				end
			end
		end

		rbHost.Size = UDim2.fromOffset(m.actionW, 8)
		rbHost.Position = UDim2.new(0.5, 0, 1, -(m.actionH + m.statsH + m.pad + 12))
		rbHost.AnchorPoint = Vector2.new(0.5, 1)
		rbTrack.Size = UDim2.new(1, 0, 0, 8)
	end

	pcall(function()
		Layout.Bind(applyMetrics, nRail)
	end)

	local api = {} :: any

	function api.Refresh()
		local st = store:PeekStats()
		local profile = store:PeekProfile()
		if not st then
			return
		end

		UIKit.SetChipValue(chipPower, Format.Num(st.damagePerClick or st.totalPower))
		UIKit.SetChipValue(chipCps, string.format("%.1f", st.cps or 0))
		UIKit.SetChipValue(chipDps, Format.Num(st.dps))
		UIKit.SetChipValue(chipCoins, Format.Num(st.coins))
		UIKit.SetChipValue(chipClicks, Format.Num(st.totalClicks))
		UIKit.SetChipValue(chipLoc, LOC[st.location or 1] or ("#" .. tostring(st.location)))
		UIKit.SetChipValue(chipR, string.format("R%d %s", st.rebirthLevel or 0, Format.Mult(st.rebirthMult)))

		local cost = st.nextRebirthCost or 1
		local dmg = st.lifetimeDamage or 0
		local pct = cost > 0 and math.clamp(dmg / cost, 0, 1) or 0
		rbFill.Size = UDim2.new(pct, 0, 1, 0)

		if st.autoClicker then
			autoBtn.Text = "АВТО ON"
			autoBtn.TextColor3 = T.Text
			local g = autoBtn:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOn, T.AutoOnDeep)
			end
		else
			autoBtn.Text = "АВТО"
			autoBtn.TextColor3 = T.Text
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
					g.Color = ColorSequence.new(T.AccentDeep, Color3.fromRGB(200, 120, 30))
				else
					g.Color = ColorSequence.new(T.Glass3, T.Glass2)
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
