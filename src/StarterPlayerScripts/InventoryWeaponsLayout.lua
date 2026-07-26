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
local ASPECT = 1.4393 -- 11014/7652
local HOVER_SCALE = 1.06
local GRID_COLS = 6

-- Figma fractions (x,y,w,h) relative to layout group
local L = {
	MAINBACKGROUD = { 0.07839, 0.05548, 0.92161, 0.81034 },
	INVENTORYWEAPONcard = { 0.00835, 0.00000, 0.32424, 0.15967 },
	BTN_Close = { 0.94692, 0.07580, 0.04181, 0.06154 },
	TitleNickPlate = { 0.77240, 0.07580, 0.16026, 0.04286 },
	Divider = { 0.30962, 0.08181, 0.65373, 0.04000 }, -- height trimmed (art is tall with transparency)
	BG_WeaponGrid = { 0.29164, 0.13735, 0.68996, 0.69941 },
	EQUIPMENTbackground = { 0.09071, 0.14153, 0.18259, 0.42707 },
	EquipTitlePlate = { 0.13320, 0.16401, 0.09752, 0.02862 },
	MAINswordCARD = { 0.11331, 0.19262, 0.06864, 0.09880 },
	SECONDswordCARD = { 0.18196, 0.19262, 0.06864, 0.09880 },
	PETcard1 = { 0.10823, 0.29143, 0.03686, 0.05306 },
	PETcard2 = { 0.14509, 0.29143, 0.03686, 0.05306 },
	PETcard3 = { 0.18196, 0.29143, 0.03686, 0.05306 },
	PETcard4 = { 0.21882, 0.29143, 0.03686, 0.05306 },
	PETcard5 = { 0.10823, 0.34448, 0.03686, 0.05306 },
	PETcard6 = { 0.14509, 0.34448, 0.03686, 0.05306 },
	PETcard7 = { 0.18196, 0.34448, 0.03686, 0.05306 },
	PETcard8 = { 0.21882, 0.34448, 0.03686, 0.05306 },
	RELICcard1 = { 0.10823, 0.39754, 0.05021, 0.07227 },
	RELICcard2 = { 0.15844, 0.39754, 0.05021, 0.07227 },
	RELICcard3 = { 0.20865, 0.39754, 0.05021, 0.07227 },
	AURAcard = { 0.15844, 0.46981, 0.05021, 0.07227 },
	EQUIPbestFORdamage = { 0.12058, 0.56194, 0.12339, 0.05920 },
	EQUIPbestFORpower = { 0.11994, 0.62493, 0.12339, 0.05920 },
	STARSdecoration = { 0.12866, 0.56913, 0.10687, 0.04312 },
	STARTSdecoration = { 0.12820, 0.63290, 0.10687, 0.04312 },
	PRESETSbutton = { 0.11395, 0.68805, 0.13601, 0.04182 },
	PRESETcard1 = { 0.10750, 0.72607, 0.03659, 0.05266 },
	PRESETcard2 = { 0.14291, 0.72607, 0.03659, 0.05266 },
	PRESETcard3 = { 0.17950, 0.72607, 0.03659, 0.05266 },
	PRESETcard4 = { 0.21610, 0.72607, 0.03659, 0.05266 },
	SELLbutton = { 0.09534, 0.79024, 0.08898, 0.04273 },
	SELLallUNLOCKED = { 0.18432, 0.79024, 0.08898, 0.04273 },
	MOUSEBINDScard = { 0.00000, 0.70009, 0.07999, 0.15799 },
	WEAPONSBUTTON = { 0.12902, 0.87520, 0.08626, 0.12415 },
	PETCBUTTON = { 0.22136, 0.87520, 0.08626, 0.12415 },
	AURABUTTON = { 0.31370, 0.87585, 0.08626, 0.12415 },
	RELICBUTTON = { 0.40604, 0.87585, 0.08626, 0.12415 },
	CONSUMABLESBUTTON = { 0.49838, 0.87585, 0.08626, 0.12415 },
	SHOPBUTTON = { 0.59072, 0.87520, 0.08626, 0.12415 },
	PROFILEBUTTON = { 0.68215, 0.87520, 0.08626, 0.12415 },
	SETTINGSBUTTON = { 0.81590, 0.87520, 0.08626, 0.12415 },
	-- Tooltip size (position follows mouse)
	TOOLTIPshell = { 0, 0, 0.23979, 0.20765 },
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
	placeImage(root, "Divider", "Divider_3_Minimal_1", L.Divider, 40, Enum.ScaleType.Stretch)

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

	-- Equip best buttons (+ optional star decorations under/over)
	placeImage(root, "STARSdecoration", "STARSdecoration", L.STARSdecoration, 37)
	placeImage(root, "STARTSdecoration", "STARTSdecoration", L.STARTSdecoration, 37)

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

	placeImage(root, "MOUSEBINDScard", "MOUSEBINDScard", L.MOUSEBINDScard, 45)

	---------------------------------------------------------------- weapon grid
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

	-- Figma slot cell ≈ 0.1579 of grid width; 6 columns, pad ~0.026
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Slots"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(0.948, 0.96)
	scroll.Position = UDim2.fromScale(0.026, 0.02)
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 140, 255)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 36
	scroll.Parent = gridHost

	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = GRID_COLS
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	-- Cell padding: Figma mock is nearly flush; use slight gap for hover
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.Parent = scroll

	local function relayout()
		local w = scroll.AbsoluteSize.X
		if w < 40 then
			return
		end
		-- 6 columns, match Figma slot aspect (square)
		local pad = 8
		local cell = math.floor((w - pad * (GRID_COLS - 1)) / GRID_COLS)
		cell = math.clamp(cell, 52, 140)
		grid.CellSize = UDim2.fromOffset(cell, cell)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)

	---------------------------------------------------------------- tooltip (mouse-follow + TOOLTIPshell)
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Size = UDim2.fromScale(L.TOOLTIPshell[3], L.TOOLTIPshell[4])
	tip.ZIndex = 200
	tip.Parent = root

	local tipBg = Instance.new("ImageLabel")
	tipBg.Name = "Shell"
	tipBg.BackgroundTransparency = 1
	tipBg.Image = art("TOOLTIPshell")
	tipBg.ScaleType = Enum.ScaleType.Stretch
	tipBg.Size = UDim2.fromScale(1, 1)
	tipBg.ZIndex = 200
	tipBg.Parent = tip

	UIKit.Pad(tip, 12)
	local tipList = Instance.new("UIListLayout")
	tipList.SortOrder = Enum.SortOrder.LayoutOrder
	tipList.Padding = UDim.new(0, 2)
	tipList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tipList.VerticalAlignment = Enum.VerticalAlignment.Center
	tipList.Parent = tip

	local function clearTip()
		for _, c in tip:GetChildren() do
			if c.Name == "Shell" then
				continue
			end
			if c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UISizeConstraint") then
				continue
			end
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
		local tipW = math.max(tip.AbsoluteSize.X, 120)
		local tipH = math.max(tip.AbsoluteSize.Y, 80)
		local EDGE = 14
		local screenX = mx + EDGE
		if screenX + tipW > parentAbs.X + parentSz.X - 4 then
			screenX = mx - EDGE - tipW
		end
		local screenY = my + 6
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
			tipText(tip, order, equippedLine, "gold", 22)
			order += 1
		end
		tipText(tip, order, title, "purple", 28)
		order += 1
		if rarity then
			tipText(tip, order, rarity, "gray", 20)
			order += 1
		end
		tipText(tip, order, string.format("POWER: ×%.2f", power), "purple", 20)
		order += 1
		tipText(tip, order, string.format("SELL PRICE: %d", sell), "gold", 20)
		order += 1
		tipText(tip, order, string.format("LEVEL: %d", level), "gray", 20)
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
