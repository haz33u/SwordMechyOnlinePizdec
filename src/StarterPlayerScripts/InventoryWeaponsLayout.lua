--!strict
--[[
	Figma WEAPON INVENTORY LAYOUT (node ~5193:9879) — first page only.

	Zones:
	  MAINBACKGROUD shell
	  Left EQUIPMENTbackground = equipped loadout (2 swords, 8 pets, 3 relics, 1 aura)
	  Center BG_WeaponGrid = inventory slots (rarity PNG frame + 3D viewport)
	  TOOLTIPshell = mouse-follow tooltip (left/right flip)
	  Bottom tab rail + header card + action buttons

	Sell mode / lock / merge: later (after UI pass).
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
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local RelicConfig = require(Shared.Config.RelicConfig)
local InventoryAssetConfig = require(Shared.Config.InventoryAssetConfig)
local IconConfig = require(Shared.Config.IconConfig)

local InventoryWeaponsLayout = {}

local ROOT_NAME = "FigmaWeaponsRoot"
local HOVER_SCALE = 1.06
local SLOT_GAP = 10
local GRID_COLS = 6
local PRESETS_WM_BG = "rbxassetid://125069362428324"
local TIP_W, TIP_H = 300, 178

local FIGMA_TABS = {
	{ id = "weapons", key = "WEAPONSBUTTON" },
	{ id = "pets", key = "PETCBUTTON" },
	{ id = "auras", key = "AURABUTTON" },
	{ id = "relics", key = "RELICBUTTON" },
	{ id = "items", key = "CONSUMABLESBUTTON" },
	{ id = "shop", key = "SHOPBUTTON" },
	{ id = "profile", key = "PROFILEBUTTON" },
	{ id = "settings", key = "SETTINGSBUTTON" },
}

local function art(key: string): string
	return InventoryAssetConfig.Get(key)
end

local function img(parent: Instance, name: string, assetKey: string, size: UDim2, pos: UDim2?, z: number?): ImageLabel
	local i = Instance.new("ImageLabel")
	i.Name = name
	i.BackgroundTransparency = 1
	i.BorderSizePixel = 0
	i.Image = art(assetKey)
	i.ScaleType = Enum.ScaleType.Fit
	i.Size = size
	if pos then
		i.Position = pos
	end
	i.ZIndex = z or 10
	i.Parent = parent
	return i
end

local function tipText(parent: Instance, order: number, text: string, grad: string?, h: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = "T" .. order
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -16, 0, h or 26)
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

local function tipLine(parent: Instance, order: number): Frame
	local f = Instance.new("Frame")
	f.Name = "Line" .. order
	f.BackgroundColor3 = Color3.fromRGB(207, 178, 255)
	f.BackgroundTransparency = 0.3
	f.BorderSizePixel = 0
	f.Size = UDim2.new(0.72, 0, 0, 2)
	f.LayoutOrder = order
	f.ZIndex = (parent :: GuiObject).ZIndex + 2
	f.Parent = parent
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = f
	return f
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
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 0.96)
	root.ClipsDescendants = false
	root.ZIndex = 30
	root.Parent = parent

	-- Lock the ref frame aspect (22039x15305 = 1.44) so all fractions match the mock 1:1
	local rootAspect = Instance.new("UIAspectRatioConstraint")
	rootAspect.AspectRatio = 1.44
	rootAspect.AspectType = Enum.AspectType.FitWithinMaxSize
	rootAspect.DominantAxis = Enum.DominantAxis.Width
	rootAspect.Parent = root

	-- Full-bleed shell (no solid backdrop — kill the gray box)
	local bg = Instance.new("ImageLabel")
	bg.Name = "MAINBACKGROUD"
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Image = art("MAINBACKGROUD")
	bg.ScaleType = Enum.ScaleType.Stretch
	bg.Position = UDim2.fromScale(0.066, 0.046)
	bg.Size = UDim2.fromScale(0.928, 0.826)
	bg.ZIndex = 30
	bg.Parent = root

	-- Close
	local close = Instance.new("ImageButton")
	close.Name = "Close"
	close.BackgroundTransparency = 1
	close.Image = art("BTN_Close_3")
	close.ScaleType = Enum.ScaleType.Fit
	close.Size = UDim2.fromScale(0.038, 0.058)
	close.Position = UDim2.fromScale(0.952, 0.073)
	close.ZIndex = 80
	close.Parent = root
	close.MouseButton1Click:Connect(args.onClose)

	-- Header wordmark
	img(root, "INVENTORYWEAPONcard", "INVENTORYWEAPONcard", UDim2.fromScale(0.315, 0.13), UDim2.fromScale(0.008, 0.025), 45)

	-- Divider under the top strip (stretched full width like ref)
	local divider = Instance.new("ImageLabel")
	divider.Name = "Divider"
	divider.BackgroundTransparency = 1
	divider.Image = art("Divider_3_Minimal_1")
	divider.ScaleType = Enum.ScaleType.Stretch
	divider.Size = UDim2.fromScale(0.60, 0.02)
	divider.Position = UDim2.fromScale(0.30, 0.117)
	divider.ZIndex = 40
	divider.Parent = root

	-- Title / nick plate (top-right): TITLE | NICKNAME on btn_neutral plate
	local nickPlate = Instance.new("ImageLabel")
	nickPlate.Name = "TitleNickPlate"
	nickPlate.BackgroundTransparency = 1
	nickPlate.Image = art("btn_neutral_2_1")
	nickPlate.ScaleType = Enum.ScaleType.Fit
	nickPlate.Size = UDim2.fromScale(0.145, 0.036)
	nickPlate.Position = UDim2.fromScale(0.774, 0.079)
	nickPlate.ZIndex = 40
	nickPlate.Parent = root

	local nickStrip = Instance.new("TextLabel")
	nickStrip.Name = "NickStrip"
	nickStrip.BackgroundTransparency = 1
	nickStrip.Size = UDim2.fromScale(0.84, 0.56)
	nickStrip.Position = UDim2.fromScale(0.5, 0.5)
	nickStrip.AnchorPoint = Vector2.new(0.5, 0.5)
	local titleTxt = (profile and (profile.equippedTitle or profile.title)) or "TITLE"
	local nickTxt = (Players.LocalPlayer and Players.LocalPlayer.Name) or "NICKNAME"
	nickStrip.Text = string.upper(tostring(titleTxt) .. " | " .. nickTxt)
	nickStrip.TextScaled = true
	nickStrip.ZIndex = 41
	nickStrip.Parent = nickPlate
	UIKit.StyleText(nickStrip, "gold", 2)

	----------------------------------------------------------------
	-- LEFT: Equipment loadout (Panel_EquipInfo / EQUIPMENTbackground)
	----------------------------------------------------------------
	local equip = Instance.new("Frame")
	equip.Name = "Panel_EquipInfo"
	equip.BackgroundTransparency = 1
	equip.Size = UDim2.fromScale(0.164, 0.40)
	equip.Position = UDim2.fromScale(0.103, 0.147)
	equip.ZIndex = 35
	equip.Parent = root

	local equipBg = Instance.new("ImageLabel")
	equipBg.Name = "EQUIPMENTbackground"
	equipBg.BackgroundTransparency = 1
	equipBg.Image = art("EQUIPMENTbackground")
	equipBg.ScaleType = Enum.ScaleType.Stretch
	equipBg.Size = UDim2.fromScale(1, 1)
	equipBg.ZIndex = 35
	equipBg.Parent = equip

	local equipTitle = Instance.new("TextLabel")
	equipTitle.BackgroundTransparency = 1
	equipTitle.Size = UDim2.fromScale(0.37, 0.05)
	equipTitle.Position = UDim2.fromScale(0.315, 0.02)
	equipTitle.Text = "EQUIPMENT"
	equipTitle.ZIndex = 36
	equipTitle.Parent = equip
	UIKit.StyleText(equipTitle, "purple", 3)

	-- 2 swords
	local swordRow = Instance.new("Frame")
	swordRow.Name = "Swords"
	swordRow.BackgroundTransparency = 1
	swordRow.Size = UDim2.fromScale(1, 0.20)
	swordRow.Position = UDim2.fromScale(0, 0.11)
	swordRow.ZIndex = 36
	swordRow.Parent = equip
	UIKit.List(swordRow, 8, true, Enum.HorizontalAlignment.Center)

	local function swordCard(assetKey: string, weaponUid: string?, order: number)
		local holder = Instance.new("Frame")
		holder.Name = assetKey
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromScale(0.43, 1)
		holder.LayoutOrder = order
		holder.ZIndex = 37
		holder.Parent = swordRow

		local plate = Instance.new("ImageLabel")
		plate.Name = "Plate"
		plate.BackgroundTransparency = 1
		plate.Image = art(assetKey)
		plate.ScaleType = Enum.ScaleType.Fit
		plate.Size = UDim2.fromScale(1, 1)
		plate.ZIndex = 37
		plate.Parent = holder

		local vpHost = Instance.new("Frame")
		vpHost.Name = "VpHost"
		vpHost.BackgroundTransparency = 1
		vpHost.Size = UDim2.fromScale(0.7, 0.7)
		vpHost.Position = UDim2.fromScale(0.5, 0.48)
		vpHost.AnchorPoint = Vector2.new(0.5, 0.5)
		vpHost.ZIndex = 38
		vpHost.Parent = holder

		if weaponUid then
			local w = nil
			for _, ww in ipairs(profile.weapons or {}) do
				if ww.uid == weaponUid then
					w = ww
					break
				end
			end
			if w then
				pcall(function()
					WeaponModels.TryFillInventoryIcon(vpHost, w.id, 48)
				end)
			end
		end
	end

	swordCard("MAINswordCARD", profile.equippedMain, 1)
	swordCard("SECONDswordCARD", profile.equippedOffhand, 2)

	-- 8 pets (2x4)
	local petsGrid = Instance.new("Frame")
	petsGrid.Name = "Pets"
	petsGrid.BackgroundTransparency = 1
	petsGrid.Size = UDim2.fromScale(1, 0.205)
	petsGrid.Position = UDim2.fromScale(0, 0.36)
	petsGrid.ZIndex = 36
	petsGrid.Parent = equip
	local petLayout = Instance.new("UIGridLayout")
	petLayout.CellSize = UDim2.fromScale(0.175, 0.44)
	petLayout.CellPadding = UDim2.fromScale(0.016, 0.06)
	petLayout.SortOrder = Enum.SortOrder.LayoutOrder
	petLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	petLayout.Parent = petsGrid

	local team = profile.petTeam or {}
	local petByUid: { [string]: any } = {}
	for _, p in ipairs(profile.pets or {}) do
		petByUid[p.uid] = p
	end
	for i = 1, 8 do
		local key = "PETcard" .. tostring(i)
		local cell = Instance.new("ImageLabel")
		cell.Name = key
		cell.BackgroundTransparency = 1
		cell.Image = art(key)
		cell.ScaleType = Enum.ScaleType.Fit
		cell.LayoutOrder = i
		cell.ZIndex = 37
		cell.Parent = petsGrid
		local uid = team[i]
		if uid and petByUid[uid] then
			local host = Instance.new("Frame")
			host.BackgroundTransparency = 1
			host.Size = UDim2.fromScale(0.75, 0.75)
			host.Position = UDim2.fromScale(0.5, 0.5)
			host.AnchorPoint = Vector2.new(0.5, 0.5)
			host.ZIndex = 38
			host.Parent = cell
			pcall(function()
				PetVisual.TryFillInventoryIcon(host, petByUid[uid].id, 32)
			end)
		end
	end

	-- 3 relics + 1 aura
	local relicRow = Instance.new("Frame")
	relicRow.Name = "RelicsAura"
	relicRow.BackgroundTransparency = 1
	relicRow.Size = UDim2.fromScale(1, 0.135)
	relicRow.Position = UDim2.fromScale(0, 0.63)
	relicRow.ZIndex = 36
	relicRow.Parent = equip
	UIKit.List(relicRow, 6, true, Enum.HorizontalAlignment.Center)

	local equippedRelics = profile.equippedRelics or profile.relicsEquipped or {}
	-- support array of uids or map
	local relicUids: { string } = {}
	if type(equippedRelics) == "table" then
		for k, v in pairs(equippedRelics) do
			if type(v) == "string" then
				table.insert(relicUids, v)
			elseif type(k) == "number" and type(v) == "string" then
				table.insert(relicUids, v)
			end
		end
	end
	for i = 1, 3 do
		local cell = Instance.new("ImageLabel")
		cell.Name = "RELICcard" .. i
		cell.BackgroundTransparency = 1
		cell.Image = art("RELICcard" .. i)
		cell.ScaleType = Enum.ScaleType.Fit
		cell.Size = UDim2.fromScale(0.24, 1)
		cell.LayoutOrder = i
		cell.ZIndex = 37
		cell.Parent = relicRow
	end
	do
		local cell = Instance.new("ImageLabel")
		cell.Name = "AURAcard"
		cell.BackgroundTransparency = 1
		-- reuse PETcard style frame if no dedicated empty; use AURAScard crop via generic
		cell.Image = art("RELICcard1")
		cell.ScaleType = Enum.ScaleType.Fit
		cell.AnchorPoint = Vector2.new(0.5, 0)
		cell.Position = UDim2.fromScale(0.5, 0.79)
		cell.Size = UDim2.fromScale(0.24, 0.15)
		cell.ZIndex = 37
		cell.Parent = equip
		if profile.equippedAura then
			local host = Instance.new("Frame")
			host.BackgroundTransparency = 1
			host.Size = UDim2.fromScale(0.8, 0.8)
			host.Position = UDim2.fromScale(0.5, 0.5)
			host.AnchorPoint = Vector2.new(0.5, 0.5)
			host.ZIndex = 38
			host.Parent = cell
			pcall(function()
				AuraVisual.TryFillInventoryIcon(host, profile.equippedAura, 36)
			end)
		end
	end

	-- Equip best + sell buttons (art only for now — logic later for sell mode)
	local actCol = Instance.new("Frame")
	actCol.Name = "Actions"
	actCol.BackgroundTransparency = 1
	actCol.Size = UDim2.fromScale(0.094, 0.108)
	actCol.Position = UDim2.fromScale(0.152, 0.557)
	actCol.ZIndex = 40
	actCol.Parent = root
	UIKit.List(actCol, 6, false, Enum.HorizontalAlignment.Center)

	local function imgBtn(parent: Instance, key: string, order: number, onClick: () -> (), size: UDim2?)
		local b = Instance.new("ImageButton")
		b.Name = key
		b.BackgroundTransparency = 1
		b.Image = art(key)
		b.ScaleType = Enum.ScaleType.Fit
		b.Size = size or UDim2.fromScale(1, 0.44)
		b.LayoutOrder = order
		b.ZIndex = 37
		b.Parent = parent
		local sc = Instance.new("UIScale")
		sc.Parent = b
		b.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1.05 }):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
		end)
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	imgBtn(actCol, "EQUIPbestFORpowerBUTTON", 2, function()
		local ranked = {}
		for _, w in ipairs(profile.weapons or {}) do
			local d = WeaponConfig.Get(w.id)
			table.insert(ranked, { uid = w.uid, power = (d and d.powerMult) or 0, level = w.level or 1 })
		end
		table.sort(ranked, function(a, b)
			if a.power ~= b.power then
				return a.power > b.power
			end
			return a.level > b.level
		end)
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		if ranked[2] then
			Net.EquipWeapon(ranked[2].uid, "offhand")
		end
		args.onRefresh()
	end)
	imgBtn(actCol, "EQUIPbestFORdamageBUTTON", 1, function()
		-- same ranking for now (damage ≈ power in this game)
		local ranked = {}
		for _, w in ipairs(profile.weapons or {}) do
			local d = WeaponConfig.Get(w.id)
			table.insert(ranked, { uid = w.uid, power = (d and d.powerMult) or 0, level = w.level or 1 })
		end
		table.sort(ranked, function(a, b)
			return a.power > b.power
		end)
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		args.onRefresh()
	end)

	local sellRow = Instance.new("Frame")
	sellRow.Name = "SellRow"
	sellRow.BackgroundTransparency = 1
	sellRow.Size = UDim2.fromScale(0.16, 0.038)
	sellRow.Position = UDim2.fromScale(0.107, 0.796)
	sellRow.ZIndex = 40
	sellRow.Parent = root
	UIKit.List(sellRow, 6, true, Enum.HorizontalAlignment.Center)
	imgBtn(sellRow, "SELLbutton", 1, function()
		-- stub: sell selected later
	end, UDim2.fromScale(0.48, 1))
	imgBtn(sellRow, "SELLallUNLOCKEDbutton", 2, function()
		Net.SellAllWeapons()
		args.onRefresh()
	end, UDim2.fromScale(0.48, 1))

	----------------------------------------------------------------
	-- CENTER: weapon grid
	----------------------------------------------------------------
	local gridHost = Instance.new("Frame")
	gridHost.Name = "BG_WeaponGrid"
	gridHost.BackgroundTransparency = 1
	gridHost.Size = UDim2.fromScale(0.665, 0.71)
	gridHost.Position = UDim2.fromScale(0.302, 0.145)
	gridHost.ZIndex = 35
	gridHost.Parent = root

	local gridBg = Instance.new("ImageLabel")
	gridBg.Name = "GridBg"
	gridBg.BackgroundTransparency = 1
	gridBg.Image = art("BG_WeaponGrid")
	gridBg.ScaleType = Enum.ScaleType.Stretch
	gridBg.Size = UDim2.fromScale(1, 1)
	gridBg.ZIndex = 35
	gridBg.ImageTransparency = 0.3
	gridBg.Parent = gridHost

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Slots"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(0.96, 0.94)
	scroll.Position = UDim2.fromScale(0.02, 0.03)
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 36
	scroll.Parent = gridHost
	UIKit.Pad(scroll, 8)
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(SLOT_GAP, SLOT_GAP)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = GRID_COLS
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = scroll

	local function relayout()
		local w = scroll.AbsoluteSize.X
		if w < 40 then
			return
		end
		local pad = 16
		local inner = w - pad - scroll.ScrollBarThickness
		local cell = math.floor((inner - SLOT_GAP * (GRID_COLS - 1)) / GRID_COLS)
		cell = math.clamp(cell, 64, 220)
		grid.CellSize = UDim2.fromOffset(cell, cell)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)

	----------------------------------------------------------------
	-- TOOLTIP (mouse follow, TOOLTIPshell, fixed size — text ON the shell)
	----------------------------------------------------------------
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Size = UDim2.fromOffset(TIP_W, TIP_H)
	tip.ZIndex = 200
	tip.Parent = root

	local tipBg = Instance.new("ImageLabel")
	tipBg.Name = "Shell"
	tipBg.BackgroundTransparency = 1
	tipBg.Image = art("TOOLTIPshell")
	tipBg.ScaleType = Enum.ScaleType.Fit
	tipBg.Size = UDim2.fromScale(1, 1)
	tipBg.ZIndex = 200
	tipBg.Parent = tip

	local tipBody = Instance.new("Frame")
	tipBody.Name = "Body"
	tipBody.BackgroundTransparency = 1
	tipBody.Size = UDim2.new(1, -40, 1, -40)
	tipBody.Position = UDim2.fromScale(0.5, 0.5)
	tipBody.AnchorPoint = Vector2.new(0.5, 0.5)
	tipBody.ZIndex = 201
	tipBody.Parent = tip
	local tipList = Instance.new("UIListLayout")
	tipList.SortOrder = Enum.SortOrder.LayoutOrder
	tipList.Padding = UDim.new(0, 4)
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
		if not tip.Visible then
			return
		end
		local inset = GuiService:GetGuiInset()
		local mouse = UserInputService:GetMouseLocation()
		local mx = mouse.X - inset.X
		local my = mouse.Y - inset.Y
		local parentAbs = root.AbsolutePosition
		local parentSz = root.AbsoluteSize
		local tipW = TIP_W
		local tipH = TIP_H
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
		tip.Position = UDim2.fromOffset(math.floor(screenX - parentAbs.X + 0.5), math.floor(screenY - parentAbs.Y + 0.5))
	end

	local function showTip(title: string, rarity: string?, power: number, sell: number, level: number, equippedLine: string?)
		clearTip()
		local order = 1
		if equippedLine then
			tipText(tipBody, order, equippedLine, "gold", 20)
			order += 1
		end
		tipText(tipBody, order, title, "purple", 26)
		order += 1
		if rarity then
			tipText(tipBody, order, rarity, "gray", 18)
			order += 1
		end
		tipLine(tipBody, order)
		order += 1
		tipText(tipBody, order, string.format("POWER: ×%.2f", power), "purple", 18)
		order += 1
		tipText(tipBody, order, string.format("SELL PRICE: %d", sell), "gold", 18)
		order += 1
		tipText(tipBody, order, string.format("LEVEL: %d", level), "gray", 18)
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

	----------------------------------------------------------------
	-- Slots
	----------------------------------------------------------------
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

		-- Limited rim layer
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
					for rot = 0, 359, 4 do
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
	local fillTo = math.max(24, #weapons)
	for i = #weapons + 1, fillTo do
		makeSlot(i, nil)
	end

	----------------------------------------------------------------
	-- Presets (wordmark on its own plate + 4 preset cards)
	----------------------------------------------------------------
	local presetWmBg = Instance.new("ImageLabel")
	presetWmBg.Name = "PresetsWmBg"
	presetWmBg.BackgroundTransparency = 1
	presetWmBg.Image = PRESETS_WM_BG
	presetWmBg.ScaleType = Enum.ScaleType.Stretch
	presetWmBg.Size = UDim2.fromScale(0.118, 0.039)
	presetWmBg.Position = UDim2.fromScale(0.136, 0.687)
	presetWmBg.ZIndex = 39
	presetWmBg.Parent = root

	local presetWm = Instance.new("ImageLabel")
	presetWm.Name = "PresetsWordmark"
	presetWm.BackgroundTransparency = 1
	presetWm.Image = art("WORDMARK_presets__click_to_equip_1")
	presetWm.ScaleType = Enum.ScaleType.Fit
	presetWm.Size = UDim2.fromScale(0.098, 0.029)
	presetWm.Position = UDim2.fromScale(0.146, 0.692)
	presetWm.ZIndex = 40
	presetWm.Parent = root

	local presets = Instance.new("Frame")
	presets.Name = "Presets"
	presets.BackgroundTransparency = 1
	presets.Size = UDim2.fromScale(0.126, 0.052)
	presets.Position = UDim2.fromScale(0.134, 0.732)
	presets.ZIndex = 40
	presets.Parent = root
	UIKit.List(presets, 6, true, Enum.HorizontalAlignment.Center)
	for i = 1, 4 do
		local p = Instance.new("ImageLabel")
		p.Name = "PRESETcard" .. i
		p.BackgroundTransparency = 1
		p.Image = art("PRESETcard" .. i)
		p.ScaleType = Enum.ScaleType.Fit
		p.Size = UDim2.fromScale(0.22, 1)
		p.LayoutOrder = i
		p.ZIndex = 41
		p.Parent = presets
	end

	----------------------------------------------------------------
	-- Bottom tab rail (Figma only — no Cases)
	----------------------------------------------------------------
	local tabRail = Instance.new("Frame")
	tabRail.Name = "TabRail"
	tabRail.BackgroundTransparency = 1
	tabRail.Size = UDim2.fromScale(0.84, 0.12)
	tabRail.Position = UDim2.fromScale(0.08, 0.872)
	tabRail.ZIndex = 50
	tabRail.Parent = root
	UIKit.List(tabRail, 8, true, Enum.HorizontalAlignment.Center)

	for tabIndex, def in ipairs(FIGMA_TABS) do
		local b = Instance.new("ImageButton")
		b.Name = def.id
		b.BackgroundTransparency = 1
		b.Image = art(def.key)
		b.ScaleType = Enum.ScaleType.Fit
		b.Size = UDim2.fromScale(0.095, 1)
		b.LayoutOrder = tabIndex * 10
		b.ImageTransparency = if def.id == "weapons" then 0 else 0.25
		b.ZIndex = 51
		b.Parent = tabRail
		local sc = Instance.new("UIScale")
		sc.Scale = if def.id == "weapons" then 1.06 else 1
		sc.Parent = b
		b.MouseButton1Click:Connect(function()
			if def.id == "weapons" then
				return
			end
			if def.id == "settings" then
				-- settings not in old tabs — notify via shop fallback later
				args.onTab("shop")
				return
			end
			args.onTab(def.id)
		end)
	end

	-- Gap before SETTINGS like in the ref
	local tabSpacer = Instance.new("Frame")
	tabSpacer.Name = "Spacer"
	tabSpacer.BackgroundTransparency = 1
	tabSpacer.Size = UDim2.fromScale(0.05, 1)
	tabSpacer.LayoutOrder = 75
	tabSpacer.Parent = tabRail

	-- Binds card (hint only this pass)
	local binds = Instance.new("ImageLabel")
	binds.Name = "MOUSEBINDScard"
	binds.BackgroundTransparency = 1
	binds.Image = art("MOUSEBINDScard")
	binds.ScaleType = Enum.ScaleType.Fit
	binds.Size = UDim2.fromScale(0.08, 0.18)
	binds.Position = UDim2.fromScale(0.0, 0.685)
	binds.ZIndex = 45
	binds.Parent = root
end

return InventoryWeaponsLayout
