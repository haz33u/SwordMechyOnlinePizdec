--!strict
--[[
	CasePreviewUI — Pre-open Case Preview Window showing:
	- Case Title, Player Keys & Coins
	- x1 / x3 / x5 multiplier toggle
	- Payment method toggle (Key vs Coins)
	- Main Open CTA button
	- "Possible Rewards" grid with item icons, rarity borders, & exact drop percentages!
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Rarity = require(script.Parent.Rarity)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local CaseConfig = require(Shared.Config.CaseConfig)

local CasePreviewUI = {}

local S = 1.42
local function px(n: number): number
	return math.floor(n * S + 0.5)
end

export type RewardInfo = {
	id: string,
	name: string,
	rarity: string,
	icon: string,
	sub: string?,
	weight: number,
	percentStr: string,
}

local function getPetRewards(poolIdArg: string?, locId: number): { RewardInfo }
	local pid = poolIdArg
	if type(pid) ~= "string" or not PetConfig.IsValidPool(pid) then
		pid = PetConfig.GetDefaultPoolId(locId)
	end
	local raw = PetConfig.GetPool(pid)
	local totalWeight = 0
	for _, def in ipairs(raw) do
		totalWeight += (def.caseWeight or 1)
	end
	if totalWeight <= 0 then totalWeight = 1 end

	local out: { RewardInfo } = {}
	for _, def in ipairs(raw) do
		local w = def.caseWeight or 1
		local pct = (w / totalWeight) * 100
		local pctStr = if pct >= 1 then string.format("%.2f%%", pct) else string.format("%.4f%%", pct)
		table.insert(out, {
			id = def.id,
			name = def.name,
			rarity = def.rarity,
			icon = "🐾",
			sub = string.format("power x%.2f", PetConfig.GetPowerMult(def)),
			weight = w,
			percentStr = pctStr,
		})
	end
	table.sort(out, function(a, b) return a.weight > b.weight end)
	return out
end

local function getAuraRewards(): { RewardInfo }
	local out: { RewardInfo } = {}
	local totalWeight = 0
	for _, def in pairs(AuraConfig.Auras) do
		totalWeight += (def.dropWeight or 1)
	end
	if totalWeight <= 0 then totalWeight = 1 end

	for _, def in pairs(AuraConfig.Auras) do
		local w = def.dropWeight or 1
		local pct = (w / totalWeight) * 100
		local pctStr = if pct >= 1 then string.format("%.2f%%", pct) else string.format("%.4f%%", pct)
		table.insert(out, {
			id = def.id,
			name = def.name,
			rarity = def.rarity,
			icon = "✨",
			sub = string.format("+%d%% power", math.floor(def.powerPct or 0)),
			weight = w,
			percentStr = pctStr,
		})
	end
	table.sort(out, function(a, b) return a.weight > b.weight end)
	return out
end

function CasePreviewUI.Mount(gui: ScreenGui, store: any, toastApi: any?, caseOpeningApi: any?)
	local layer = Instance.new("Folder")
	layer.Name = "CasePreviewUI"
	layer.Parent = gui

	-- Dark glass hit catcher
	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.55
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Visible = false
	dim.ZIndex = 120
	dim.Parent = layer

	-- Main Window Card
	local card = UIKit.Glass({
		Name = "PreviewCard",
		Parent = layer,
		Size = UDim2.fromScale(0.48, 0.72),
		Position = UDim2.fromScale(0.5, 0.5),
		Anchor = Vector2.new(0.5, 0.5),
		Radius = T.R.md,
		Z = 121,
		Deep = true,
	})
	card.Visible = false
	local rsc = Instance.new("UISizeConstraint")
	rsc.MinSize = Vector2.new(460, 460)
	rsc.MaxSize = Vector2.new(720, 640)
	rsc.Parent = card
	UIKit.Stroke(card, T.StrokeLight, 1.5, 0.2)
	UIKit.Pad(card, px(14))
	card.ZIndex = 121

	-- Top Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, px(36))
	header.ZIndex = 122
	header.Parent = card

	local title = UIKit.Label({
		Parent = header,
		Text = "Case Preview",
		Size = UDim2.new(0.60, 0, 1, 0),
		SizePx = px(20),
		Font = T.Font.Title,
		Color = T.Text,
		X = Enum.TextXAlignment.Left,
		Z = 123,
	})

	local currencyBox = Instance.new("Frame")
	currencyBox.Name = "CurrencyBox"
	currencyBox.BackgroundTransparency = 1
	currencyBox.Size = UDim2.new(0.35, 0, 1, 0)
	currencyBox.Position = UDim2.new(0.60, 0, 0, 0)
	currencyBox.ZIndex = 123
	currencyBox.Parent = header

	local keysLab = UIKit.Label({
		Parent = currencyBox,
		Text = "🔑 0",
		Size = UDim2.new(0.48, 0, 1, 0),
		SizePx = px(14),
		Font = T.Font.Title,
		Color = Color3.fromRGB(255, 210, 80),
		X = Enum.TextXAlignment.Right,
		Z = 124,
	})

	local coinsLab = UIKit.Label({
		Parent = currencyBox,
		Text = "🪙 0",
		Size = UDim2.new(0.48, 0, 1, 0),
		Position = UDim2.new(0.50, 0, 0, 0),
		SizePx = px(14),
		Font = T.Font.Title,
		Color = Color3.fromRGB(100, 220, 255),
		X = Enum.TextXAlignment.Right,
		Z = 124,
	})

	local closeBtn = UIKit.Button({
		Name = "Close",
		Parent = card,
		Text = "✕",
		Size = UDim2.fromOffset(px(36), px(36)),
		Position = UDim2.new(1, 0, 0, 0),
		Anchor = Vector2.new(1, 0),
		Color = T.Danger,
		Color2 = T.Colors and T.Colors.DangerDeep or Color3.fromRGB(160, 40, 50),
		SizePx = px(16),
		Compact = true,
		Radius = T.R.sm,
		Z = 130,
	})

	-- Top Horizontal Reel Preview Strip
	local previewStripHost = Instance.new("Frame")
	previewStripHost.Name = "PreviewStripHost"
	previewStripHost.BackgroundColor3 = Color3.new(1, 1, 1)
	previewStripHost.BorderSizePixel = 0
	previewStripHost.Size = UDim2.new(1, 0, 0, px(80))
	previewStripHost.Position = UDim2.fromOffset(0, px(42))
	previewStripHost.ClipsDescendants = true
	previewStripHost.ZIndex = 122
	previewStripHost.Parent = card
	UIKit.Corner(previewStripHost, T.R.sm)
	UIKit.Stroke(previewStripHost, T.StrokeLight, 1.2, 0.3)
	UIKit.Gradient(previewStripHost, T.Surface2, T.Bg, 90)

	local stripScroll = Instance.new("ScrollingFrame")
	stripScroll.Size = UDim2.fromScale(1, 1)
	stripScroll.BackgroundTransparency = 1
	stripScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	stripScroll.ScrollBarThickness = 0
	stripScroll.ZIndex = 123
	stripScroll.Parent = previewStripHost

	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	stripLayout.Padding = UDim.new(0, px(8))
	stripLayout.Parent = stripScroll

	-- Controls Row: x1 / x3 / x5 + Payment Mode + Big Open Button
	local controlsFrame = Instance.new("Frame")
	controlsFrame.Name = "ControlsFrame"
	controlsFrame.BackgroundTransparency = 1
	controlsFrame.Size = UDim2.new(1, 0, 0, px(90))
	controlsFrame.Position = UDim2.fromOffset(0, px(130))
	controlsFrame.ZIndex = 122
	controlsFrame.Parent = card

	-- Multiplier selector buttons (x1, x3, x5)
	local multRow = Instance.new("Frame")
	multRow.Name = "MultRow"
	multRow.BackgroundTransparency = 1
	multRow.Size = UDim2.new(0.40, 0, 0, px(34))
	multRow.Position = UDim2.fromOffset(0, 0)
	multRow.ZIndex = 123
	multRow.Parent = controlsFrame

	local multLayout = Instance.new("UIListLayout")
	multLayout.FillDirection = Enum.FillDirection.Horizontal
	multLayout.Padding = UDim.new(0, px(6))
	multLayout.Parent = multRow

	local multBtns: { [number]: TextButton } = {}
	local currentCount = 1

	for _, cnt in ipairs({ 1, 3, 5 }) do
		local btn = UIKit.Button({
			Name = "Mult_" .. cnt,
			Parent = multRow,
			Text = "x" .. cnt,
			Size = UDim2.new(0.31, 0, 1, 0),
			Color = if cnt == 1 then T.Accent else T.Surface3,
			Color2 = if cnt == 1 then T.AccentDeep else T.Surface2,
			SizePx = px(14),
			Compact = true,
			Radius = T.R.sm,
			Z = 124,
		})
		multBtns[cnt] = btn
	end

	-- Payment mode toggle (For Key vs For Coins)
	local payRow = Instance.new("Frame")
	payRow.Name = "PayRow"
	payRow.BackgroundTransparency = 1
	payRow.Size = UDim2.new(0.58, 0, 0, px(34))
	payRow.Position = UDim2.new(0.42, 0, 0, 0)
	payRow.ZIndex = 123
	payRow.Parent = controlsFrame

	local payLayout = Instance.new("UIListLayout")
	payLayout.FillDirection = Enum.FillDirection.Horizontal
	payLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	payLayout.Padding = UDim.new(0, px(6))
	payLayout.Parent = payRow

	local keyPayBtn = UIKit.Button({
		Name = "PayKey",
		Parent = payRow,
		Text = "For Key 🔑",
		Size = UDim2.new(0.48, 0, 1, 0),
		Color = T.Accent,
		Color2 = T.AccentDeep,
		SizePx = px(13),
		Compact = true,
		Radius = T.R.sm,
		Z = 124,
	})

	local coinPayBtn = UIKit.Button({
		Name = "PayCoins",
		Parent = payRow,
		Text = "For Coins 🪙",
		Size = UDim2.new(0.48, 0, 1, 0),
		Color = T.Surface3,
		Color2 = T.Surface2,
		SizePx = px(13),
		Compact = true,
		Radius = T.R.sm,
		Z = 124,
	})

	local currentPayMode = "key" -- "key" or "coin"

	-- Main Open CTA Button
	local openCtaBtn = UIKit.Button({
		Name = "OpenCTA",
		Parent = controlsFrame,
		Text = "Open for 1 🔑",
		Size = UDim2.new(1, 0, 0, px(42)),
		Position = UDim2.fromOffset(0, px(44)),
		Color = T.Success,
		Color2 = T.Colors and T.Colors.SuccessDeep or Color3.fromRGB(28, 140, 80),
		Primary = true,
		SizePx = px(16),
		Radius = T.R.sm,
		Z = 125,
	})

	-- Possible Rewards Section ("Possible Rewards")
	local rewardsHeader = UIKit.Label({
		Parent = card,
		Text = "Possible Rewards",
		Size = UDim2.new(1, 0, 0, px(24)),
		Position = UDim2.fromOffset(0, px(228)),
		SizePx = px(15),
		Font = T.Font.Title,
		Color = T.TextMuted,
		X = Enum.TextXAlignment.Left,
		Z = 122,
	})

	local rewardsScroll = Instance.new("ScrollingFrame")
	rewardsScroll.Name = "RewardsScroll"
	rewardsScroll.BackgroundTransparency = 1
	rewardsScroll.Size = UDim2.new(1, 0, 1, -px(260))
	rewardsScroll.Position = UDim2.fromOffset(0, px(255))
	rewardsScroll.ScrollBarThickness = 5
	rewardsScroll.ScrollBarImageColor3 = T.Accent
	rewardsScroll.ZIndex = 122
	rewardsScroll.Parent = card

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(px(100), px(125))
	grid.CellPadding = UDim2.fromOffset(px(8), px(8))
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = rewardsScroll

	local currentKind = "pet"
	local currentPoolId: string? = nil

	local function hideAll()
		dim.Visible = false
		card.Visible = false
	end

	closeBtn.MouseButton1Click:Connect(hideAll)
	dim.MouseButton1Click:Connect(hideAll)

	local function updateCtaText()
		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local loc = (profile and profile.currentLocation) or 1

		local singleKeyCost = 0
		local singleCoinCost = 0
		if currentKind == "aura" then
			singleKeyCost = CaseConfig.AURA_KEY_COST or 1
			singleCoinCost = CaseConfig.AURA_COIN_COST or 0
		else
			local pid = currentPoolId or PetConfig.GetDefaultPoolId(loc)
			singleCoinCost, singleKeyCost = PetConfig.GetCaseCosts(pid)
		end

		local keyCost = singleKeyCost * currentCount
		local coinCost = singleCoinCost * currentCount

		if currentPayMode == "key" and keyCost > 0 then
			openCtaBtn:FindFirstChild("Label", true).Text = string.format("Open x%d for %d 🔑", currentCount, keyCost)
		elseif currentPayMode == "coin" and coinCost > 0 then
			openCtaBtn:FindFirstChild("Label", true).Text = string.format("Open x%d for %s 🪙", currentCount, Format.Num(coinCost))
		else
			if keyCost > 0 then
				openCtaBtn:FindFirstChild("Label", true).Text = string.format("Open x%d for %d 🔑", currentCount, keyCost)
			else
				openCtaBtn:FindFirstChild("Label", true).Text = string.format("Open x%d for %s 🪙", currentCount, Format.Num(coinCost))
			end
		end

		local keys = if currentKind == "aura"
			then ((stats and stats.auraKeys) or (profile and profile.auraKeys) or 0)
			else ((stats and stats.petKeys) or (profile and profile.petKeys) or 0)
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0

		keysLab.Text = "🔑 " .. Format.Num(keys)
		coinsLab.Text = "🪙 " .. Format.Num(coins)
	end

	-- Multiplier selection handler
	for cnt, btn in pairs(multBtns) do
		btn.MouseButton1Click:Connect(function()
			currentCount = cnt
			for c, b in pairs(multBtns) do
				UIKit.Gradient(b, if c == cnt then T.Accent else T.Surface3, if c == cnt then T.AccentDeep else T.Surface2, 100)
			end
			updateCtaText()
		end)
	end

	-- Payment mode selection handler
	keyPayBtn.MouseButton1Click:Connect(function()
		currentPayMode = "key"
		UIKit.Gradient(keyPayBtn, T.Accent, T.AccentDeep, 100)
		UIKit.Gradient(coinPayBtn, T.Surface3, T.Surface2, 100)
		updateCtaText()
	end)

	coinPayBtn.MouseButton1Click:Connect(function()
		currentPayMode = "coin"
		UIKit.Gradient(coinPayBtn, T.Accent, T.AccentDeep, 100)
		UIKit.Gradient(keyPayBtn, T.Surface3, T.Surface2, 100)
		updateCtaText()
	end)

	-- Launch 3D Case Opening on CTA click
	openCtaBtn.MouseButton1Click:Connect(function()
		hideAll()
		if caseOpeningApi and type(caseOpeningApi.Begin) == "function" then
			caseOpeningApi.Begin({
				kind = currentKind,
				poolId = currentPoolId,
				count = currentCount,
			})
		end
	end)

	local api = {}

	function api.Show(payload: any?)
		currentKind = (payload and payload.kind) or "pet"
		if currentKind ~= "pet" and currentKind ~= "aura" then
			currentKind = "pet"
		end
		currentPoolId = if payload and type(payload.poolId) == "string" then payload.poolId else nil
		currentCount = 1

		local profile = store:PeekProfile()
		local loc = (profile and profile.currentLocation) or 1
		local caseName = if currentKind == "aura"
			then "Aura Case"
			else string.format("Pet Case (%s)", if currentPoolId == "loc1_50k" then "50K" else (if currentPoolId == "loc1_key49" then "49 R$" else "500"))

		title.Text = caseName
		dim.Visible = true
		card.Visible = true

		-- Reset multipliers UI
		for c, b in pairs(multBtns) do
			UIKit.Gradient(b, if c == 1 then T.Accent else T.Surface3, if c == 1 then T.AccentDeep else T.Surface2, 100)
		end
		updateCtaText()

		-- Clear previous rewards & preview strips
		for _, c in rewardsScroll:GetChildren() do
			if not c:IsA("UIGridLayout") then
				c:Destroy()
			end
		end
		for _, c in stripScroll:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end

		-- Load reward definitions & calculate drop percentages
		local rewards = if currentKind == "aura" then getAuraRewards() else getPetRewards(currentPoolId, loc)

		-- Populate Top Reel Strip
		for i, r in ipairs(rewards) do
			local col = Rarity.Of(r.rarity)
			local cell = Instance.new("Frame")
			cell.BackgroundColor3 = Color3.new(1, 1, 1)
			cell.BorderSizePixel = 0
			cell.Size = UDim2.fromOffset(px(60), px(68))
			cell.LayoutOrder = i
			cell.ZIndex = 124
			cell.Parent = stripScroll
			UIKit.Corner(cell, T.R.sm)
			UIKit.Stroke(cell, col, 1.6, 0.25)
			UIKit.Gradient(cell, T.Surface2, T.Surface, 100)

			UIKit.Label({
				Parent = cell,
				Text = r.icon,
				Size = UDim2.new(1, 0, 0, px(32)),
				SizePx = px(22),
				X = Enum.TextXAlignment.Center,
				Z = 125,
			})
			UIKit.Label({
				Parent = cell,
				Text = r.name,
				Size = UDim2.new(1, -2, 0, px(24)),
				Position = UDim2.fromOffset(1, px(34)),
				SizePx = px(10),
				Font = T.Font.Title,
				Color = T.Text,
				X = Enum.TextXAlignment.Center,
				Wrap = true,
				Z = 125,
			})
		end

		-- Populate Possible Rewards Grid
		for i, r in ipairs(rewards) do
			local col = Rarity.Of(r.rarity)
			local rCard = Instance.new("Frame")
			rCard.BackgroundColor3 = Color3.new(1, 1, 1)
			rCard.BorderSizePixel = 0
			rCard.LayoutOrder = i
			rCard.ZIndex = 124
			rCard.Parent = rewardsScroll
			UIKit.Corner(rCard, T.R.sm)
			UIKit.Stroke(rCard, col, 1.8, 0.2)
			UIKit.Gradient(rCard, T.Surface2, T.Surface, 100)
			UIKit.Pad(rCard, px(4))

			UIKit.Label({
				Parent = rCard,
				Text = r.icon,
				Size = UDim2.new(1, 0, 0, px(36)),
				SizePx = px(26),
				X = Enum.TextXAlignment.Center,
				Z = 125,
			})

			UIKit.Label({
				Parent = rCard,
				Text = r.name,
				Size = UDim2.new(1, 0, 0, px(24)),
				Position = UDim2.fromOffset(0, px(38)),
				SizePx = px(11),
				Font = T.Font.Title,
				Color = T.Text,
				X = Enum.TextXAlignment.Center,
				Wrap = true,
				Z = 125,
			})

			local badge = Instance.new("Frame")
			badge.BackgroundColor3 = col
			badge.BorderSizePixel = 0
			badge.Size = UDim2.new(1, 0, 0, px(16))
			badge.Position = UDim2.fromOffset(0, px(64))
			badge.ZIndex = 125
			badge.Parent = rCard
			UIKit.Corner(badge, T.R.sm)
			UIKit.Label({
				Parent = badge,
				Text = string.upper(r.rarity),
				Size = UDim2.fromScale(1, 1),
				SizePx = px(9),
				Font = T.Font.Title,
				Color = Color3.new(1, 1, 1),
				X = Enum.TextXAlignment.Center,
				Z = 126,
			})

			-- Exact Drop Percentage Label
			local pctLab = UIKit.Label({
				Parent = rCard,
				Text = r.percentStr,
				Size = UDim2.new(1, 0, 0, px(20)),
				Position = UDim2.new(0, 0, 1, -px(20)),
				SizePx = px(12),
				Font = T.Font.Title,
				Color = Color3.fromRGB(255, 235, 120),
				X = Enum.TextXAlignment.Center,
				Z = 125,
			})
			pctLab.TextStrokeTransparency = 0.3
		end

		-- Calculate scroll canvas size
		local rows = math.ceil(#rewards / 4)
		rewardsScroll.CanvasSize = UDim2.new(0, 0, 0, rows * px(133))
	end

	function api.Hide()
		hideAll()
	end

	return api
end

return CasePreviewUI
