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
local Titles = require(script.Parent.Titles)
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
local PotionIconConfig = require(Shared.Config.PotionIconConfig)

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
	-- Divider: lower + wider, same horizontal center as brief (0.3344+0.45/2)
	Divider_3_Minimal_1 = { 0.2994, 0.125, 0.52, 0.072 },
	EQUIPbestFORdamageBUTTON = { 0.112, 0.6574, 0.1724, 0.1019 },
	EQUIPbestFORpowerBUTTON = { 0.113, 0.5611, 0.1698, 0.1009 },
	-- Uniform equipment slots (even sizes + spacing)
	MAINswordCARD = { 0.100, 0.178, 0.074, 0.110 },
	SECONDswordCARD = { 0.192, 0.178, 0.074, 0.110 },
	PETcard1 = { 0.100, 0.318, 0.054, 0.080 },
	PETcard2 = { 0.164, 0.318, 0.054, 0.080 },
	PETcard3 = { 0.228, 0.318, 0.054, 0.080 },
	PETcard4 = { 0.292, 0.318, 0.054, 0.080 },
	RELICcard1 = { 0.100, 0.428, 0.068, 0.100 },
	RELICcard2 = { 0.178, 0.428, 0.068, 0.100 },
	RELICcard3 = { 0.256, 0.428, 0.068, 0.100 },
	AURAcard = { 0.178, 0.548, 0.068, 0.100 },
	WEAPONSBUTTON = { 0.8477, 0.0111, 0.0885, 0.1574 },
	PETCBUTTON = { 0.8477, 0.1759, 0.0885, 0.1574 },
	AURABUTTON = { 0.8477, 0.3389, 0.0885, 0.1574 },
	RELICBUTTON = { 0.8467, 0.5037, 0.0885, 0.1574 },
	CONSUMABLESBUTTON = { 0.8467, 0.6685, 0.0885, 0.1574 },
	SHOPBUTTON = { 0.8477, 0.8287, 0.0885, 0.1574 },
	PRESETcard1 = { 0.100, 0.830, 0.058, 0.086 },
	PRESETcard2 = { 0.168, 0.830, 0.058, 0.086 },
	PRESETcard3 = { 0.236, 0.830, 0.058, 0.086 },
	PRESETcard4 = { 0.304, 0.830, 0.058, 0.086 },
	PRESETSbutton = { 0.1135, 0.7593, 0.1734, 0.0769 },
	btn_neutral_2_1 = { 0.5534, 0.0602, 0.2208, 0.0815 },
	mousebind1 = { 0.3154, 0.118, 0.1182, 0.0556 },
	mousebind2 = { 0.4826, 0.072, 0.0682, 0.0463 },
	mousebind3 = { 0.430, 0.104, 0.1255, 0.0574 },
	unequip = { 0.3628, 0.072, 0.1083, 0.0546 },
	TitleNickHost = { 0.5805, 0.0593, 0.182, 0.0806 },
	TitleCard = { 0.0245, 0.0019, 0.3005, 0.1815 },
	-- Sell mode: same slots as equip-best buttons
	SELLbutton = { 0.112, 0.6574, 0.1724, 0.1019 },
	SELLallUNLOCKED = { 0.113, 0.5611, 0.1698, 0.1009 },
}

-- Shift inv cluster slightly left (grid + shell chrome + tabs already shifted above)
local SHIFT_LEFT = 0.018

-- WeaponGrid: larger + stretch UP toward divider (kill visual gap under divider)
do
	local g = B.BG_WeaponGrid
	local left, right, top, bottom = 0.020, 0.028, 0.045, 0.016
	B.BG_WeaponGrid = {
		g[1] - left,
		g[2] - top,
		g[3] + left + right,
		g[4] + top + bottom,
	}
end

