--!strict
--[[
	WEAPON INVENTORY LAYOUT — 1:1 Figma node 5193:9879
	Ref size: 11014 x 7652 (aspect 1.4393)
	All positions = absoluteBoundingBox fractions of layout root.
	Assets: InventoryAssetConfig (IMAGE rbxassetids)
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Rarity = require(script.Parent.Rarity)
local WeaponModels = require(script.Parent.WeaponModels)
local PetVisual = require(script.Parent.PetVisual)
local AuraVisual = require(script.Parent.AuraVisual)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(Shared.Config.WeaponConfig)
local InventoryAssetConfig = require(Shared.Config.InventoryAssetConfig)
local IconConfig = require(Shared.Config.IconConfig)

local InventoryWeaponsLayout = {}

local ROOT_NAME = "FigmaWeaponsRoot"
-- Live Figma group 5193:9879 (re-measured 2026-07-26): 11609 x 7943
local ASPECT = 1.4614
local HOVER_SCALE = 1.06
local GRID_COLS = 6

-- Absolute fractions from Figma absoluteBoundingBox / root
local L = {
	MAINBACKGROUD = { 0.12563, 0.08995, 0.87437, 0.78063 },
	INVENTORYWEAPONcard = { 0.05513, 0.00000, 0.30762, 0.15381 },
	BTN_Close = { 0.94964, 0.10952, 0.03966, 0.05929 },
	TitleNickPlate = { 0.78407, 0.10952, 0.15204, 0.04129 },
	-- Divider sits on top of grid; use Figma x/w (art has tall transparent pad → use modest h)
	Divider = { 0.34500, 0.11531, 0.62023, 0.03500 },
	BG_WeaponGrid = { 0.32794, 0.16881, 0.65460, 0.67376 },
	EQUIPMENTbackground = { 0.14369, 0.13722, 0.17323, 0.38434 },
	EquipTitlePlate = { 0.18400, 0.14880, 0.09252, 0.02757 },
	MAINswordCARD = { 0.15936, 0.17285, 0.06995, 0.10222 },
	SECONDswordCARD = { 0.23147, 0.17285, 0.06995, 0.10222 }, -- second sword (also named MAINswordCARD in Figma)
	PETcard1 = { 0.16031, 0.27169, 0.03497, 0.05111 },
	PETcard2 = { 0.19529, 0.27169, 0.03497, 0.05111 },
	PETcard3 = { 0.23026, 0.27169, 0.03497, 0.05111 },
	PETcard4 = { 0.26523, 0.27169, 0.03497, 0.05111 },
	PETcard5 = { 0.16031, 0.32281, 0.03497, 0.05111 },
	PETcard6 = { 0.19529, 0.32281, 0.03497, 0.05111 },
	PETcard7 = { 0.23026, 0.32281, 0.03497, 0.05111 },
	PETcard8 = { 0.26523, 0.32281, 0.03497, 0.05111 },
	RELICcard1 = { 0.16031, 0.37392, 0.04764, 0.06962 },
	RELICcard2 = { 0.20795, 0.37392, 0.04764, 0.06962 },
	RELICcard3 = { 0.25559, 0.37392, 0.04764, 0.06962 },
	AURAcard = { 0.20795, 0.44353, 0.04764, 0.06962 },
	EQUIPbestFORdamage = { 0.14205, 0.51670, 0.17935, 0.08737 },
	EQUIPbestFORpower = { 0.14170, 0.60003, 0.18150, 0.08837 },
	PRESETSbutton = { 0.14946, 0.68047, 0.16453, 0.06043 },
	PRESETcard1 = { 0.14584, 0.73573, 0.04299, 0.06282 },
	PRESETcard2 = { 0.18667, 0.73573, 0.04324, 0.06320 },
	PRESETcard3 = { 0.22776, 0.73572, 0.04367, 0.06383 },
	PRESETcard4 = { 0.26902, 0.73534, 0.04454, 0.06508 },
	SELLbutton = { 0.13499, 0.80264, 0.09570, 0.04667 },
	SELLallUNLOCKED = { 0.22991, 0.80180, 0.09933, 0.04844 },
	MOUSEBINDScard = { 0.00000, 0.60792, 0.13144, 0.26360 },
	WEAPONSBUTTON = { 0.17366, 0.87978, 0.08184, 0.11960 },
	PETCBUTTON = { 0.26127, 0.87978, 0.08184, 0.11960 },
	AURABUTTON = { 0.34888, 0.88040, 0.08184, 0.11960 },
	RELICBUTTON = { 0.43648, 0.88040, 0.08184, 0.11960 },
	CONSUMABLESBUTTON = { 0.52409, 0.88040, 0.08184, 0.11960 },
	SHOPBUTTON = { 0.61170, 0.87978, 0.08184, 0.11960 },
	PROFILEBUTTON = { 0.69844, 0.87978, 0.08184, 0.11960 },
	SETTINGSBUTTON = { 0.82533, 0.87978, 0.08184, 0.11960 },
}

local FIGMA_TABS = {
	{ id = "weapons", key = "WEAPONSBUTTON", box = L.WEAPONSBUTTON },
	{ id = "pets", key = "PETCBUTTON", box = L.PETCBUTTON },
	{ id = "auras", key = "AURABUTTON", box = L.AURABUTTON },
	{ id = "relics", key = "RELICBUTTON", box = L.RELICBUTTON },
	{ id = "items", key = "CONSUMABLESBUTTON", box = L.CONSUMABLESBUTTON },
	{ id = "shop", key = "SHOPBUTTON", box = L.SHOPBUTTON },
	{ id = "profile", key = "PROFILEBUTTON", box = L.PROFILEBUTTON },
	{ id = "settings", key = "SETTINGSBUTTON", box = L.SETTINGSBUTTON },
}

local function art(key: string): string
	return InventoryAssetConfig.Get(key)
end

local function box(b: { number }): (UDim2, UDim2)
	return UDim2.fromScale(b[3], b[4]), UDim2.fromScale(b[1], b[2])
end

local function placeImage(
	parent: Instance,
	name: string,
	assetKey: string,
	b: { number },
	z: number?,
	scaleType: Enum.ScaleType?
): ImageLabel
	local i = Instance.new("ImageLabel")
	i.Name = name
	i.BackgroundTransparency = 1
	i.BorderSizePixel = 0
	i.Image = art(assetKey)
	i.ScaleType = scaleType or Enum.ScaleType.Fit
	i.Size, i.Position = box(b)
	i.ZIndex = z or 40
	i.Parent = parent
	return i
end

local function placeButton(
	parent: Instance,
	name: string,
	assetKey: string,
	b: { number },
	z: number?,
	onClick: (() -> ())?
): ImageButton
	local i = Instance.new("ImageButton")
	i.Name = name
	i.BackgroundTransparency = 1
	i.BorderSizePixel = 0
	i.Image = art(assetKey)
	i.ScaleType = Enum.ScaleType.Fit
	i.AutoButtonColor = false
	i.Size, i.Position = box(b)
	i.ZIndex = z or 50
	i.Parent = parent
	local sc = Instance.new("UIScale")
	sc.Parent = i
	i.MouseEnter:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1.05 }):Play()
	end)
	i.MouseLeave:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	if onClick then
		i.MouseButton1Click:Connect(onClick)
	end
	return i
