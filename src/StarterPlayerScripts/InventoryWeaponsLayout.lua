--!strict
--[[
	WEAPON INVENTORY — rebuilt 1:1 from Figma ref "WEAPON INVENTORY LAYOUT" (11020x7653, aspect 1.44).

	Canvas map (fractions of parent frame, measured from the ref):
	  window (MAINBACKGROUD)  x 0.079..0.986  y 0.056..0.864
	  header card             top-left, overlaps window corner, slight tilt
	  bottom tab rail         y 0.875..0.998 (OUTSIDE the window, like the ref)
	  MOUSEBINDScard          hangs off the left edge, outside the window

	Card structure (all grid cards, per spec):
	  ImageButton "Card" (transparent hit area)
	  ├─ ImageLabel "Body"  — rarity frame PNG (Limited -> Slot_Limited_Body)
	  ├─ ImageLabel "Rim"   — Limited only, Slot_Limited_Rim + animated UIGradient
	  └─ Frame "Content"    — weapon icon, equip mark etc.

	Tooltip (TOOLTIPshell, mouse-follow, left/right flip):
	  [EQUIPPED MAIN / EQUIPPED OFFHAND]  (only when equipped)
	  NAME
	  RARITY (colored via Rarity.Of)
	  POWER / SELL PRICE / LEVEL

	NOTE: add to InventoryAssetConfig.lua:
	  EQUIPMENTbackground = "rbxassetid://122812087743674",
	(this file falls back to the raw id until the key exists)
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
local HOVER_SCALE = 1.06
local SLOT_GAP = 14 -- ref: gaps noticeably wider than old build
local GRID_COLS = 6
local SHIMMER_SPEED = 0.35
local OUTLINE = Color3.fromRGB(10, 8, 36)

-- until EQUIPMENTbackground lands in InventoryAssetConfig.lua
local EQUIPMENT_BG_FALLBACK = "rbxassetid://122812087743674"

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

-- house rainbow, first stop == last stop (no seam)
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(95, 216, 245)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(127, 111, 255)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(176, 92, 255)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 90, 214)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 184, 79)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(95, 216, 245)),
})

local function art(key: string): string
	return InventoryAssetConfig.Get(key)
end

local function artOr(key: string, fallback: string): string
	local ok, v = pcall(InventoryAssetConfig.Get, key)
	if ok and type(v) == "string" and v ~= "" and v ~= "rbxassetid://0" then
		return v
	end
	return fallback
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
	i.ZIndex = z or 40
	i.Parent = parent
	return i
end

local function hoverify(b: GuiButton, scale: number?)
	local sc = Instance.new("UIScale")
	sc.Parent = b
	b.MouseEnter:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = scale or 1.05 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	return sc
end

local function imgBtn(parent: Instance, key: string, size: UDim2, pos: UDim2?, z: number?, onClick: (() -> ())?): ImageButton
	local b = Instance.new("ImageButton")
	b.Name = key
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Image = art(key)
	b.ScaleType = Enum.ScaleType.Fit
	b.Size = size
	if pos then
		b.Position = pos
	end
	b.ZIndex = z or 40
	b.Parent = parent
	hoverify(b)
	if onClick then
		b.MouseButton1Click:Connect(onClick)
	end
	return b
end

-- canonical Limited shimmer: horizontal offset sweep, NOT rotation
local function attachShimmer(rim: ImageLabel)
	local g = Instance.new("UIGradient")
	g.Rotation = 20
	g.Color = RAINBOW
	g.Parent = rim
	local t = 0
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt: number)
		if not rim.Parent then
			conn:Disconnect()
			return
		end
		t = (t + dt * SHIMMER_SPEED) % 1
		g.Offset = Vector2.new(t * 2 - 1, 0)
	end)
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

