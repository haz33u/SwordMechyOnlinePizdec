--!strict
--[[
	Inventory (INVETAR layout + live data):
	  - near-fullscreen responsive shell (no left preview strip)
	  - compact structured tooltips (refICONTOLLTIP style)
	  - bottom ImageButton tabs (Creator Store free cartoon icons)
	  - opaque slots, hover pulse, sell-all, gamepass shop, profile search
]]

local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)
local Rarity = require(script.Parent.Rarity)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(Shared.Config.WeaponConfig)
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local IconConfig = require(Shared.Config.IconConfig)
local GamePassConfig = require(Shared.Config.GamePassConfig)
local Formulas = require(Shared.Formulas)

local Inventory = {}

local BG_PANEL = Color3.fromRGB(24, 24, 24)
local BG_SECTION = Color3.fromRGB(32, 32, 32)
local BG_SLOT = Color3.fromRGB(34, 34, 34)
local BG_SLOT_MT = Color3.fromRGB(22, 22, 22)
local BD = Color3.fromRGB(48, 48, 48)
local BD2 = Color3.fromRGB(62, 62, 62)
local TW = Color3.fromRGB(220, 220, 220)
local TD = Color3.fromRGB(150, 150, 150)
local TL = Color3.fromRGB(100, 100, 100)
local CYAN = Color3.fromRGB(0, 255, 224)
local GOLD = Color3.fromRGB(232, 184, 0)
local RED_CLOSE = Color3.fromRGB(204, 34, 0)
local GREEN = Color3.fromRGB(120, 170, 100)
local STAT_BLUE = Color3.fromRGB(90, 160, 230)

-- Base design px; scaled by UIScale from AbsoluteSize
local SLOT = 72
local SLOT_GAP = 6
local COLS = 10
local HOVER_SCALE = 1.12
local TAB_ICON = 58

-- Free Creator Store cartoon icons (Decal/Image)
local TAB_ICONS: { [string]: string } = {
	weapons = "rbxassetid://114848036963361", -- medieval-sword-cartoon-icon
	pets = "rbxassetid://92327170909498", -- pet_button_icon
	auras = "rbxassetid://133879685799043", -- light/sparkle
	relics = "rbxassetid://9650296120", -- gem
	cases = "rbxassetid://7181747872", -- chest-icon
	shop = "rbxassetid://16009435598", -- coin
	profile = "rbxassetid://7492903668", -- user icon
}

local TABS = {
	{ id = "weapons", label = "Weapons" },
	{ id = "pets", label = "Pets" },
	{ id = "auras", label = "Auras" },
	{ id = "relics", label = "Relics" },
	{ id = "cases", label = "Cases" },
	{ id = "shop", label = "Shop" },
	{ id = "profile", label = "Profile" },
}

local function rarityBorder(r: string?): Color3
	return Rarity.Of(r)
end

--- Normalize weapons/pets arrays (ipairs-safe after DataStore quirks)
local function asArray(list: any): { any }
	if type(list) ~= "table" then
		return {}
	end
	local out: { any } = {}
	for _, v in ipairs(list) do
		if type(v) == "table" then
			table.insert(out, v)
		end
	end
	if #out == 0 then
		for _, v in pairs(list) do
			if type(v) == "table" and (v.uid or v.id) then
				table.insert(out, v)
			end
		end
	end
	return out
end