end

local function tipText(parent: Instance, order: number, text: string, grad: string?, h: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = "T" .. order
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -20, 0, h or 26)
	l.LayoutOrder = order
	l.Text = string.upper(text)
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextWrapped = true
	l.ZIndex = (parent :: GuiObject).ZIndex + 2
	l.Parent = parent
	UIKit.StyleText(l, grad or "purple", 3)
	return l
end

export type RenderArgs = {
	profile: any,
	stats: any?,
	onClose: () -> (),
	onTab: (tabId: string) -> (),
	onRefresh: () -> (),
}

function InventoryWeaponsLayout.Destroy(parent: Instance)
	local old = parent:FindFirstChild(ROOT_NAME)
	if old then
		old:Destroy()
	end
end

function InventoryWeaponsLayout.Render(parent: Frame, args: RenderArgs)
	InventoryWeaponsLayout.Destroy(parent)

	local profile = args.profile

	local root = Instance.new("Frame")
	root.Name = ROOT_NAME
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 1)
	root.ClipsDescendants = false
	root.ZIndex = 30
	root.Parent = parent

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = ASPECT
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	aspect.DominantAxis = Enum.DominantAxis.Width
	aspect.Parent = root

	---------------------------------------------------------------- shell
	placeImage(root, "MAINBACKGROUD", "MAINBACKGROUD", L.MAINBACKGROUD, 30, Enum.ScaleType.Stretch)
	placeImage(root, "INVENTORYWEAPONcard", "INVENTORYWEAPONcard", L.INVENTORYWEAPONcard, 45)
	-- Stretch divider exactly over the weapon grid top edge
	local divider = placeImage(root, "Divider", "Divider_3_Minimal_1", L.Divider, 42, Enum.ScaleType.Stretch)
	divider.ImageTransparency = 0

	placeButton(root, "Close", "BTN_Close_3", L.BTN_Close, 80, args.onClose)

	-- Title | Nick plate
	local nickPlate = placeImage(root, "TitleNickPlate", "btn_neutral_2_1", L.TitleNickPlate, 40)
	local nickStrip = Instance.new("TextLabel")
	nickStrip.Name = "NickStrip"
	nickStrip.BackgroundTransparency = 1
	nickStrip.Size = UDim2.fromScale(0.9, 0.7)
	nickStrip.Position = UDim2.fromScale(0.5, 0.5)
	nickStrip.AnchorPoint = Vector2.new(0.5, 0.5)
	local titleTxt = (profile and (profile.equippedTitle or profile.title)) or "TITLE"
	local nickTxt = (Players.LocalPlayer and Players.LocalPlayer.Name) or "PLAYER"
	nickStrip.Text = string.upper(tostring(titleTxt) .. " | " .. tostring(nickTxt))
	nickStrip.ZIndex = 41
	nickStrip.Parent = nickPlate
	UIKit.StyleText(nickStrip, "gold", 2)

	---------------------------------------------------------------- equip panel (absolute Figma coords on root)
	placeImage(root, "EQUIPMENTbackground", "EQUIPMENTbackground", L.EQUIPMENTbackground, 35, Enum.ScaleType.Stretch)

	local equipTitleBg = placeImage(root, "EquipTitlePlate", "btn_neutral_2_2", L.EquipTitlePlate, 36)
	local equipTitle = Instance.new("TextLabel")
	equipTitle.BackgroundTransparency = 1
	equipTitle.Size = UDim2.fromScale(0.92, 0.75)
	equipTitle.Position = UDim2.fromScale(0.5, 0.5)
	equipTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	equipTitle.Text = "EQUIPMENT"
	equipTitle.ZIndex = 37
	equipTitle.Parent = equipTitleBg
	UIKit.StyleText(equipTitle, "purple", 2)

	local function fillWeaponCard(assetKey: string, b: { number }, weaponUid: string?)
		local plate = placeImage(root, assetKey, assetKey, b, 38)
		local host = Instance.new("Frame")
		host.Name = "VpHost"
		host.BackgroundTransparency = 1
		host.Size = UDim2.fromScale(0.72, 0.72)
		host.Position = UDim2.fromScale(0.5, 0.5)
		host.AnchorPoint = Vector2.new(0.5, 0.5)
		host.ZIndex = 39
		host.Parent = plate
		if weaponUid then
			for _, w in ipairs(profile.weapons or {}) do
				if w.uid == weaponUid then
					pcall(function()
						WeaponModels.TryFillInventoryIcon(host, w.id, 48)
					end)
					break
				end
			end
		end
		return plate
	end

	fillWeaponCard("MAINswordCARD", L.MAINswordCARD, profile.equippedMain)
	fillWeaponCard("SECONDswordCARD", L.SECONDswordCARD, profile.equippedOffhand)

	local team = profile.petTeam or {}
	local petByUid: { [string]: any } = {}
	for _, p in ipairs(profile.pets or {}) do
		petByUid[tostring(p.uid)] = p
	end
	local petBoxes = {
		L.PETcard1,
		L.PETcard2,
		L.PETcard3,
		L.PETcard4,
		L.PETcard5,
		L.PETcard6,
		L.PETcard7,
		L.PETcard8,
	}
	for i = 1, 8 do
		local key = "PETcard" .. i
		local plate = placeImage(root, key, key, petBoxes[i], 38)
		local uid = team[i]
		if uid and petByUid[tostring(uid)] then
			local host = Instance.new("Frame")
			host.BackgroundTransparency = 1
			host.Size = UDim2.fromScale(0.78, 0.78)
			host.Position = UDim2.fromScale(0.5, 0.5)
			host.AnchorPoint = Vector2.new(0.5, 0.5)
			host.ZIndex = 39
			host.Parent = plate
			pcall(function()
				PetVisual.TryFillInventoryIcon(host, petByUid[tostring(uid)].id, 32)
			end)
		end
	end

	for i = 1, 3 do
		placeImage(root, "RELICcard" .. i, "RELICcard" .. i, ({ L.RELICcard1, L.RELICcard2, L.RELICcard3 })[i], 38)
	end
	do
		local auraPlate = placeImage(root, "AURAcard", "RELICcard1", L.AURAcard, 38)
		if profile.equippedAura then
			local host = Instance.new("Frame")
			host.BackgroundTransparency = 1
			host.Size = UDim2.fromScale(0.8, 0.8)
			host.Position = UDim2.fromScale(0.5, 0.5)
			host.AnchorPoint = Vector2.new(0.5, 0.5)
			host.ZIndex = 39
			host.Parent = auraPlate
			pcall(function()
				AuraVisual.TryFillInventoryIcon(host, profile.equippedAura, 36)
			end)
		end
	end

	local function rankWeapons(): { { uid: string, power: number, level: number } }
		local ranked = {}
		for _, w in ipairs(profile.weapons or {}) do
			local d = WeaponConfig.Get(w.id)
			table.insert(ranked, {
				uid = w.uid,
				power = (d and d.powerMult) or 0,
				level = w.level or 1,
			})
		end
		table.sort(ranked, function(a, b)
			if a.power ~= b.power then
				return a.power > b.power
			end
			return a.level > b.level
		end)
		return ranked
	end

	placeButton(root, "EQUIPbestFORdamageBUTTON", "EQUIPbestFORdamageBUTTON", L.EQUIPbestFORdamage, 50, function()
		local ranked = rankWeapons()
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		args.onRefresh()
	end)
	placeButton(root, "EQUIPbestFORpowerBUTTON", "EQUIPbestFORpowerBUTTON", L.EQUIPbestFORpower, 50, function()
		local ranked = rankWeapons()
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		if ranked[2] then
			Net.EquipWeapon(ranked[2].uid, "offhand")
		end
		args.onRefresh()
	end)

	-- Presets
	placeImage(root, "PRESETSbutton", "WORDMARK_presets__click_to_equip_1", L.PRESETSbutton, 40)
	for i = 1, 4 do
		placeImage(root, "PRESETcard" .. i, "PRESETcard" .. i, ({ L.PRESETcard1, L.PRESETcard2, L.PRESETcard3, L.PRESETcard4 })[i], 41)
	end

	placeButton(root, "SELLbutton", "SELLbutton", L.SELLbutton, 50, function() end)
	placeButton(root, "SELLallUNLOCKEDbutton", "SELLallUNLOCKEDbutton", L.SELLallUNLOCKED, 50, function()
		Net.SellAllWeapons()
		args.onRefresh()
	end)

	placeImage(root, "MOUSEBINDScard", "MOUSEBINDScard", L.MOUSEBINDScard, 55)

	---------------------------------------------------------------- weapon grid (slots clipped strictly inside)
	local gridHost = Instance.new("Frame")
	gridHost.Name = "BG_WeaponGrid"
	gridHost.BackgroundTransparency = 1
	gridHost.Size, gridHost.Position = box(L.BG_WeaponGrid)
	gridHost.ZIndex = 35
	gridHost.ClipsDescendants = true
	gridHost.Parent = root

	local gridBg = Instance.new("ImageLabel")
	gridBg.Name = "GridBg"
	gridBg.BackgroundTransparency = 1
	gridBg.Image = art("BG_WeaponGrid")
	gridBg.ScaleType = Enum.ScaleType.Stretch
	gridBg.Size = UDim2.fromScale(1, 1)
	gridBg.ZIndex = 35
	gridBg.Parent = gridHost

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Slots"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(0.96, 0.96)
	scroll.Position = UDim2.fromScale(0.02, 0.02)
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 140, 255)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ClipsDescendants = true
	scroll.ZIndex = 36
	scroll.Parent = gridHost

	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = GRID_COLS
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	-- Tighter gap between weapon cards
	grid.CellPadding = UDim2.fromOffset(4, 4)
	grid.Parent = scroll

	local function relayout()
		local w = scroll.AbsoluteSize.X
		if w < 40 then
			return
		end
		local pad = 4
		local cell = math.floor((w - pad * (GRID_COLS - 1)) / GRID_COLS)
		cell = math.clamp(cell, 48, 130)
		grid.CellSize = UDim2.fromOffset(cell, cell)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)

	---------------------------------------------------------------- tooltip: shell BEHIND text (Z), follow mouse
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Size = UDim2.fromOffset(280, 168)
	tip.ZIndex = 250
	tip.ClipsDescendants = false
	tip.Parent = root
	-- Sibling order so shell cannot paint over labels
	tip.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local tipBg = Instance.new("ImageLabel")
	tipBg.Name = "Shell"
	tipBg.BackgroundTransparency = 1
	tipBg.Image = art("TOOLTIPshell")
	tipBg.ScaleType = Enum.ScaleType.Stretch
	tipBg.Size = UDim2.fromScale(1, 1)
	tipBg.ZIndex = 1 -- behind content
	tipBg.Parent = tip

	local tipBody = Instance.new("Frame")
	tipBody.Name = "Body"
	tipBody.BackgroundTransparency = 1
	tipBody.Size = UDim2.fromScale(1, 1)
	tipBody.ZIndex = 10 -- above shell
	tipBody.Parent = tip
	UIKit.Pad(tipBody, 14)
	local tipList = Instance.new("UIListLayout")
	tipList.SortOrder = Enum.SortOrder.LayoutOrder
	tipList.Padding = UDim.new(0, 3)
	tipList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tipList.VerticalAlignment = Enum.VerticalAlignment.Center
	tipList.Parent = tipBody

	local function clearTip()
		for _, c in tipBody:GetChildren() do
			if c:IsA("TextLabel") or c:IsA("Frame") then
				c:Destroy()
			end
		end
	end

	local function placeTip()
		if not tip.Visible or not tip.Parent then
			return
		end
		local inset = GuiService:GetGuiInset()
		local mouse = UserInputService:GetMouseLocation()
		local mx = mouse.X - inset.X
		local my = mouse.Y - inset.Y
		local parentAbs = root.AbsolutePosition
		local parentSz = root.AbsoluteSize
		local tipW = tip.AbsoluteSize.X
		local tipH = tip.AbsoluteSize.Y
		if tipW < 8 then
			tipW = 280
		end
		if tipH < 8 then
			tipH = 168
		end
		local EDGE = 12
		local screenX = mx + EDGE
		if screenX + tipW > parentAbs.X + parentSz.X - 4 then
			screenX = mx - EDGE - tipW
		end
		local screenY = my + 8
		if screenY + tipH > parentAbs.Y + parentSz.Y - 4 then
			screenY = parentAbs.Y + parentSz.Y - tipH - 4
		end
		if screenY < parentAbs.Y + 2 then
			screenY = parentAbs.Y + 2
		end
		tip.Position = UDim2.fromOffset(
			math.floor(screenX - parentAbs.X + 0.5),
			math.floor(screenY - parentAbs.Y + 0.5)
		)
	end

	local function showTip(title: string, rarity: string?, power: number, sell: number, level: number, equippedLine: string?)
		clearTip()
		local order = 1
		if equippedLine then
			tipText(tipBody, order, equippedLine, "gold", 22)
			order += 1
		end
		tipText(tipBody, order, title, "purple", 28)
		order += 1
		if rarity then
			tipText(tipBody, order, rarity, "gray", 20)
			order += 1
		end
		tipText(tipBody, order, string.format("POWER: ×%.2f", power), "purple", 20)
		order += 1
		tipText(tipBody, order, string.format("SELL PRICE: %d", sell), "gold", 20)
		order += 1
		tipText(tipBody, order, string.format("LEVEL: %d", level), "gray", 20)
		tip.Visible = true
		task.defer(placeTip)
		placeTip()
	end

	local function hideTip()
		tip.Visible = false
	end

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible and tip.Parent then
			placeTip()
		end
	end)

	---------------------------------------------------------------- slots
	local weapons = profile.weapons or {}
	local function makeSlot(order: number, w: any?)
		local btn = Instance.new("ImageButton")
		btn.Name = if w then ("W_" .. w.uid) else ("Empty_" .. order)
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.ZIndex = 40
		btn.ClipsDescendants = false
		btn.Parent = scroll

		local rar = "Empty"
		if w then
			local def = WeaponConfig.Get(w.id)
			rar = (def and def.rarity) or "Common"
		end
		btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
		btn.ScaleType = Enum.ScaleType.Fit

		if rar == "Limited" then
			local body, rim = InventoryAssetConfig.GetLimitedLayers()
			btn.Image = body
			local rimImg = Instance.new("ImageLabel")
			rimImg.Name = "Rim"
			rimImg.BackgroundTransparency = 1
			rimImg.Image = rim
			rimImg.ScaleType = Enum.ScaleType.Fit
			rimImg.Size = UDim2.fromScale(1, 1)
			rimImg.ZIndex = 41
			rimImg.Parent = btn
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 220)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 220, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 100)),
			})
			g.Parent = rimImg
			task.spawn(function()
				while rimImg.Parent do
					for rot = 0, 359, 6 do
						if not rimImg.Parent then
							return
						end
						g.Rotation = rot
						task.wait(0.03)
					end
				end
			end)
		end

		if w then
			local host = Instance.new("Frame")
			host.Name = "IconHost"
			host.BackgroundTransparency = 1
			host.Size = UDim2.fromScale(0.72, 0.72)
			host.Position = UDim2.fromScale(0.5, 0.5)
			host.AnchorPoint = Vector2.new(0.5, 0.5)
			host.ZIndex = 42
			host.Active = false
			host.Parent = btn

			local used = false
			pcall(function()
				used = WeaponModels.TryFillInventoryIcon(host, w.id, 44) == true
			end)
			if not used and IconConfig.HasWeaponImage(w.id) then
				local ic = Instance.new("ImageLabel")
				ic.BackgroundTransparency = 1
				ic.Size = UDim2.fromScale(1, 1)
				ic.Image = IconConfig.GetWeaponImage(w.id)
				ic.ScaleType = Enum.ScaleType.Fit
				ic.ZIndex = 42
				ic.Parent = host
			end

			if profile.equippedMain == w.uid or profile.equippedOffhand == w.uid then
				local mark = Instance.new("Frame")
				mark.Size = UDim2.fromOffset(10, 10)
				mark.Position = UDim2.fromOffset(6, 6)
				mark.BackgroundColor3 = Rarity.Of(rar)
				mark.BorderSizePixel = 0
				mark.ZIndex = 45
				mark.Parent = btn
				UIKit.Corner(mark, 99)
			end

			local def = WeaponConfig.Get(w.id)
			local name = (def and def.name) or WeaponConfig.GetDisplayName(w.id)
			local mult = (def and def.powerMult) or 1
			local sellP = (def and def.sellPrice) or 5
			local lv = w.level or 1

			local sc = Instance.new("UIScale")
			sc.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = HOVER_SCALE }):Play()
				local eq: string? = nil
				if profile.equippedMain == w.uid then
					eq = "EQUIPPED MAIN"
				elseif profile.equippedOffhand == w.uid then
					eq = "EQUIPPED OFFHAND"
				end
				showTip(name, rar, mult, sellP, lv, eq)
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
				hideTip()
			end)
			btn.MouseButton1Click:Connect(function()
				Net.EquipWeapon(w.uid, "main")
				args.onRefresh()
			end)
		end
	end

	for i, w in ipairs(weapons) do
		makeSlot(i, w)
	end
	-- fill empty slots to at least 2 full rows (12) or inventory count
	local fillTo = math.max(12, math.ceil(math.max(#weapons, 1) / GRID_COLS) * GRID_COLS)
	fillTo = math.min(fillTo, 48)
	for i = #weapons + 1, fillTo do
		makeSlot(i, nil)
	end

	---------------------------------------------------------------- bottom tab rail (absolute Figma coords)
	for _, def in ipairs(FIGMA_TABS) do
		local b = placeButton(root, def.id .. "Tab", def.key, def.box, 55, function()
			if def.id == "weapons" then
				return
			end
			if def.id == "settings" then
				-- no settings panel yet — keep on weapons
				return
			end
			args.onTab(def.id)
		end)
		if def.id == "weapons" then
			local sc = b:FindFirstChildOfClass("UIScale")
			if sc then
				sc.Scale = 1.08
			end
			b.ImageTransparency = 0
		else
			b.ImageTransparency = 0.12
		end
	end
end

return InventoryWeaponsLayout
