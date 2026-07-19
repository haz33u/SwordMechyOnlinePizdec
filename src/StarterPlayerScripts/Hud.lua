--!strict
--[[
	Main HUD — SCREEENS "главный интерфейс пользователя":
	- top-left: active boosts
	- bottom-center: coins + power, Q=rebirth, E=inventory
	- left rail: menus
	CPS/DPS/Clicks live in character/profile panel, not here.
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
	{ id = "locations", glyph = "TP" },
	{ id = "dungeons", glyph = "DG" },
	{ id = "cases", glyph = "CS" },
	{ id = "shop", glyph = "$" },
}

local LOC = {
	[1] = "Dark Forest",
	[2] = "Pirate Shore",
	[3] = "Shinobi Lands",
	[4] = "Polar Tundra",
}

-- Boost row style (top-left). Data from profile.boosts when present.
local BOOST_META = {
	{ key = "money", icon = "🪙", color = Color3.fromRGB(200, 130, 40), name = "Coins" },
	{ key = "power", icon = "💪", color = Color3.fromRGB(200, 55, 70), name = "Power" },
	{ key = "damage", icon = "⚡", color = Color3.fromRGB(120, 60, 200), name = "Damage" },
	{ key = "luck", icon = "🍀", color = Color3.fromRGB(50, 160, 70), name = "Luck" },
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

	---------------------------------------------------------------- RAIL (left menus)
	local rail = UIKit.Glass({
		Name = "Rail",
		Parent = root,
		Size = UDim2.fromOffset(72, 420),
		Position = UDim2.fromOffset(12, 12),
		Radius = T.R.sm,
		Z = 10,
		Deep = true,
	})
	local railPad = UIKit.Pad(rail, 10)
	local railList = UIKit.List(rail, 8, false, Enum.HorizontalAlignment.Center)
	railList.VerticalAlignment = Enum.VerticalAlignment.Top
	UIKit.SizeConstraint(rail, Vector2.new(56, 200), Vector2.new(120, 900))

	-- Inventory shell tabs (INVETAR): open weapons panel with tab
	local INV_TABS = {
		weapons = true,
		pets = true,
		auras = true,
		relics = true,
		cases = true,
		shop = true,
		character = true, -- profile tab inside inventory
	}

	local railBtns: { [string]: TextButton } = {}
	for i, item in ipairs(RAIL) do
		local b = UIKit.IconBtn({
			Name = item.id,
			Parent = rail,
			Glyph = item.glyph,
			Order = i,
			OnClick = function()
				if INV_TABS[item.id] then
					local tab = item.id == "character" and "profile" or item.id
					(store :: any)._invTab = tab
					store:OpenPanel("weapons")
				else
					store:OpenPanel(item.id)
				end
			end,
		})
		railBtns[item.id] = b
	end

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

	---------------------------------------------------------------- TOP-LEFT BOOSTS
	local boosts = Instance.new("Frame")
	boosts.Name = "Boosts"
	boosts.BackgroundTransparency = 1
	boosts.Size = UDim2.fromOffset(220, 160)
	boosts.Position = UDim2.fromOffset(90, 14)
	boosts.ZIndex = 11
	boosts.Parent = root
	local boostList = UIKit.List(boosts, 6, false)
	boostList.VerticalAlignment = Enum.VerticalAlignment.Top
	local boostRows: { Frame } = {}

	local function makeBoostRow(meta: any): Frame
		local row = Instance.new("Frame")
		row.Name = meta.key
		row.BackgroundColor3 = Color3.new(1, 1, 1)
		row.BorderSizePixel = 0
		row.Size = UDim2.fromOffset(200, 28)
		row.ZIndex = 12
		row.Visible = false
		row.Parent = boosts
		UIKit.Corner(row, T.R.sm)
		UIKit.Stroke(row, meta.color, 1.2, 0.25)
		UIKit.Gradient(row, meta.color:Lerp(Color3.new(0, 0, 0), 0.45), meta.color:Lerp(Color3.new(0, 0, 0), 0.65), 0)

		UIKit.Label({
			Name = "Pct",
			Parent = row,
			Text = "+0%",
			Size = UDim2.fromOffset(52, 28),
			Position = UDim2.fromOffset(6, 0),
			SizePx = 13,
			Font = T.Font.Title,
			Color = Color3.new(1, 1, 1),
			Z = 13,
		})
		UIKit.Label({
			Name = "Scope",
			Parent = row,
			Text = "Local",
			Size = UDim2.new(1, -64, 1, 0),
			Position = UDim2.fromOffset(58, 0),
			SizePx = 12,
			Color = Color3.fromRGB(240, 240, 245),
			Z = 13,
		})
		return row
	end

	for _, meta in ipairs(BOOST_META) do
		boostRows[meta.key] = makeBoostRow(meta)
	end

	---------------------------------------------------------------- BOTTOM-CENTER: Q | coins/power | E
	local bal = UIKit.Glass({
		Name = "BalanceBar",
		Parent = root,
		Size = UDim2.fromOffset(280, 72),
		Position = UDim2.new(0.5, 0, 1, -18),
		Anchor = Vector2.new(0.5, 1),
		Radius = T.R.md,
		Z = 12,
		Deep = true,
	})
	UIKit.Stroke(bal, T.Stroke, 1.2, 0.25)

	-- Q = rebirth (left)
	local qBtn = UIKit.Button({
		Name = "RebirthQ",
		Parent = bal,
		Text = "Q",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(0, 10, 0.5, 0),
		Anchor = Vector2.new(0, 0.5),
		Color = Color3.fromRGB(70, 90, 160),
		Color2 = Color3.fromRGB(40, 55, 110),
		Primary = true,
		SizePx = 16,
		Compact = true,
		Radius = T.R.sm,
		Z = 14,
		OnClick = function()
			openModal("rebirth", nil)
		end,
	})
	UIKit.Label({
		Parent = bal,
		Text = "♻",
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(0, 52, 0.5, -16),
		SizePx = 12,
		Color = T.Accent,
		Z = 14,
	})

	-- center metrics
	local mid = Instance.new("Frame")
	mid.Name = "Mid"
	mid.BackgroundTransparency = 1
	mid.Size = UDim2.fromOffset(130, 56)
	mid.Position = UDim2.new(0.5, 0, 0.5, 0)
	mid.AnchorPoint = Vector2.new(0.5, 0.5)
	mid.ZIndex = 13
	mid.Parent = bal

	local coinLab = UIKit.Label({
		Name = "Coins",
		Parent = mid,
		Text = "🪙  0",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 2),
		SizePx = 16,
		Font = T.Font.Num,
		Color = T.Gold,
		X = Enum.TextXAlignment.Center,
		Z = 14,
	})
	local powerLab = UIKit.Label({
		Name = "Power",
		Parent = mid,
		Text = "⚔  0",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 28),
		SizePx = 16,
		Font = T.Font.Num,
		Color = Color3.fromRGB(255, 120, 90),
		X = Enum.TextXAlignment.Center,
		Z = 14,
	})

	-- E = inventory (right)
	local eBtn = UIKit.Button({
		Name = "InvE",
		Parent = bal,
		Text = "E",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -10, 0.5, 0),
		Anchor = Vector2.new(1, 0.5),
		Color = Color3.fromRGB(70, 90, 160),
		Color2 = Color3.fromRGB(40, 55, 110),
		Primary = true,
		SizePx = 16,
		Compact = true,
		Radius = T.R.sm,
		Z = 14,
		OnClick = function()
			store:OpenPanel("weapons")
		end,
	})
	UIKit.Label({
		Parent = bal,
		Text = "🎒",
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -70, 0.5, -16),
		SizePx = 12,
		Color = T.TextSoft,
		Z = 14,
	})

	-- rebirth progress thin bar above balance
	local rbHost = Instance.new("Frame")
	rbHost.Name = "RebirthProg"
	rbHost.BackgroundTransparency = 1
	rbHost.Size = UDim2.fromOffset(280, 6)
	rbHost.Position = UDim2.new(0.5, 0, 1, -96)
	rbHost.AnchorPoint = Vector2.new(0.5, 1)
	rbHost.ZIndex = 11
	rbHost.Parent = root
	local rbTrack, rbFill = UIKit.Bar(rbHost, 0, T.Accent, 6)

	-- auto status chip (toggle still T) — small, above balance
	local autoChip = UIKit.Button({
		Name = "AutoChip",
		Parent = root,
		Text = "AUTO",
		Size = UDim2.fromOffset(72, 28),
		Position = UDim2.new(0.5, 0, 1, -108),
		Anchor = Vector2.new(0.5, 1),
		Color = T.AutoOff,
		Color2 = T.AutoOffDeep,
		SizePx = 12,
		Compact = true,
		Z = 12,
		OnClick = function()
			Net.ToggleAuto()
		end,
	})

	-- ClickPop anchor (center of screen). Actual swing is App-wide LMB/touch.
	local clickAnchor = Instance.new("Frame")
	clickAnchor.Name = "ClickAnchor"
	clickAnchor.BackgroundTransparency = 1
	clickAnchor.Size = UDim2.fromOffset(1, 1)
	clickAnchor.Position = UDim2.new(0.5, 0, 0.55, 0)
	clickAnchor.AnchorPoint = Vector2.new(0.5, 0.5)
	clickAnchor.ZIndex = 1
	clickAnchor.Parent = root
	local _ = onManualClick

	local function applyMetrics(m: Layout.Metrics)
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

		boosts.Position = UDim2.fromOffset(m.railW + m.pad * 2, m.pad)

		local balW = math.clamp(m.actionW * 0.72, 240, 320)
		bal.Size = UDim2.fromOffset(balW, 68)
		bal.Position = UDim2.new(0.5, 0, 1, -m.pad)
		rbHost.Size = UDim2.fromOffset(balW, 6)
		rbHost.Position = UDim2.new(0.5, 0, 1, -(m.pad + 78))
		autoChip.Position = UDim2.new(0.5, 0, 1, -(m.pad + 90))
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

		coinLab.Text = "🪙  " .. Format.Num(st.coins)
		powerLab.Text = "⚔  " .. Format.Num(st.damagePerClick or st.totalPower)

		-- dual-cost rebirth bar
		local pct = st.rebirthProgress
		if type(pct) ~= "number" then
			local cost = st.nextRebirthCost or 1
			local coinCost = st.nextRebirthCoinCost or 0
			local dmg = st.lifetimeDamage or 0
			local coins = st.coins or 0
			local pD = cost > 0 and math.clamp(dmg / cost, 0, 1) or 1
			local pC = coinCost > 0 and math.clamp(coins / coinCost, 0, 1) or 1
			pct = math.min(pD, pC)
		end
		rbFill.Size = UDim2.new(math.clamp(pct :: number, 0, 1), 0, 1, 0)

		if st.autoClicker then
			autoChip.Text = "AUTO ON"
			local g = autoChip:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOn, T.AutoOnDeep)
			end
		else
			autoChip.Text = "AUTO"
			local g = autoChip:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = ColorSequence.new(T.AutoOff, T.AutoOffDeep)
			end
		end
		local alab = autoChip:FindFirstChild("Label")
		if alab and alab:IsA("TextLabel") then
			alab.TextColor3 = Color3.new(1, 1, 1)
		end

		-- boosts: profile.boosts = { money = {pct=0.5, scope="local"}, ... }
		local boostsData = (profile and profile.boosts) or {}
		for _, meta in ipairs(BOOST_META) do
			local row = boostRows[meta.key]
			local b = boostsData[meta.key]
			if type(b) == "table" and type(b.pct) == "number" and b.pct > 0 then
				row.Visible = true
				local pctLab = row:FindFirstChild("Pct")
				local scopeLab = row:FindFirstChild("Scope")
				if pctLab and pctLab:IsA("TextLabel") then
					pctLab.Text = string.format("+%d%%", math.floor(b.pct * 100 + 0.5))
				end
				if scopeLab and scopeLab:IsA("TextLabel") then
					local sc = tostring(b.scope or "local")
					scopeLab.Text = (sc == "global" or sc == "Global") and "Global" or "Local"
				end
			else
				row.Visible = false
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
					g.Color = ColorSequence.new(T.Accent, T.AccentDeep)
				else
					g.Color = ColorSequence.new(T.Surface3, T.Surface2)
				end
			end
			b.TextColor3 = T.Text
		end

		-- keep LOC for future top bar if needed
		local _loc = LOC[st.location or 1]
		local _ = _loc
	end

	function api.GetClickButton(): GuiObject
		return clickAnchor
	end

	return api
end

return Hud