local function solid(parent: Instance, name: string, size: UDim2, pos: UDim2?, bg: Color3?, z: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = bg or BG_SECTION
	f.BackgroundTransparency = 0
	f.BorderSizePixel = 0
	f.Size = size
	if pos then
		f.Position = pos
	end
	f.ZIndex = z or 32
	f.Parent = parent
	return f
end

local function lbl(
	parent: Instance,
	text: string,
	size: UDim2,
	pos: UDim2?,
	sizePx: number?,
	color: Color3?,
	z: number?,
	font: Enum.Font?
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Text = text
	l.Size = size
	if pos then
		l.Position = pos
	end
	l.Font = font or Enum.Font.GothamBold
	l.TextSize = sizePx or 13
	l.TextColor3 = color or TW
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.ZIndex = z or 34
	l.Parent = parent
	return l
end

local function avatarBustUrl(userId: number): string
	return string.format("rbxthumb://type=AvatarBust&id=%d&w=420&h=420", userId)
end

export type Api = {
	Refresh: (self: Api) -> (),
	SetTab: (self: Api, tab: string) -> (),
	GetTab: (self: Api) -> string,
}

function Inventory.Bind(
	body: Frame,
	_root: Frame,
	store: any,
	openModal: (string, any?) -> (),
	onClose: () -> ()
): Api
	local tab = "weapons"
	local selectedWeaponUid: string? = nil
	local shellBuilt = false
	local mouseMove: RBXScriptConnection? = nil
	local priceCache: { [number]: string } = {}
	local pricesReady = false

	local inspectName: string? = nil
	local inspectUserId: number? = nil
	local inspectStats: any? = nil
	local inspectLocation: number? = nil
	local inspectStatus: string? = nil

	local canvas: Frame
	local titleLab: TextLabel
	local countLab: TextLabel
	local infoLab: TextLabel
	local main: Frame
	local actions: Frame
	local tip: Frame
	local tipLayout: UIListLayout
	local scaleObj: UIScale
	local tabButtons: { [string]: ImageButton } = {}
	local tabLabels: { [string]: TextLabel } = {}

	local function preloadPrices()
		if pricesReady then
			return
		end
		pricesReady = true
		for _, key in ipairs(GamePassConfig.Order) do
			local def = GamePassConfig.Get(key)
			if def then
				local id = def.gamePassId
				task.spawn(function()
					local ok, info = pcall(function()
						return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)
					end)
					if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
						priceCache[id] = "R$ " .. tostring(info.PriceInRobux)
					else
						priceCache[id] = "R$ —"
					end
				end)
			end
		end
	end

	local function fetchPrice(passId: number, label: TextLabel)
		if priceCache[passId] then
			label.Text = priceCache[passId]
			return
		end
		label.Text = "…"
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				priceCache[passId] = "R$ " .. tostring(info.PriceInRobux)
			else
				priceCache[passId] = "R$ —"
			end
			if label.Parent then
				label.Text = priceCache[passId]
			end
		end)
	end

	local function clearTipRows()
		for _, c in tip:GetChildren() do
			if c:IsA("TextLabel") or c:IsA("Frame") then
				if c.Name ~= "Pad" then
					c:Destroy()
				end
			end
		end
	end

	local function tipLine(order: number, left: string, right: string?, leftCol: Color3?, rightCol: Color3?)
		local row = Instance.new("Frame")
		row.Name = "R" .. order
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 18)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.LayoutOrder = order
		row.ZIndex = 91
		row.Parent = tip

		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(if right then 0.48 else 1, 0, 0, 18)
		l.Font = Enum.Font.Gotham
		l.TextSize = 14
		l.TextColor3 = leftCol or TD
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = left
		l.ZIndex = 92
		l.Parent = row

		if right then
			local r = Instance.new("TextLabel")
			r.BackgroundTransparency = 1
			r.Size = UDim2.new(0.52, 0, 0, 18)
			r.Position = UDim2.new(0.48, 0, 0, 0)
			r.Font = Enum.Font.GothamBold
			r.TextSize = 14
			r.TextColor3 = rightCol or TW
			r.TextXAlignment = Enum.TextXAlignment.Left
			r.Text = right
			r.ZIndex = 92
			r.Parent = row
		end
	end

	local function placeTooltip()
		if not tip.Visible or not canvas then
			return
		end
		local inset = GuiService:GetGuiInset()
		local mouse = UserInputService:GetMouseLocation()
		local screenX = mouse.X - inset.X
		local screenY = mouse.Y - inset.Y
		local abs = canvas.AbsolutePosition
		local canvasSz = canvas.AbsoluteSize
		local tipSz = tip.AbsoluteSize
		if tipSz.X < 4 then
			tipSz = Vector2.new(220, 120)
		end
		local gap = 12
		local localX = (screenX - abs.X) + gap
		local localY = (screenY - abs.Y) + 4
		if localX + tipSz.X > canvasSz.X - 6 then
			localX = (screenX - abs.X) - tipSz.X - gap
		end
		if localY + tipSz.Y > canvasSz.Y - 6 then
			localY = canvasSz.Y - tipSz.Y - 6
		end
		localX = math.clamp(localX, 4, math.max(4, canvasSz.X - tipSz.X - 4))
		localY = math.clamp(localY, 4, math.max(4, canvasSz.Y - tipSz.Y - 4))
		tip.Position = UDim2.fromOffset(localX, localY)
	end

	--- Compact tooltip like refICONTOLLTIP: title + labeled stats, minimal empty space
	local function setTooltip(opts: {
		title: string,
		rarity: string?,
		power: string?,
		sell: string?,
		level: string?,
		extra: string?,
		border: Color3?,
	})
		clearTipRows()
		local order = 1
		tipLine(order, opts.title, nil, opts.border or TW, nil)
		order += 1
		if opts.rarity then
			tipLine(order, "Rarity:", opts.rarity, TD, rarityBorder(opts.rarity))
			order += 1
		end
		-- spacer
		local sp = Instance.new("Frame")
		sp.BackgroundTransparency = 1
		sp.Size = UDim2.new(1, 0, 0, 6)
		sp.LayoutOrder = order
		sp.ZIndex = 91
		sp.Parent = tip
		order += 1
		if opts.power then
			tipLine(order, "Power:", opts.power, TD, STAT_BLUE)
			order += 1
		end
		if opts.sell then
			tipLine(order, "Sell:", opts.sell, TD, STAT_BLUE)
			order += 1
		end
		if opts.level then
			tipLine(order, "Level:", opts.level, TD, STAT_BLUE)
			order += 1
		end
		if opts.extra and opts.extra ~= "" then
			tipLine(order, opts.extra, nil, CYAN, nil)
		end
		local st = tip:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = opts.border or rarityBorder(opts.rarity) or BD2
		end
		tip.Visible = true
		-- next frame so AutomaticSize settles
		task.defer(placeTooltip)
		placeTooltip()
	end

	local function hideTooltip()
		tip.Visible = false
	end

	local function clearMainAndActions()
		for _, c in main:GetChildren() do
			c:Destroy()
		end
		for _, c in actions:GetChildren() do
			if c.Name ~= "Line" then
				c:Destroy()
			end
		end
	end

	local function bindHover(btn: GuiObject, stroke: UIStroke?, baseStroke: Color3?)
		local sc = Instance.new("UIScale")
		sc.Scale = 1
		sc.Parent = btn
		local baseCol = baseStroke or BD
		btn.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = HOVER_SCALE,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.1), {
					Color = CYAN,
					Thickness = 2.4,
					Transparency = 0,
				}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.1), {
					Color = baseCol,
					Thickness = 1.4,
					Transparency = 0.12,
				}):Play()
			end
		end)
	end

	local function makeItemSlot(parent: Instance, order: number, edge: Color3): (TextButton, UIStroke)
		local btn = Instance.new("TextButton")
		btn.Name = "Slot" .. order
		btn.Size = UDim2.fromOffset(SLOT, SLOT)
		btn.BackgroundColor3 = BG_SLOT
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.ClipsDescendants = true
		btn.LayoutOrder = order
		btn.ZIndex = 35
		btn.Parent = parent

		local plate = Instance.new("Frame")
		plate.Name = "Plate"
		plate.Size = UDim2.fromScale(1, 1)
		plate.BackgroundColor3 = BG_SLOT
		plate.BackgroundTransparency = 0
		plate.BorderSizePixel = 0
		plate.ZIndex = 35
		plate.Parent = btn

		local stroke = UIKit.Stroke(btn, edge, 1.4, 0.12)
		bindHover(btn, stroke, edge)
		return btn, stroke
	end

	local function emptySlot(parent: Instance, order: number)
		local btn = Instance.new("TextButton")
		btn.Name = "E" .. order
		btn.Size = UDim2.fromOffset(SLOT, SLOT)
		btn.BackgroundColor3 = BG_SLOT_MT
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Active = false
		btn.LayoutOrder = order
		btn.ZIndex = 35
		btn.Parent = parent
		UIKit.Stroke(btn, BD, 1, 0.35)
	end

	local function makeSlotGrid(parent: Instance): ScrollingFrame
		local scroll = Instance.new("ScrollingFrame")
		scroll.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
		scroll.BackgroundTransparency = 0
		scroll.BorderSizePixel = 0
		scroll.Size = UDim2.new(1, -12, 1, -12)
		scroll.Position = UDim2.fromOffset(6, 6)
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 8
		scroll.ScrollBarImageColor3 = BD2
		scroll.ZIndex = 34
		scroll.ClipsDescendants = true
		scroll.Parent = parent
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(SLOT, SLOT)
		grid.CellPadding = UDim2.fromOffset(SLOT_GAP, SLOT_GAP)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = COLS
		grid.Parent = scroll
		UIKit.Pad(scroll, 10)
		return scroll
	end

	local function actBtn(parent: Instance, text: string, color: Color3, order: number, onClick: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(0, 36)
		b.AutomaticSize = Enum.AutomaticSize.X
		b.BackgroundColor3 = color
		b.BackgroundTransparency = 0
		b.BorderSizePixel = 0
		b.Text = text
		b.TextColor3 = TW
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.AutoButtonColor = false
		b.LayoutOrder = order
		b.ZIndex = 35
		b.Parent = parent
		UIKit.Corner(b, 5)
		UIKit.Stroke(b, BD2, 1, 0.2)
		UIKit.Pad(b, nil, 14, 0, 14, 0)
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	local function actionsRow(): Frame
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -24, 1, -8)
		row.Position = UDim2.fromOffset(14, 6)
		row.ZIndex = 34
		row.Parent = actions
		UIKit.List(row, 10, true, Enum.HorizontalAlignment.Left)
		return row
	end

	local function updateScale()
		if not canvas then
			return
		end
		local w = canvas.AbsoluteSize.X
		if w < 50 then
			return
		end
		-- design reference ~1200px wide → scale so UI stays big on large screens
		local s = math.clamp(w / 1180, 0.9, 1.25)
		scaleObj.Scale = s
	end

	local api: Api

	local function ensureShell()
		if shellBuilt then
			return
		end
		shellBuilt = true
		preloadPrices()
		body.ClipsDescendants = false
		for _, c in body:GetChildren() do
			c:Destroy()
		end

		canvas = solid(body, "InvCanvas", UDim2.new(1, 0, 1, 0), nil, BG_PANEL, 31)
		UIKit.Stroke(canvas, BD2, 2, 0.08)
		scaleObj = Instance.new("UIScale")
		scaleObj.Scale = 1
		scaleObj.Parent = canvas
		canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)

		local header = solid(canvas, "Header", UDim2.new(1, 0, 0, 50), UDim2.fromOffset(0, 0), Color3.fromRGB(16, 16, 16), 32)
		solid(header, "Line", UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), BD, 33)
		titleLab = lbl(header, "Inventory — Weapons", UDim2.new(0.55, 0, 1, 0), UDim2.fromOffset(20, 0), 16, TW, 34)
		countLab = lbl(header, "", UDim2.new(0.28, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), 13, TL, 34)
		countLab.TextXAlignment = Enum.TextXAlignment.Right

		local close = Instance.new("TextButton")
		close.Size = UDim2.fromOffset(32, 32)
		close.Position = UDim2.new(1, -44, 0.5, 0)
		close.AnchorPoint = Vector2.new(0, 0.5)
		close.BackgroundColor3 = RED_CLOSE
		close.BackgroundTransparency = 0
		close.Text = "✕"
		close.TextColor3 = Color3.new(1, 1, 1)
		close.Font = Enum.Font.GothamBold
		close.TextSize = 15
		close.AutoButtonColor = false
		close.BorderSizePixel = 0
		close.ZIndex = 35
		close.Parent = header
		UIKit.Corner(close, 99)
		close.MouseButton1Click:Connect(onClose)

		local info = solid(canvas, "Info", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 50), Color3.fromRGB(14, 14, 14), 32)
		infoLab = lbl(info, "", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(20, 0), 13, TD, 34, Enum.Font.Gotham)

		-- Full width content (NO left strip)
		local contentH = 50 + 30 + 56 + 96
		main = solid(canvas, "Main", UDim2.new(1, 0, 1, -contentH), UDim2.fromOffset(0, 80), Color3.fromRGB(18, 18, 18), 32)
		main.BackgroundTransparency = 0
		main.ClipsDescendants = true

		actions = solid(canvas, "Actions", UDim2.new(1, 0, 0, 56), UDim2.new(0, 0, 1, -(56 + 96)), Color3.fromRGB(14, 14, 14), 32)
		solid(actions, "Line", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, 0), BD, 33)

		local tabs = solid(canvas, "Tabs", UDim2.new(1, 0, 0, 96), UDim2.new(0, 0, 1, -96), Color3.fromRGB(12, 12, 12), 32)
		solid(tabs, "Line", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, 0), BD, 33)
		local tabRow = Instance.new("Frame")
		tabRow.BackgroundTransparency = 1
		tabRow.Size = UDim2.new(1, -12, 1, -8)
		tabRow.Position = UDim2.fromOffset(6, 6)
		tabRow.ZIndex = 33
		tabRow.Parent = tabs
		UIKit.List(tabRow, 14, true, Enum.HorizontalAlignment.Center)

		for _, def in ipairs(TABS) do
			local col = Instance.new("Frame")
			col.Name = def.id .. "Col"
			col.BackgroundTransparency = 1
			col.Size = UDim2.fromOffset(TAB_ICON + 12, 84)
			col.ZIndex = 34
			col.Parent = tabRow

			local b = Instance.new("ImageButton")
			b.Name = def.id
			b.Size = UDim2.fromOffset(TAB_ICON, TAB_ICON)
			b.Position = UDim2.new(0.5, 0, 0, 0)
			b.AnchorPoint = Vector2.new(0.5, 0)
			b.BackgroundTransparency = 1 -- no circle / plate — pure icon on frame
			b.BorderSizePixel = 0
			b.Image = TAB_ICONS[def.id] or ""
			b.ScaleType = Enum.ScaleType.Fit
			b.AutoButtonColor = false
			b.ZIndex = 35
			b.Parent = col

			local sc = Instance.new("UIScale")
			sc.Scale = 1
			sc.Parent = b
			b.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Scale = 1.18,
				}):Play()
			end)
			b.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
			end)

			local lab = lbl(col, def.label, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), 11, Color3.fromRGB(90, 90, 90), 35)
			lab.TextXAlignment = Enum.TextXAlignment.Center

			tabButtons[def.id] = b
			tabLabels[def.id] = lab
			b.MouseButton1Click:Connect(function()
				tab = def.id
				api:Refresh()
			end)
		end

		-- Compact tooltip (auto-size, structured rows)
		tip = solid(canvas, "Tooltip", UDim2.fromOffset(200, 0), UDim2.fromOffset(0, 0), Color3.fromRGB(36, 36, 40), 95)
		tip.Visible = false
		tip.AutomaticSize = Enum.AutomaticSize.XY
		tip.BackgroundTransparency = 0.05
		UIKit.Stroke(tip, BD2, 1.2, 0.15)
		UIKit.Pad(tip, 10)
		local tipPad = tip:FindFirstChildOfClass("UIPadding")
		if tipPad then
			tipPad.Name = "Pad"
		end
		tipLayout = Instance.new("UIListLayout")
		tipLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tipLayout.Padding = UDim.new(0, 2)
		tipLayout.Parent = tip
		local tipConstraint = Instance.new("UISizeConstraint")
		tipConstraint.MinSize = Vector2.new(180, 40)
		tipConstraint.MaxSize = Vector2.new(280, 220)
		tipConstraint.Parent = tip

		if mouseMove then
			mouseMove:Disconnect()
		end
		mouseMove = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible then
				placeTooltip()
			end
		end)

		task.defer(updateScale)
	end

	api = {} :: Api

	function api:GetTab(): string
		return tab
	end

	function api:SetTab(t: string)
		for _, def in ipairs(TABS) do
			if def.id == t then
				tab = t
				return
			end
		end
	end

	function api:Refresh()
		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		if not profile then
			return
		end

		ensureShell()
		clearMainAndActions()
		hideTooltip()
		preloadPrices()
		updateScale()

		for id, b in tabButtons do
			local on = id == tab
			b.ImageTransparency = on and 0 or 0.25
			local lab = tabLabels[id]
			if lab then
				lab.TextColor3 = on and CYAN or Color3.fromRGB(90, 90, 90)
			end
		end

		local titles = {
			weapons = "Inventory — Weapons",
			pets = "Inventory — Pets",
			auras = "Inventory — Auras",
			relics = "Inventory — Relics",
			cases = "Inventory — Cases",
			shop = "Donate Shop",
			profile = "Player Profile",
		}
		titleLab.Text = titles[tab] or "Inventory"

		local lp = Players.LocalPlayer
		local showName = inspectName or (lp and lp.Name) or "Player"
		local showStats = inspectStats or stats
		local showLoc = inspectLocation or profile.currentLocation or 1
		infoLab.Text = string.format(
			"● %s  |  R%d %s   ●  Loc %s%s",
			showName,
			showStats and (showStats.rebirthLevel or 0) or 0,
			showStats and Format.Mult(showStats.rebirthMult) or "x1",
			tostring(showLoc),
			inspectName and "  ·  VIEWING" or ""
		)

		---------------------------------------------------------------- WEAPONS
		if tab == "weapons" then
			local weapons = asArray(profile.weapons)
			local bagCap = 32
			pcall(function()
				bagCap = Formulas.GetWeaponBagCap(profile)
			end)
			if bagCap < 8 then
				bagCap = 32
			end
			countLab.Text = string.format("%d OF %d", #weapons, bagCap)

			local scroll = makeSlotGrid(main)
			local offUnlocked = (stats and stats.offhandUnlocked) == true
				or (profile.unlocks and profile.unlocks.offhand) == true

			for i, w in ipairs(weapons) do
				local def = WeaponConfig.Get(w.id)
				local edge = rarityBorder(def and def.rarity)
				local isSel = w.uid == selectedWeaponUid
				local btn, stroke = makeItemSlot(scroll, i, isSel and CYAN or edge)
				btn.Name = "W_" .. tostring(w.uid)
				if isSel and stroke then
					stroke.Color = CYAN
					stroke.Thickness = 2.4
				end

				local img = Instance.new("ImageLabel")
				img.BackgroundColor3 = BG_SLOT
				img.BackgroundTransparency = 0
				img.BorderSizePixel = 0
				img.Size = UDim2.fromScale(0.8, 0.8)
				img.Position = UDim2.fromScale(0.5, 0.5)
				img.AnchorPoint = Vector2.new(0.5, 0.5)
				img.Image = IconConfig.GetWeaponImage(w.id)
				img.ScaleType = Enum.ScaleType.Fit
				img.ZIndex = 36
				img.Parent = btn

				if profile.equippedMain == w.uid or profile.equippedOffhand == w.uid then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(9, 9)
					dot.Position = UDim2.fromOffset(5, 5)
					dot.BackgroundColor3 = CYAN
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end

				local name = (def and def.name) or tostring(w.id)
				local rar = (def and def.rarity) or "Common"
				local mult = (def and def.powerMult) or 1
				local sell = (def and def.sellPrice) or 5
				local level = w.level or 1
				btn.MouseEnter:Connect(function()
					local extra = profile.equippedMain == w.uid and "● Equipped main"
						or (profile.equippedOffhand == w.uid and "● Equipped off" or nil)
					setTooltip({
						title = name,
						rarity = rar,
						power = string.format("×%.2f", mult),
						sell = tostring(sell),
						level = tostring(level),
						extra = extra,
						border = edge,
					})
				end)
				btn.MouseLeave:Connect(hideTooltip)
				btn.MouseButton1Click:Connect(function()
					selectedWeaponUid = w.uid
					api:Refresh()
				end)
			end

			local padTo = math.max(bagCap, COLS * 3)
			for i = #weapons + 1, padTo do
				emptySlot(scroll, i)
			end

			local selected = nil
			for _, w in ipairs(weapons) do
				if w.uid == selectedWeaponUid then
					selected = w
					break
				end
			end
			if not selected and weapons[1] then
				selected = weapons[1]
				selectedWeaponUid = selected.uid
			end

			local row = actionsRow()
			if selected then
				local def = WeaponConfig.Get(selected.id)
				lbl(row, (def and def.name) or selected.id, UDim2.fromOffset(130, 34), nil, 13, rarityBorder(def and def.rarity), 35)
				actBtn(row, "Equip main", Color3.fromRGB(0, 90, 80), 2, function()
					Net.EquipWeapon(selected.uid, "main")
				end)
				actBtn(row, offUnlocked and "Equip off" or "Off 🔒", Color3.fromRGB(50, 50, 50), 3, function()
					if offUnlocked then
						Net.EquipWeapon(selected.uid, "offhand")
					else
						local gp = GamePassConfig.Get("offhand")
						if gp then
							Net.PromptGamePass(gp.gamePassId)
						end
					end
				end)
				actBtn(row, "Enchant", Color3.fromRGB(70, 40, 100), 4, function()
					Net.EnchantWeapon(selected.uid)
					openModal("enchant", selected)
				end)
				actBtn(row, "Sell", Color3.fromRGB(120, 30, 30), 5, function()
					openModal("sell", selected)
				end)
			end
			actBtn(row, "Sell all unequipped", Color3.fromRGB(140, 40, 40), 10, function()
				Net.SellAllWeapons()
			end)

		---------------------------------------------------------------- PETS
		elseif tab == "pets" then
			local pets = asArray(profile.pets)
			countLab.Text = string.format("%d / %d team", #(profile.petTeam or {}), profile.petSlots or 3)
			local scroll = makeSlotGrid(main)
			for i, p in ipairs(pets) do
				local def = PetConfig.Get(p.id)
				local name = (def and def.name) or p.name or p.id
				local rar = (def and def.rarity) or p.rarity or "Common"
				local inTeam = false
				for _, uid in ipairs(profile.petTeam or {}) do
					if uid == p.uid then
						inTeam = true
						break
					end
				end
				local btn = makeItemSlot(scroll, i, rarityBorder(rar))
				local glyph = lbl(btn, "🐾", UDim2.fromScale(1, 0.8), UDim2.fromScale(0, 0.1), 30, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				if inTeam then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(9, 9)
					dot.Position = UDim2.fromOffset(5, 5)
					dot.BackgroundColor3 = CYAN
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end
				btn.MouseEnter:Connect(function()
					local power = def and def.powerPct or p.powerPct or 0
					setTooltip({
						title = name,
						rarity = rar,
						power = string.format("+%d%%", math.floor(power)),
						extra = inTeam and "● On team" or "LMB equip",
						border = rarityBorder(rar),
					})
				end)
				btn.MouseLeave:Connect(hideTooltip)
				btn.MouseButton1Click:Connect(function()
					if inTeam then
						Net.UnequipPet(p.uid)
					else
						Net.EquipPet(p.uid)
					end
				end)
			end
			for i = #pets + 1, math.max(30, #pets + 10) do
				emptySlot(scroll, i)
			end
			local row = actionsRow()
			actBtn(row, "Open pet case", Color3.fromRGB(0, 90, 80), 1, function()
				openModal("case", { kind = "pet" })
			end)

		---------------------------------------------------------------- AURAS
		elseif tab == "auras" then
			local auras = asArray(profile.auras)
			countLab.Text = string.format("%d auras", #auras)
			local scroll = makeSlotGrid(main)
			for i, a in ipairs(auras) do
				local def = AuraConfig.Get(a.id)
				local name = (def and def.name) or a.name or a.id
				local rar = (def and def.rarity) or a.rarity or "Common"
				local active = profile.equippedAura == a.uid
				local btn = makeItemSlot(scroll, i, rarityBorder(rar))
				local glyph = lbl(btn, "✨", UDim2.fromScale(1, 0.8), UDim2.fromScale(0, 0.1), 30, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				btn.MouseEnter:Connect(function()
					setTooltip({
						title = name,
						rarity = rar,
						power = def and string.format("+%d%%", math.floor(def.powerPct or 0)) or nil,
						extra = active and "● Active" or "LMB equip",
						border = rarityBorder(rar),
					})
				end)
				btn.MouseLeave:Connect(hideTooltip)
				btn.MouseButton1Click:Connect(function()
					Net.EquipAura(a.uid)
				end)
			end
			for i = #auras + 1, math.max(30, #auras + 10) do
				emptySlot(scroll, i)
			end
			local row = actionsRow()
			actBtn(row, "Open aura case", Color3.fromRGB(80, 50, 120), 1, function()
				openModal("case", { kind = "aura" })
			end)

		---------------------------------------------------------------- RELICS
		elseif tab == "relics" then
			local relics = asArray(profile.relics)
			countLab.Text = string.format("%d relics", #relics)
			local scroll = makeSlotGrid(main)
			for i, r in ipairs(relics) do
				local btn = makeItemSlot(scroll, i, BD)
				local glyph = lbl(btn, "💎", UDim2.fromScale(1, 0.7), nil, 28, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				btn.MouseEnter:Connect(function()
					setTooltip({
						title = tostring(r.name or r.id),
						level = tostring(r.stars or 1),
						extra = "Dungeon drop",
					})
				end)
				btn.MouseLeave:Connect(hideTooltip)
			end
			for i = #relics + 1, 30 do
				emptySlot(scroll, i)
			end
			local row = actionsRow()
			lbl(row, "Relics are read-only", UDim2.fromOffset(220, 34), nil, 13, TL, 35)

		---------------------------------------------------------------- CASES
		elseif tab == "cases" then
			countLab.Text = ""
			local scroll = UIKit.Scroll(main, UDim2.new(1, -12, 1, -12))
			scroll.Position = UDim2.fromOffset(6, 6)
			local function caseCard(order: number, title: string, kind: string, color: Color3)
				local c = solid(scroll, kind, UDim2.new(1, -8, 0, 110), nil, BG_SECTION, 35)
				c.LayoutOrder = order
				UIKit.Stroke(c, color, 1.5, 0.2)
				UIKit.Pad(c, 14)
				lbl(c, title, UDim2.new(1, 0, 0, 30), nil, 18, TW, 36)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 40)
				b.Position = UDim2.new(0, 0, 1, -40)
				b.BackgroundColor3 = color
				b.BackgroundTransparency = 0
				b.Text = "Open"
				b.TextColor3 = Color3.new(1, 1, 1)
				b.Font = Enum.Font.GothamBold
				b.TextSize = 15
				b.BorderSizePixel = 0
				b.ZIndex = 37
				b.Parent = c
				UIKit.Corner(b, 5)
				b.MouseButton1Click:Connect(function()
					openModal("case", { kind = kind })
				end)
			end
			caseCard(1, "🐾  Pet Case", "pet", Color3.fromRGB(40, 120, 80))
			caseCard(2, "✨  Aura Case", "aura", Color3.fromRGB(100, 60, 160))
			local row = actionsRow()
			lbl(row, "LMB open case", UDim2.fromOffset(160, 34), nil, 13, TL, 35)

		---------------------------------------------------------------- SHOP
		elseif tab == "shop" then
			countLab.Text = "Gamepasses"
			local scroll = UIKit.Scroll(main, UDim2.new(1, -12, 1, -12))
			scroll.Position = UDim2.fromOffset(6, 6)
			for _, ch in scroll:GetChildren() do
				if ch:IsA("UIListLayout") then
					ch:Destroy()
				end
			end
			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.fromOffset(180, 220)
			grid.CellPadding = UDim2.fromOffset(14, 14)
			grid.SortOrder = Enum.SortOrder.LayoutOrder
			grid.FillDirectionMaxCells = 5
			grid.Parent = scroll
			UIKit.Pad(scroll, 10)

			local unlocks = profile.unlocks or {}
			for i, key in ipairs(GamePassConfig.Order) do
				local def = GamePassConfig.Get(key)
				if def then
					local owned = (def.feature and unlocks[def.feature] == true)
						or (def.feature == "autoClicker" and profile.purchasedAutoClicker == true)
					local card = solid(scroll, key, UDim2.fromOffset(180, 220), nil, BG_SECTION, 35)
					card.LayoutOrder = i
					UIKit.Stroke(card, owned and GREEN or BD2, 1.5, 0.1)

					local imgBtn = Instance.new("ImageButton")
					imgBtn.Size = UDim2.fromOffset(136, 136)
					imgBtn.Position = UDim2.new(0.5, 0, 0, 12)
					imgBtn.AnchorPoint = Vector2.new(0.5, 0)
					imgBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
					imgBtn.BackgroundTransparency = 0
					imgBtn.BorderSizePixel = 0
					imgBtn.Image = GamePassConfig.ThumbUrl(def.gamePassId, 150)
					imgBtn.ScaleType = Enum.ScaleType.Fit
					imgBtn.AutoButtonColor = not owned
					imgBtn.ZIndex = 36
					imgBtn.Parent = card
					UIKit.Corner(imgBtn, 8)
					bindHover(imgBtn, nil, nil)

					local pricePill = Instance.new("TextLabel")
					pricePill.Size = UDim2.new(1, -10, 0, 24)
					pricePill.Position = UDim2.new(0.5, 0, 1, -28)
					pricePill.AnchorPoint = Vector2.new(0.5, 0)
					pricePill.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
					pricePill.BackgroundTransparency = 0.1
					pricePill.BorderSizePixel = 0
					pricePill.Font = Enum.Font.GothamBold
					pricePill.TextSize = 14
					pricePill.TextColor3 = owned and GREEN or GOLD
					pricePill.ZIndex = 40
					pricePill.Parent = imgBtn
					UIKit.Corner(pricePill, 4)
					if owned then
						pricePill.Text = "OWNED"
						imgBtn.ImageTransparency = 0.2
					else
						pricePill.Text = priceCache[def.gamePassId] or "…"
						fetchPrice(def.gamePassId, pricePill)
					end

					local titleL = lbl(card, def.title, UDim2.new(1, -10, 0, 22), UDim2.fromOffset(5, 154), 12, TW, 36)
					titleL.TextXAlignment = Enum.TextXAlignment.Center
					titleL.TextTruncate = Enum.TextTruncate.AtEnd
					local priceLab = lbl(
						card,
						owned and "Owned" or (priceCache[def.gamePassId] or "…"),
						UDim2.new(1, -10, 0, 24),
						UDim2.fromOffset(5, 182),
						15,
						owned and GREEN or GOLD,
						36,
						Enum.Font.GothamBold
					)
					priceLab.TextXAlignment = Enum.TextXAlignment.Center
					if not owned then
						fetchPrice(def.gamePassId, priceLab)
					end

					imgBtn.MouseButton1Click:Connect(function()
						if not owned then
							Net.PromptGamePass(def.gamePassId)
						end
					end)
					imgBtn.MouseEnter:Connect(function()
						setTooltip({
							title = def.title,
							extra = owned and "● Owned" or (priceCache[def.gamePassId] or "LMB buy"),
							power = def.desc,
						})
					end)
					imgBtn.MouseLeave:Connect(hideTooltip)
				end
			end
			local row = actionsRow()
			lbl(row, "LMB purchase gamepass", UDim2.fromOffset(220, 34), nil, 13, TL, 35)

		---------------------------------------------------------------- PROFILE
		else
			local viewUserId = inspectUserId or (lp and lp.UserId) or 0
			countLab.Text = inspectName and ("@" .. inspectName) or "You"
			local scroll = UIKit.Scroll(main, UDim2.new(1, -12, 1, -12))
			scroll.Position = UDim2.fromOffset(6, 6)

			local searchBar = solid(scroll, "Search", UDim2.new(1, -8, 0, 50), nil, BG_SECTION, 35)
			searchBar.LayoutOrder = 0
			UIKit.Stroke(searchBar, BD2, 1, 0.15)
			UIKit.Pad(searchBar, 8)

			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -100, 1, 0)
			box.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
			box.BackgroundTransparency = 0
			box.BorderSizePixel = 0
			box.PlaceholderText = "@username (online)"
			box.PlaceholderColor3 = TL
			box.Text = inspectName and ("@" .. inspectName) or ""
			box.TextColor3 = TW
			box.Font = Enum.Font.Gotham
			box.TextSize = 15
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.ClearTextOnFocus = false
			box.ZIndex = 37
			box.Parent = searchBar
			UIKit.Corner(box, 4)
			UIKit.Pad(box, nil, 12, 0, 12, 0)

			local searchBtn = Instance.new("TextButton")
			searchBtn.Size = UDim2.fromOffset(90, 34)
			searchBtn.Position = UDim2.new(1, -90, 0.5, 0)
			searchBtn.AnchorPoint = Vector2.new(0, 0.5)
			searchBtn.BackgroundColor3 = Color3.fromRGB(0, 90, 80)
			searchBtn.BackgroundTransparency = 0
			searchBtn.BorderSizePixel = 0
			searchBtn.Text = "Search"
			searchBtn.TextColor3 = TW
			searchBtn.Font = Enum.Font.GothamBold
			searchBtn.TextSize = 13
			searchBtn.ZIndex = 37
			searchBtn.Parent = searchBar
			UIKit.Corner(searchBtn, 4)

			local statusLab = lbl(
				scroll,
				inspectStatus or "Your stats or search an online player",
				UDim2.new(1, -8, 0, 22),
				nil,
				12,
				inspectStatus and GOLD or TL,
				35
			)
			statusLab.LayoutOrder = 1

			local function doSearch()
				local q = box.Text
				if q == "" or q == "@" then
					inspectName = nil
					inspectUserId = nil
					inspectStats = nil
					inspectLocation = nil
					inspectStatus = nil
					api:Refresh()
					return
				end
				inspectStatus = "Searching…"
				api:Refresh()
				task.spawn(function()
					local res = Net.GetPublicProfile(q)
					if type(res) == "table" and res.ok then
						inspectName = res.name
						inspectUserId = res.userId
						inspectStats = res.stats
						inspectLocation = res.currentLocation
						inspectStatus = string.format("Viewing @%s", res.name)
					else
						inspectName = nil
						inspectUserId = nil
						inspectStats = nil
						inspectLocation = nil
						inspectStatus = (type(res) == "table" and res.error) or "Not found"
					end
					api:Refresh()
				end)
			end
			searchBtn.MouseButton1Click:Connect(doSearch)
			box.FocusLost:Connect(function(enter)
				if enter then
					doSearch()
				end
			end)

			local headRow = solid(scroll, "HeadRow", UDim2.new(1, -8, 0, 130), nil, BG_SECTION, 35)
			headRow.LayoutOrder = 2
			UIKit.Stroke(headRow, BD, 1, 0.15)

			local bust = Instance.new("ImageLabel")
			bust.Size = UDim2.fromOffset(110, 110)
			bust.Position = UDim2.fromOffset(12, 10)
			bust.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			bust.BackgroundTransparency = 0
			bust.BorderSizePixel = 0
			bust.Image = avatarBustUrl(viewUserId)
			bust.ScaleType = Enum.ScaleType.Crop
			bust.ZIndex = 36
			bust.Parent = headRow
			UIKit.Corner(bust, 8)
			UIKit.Stroke(bust, CYAN, 1.5, 0.25)

			lbl(headRow, inspectName or (lp and lp.DisplayName) or "Player", UDim2.new(1, -140, 0, 30), UDim2.fromOffset(136, 18), 20, TW, 36)
			lbl(headRow, "@" .. (inspectName or (lp and lp.Name) or "player"), UDim2.new(1, -140, 0, 22), UDim2.fromOffset(136, 52), 14, CYAN, 36, Enum.Font.Gotham)
			if inspectName then
				local meBtn = Instance.new("TextButton")
				meBtn.Size = UDim2.fromOffset(120, 30)
				meBtn.Position = UDim2.fromOffset(136, 84)
				meBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				meBtn.BackgroundTransparency = 0
				meBtn.Text = "Back to me"
				meBtn.TextColor3 = TW
				meBtn.Font = Enum.Font.GothamBold
				meBtn.TextSize = 12
				meBtn.BorderSizePixel = 0
				meBtn.ZIndex = 37
				meBtn.Parent = headRow
				UIKit.Corner(meBtn, 4)
				meBtn.MouseButton1Click:Connect(function()
					inspectName = nil
					inspectUserId = nil
					inspectStats = nil
					inspectLocation = nil
					inspectStatus = nil
					api:Refresh()
				end)
			end

			local s = inspectStats or stats
			local cols = Instance.new("Frame")
			cols.BackgroundTransparency = 1
			cols.Size = UDim2.new(1, -8, 0, 280)
			cols.LayoutOrder = 3
			cols.ZIndex = 35
			cols.Parent = scroll
			UIKit.List(cols, 12, true)

			local function colPanel(name: string, order: number): Frame
				local p = solid(cols, name, UDim2.new(0.5, -8, 1, 0), nil, BG_SECTION, 36)
				p.LayoutOrder = order
				UIKit.Stroke(p, BD, 1, 0.15)
				UIKit.Pad(p, 12)
				local list = Instance.new("UIListLayout")
				list.Padding = UDim.new(0, 5)
				list.SortOrder = Enum.SortOrder.LayoutOrder
				list.Parent = p
				return p
			end
			local leftCol = colPanel("Mods", 1)
			local rightCol = colPanel("Combat", 2)
			lbl(leftCol, "MODIFIERS", UDim2.new(1, 0, 0, 18), nil, 11, TL, 37).LayoutOrder = 0
			lbl(rightCol, "COMBAT STATS", UDim2.new(1, 0, 0, 18), nil, 11, TL, 37).LayoutOrder = 0

			local function statLine(parent: Frame, order: number, label: string, value: string, dot: Color3, vcol: Color3?)
				local line = solid(parent, "L" .. order, UDim2.new(1, 0, 0, 24), nil, BG_SECTION, 37)
				line.BackgroundTransparency = 1
				line.LayoutOrder = order
				local d = Instance.new("Frame")
				d.Size = UDim2.fromOffset(8, 8)
				d.Position = UDim2.new(0, 0, 0.5, 0)
				d.AnchorPoint = Vector2.new(0, 0.5)
				d.BackgroundColor3 = dot
				d.BorderSizePixel = 0
				d.ZIndex = 38
				d.Parent = line
				UIKit.Corner(d, 99)
				lbl(line, label, UDim2.new(0.58, -12, 1, 0), UDim2.fromOffset(14, 0), 13, TD, 38, Enum.Font.Gotham)
				local v = lbl(line, value, UDim2.new(0.42, 0, 1, 0), UDim2.new(0.58, 0, 0, 0), 13, vcol or TW, 38, Enum.Font.GothamBold)
				v.TextXAlignment = Enum.TextXAlignment.Right
			end

			statLine(leftCol, 1, "Click power", Format.Num(s and (s.damagePerClick or s.totalPower) or 0), Color3.fromRGB(204, 68, 68), TW)
			statLine(leftCol, 2, "CPS", string.format("%.2f", s and s.cps or 0), GREEN, GREEN)
			statLine(leftCol, 3, "Crit", Format.Pct(s and s.crit or 0), GOLD, GOLD)
			statLine(leftCol, 4, "Luck", Format.Pct(s and s.luck or 0), CYAN, GREEN)
			statLine(leftCol, 5, "Rebirth", string.format("R%d %s", s and (s.rebirthLevel or 0) or 0, s and Format.Mult(s.rebirthMult) or "x1"), GOLD, GOLD)
			statLine(rightCol, 1, "DPS", Format.Num(s and s.dps or 0), Color3.fromRGB(204, 68, 68), TW)
			statLine(rightCol, 2, "Coins", Format.Num(s and s.coins or 0), GOLD, GOLD)
			statLine(rightCol, 3, "Clicks", Format.Num(s and s.totalClicks or 0), GREEN, TW)
			statLine(rightCol, 4, "Life dmg", Format.Num(s and s.lifetimeDamage or 0), Color3.fromRGB(144, 112, 192), TW)
			statLine(rightCol, 5, "Location", tostring(inspectLocation or profile.currentLocation or 1), CYAN, CYAN)

			local row = actionsRow()
			lbl(row, inspectName and ("Viewing @" .. inspectName) or "Your live profile", UDim2.fromOffset(260, 34), nil, 13, TL, 35)
		end
	end

	return api
end

return Inventory