-- Whole inv shell nudge left (tabs already have lower X in B)
B.MAINBACKGROUD = {
	B.MAINBACKGROUD[1] - SHIFT_LEFT,
	B.MAINBACKGROUD[2],
	B.MAINBACKGROUD[3],
	B.MAINBACKGROUD[4],
}
-- Keep divider/equip/etc in shell-relative space: also shift their canvas X with shell
for _, key in ipairs({
	"Divider_3_Minimal_1",
	"EQUIPMENTbackground",
	"EQUIPbestFORdamageBUTTON",
	"EQUIPbestFORpowerBUTTON",
	"MAINswordCARD",
	"SECONDswordCARD",
	"PETcard1",
	"PETcard2",
	"PETcard3",
	"PETcard4",
	"RELICcard1",
	"RELICcard2",
	"RELICcard3",
	"AURAcard",
	"PRESETcard1",
	"PRESETcard2",
	"PRESETcard3",
	"PRESETcard4",
	"PRESETSbutton",
	"btn_neutral_2_1",
	"mousebind1",
	"mousebind2",
	"mousebind3",
	"unequip",
	"TitleNickHost",
	"TitleCard",
	"BTN_Close_3",
	"SELLbutton",
	"SELLallUNLOCKED",
	"BG_WeaponGrid",
}) do
	local b = B[key]
	if b then
		B[key] = { b[1] - SHIFT_LEFT, b[2], b[3], b[4] }
	end
end

-- NOTE: Do NOT use brief SliceCenter on our MechyForge IMAGE uploads —
-- source PNG sizes differ → Roblox Slice turns frames into circles / mush.
-- Fit = square cards/buttons keep aspect; Stretch = full-bleed plates only.

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

-- Remap canvas box → relative to MAINBACKGROUD shell (keeps layout glued to art)
local MB = B.MAINBACKGROUD
local function rel(box: { number }): { number }
	return {
		(box[1] - MB[1]) / MB[3],
		(box[2] - MB[2]) / MB[4],
		box[3] / MB[3],
		box[4] / MB[4],
	}
end

