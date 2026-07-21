--!strict
--[[
	All game windows share Theme design system:
	header (icon + title + close) | body sections | cards with semantic CTAs
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)
local Rarity = require(script.Parent.Rarity)
local Layout = require(script.Parent.Layout)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UpgradeConfig = require(Shared.Config.UpgradeConfig)
local UpgradeIconConfig = require(Shared.Config.UpgradeIconConfig)
local WorldConfig = require(Shared.Config.WorldConfig)
local QuestConfig = require(Shared.Config.QuestConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local IconConfig = require(Shared.Config.IconConfig)
local GamePassConfig = require(Shared.Config.GamePassConfig)
local Inventory = require(script.Parent.Inventory)

local Windows = {}

-- Interior upscale for left-rail panels only (HUD bottom untouched)
local S = 1.42
local function px(n: number): number
	return math.floor(n * S + 0.5)
end

local function surfaceCard(parent: Instance, h: number, order: number, edge: Color3?): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	f.Size = UDim2.new(1, -6, 0, px(h))
	f.LayoutOrder = order
	f.ZIndex = 32
	f.ClipsDescendants = true
	f.Parent = parent
	UIKit.Corner(f, T.R.sm)
	UIKit.Stroke(f, edge or T.Stroke, edge and 1.5 or 1.1, edge and 0.25 or 0.2)
	UIKit.Gradient(f, T.Surface3, T.Surface2, 105)
	UIKit.Pad(f, px(12))
	return f
end

local function sectionLabel(parent: Instance, text: string, order: number)
	return UIKit.Label({
		Parent = parent,
		Text = text,
		Size = UDim2.new(1, 0, 0, px(28)),
		SizePx = px(16),
		Font = T.Font.Title,
		Color = T.TextMuted,
		Order = order,
		Z = 33,
	})
end


function Windows.Mount(gui: ScreenGui, store: any, openModal: (string, any?) -> ())
	local folder = Instance.new("Folder")
	folder.Name = "Windows"
	folder.Parent = gui

	local frames: { [string]: Frame } = {}
	local bodies: { [string]: Frame } = {}

	local titles = {
		character = "Character Upgrade", -- Figma track / debug (rail UP · key U)
		weapons = "Inventory", -- INVETAR shell (E key)
		pets = "Pets",
		auras = "Auras",
		cases = "Cases",
		relics = "Relics",
		quests = "Quests",
		locations = "Teleport",
		dungeons = "Dungeons",
		shop = "Donate Shop",
	}

	for id, title in titles do
		local icon = (T.WindowIcon and T.WindowIcon[id]) or "◆"
		local root, body = UIKit.Window(folder, title, function()
			store:ClosePanel()
		end, icon)
		root.Name = id
		frames[id] = root
		bodies[id] = body
	end

	-- Inventory uses fixed design scale (Make ~920 panel); hide outer Window chrome
	-- so INVETAR shell provides its own header/close (no double title bar).
	do
		local invRoot = frames.weapons
		local invHeader = invRoot:FindFirstChild("Header")
		if invHeader and invHeader:IsA("GuiObject") then
			invHeader.Visible = false
		end
		local invBody = bodies.weapons
		invBody.Size = UDim2.new(1, 0, 1, 0)
		invBody.Position = UDim2.fromOffset(0, 0)
		invRoot.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
		-- drop outer gradient/stroke feel for Make flat panel
		local stroke = invRoot:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Color3.fromRGB(62, 62, 62)
			stroke.Thickness = 2
			stroke.Transparency = 0.1
		end
		local sc = invRoot:FindFirstChildOfClass("UISizeConstraint")
		if sc then
			sc.MinSize = Vector2.new(780, 520)
			sc.MaxSize = Vector2.new(1600, 1000)
		end
	end

	Layout.Bind(function(m)
		local ww = math.clamp((m.windowW or 0.5) + 0.10, 0.56, 0.68)
		local wh = math.clamp((m.windowH or 0.62) + 0.10, 0.66, 0.80)
		for id, root in frames do
			if id == "weapons" then
				-- Large but not broken: ~88% width / 88% height, same on all res
				root.Size = UDim2.fromScale(0.88, 0.88)
				root.Position = UDim2.fromScale(0.5, 0.5)
				root.AnchorPoint = Vector2.new(0.5, 0.5)
			elseif id == "character" then
				-- Larger panel; raised on screen so levels/stats clear of bottom HUD
				local cam = workspace.CurrentCamera
				local vw = if cam then cam.ViewportSize.X else 1280
				local w = math.clamp(math.floor(vw * 0.90), 900, 1220)
				-- header + cards + bar ≈ 460 base (refreshCharacter may hug)
				local h = 460
				root.Size = UDim2.fromOffset(w, h)
				-- Y 0.42 = slightly above center (was 0.5 — hard to read levels near HUD)
				root.Position = UDim2.fromScale(0.5, 0.42)
				root.AnchorPoint = Vector2.new(0.5, 0.5)
				local sc = root:FindFirstChildOfClass("UISizeConstraint")
				if sc then
					sc.MinSize = Vector2.new(860, 400)
					sc.MaxSize = Vector2.new(1280, 560)
				end
			else
				root.Size = UDim2.fromScale(ww, wh)
			end
		end
	end)

	-- Unified inventory (Figma Make INVETAR) on weapons body
	local invApi = Inventory.Bind(bodies.weapons, frames.weapons, store, openModal, function()
		store:ClosePanel()
	end)

	-- Panel open/close: slight bounce (scale pop)
	local panelAnimGen = 0
	local function ensurePanelScale(f: Frame): UIScale
		local sc = f:FindFirstChildOfClass("UIScale")
		if not sc then
			sc = Instance.new("UIScale")
			sc.Scale = 1
			sc.Parent = f
		end
		return sc
	end

	local function showOnly(active: string)
		panelAnimGen += 1
		local gen = panelAnimGen
		for id, f in frames do
			local sc = ensurePanelScale(f)
			if id == active then
				if f.Visible then
					-- already open — do NOT re-bounce (was flashing inventory on every ProfileUpdate)
					sc.Scale = 1
					f.Visible = true
				else
					sc.Scale = 0.86
					f.Visible = true
					TweenService:Create(
						sc,
						TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Scale = 1 }
					):Play()
				end
			elseif f.Visible then
				local tw = TweenService:Create(
					sc,
					TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Scale = 0.9 }
				)
				tw:Play()
				tw.Completed:Connect(function()
					if panelAnimGen ~= gen then
						return
					end
					if id ~= active then
						f.Visible = false
						sc.Scale = 1
					end
				end)
			else
				f.Visible = false
				sc.Scale = 1
			end
		end
	end

	---------------------------------------------------------------- Character Upgrade — Figma MainCharacterUpgrader (1:122)
	-- Cards: Strength / Backpack / Speed / Crit / Multi-Crit · footer Upgrade for selection
	local selectedUpgradeId = "ClickSpeed" -- Figma default selected = Speed

	-- Figma display names + border + mid gradient accents
	local UPGRADE_UI = {
		Power = {
			title = "Strength",
			statLabel = "Power",
			edge = Color3.fromRGB(232, 20, 20),
			grad0 = Color3.fromRGB(110, 21, 21),
			grad1 = Color3.fromRGB(254, 16, 16),
			glyph = "⚔",
		},
		Backpack = {
			title = "Backpack",
			statLabel = "Slots",
			edge = Color3.fromRGB(1, 162, 30),
			grad0 = Color3.fromRGB(20, 82, 20),
			grad1 = Color3.fromRGB(45, 184, 45),
			glyph = "🎒",
		},
		ClickSpeed = {
			title = "Speed",
			statLabel = "Speed",
			edge = Color3.fromRGB(232, 184, 0),
			grad0 = Color3.fromRGB(90, 70, 10),
			grad1 = Color3.fromRGB(200, 160, 20),
			glyph = "👟",
		},
		CritChance = {
			title = "Crit",
			statLabel = "Chance",
			edge = Color3.fromRGB(51, 51, 51),
			grad0 = Color3.fromRGB(40, 40, 48),
			grad1 = Color3.fromRGB(80, 80, 90),
			glyph = "◎",
		},
		MultiCrit = {
			title = "Multi-Crit",
			statLabel = "Chance",
			edge = Color3.fromRGB(51, 51, 51),
			grad0 = Color3.fromRGB(40, 40, 48),
			grad1 = Color3.fromRGB(80, 80, 90),
			glyph = "✦",
		},
	}
	local UPGRADE_ORDER = { "Power", "Backpack", "ClickSpeed", "CritChance", "MultiCrit" }

	local function refreshCharacter()
		local body = bodies.character
		UIKit.Clear(body)
		local stats = store:PeekStats()
		local profile = store:PeekProfile()
		if not stats or not profile then
			return
		end

		-- Hide default window chrome; Figma-style custom header fills full root
		local root = frames.character
		local hdr = root:FindFirstChild("Header")
		if hdr and hdr:IsA("GuiObject") then
			hdr.Visible = false
		end
		body.Size = UDim2.new(1, 0, 1, 0)
		body.Position = UDim2.fromOffset(0, 0)
		body.ClipsDescendants = false
		root.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
		root.ClipsDescendants = true
		UIKit.Stroke(root, Color3.fromRGB(51, 51, 51), 2, 0)

		local coins = stats.coins or 0
		local coinImgId = UpgradeIconConfig.Get("Coin") -- header + price, same asset

		-- Design-space size (NOT AbsoluteSize — ScreenGui UIScale would inflate cards)
		local panelW = root.Size.X.Offset
		local panelH = root.Size.Y.Offset
		if panelW < 100 then
			local cam = workspace.CurrentCamera
			local vw = if cam then cam.ViewportSize.X else 1280
			panelW = math.clamp(math.floor(vw * 0.90), 900, 1220)
		end
		if panelH < 100 then
			panelH = 460
		end

		local PAD = 16
		local N = #UPGRADE_ORDER
		local headerH = 54
		local barH = 72
		local midGap = 14
		-- Cards fill width exactly; height fills remaining vertical space (no dead middle)
		local cardGap = 10
		local cardsTop = headerH + midGap
		local cardsBottomPad = midGap + barH + PAD
		local cardH = math.max(200, panelH - cardsTop - cardsBottomPad)
		local cardsInnerW = panelW - PAD * 2
		local cardW = math.floor((cardsInnerW - cardGap * (N - 1)) / N)
		if cardW < 130 then
			cardW = 130
		end
		-- slightly taller cards for readable Level / stat rows
		cardH = math.min(cardH, math.floor(cardW * 1.28))
		local iconSz = math.clamp(math.floor(cardW * 0.44), 56, 90)
		local titleH = 38
		local footH = 54
		local midH = math.max(70, cardH - titleH - footH)
		local textSm = 13
		local textMd = 15
		local textLg = 18

		-- ===== Header =====
		local header = Instance.new("Frame")
		header.Name = "CU_Header"
		header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		header.BorderSizePixel = 0
		header.Size = UDim2.new(1, 0, 0, headerH)
		header.ZIndex = 32
		header.Parent = body
		local hStroke = Instance.new("UIStroke")
		hStroke.Color = Color3.fromRGB(51, 51, 51)
		hStroke.Thickness = 1
		hStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hStroke.Parent = header

		UIKit.Label({
			Parent = header,
			Text = "Character Upgrade",
			Size = UDim2.new(0.55, 0, 1, 0),
			Position = UDim2.fromOffset(PAD, 0),
			SizePx = textLg,
			Font = T.Font.Title,
			Color = Color3.fromRGB(204, 204, 204),
			Z = 34,
		})

		local closeSz = 32
		local coinPillW = 132
		local coinPill = Instance.new("Frame")
		coinPill.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		coinPill.BorderSizePixel = 0
		coinPill.Size = UDim2.fromOffset(coinPillW, 34)
		coinPill.Position = UDim2.new(1, -(PAD + closeSz + 12 + coinPillW), 0.5, 0)
		coinPill.AnchorPoint = Vector2.new(0, 0.5)
		coinPill.ZIndex = 33
		coinPill.Parent = header
		UIKit.Corner(coinPill, 4)
		UIKit.Stroke(coinPill, Color3.fromRGB(51, 51, 51), 1, 0)
		if coinImgId ~= "" then
			local cimg = Instance.new("ImageLabel")
			cimg.BackgroundTransparency = 1
			cimg.Image = coinImgId
			cimg.ScaleType = Enum.ScaleType.Fit
			cimg.Size = UDim2.fromOffset(20, 20)
			cimg.Position = UDim2.fromOffset(8, 7)
			cimg.ZIndex = 34
			cimg.Parent = coinPill
			UIKit.Label({
				Parent = coinPill,
				Text = Format.Num(coins),
				Size = UDim2.new(1, -32, 1, 0),
				Position = UDim2.fromOffset(30, 0),
				SizePx = textMd,
				Font = T.Font.Title,
				Color = Color3.fromRGB(255, 178, 0),
				Z = 34,
			})
		else
			UIKit.Label({
				Parent = coinPill,
				Text = "C  " .. Format.Num(coins),
				Size = UDim2.fromScale(1, 1),
				SizePx = textMd,
				Font = T.Font.Title,
				Color = Color3.fromRGB(255, 178, 0),
				X = Enum.TextXAlignment.Center,
				Z = 34,
			})
		end

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "Close"
		closeBtn.Text = ""
		closeBtn.AutoButtonColor = true
		closeBtn.Size = UDim2.fromOffset(closeSz, closeSz)
		closeBtn.Position = UDim2.new(1, -PAD, 0.5, 0)
		closeBtn.AnchorPoint = Vector2.new(1, 0.5)
		closeBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
		closeBtn.BorderSizePixel = 0
		closeBtn.ZIndex = 35
		closeBtn.Parent = header
		UIKit.Corner(closeBtn, 4)
		UIKit.Stroke(closeBtn, Color3.fromRGB(170, 34, 34), 1, 0)
		local closeImgId = UpgradeIconConfig.Get("Close")
		if closeImgId ~= "" then
			local ximg = Instance.new("ImageLabel")
			ximg.BackgroundTransparency = 1
			ximg.Image = closeImgId
			ximg.ScaleType = Enum.ScaleType.Fit
			ximg.Size = UDim2.fromOffset(16, 16)
			ximg.Position = UDim2.fromScale(0.5, 0.5)
			ximg.AnchorPoint = Vector2.new(0.5, 0.5)
			ximg.ZIndex = 36
			ximg.Parent = closeBtn
		else
			closeBtn.Text = "X"
			closeBtn.Font = Enum.Font.GothamBold
			closeBtn.TextSize = 16
			closeBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
		end
		closeBtn.MouseButton1Click:Connect(function()
			store:ClosePanel()
		end)

		-- ===== Cards row (5 equal columns, no overflow) =====
		local cardsRow = Instance.new("Frame")
		cardsRow.Name = "Cards"
		cardsRow.BackgroundTransparency = 1
		cardsRow.Size = UDim2.new(1, -PAD * 2, 0, cardH)
		cardsRow.Position = UDim2.fromOffset(PAD, cardsTop)
		cardsRow.ZIndex = 32
		cardsRow.ClipsDescendants = false
		cardsRow.Parent = body
		local cardList = UIKit.List(cardsRow, cardGap, true)
		cardList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		cardList.VerticalAlignment = Enum.VerticalAlignment.Top

		local function statValueText(upId: string, def: any, lvl: number): string
			if not def then
				return "0"
			end
			if upId == "Backpack" then
				return tostring(UpgradeConfig.GetBagCap(profile))
			end
			if def.effectType == "mult_add" or def.statKey == "critChance" or def.statKey == "multiCritChance" then
				local pct = math.floor((def.effectPerLevel or 0) * 100 * lvl + 0.5)
				return pct .. "%"
			end
			return Format.Num((def.effectPerLevel or 0) * lvl)
		end

		for i, upId in ipairs(UPGRADE_ORDER) do
			local def = UpgradeConfig.Defs[upId]
			local ui = UPGRADE_UI[upId]
			if def and ui then
				local lvl = (profile.upgradeLevels and profile.upgradeLevels[upId]) or 0
				local unlocked = select(1, UpgradeConfig.IsUnlocked(profile, upId))
				local selected = selectedUpgradeId == upId
				local edge = if selected then ui.edge else Color3.fromRGB(51, 51, 51)
				if selected and upId == "ClickSpeed" then
					edge = Color3.fromRGB(232, 184, 0)
				end

				local card = Instance.new("TextButton")
				card.Name = upId
				card.Text = ""
				card.AutoButtonColor = false
				card.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
				card.BorderSizePixel = 0
				card.Size = UDim2.fromOffset(cardW, cardH)
				card.LayoutOrder = i
				card.ZIndex = 33
				card.ClipsDescendants = true
				card.Parent = cardsRow
				UIKit.Corner(card, 5)
				UIKit.Stroke(card, edge, selected and 2.5 or 1.5, 0)

				local titleBar = Instance.new("Frame")
				titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
				titleBar.BorderSizePixel = 0
				titleBar.Size = UDim2.new(1, 0, 0, titleH)
				titleBar.ZIndex = 34
				titleBar.Parent = card
				UIKit.Label({
					Parent = titleBar,
					Text = ui.title,
					Size = UDim2.new(1, -8, 1, 0),
					Position = UDim2.fromOffset(4, 0),
					SizePx = textSm + 1,
					Font = T.Font.Title,
					Color = Color3.fromRGB(204, 204, 204),
					X = Enum.TextXAlignment.Center,
					Z = 35,
				})

				local mid = Instance.new("Frame")
				mid.BackgroundColor3 = Color3.new(1, 1, 1)
				mid.BorderSizePixel = 0
				mid.Size = UDim2.new(1, 0, 0, midH)
				mid.Position = UDim2.fromOffset(0, titleH)
				mid.ZIndex = 34
				mid.ClipsDescendants = true
				mid.Parent = card
				UIKit.Gradient(mid, ui.grad0, ui.grad1, 160)
				local iconAsset = UpgradeIconConfig.Get(upId)
				if iconAsset ~= "" then
					local img = Instance.new("ImageLabel")
					img.BackgroundTransparency = 1
					img.Image = iconAsset
					img.ScaleType = Enum.ScaleType.Fit
					img.Size = UDim2.fromOffset(iconSz, iconSz)
					img.Position = UDim2.fromScale(0.5, 0.5)
					img.AnchorPoint = Vector2.new(0.5, 0.5)
					img.ZIndex = 35
					img.Parent = mid
				else
					UIKit.Label({
						Parent = mid,
						Text = ui.glyph,
						Size = UDim2.fromScale(1, 1),
						SizePx = math.floor(iconSz * 0.55),
						X = Enum.TextXAlignment.Center,
						Z = 35,
					})
				end
				if not unlocked then
					local lock = UIKit.Label({
						Parent = mid,
						Text = "LOCKED",
						Size = UDim2.new(1, 0, 0, 14),
						Position = UDim2.new(0, 0, 1, -16),
						SizePx = 10,
						Color = Color3.fromRGB(255, 120, 120),
						X = Enum.TextXAlignment.Center,
						Z = 36,
					})
					lock.BackgroundTransparency = 1
				end

				local foot = Instance.new("Frame")
				foot.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
				foot.BorderSizePixel = 0
				foot.Size = UDim2.new(1, 0, 0, footH)
				foot.Position = UDim2.new(0, 0, 1, -footH)
				foot.ZIndex = 34
				foot.Parent = card
				local footPad = 10
				-- Values slightly larger than labels so Level / stats are easy to read
				UIKit.Label({
					Parent = foot,
					Text = "Level",
					Size = UDim2.new(0.55, -footPad, 0, 18),
					Position = UDim2.fromOffset(footPad, 6),
					SizePx = textSm,
					Color = Color3.fromRGB(119, 119, 119),
					Z = 35,
				})
				UIKit.Label({
					Parent = foot,
					Text = tostring(lvl),
					Size = UDim2.new(0.45, -footPad, 0, 18),
					Position = UDim2.new(0.55, 0, 0, 6),
					SizePx = textMd,
					Font = T.Font.Title,
					Color = Color3.fromRGB(230, 230, 230),
					X = Enum.TextXAlignment.Right,
					Z = 35,
				})
				UIKit.Label({
					Parent = foot,
					Text = ui.statLabel,
					Size = UDim2.new(0.55, -footPad, 0, 18),
					Position = UDim2.fromOffset(footPad, 28),
					SizePx = textSm,
					Color = Color3.fromRGB(119, 119, 119),
					Z = 35,
				})
				UIKit.Label({
					Parent = foot,
					Text = statValueText(upId, def, lvl),
					Size = UDim2.new(0.45, -footPad, 0, 18),
					Position = UDim2.new(0.55, 0, 0, 28),
					SizePx = textMd,
					Font = T.Font.Title,
					Color = Color3.fromRGB(230, 230, 230),
					X = Enum.TextXAlignment.Right,
					Z = 35,
				})

				card.MouseButton1Click:Connect(function()
					selectedUpgradeId = upId
					refreshCharacter()
				end)
			end
		end

		-- ===== Bottom bar: sits right under cards (tight, no floating void) =====
		local barY = cardsTop + cardH + midGap
		-- if panel taller than content, still keep bar near cards (not stuck only to bottom with gap)
		local barYMax = panelH - PAD - barH
		if barY > barYMax then
			barY = barYMax
		end

		local bar = Instance.new("Frame")
		bar.Name = "UpgradeBar"
		bar.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.new(1, -PAD * 2, 0, barH)
		bar.Position = UDim2.fromOffset(PAD, barY)
		bar.ZIndex = 32
		bar.Parent = body
		UIKit.Corner(bar, 5)
		UIKit.Stroke(bar, Color3.fromRGB(51, 51, 51), 1, 0)

		local selId = selectedUpgradeId
		local selDef = UpgradeConfig.Defs[selId]
		local selUi = UPGRADE_UI[selId]
		local selLvl = (profile.upgradeLevels and profile.upgradeLevels[selId]) or 0
		local nextLvl = selLvl + 1
		local cost = if selDef then UpgradeConfig.GetCost(selId, nextLvl) else 0
		local unlocked = false
		local lockReason: string? = "—"
		if selDef then
			unlocked, lockReason = UpgradeConfig.IsUnlocked(profile, selId)
		end
		local maxed = selDef ~= nil and selLvl >= (selDef.maxLevel or 0)
		local canBuy = unlocked and not maxed and coins >= cost

		local nextStat = "—"
		if selDef and selUi then
			if selId == "Backpack" then
				nextStat = tostring((UpgradeConfig.GetBagCap(profile) or 32) + 1)
			elseif selDef.effectType == "mult_add" or selDef.statKey == "critChance" or selDef.statKey == "multiCritChance" then
				local per = math.floor((selDef.effectPerLevel or 0) * 100 + 0.5)
				nextStat = per .. "%"
			else
				nextStat = Format.Num(selDef.effectPerLevel or 0)
			end
		end

		-- Compact left stack: label/value pairs in a tight block
		local leftW = math.floor(panelW * 0.38)
		local leftBlock = Instance.new("Frame")
		leftBlock.Name = "NextInfo"
		leftBlock.BackgroundTransparency = 1
		leftBlock.Size = UDim2.fromOffset(math.max(220, leftW), barH)
		leftBlock.Position = UDim2.fromOffset(16, 0)
		leftBlock.ZIndex = 33
		leftBlock.Parent = bar

		local row1Y, row2Y = 12, 38
		UIKit.Label({
			Parent = leftBlock,
			Text = "Next Level",
			Size = UDim2.new(0.62, 0, 0, 20),
			Position = UDim2.fromOffset(0, row1Y),
			SizePx = textSm,
			Color = Color3.fromRGB(119, 119, 119),
			Z = 34,
		})
		UIKit.Label({
			Parent = leftBlock,
			Text = maxed and "MAX" or tostring(nextLvl),
			Size = UDim2.new(0.35, 0, 0, 20),
			Position = UDim2.new(0.62, 0, 0, row1Y),
			SizePx = textMd + 1,
			Font = T.Font.Title,
			Color = Color3.fromRGB(230, 230, 230),
			X = Enum.TextXAlignment.Right,
			Z = 34,
		})
		UIKit.Label({
			Parent = leftBlock,
			Text = selUi and selUi.statLabel or "Stat",
			Size = UDim2.new(0.62, 0, 0, 20),
			Position = UDim2.fromOffset(0, row2Y),
			SizePx = textSm,
			Color = Color3.fromRGB(119, 119, 119),
			Z = 34,
		})
		UIKit.Label({
			Parent = leftBlock,
			Text = if not unlocked then (lockReason or "Locked") else nextStat,
			Size = UDim2.new(0.35, 0, 0, 20),
			Position = UDim2.new(0.62, 0, 0, row2Y),
			SizePx = textMd + 1,
			Font = T.Font.Title,
			Color = Color3.fromRGB(230, 230, 230),
			X = Enum.TextXAlignment.Right,
			Z = 34,
		})

		-- Price + Upgrade on the right, aligned as a pair
		local upBtnW, upBtnH = 120, 40
		local priceW = 130
		local rightPad = 14
		local upBtn = Instance.new("TextButton")
		upBtn.Name = "UpgradeBtn"
		upBtn.Text = if not unlocked then "Locked" elseif maxed then "MAX" else "Upgrade"
		upBtn.Font = Enum.Font.GothamBold
		upBtn.TextSize = textMd
		upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		upBtn.AutoButtonColor = canBuy
		upBtn.Size = UDim2.fromOffset(upBtnW, upBtnH)
		upBtn.Position = UDim2.new(1, -rightPad, 0.5, 0)
		upBtn.AnchorPoint = Vector2.new(1, 0.5)
		upBtn.BackgroundColor3 = if canBuy then Color3.fromRGB(48, 48, 56) else Color3.fromRGB(40, 40, 40)
		upBtn.BorderSizePixel = 0
		upBtn.ZIndex = 35
		upBtn.Parent = bar
		UIKit.Corner(upBtn, 5)
		UIKit.Stroke(upBtn, if canBuy then Color3.fromRGB(90, 90, 100) else Color3.fromRGB(50, 50, 50), 1, 0)

		local priceCol = Instance.new("Frame")
		priceCol.Name = "Price"
		priceCol.BackgroundTransparency = 1
		priceCol.Size = UDim2.fromOffset(priceW, barH)
		priceCol.Position = UDim2.new(1, -(rightPad + upBtnW + 14 + priceW), 0, 0)
		priceCol.ZIndex = 34
		priceCol.Parent = bar

		UIKit.Label({
			Parent = priceCol,
			Text = "Price",
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.fromOffset(0, 10),
			SizePx = textSm,
			Color = Color3.fromRGB(119, 119, 119),
			Z = 35,
		})

		local priceRow = Instance.new("Frame")
		priceRow.BackgroundTransparency = 1
		priceRow.Size = UDim2.new(1, 0, 0, 26)
		priceRow.Position = UDim2.fromOffset(0, 32)
		priceRow.ZIndex = 35
		priceRow.Parent = priceCol

		local priceText = if maxed then "—" else Format.Num(cost)
		if coinImgId ~= "" then
			local pimg = Instance.new("ImageLabel")
			pimg.Name = "CoinIcon"
			pimg.BackgroundTransparency = 1
			pimg.Image = coinImgId
			pimg.ScaleType = Enum.ScaleType.Fit
			pimg.Size = UDim2.fromOffset(20, 20)
			pimg.Position = UDim2.fromOffset(0, 3)
			pimg.ZIndex = 36
			pimg.Parent = priceRow
			UIKit.Label({
				Parent = priceRow,
				Text = priceText,
				Size = UDim2.new(1, -26, 1, 0),
				Position = UDim2.fromOffset(26, 0),
				SizePx = textMd + 1,
				Font = T.Font.Title,
				Color = Color3.fromRGB(255, 178, 0),
				Z = 36,
			})
		else
			UIKit.Label({
				Parent = priceRow,
				Text = "C " .. priceText,
				Size = UDim2.fromScale(1, 1),
				SizePx = textMd + 1,
				Font = T.Font.Title,
				Color = Color3.fromRGB(255, 178, 0),
				Z = 36,
			})
		end

		if canBuy then
			upBtn.MouseButton1Click:Connect(function()
				Net.BuyUpgrade(selId)
			end)
		end

		-- Resize window height to hug content (removes empty void under footer)
		local contentH = barY + barH + PAD
		local cam = workspace.CurrentCamera
		local vh = if cam then cam.ViewportSize.Y else 720
		local targetH = math.clamp(contentH, 400, math.min(560, math.floor(vh * 0.72)))
		if math.abs(root.Size.Y.Offset - targetH) > 2 then
			root.Size = UDim2.fromOffset(root.Size.X.Offset > 0 and root.Size.X.Offset or panelW, targetH)
		end
		-- Keep raised position after size hug (Layout.Bind sets this too)
		root.Position = UDim2.fromScale(0.5, 0.42)
		root.AnchorPoint = Vector2.new(0.5, 0.5)
	end

	---------------------------------------------------------------- Inventory (INVETAR Make) — E key
	-- Merge = MMB on sword slot only (Inventory.lua). No extra buttons / inventory UI redesign.
	local function refreshWeapons()
		local invStore = store :: any
		local t = invStore._invTab
		if type(t) == "string" and t ~= "" then
			invApi:SetTab(t)
			invStore._invTab = nil
		end
		invApi:Refresh()
	end

	---------------------------------------------------------------- Pets
	local function refreshPets()
		local body = bodies.pets
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local btnW = px(110)
		local head = surfaceCard(body, 56, 1, T.Gold)
		local pStats = store:PeekStats()
		local slots = profile.petSlots or 3
		local hint = (pStats and pStats.nextPetSlotHint) or ""
		UIKit.Label({
			Parent = head,
			Text = string.format("Team %d / %d", #(profile.petTeam or {}), slots),
			Size = UDim2.new(1, -btnW - 12, 0, px(22)),
			SizePx = px(16),
			Color = T.Text,
			Z = 33,
		})
		if hint ~= "" then
			UIKit.Label({
				Parent = head,
				Text = hint,
				Size = UDim2.new(1, -btnW - 12, 0, px(18)),
				Position = UDim2.fromOffset(0, px(24)),
				SizePx = px(11),
				Color = T.TextMuted,
				Z = 33,
			})
		end
		UIKit.Button({
			Parent = head,
			Text = "Case",
			Size = UDim2.fromOffset(btnW, px(40)),
			Position = UDim2.new(1, -btnW, 0.5, -px(20)),
			Color = T.GoldDeep,
			Color2 = Color3.fromRGB(180, 110, 25),
			Primary = true,
			SizePx = px(15),
			Z = 34,
			OnClick = function()
				openModal("case", { kind = "pet" })
			end,
		})
		-- paid +1 slot (7th)
		local paidOwned = (pStats and pStats.paidPetSlot) == true
			or (profile.unlocks and profile.unlocks.paidPetSlot) == true
		if not paidOwned and slots < 8 then
			local payRow = surfaceCard(body, 44, 2, T.Stroke)
			UIKit.Label({
				Parent = payRow,
				Text = "Paid: +1 pet slot (max 8)",
				Size = UDim2.new(0.6, 0, 1, 0),
				SizePx = px(13),
				Color = T.TextSoft,
				Z = 33,
			})
			UIKit.Button({
				Parent = payRow,
				Text = "Unlock (debug)",
				Size = UDim2.fromOffset(px(130), px(32)),
				Position = UDim2.new(1, -px(130), 0.5, -px(16)),
				SizePx = px(12),
				Primary = true,
				Z = 34,
				OnClick = function()
					Net.UnlockPaidFeature("paidPetSlot")
				end,
			})
		end
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(120)))
		scroll.LayoutOrder = 2
		for i, p in ipairs(profile.pets or {}) do
			local def = PetConfig.Get(p.id)
			local inTeam = false
			for _, uid in ipairs(profile.petTeam or {}) do
				if uid == p.uid then
					inTeam = true
					break
				end
			end
			local sideW = px(150)
			local rarity = (def and def.rarity) or p.rarity or "Common"
			local c = surfaceCard(scroll, 88, i, Rarity.Of(rarity))
			local dispName = (def and def.name) or p.name or p.id
			UIKit.Label({
				Parent = c,
				Text = string.format(
					"%s · %s · lv%s%s",
					tostring(dispName),
					tostring(rarity),
					tostring(p.level or 1),
					inTeam and " · TEAM" or ""
				),
				Size = UDim2.new(1, -sideW - 8, 0, px(22)),
				SizePx = px(15),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			local pMult = if def then PetConfig.GetPowerMult(def) else 1
			local coinPct = (def and def.coinPct) or 0
			UIKit.Label({
				Parent = c,
				Text = string.format("Power x%.2f   +%d%% coins", pMult, math.floor(coinPct)),
				Size = UDim2.new(1, -sideW - 8, 0, px(18)),
				Position = UDim2.fromOffset(0, px(32)),
				SizePx = px(13),
				Color = T.TextMuted,
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.fromOffset(sideW, px(38))
			row.Position = UDim2.new(1, -sideW, 0.5, -px(19))
			row.ZIndex = 34
			row.Parent = c
			UIKit.List(row, px(8), true)
			UIKit.Button({
				Parent = row,
				Text = inTeam and "Unequip" or "Equip",
				Size = UDim2.fromOffset(px(72), px(36)),
				SizePx = px(13),
				Color = inTeam and T.Disabled or T.Success,
				Color2 = inTeam and (T.Colors and T.Colors.DisabledDeep) or (T.Colors and T.Colors.SuccessDeep),
				OnClick = function()
					if inTeam then
						Net.UnequipPet(p.uid)
					else
						Net.EquipPet(p.uid)
					end
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Feed",
				Size = UDim2.fromOffset(px(64), px(36)),
				SizePx = px(13),
				OnClick = function()
					Net.FeedPet(p.uid)
				end,
			})
		end
		if #(profile.pets or {}) == 0 then
			UIKit.Label({
				Parent = scroll,
				Text = "Empty — open a case.",
				Size = UDim2.new(1, 0, 0, px(48)),
				Color = T.TextMuted,
				SizePx = px(15),
			})
		end
	end

	---------------------------------------------------------------- Auras
	local function refreshAuras()
		local body = bodies.auras
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local btnW = px(110)
		local head = surfaceCard(body, 56, 1, T.Gold)
		UIKit.Label({
			Parent = head,
			Text = "Active: " .. tostring(profile.equippedAura or "none"),
			Size = UDim2.new(1, -btnW - 12, 1, 0),
			SizePx = px(16),
			Color = T.Text,
			Z = 33,
		})
		UIKit.Button({
			Parent = head,
			Text = "Case",
			Size = UDim2.fromOffset(btnW, px(40)),
			Position = UDim2.new(1, -btnW, 0.5, -px(20)),
			Color = Color3.fromRGB(100, 70, 160),
			Color2 = Color3.fromRGB(60, 40, 100),
			Primary = true,
			SizePx = px(15),
			Z = 34,
			OnClick = function()
				Net.OpenAuraCase()
				openModal("case", { kind = "aura" })
			end,
		})
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(72)))
		scroll.LayoutOrder = 2
		for i, a in ipairs(profile.auras or {}) do
			local c = surfaceCard(scroll, 72, i, Rarity.Of(a.rarity))
			UIKit.Label({
				Parent = c,
				Text = string.format("%s · %s", tostring(a.name or a.id), tostring(a.rarity or "Common")),
				Size = UDim2.new(1, -px(110), 1, 0),
				SizePx = px(16),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Equip",
				Size = UDim2.fromOffset(px(96), px(38)),
				Position = UDim2.new(1, -px(96), 0.5, -px(19)),
				Color = T.Success,
				Color2 = T.Colors and T.Colors.SuccessDeep,
				SizePx = px(14),
				Z = 34,
				OnClick = function()
					Net.EquipAura(a.uid)
				end,
			})
		end
	end

	---------------------------------------------------------------- Relics
	local function refreshRelics()
		local body = bodies.relics
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		sectionLabel(body, "FROM DUNGEONS (read-only)", 1)
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(40)))
		scroll.LayoutOrder = 2
		for i, r in ipairs(profile.relics or {}) do
			local c = surfaceCard(scroll, 62, i)
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ★%s", tostring(r.name or r.id), tostring(r.stars or 1)),
				Size = UDim2.new(1, 0, 1, 0),
				SizePx = px(16),
				Color = T.Text,
				Z = 33,
			})
		end
		if #(profile.relics or {}) == 0 then
			UIKit.Label({
				Parent = scroll,
				Text = "Empty — clear dungeons.",
				Size = UDim2.new(1, 0, 0, px(48)),
				Color = T.TextMuted,
				SizePx = px(15),
			})
		end
	end

	---------------------------------------------------------------- Quests
	local function refreshQuests()
		local body = bodies.quests
		UIKit.Clear(body)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local Format = require(script.Parent.Format)
		local scroll = UIKit.Scroll(body, UDim2.fromScale(1, 1))
		-- stable order: Sam chain first by index, then others
		local list = {}
		for id, state in pairs(profile.quests or {}) do
			table.insert(list, { id = id, state = state })
		end
		table.sort(list, function(a, b)
			local da = QuestConfig.Get(a.id)
			local db = QuestConfig.Get(b.id)
			local pa = if da and da.chain == "sam" then 0 elseif da and da.chain == "frost" then 1 else 2
			local pb = if db and db.chain == "sam" then 0 elseif db and db.chain == "frost" then 1 else 2
			if pa ~= pb then
				return pa < pb
			end
			if da and db and da.chain and da.chain == db.chain then
				return (da.chainIndex or 0) < (db.chainIndex or 0)
			end
			return a.id < b.id
		end)
		local samDone, samTotal = QuestConfig.GetSamProgress(profile)
		local frostDone, frostTotal = QuestConfig.GetFrostProgress(profile)
		local order = 0
		for _, entry in ipairs(list) do
			local id = entry.id
			local state = entry.state
			order += 1
			local def = QuestConfig.Get(id)
			-- hide future chain steps until previous claimed
			local showRow = true
			if def and def.chain == "sam" then
				if (def.chainIndex or 1) > samDone + 1 then
					showRow = false
				end
			elseif def and def.chain == "frost" then
				if (def.chainIndex or 1) > frostDone + 1 then
					showRow = false
				end
			end
			if showRow then
			local name = (def and def.name) or id
			if def and def.chain == "sam" then
				name = string.format("Sam · %s  (%d/%d)", name, def.chainIndex or 0, samTotal)
			elseif def and def.chain == "frost" then
				name = string.format("Frost · %s  (%d/%d)", name, def.chainIndex or 0, frostTotal)
			end
			local desc = (def and def.description) or ""
			local amount = (def and def.amount) or 1
			local progress = state.progress or 0
			local done = state.completed == true
			local claimed = state.claimed == true
			local needBtn = done and not claimed

			local c = surfaceCard(scroll, needBtn and 118 or 100, claimed and (500 + order) or order, needBtn and T.Success or nil)
			UIKit.Label({
				Parent = c,
				Text = name,
				Size = UDim2.new(1, 0, 0, px(22)),
				SizePx = px(17),
				Font = T.Font.Title,
				Color = claimed and T.TextMuted or T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ·  %s/%s", desc, Format.Num(progress), Format.Num(amount)),
				Size = UDim2.new(1, 0, 0, px(18)),
				Position = UDim2.fromOffset(0, px(26)),
				SizePx = px(13),
				Color = T.TextMuted,
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, px(36))
			row.Position = UDim2.fromOffset(0, px(56))
			row.ZIndex = 33
			row.Parent = c
			UIKit.List(row, px(10), true)
			local track = Instance.new("Frame")
			track.BackgroundColor3 = T.Surface
			track.BorderSizePixel = 0
			track.Size = UDim2.new(needBtn and 0.65 or 1, 0, 0, px(14))
			track.LayoutOrder = 1
			track.ZIndex = 33
			track.Parent = row
			UIKit.Corner(track, 99)
			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = done and T.Success or T.Gold
			fill.BorderSizePixel = 0
			fill.Size = UDim2.new(amount > 0 and math.clamp(progress / amount, 0, 1) or 0, 0, 1, 0)
			fill.Parent = track
			UIKit.Corner(fill, 99)
			if needBtn then
				UIKit.Button({
					Parent = row,
					Text = "Claim",
					Size = UDim2.fromOffset(px(100), px(36)),
					Color = T.Success,
					Color2 = T.Colors and T.Colors.SuccessDeep,
					SizePx = px(14),
					Order = 2,
					Z = 34,
					OnClick = function()
						Net.ClaimQuest(id)
					end,
				})
			elseif claimed then
				UIKit.Label({
					Parent = row,
					Text = "done",
					Size = UDim2.fromOffset(px(72), px(32)),
					Color = T.Success,
					SizePx = px(13),
					Order = 2,
				})
			end
			end -- showRow
		end
	end

	---------------------------------------------------------------- Locations / Teleport (existing SetLocation)
	local function refreshLocations()
		local body = bodies.locations
		UIKit.Clear(body)
		UIKit.List(body, px(10), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local current = profile.currentLocation or 1
		local stats = store:PeekStats()
		local power = (stats and (stats.totalPower or stats.damagePerClick)) or 0

		sectionLabel(body, "ENTER LOCATION", 1)
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(36)))
		scroll.LayoutOrder = 2
		-- 2-col grid like SCREEENS teleport
		for _, ch in scroll:GetChildren() do
			if ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.5, -px(8), 0, px(200))
		grid.CellPadding = UDim2.fromOffset(px(10), px(10))
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = 2
		grid.Parent = scroll
		UIKit.Pad(scroll, px(4))

		local themeTint = {
			Color3.fromRGB(40, 90, 50),
			Color3.fromRGB(40, 70, 110),
			Color3.fromRGB(90, 50, 40),
			Color3.fromRGB(50, 80, 110),
		}

		local coins = (stats and stats.coins) or (profile.coins or 0)
		for i, meta in ipairs(WorldConfig.Locations) do
			local unlocked = false
			for _, id in ipairs(profile.locationsUnlocked or { 1 }) do
				if id == meta.id then
					unlocked = true
					break
				end
			end
			local travelCost = meta.travelCostCoins or 0
			local needRb = meta.unlockRebirth or 0
			local myRb = profile.rebirthLevel or 0
			local rbOk = needRb <= 0 or myRb >= needRb
			local canBuy = travelCost > 0 and coins >= travelCost and rbOk
			local here = current == meta.id
			local tint = themeTint[((i - 1) % #themeTint) + 1]

			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.new(1, 1, 1)
			card.BorderSizePixel = 0
			card.LayoutOrder = i
			card.ZIndex = 33
			card.ClipsDescendants = true
			card.Parent = scroll
			UIKit.Corner(card, T.R.sm)
			UIKit.Stroke(card, here and T.Accent or T.Stroke, here and 1.8 or 1.1, 0.2)
			UIKit.Gradient(card, T.Surface2, T.Surface, 105)

			local prev = Instance.new("Frame")
			prev.BackgroundColor3 = tint
			prev.BorderSizePixel = 0
			prev.Size = UDim2.new(1, -px(16), 0, px(72))
			prev.Position = UDim2.fromOffset(px(8), px(8))
			prev.ZIndex = 34
			prev.Parent = card
			UIKit.Corner(prev, T.R.sm)
			UIKit.Label({
				Parent = prev,
				Text = (T.WindowIcon and T.WindowIcon.locations) or "🗺",
				Size = UDim2.fromScale(1, 1),
				SizePx = px(28),
				X = Enum.TextXAlignment.Center,
				Z = 35,
			})

			UIKit.Label({
				Parent = card,
				Text = meta.name .. (here and "  ·  HERE" or ""),
				Size = UDim2.new(1, -px(16), 0, px(22)),
				Position = UDim2.fromOffset(px(8), px(88)),
				SizePx = px(14),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 34,
			})
			UIKit.Label({
				Parent = card,
				Text = (meta.blurb or meta.theme or ""):sub(1, 64),
				Size = UDim2.new(1, -px(16), 0, px(32)),
				Position = UDim2.fromOffset(px(8), px(110)),
				SizePx = px(11),
				Color = T.TextMuted,
				Wrap = true,
				Z = 34,
			})

			local btnText = "Teleport"
			local canClick = false
			local disabled = true
			if here then
				btnText = "You are here"
			elseif unlocked then
				btnText = "Teleport"
				canClick = true
				disabled = false
			elseif not rbOk then
				btnText = "Need R" .. tostring(needRb)
				disabled = true
			elseif travelCost > 0 then
				btnText = "Buy for " .. Format.Num(travelCost)
				canClick = canBuy
				disabled = not canBuy
			else
				btnText = "Teleport"
				canClick = true
				disabled = false
			end

			UIKit.Button({
				Parent = card,
				Text = btnText,
				Size = UDim2.new(1, -px(16), 0, px(34)),
				Position = UDim2.new(0, px(8), 1, -px(42)),
				Primary = canClick and not here,
				Disabled = disabled,
				Color = disabled and T.Disabled or nil,
				Color2 = disabled and (T.Colors and T.Colors.DisabledDeep) or nil,
				SizePx = px(12),
				Z = 35,
				OnClick = function()
					if here then
						return
					end
					-- SetLocation buys (if needed) + teleports
					Net.SetLocation(meta.id)
				end,
			})
		end
	end

	---------------------------------------------------------------- Dungeons
	local function refreshDungeons()
		local body = bodies.dungeons
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local tiers = {
			{ id = "easy", name = "Easy", color = T.Success },
			{ id = "medium", name = "Medium", color = T.Gold },
			{ id = "hard", name = "Hard", color = T.Danger },
		}
		local btnW = px(112)
		for i, tier in ipairs(tiers) do
			local stage = (profile.dungeonStage and profile.dungeonStage[tier.id]) or 0
			local c = surfaceCard(body, 86, i, tier.color)
			UIKit.Label({
				Parent = c,
				Text = tier.name,
				Size = UDim2.new(1, -btnW - 12, 0, px(24)),
				SizePx = px(18),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = "Stage " .. tostring(stage),
				Size = UDim2.new(1, -btnW - 12, 0, px(18)),
				Position = UDim2.fromOffset(0, px(34)),
				SizePx = px(14),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Enter",
				Size = UDim2.fromOffset(btnW, px(42)),
				Position = UDim2.new(1, -btnW, 0.5, -px(21)),
				Color = tier.color,
				Color2 = Color3.fromRGB(80, 30, 40),
				Primary = true,
				SizePx = px(15),
				Z = 34,
				OnClick = function()
					Net.StartDungeon(tier.id)
				end,
			})
		end
	end

	---------------------------------------------------------------- Cases + odds (1 sample per rarity, scroll)
	local function weightOdds(weights: { [string]: number }): { { rarity: string, pct: number } }
		local total = 0
		for _, w in pairs(weights) do
			total += w
		end
		if total <= 0 then
			total = 1
		end
		local out = {}
		for _, r in ipairs(Rarity.Order) do
			local w = weights[r]
			if w and w > 0 then
				table.insert(out, { rarity = r, pct = (w / total) * 100 })
			end
		end
		return out
	end

	local function firstOfRarity(kind: string, rarity: string, loc: number): string
		if kind == "pet" then
			for _, def in PetConfig.Pets do
				if def.rarity == rarity and (def.location == loc or loc == 0) then
					return def.name
				end
			end
			for _, def in PetConfig.Pets do
				if def.rarity == rarity then
					return def.name
				end
			end
		else
			for _, def in AuraConfig.Auras do
				if def.rarity == rarity then
					return def.name
				end
			end
		end
		return rarity
	end

	local function addOddsSection(parent: Instance, title: string, kind: string, weights: any, loc: number, order: number)
		sectionLabel(parent, title, order)
		local odds = weightOdds(weights)
		local wrap = Instance.new("Frame")
		wrap.BackgroundTransparency = 1
		wrap.Size = UDim2.new(1, 0, 0, px(100))
		wrap.LayoutOrder = order + 1
		wrap.ZIndex = 32
		wrap.Parent = parent
		local g = Instance.new("UIGridLayout")
		g.CellSize = UDim2.fromOffset(px(92), px(88))
		g.CellPadding = UDim2.fromOffset(px(8), px(8))
		g.SortOrder = Enum.SortOrder.LayoutOrder
		g.FillDirectionMaxCells = 6
		g.Parent = wrap

		for i, o in ipairs(odds) do
			local col = Rarity.Of(o.rarity)
			local cell = Instance.new("Frame")
			cell.BackgroundColor3 = Color3.new(1, 1, 1)
			cell.BorderSizePixel = 0
			cell.LayoutOrder = i
			cell.ZIndex = 33
			cell.Parent = wrap
			UIKit.Corner(cell, T.R.sm)
			UIKit.Stroke(cell, col, 1.5, 0.2)
			UIKit.Gradient(cell, T.Surface3, T.Surface2, 110)
			UIKit.Label({
				Parent = cell,
				Text = kind == "pet" and "🐾" or "✨",
				Size = UDim2.new(1, 0, 0, px(28)),
				Position = UDim2.fromOffset(0, px(6)),
				SizePx = px(20),
				X = Enum.TextXAlignment.Center,
				Z = 34,
			})
			UIKit.Label({
				Parent = cell,
				Text = firstOfRarity(kind, o.rarity, loc):sub(1, 10),
				Size = UDim2.new(1, -4, 0, px(22)),
				Position = UDim2.fromOffset(2, px(34)),
				SizePx = px(10),
				Color = T.TextSoft,
				X = Enum.TextXAlignment.Center,
				Wrap = true,
				Z = 34,
			})
			UIKit.Label({
				Parent = cell,
				Text = string.format("%.2f%%", o.pct),
				Size = UDim2.new(1, 0, 0, px(18)),
				Position = UDim2.fromOffset(0, px(62)),
				SizePx = px(12),
				Font = T.Font.Title,
				Color = col,
				X = Enum.TextXAlignment.Center,
				Z = 34,
			})
		end
	end

	local function refreshCases()
		local body = bodies.cases
		UIKit.Clear(body)
		UIKit.List(body, px(10), false)
		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0
		local petKeys = (stats and stats.petKeys) or (profile and profile.petKeys) or 0
		local auraKeys = (stats and stats.auraKeys) or (profile and profile.auraKeys) or 0
		local loc = (profile and profile.currentLocation) or 1
		local petKeyCost = CaseConfig.PET_KEY_COST or 0
		local petCoinCost = CaseConfig.PET_COIN_COST or PetConfig.OPEN_COST or 0
		local auraKeyCost = CaseConfig.AURA_KEY_COST or 1

		local head = surfaceCard(body, 48, 1, T.Stroke)
		UIKit.Label({
			Parent = head,
			Text = string.format(
				"Keys 🐾 %d  ✨ %d  ·  🪙 %s  ·  loc %d",
				petKeys,
				auraKeys,
				Format.Num(coins),
				loc
			),
			Size = UDim2.new(1, 0, 1, 0),
			SizePx = px(15),
			Color = T.TextSoft,
			Z = 33,
		})

		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(60)))
		scroll.LayoutOrder = 2

		-- Pet case (Loc1: 500 coins)
		do
			local can = true
			if petKeyCost > 0 and petKeys < petKeyCost then
				can = false
			end
			if petCoinCost > 0 and coins < petCoinCost then
				can = false
			end
			local costParts = {}
			if petKeyCost > 0 then
				table.insert(costParts, string.format("%d key", petKeyCost))
			end
			if petCoinCost > 0 then
				table.insert(costParts, Format.Num(petCoinCost) .. " coins")
			end
			local costTxt = if #costParts > 0 then table.concat(costParts, " + ") else "Free"
			local c = surfaceCard(scroll, 110, 1, T.Success)
			UIKit.Label({
				Parent = c,
				Text = "🐾  Pet Case",
				Size = UDim2.new(1, 0, 0, px(24)),
				SizePx = px(17),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("Loc %d pets  ·  cost %s", loc, costTxt),
				Size = UDim2.new(1, 0, 0, px(20)),
				Position = UDim2.fromOffset(0, px(28)),
				SizePx = px(12),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = can and ("Open · " .. costTxt) or ("Need " .. costTxt),
				Size = UDim2.new(1, 0, 0, px(38)),
				Position = UDim2.new(0, 0, 1, -px(4)),
				Anchor = Vector2.new(0, 1),
				Primary = can,
				Disabled = not can,
				SizePx = px(14),
				Z = 34,
				OnClick = function()
					if can then
						openModal("case", { kind = "pet" })
					end
				end,
			})
		end
		-- Per-pet odds from dumps (not only rarity weights)
		do
			local oddsCard = surfaceCard(scroll, 0, 5, T.Stroke)
			oddsCard.AutomaticSize = Enum.AutomaticSize.Y
			UIKit.List(oddsCard, px(4), false)
			UIKit.Label({
				Parent = oddsCard,
				Text = "PET ODDS (this location)",
				Size = UDim2.new(1, 0, 0, px(20)),
				SizePx = px(13),
				Font = T.Font.Title,
				Color = T.TextSoft,
				Z = 33,
			})
			local pool = PetConfig.GetPool(loc)
			local sumW = 0
			for _, def in pool do
				sumW += def.caseWeight or PetConfig.CaseWeights[def.rarity] or 1
			end
			for _, def in pool do
				local w = def.caseWeight or PetConfig.CaseWeights[def.rarity] or 1
				local pct = if sumW > 0 then (w / sumW) * 100 else 0
				local mult = PetConfig.GetPowerMult(def)
				UIKit.Label({
					Parent = oddsCard,
					Text = string.format(
						"%.2f%%  %s  [%s]  power x%.2f  +%d%% coins",
						pct,
						def.name,
						def.rarity,
						mult,
						math.floor(def.coinPct or 0)
					),
					Size = UDim2.new(1, 0, 0, px(18)),
					SizePx = px(12),
					Color = Rarity.Of(def.rarity),
					Z = 33,
				})
			end
			if #pool == 0 then
				UIKit.Label({
					Parent = oddsCard,
					Text = "(no pets for this location)",
					Size = UDim2.new(1, 0, 0, px(18)),
					SizePx = px(12),
					Color = T.TextMuted,
					Z = 33,
				})
			end
		end

		-- Aura case
		do
			local can = auraKeys >= auraKeyCost
			local costTxt = string.format("%d key", auraKeyCost)
			local c = surfaceCard(scroll, 110, 20, Color3.fromRGB(140, 90, 210))
			UIKit.Label({
				Parent = c,
				Text = "✨  Aura Case",
				Size = UDim2.new(1, 0, 0, px(24)),
				SizePx = px(17),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("Keys: %d  ·  random aura", auraKeys),
				Size = UDim2.new(1, 0, 0, px(20)),
				Position = UDim2.fromOffset(0, px(28)),
				SizePx = px(12),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = can and ("Open · " .. costTxt) or ("Need " .. costTxt),
				Size = UDim2.new(1, 0, 0, px(38)),
				Position = UDim2.new(0, 0, 1, -px(4)),
				Anchor = Vector2.new(0, 1),
				Primary = can,
				Disabled = not can,
				SizePx = px(14),
				Z = 34,
				OnClick = function()
					if can then
						openModal("case", { kind = "aura" })
					end
				end,
			})
		end
		addOddsSection(scroll, "POSSIBLE REWARDS · AURAS", "aura", AuraConfig.Weights, loc, 30)
	end

	---------------------------------------------------------------- Donate shop — gamepass ImageButtons
	local function refreshShop()
		local body = bodies.shop
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		sectionLabel(body, "GAMEPASSES", 1)
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(40)))
		scroll.LayoutOrder = 2
		for _, ch in scroll:GetChildren() do
			if ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(px(150), px(180))
		grid.CellPadding = UDim2.fromOffset(px(12), px(12))
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = 4
		grid.Parent = scroll
		UIKit.Pad(scroll, px(6))

		local MarketplaceService = game:GetService("MarketplaceService")
		local profile = store:PeekProfile()
		local unlocks = (profile and profile.unlocks) or {}
		for i, key in ipairs(GamePassConfig.Order) do
			local def = GamePassConfig.Get(key)
			if def then
				local owned = def.feature and unlocks[def.feature] == true
				local card = surfaceCard(scroll, 170, i, owned and T.Success or T.Stroke)
				card.Size = UDim2.fromOffset(px(140), px(168))

				local img = Instance.new("ImageButton")
				img.Name = "Buy"
				img.Size = UDim2.fromOffset(px(100), px(100))
				img.Position = UDim2.new(0.5, 0, 0, px(8))
				img.AnchorPoint = Vector2.new(0.5, 0)
				img.BackgroundColor3 = T.Surface2
				img.BorderSizePixel = 0
				img.Image = GamePassConfig.ThumbUrl(def.gamePassId, 150)
				img.ScaleType = Enum.ScaleType.Fit
				img.AutoButtonColor = not owned
				img.ImageTransparency = owned and 0.2 or 0
				img.ZIndex = 34
				img.Parent = card
				UIKit.Corner(img, T.R.sm)

				UIKit.Label({
					Parent = card,
					Text = def.title,
					Size = UDim2.new(1, -8, 0, px(28)),
					Position = UDim2.fromOffset(4, px(112)),
					SizePx = px(11),
					Color = T.Text,
					X = Enum.TextXAlignment.Center,
					Wrap = true,
					Z = 34,
				})
				local priceLab = UIKit.Label({
					Parent = card,
					Text = owned and "Owned" or "…",
					Size = UDim2.new(1, 0, 0, px(18)),
					Position = UDim2.fromOffset(0, px(142)),
					SizePx = px(12),
					Color = owned and (T.Success or Color3.fromRGB(100, 200, 120)) or T.Gold,
					Font = T.Font.Title,
					X = Enum.TextXAlignment.Center,
					Z = 34,
				})
				if not owned then
					task.spawn(function()
						local ok, info = pcall(function()
							return MarketplaceService:GetProductInfo(def.gamePassId, Enum.InfoType.GamePass)
						end)
						if priceLab.Parent then
							if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
								priceLab.Text = "R$ " .. tostring(info.PriceInRobux)
							else
								priceLab.Text = "R$ —"
							end
						end
					end)
				end
				img.MouseButton1Click:Connect(function()
					if not owned then
						Net.PromptGamePass(def.gamePassId)
					end
				end)
			end
		end
	end

	local refreshers = {
		character = refreshCharacter,
		weapons = refreshWeapons,
		pets = refreshPets,
		auras = refreshAuras,
		cases = refreshCases,
		relics = refreshRelics,
		quests = refreshQuests,
		locations = refreshLocations,
		dungeons = refreshDungeons,
		shop = refreshShop,
	}

	local api = {}
	local lastInvSig = ""

	local function inventorySignature(profile: any): string
		if type(profile) ~= "table" then
			return ""
		end
		local n = 0
		local weapons = profile.weapons
		if type(weapons) == "table" then
			n = #weapons
		end
		return table.concat({
			tostring(n),
			tostring(profile.equippedMain),
			tostring(profile.equippedOffhand),
			tostring(profile.equippedAura),
			tostring(#(profile.pets or {})),
			tostring(#(profile.auras or {})),
			tostring(#(profile.petTeam or {})),
			tostring(profile.petSlots),
		}, "|")
	end

	function api.RefreshAll()
		local panel = store:PeekPanel()
		if panel and panel ~= "none" and refreshers[panel] then
			showOnly(panel)
			-- Inventory is heavy (full rebuild). Only rebuild when bag/equip actually changes
			-- or panel just opened — not on every combat ProfileUpdate / key path.
			if panel == "weapons" then
				local prof = store:PeekProfile()
				local sig = inventorySignature(prof)
				local invStore = store :: any
				local forceTab = type(invStore._invTab) == "string" and invStore._invTab ~= ""
				if forceTab or sig ~= lastInvSig then
					lastInvSig = sig
					refreshers[panel]()
				end
			else
				refreshers[panel]()
			end
		else
			showOnly("")
			lastInvSig = ""
		end
	end

	function api.ForceRefreshPanel()
		lastInvSig = ""
		api.RefreshAll()
	end

	return api
end

return Windows
