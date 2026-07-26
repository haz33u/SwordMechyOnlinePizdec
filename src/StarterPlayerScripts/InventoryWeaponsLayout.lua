--!strict
--[[
	Inventory UI — MechyForge brief (1920×1080 scale).
	Chrome positions = canvas UDim2 from MechyUI_AI_Brief.md.
	Assets via InventoryAssetConfig.
	Tabs: weapons | pets | auras | relics | items | shop (no profile/settings).
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

-- Client-side lock set (Ctrl+MMB). Visual: LOCKED in tooltip only.
local lockedUids: { [string]: boolean } = {}

-- Brief canvas UDim2: { posX, posY, sizeX, sizeY } scale on 1920×1080
local B = {
	MAINBACKGROUD = { 0.0609, 0.0324, 0.8052, 0.938 },
	BG_WeaponGrid = { 0.3214, 0.1667, 0.5323, 0.7769 },
	BTN_Close_3 = { 0.7984, 0.0593, 0.0547, 0.1 },
	EQUIPMENTbackground = { 0.0729, 0.1574, 0.2589, 0.4102 },
	Divider_3_Minimal_1 = { 0.3344, 0.1093, 0.45, 0.0796 },
	AURAcard = { 0.163, 0.1741, 0.076, 0.1352 },
	EQUIPbestFORdamageBUTTON = { 0.112, 0.6574, 0.1724, 0.1019 },
	EQUIPbestFORpowerBUTTON = { 0.113, 0.5611, 0.1698, 0.1009 },
	MAINswordCARD = { 0.0901, 0.1704, 0.0776, 0.138 },
	SECONDswordCARD = { 0.2359, 0.1741, 0.0771, 0.137 },
	PETcard1 = { 0.0922, 0.3111, 0.0557, 0.0991 },
	PETcard2 = { 0.1453, 0.3102, 0.0563, 0.1 },
	PETcard3 = { 0.2021, 0.3093, 0.0563, 0.1 },
	PETcard4 = { 0.2562, 0.3093, 0.0563, 0.1 },
	WEAPONSBUTTON = { 0.8677, 0.0111, 0.0885, 0.1574 },
	PETCBUTTON = { 0.8677, 0.1759, 0.0885, 0.1574 },
	AURABUTTON = { 0.8677, 0.3389, 0.0885, 0.1574 },
	RELICBUTTON = { 0.8667, 0.5037, 0.0885, 0.1574 },
	CONSUMABLESBUTTON = { 0.8667, 0.6685, 0.0885, 0.1574 },
	SHOPBUTTON = { 0.8677, 0.8287, 0.0885, 0.1574 },
	PRESETcard1 = { 0.0786, 0.8278, 0.0625, 0.1111 },
	PRESETcard2 = { 0.1385, 0.8287, 0.0625, 0.1111 },
	PRESETcard3 = { 0.1974, 0.8269, 0.0625, 0.1111 },
	PRESETcard4 = { 0.2562, 0.8278, 0.0625, 0.1111 },
	RELICcard1 = { 0.0891, 0.413, 0.0776, 0.138 },
	PRESETSbutton = { 0.1135, 0.7593, 0.1734, 0.0769 },
	RELICcard2 = { 0.162, 0.413, 0.0776, 0.138 },
	RELICcard3 = { 0.238, 0.413, 0.0776, 0.138 },
	btn_neutral_2_1 = { 0.5734, 0.0602, 0.2208, 0.0815 },
	mousebind1 = { 0.3354, 0.1037, 0.1182, 0.0556 },
	mousebind2 = { 0.5026, 0.0574, 0.0682, 0.0463 },
	mousebind3 = { 0.45, 0.0898, 0.1255, 0.0574 },
	unequip = { 0.3828, 0.0593, 0.1083, 0.0546 },
	WORDMARK_TITLE_NICK = { 0.6005, 0.0593, 0.162, 0.0806 },
	TitleCard = { 0.0245, 0.0019, 0.3005, 0.1815 },
	-- Sell mode: same slots as equip-best buttons
	SELLbutton = { 0.112, 0.6574, 0.1724, 0.1019 },
	SELLallUNLOCKED = { 0.113, 0.5611, 0.1698, 0.1009 },
}

-- Slice centers from brief (source image px)
local SLICE: { [string]: Rect } = {
	BG_WeaponGrid = Rect.new(1177, 1177, 6422, 4175),
	BTN_Close_3 = Rect.new(101, 101, 360, 370),
	EQUIPMENTbackground = Rect.new(442, 442, 1569, 2611),
	AURAcard = Rect.new(122, 122, 431, 431),
	MAINswordCARD = Rect.new(179, 179, 633, 633),
	SECONDswordCARD = Rect.new(179, 179, 633, 633),
	PETcard1 = Rect.new(89, 89, 317, 317),
	PETcard2 = Rect.new(89, 89, 317, 317),
	PETcard3 = Rect.new(89, 89, 317, 317),
	PETcard4 = Rect.new(89, 89, 317, 317),
	WEAPONSBUTTON = Rect.new(209, 209, 741, 741),
	PETCBUTTON = Rect.new(209, 209, 741, 741),
	AURABUTTON = Rect.new(209, 209, 741, 741),
	RELICBUTTON = Rect.new(209, 209, 741, 741),
	CONSUMABLESBUTTON = Rect.new(209, 209, 741, 741),
	SHOPBUTTON = Rect.new(209, 209, 741, 741),
	PRESETcard1 = Rect.new(110, 110, 389, 389),
	PRESETcard2 = Rect.new(110, 110, 392, 392),
	PRESETcard3 = Rect.new(112, 112, 395, 395),
	PRESETcard4 = Rect.new(114, 114, 403, 403),
	RELICcard1 = Rect.new(122, 122, 431, 431),
	RELICcard2 = Rect.new(122, 122, 431, 431),
	RELICcard3 = Rect.new(122, 122, 431, 431),
}

local TITLE_CARD: { [string]: string } = {
	weapons = "INVENTORYWEAPONcard",
	pets = "PETScard",
	auras = "AURAScard",
	relics = "RELICcard",
	items = "CONSUMABLEScard",
	shop = "SHOPcard",
}

local SIDE_TABS = {
	{ id = "weapons", key = "WEAPONSBUTTON", box = B.WEAPONSBUTTON },
	{ id = "pets", key = "PETCBUTTON", box = B.PETCBUTTON },
	{ id = "auras", key = "AURABUTTON", box = B.AURABUTTON },
	{ id = "relics", key = "RELICBUTTON", box = B.RELICBUTTON },
	{ id = "items", key = "CONSUMABLESBUTTON", box = B.CONSUMABLESBUTTON },
	{ id = "shop", key = "SHOPBUTTON", box = B.SHOPBUTTON },
}

local function art(key: string): string
	return InventoryAssetConfig.Get(key)
end

local function place(
	parent: Instance,
	name: string,
	assetKey: string,
	box: { number },
	z: number,
	isBtn: boolean?,
	useSlice: boolean?
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
	-- Studio Luau: avoid `;(x :: any).Prop` / ambiguous `(x :: any).Prop =` forms
	local gi = i :: any
	gi.Image = art(assetKey)
	if useSlice and SLICE[assetKey] then
		gi.ScaleType = Enum.ScaleType.Slice
		gi.SliceCenter = SLICE[assetKey]
	elseif useSlice and SLICE[name] then
		gi.ScaleType = Enum.ScaleType.Slice
		gi.SliceCenter = SLICE[name]
	else
		gi.ScaleType = Enum.ScaleType.Stretch
	end
	i.Position = UDim2.fromScale(box[1], box[2])
	i.Size = UDim2.fromScale(box[3], box[4])
	i.ZIndex = z
	i.Parent = parent
	return i
end

local function tipLine(parent: Instance, order: number, text: string, grad: string?, h: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = "T" .. order
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -16, 0, h or 20)
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
	local p: Instance? = parent
	while p and not p:IsA("ScreenGui") do
		p = p.Parent
	end
	if p then
		wipe(p)
		local deep = p:FindFirstChild(ROOT_NAME, true)
		if deep then
			deep:Destroy()
		end
	end
end

function InventoryWeaponsLayout.Render(parent: Frame, args: RenderArgs)
	InventoryWeaponsLayout.Destroy(parent)

	local profile = args.profile
	local invTab = args.invTab or "weapons"
	if TITLE_CARD[invTab] == nil and invTab ~= "shop" then
		invTab = "weapons"
	end

	local sellMode = false
	local selectedSellUid: string? = nil

	local mountTo: Instance = parent
	do
		local p: Instance? = parent
		while p do
			if p:IsA("GuiObject") and p.Name == "weapons" then
				mountTo = p
			end
			p = p.Parent
		end
	end
	if mountTo:IsA("GuiObject") then
		local g = mountTo :: GuiObject
		g.ClipsDescendants = false
		g.BackgroundTransparency = 1
		g.BorderSizePixel = 0
	end
	-- strip leftover window strokes
	for _, ch in mountTo:GetDescendants() do
		if ch:IsA("UIStroke") and ch.Parent and ch.Parent.Name ~= "Tooltip" then
			local par = ch.Parent
			if par:IsA("GuiObject") and (par.Name == "weapons" or par.Name == "Body" or par.Name == "Header" or par.Name == "InvCanvas") then
				ch:Destroy()
			end
		end
	end
	local invCanvas = mountTo:FindFirstChild("InvCanvas", true)
	if invCanvas and invCanvas:IsA("GuiObject") then
		invCanvas.Visible = false
	end

	local host = Instance.new("Frame")
	host.Name = ROOT_NAME
	host.BackgroundTransparency = 1
	host.BorderSizePixel = 0
	host.Size = UDim2.fromScale(1, 1)
	host.Position = UDim2.fromScale(0, 0)
	host.ClipsDescendants = false
	host.ZIndex = 200
	host.Parent = mountTo

	---------------------------------------------------------------- MAINBACKGROUD (center of inventory)
	local mainBg = place(host, "MAINBACKGROUD", "MAINBACKGROUD", B.MAINBACKGROUD, 1, false, false)
	-- Slight vertical nudge down (center X unchanged — canvas already places it)
	mainBg.Position = UDim2.fromScale(B.MAINBACKGROUD[1], B.MAINBACKGROUD[2] + 0.012)

	---------------------------------------------------------------- chrome
	place(host, "EQUIPMENTbackground", "EQUIPMENTbackground", B.EQUIPMENTbackground, 4, false, true)
	place(host, "Divider", "Divider_3_Minimal_1", B.Divider_3_Minimal_1, 5, false, false)
	place(host, "btn_neutral_2_1", "btn_neutral_2_1", B.btn_neutral_2_1, 32, false, false)
	place(host, "mousebind1", "mousebind1", B.mousebind1, 32, false, false)
	place(host, "mousebind2", "mousebind2", B.mousebind2, 33, false, false)
	place(host, "mousebind3", "mousebind3", B.mousebind3, 34, false, false)
	place(host, "unequip", "unequip", B.unequip, 35, false, false)
	place(host, "PRESETSbutton", "WORDMARK_presets__click_to_equip_1", B.PRESETSbutton, 28, false, false)
	for i = 1, 4 do
		place(host, "PRESETcard" .. i, "PRESETcard" .. i, B["PRESETcard" .. i], 24 + i, true, true)
	end

	local titleArt = TITLE_CARD[invTab] or "INVENTORYWEAPONcard"
	place(host, "TitleCard", titleArt, B.TitleCard, 99, false, false)

	local closeBtn = place(host, "BTN_Close_3", "BTN_Close_3", B.BTN_Close_3, 80, true, true) :: ImageButton
	closeBtn.MouseButton1Click:Connect(args.onClose)

	-- Title | Nick
	local nickPlate = place(host, "WORDMARK_TITLE_NICK", "WORDMARK_TITLE_NICK_1_1", B.WORDMARK_TITLE_NICK, 98, false, false)
	local nickLab = Instance.new("TextLabel")
	nickLab.BackgroundTransparency = 1
	nickLab.Size = UDim2.fromScale(0.92, 0.7)
	nickLab.Position = UDim2.fromScale(0.5, 0.5)
	nickLab.AnchorPoint = Vector2.new(0.5, 0.5)
	local titleTxt = (profile and (profile.equippedTitle or profile.title)) or "TITLE"
	local nickTxt = (Players.LocalPlayer and Players.LocalPlayer.Name) or "PLAYER"
	nickLab.Text = string.upper(tostring(titleTxt) .. " | " .. tostring(nickTxt))
	nickLab.ZIndex = 99
	nickLab.Parent = nickPlate
	UIKit.StyleText(nickLab, "gold", 2)

	---------------------------------------------------------------- equipment slots
	local function fillPlate(name: string, assetKey: string, box: { number }, z: number): GuiObject
		return place(host, name, assetKey, box, z, false, true)
	end

	local function iconHost(parent: GuiObject, scale: number?): Frame
		local vp = Instance.new("Frame")
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(scale or 0.72, scale or 0.72)
		vp.Position = UDim2.fromScale(0.5, 0.5)
		vp.AnchorPoint = Vector2.new(0.5, 0.5)
		vp.ZIndex = parent.ZIndex + 1
		vp.Active = false
		vp.Parent = parent
		return vp
	end

	---------------------------------------------------------------- tooltip system (gear + consumable)
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Size = UDim2.fromOffset(280, 170)
	tip.ZIndex = 500
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
			if c:IsA("TextLabel") then
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
		local tipW, tipH = math.max(tip.AbsoluteSize.X, 260), math.max(tip.AbsoluteSize.Y, 150)
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

	local function showLines(lines: { any }, size: Vector2?)
		clearTip()
		if size then
			tip.Size = UDim2.fromOffset(size.X, size.Y)
		end
		for i, row in ipairs(lines) do
			tipLine(tipBody, i, tostring(row[1]), if type(row[2]) == "string" then row[2] :: string else "purple", if type(row[3]) == "number" then row[3] :: number else 18)
		end
		tip.Visible = true
		task.defer(placeTip)
		placeTip()
	end

	-- Gear tooltip: name, rarity, where equipped, stat, sell, lvl (+ LOCKED)
	local function showGearTip(name: string, rarity: string?, where: string?, stat: string?, sell: number?, level: number?, locked: boolean?)
		local lines: { any } = {}
		if locked then
			table.insert(lines, { "LOCKED", "gold", 18 })
		end
		table.insert(lines, { name, "purple", 22 })
		if rarity then
			table.insert(lines, { rarity, "gray", 16 })
		end
		if where and where ~= "" then
			table.insert(lines, { where, "gold", 16 })
		end
		if stat then
			table.insert(lines, { stat, "purple", 16 })
		end
		if sell ~= nil then
			table.insert(lines, { string.format("SELL PRICE: %d", sell), "gold", 16 })
		end
		if level ~= nil then
			table.insert(lines, { string.format("LVL %d", level), "gray", 16 })
		end
		showLines(lines, Vector2.new(280, 175))
	end

	-- Consumable tooltip: name, rarity, qty, effect, duration
	local function showConsumableTip(name: string, rarity: string?, qty: string?, effect: string?, duration: string?)
		local lines: { any } = {
			{ name, "purple", 22 },
		}
		if rarity then
			table.insert(lines, { rarity, "gray", 16 })
		end
		if qty then
			table.insert(lines, { qty, "gold", 16 })
		end
		if effect then
			table.insert(lines, { effect, "purple", 16 })
		end
		if duration then
			table.insert(lines, { duration, "gray", 16 })
		end
		showLines(lines, Vector2.new(260, 155))
	end

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible then
			placeTip()
		end
	end)

	local function bindHover(gui: GuiObject, builder: () -> (), onClick: (() -> ())?)
		gui.Active = true
		local sc = Instance.new("UIScale")
		sc.Parent = gui
		gui.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = HOVER_SCALE }):Play()
			builder()
		end)
		gui.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
			hideTip()
		end)
		if onClick and gui:IsA("GuiButton") then
			gui.MouseButton1Click:Connect(onClick)
		elseif onClick then
			-- ImageLabel: use InputBegan
			gui.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					onClick()
				end
			end)
		end
	end

	-- Main / offhand swords
	do
		local plate = fillPlate("MAINswordCARD", "MAINswordCARD", B.MAINswordCARD, 10)
		local vp = iconHost(plate)
		local matched: any = nil
		if profile.equippedMain then
			for _, w in ipairs(profile.weapons or {}) do
				if w.uid == profile.equippedMain then
					matched = w
					pcall(function()
						WeaponModels.TryFillInventoryIcon(vp, w.id, 48)
					end)
					break
				end
			end
		end
		bindHover(plate, function()
			if not matched then
				showGearTip("Empty Slot", nil, "Equipped Main", nil, nil, nil, false)
				return
			end
			local def = WeaponConfig.Get(matched.id)
			showGearTip(
				(def and def.name) or WeaponConfig.GetDisplayName(matched.id),
				(def and def.rarity) or "Common",
				"Equipped Main",
				string.format("POWER: ×%.2f", (def and def.powerMult) or 1),
				(def and def.sellPrice) or 5,
				matched.level or 1,
				lockedUids[tostring(matched.uid)] == true
			)
		end)
	end
	do
		local plate = fillPlate("SECONDswordCARD", "SECONDswordCARD", B.SECONDswordCARD, 11)
		local vp = iconHost(plate)
		local matched: any = nil
		if profile.equippedOffhand then
			for _, w in ipairs(profile.weapons or {}) do
				if w.uid == profile.equippedOffhand then
					matched = w
					pcall(function()
						WeaponModels.TryFillInventoryIcon(vp, w.id, 48)
					end)
					break
				end
			end
		end
		bindHover(plate, function()
			if not matched then
				showGearTip("Empty Slot", nil, "Equipped Offhand", nil, nil, nil, false)
				return
			end
			local def = WeaponConfig.Get(matched.id)
			showGearTip(
				(def and def.name) or WeaponConfig.GetDisplayName(matched.id),
				(def and def.rarity) or "Common",
				"Equipped Offhand",
				string.format("POWER: ×%.2f", (def and def.powerMult) or 1),
				(def and def.sellPrice) or 5,
				matched.level or 1,
				lockedUids[tostring(matched.uid)] == true
			)
		end)
	end

	-- Pets 1–4 only
	local team = profile.petTeam or {}
	local petByUid: { [string]: any } = {}
	for _, p in ipairs(profile.pets or {}) do
		petByUid[tostring(p.uid)] = p
	end
	for i = 1, 4 do
		local plate = fillPlate("PETcard" .. i, "PETcard" .. i, B["PETcard" .. i], 11 + i)
		local uid = team[i]
		local pet = if uid then petByUid[tostring(uid)] else nil
		if pet then
			local vp = iconHost(plate, 0.78)
			pcall(function()
				PetVisual.TryFillInventoryIcon(vp, pet.id, 36)
			end)
		end
		bindHover(plate, function()
			if not pet then
				showGearTip("Empty Slot", nil, "Pet Slot " .. i, nil, nil, nil, false)
				return
			end
			local def = PetConfig.Get(pet.id)
			showGearTip(
				(def and def.name) or tostring(pet.id),
				(def and def.rarity) or "Common",
				"On Team · Slot " .. i,
				string.format("POWER: ×%.2f", (def and def.powerMult) or 1),
				nil,
				pet.level or 1,
				false
			)
		end)
	end

	-- Relics + Aura
	for i = 1, 3 do
		local plate = fillPlate("RELICcard" .. i, "RELICcard" .. i, B["RELICcard" .. i], 26 + i)
		bindHover(plate, function()
			showGearTip("Empty Slot", nil, "Relic Slot " .. i, nil, nil, nil, false)
		end)
	end
	do
		local plate = fillPlate("AURAcard", "RELICcard1", B.AURAcard, 7)
		local auraId = profile.equippedAura
		if auraId then
			local vp = iconHost(plate, 0.8)
			pcall(function()
				AuraVisual.TryFillInventoryIcon(vp, auraId, 40)
			end)
		end
		bindHover(plate, function()
			if not auraId then
				showGearTip("Empty Slot", nil, "Equipped Aura", nil, nil, nil, false)
				return
			end
			local resolved = AuraConfig.ResolveId(tostring(auraId))
			local def = AuraConfig.Get(resolved)
			showGearTip(
				(def and def.name) or tostring(auraId),
				(def and def.rarity) or "Common",
				"Equipped Aura",
				string.format("POWER: +%d%%", (def and def.powerPct) or 0),
				nil,
				nil,
				false
			)
		end)
	end

	---------------------------------------------------------------- Equip best / Sell mode buttons
	local bestDmg = place(host, "EQUIPbestFORdamageBUTTON", "EQUIPbestFORdamageBUTTON", B.EQUIPbestFORdamageBUTTON, 8, true, false) :: ImageButton
	local bestPow = place(host, "EQUIPbestFORpowerBUTTON", "EQUIPbestFORpowerBUTTON", B.EQUIPbestFORpowerBUTTON, 9, true, false) :: ImageButton
	local sellBtn = place(host, "SELLbutton", "SELLbutton", B.SELLbutton, 8, true, false) :: ImageButton
	local sellAllBtn = place(host, "SELLallUNLOCKEDbutton", "SELLallUNLOCKEDbutton", B.SELLallUNLOCKED, 9, true, false) :: ImageButton
	sellBtn.Visible = false
	sellAllBtn.Visible = false

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

	bestDmg.MouseButton1Click:Connect(function()
		local ranked = rankWeapons()
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		args.onRefresh()
	end)
	bestPow.MouseButton1Click:Connect(function()
		local ranked = rankWeapons()
		if ranked[1] then
			Net.EquipWeapon(ranked[1].uid, "main")
		end
		if ranked[2] then
			Net.EquipWeapon(ranked[2].uid, "offhand")
		end
		args.onRefresh()
	end)

	local function setSellMode(on: boolean)
		sellMode = on
		bestDmg.Visible = not on
		bestPow.Visible = not on
		sellBtn.Visible = on
		sellAllBtn.Visible = on
		if not on then
			selectedSellUid = nil
		end
	end

	sellBtn.MouseButton1Click:Connect(function()
		if selectedSellUid and not lockedUids[tostring(selectedSellUid)] then
			Net.SellWeapon(selectedSellUid)
			selectedSellUid = nil
			args.onRefresh()
		end
	end)
	sellAllBtn.MouseButton1Click:Connect(function()
		for _, w in ipairs(profile.weapons or {}) do
			if not lockedUids[tostring(w.uid)] and profile.equippedMain ~= w.uid and profile.equippedOffhand ~= w.uid then
				Net.SellWeapon(w.uid)
			end
		end
		setSellMode(false)
		args.onRefresh()
	end)

	---------------------------------------------------------------- side tabs (6 — no profile/settings)
	for _, def in ipairs(SIDE_TABS) do
		local btn = place(host, def.id .. "Tab", def.key, def.box, 16, true, true) :: ImageButton
		btn.ImageTransparency = if def.id == invTab then 0 else 0.22
		btn.MouseButton1Click:Connect(function()
			if def.id == invTab then
				return
			end
			if sellMode then
				setSellMode(false)
			end
			args.onTab(def.id)
		end)
	end

	---------------------------------------------------------------- WeaponGrid — cards NEVER leave bounds
	local gridHost = Instance.new("Frame")
	gridHost.Name = "BG_WeaponGrid"
	gridHost.BackgroundTransparency = 1
	gridHost.Position = UDim2.fromScale(B.BG_WeaponGrid[1], B.BG_WeaponGrid[2])
	gridHost.Size = UDim2.fromScale(B.BG_WeaponGrid[3], B.BG_WeaponGrid[4])
	gridHost.ClipsDescendants = true -- hard rule
	gridHost.ZIndex = 2
	gridHost.Parent = host

	local gridBg = Instance.new("ImageLabel")
	gridBg.BackgroundTransparency = 1
	gridBg.Image = art("BG_WeaponGrid")
	gridBg.ScaleType = Enum.ScaleType.Slice
	gridBg.SliceCenter = SLICE.BG_WeaponGrid
	gridBg.Size = UDim2.fromScale(1, 1)
	gridBg.ZIndex = 2
	gridBg.Parent = gridHost

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(0.93, 0.88)
	scroll.Position = UDim2.fromScale(0.035, 0.07)
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 140, 255)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ClipsDescendants = true
	scroll.ZIndex = 3
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
		local pad = math.max(3, math.floor(w * 0.0045))
		grid.CellPadding = UDim2.fromOffset(pad, pad)
		local cell = math.floor((w - pad * (GRID_COLS - 1)) / GRID_COLS)
		cell = math.max(40, cell)
		grid.CellSize = UDim2.fromOffset(cell, cell)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)
	task.delay(0.05, relayout)

	local function emptySlot(order: number)
		local btn = Instance.new("ImageButton")
		btn.Name = "Empty_" .. order
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.ZIndex = 4
		btn.Image = InventoryAssetConfig.GetSlotFrame("Empty")
		btn.ScaleType = Enum.ScaleType.Stretch
		btn.Parent = scroll
	end

	local function makeIconHost(btn: GuiObject): Frame
		local iconHost = Instance.new("Frame")
		iconHost.BackgroundTransparency = 1
		iconHost.Size = UDim2.fromScale(0.78, 0.78)
		iconHost.Position = UDim2.fromScale(0.5, 0.5)
		iconHost.AnchorPoint = Vector2.new(0.5, 0.5)
		iconHost.ZIndex = 5
		iconHost.Active = false
		iconHost.Parent = btn
		return iconHost
	end

	local itemCount = 0

	---------------------------------------------------------------- WEAPONS grid
	if invTab == "weapons" then
		local weapons = profile.weapons or {}
		itemCount = #weapons
		for i, w in ipairs(weapons) do
			local btn = Instance.new("ImageButton")
			btn.Name = "W_" .. w.uid
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 4
			btn.Parent = scroll
			local def = WeaponConfig.Get(w.id)
			local rar = (def and def.rarity) or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local ih = makeIconHost(btn)
			local used = false
			pcall(function()
				used = WeaponModels.TryFillInventoryIcon(ih, w.id, 48) == true
			end)
			if not used and IconConfig.HasWeaponImage(w.id) then
				local ic = Instance.new("ImageLabel")
				ic.BackgroundTransparency = 1
				ic.Size = UDim2.fromScale(1, 1)
				ic.Image = IconConfig.GetWeaponImage(w.id)
				ic.ScaleType = Enum.ScaleType.Fit
				ic.ZIndex = 5
				ic.Parent = ih
			end
			if profile.equippedMain == w.uid or profile.equippedOffhand == w.uid then
				local mark = Instance.new("Frame")
				mark.Size = UDim2.fromOffset(10, 10)
				mark.Position = UDim2.fromOffset(6, 6)
				mark.BackgroundColor3 = Rarity.Of(rar)
				mark.BorderSizePixel = 0
				mark.ZIndex = 6
				mark.Parent = btn
				UIKit.Corner(mark, 99)
			end

			local name = (def and def.name) or WeaponConfig.GetDisplayName(w.id)
			local mult = (def and def.powerMult) or 1
			local sellP = (def and def.sellPrice) or 5
			local lv = w.level or 1
			local sc = Instance.new("UIScale")
			sc.Parent = btn

			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = HOVER_SCALE }):Play()
				local where = ""
				if profile.equippedMain == w.uid then
					where = "Equipped Main"
				elseif profile.equippedOffhand == w.uid then
					where = "Equipped Offhand"
				end
				showGearTip(name, rar, where, string.format("POWER: ×%.2f", mult), sellP, lv, lockedUids[tostring(w.uid)] == true)
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
				hideTip()
			end)

			-- LMB: equip/unequip chain
			btn.MouseButton1Click:Connect(function()
				if sellMode then
					if lockedUids[tostring(w.uid)] then
						return
					end
					selectedSellUid = w.uid
					return
				end
				if profile.equippedMain == w.uid then
					-- already main → try offhand if empty
					if not profile.equippedOffhand then
						Net.EquipWeapon(w.uid, "offhand")
					end
					-- if both slots occupied with this as main, leave as is (unequip not exposed)
				elseif profile.equippedOffhand == w.uid then
					-- already offhand → promote to main
					Net.EquipWeapon(w.uid, "main")
				else
					if not profile.equippedMain then
						Net.EquipWeapon(w.uid, "main")
					elseif not profile.equippedOffhand then
						Net.EquipWeapon(w.uid, "offhand")
					else
						Net.EquipWeapon(w.uid, "main")
					end
				end
				args.onRefresh()
			end)

			-- RMB: enter sell mode
			btn.MouseButton2Click:Connect(function()
				setSellMode(true)
				if not lockedUids[tostring(w.uid)] then
					selectedSellUid = w.uid
				end
			end)

			-- MMB: merge; Ctrl+MMB: lock toggle
			btn.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
					return
				end
				local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				if ctrl then
					local key = tostring(w.uid)
					lockedUids[key] = not lockedUids[key]
					-- refresh tip if hovering
					local where = ""
					if profile.equippedMain == w.uid then
						where = "Equipped Main"
					elseif profile.equippedOffhand == w.uid then
						where = "Equipped Offhand"
					end
					showGearTip(name, rar, where, string.format("POWER: ×%.2f", mult), sellP, lv, lockedUids[key] == true)
				else
					Net.MergeWeapon(w.uid)
					args.onRefresh()
				end
			end)
		end

	---------------------------------------------------------------- PETS
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
			btn.ZIndex = 4
			btn.Parent = scroll
			local def = PetConfig.Get(p.id)
			local rar = (def and def.rarity) or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local ih = makeIconHost(btn)
			pcall(function()
				PetVisual.TryFillInventoryIcon(ih, p.id, 44)
			end)
			if teamSet[tostring(p.uid)] then
				local mark = Instance.new("Frame")
				mark.Size = UDim2.fromOffset(10, 10)
				mark.Position = UDim2.fromOffset(6, 6)
				mark.BackgroundColor3 = Rarity.Of(rar)
				mark.BorderSizePixel = 0
				mark.ZIndex = 6
				mark.Parent = btn
				UIKit.Corner(mark, 99)
			end
			local sc = Instance.new("UIScale")
			sc.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = HOVER_SCALE }):Play()
				showGearTip(
					(def and def.name) or tostring(p.id),
					rar,
					if teamSet[tostring(p.uid)] then "On Team" else "In Bag",
					string.format("POWER: ×%.2f", (def and def.powerMult) or 1),
					nil,
					p.level or 1,
					false
				)
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
				hideTip()
			end)
			btn.MouseButton1Click:Connect(function()
				if teamSet[tostring(p.uid)] then
					Net.UnequipPet(p.uid)
				else
					Net.EquipPet(p.uid)
				end
				args.onRefresh()
			end)
		end

	---------------------------------------------------------------- AURAS
	elseif invTab == "auras" then
		local auras = profile.auras or {}
		itemCount = #auras
		for i, a in ipairs(auras) do
			local btn = Instance.new("ImageButton")
			btn.Name = "A_" .. tostring(a.uid or a.id or i)
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 4
			btn.Parent = scroll
			local aid = a.id or a.uid
			local resolved = AuraConfig.ResolveId(tostring(aid))
			local def = AuraConfig.Get(resolved)
			local rar = (def and def.rarity) or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local ih = makeIconHost(btn)
			pcall(function()
				AuraVisual.TryFillInventoryIcon(ih, resolved, 44)
			end)
			local equipped = profile.equippedAura == a.uid or profile.equippedAura == resolved or profile.equippedAura == aid
			local sc = Instance.new("UIScale")
			sc.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = HOVER_SCALE }):Play()
				showGearTip(
					(def and def.name) or tostring(aid),
					rar,
					if equipped then "Equipped Aura" else "In Bag",
					string.format("POWER: +%d%%", (def and def.powerPct) or 0),
					nil,
					nil,
					false
				)
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
				hideTip()
			end)
			btn.MouseButton1Click:Connect(function()
				if equipped then
					Net.UnequipAura()
				else
					Net.EquipAura(a.uid or a.id)
				end
				args.onRefresh()
			end)
		end

	---------------------------------------------------------------- RELICS
	elseif invTab == "relics" then
		local relics = profile.relics or {}
		itemCount = #relics
		for i, r in ipairs(relics) do
			local btn = Instance.new("ImageButton")
			btn.Name = "R_" .. tostring(r.uid or i)
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 4
			btn.Parent = scroll
			local def = RelicConfig.Get(r.id)
			local rar = (def and def.rarity) or r.rarity or "Common"
			btn.Image = InventoryAssetConfig.GetSlotFrame(rar)
			btn.ScaleType = Enum.ScaleType.Stretch
			local ih = makeIconHost(btn)
			local gl = Instance.new("TextLabel")
			gl.BackgroundTransparency = 1
			gl.Size = UDim2.fromScale(1, 1)
			gl.Text = "◆"
			gl.TextScaled = true
			gl.TextColor3 = Color3.fromRGB(220, 200, 255)
			gl.Font = Enum.Font.GothamBold
			gl.ZIndex = 5
			gl.Parent = ih
			local sc = Instance.new("UIScale")
			sc.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = HOVER_SCALE }):Play()
				showGearTip((def and def.name) or tostring(r.id), rar, "Relic", nil, nil, nil, false)
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
				hideTip()
			end)
			btn.MouseButton1Click:Connect(function()
				Net.EquipRelic(r.uid)
				args.onRefresh()
			end)
		end

	---------------------------------------------------------------- CONSUMABLES
	elseif invTab == "items" then
		local POTIONS = {
			{ id = "SmallCoin", name = "Small Coin Potion", effect = "+25% Coins", duration = "10 min" },
			{ id = "MidCoin", name = "Mid Coin Potion", effect = "+50% Coins", duration = "20 min" },
			{ id = "BigCoin", name = "Big Coin Potion", effect = "+100% Coins", duration = "30 min" },
			{ id = "SmallPower", name = "Small Power Potion", effect = "+25% Power", duration = "10 min" },
			{ id = "MidPower", name = "Mid Power Potion", effect = "+50% Power", duration = "20 min" },
			{ id = "BigPower", name = "Big Power Potion", effect = "+100% Power", duration = "30 min" },
			{ id = "SmallDamage", name = "Small Damage Potion", effect = "+25% Damage", duration = "10 min" },
			{ id = "MidDamage", name = "Mid Damage Potion", effect = "+50% Damage", duration = "20 min" },
			{ id = "BigDamage", name = "Big Damage Potion", effect = "+100% Damage", duration = "30 min" },
			{ id = "SmallLuck", name = "Small Luck Potion", effect = "+25% Luck", duration = "10 min" },
			{ id = "MidLuck", name = "Mid Luck Potion", effect = "+50% Luck", duration = "20 min" },
			{ id = "BigLuck", name = "Big Luck Potion", effect = "+100% Luck", duration = "30 min" },
		}
		itemCount = #POTIONS
		for i, pot in ipairs(POTIONS) do
			local btn = Instance.new("ImageButton")
			btn.Name = "Pot_" .. pot.id
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 4
			btn.Parent = scroll
			btn.Image = InventoryAssetConfig.GetSlotFrame("Common")
			btn.ScaleType = Enum.ScaleType.Stretch
			local ih = makeIconHost(btn)
			local gl = Instance.new("TextLabel")
			gl.BackgroundTransparency = 1
			gl.Size = UDim2.fromScale(1, 1)
			gl.Text = "🧪"
			gl.TextScaled = true
			gl.ZIndex = 5
			gl.Parent = ih
			local sc = Instance.new("UIScale")
			sc.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = HOVER_SCALE }):Play()
				showConsumableTip(
					pot.name,
					"Common",
					string.format(
						"Qty · Pet keys %d · Aura keys %d · Dust %d",
						profile.petKeys or 0,
						profile.auraKeys or 0,
						profile.enchantDust or 0
					),
					pot.effect,
					pot.duration
				)
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
				hideTip()
			end)
			btn.MouseButton1Click:Connect(function()
				Net.UsePotion(pot.id)
				args.onRefresh()
			end)
		end
	else
		-- shop tab routes via onTab; empty grid placeholder
		itemCount = 0
	end

	local fillTo = math.min(48, math.max(12, math.ceil(math.max(itemCount, 1) / GRID_COLS) * GRID_COLS))
	for i = itemCount + 1, fillTo do
		emptySlot(i)
	end
end

return InventoryWeaponsLayout