local function place(
	parent: Instance,
	name: string,
	assetKey: string,
	box: { number },
	z: number,
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
	local gi = i :: any
	gi.Image = art(assetKey)
	-- Fit = no circular slice distortion on square chrome
	gi.ScaleType = scaleType or Enum.ScaleType.Fit
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

	---------------------------------------------------------------- MAINBACKGROUD shell — all inv chrome parented here
	local mainBg = place(host, "MAINBACKGROUD", "MAINBACKGROUD", B.MAINBACKGROUD, 1, false, Enum.ScaleType.Stretch)
	-- slight down only (X from brief)
	mainBg.Position = UDim2.fromScale(MB[1], MB[2] + 0.012)

	local function pShell(
		name: string,
		assetKey: string,
		box: { number },
		z: number,
		isBtn: boolean?,
		scaleType: Enum.ScaleType?
	): GuiObject
		return place(mainBg, name, assetKey, rel(box), z, isBtn, scaleType)
	end

	---------------------------------------------------------------- chrome (relative to MAINBACKGROUD)
	pShell("EQUIPMENTbackground", "EQUIPMENTbackground", B.EQUIPMENTbackground, 4, false, Enum.ScaleType.Stretch)
	pShell("Divider", "Divider_3_Minimal_1", B.Divider_3_Minimal_1, 5, false, Enum.ScaleType.Stretch)
	pShell("btn_neutral_2_1", "btn_neutral_2_1", B.btn_neutral_2_1, 32, false, Enum.ScaleType.Stretch)
	pShell("mousebind1", "mousebind1", B.mousebind1, 32, false, Enum.ScaleType.Fit)
	pShell("mousebind2", "mousebind2", B.mousebind2, 33, false, Enum.ScaleType.Fit)
	pShell("mousebind3", "mousebind3", B.mousebind3, 34, false, Enum.ScaleType.Fit)
	pShell("unequip", "unequip", B.unequip, 35, false, Enum.ScaleType.Fit)
	pShell("PRESETSbutton", "WORDMARK_presets__click_to_equip_1", B.PRESETSbutton, 28, false, Enum.ScaleType.Fit)
	for i = 1, 4 do
		local pc = pShell("PRESETcard" .. i, "PRESETcard" .. i, B["PRESETcard" .. i], 24 + i, true, Enum.ScaleType.Fit)
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = 1
		ar.AspectType = Enum.AspectType.FitWithinMaxSize
		ar.DominantAxis = Enum.DominantAxis.Width
		ar.Parent = pc
	end

	local titleArt = TITLE_CARD[invTab] or "INVENTORYWEAPONcard"
	pShell("TitleCard", titleArt, B.TitleCard, 99, false, Enum.ScaleType.Fit)

	local closeBtn = pShell("BTN_Close_3", "BTN_Close_3", B.BTN_Close_3, 80, true, Enum.ScaleType.Fit) :: ImageButton
	closeBtn.MouseButton1Click:Connect(args.onClose)

	-- Real title | nick (Titles.PaintLine colors) — no wordmark image
	do
		local nickHost = Instance.new("Frame")
		nickHost.Name = "TitleNickHost"
		nickHost.BackgroundTransparency = 1
		nickHost.BorderSizePixel = 0
		local nb = rel(B.TitleNickHost)
		nickHost.Position = UDim2.fromScale(nb[1], nb[2])
		nickHost.Size = UDim2.fromScale(nb[3], nb[4])
		nickHost.ZIndex = 98
		nickHost.ClipsDescendants = false
		nickHost.Parent = mainBg
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.fromScale(1, 1)
		row.Parent = nickHost
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, 6)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = row
		local function mkLab(order: number): TextLabel
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.AutomaticSize = Enum.AutomaticSize.X
			l.Size = UDim2.fromScale(0, 0.85)
			l.LayoutOrder = order
			l.TextSize = Titles.PlateTextSize
			l.ZIndex = 99
			l.Parent = row
			return l
		end
		local tLab = mkLab(1)
		local sLab = mkLab(2)
		local nLab = mkLab(3)
		local nick = (Players.LocalPlayer and ((Players.LocalPlayer.DisplayName ~= "" and Players.LocalPlayer.DisplayName) or Players.LocalPlayer.Name))
			or "Player"
		Titles.PaintLine(tLab, sLab, nLab, profile, nick)
	end

	---------------------------------------------------------------- equipment slots
	local function forceSquare(g: GuiObject)
		local ar = g:FindFirstChildOfClass("UIAspectRatioConstraint")
		if not ar then
			ar = Instance.new("UIAspectRatioConstraint")
			ar.Parent = g
		end
		ar.AspectRatio = 1
		ar.AspectType = Enum.AspectType.FitWithinMaxSize
		ar.DominantAxis = Enum.DominantAxis.Width
	end

	local function fillPlate(name: string, assetKey: string, box: { number }, z: number): GuiObject
		local p = pShell(name, assetKey, box, z, false, Enum.ScaleType.Fit)
		forceSquare(p)
		return p
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

	---------------------------------------------------------------- tooltip system (gear + consumable) — non-interactive, gen-guarded
	local tipGen = 0
	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.BackgroundTransparency = 1
	tip.Visible = false
	tip.Active = false
	tip.Size = UDim2.fromOffset(280, 170)
	tip.ZIndex = 500
	tip.Parent = host

	local tipBg = Instance.new("ImageLabel")
	tipBg.BackgroundTransparency = 1
	tipBg.Active = false
	tipBg.Image = art("TOOLTIPshell")
	tipBg.ScaleType = Enum.ScaleType.Stretch
	tipBg.Size = UDim2.fromScale(1, 1)
	tipBg.ZIndex = 1
	tipBg.Parent = tip

	local tipBody = Instance.new("Frame")
	tipBody.BackgroundTransparency = 1
	tipBody.Active = false
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
		tipGen += 1
		tip.Visible = false
	end

	local function showLines(lines: { any }, size: Vector2?)
		tipGen += 1
		local my = tipGen
		clearTip()
		if size then
			tip.Size = UDim2.fromOffset(size.X, size.Y)
		end
		for i, row in ipairs(lines) do
			tipLine(tipBody, i, tostring(row[1]), if type(row[2]) == "string" then row[2] :: string else "purple", if type(row[3]) == "number" then row[3] :: number else 18)
		end
		if my ~= tipGen then
			return
		end
		tip.Visible = true
		task.defer(function()
			if my == tipGen then
				placeTip()
			end
		end)
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

	-- Equipment hover only when filled (no empty-slot tips — they lag/suck)
	local function bindEquipHover(gui: GuiObject, filled: boolean, builder: () -> ())
		if not filled then
			gui.Active = false
			return
		end
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
		bindEquipHover(plate, matched ~= nil, function()
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
		bindEquipHover(plate, matched ~= nil, function()
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

	-- Pets 1–4 only (uniform size via forceSquare)
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
		bindEquipHover(plate, pet ~= nil, function()
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

	-- Relics + Aura (same size, even row)
	for i = 1, 3 do
		local plate = fillPlate("RELICcard" .. i, "RELICcard" .. i, B["RELICcard" .. i], 26 + i)
		bindEquipHover(plate, false, function() end)
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
		bindEquipHover(plate, auraId ~= nil, function()
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
	local bestDmg = pShell("EQUIPbestFORdamageBUTTON", "EQUIPbestFORdamageBUTTON", B.EQUIPbestFORdamageBUTTON, 8, true, Enum.ScaleType.Fit) :: ImageButton
	local bestPow = pShell("EQUIPbestFORpowerBUTTON", "EQUIPbestFORpowerBUTTON", B.EQUIPbestFORpowerBUTTON, 9, true, Enum.ScaleType.Fit) :: ImageButton
	local sellBtn = pShell("SELLbutton", "SELLbutton", B.SELLbutton, 8, true, Enum.ScaleType.Fit) :: ImageButton
	local sellAllBtn = pShell("SELLallUNLOCKEDbutton", "SELLallUNLOCKEDbutton", B.SELLallUNLOCKED, 9, true, Enum.ScaleType.Fit) :: ImageButton
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

	---------------------------------------------------------------- side tabs (6 — no profile/settings) — host-level (outside shell)
	for _, def in ipairs(SIDE_TABS) do
		local btn = place(host, def.id .. "Tab", def.key, def.box, 16, true, Enum.ScaleType.Fit) :: ImageButton
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

	---------------------------------------------------------------- WeaponGrid — cards NEVER leave bounds (inside MAINBACKGROUD)
	local gRel = rel(B.BG_WeaponGrid)
	local gridHost = Instance.new("Frame")
	gridHost.Name = "BG_WeaponGrid"
	gridHost.BackgroundTransparency = 1
	gridHost.Position = UDim2.fromScale(gRel[1], gRel[2])
	gridHost.Size = UDim2.fromScale(gRel[3], gRel[4])
	gridHost.ClipsDescendants = true -- hard rule
	gridHost.ZIndex = 2
	gridHost.Parent = mainBg

	local gridBg = Instance.new("ImageLabel")
	gridBg.BackgroundTransparency = 1
	gridBg.Image = art("BG_WeaponGrid")
	gridBg.ScaleType = Enum.ScaleType.Stretch -- no Slice (wrong source sizes → circles)
	gridBg.Size = UDim2.fromScale(1, 1)
	gridBg.ZIndex = 2
	gridBg.Parent = gridHost

	-- Cards sit INSIDE the painted frame (not flush on rim) — bigger inset than before
	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(0.86, 0.82)
	scroll.Position = UDim2.fromScale(0.07, 0.10)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 140, 255)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ClipsDescendants = true
	scroll.ZIndex = 3
	scroll.Parent = gridHost

	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = GRID_COLS
	-- Center each row so incomplete rows (e.g. 2 swords) sit in middle of WeaponGrid
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.CellPadding = UDim2.fromOffset(2, 2)
	grid.Parent = scroll

	local function relayout()
		local w = scroll.AbsoluteSize.X
		if w < 40 then
			return
		end
		local pad = math.max(2, math.floor(w * 0.0022))
		grid.CellPadding = UDim2.fromOffset(pad, pad)
		local cell = math.floor((w - pad * (GRID_COLS - 1)) / GRID_COLS)
		cell = math.max(42, cell)
		grid.CellSize = UDim2.fromOffset(cell, cell)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)
	task.delay(0.05, relayout)

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

	-- Strong rarity glow: Legendary < Mythic < Secret < Limited
	local function applyRarityGlow(btn: GuiObject, rar: string)
		local thick = 0
		local trans = 1
		if rar == "Legendary" then
			thick, trans = 5, 0.42
		elseif rar == "Mythic" then
			thick, trans = 7, 0.32
		elseif rar == "Secret" then
			thick, trans = 10, 0.18
		elseif rar == "Limited" then
			thick, trans = 13, 0.10
		else
			return
		end
		local col = Rarity.Of(rar)
		local glow = Instance.new("UIStroke")
		glow.Name = "RarityGlow"
		glow.Color = col
		glow.Thickness = thick
		glow.Transparency = trans
		glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		glow.LineJoinMode = Enum.LineJoinMode.Round
		glow.Parent = btn
		-- second softer outer ring for Secret/Limited
		if rar == "Secret" or rar == "Limited" then
			local outer = Instance.new("UIStroke")
			outer.Name = "RarityGlowOuter"
			outer.Color = col
			outer.Thickness = thick + 6
			outer.Transparency = math.clamp(trans + 0.25, 0, 0.85)
			outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			outer.LineJoinMode = Enum.LineJoinMode.Round
			outer.Parent = btn
		end
	end

	---------------------------------------------------------------- WEAPONS grid (no empty filler slots)
	if invTab == "weapons" then
		local weapons = profile.weapons or {}
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
			applyRarityGlow(btn, rar)
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
			applyRarityGlow(btn, rar)
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
			applyRarityGlow(btn, rar)
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
			applyRarityGlow(btn, rar)
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

	---------------------------------------------------------------- CONSUMABLES (PotionIconConfig idle/hover)
	elseif invTab == "items" then
		local POTIONS = {
			{ id = "SmallCoin", size = "Small", stat = "Coin", name = "Small Coin Potion", effect = "+25% Coins", duration = "10 min" },
			{ id = "MidCoin", size = "Mid", stat = "Coin", name = "Mid Coin Potion", effect = "+50% Coins", duration = "20 min" },
			{ id = "BigCoin", size = "Big", stat = "Coin", name = "Big Coin Potion", effect = "+100% Coins", duration = "30 min" },
			{ id = "SmallPower", size = "Small", stat = "Power", name = "Small Power Potion", effect = "+25% Power", duration = "10 min" },
			{ id = "MidPower", size = "Mid", stat = "Power", name = "Mid Power Potion", effect = "+50% Power", duration = "20 min" },
			{ id = "BigPower", size = "Big", stat = "Power", name = "Big Power Potion", effect = "+100% Power", duration = "30 min" },
			{ id = "SmallDamage", size = "Small", stat = "Damage", name = "Small Damage Potion", effect = "+25% Damage", duration = "10 min" },
			{ id = "MidDamage", size = "Mid", stat = "Damage", name = "Mid Damage Potion", effect = "+50% Damage", duration = "20 min" },
			{ id = "BigDamage", size = "Big", stat = "Damage", name = "Big Damage Potion", effect = "+100% Damage", duration = "30 min" },
			{ id = "SmallLuck", size = "Small", stat = "Luck", name = "Small Luck Potion", effect = "+25% Luck", duration = "10 min" },
			{ id = "MidLuck", size = "Mid", stat = "Luck", name = "Mid Luck Potion", effect = "+50% Luck", duration = "20 min" },
			{ id = "BigLuck", size = "Big", stat = "Luck", name = "Big Luck Potion", effect = "+100% Luck", duration = "30 min" },
		}
		for i, pot in ipairs(POTIONS) do
			local btn = Instance.new("ImageButton")
			btn.Name = "Pot_" .. pot.id
			btn.BackgroundTransparency = 1
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.ZIndex = 4
			btn.Parent = scroll
			local idle = PotionIconConfig.GetIdle(pot.size :: any, pot.stat :: any)
			local hover = PotionIconConfig.GetHover(pot.size :: any, pot.stat :: any)
			if idle == "" then
				btn.Image = InventoryAssetConfig.GetSlotFrame("Common")
			else
				btn.Image = idle
			end
			btn.ScaleType = Enum.ScaleType.Fit
			local sc = Instance.new("UIScale")
			sc.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = HOVER_SCALE }):Play()
				if hover ~= "" then
					btn.Image = hover
				end
				showConsumableTip(
					pot.name,
					"Consumable",
					string.format(
						"Keys P%d · A%d · Dust %d",
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
				if idle ~= "" then
					btn.Image = idle
				end
				hideTip()
			end)
			btn.MouseButton1Click:Connect(function()
				Net.UsePotion(pot.id)
				args.onRefresh()
			end)
		end
	end
	-- No empty filler slots on any page
end

return InventoryWeaponsLayout
