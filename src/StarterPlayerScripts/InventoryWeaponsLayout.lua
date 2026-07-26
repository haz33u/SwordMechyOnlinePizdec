--!strict
--[[
	FIGMA INVENTORY — layout anchored on MAINBACKGROUD (not outer Frame).

	host (full-screen transparent, weapons window)
	  shell (MAINBACKGROUD plate; slightly left + lowered)
	    chrome remapped relative to shell (Figma → MAINBACKGROUD box)
	    grid content: weapons | pets | auras | relics | items
	  Tooltip (mouse-follow)
	Side tabs — snug right of MAINBACKGROUD shell (no strip/plate, no text labels)
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
local GRID_COLS = 6

-- Figma fractions vs FULL layout group 5193:9879 (11609x7943)
local FIGMA = {
	MAINBACKGROUD = { 0.12563, 0.08995, 0.87437, 0.78063 },
	INVENTORYWEAPONcard = { 0.05513, 0.00000, 0.30762, 0.15381 },
	BTN_Close = { 0.94964, 0.10952, 0.03966, 0.05929 },
	TitleNickPlate = { 0.78407, 0.10952, 0.15204, 0.04129 },
	Divider = { 0.34500, 0.11531, 0.62023, 0.03500 },
	BG_WeaponGrid = { 0.32794, 0.16881, 0.65460, 0.67376 },
	EQUIPMENTbackground = { 0.14369, 0.13722, 0.17323, 0.38434 },
	EquipTitlePlate = { 0.18400, 0.14880, 0.09252, 0.02757 },
	MAINswordCARD = { 0.15936, 0.17285, 0.06995, 0.10222 },
	SECONDswordCARD = { 0.23147, 0.17285, 0.06995, 0.10222 },
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
	-- Binds left of MAINBACKGROUD (negative x after remap) — stay adjacent, no extra fly-out
	MOUSEBINDScard = { 0.00000, 0.60792, 0.13144, 0.26360 },
}

-- Remap full-layout fractions → relative to MAINBACKGROUD box
local MB = FIGMA.MAINBACKGROUD
local function rel(b: { number }): { number }
	return {
		(b[1] - MB[1]) / MB[3],
		(b[2] - MB[2]) / MB[4],
		b[3] / MB[3],
		b[4] / MB[4],
	}
end

local R: { [string]: { number } } = {}
for k, b in FIGMA do
	if k ~= "MAINBACKGROUD" then
		R[k] = rel(b)
	end
end
-- RULE: chrome stays inside MAINBACKGROUD shell (0..1), except binds (negative x).
-- WeaponGrid: grow a bit more on all sides (more up/right), still clamped to shell.
do
	local g = R.BG_WeaponGrid
	local left, right, top, bottom = 0.014, 0.036, 0.030, 0.016
	local nx = g[1] - left
	local ny = g[2] - top
	local nw = g[3] + left + right
	local nh = g[4] + top + bottom
	nx = math.max(0, nx)
	ny = math.max(0, ny)
	nw = math.min(nw, 0.99 - nx)
	nh = math.min(nh, 0.99 - ny)
	R.BG_WeaponGrid = { nx, ny, nw, nh }
end

-- EQUIPMENTbackground: pull top edge up so EQUIPMENT title sits inside the plate
do
	local e = R.EQUIPMENTbackground
	local up = 0.028
	local ny = math.max(0.01, e[2] - up)
	local nh = e[4] + (e[2] - ny)
	R.EQUIPMENTbackground = { e[1], ny, e[3], nh }
	local t = R.EquipTitlePlate
	if t then
		R.EquipTitlePlate = { t[1], math.max(0.02, t[2] - up * 0.85), t[3], t[4] }
	end
end

local TITLE_CARD: { [string]: string } = {
	weapons = "INVENTORYWEAPONcard",
	pets = "PETScard",
	auras = "AURAScard",
	relics = "RELICcard",
	items = "CONSUMABLEScard",
}

local FIGMA_TABS = {
	{ id = "weapons", key = "WEAPONSBUTTON", label = "WEAPONS" },
	{ id = "pets", key = "PETCBUTTON", label = "PETS" },
	{ id = "auras", key = "AURABUTTON", label = "AURAS" },
	{ id = "relics", key = "RELICBUTTON", label = "RELICS" },
	{ id = "items", key = "CONSUMABLESBUTTON", label = "ITEMS" },
	{ id = "shop", key = "SHOPBUTTON", label = "SHOP" },
	{ id = "profile", key = "PROFILEBUTTON", label = "PROFILE" },
	{ id = "settings", key = "SETTINGSBUTTON", label = "SETTINGS" },
}

local function art(key: string): string
	return InventoryAssetConfig.Get(key)
end

local function place(
	parent: Instance,
	name: string,
	assetKey: string,
	b: { number },
	z: number?,
	isBtn: boolean?,
	scaleType: Enum.ScaleType?
): GuiObject
	local i: GuiObject
	if isBtn then
		local btn = Instance.new("ImageButton")
		btn.AutoButtonColor = false
		i = btn
	else
		i = Instance.new("ImageLabel")
	end
	i.Name = name
	i.BackgroundTransparency = 1
	i.BorderSizePixel = 0
	;(i :: any).Image = art(assetKey)
	;(i :: any).ScaleType = scaleType or Enum.ScaleType.Fit
	i.Size = UDim2.fromScale(b[3], b[4])
	i.Position = UDim2.fromScale(b[1], b[2])
	i.ZIndex = z or 40
	i.Parent = parent
	return i
end

local function tipText(parent: Instance, order: number, text: string, grad: string?, h: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = "T" .. order
	l.BackgroundTransparency = 1
	-- Slightly smaller than original (was ~26–28) — still readable
	l.Size = UDim2.new(1, -18, 0, h or 22)
	l.LayoutOrder = order
	l.Text = string.upper(text)
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextWrapped = true
	l.ZIndex = (parent :: GuiObject).ZIndex + 2
	l.Parent = parent
	UIKit.StyleText(l, grad or "purple", 2)
	return l
end

export type RenderArgs = {
	profile: any,
	stats: any?,
	-- weapons | pets | auras | relics | items
	invTab: string?,
	onClose: () -> (),
	onTab: (tabId: string) -> (),
	onRefresh: () -> (),
}

function InventoryWeaponsLayout.Destroy(parent: Instance)
	local function wipe(inst: Instance?)
		if not inst then
			return
		end
		local old = inst:FindFirstChild(ROOT_NAME)
		if old then
			old:Destroy()
		end
		local tabs = inst:FindFirstChild("InvBottomTabBar")
		if tabs then
			tabs:Destroy()
		end
	end
	wipe(parent)
	wipe(parent.Parent)
	local p = parent
	while p and not p:IsA("ScreenGui") do
		p = p.Parent
	end
	if p then
		wipe(p)
		local tabs = p:FindFirstChild("InvBottomTabBar")
		if tabs then
			tabs:Destroy()
		end
	end
end

function InventoryWeaponsLayout.Render(parent: Frame, args: RenderArgs)
	InventoryWeaponsLayout.Destroy(parent)

	local profile = args.profile
	local invTab = args.invTab or "weapons"
	if TITLE_CARD[invTab] == nil then
		invTab = "weapons"
	end

	-- Climb to ScreenGui so side tabs cannot be clipped by Window/Body
	local mountTo: Instance = parent
	local screenGui: ScreenGui? = nil
	do
		local p: Instance? = parent
		while p do
			if p:IsA("ScreenGui") then
				screenGui = p
				break
			end
			if p:IsA("GuiObject") and p.Name == "weapons" then
				mountTo = p
			end
			p = p.Parent
		end
	end
	if mountTo:IsA("GuiObject") then
		(mountTo :: GuiObject).ClipsDescendants = false
	end

	local host = Instance.new("Frame")
	host.Name = ROOT_NAME
	host.BackgroundTransparency = 1
	host.BorderSizePixel = 0
	host.Size = UDim2.fromScale(1, 1)
	host.Position = UDim2.fromScale(0, 0)
	host.AnchorPoint = Vector2.new(0, 0)
	host.ClipsDescendants = false
	host.ZIndex = 200
	host.Parent = mountTo

	-- Kill leftover window chrome (strokes / gray plates) that look like a strip around inv
	do
		local killRoot: Instance? = mountTo
		while killRoot and not killRoot:IsA("ScreenGui") do
			if killRoot:IsA("GuiObject") then
				local g = killRoot :: GuiObject
				g.BackgroundTransparency = 1
				g.BorderSizePixel = 0
			end
			for _, ch in killRoot:GetChildren() do
				if ch:IsA("UIStroke") or ch:IsA("UIGradient") then
					ch:Destroy()
				end
				if ch.Name == "InvCanvas" and ch:IsA("GuiObject") then
					ch.Visible = false
					ch.BackgroundTransparency = 1
					for _, d in ch:GetDescendants() do
						if d:IsA("UIStroke") then
							d:Destroy()
						end
					end
				end
			end
			killRoot = killRoot.Parent
		end
	end

	----------------------------------------------------------------
	-- SHELL = MAINBACKGROUD plate
	-- Dead center on X, only slightly lowered on Y (no left/right shift)
	----------------------------------------------------------------
	local shell = Instance.new("Frame")
	shell.Name = "MAINBACKGROUD_Shell"
	shell.BackgroundTransparency = 1
	shell.BorderSizePixel = 0
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.52) -- center X, slightly down from mid
	shell.Size = UDim2.fromScale(0.96, 0.86)
	shell.ClipsDescendants = false -- binds hang left of plate
	shell.ZIndex = 40
	shell.Parent = host

	-- MAINBACKGROUD aspect ≈ 1.637 — FitWithinMaxSize keeps plate proportional
	local shellAspect = Instance.new("UIAspectRatioConstraint")
	shellAspect.AspectRatio = 1.637
	shellAspect.AspectType = Enum.AspectType.FitWithinMaxSize
	shellAspect.DominantAxis = Enum.DominantAxis.Width
	shellAspect.Parent = shell

	local bg = Instance.new("ImageLabel")
	bg.Name = "MAINBACKGROUD"
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Image = art("MAINBACKGROUD")
	bg.ScaleType = Enum.ScaleType.Stretch
	bg.Size = UDim2.fromScale(1, 1)
	bg.ZIndex = 40
	bg.Parent = shell

	----------------------------------------------------------------
	-- SIDE TABS — snug against RIGHT edge of shell, a bit larger, no plate/strip
	----------------------------------------------------------------
	local tabBar = Instance.new("Frame")
	tabBar.Name = "InvBottomTabBar"
	tabBar.BackgroundTransparency = 1
	tabBar.BorderSizePixel = 0
	tabBar.AnchorPoint = Vector2.new(0, 0.5)
	tabBar.Position = UDim2.fromScale(0.9, 0.5) -- placeholder; placeSideTabs pins to shell
	tabBar.Size = UDim2.fromOffset(100, 600)
	tabBar.ZIndex = 400
	tabBar.Visible = true
	tabBar.Active = false
	tabBar.Parent = host -- same host as shell so they track together

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Vertical
	tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabList.VerticalAlignment = Enum.VerticalAlignment.Center
	tabList.Padding = UDim.new(0, 8)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = tabBar

	local tabButtons: { ImageButton } = {}
	for i, def in ipairs(FIGMA_TABS) do
		local b = Instance.new("ImageButton")
		b.Name = def.id .. "Tab"
		b.BackgroundTransparency = 1
		b.BorderSizePixel = 0
		b.Image = art(def.key)
		b.ScaleType = Enum.ScaleType.Fit
		b.AutoButtonColor = true
		b.Size = UDim2.fromOffset(96, 96)
		b.LayoutOrder = i
		b.ZIndex = 401
		b.Visible = true
		b.Active = true
		b.ImageTransparency = if def.id == invTab then 0 else 0.22
		b.Parent = tabBar
		table.insert(tabButtons, b)

		b.MouseButton1Click:Connect(function()
			if def.id == invTab or def.id == "settings" then
				return
			end
			args.onTab(def.id)
		end)
	end

	local function placeSideTabs()
		local sPos = shell.AbsolutePosition
		local sSize = shell.AbsoluteSize
		local hPos = host.AbsolutePosition
		local hSize = host.AbsoluteSize
		if sSize.X < 40 or sSize.Y < 40 or hSize.X < 40 then
			return
		end
		-- Bigger than before (~11% of shell height), clamped
		local side = math.clamp(math.floor(sSize.Y * 0.112), 84, 132)
		local gap = math.max(6, math.floor(side * 0.07))
		local n = #tabButtons
		local totalH = side * n + gap * math.max(0, n - 1)
		-- If taller than shell, shrink to fit
		if totalH > sSize.Y * 0.98 then
			side = math.floor((sSize.Y * 0.98 - gap * (n - 1)) / n)
			side = math.clamp(side, 72, 132)
			totalH = side * n + gap * (n - 1)
		end
		tabList.Padding = UDim.new(0, gap)
		for _, b in ipairs(tabButtons) do
			b.Size = UDim2.fromOffset(side, side)
		end
		local gapX = math.max(8, math.floor(side * 0.1))
		local localX = (sPos.X - hPos.X) + sSize.X + gapX
		local localY = (sPos.Y - hPos.Y) + sSize.Y * 0.5
		-- Keep on-screen if shell is very wide
		if localX + side > hSize.X - 4 then
			localX = hSize.X - side - 8
		end
		tabBar.Size = UDim2.fromOffset(side + 4, totalH)
		tabBar.Position = UDim2.fromOffset(math.floor(localX + 0.5), math.floor(localY + 0.5))
	end
	shell:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeSideTabs)
	shell:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeSideTabs)
	host:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeSideTabs)
	task.defer(placeSideTabs)
	task.delay(0.05, placeSideTabs)
	task.delay(0.15, placeSideTabs)

	-- All chrome positions are relative to SHELL (MAINBACKGROUD)
	local function pImg(name: string, key: string, b: { number }, z: number?, st: Enum.ScaleType?)
		return place(shell, name, key, b, z, false, st)
	end
	local function pBtn(name: string, key: string, b: { number }, z: number?, onClick: (() -> ())?)
		local btn = place(shell, name, key, b, z, true) :: ImageButton
		local sc = Instance.new("UIScale")
		sc.Parent = btn
		btn.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1.05 }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
		end)
		if onClick then
			btn.MouseButton1Click:Connect(onClick)
		end
		return btn
	end

	local titleArt = TITLE_CARD[invTab] or "INVENTORYWEAPONcard"
	pImg("TitleCard", titleArt, R.INVENTORYWEAPONcard, 50)
	pImg("Divider", "Divider_3_Minimal_1", R.Divider, 48, Enum.ScaleType.Stretch)
	pBtn("Close", "BTN_Close_3", R.BTN_Close, 80, args.onClose)

	local nickPlate = pImg("TitleNickPlate", "btn_neutral_2_1", R.TitleNickPlate, 50)
	local nickStrip = Instance.new("TextLabel")
	nickStrip.BackgroundTransparency = 1
	nickStrip.Size = UDim2.fromScale(0.9, 0.7)
	nickStrip.Position = UDim2.fromScale(0.5, 0.5)
	nickStrip.AnchorPoint = Vector2.new(0.5, 0.5)
	local titleTxt = (profile and (profile.equippedTitle or profile.title)) or "TITLE"
	local nickTxt = (Players.LocalPlayer and Players.LocalPlayer.Name) or "PLAYER"
	nickStrip.Text = string.upper(tostring(titleTxt) .. " | " .. tostring(nickTxt))
	nickStrip.ZIndex = 51
	nickStrip.Parent = nickPlate
	UIKit.StyleText(nickStrip, "gold", 2)

	---------------------------------------------------------------- tooltip first (equip + grid both use it)
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Size = UDim2.fromOffset(270, 160)
	tip.ZIndex = 300
	tip.Parent = host

	local tipBg = Instance.new("ImageLabel")
	tipBg.BackgroundTransparency = 1
	tipBg.Image = art("TOOLTIPshell")
	tipBg.ScaleType = Enum.ScaleType.Stretch
	tipBg.Size = UDim2.fromScale(1, 1)
	tipBg.ZIndex = 1
	tipBg.Parent = tip

	local tipBody = Instance.new("Frame")
	tipBody.BackgroundTransparency = 1
	tipBody.Size = UDim2.fromScale(1, 1)
	tipBody.ZIndex = 10
	tipBody.Parent = tip
	UIKit.Pad(tipBody, 12)
	local tipList = Instance.new("UIListLayout")
	tipList.SortOrder = Enum.SortOrder.LayoutOrder
	tipList.Padding = UDim.new(0, 2)
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
		local mx, my = mouse.X - inset.X, mouse.Y - inset.Y
		local parentAbs, parentSz = host.AbsolutePosition, host.AbsoluteSize
		local tipW, tipH = math.max(tip.AbsoluteSize.X, 270), math.max(tip.AbsoluteSize.Y, 160)
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
		tip.Position = UDim2.fromOffset(math.floor(screenX - parentAbs.X + 0.5), math.floor(screenY - parentAbs.Y + 0.5))
	end

	local function hideTip()
		tip.Visible = false
	end

	-- Tip text only slightly smaller than original (readable, fits art)
	local function showTip(title: string, rarity: string?, power: number, sell: number, level: number, equippedLine: string?)
		clearTip()
		local order = 1
		if equippedLine then
			tipText(tipBody, order, equippedLine, "gold", 18)
			order += 1
		end
		tipText(tipBody, order, title, "purple", 24)
		order += 1
		if rarity then
			tipText(tipBody, order, rarity, "gray", 17)
			order += 1
		end
		tipText(tipBody, order, string.format("POWER: ×%.2f", power), "purple", 17)
		order += 1
		tipText(tipBody, order, string.format("SELL PRICE: %d", sell), "gold", 17)
		order += 1
		tipText(tipBody, order, string.format("LEVEL: %d", level), "gray", 17)
		tip.Visible = true
		task.defer(placeTip)
		placeTip()
	end

	local function showTipLines(lines: { any })
		clearTip()
		for i, row in ipairs(lines) do
			local text = tostring(row[1])
			local grad = if type(row[2]) == "string" then (row[2] :: string) else "purple"
			local h = if type(row[3]) == "number" then (row[3] :: number) else 18
			tipText(tipBody, i, text, grad, h)
		end
		tip.Visible = true
		task.defer(placeTip)
		placeTip()
	end

	local function bindHoverTip(gui: GuiObject, buildLines: () -> any)
		gui.Active = true
		gui.MouseEnter:Connect(function()
			local lines = buildLines()
			if type(lines) == "table" and #lines > 0 then
				showTipLines(lines)
			end
		end)
		gui.MouseLeave:Connect(function()
			hideTip()
		end)
	end

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible then
			placeTip()
		end
	end)

	---------------------------------------------------------------- Equipment panel (+ tooltips on slots)
	pImg("EQUIPMENTbackground", "EQUIPMENTbackground", R.EQUIPMENTbackground, 45, Enum.ScaleType.Stretch)
	local equipTitleBg = pImg("EquipTitlePlate", "btn_neutral_2_2", R.EquipTitlePlate, 46)
	local equipTitle = Instance.new("TextLabel")
	equipTitle.BackgroundTransparency = 1
	equipTitle.Size = UDim2.fromScale(0.92, 0.75)
	equipTitle.Position = UDim2.fromScale(0.5, 0.5)
	equipTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	equipTitle.Text = "EQUIPMENT"
	equipTitle.ZIndex = 47
	equipTitle.Parent = equipTitleBg
	UIKit.StyleText(equipTitle, "purple", 2)

	local function fillWeapon(key: string, b: { number }, uid: string?, equipLabel: string)
		local plate = pImg(key, key, b, 48)
		local vp = Instance.new("Frame")
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(0.72, 0.72)
		vp.Position = UDim2.fromScale(0.5, 0.5)
		vp.AnchorPoint = Vector2.new(0.5, 0.5)
		vp.ZIndex = 49
		vp.Active = false
		vp.Parent = plate
		local matched: any = nil
		if uid then
			for _, w in ipairs(profile.weapons or {}) do
				if w.uid == uid then
					matched = w
					pcall(function()
						WeaponModels.TryFillInventoryIcon(vp, w.id, 48)
					end)
					break
				end
			end
		end
		bindHoverTip(plate, function()
			if not matched then
				return {
					{ equipLabel, "gold", 18 },
					{ "EMPTY SLOT", "gray", 22 },
				}
			end
			local def = WeaponConfig.Get(matched.id)
			local name = (def and def.name) or WeaponConfig.GetDisplayName(matched.id)
			local rar = (def and def.rarity) or "Common"
			local mult = (def and def.powerMult) or 1
			local sellP = (def and def.sellPrice) or 5
			local lv = matched.level or 1
			return {
				{ equipLabel, "gold", 18 },
				{ name, "purple", 24 },
				{ rar, "gray", 17 },
				{ string.format("POWER: ×%.2f", mult), "purple", 17 },
				{ string.format("SELL PRICE: %d", sellP), "gold", 17 },
				{ string.format("LEVEL: %d", lv), "gray", 17 },
			}
		end)
	end
	fillWeapon("MAINswordCARD", R.MAINswordCARD, profile.equippedMain, "EQUIPPED MAIN")
	fillWeapon("SECONDswordCARD", R.SECONDswordCARD, profile.equippedOffhand, "EQUIPPED OFFHAND")

	local team = profile.petTeam or {}
	local petByUid: { [string]: any } = {}
	for _, p in ipairs(profile.pets or {}) do
		petByUid[tostring(p.uid)] = p
	end
	local petKeys = { "PETcard1", "PETcard2", "PETcard3", "PETcard4", "PETcard5", "PETcard6", "PETcard7", "PETcard8" }
	for i, key in ipairs(petKeys) do
		local plate = pImg(key, key, R[key], 48)
		local uid = team[i]
		local pet = if uid then petByUid[tostring(uid)] else nil
		if pet then
			local vp = Instance.new("Frame")
			vp.BackgroundTransparency = 1
			vp.Size = UDim2.fromScale(0.78, 0.78)
			vp.Position = UDim2.fromScale(0.5, 0.5)
			vp.AnchorPoint = Vector2.new(0.5, 0.5)
			vp.ZIndex = 49
			vp.Active = false
			vp.Parent = plate
			pcall(function()
				PetVisual.TryFillInventoryIcon(vp, pet.id, 32)
			end)
		end
		bindHoverTip(plate, function()
			if not pet then
				return {
					{ "PET SLOT " .. i, "gold", 18 },
					{ "EMPTY", "gray", 22 },
				}
			end
			local def = PetConfig.Get(pet.id)
			local name = (def and def.name) or tostring(pet.id)
			local rar = (def and def.rarity) or "Common"
			local mult = (def and def.powerMult) or 1
			local lv = pet.level or 1
			return {
				{ "PET SLOT " .. i, "gold", 18 },
				{ name, "purple", 24 },
				{ rar, "gray", 17 },
				{ string.format("POWER: ×%.2f", mult), "purple", 17 },
				{ string.format("LEVEL: %d", lv), "gray", 17 },
			}
		end)
	end
	for i = 1, 3 do
		local plate = pImg("RELICcard" .. i, "RELICcard" .. i, R["RELICcard" .. i], 48)
		bindHoverTip(plate, function()
			return {
				{ "RELIC SLOT " .. i, "gold", 18 },
				{ "EMPTY", "gray", 22 },
			}
		end)
	end
	do
		local aura = pImg("AURAcard", "RELICcard1", R.AURAcard, 48)
		local auraId = profile.equippedAura
		if auraId then
			local vp = Instance.new("Frame")
			vp.BackgroundTransparency = 1
			vp.Size = UDim2.fromScale(0.8, 0.8)
			vp.Position = UDim2.fromScale(0.5, 0.5)
			vp.AnchorPoint = Vector2.new(0.5, 0.5)
			vp.ZIndex = 49
			vp.Active = false
			vp.Parent = aura
			pcall(function()
				AuraVisual.TryFillInventoryIcon(vp, auraId, 36)
			end)
		end
		bindHoverTip(aura, function()
			if not auraId then
				return {
					{ "AURA", "gold", 18 },
					{ "EMPTY", "gray", 22 },
				}
			end
			local resolved = AuraConfig.ResolveId(tostring(auraId))
			local def = AuraConfig.Get(resolved)
			local name = (def and def.name) or tostring(auraId)
			local rar = (def and def.rarity) or "Common"
			local powerPct = (def and def.powerPct) or 0
			return {
				{ "EQUIPPED AURA", "gold", 18 },
				{ name, "purple", 24 },
				{ rar, "gray", 17 },
				{ string.format("POWER: +%d%%", powerPct), "purple", 17 },
			}
		end)
	end

	local function rankWeapons()
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

	pBtn("EQUIPbestFORdamageBUTTON", "EQUIPbestFORdamageBUTTON", R.EQUIPbestFORdamage, 55, function()
		local ranked = rankWeapons()
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		args.onRefresh()
	end)
	pBtn("EQUIPbestFORpowerBUTTON", "EQUIPbestFORpowerBUTTON", R.EQUIPbestFORpower, 55, function()
		local ranked = rankWeapons()
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		if ranked[2] then
			Net.EquipWeapon(ranked[2].uid, "offhand")
		end
		args.onRefresh()
	end)

	pImg("PRESETSbutton", "WORDMARK_presets__click_to_equip_1", R.PRESETSbutton, 50)
	for i = 1, 4 do
		pImg("PRESETcard" .. i, "PRESETcard" .. i, R["PRESETcard" .. i], 51)
	end
	pBtn("SELLbutton", "SELLbutton", R.SELLbutton, 55, function() end)
	pBtn("SELLallUNLOCKEDbutton", "SELLallUNLOCKEDbutton", R.SELLallUNLOCKED, 55, function()
		if invTab == "weapons" then
			Net.SellAllWeapons()
		elseif invTab == "pets" then
			for _, p in ipairs(profile.pets or {}) do
				local onTeam = false
				for _, uid in ipairs(profile.petTeam or {}) do
					if uid == p.uid then
						onTeam = true
						break
					end
				end
				if not onTeam then
					Net.SellPet(p.uid)
				end
			end
		end
		args.onRefresh()
	end)
	-- binds left of shell
	pImg("MOUSEBINDScard", "MOUSEBINDScard", R.MOUSEBINDScard, 52)

	---------------------------------------------------------------- weapon grid INSIDE MAINBACKGROUD only
	local gBox = R.BG_WeaponGrid
	-- Safety clamp: never leave shell bounds (0..1)
	local gx = math.clamp(gBox[1], 0, 0.98)
	local gy = math.clamp(gBox[2], 0, 0.98)
	local gw = math.clamp(gBox[3], 0.05, 1 - gx)
	local gh = math.clamp(gBox[4], 0.05, 1 - gy)

	local gridHost = Instance.new("Frame")
	gridHost.Name = "BG_WeaponGrid"
	gridHost.BackgroundTransparency = 1
	gridHost.Size = UDim2.fromScale(gw, gh)
	gridHost.Position = UDim2.fromScale(gx, gy)
	gridHost.ClipsDescendants = true
	gridHost.ZIndex = 46
	gridHost.Parent = shell

	local gridBg = Instance.new("ImageLabel")
	gridBg.BackgroundTransparency = 1
	gridBg.Image = art("BG_WeaponGrid")
	gridBg.ScaleType = Enum.ScaleType.Stretch
	gridBg.Size = UDim2.fromScale(1, 1)
	gridBg.ZIndex = 46
	gridBg.Parent = gridHost

	-- Cards sit INSIDE the painted grid; fill most of the frame (tight gaps for hover)
	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(0.935, 0.88)
	scroll.Position = UDim2.fromScale(0.032, 0.07)
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 140, 255)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ClipsDescendants = true
	scroll.ZIndex = 47
	scroll.Parent = gridHost

	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = GRID_COLS
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.CellPadding = UDim2.fromOffset(4, 4)
	grid.Parent = scroll

	local function relayout()
		local w = scroll.AbsoluteSize.X
		if w < 40 then
			return
		end
		-- Tight gaps but enough for HOVER_SCALE 1.06 (~6% of cell)
		local pad = math.max(3, math.floor(w * 0.0045))
		grid.CellPadding = UDim2.fromOffset(pad, pad)
		local cell = math.floor((w - pad * (GRID_COLS - 1)) / GRID_COLS)
		cell = math.max(40, cell)
		grid.CellSize = UDim2.fromOffset(cell, cell)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)
	task.delay(0.05, relayout)

	---------------------------------------------------------------- grid slots (weapons / pets / auras / relics / items)
	local function emptySlot(order: number)
		local btn = Instance.new("ImageButton")
		btn.Name = "Empty_" .. order
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.ZIndex = 50
		btn.Image = InventoryAssetConfig.GetSlotFrame("Empty")
		btn.ScaleType = Enum.ScaleType.Stretch
		btn.Parent = scroll
	end

	local function iconHostOn(btn: GuiObject): Frame
		local iconHost = Instance.new("Frame")
		iconHost.BackgroundTransparency = 1
		iconHost.Size = UDim2.fromScale(0.78, 0.78)
		iconHost.Position = UDim2.fromScale(0.5, 0.5)
		iconHost.AnchorPoint = Vector2.new(0.5, 0.5)
		iconHost.ZIndex = 51
		iconHost.Active = false
		iconHost.Parent = btn
		return iconHost
	end

	local function markDot(btn: GuiObject, col: Color3)
		local mark = Instance.new("Frame")
		mark.Size = UDim2.fromOffset(10, 10)
		mark.Position = UDim2.fromOffset(6, 6)
		mark.BackgroundColor3 = col
		mark.BorderSizePixel = 0
		mark.ZIndex = 52
		mark.Parent = btn
		UIKit.Corner(mark, 99)
	end

	local function wireHover(btn: GuiObject, linesBuilder: () -> any, onClick: (() -> ())?)
		local sc = Instance.new("UIScale")
		sc.Parent = btn
		btn.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.12), { Scale = HOVER_SCALE }):Play()
			local lines = linesBuilder()
			if type(lines) == "table" and #lines > 0 then
				showTipLines(lines)
			end
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
			hideTip()
		end)
		if onClick then
			(btn :: ImageButton).MouseButton1Click:Connect(onClick)
		end
	end

	local itemCount = 0

	if invTab == "weapons" then
		local weapons = profile.weapons or {}
		itemCount = #weapons
		for i, w in ipairs(weapons) do
			local btn = Instance.new("ImageButton")
			btn.Name = "W_" .. w.uid
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 50
			btn.Parent = scroll
			local def = WeaponConfig.Get(w.id)
			local rar = (def and def.rarity) or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local iconHost = iconHostOn(btn)
			local used = false
			pcall(function()
				used = WeaponModels.TryFillInventoryIcon(iconHost, w.id, 48) == true
			end)
			if not used and IconConfig.HasWeaponImage(w.id) then
				local ic = Instance.new("ImageLabel")
				ic.BackgroundTransparency = 1
				ic.Size = UDim2.fromScale(1, 1)
				ic.Image = IconConfig.GetWeaponImage(w.id)
				ic.ScaleType = Enum.ScaleType.Fit
				ic.ZIndex = 51
				ic.Parent = iconHost
			end
			if profile.equippedMain == w.uid or profile.equippedOffhand == w.uid then
				markDot(btn, Rarity.Of(rar))
			end
			local name = (def and def.name) or WeaponConfig.GetDisplayName(w.id)
			local mult = (def and def.powerMult) or 1
			local sellP = (def and def.sellPrice) or 5
			local lv = w.level or 1
			wireHover(btn, function()
				local eq: string? = nil
				if profile.equippedMain == w.uid then
					eq = "EQUIPPED MAIN"
				elseif profile.equippedOffhand == w.uid then
					eq = "EQUIPPED OFFHAND"
				end
				local lines: { any } = {}
				if eq then
					table.insert(lines, { eq, "gold", 18 })
				end
				table.insert(lines, { name, "purple", 24 })
				table.insert(lines, { rar, "gray", 17 })
				table.insert(lines, { string.format("POWER: ×%.2f", mult), "purple", 17 })
				table.insert(lines, { string.format("SELL PRICE: %d", sellP), "gold", 17 })
				table.insert(lines, { string.format("LEVEL: %d", lv), "gray", 17 })
				return lines
			end, function()
				Net.EquipWeapon(w.uid, "main")
				args.onRefresh()
			end)
		end
	elseif invTab == "pets" then
		local pets = profile.pets or {}
		itemCount = #pets
		local teamSet: { [string]: boolean } = {}
		for _, uid in ipairs(profile.petTeam or {}) do
			teamSet[tostring(uid)] = true
		end
		for i, p in ipairs(pets) do
			local btn = Instance.new("ImageButton")
			btn.Name = "P_" .. tostring(p.uid)
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 50
			btn.Parent = scroll
			local def = PetConfig.Get(p.id)
			local rar = (def and def.rarity) or p.rarity or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local iconHost = iconHostOn(btn)
			pcall(function()
				PetVisual.TryFillInventoryIcon(iconHost, p.id, 44)
			end)
			if teamSet[tostring(p.uid)] then
				markDot(btn, Rarity.Of(rar))
			end
			local name = (def and def.name) or tostring(p.id)
			local mult = (def and def.powerMult) or 1
			local lv = p.level or 1
			wireHover(btn, function()
				return {
					{ if teamSet[tostring(p.uid)] then "ON TEAM" else "PET", "gold", 18 },
					{ name, "purple", 24 },
					{ rar, "gray", 17 },
					{ string.format("POWER: ×%.2f", mult), "purple", 17 },
					{ string.format("LEVEL: %d", lv), "gray", 17 },
				}
			end, function()
				if teamSet[tostring(p.uid)] then
					Net.UnequipPet(p.uid)
				else
					Net.EquipPet(p.uid)
				end
				args.onRefresh()
			end)
		end
	elseif invTab == "auras" then
		local auras = profile.auras or {}
		itemCount = #auras
		for i, a in ipairs(auras) do
			local btn = Instance.new("ImageButton")
			btn.Name = "A_" .. tostring(a.uid or a.id or i)
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 50
			btn.Parent = scroll
			local aid = a.id or a.uid
			local resolved = AuraConfig.ResolveId(tostring(aid))
			local def = AuraConfig.Get(resolved)
			local rar = (def and def.rarity) or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local iconHost = iconHostOn(btn)
			pcall(function()
				AuraVisual.TryFillInventoryIcon(iconHost, resolved, 44)
			end)
			local equipped = profile.equippedAura == a.uid or profile.equippedAura == resolved or profile.equippedAura == aid
			if equipped then
				markDot(btn, Rarity.Of(rar))
			end
			local name = (def and def.name) or tostring(aid)
			local powerPct = (def and def.powerPct) or 0
			wireHover(btn, function()
				return {
					{ if equipped then "EQUIPPED" else "AURA", "gold", 18 },
					{ name, "purple", 24 },
					{ rar, "gray", 17 },
					{ string.format("POWER: +%d%%", powerPct), "purple", 17 },
				}
			end, function()
				if equipped then
					Net.UnequipAura()
				else
					Net.EquipAura(a.uid or a.id)
				end
				args.onRefresh()
			end)
		end
	elseif invTab == "relics" then
		local relics = profile.relics or {}
		itemCount = #relics
		for i, r in ipairs(relics) do
			local btn = Instance.new("ImageButton")
			btn.Name = "R_" .. tostring(r.uid or i)
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 50
			btn.Parent = scroll
			local def = RelicConfig.Get(r.id)
			local rar = (def and def.rarity) or r.rarity or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local iconHost = iconHostOn(btn)
			-- placeholder glyph if no relic visual helper
			local gl = Instance.new("TextLabel")
			gl.BackgroundTransparency = 1
			gl.Size = UDim2.fromScale(1, 1)
			gl.Text = "◆"
			gl.TextScaled = true
			gl.TextColor3 = Color3.fromRGB(220, 200, 255)
			gl.Font = Enum.Font.GothamBold
			gl.ZIndex = 51
			gl.Parent = iconHost
			local name = (def and def.name) or tostring(r.id)
			wireHover(btn, function()
				return {
					{ "RELIC", "gold", 18 },
					{ name, "purple", 24 },
					{ rar, "gray", 17 },
				}
			end, function()
				Net.EquipRelic(r.uid)
				args.onRefresh()
			end)
		end
	elseif invTab == "items" then
		local POTIONS = {
			{ id = "SmallCoin", name = "Small Coin Potion", desc = "+25% Coins (10m)" },
			{ id = "MidCoin", name = "Mid Coin Potion", desc = "+50% Coins (20m)" },
			{ id = "BigCoin", name = "Big Coin Potion", desc = "+100% Coins (30m)" },
			{ id = "SmallPower", name = "Small Power Potion", desc = "+25% Power (10m)" },
			{ id = "MidPower", name = "Mid Power Potion", desc = "+50% Power (20m)" },
			{ id = "BigPower", name = "Big Power Potion", desc = "+100% Power (30m)" },
			{ id = "SmallDamage", name = "Small Damage Potion", desc = "+25% Damage (10m)" },
			{ id = "MidDamage", name = "Mid Damage Potion", desc = "+50% Damage (20m)" },
			{ id = "BigDamage", name = "Big Damage Potion", desc = "+100% Damage (30m)" },
			{ id = "SmallLuck", name = "Small Luck Potion", desc = "+25% Luck (10m)" },
			{ id = "MidLuck", name = "Mid Luck Potion", desc = "+50% Luck (20m)" },
			{ id = "BigLuck", name = "Big Luck Potion", desc = "+100% Luck (30m)" },
		}
		itemCount = #POTIONS
		for i, pot in ipairs(POTIONS) do
			local btn = Instance.new("ImageButton")
			btn.Name = "Pot_" .. pot.id
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 50
			btn.Parent = scroll
			btn.Image = InventoryAssetConfig.GetSlotFrame("Common")
			btn.ScaleType = Enum.ScaleType.Stretch
			local iconHost = iconHostOn(btn)
			local gl = Instance.new("TextLabel")
			gl.BackgroundTransparency = 1
			gl.Size = UDim2.fromScale(1, 1)
			gl.Text = "🧪"
			gl.TextScaled = true
			gl.ZIndex = 51
			gl.Parent = iconHost
			wireHover(btn, function()
				return {
					{ "CONSUMABLE", "gold", 18 },
					{ pot.name, "purple", 22 },
					{ pot.desc, "gray", 16 },
					{
						string.format(
							"KEYS P%d A%d · DUST %d",
							profile.petKeys or 0,
							profile.auraKeys or 0,
							profile.enchantDust or 0
						),
						"gray",
						15,
					},
				}
			end, function()
				Net.UsePotion(pot.id)
				args.onRefresh()
			end)
		end
	end

	local fillTo = math.min(48, math.max(12, math.ceil(math.max(itemCount, 1) / GRID_COLS) * GRID_COLS))
	for i = itemCount + 1, fillTo do
		emptySlot(i)
	end
end

return InventoryWeaponsLayout
