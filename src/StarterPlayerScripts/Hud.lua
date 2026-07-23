--!strict
--[[
	Main HUD — SCREEENS "главный интерфейс пользователя":
	- top-left: active boosts
	- bottom-center: coins + power, Q=rebirth, E=inventory
	- left rail: menus
	CPS/DPS/Clicks live in character/profile panel, not here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)
local Layout = require(script.Parent.Layout)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared.Formulas)

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
	---------------------------------------------------------------- DUNGEON QUICK TELEPORT BUTTON
	local dungBanner = Instance.new("Frame")
	dungBanner.Name = "DungeonQuickTeleport"
	dungBanner.Size = UDim2.fromOffset(210, 48)
	dungBanner.Position = UDim2.new(0, 96, 1, -80)
	dungBanner.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
	dungBanner.BackgroundTransparency = 0.15
	dungBanner.ZIndex = 15
	dungBanner.Parent = root

	local dungCorner = Instance.new("UICorner")
	dungCorner.CornerRadius = UDim.new(0, 10)
	dungCorner.Parent = dungBanner

	local dungStroke = Instance.new("UIStroke")
	dungStroke.Color = Color3.fromRGB(180, 40, 255)
	dungStroke.Thickness = 2
	dungStroke.Parent = dungBanner

	local dungIcon = Instance.new("TextLabel")
	dungIcon.Size = UDim2.fromOffset(36, 36)
	dungIcon.Position = UDim2.fromOffset(6, 6)
	dungIcon.BackgroundTransparency = 1
	dungIcon.Text = "🏰"
	dungIcon.TextSize = 22
	dungIcon.Parent = dungBanner

	local dungTxt = Instance.new("TextLabel")
	dungTxt.Size = UDim2.new(1, -50, 1, 0)
	dungTxt.Position = UDim2.fromOffset(46, 0)
	dungTxt.BackgroundTransparency = 1
	dungTxt.Text = "DUNGEON READY!\nClick to Teleport [E]"
	dungTxt.TextColor3 = Color3.fromRGB(245, 220, 255)
	dungTxt.Font = Enum.Font.Arcade
	dungTxt.TextSize = 12
	dungTxt.TextXAlignment = Enum.TextXAlignment.Left
	dungTxt.Parent = dungBanner

	local dungBtn = Instance.new("TextButton")
	dungBtn.Size = UDim2.fromScale(1, 1)
	dungBtn.BackgroundTransparency = 1
	dungBtn.Text = ""
	dungBtn.ZIndex = 20
	dungBtn.Parent = dungBanner

	dungBtn.MouseButton1Click:Connect(function()
		store:OpenPanel("dungeons")
	end)

	---------------------------------------------------------------- EXIT DUNGEON BUTTON
	local dungExitBanner = Instance.new("Frame")
	dungExitBanner.Name = "DungeonExitButton"
	dungExitBanner.Size = UDim2.fromOffset(160, 48)
	dungExitBanner.Position = UDim2.new(0, 314, 1, -80)
	dungExitBanner.BackgroundColor3 = Color3.fromRGB(80, 20, 30)
	dungExitBanner.BackgroundTransparency = 0.15
	dungExitBanner.ZIndex = 15
	dungExitBanner.Parent = root

	local dungExitCorner = Instance.new("UICorner")
	dungExitCorner.CornerRadius = UDim.new(0, 10)
	dungExitCorner.Parent = dungExitBanner

	local dungExitStroke = Instance.new("UIStroke")
	dungExitStroke.Color = Color3.fromRGB(255, 60, 80)
	dungExitStroke.Thickness = 2
	dungExitStroke.Parent = dungExitBanner

	local dungExitTxt = Instance.new("TextLabel")
	dungExitTxt.Size = UDim2.fromScale(1, 1)
	dungExitTxt.BackgroundTransparency = 1
	dungExitTxt.Text = "🚪 EXIT DUNGEON"
	dungExitTxt.TextColor3 = Color3.fromRGB(255, 220, 220)
	dungExitTxt.Font = Enum.Font.Arcade
	dungExitTxt.TextSize = 13
	dungExitTxt.Parent = dungExitBanner

	local dungExitBtn = Instance.new("TextButton")
	dungExitBtn.Size = UDim2.fromScale(1, 1)
	dungExitBtn.BackgroundTransparency = 1
	dungExitBtn.Text = ""
	dungExitBtn.ZIndex = 20
	dungExitBtn.Parent = dungExitBanner

	dungExitBtn.MouseButton1Click:Connect(function()
		local SharedRemotes = ReplicatedStorage:FindFirstChild("Remotes")
		if SharedRemotes then
			local exitEv = SharedRemotes:FindFirstChild("ExitDungeon")
			if exitEv and exitEv:IsA("RemoteEvent") then
				exitEv:FireServer()
			end
		end
	end)

	-- Inventory shell tabs (INVETAR): open weapons panel with tab
	-- "character" / UP = dedicated Character Upgrade window (not inventory profile)
	local INV_TABS = {
		weapons = true,
		pets = true,
		auras = true,
		relics = true,
		cases = true,
		shop = true,
	}

	local railBtns: { [string]: TextButton } = {}
	for i, item in ipairs(RAIL) do
		local b = UIKit.IconBtn({
			Name = item.id,
			Parent = rail,
			Glyph = item.glyph,
			Order = i,
			OnClick = function()
				if item.id == "character" then
					-- Debug / primary: Character Upgrade panel (Figma track start)
					store:OpenPanel("character")
				elseif INV_TABS[item.id] then
					local s = store :: any
					s._invTab = item.id
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

	-- Active anomaly banner (global)
	local anomBanner = Instance.new("TextLabel")
	anomBanner.Name = "AnomalyBanner"
	anomBanner.BackgroundColor3 = Color3.fromRGB(40, 28, 60)
	anomBanner.BackgroundTransparency = 0.15
	anomBanner.BorderSizePixel = 0
	anomBanner.Size = UDim2.fromOffset(220, 36)
	anomBanner.Position = UDim2.fromOffset(90, 178)
	anomBanner.ZIndex = 12
	anomBanner.Visible = false
	anomBanner.Font = T.Font.Title
	anomBanner.TextSize = 12
	anomBanner.TextColor3 = Color3.fromRGB(255, 230, 160)
	anomBanner.TextXAlignment = Enum.TextXAlignment.Left
	anomBanner.TextTruncate = Enum.TextTruncate.AtEnd
	anomBanner.Text = ""
	anomBanner.Parent = root
	UIKit.Corner(anomBanner, T.R.sm)
	UIKit.Stroke(anomBanner, Color3.fromRGB(180, 120, 255), 1.2, 0.3)
	local anomPad = Instance.new("UIPadding")
	anomPad.PaddingLeft = UDim.new(0, 8)
	anomPad.PaddingRight = UDim.new(0, 8)
	anomPad.Parent = anomBanner

	---------------------------------------------------------------- BOTTOM-CENTER: 4 separate chips
	-- SCREEENS / Theme palette (not pure black — matches rail/windows)
	local MAKE_GOLD = T.Gold -- coin gold
	local MAKE_GOLD_GLOW = Color3.fromRGB(255, 220, 100)
	local MAKE_POWER = Color3.fromRGB(255, 120, 90)
	local MAKE_POWER_GLOW = Color3.fromRGB(255, 160, 120)
	local MAKE_PANEL = T.Surface2 -- 30,30,36 charcoal (not pure black)
	local MAKE_SECTION = T.Surface3 -- 40,40,48
	local MAKE_BD2 = T.StrokeLight

	-- Creator Store free Decals (rebirth / backpack)
	local ICON_REBIRTH = "rbxassetid://18367579979" -- Rebirth Icon
	local ICON_INVENTORY = "rbxassetid://12878997124" -- Inventory Backpack icon

	local BAL_H = 118
	local CHIP_H = 104
	local ICON_SZ = 80
	local GAP = 14
	local RB_H = 10
	local AUTO_H = 42
	local GAP_BAL_RB = 12
	local GAP_RB_AUTO = 10

	local bal = Instance.new("Frame")
	bal.Name = "BalanceBar"
	bal.BackgroundTransparency = 1
	bal.BorderSizePixel = 0
	bal.Size = UDim2.fromOffset(620, BAL_H)
	bal.Position = UDim2.new(0.5, 0, 1, -20)
	bal.AnchorPoint = Vector2.new(0.5, 1)
	bal.ZIndex = 12
	bal.Parent = root
	local balList = Instance.new("UIListLayout")
	balList.FillDirection = Enum.FillDirection.Horizontal
	balList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	balList.VerticalAlignment = Enum.VerticalAlignment.Center
	balList.Padding = UDim.new(0, GAP)
	balList.SortOrder = Enum.SortOrder.LayoutOrder
	balList.Parent = bal

	local function softNumLabel(parent: Instance, name: string, color: Color3, glow: Color3): TextLabel
		local lab = Instance.new("TextLabel")
		lab.Name = name
		lab.BackgroundTransparency = 1
		lab.BorderSizePixel = 0
		lab.Size = UDim2.new(1, -16, 0, 52)
		lab.Position = UDim2.new(0, 8, 0, 38)
		lab.Font = Enum.Font.GothamBold -- normal clean UI font (not pixel/Builder)
		lab.TextSize = 30
		lab.TextColor3 = color
		lab.TextXAlignment = Enum.TextXAlignment.Center
		lab.TextYAlignment = Enum.TextYAlignment.Center
		lab.Text = "0"
		lab.ZIndex = 16
		lab.Parent = parent
		lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		lab.TextStrokeTransparency = 0.5
		local st = Instance.new("UIStroke")
		st.Name = "SoftGlow"
		st.Color = glow
		st.Thickness = 1.4
		st.Transparency = 0.55
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		st.LineJoinMode = Enum.LineJoinMode.Round
		st.Parent = lab
		return lab
	end

	local function metricChip(name: string, order: number, accent: Color3, glow: Color3): (Frame, TextLabel)
		-- Solid Theme charcoal (Surface3) — NO UIGradient on same node as text
		local chip = Instance.new("Frame")
		chip.Name = name .. "Chip"
		chip.BackgroundColor3 = MAKE_SECTION -- Surface3 blue-gray charcoal
		chip.BackgroundTransparency = 0.05
		chip.BorderSizePixel = 0
		chip.Size = UDim2.fromOffset(180, CHIP_H)
		chip.LayoutOrder = order
		chip.ZIndex = 13
		chip.Parent = bal
		UIKit.Corner(chip, 12)
		UIKit.Stroke(chip, accent, 2, 0.28)

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, 0, 0, 22)
		title.Position = UDim2.fromOffset(0, 10)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextColor3 = accent
		title.Text = string.upper(name)
		title.TextXAlignment = Enum.TextXAlignment.Center
		title.ZIndex = 15
		title.Parent = chip

		local lab = softNumLabel(chip, name, accent, glow)
		lab.ZIndex = 16
		return chip, lab
	end

	local function iconChip(
		name: string,
		order: number,
		image: string,
		fallbackGlyph: string,
		hint: string,
		onClick: () -> ()
	): ImageButton
		local btn = Instance.new("ImageButton")
		btn.Name = name
		btn.Size = UDim2.fromOffset(ICON_SZ, CHIP_H)
		btn.BackgroundColor3 = MAKE_SECTION
		btn.BackgroundTransparency = 0.05
		btn.BorderSizePixel = 0
		btn.Image = ""
		btn.AutoButtonColor = true
		btn.LayoutOrder = order
		btn.ZIndex = 13
		btn.Parent = bal
		UIKit.Corner(btn, 12)
		UIKit.Stroke(btn, MAKE_BD2, 1.5, 0.25)
		-- subtle panel fill (same family as windows)
		UIKit.Gradient(btn, MAKE_SECTION, MAKE_PANEL, 100)

		-- Always-visible glyph fallback (Decals often fail to load in place)
		local glyph = Instance.new("TextLabel")
		glyph.Name = "Glyph"
		glyph.BackgroundTransparency = 1
		glyph.Size = UDim2.fromOffset(52, 52)
		glyph.Position = UDim2.new(0.5, 0, 0, 10)
		glyph.AnchorPoint = Vector2.new(0.5, 0)
		glyph.Font = Enum.Font.GothamBold
		glyph.TextSize = 34
		glyph.Text = fallbackGlyph
		glyph.TextColor3 = Color3.fromRGB(220, 220, 230)
		glyph.ZIndex = 14
		glyph.Parent = btn

		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(52, 52)
		img.Position = UDim2.new(0.5, 0, 0, 10)
		img.AnchorPoint = Vector2.new(0.5, 0)
		img.Image = image
		img.ScaleType = Enum.ScaleType.Fit
		img.ZIndex = 15
		img.Parent = btn

		local hintLab = Instance.new("TextLabel")
		hintLab.Name = "KeyHint"
		hintLab.BackgroundTransparency = 1
		hintLab.Size = UDim2.new(1, 0, 0, 18)
		hintLab.Position = UDim2.new(0, 0, 1, -22)
		hintLab.Font = Enum.Font.GothamBold
		hintLab.TextSize = 14
		hintLab.TextColor3 = Color3.fromRGB(180, 180, 190)
		hintLab.Text = hint
		hintLab.TextXAlignment = Enum.TextXAlignment.Center
		hintLab.ZIndex = 15
		hintLab.Parent = btn

		btn.MouseButton1Click:Connect(onClick)
		return btn
	end

	local qBtn = iconChip("RebirthQ", 1, ICON_REBIRTH, "♻", "Q", function()
		openModal("rebirth", nil)
	end)
	local coinChip, coinLab = metricChip("Coins", 2, MAKE_GOLD, MAKE_GOLD_GLOW)
	local powerChip, powerLab = metricChip("Power", 3, MAKE_POWER, MAKE_POWER_GLOW)
	local eBtn = iconChip("InvE", 4, ICON_INVENTORY, "🎒", "E", function()
		store:OpenPanel("weapons")
	end)
	local _ = qBtn
	local _ = eBtn
	local _ = coinChip
	local _ = powerChip

	local rbHost = Instance.new("Frame")
	rbHost.Name = "RebirthProg"
	rbHost.BackgroundTransparency = 1
	rbHost.Size = UDim2.fromOffset(440, RB_H)
	rbHost.Position = UDim2.new(0.5, 0, 1, -(20 + BAL_H + GAP_BAL_RB))
	rbHost.AnchorPoint = Vector2.new(0.5, 1)
	rbHost.ZIndex = 11
	rbHost.Parent = root
	local rbTrack, rbFill = UIKit.Bar(rbHost, 0, T.Accent, RB_H)

	local autoChip = UIKit.Button({
		Name = "AutoChip",
		Parent = root,
		Text = "AUTO",
		Size = UDim2.fromOffset(128, AUTO_H),
		Position = UDim2.new(0.5, 0, 1, -(20 + BAL_H + GAP_BAL_RB + RB_H + GAP_RB_AUTO)),
		Anchor = Vector2.new(0.5, 1),
		Color = T.AutoOff,
		Color2 = T.AutoOffDeep,
		SizePx = 18,
		Compact = true,
		Z = 12,
		OnClick = function()
			Net.ToggleAuto()
		end,
	})

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
		anomBanner.Position = UDim2.fromOffset(m.railW + m.pad * 2, m.pad + 168)

		local rowW = math.clamp(m.actionW * 1.1, 520, 780)
		local pad = m.pad
		bal.Size = UDim2.fromOffset(rowW, BAL_H)
		bal.Position = UDim2.new(0.5, 0, 1, -pad)

		-- scale chips with row width (keep metrics wide + readable)
		local chipW = math.floor((rowW - GAP * 3 - ICON_SZ * 2) / 2)
		chipW = math.clamp(chipW, 160, 240)
		coinChip.Size = UDim2.fromOffset(chipW, CHIP_H)
		powerChip.Size = UDim2.fromOffset(chipW, CHIP_H)
		coinLab.Font = Enum.Font.GothamBold
		powerLab.Font = Enum.Font.GothamBold
		coinLab.TextSize = 30
		powerLab.TextSize = 30

		rbHost.Size = UDim2.fromOffset(math.min(rowW, 520), RB_H)
		rbHost.Position = UDim2.new(0.5, 0, 1, -(pad + BAL_H + GAP_BAL_RB))

		autoChip.Size = UDim2.fromOffset(math.clamp(math.floor(rowW * 0.28), 120, 168), AUTO_H)
		autoChip.Position = UDim2.new(0.5, 0, 1, -(pad + BAL_H + GAP_BAL_RB + RB_H + GAP_RB_AUTO))
		autoChip.TextSize = 18
		local autoLab = autoChip:FindFirstChild("Label")
		if autoLab and autoLab:IsA("TextLabel") then
			autoLab.TextSize = 18
		end
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

		-- Force Make palette colors every refresh (never black)
		coinLab.Text = Format.Num(st.coins)
		coinLab.TextColor3 = MAKE_GOLD
		powerLab.Text = Format.Num(st.damagePerClick or st.totalPower)
		powerLab.TextColor3 = MAKE_POWER

		-- rebirth progress (damage toward next R)
		local pct = st.rebirthProgress
		if type(pct) ~= "number" then
			local cost = st.nextRebirthCost or 1
			local dmg = st.lifetimeDamage or 0
			pct = cost > 0 and math.clamp(dmg / cost, 0, 1) or 1
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

		-- boosts: profile.boosts (local potions later) + global anomaly hud
		local boostsData = (profile and profile.boosts) or {}
		local anom = Formulas.GetActiveAnomaly()
		local anomHud = (anom and anom.hud) or {}
		for _, meta in ipairs(BOOST_META) do
			local row = boostRows[meta.key]
			local b = boostsData[meta.key]
			local localPct = if type(b) == "table" and type(b.pct) == "number" then b.pct else 0
			local globalPct = anomHud[meta.key] or 0
			local totalPct = localPct + globalPct
			if totalPct ~= 0 then
				row.Visible = true
				local pctLab = row:FindFirstChild("Pct")
				local scopeLab = row:FindFirstChild("Scope")
				if pctLab and pctLab:IsA("TextLabel") then
					local sign = if totalPct >= 0 then "+" else ""
					pctLab.Text = string.format("%s%d%%", sign, math.floor(totalPct * 100 + (if totalPct >= 0 then 0.5 else -0.5)))
				end
				if scopeLab and scopeLab:IsA("TextLabel") then
					if globalPct ~= 0 and localPct ~= 0 then
						scopeLab.Text = "Both"
					elseif globalPct ~= 0 then
						scopeLab.Text = "Global"
					else
						local sc = tostring((type(b) == "table" and b.scope) or "local")
						scopeLab.Text = (sc == "global" or sc == "Global") and "Global" or "Local"
					end
				end
			else
				row.Visible = false
			end
		end

		if anom then
			local left = math.max(0, anom.endsAt - os.time())
			local m = math.floor(left / 60)
			local s = left % 60
			anomBanner.Visible = true
			anomBanner.Text = string.format("⚡ %s  %d:%02d", anom.name, m, s)
		else
			anomBanner.Visible = false
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