-- rarity line colored via Rarity.Of (Luckiest Guy + dark stroke, house style)
local function tipRarity(parent: Instance, order: number, rar: string): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = "T" .. order
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -16, 0, 22)
	l.LayoutOrder = order
	l.Text = string.upper(rar)
	l.Font = Enum.Font.LuckiestGuy
	l.TextScaled = true
	l.TextColor3 = Rarity.Of(rar)
	l.ZIndex = (parent :: GuiObject).ZIndex + 2
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = OUTLINE
	s.Thickness = 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = l
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
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = 30
	root.Parent = parent

	----------------------------------------------------------------
	-- WINDOW (not full-bleed! header, tabs and binds live outside)
	----------------------------------------------------------------
	local window = Instance.new("ImageLabel")
	window.Name = "Window"
	window.BackgroundTransparency = 1
	window.BorderSizePixel = 0
	window.Image = art("MAINBACKGROUD")
	window.ScaleType = Enum.ScaleType.Stretch
	window.Position = UDim2.fromScale(0.079, 0.056)
	window.Size = UDim2.fromScale(0.907, 0.808)
	window.ZIndex = 30
	window.Parent = root

	-- Header card, overlaps the window's top-left corner, slight tilt (as in ref)
	local header = img(root, "INVENTORYWEAPONcard", "INVENTORYWEAPONcard", UDim2.fromScale(0.315, 0.125), UDim2.fromScale(0.002, 0.008), 60)
	header.Rotation = -2

	-- TITLE | NICK plate (btn_neutral_2_1 behind dynamic text)
	local nickPlate = Instance.new("ImageLabel")
	nickPlate.Name = "TitleNick"
	nickPlate.BackgroundTransparency = 1
	nickPlate.Image = art("btn_neutral_2_1")
	nickPlate.ScaleType = Enum.ScaleType.Fit
	nickPlate.Position = UDim2.fromScale(0.75, 0.025)
	nickPlate.Size = UDim2.fromScale(0.19, 0.055)
	nickPlate.ZIndex = 40
	nickPlate.Parent = window

	local nickText = Instance.new("TextLabel")
	nickText.Name = "Text"
	nickText.BackgroundTransparency = 1
	nickText.AnchorPoint = Vector2.new(0.5, 0.5)
	nickText.Position = UDim2.fromScale(0.5, 0.5)
	nickText.Size = UDim2.fromScale(0.82, 0.6)
	local nick = (Players.LocalPlayer and Players.LocalPlayer.Name) or "PLAYER"
	local title = (profile and (profile.equippedTitle or profile.title)) or nil
	nickText.Text = string.upper(if title and title ~= "" then (tostring(title) .. " | " .. nick) else nick)
	nickText.ZIndex = 41
	nickText.Parent = nickPlate
	UIKit.StyleText(nickText, "gray", 2)

	-- Close (red X, top-right corner of the window)
	local close = Instance.new("ImageButton")
	close.Name = "Close"
	close.BackgroundTransparency = 1
	close.AutoButtonColor = false
	close.Image = art("BTN_Close_3")
	close.ScaleType = Enum.ScaleType.Fit
	close.Position = UDim2.fromScale(0.952, 0.022)
	close.Size = UDim2.fromScale(0.045, 0.075)
	close.ZIndex = 80
	close.Parent = window
	hoverify(close, 1.08)
	close.MouseButton1Click:Connect(args.onClose)

	-- Divider with the glowing dot, under the title row
	img(window, "Divider", "Divider_3_Minimal_1", UDim2.fromScale(0.69, 0.04), UDim2.fromScale(0.265, 0.068), 36)

	----------------------------------------------------------------
	-- LEFT: EQUIPMENT panel (EQUIPMENTbackground asset)
	----------------------------------------------------------------
	local equip = Instance.new("ImageLabel")
	equip.Name = "Panel_EquipInfo"
	equip.BackgroundTransparency = 1
	equip.Image = artOr("EQUIPMENTbackground", EQUIPMENT_BG_FALLBACK)
	equip.ScaleType = Enum.ScaleType.Stretch
	equip.Position = UDim2.fromScale(0.012, 0.115)
	equip.Size = UDim2.fromScale(0.19, 0.5)
	equip.ZIndex = 35
	equip.Parent = window

	-- If the EQUIPMENT title is baked into the bg asset, set Visible = false here.
	local equipTitle = Instance.new("TextLabel")
	equipTitle.Name = "EquipTitle"
	equipTitle.BackgroundTransparency = 1
	equipTitle.Size = UDim2.fromScale(0.8, 0.07)
	equipTitle.Position = UDim2.fromScale(0.1, 0.008)
	equipTitle.Text = "EQUIPMENT"
	equipTitle.ZIndex = 37
	equipTitle.Parent = equip
	UIKit.StyleText(equipTitle, "purple", 3)

	-- 2 swords (main / offhand)
	local swordRow = Instance.new("Frame")
	swordRow.Name = "Swords"
	swordRow.BackgroundTransparency = 1
	swordRow.Position = UDim2.fromScale(0.08, 0.1)
	swordRow.Size = UDim2.fromScale(0.84, 0.22)
	swordRow.ZIndex = 36
	swordRow.Parent = equip
	UIKit.List(swordRow, 8, true, Enum.HorizontalAlignment.Center)

	local function swordCard(assetKey: string, weaponUid: string?, order: number)
		local holder = Instance.new("Frame")
		holder.Name = assetKey
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromScale(0.47, 1)
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
		vpHost.Position = UDim2.fromScale(0.5, 0.5)
		vpHost.AnchorPoint = Vector2.new(0.5, 0.5)
		vpHost.ZIndex = 38
		vpHost.Parent = holder

		if weaponUid then
			for _, w in ipairs(profile.weapons or {}) do
				if w.uid == weaponUid then
					pcall(function()
						WeaponModels.TryFillInventoryIcon(vpHost, w.id, 48)
					end)
					break
				end
			end
		end
	end

	swordCard("MAINswordCARD", profile.equippedMain, 1)
	swordCard("SECONDswordCARD", profile.equippedOffhand, 2)

	-- 8 pets (4x2)
	local petsGrid = Instance.new("Frame")
	petsGrid.Name = "Pets"
	petsGrid.BackgroundTransparency = 1
	petsGrid.Position = UDim2.fromScale(0.08, 0.35)
	petsGrid.Size = UDim2.fromScale(0.84, 0.22)
	petsGrid.ZIndex = 36
	petsGrid.Parent = equip
	local petLayout = Instance.new("UIGridLayout")
	petLayout.CellSize = UDim2.fromScale(0.23, 0.46)
	petLayout.CellPadding = UDim2.fromScale(0.0266, 0.08)
	petLayout.SortOrder = Enum.SortOrder.LayoutOrder
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

	-- 3 relics
	local relicRow = Instance.new("Frame")
	relicRow.Name = "Relics"
	relicRow.BackgroundTransparency = 1
	relicRow.Position = UDim2.fromScale(0.08, 0.585)
	relicRow.Size = UDim2.fromScale(0.84, 0.13)
	relicRow.ZIndex = 36
	relicRow.Parent = equip
	UIKit.List(relicRow, 6, true, Enum.HorizontalAlignment.Center)
	for i = 1, 3 do
		local cell = Instance.new("ImageLabel")
		cell.Name = "RELICcard" .. i
		cell.BackgroundTransparency = 1
		cell.Image = art("RELICcard" .. i)
		cell.ScaleType = Enum.ScaleType.Fit
		cell.Size = UDim2.fromScale(0.29, 1)
		cell.LayoutOrder = i
		cell.ZIndex = 37
		cell.Parent = relicRow
	end

	-- 1 aura, centered (no dedicated empty asset yet — reuses relic frame)
	local auraCell = Instance.new("ImageLabel")
	auraCell.Name = "AURAcard"
	auraCell.BackgroundTransparency = 1
	auraCell.Image = art("RELICcard1")
	auraCell.ScaleType = Enum.ScaleType.Fit
	auraCell.AnchorPoint = Vector2.new(0.5, 0)
	auraCell.Position = UDim2.fromScale(0.5, 0.755)
	auraCell.Size = UDim2.fromScale(0.24, 0.14)
	auraCell.ZIndex = 37
	auraCell.Parent = equip
	if profile.equippedAura then
		local host = Instance.new("Frame")
		host.BackgroundTransparency = 1
		host.Size = UDim2.fromScale(0.8, 0.8)
		host.Position = UDim2.fromScale(0.5, 0.5)
		host.AnchorPoint = Vector2.new(0.5, 0.5)
		host.ZIndex = 38
		host.Parent = auraCell
		pcall(function()
			AuraVisual.TryFillInventoryIcon(host, profile.equippedAura, 36)
		end)
	end

	----------------------------------------------------------------
	-- Buttons column under the panel (order per ref: DAMAGE, POWER)
	----------------------------------------------------------------
	local function equipBest(sortDamage: boolean)
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
		if not sortDamage and ranked[2] then
			Net.EquipWeapon(ranked[2].uid, "offhand")
		end
		args.onRefresh()
	end

	imgBtn(window, "EQUIPbestFORdamageBUTTON", UDim2.fromScale(0.15, 0.062), UDim2.fromScale(0.032, 0.635), 40, function()
		equipBest(true)
	end)
	imgBtn(window, "EQUIPbestFORpowerBUTTON", UDim2.fromScale(0.15, 0.062), UDim2.fromScale(0.032, 0.705), 40, function()
		equipBest(false)
	end)

	-- Presets
	img(window, "PresetsWordmark", "WORDMARK_presets__click_to_equip_1", UDim2.fromScale(0.15, 0.045), UDim2.fromScale(0.032, 0.782), 40)
	local presetRow = Instance.new("Frame")
	presetRow.Name = "Presets"
	presetRow.BackgroundTransparency = 1
	presetRow.Position = UDim2.fromScale(0.032, 0.833)
	presetRow.Size = UDim2.fromScale(0.15, 0.058)
	presetRow.ZIndex = 40
	presetRow.Parent = window
	UIKit.List(presetRow, 6, true, Enum.HorizontalAlignment.Center)
	for i = 1, 4 do
		local b = imgBtn(presetRow, "PRESETcard" .. i, UDim2.fromScale(0.22, 1), nil, 41, function()
			-- TODO: preset equip logic (server side) — art pass first
		end)
		b.LayoutOrder = i
	end

	-- Sell row
	local sellRow = Instance.new("Frame")
	sellRow.Name = "SellRow"
	sellRow.BackgroundTransparency = 1
	sellRow.Position = UDim2.fromScale(0.012, 0.905)
	sellRow.Size = UDim2.fromScale(0.19, 0.062)
	sellRow.ZIndex = 40
	sellRow.Parent = window
	UIKit.List(sellRow, 6, true, Enum.HorizontalAlignment.Center)
	local sellBtn = imgBtn(sellRow, "SELLbutton", UDim2.fromScale(0.47, 1), nil, 41, function()
		-- TODO: sell mode (select + sell) — later pass
	end)
	sellBtn.LayoutOrder = 1
	local sellAllBtn = imgBtn(sellRow, "SELLallUNLOCKEDbutton", UDim2.fromScale(0.47, 1), nil, 41, function()
		Net.SellAllWeapons()
		args.onRefresh()
	end)
	sellAllBtn.LayoutOrder = 2

	-- MOUSEBINDScard hangs off the left edge, outside the window (as in ref)
	img(root, "MOUSEBINDScard", "MOUSEBINDScard", UDim2.fromScale(0.088, 0.17), UDim2.fromScale(0.002, 0.69), 60)

	----------------------------------------------------------------
	-- CENTER: weapon grid
	----------------------------------------------------------------
	local gridHost = Instance.new("Frame")
	gridHost.Name = "BG_WeaponGrid"
	gridHost.BackgroundTransparency = 1
	gridHost.Position = UDim2.fromScale(0.235, 0.115)
	gridHost.Size = UDim2.fromScale(0.748, 0.855)
	gridHost.ZIndex = 35
	gridHost.Parent = window

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
	grid.Parent = scroll

	local function relayout()
		local w = scroll.AbsoluteSize.X
		if w < 40 then
			return
		end
		local pad = 16
		local inner = w - pad - scroll.ScrollBarThickness
		local cell = math.floor((inner - SLOT_GAP * (GRID_COLS - 1)) / GRID_COLS)
		cell = math.clamp(cell, 56, 140)
		grid.CellSize = UDim2.fromOffset(cell, cell)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)

	----------------------------------------------------------------
	-- TOOLTIP (TOOLTIPshell, mouse-follow, left/right flip)
	----------------------------------------------------------------
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Size = UDim2.fromOffset(260, 0)
	tip.AutomaticSize = Enum.AutomaticSize.Y
	tip.ZIndex = 200
	tip.Parent = root

	local tipBg = Instance.new("ImageLabel")
	tipBg.Name = "Shell"
	tipBg.BackgroundTransparency = 1
	tipBg.Image = art("TOOLTIPshell")
	tipBg.ScaleType = Enum.ScaleType.Stretch
	tipBg.Size = UDim2.new(1, 0, 1, 0)
	tipBg.ZIndex = 200
	tipBg.Parent = tip

	UIKit.Pad(tip, 14)
	local tipList = Instance.new("UIListLayout")
	tipList.SortOrder = Enum.SortOrder.LayoutOrder
	tipList.Padding = UDim.new(0, 3)
	tipList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tipList.Parent = tip
	local tipMax = Instance.new("UISizeConstraint")
	tipMax.MinSize = Vector2.new(220, 90)
	tipMax.MaxSize = Vector2.new(300, 300)
	tipMax.Parent = tip

	local function clearTip()
		for _, c in tip:GetChildren() do
			if c.Name == "Shell" then
				continue
			end
			if c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UISizeConstraint") or c:IsA("UIStroke") then
				continue
			end
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
		local tipW = math.max(tip.AbsoluteSize.X, 240)
		local tipH = math.max(tip.AbsoluteSize.Y, 100)
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

	local function showTip(name: string, rar: string?, power: number, sell: number, level: number, equippedLine: string?)
		clearTip()
		local order = 1
		if equippedLine then
			tipText(tip, order, equippedLine, "gold", 24)
			order += 1
		end
		tipText(tip, order, name, "purple", 30)
		order += 1
		if rar then
			tipRarity(tip, order, rar)
			order += 1
		end
		tipText(tip, order, string.format("POWER: ×%.2f", power), "purple", 22)
		order += 1
		tipText(tip, order, string.format("SELL PRICE: %d", sell), "gold", 22)
		order += 1
		tipText(tip, order, string.format("LEVEL: %d", level), "gray", 22)
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
	-- Slots (Card = Body [+ Rim for Limited] + Content)
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

		local body = Instance.new("ImageLabel")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.ScaleType = Enum.ScaleType.Fit
		body.Size = UDim2.fromScale(1, 1)
		body.ZIndex = 40
		body.Parent = btn

		if rar == "Limited" then
			local bodyId, rimId = InventoryAssetConfig.GetLimitedLayers()
			body.Image = bodyId
			local rim = Instance.new("ImageLabel")
			rim.Name = "Rim"
			rim.BackgroundTransparency = 1
			rim.Image = rimId
			rim.ScaleType = Enum.ScaleType.Fit
			rim.Size = UDim2.fromScale(1, 1)
			rim.ZIndex = 41
			rim.Parent = btn
			attachShimmer(rim)
		else
			body.Image = InventoryAssetConfig.GetSlotFrame(rar)
		end

		if w then
			local content = Instance.new("Frame")
			content.Name = "Content"
			content.BackgroundTransparency = 1
			content.Size = UDim2.fromScale(0.72, 0.72)
			content.Position = UDim2.fromScale(0.5, 0.5)
			content.AnchorPoint = Vector2.new(0.5, 0.5)
			content.ZIndex = 42
			content.Active = false
			content.Parent = btn

			local used = false
			pcall(function()
				used = WeaponModels.TryFillInventoryIcon(content, w.id, 44) == true
			end)
			if not used and IconConfig.HasWeaponImage(w.id) then
				local ic = Instance.new("ImageLabel")
				ic.BackgroundTransparency = 1
				ic.Size = UDim2.fromScale(1, 1)
				ic.Image = IconConfig.GetWeaponImage(w.id)
				ic.ScaleType = Enum.ScaleType.Fit
				ic.ZIndex = 42
				ic.Parent = content
			end

			local isMain = profile.equippedMain == w.uid
			local isOff = profile.equippedOffhand == w.uid
			if isMain or isOff then
				local mark = Instance.new("Frame")
				mark.Name = "EquipMark"
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

			-- only the hovered card pops; the rest stay static
			local sc = Instance.new("UIScale")
			sc.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = HOVER_SCALE }):Play()
				local eq: string? = nil
				if isMain then
					eq = "EQUIPPED MAIN"
				elseif isOff then
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
	-- Bottom tab rail (OUTSIDE the window, gap before SETTINGS)
	----------------------------------------------------------------
	local tabRail = Instance.new("Frame")
	tabRail.Name = "TabRail"
	tabRail.BackgroundTransparency = 1
	tabRail.AnchorPoint = Vector2.new(0.5, 1)
	tabRail.Position = UDim2.fromScale(0.5, 0.998)
	tabRail.Size = UDim2.fromScale(0.85, 0.115)
	tabRail.ZIndex = 50
	tabRail.Parent = root
	UIKit.List(tabRail, 10, true, Enum.HorizontalAlignment.Center)

	for idx, def in ipairs(FIGMA_TABS) do
		if def.id == "settings" then
			-- ref has a visible gap before SETTINGS
			local spacer = Instance.new("Frame")
			spacer.Name = "Spacer"
			spacer.BackgroundTransparency = 1
			spacer.Size = UDim2.fromScale(0.025, 1)
			spacer.LayoutOrder = idx * 10 - 5
			spacer.Parent = tabRail
		end
		local b = Instance.new("ImageButton")
		b.Name = def.id
		b.BackgroundTransparency = 1
		b.AutoButtonColor = false
		b.Image = art(def.key)
		b.ScaleType = Enum.ScaleType.Fit
		b.Size = UDim2.fromScale(1, 1)
		b.LayoutOrder = idx * 10
		b.ImageTransparency = if def.id == "weapons" then 0 else 0.25
		b.ZIndex = 51
		b.Parent = tabRail
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = 1
		ar.DominantAxis = Enum.DominantAxis.Height
		ar.Parent = b
		local sc = Instance.new("UIScale")
		sc.Scale = if def.id == "weapons" then 1.06 else 1
		sc.Parent = b
		b.MouseEnter:Connect(function()
			if def.id ~= "weapons" then
				TweenService:Create(b, TweenInfo.new(0.12), { ImageTransparency = 0 }):Play()
			end
		end)
		b.MouseLeave:Connect(function()
			if def.id ~= "weapons" then
				TweenService:Create(b, TweenInfo.new(0.12), { ImageTransparency = 0.25 }):Play()
			end
		end)
		b.MouseButton1Click:Connect(function()
			if def.id == "weapons" then
				return
			end
			if def.id == "settings" then
				-- settings window not wired into onTab yet — keep old fallback
				args.onTab("shop")
				return
			end
			args.onTab(def.id)
		end)
	end
end

return InventoryWeaponsLayout
