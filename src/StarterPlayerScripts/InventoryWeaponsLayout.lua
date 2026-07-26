--!strict
--[[
	WEAPON INVENTORY — layout anchored on MAINBACKGROUD (not outer Frame).

	host (full-screen transparent, weapons window)
	  shell (MAINBACKGROUD plate, slightly left of true center so left binds stay tight)
	    chrome remapped relative to shell (Figma → MAINBACKGROUD box)
	  Tooltip (mouse-follow)
	InvBottomTabBar on ScreenGui (never clipped) — created early so layout errors can't drop it
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
-- Binds: pure Figma relative to MAINBACKGROUD (slightly left of shell, adjacent — no extra fly-out)

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

	-- Climb to ScreenGui so bottom tabs cannot be clipped by Window/Body
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

	----------------------------------------------------------------
	-- BOTTOM TABS first (ScreenGui) — must not depend on later chrome code.
	-- Previous bug: Tooltip set ZIndexBehavior on a Frame → error → no tabs.
	----------------------------------------------------------------
	local tabParent: Instance = screenGui or host
	local tabBar = Instance.new("Frame")
	tabBar.Name = "InvBottomTabBar"
	tabBar.BackgroundColor3 = Color3.fromRGB(12, 8, 28)
	tabBar.BackgroundTransparency = 0.15
	tabBar.BorderSizePixel = 0
	tabBar.AnchorPoint = Vector2.new(0.5, 1)
	tabBar.Position = UDim2.new(0.5, 0, 1, -10)
	tabBar.Size = UDim2.new(0.92, 0, 0, 110)
	tabBar.ZIndex = 400
	tabBar.Visible = true
	tabBar.Active = true
	tabBar.Parent = tabParent
	UIKit.Corner(tabBar, 14)
	UIKit.Stroke(tabBar, Color3.fromRGB(140, 100, 255), 2, 0.3)

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabList.VerticalAlignment = Enum.VerticalAlignment.Center
	tabList.Padding = UDim.new(0, 8)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = tabBar

	for i, def in ipairs(FIGMA_TABS) do
		local b = Instance.new("ImageButton")
		b.Name = def.id .. "Tab"
		-- Dark square always visible even if image fails to load
		b.BackgroundColor3 = if def.id == "weapons"
			then Color3.fromRGB(90, 50, 150)
			else Color3.fromRGB(40, 28, 70)
		b.BackgroundTransparency = 0
		b.BorderSizePixel = 0
		b.Image = art(def.key)
		b.ScaleType = Enum.ScaleType.Fit
		b.AutoButtonColor = true
		b.Size = UDim2.fromOffset(96, 96)
		b.LayoutOrder = i
		b.ZIndex = 401
		b.Visible = true
		b.Active = true
		b.Parent = tabBar
		UIKit.Corner(b, 12)

		local lab = Instance.new("TextLabel")
		lab.Name = "Label"
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.new(1, -4, 0, 16)
		lab.Position = UDim2.new(0, 2, 1, -18)
		lab.Text = def.label
		lab.TextSize = 10
		lab.Font = Enum.Font.GothamBold
		lab.TextColor3 = Color3.fromRGB(240, 230, 255)
		lab.TextStrokeTransparency = 0.4
		lab.TextXAlignment = Enum.TextXAlignment.Center
		lab.ZIndex = 402
		lab.Parent = b

		b.MouseButton1Click:Connect(function()
			if def.id == "weapons" or def.id == "settings" then
				return
			end
			args.onTab(def.id)
		end)
	end

	----------------------------------------------------------------
	-- SHELL = MAINBACKGROUD plate
	-- Slightly left of true center (binds hang left of plate; keeps cluster tight)
	----------------------------------------------------------------
	local shell = Instance.new("Frame")
	shell.Name = "MAINBACKGROUD_Shell"
	shell.BackgroundTransparency = 1
	shell.BorderSizePixel = 0
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	-- 0.47 ≈ a bit left of screen center so left binds stay next to the plate (not floating)
	shell.Position = UDim2.fromScale(0.47, 0.48)
	shell.Size = UDim2.fromScale(0.92, 0.78)
	shell.ClipsDescendants = false
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

	pImg("INVENTORYWEAPONcard", "INVENTORYWEAPONcard", R.INVENTORYWEAPONcard, 50)
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

	local function fillWeapon(key: string, b: { number }, uid: string?)
		local plate = pImg(key, key, b, 48)
		local vp = Instance.new("Frame")
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(0.72, 0.72)
		vp.Position = UDim2.fromScale(0.5, 0.5)
		vp.AnchorPoint = Vector2.new(0.5, 0.5)
		vp.ZIndex = 49
		vp.Parent = plate
		if uid then
			for _, w in ipairs(profile.weapons or {}) do
				if w.uid == uid then
					pcall(function()
						WeaponModels.TryFillInventoryIcon(vp, w.id, 48)
					end)
					break
				end
			end
		end
	end
	fillWeapon("MAINswordCARD", R.MAINswordCARD, profile.equippedMain)
	fillWeapon("SECONDswordCARD", R.SECONDswordCARD, profile.equippedOffhand)

	local team = profile.petTeam or {}
	local petByUid: { [string]: any } = {}
	for _, p in ipairs(profile.pets or {}) do
		petByUid[tostring(p.uid)] = p
	end
	local petKeys = { "PETcard1", "PETcard2", "PETcard3", "PETcard4", "PETcard5", "PETcard6", "PETcard7", "PETcard8" }
	for i, key in ipairs(petKeys) do
		local plate = pImg(key, key, R[key], 48)
		local uid = team[i]
		if uid and petByUid[tostring(uid)] then
			local vp = Instance.new("Frame")
			vp.BackgroundTransparency = 1
			vp.Size = UDim2.fromScale(0.78, 0.78)
			vp.Position = UDim2.fromScale(0.5, 0.5)
			vp.AnchorPoint = Vector2.new(0.5, 0.5)
			vp.ZIndex = 49
			vp.Parent = plate
			pcall(function()
				PetVisual.TryFillInventoryIcon(vp, petByUid[tostring(uid)].id, 32)
			end)
		end
	end
	for i = 1, 3 do
		pImg("RELICcard" .. i, "RELICcard" .. i, R["RELICcard" .. i], 48)
	end
	do
		local aura = pImg("AURAcard", "RELICcard1", R.AURAcard, 48)
		if profile.equippedAura then
			local vp = Instance.new("Frame")
			vp.BackgroundTransparency = 1
			vp.Size = UDim2.fromScale(0.8, 0.8)
			vp.Position = UDim2.fromScale(0.5, 0.5)
			vp.AnchorPoint = Vector2.new(0.5, 0.5)
			vp.ZIndex = 49
			vp.Parent = aura
			pcall(function()
				AuraVisual.TryFillInventoryIcon(vp, profile.equippedAura, 36)
			end)
		end
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
		Net.SellAllWeapons()
		args.onRefresh()
	end)
	-- binds left of shell
	pImg("MOUSEBINDScard", "MOUSEBINDScard", R.MOUSEBINDScard, 52)

	---------------------------------------------------------------- weapon grid inside shell
	local gridHost = Instance.new("Frame")
	gridHost.Name = "BG_WeaponGrid"
	gridHost.BackgroundTransparency = 1
	gridHost.Size = UDim2.fromScale(R.BG_WeaponGrid[3], R.BG_WeaponGrid[4])
	gridHost.Position = UDim2.fromScale(R.BG_WeaponGrid[1], R.BG_WeaponGrid[2])
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

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(0.96, 0.96)
	scroll.Position = UDim2.fromScale(0.02, 0.02)
	scroll.ScrollBarThickness = 6
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

	---------------------------------------------------------------- tooltip (host-level, mouse follow)
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Size = UDim2.fromOffset(280, 168)
	tip.ZIndex = 300
	tip.Parent = host
	-- NOTE: ZIndexBehavior is ScreenGui-only — never set on Frame (crashed Render before)

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
		if not tip.Visible then
			return
		end
		local inset = GuiService:GetGuiInset()
		local mouse = UserInputService:GetMouseLocation()
		local mx, my = mouse.X - inset.X, mouse.Y - inset.Y
		local parentAbs, parentSz = host.AbsolutePosition, host.AbsoluteSize
		local tipW, tipH = math.max(tip.AbsoluteSize.X, 280), math.max(tip.AbsoluteSize.Y, 168)
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
		if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible then
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
		btn.ZIndex = 50
		btn.Parent = scroll

		local rar = "Empty"
		if w then
			local def = WeaponConfig.Get(w.id)
			rar = (def and def.rarity) or "Common"
		end
		btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
		btn.ScaleType = Enum.ScaleType.Fit

		if w then
			local iconHost = Instance.new("Frame")
			iconHost.BackgroundTransparency = 1
			iconHost.Size = UDim2.fromScale(0.72, 0.72)
			iconHost.Position = UDim2.fromScale(0.5, 0.5)
			iconHost.AnchorPoint = Vector2.new(0.5, 0.5)
			iconHost.ZIndex = 51
			iconHost.Active = false
			iconHost.Parent = btn

			local used = false
			pcall(function()
				used = WeaponModels.TryFillInventoryIcon(iconHost, w.id, 44) == true
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
				local mark = Instance.new("Frame")
				mark.Size = UDim2.fromOffset(10, 10)
				mark.Position = UDim2.fromOffset(6, 6)
				mark.BackgroundColor3 = Rarity.Of(rar)
				mark.BorderSizePixel = 0
				mark.ZIndex = 52
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
				TweenService:Create(sc, TweenInfo.new(0.12), { Scale = HOVER_SCALE }):Play()
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
	local fillTo = math.min(48, math.max(12, math.ceil(math.max(#weapons, 1) / GRID_COLS) * GRID_COLS))
	for i = #weapons + 1, fillTo do
		makeSlot(i, nil)
	end
	-- Bottom tabs already mounted at start of Render (see above).
end

return InventoryWeaponsLayout
