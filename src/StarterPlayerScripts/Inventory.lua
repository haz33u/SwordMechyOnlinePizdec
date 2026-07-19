--!strict
--[[
	Inventory UI from Figma Make INVETAR + live game data.
	Large slots, opaque item plates, cursor tooltips, hover pulse,
	gamepass prices, profile AvatarBust + @username inspect, sell-all swords.
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
local Titles = require(script.Parent.Titles)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(Shared.Config.WeaponConfig)
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local IconConfig = require(Shared.Config.IconConfig)
local GamePassConfig = require(Shared.Config.GamePassConfig)
local WorldConfig = require(Shared.Config.WorldConfig)

local Inventory = {}

-- Larger readable design tokens
local BG_PANEL = Color3.fromRGB(24, 24, 24)
local BG_SECTION = Color3.fromRGB(32, 32, 32)
local BG_SLOT = Color3.fromRGB(34, 34, 34)
local BG_SLOT_MT = Color3.fromRGB(22, 22, 22)
local BD = Color3.fromRGB(48, 48, 48)
local BD2 = Color3.fromRGB(62, 62, 62)
local TW = Color3.fromRGB(204, 204, 204)
local TD = Color3.fromRGB(118, 118, 118)
local TL = Color3.fromRGB(72, 72, 72)
local CYAN = Color3.fromRGB(0, 255, 224)
local GOLD = Color3.fromRGB(232, 184, 0)
local RED_CLOSE = Color3.fromRGB(204, 34, 0)
local GREEN = Color3.fromRGB(120, 170, 100)

local SLOT_GAP = 16 -- room for hover scale + neon glow
local COLS = 9 -- target columns; cell size fills width
local MAX_SLOTS = 45
local INV_CAP = 32
local TAB_R = 64
-- Mild hover (strong scale was breaking UIStrokes + flickering on slot change)
local HOVER_SCALE = 1.06
local NEIGHBOR_SCALE = 0.97
local HOVER_LEAVE_DELAY = 0.07

--[[
	Bottom tabs ≈ nobackground.png: rounded icon tiles, semi-transparent fill,
	white symbol, NO solid black plate under them.
	Images: free Creator Store Decals (Texture ids verified in Studio).
]]
local TABS = {
	{ id = "weapons", glyph = "⚔", label = "Weapons", image = "rbxassetid://292768036" }, -- Sword.Png TRANSPARENT
	{ id = "pets", glyph = "🐾", label = "Pets", image = "rbxassetid://18514765742" }, -- Pet Icon
	{ id = "auras", glyph = "✦", label = "Auras", image = "rbxassetid://119757312338567" }, -- Star
	{ id = "relics", glyph = "◆", label = "Relics", image = "rbxassetid://9650296120" }, -- gem
	{ id = "cases", glyph = "▣", label = "Cases", image = "rbxassetid://10168237291" }, -- chest
	{ id = "shop", glyph = "$", label = "Shop", image = "rbxassetid://5684864511" }, -- gold coin
	{ id = "profile", glyph = "☺", label = "Profile", image = "rbxassetid://98048782159448" }, -- bust
}

local function rarityBorder(r: string?): Color3
	return Rarity.Of(r)
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
	l.Font = font or Enum.Font.Arcade
	l.TextSize = sizePx or 13
	l.TextColor3 = color or TW
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.ZIndex = z or 34
	l.Parent = parent
	return l
end

local function keybind(parent: Instance, order: number, key: string, desc: string)
	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.fromOffset(0, 32)
	wrap.AutomaticSize = Enum.AutomaticSize.X
	wrap.LayoutOrder = order
	wrap.ZIndex = 35
	wrap.Parent = parent
	UIKit.List(wrap, 6, true)

	local badge = Instance.new("TextLabel")
	badge.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	badge.BackgroundTransparency = 0
	badge.BorderSizePixel = 0
	badge.Text = key
	badge.Font = Enum.Font.Arcade
	badge.TextSize = 11
	badge.TextColor3 = TD
	badge.Size = UDim2.fromOffset(0, 24)
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.ZIndex = 36
	badge.Parent = wrap
	UIKit.Pad(badge, nil, 8, 3, 8, 3)
	UIKit.Stroke(badge, BD2, 1, 0.15)

	local d = Instance.new("TextLabel")
	d.BackgroundTransparency = 1
	d.Text = desc
	d.Font = Enum.Font.Arcade
	d.TextSize = 13
	d.TextColor3 = TL
	d.Size = UDim2.fromOffset(0, 24)
	d.AutomaticSize = Enum.AutomaticSize.X
	d.ZIndex = 36
	d.Parent = wrap
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

	-- Profile inspect (other online player)
	local inspectName: string? = nil
	local inspectUserId: number? = nil
	local inspectStats: any? = nil
	local inspectLocation: number? = nil
	local inspectStatus: string? = nil

	local canvas: Frame
	local titleLab: TextLabel
	local countLab: TextLabel
	local identityLab: TextLabel
	local locLab: TextLabel
	local main: Frame
	local actions: Frame
	local tip: Frame
	-- Left preview strip removed (user request) — keep stubs so refresh calls stay safe
	local previewLab: TextLabel? = nil
	local previewImg: ImageLabel? = nil
	local miniSlots: { Frame } = {}
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

	--[[
		Tooltip pinned to cursor edge (refICONTOLLTIP style):
		- prefer RIGHT of cursor: left edge of tip = mouse + EDGE
		- if no room, LEFT of cursor: right edge of tip = mouse - EDGE
		- never floats free of the cursor with a large clamp offset
		ScreenGui.IgnoreGuiInset = false → subtract GuiInset from mouse.
	]]
	local function placeTooltip()
		if not tip.Visible or not tip.Parent then
			return
		end
		local parent = tip.Parent :: GuiObject
		local inset = GuiService:GetGuiInset()
		local mouse = UserInputService:GetMouseLocation()
		-- convert to same space as Gui AbsolutePosition (IgnoreGuiInset=false)
		local mx = mouse.X - inset.X
		local my = mouse.Y - inset.Y

		local tipW = tip.AbsoluteSize.X
		local tipH = tip.AbsoluteSize.Y
		if tipW < 8 then
			tipW = 320
		end
		if tipH < 8 then
			tipH = 160
		end

		local parentAbs = parent.AbsolutePosition
		local parentSz = parent.AbsoluteSize
		local EDGE = 10 -- cursor sits on the outer edge of the tooltip

		-- Prefer: tooltip to the RIGHT of cursor
		local screenX = mx + EDGE
		local screenY = my + 4
		local placeRight = true
		if screenX + tipW > parentAbs.X + parentSz.X - 4 then
			-- flip: tooltip to the LEFT of cursor
			placeRight = false
			screenX = mx - EDGE - tipW
		end
		if screenY + tipH > parentAbs.Y + parentSz.Y - 4 then
			screenY = parentAbs.Y + parentSz.Y - tipH - 4
		end
		if screenY < parentAbs.Y + 2 then
			screenY = parentAbs.Y + 2
		end
		-- Keep X glued to cursor edge (only clamp if still out after flip)
		if placeRight then
			if screenX < parentAbs.X + 2 then
				screenX = parentAbs.X + 2
			end
		else
			if screenX + tipW > parentAbs.X + parentSz.X - 2 then
				screenX = parentAbs.X + parentSz.X - tipW - 2
			end
		end

		local localX = math.floor(screenX - parentAbs.X + 0.5)
		local localY = math.floor(screenY - parentAbs.Y + 0.5)
		tip.Position = UDim2.fromOffset(localX, localY)
	end

	local function clearTipBody()
		for _, c in tip:GetChildren() do
			if c:IsA("TextLabel") or (c:IsA("Frame") and c.Name ~= "Pad") then
				if not c:IsA("UIListLayout") and not c:IsA("UIPadding") and not c:IsA("UIStroke") and not c:IsA("UICorner") and not c:IsA("UISizeConstraint") then
					c:Destroy()
				end
			end
		end
	end

	local function tipRow(order: number, text: string, color: Color3?, bold: boolean?): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = "Row" .. order
		l.BackgroundTransparency = 1
		l.BorderSizePixel = 0
		l.Size = UDim2.new(1, 0, 0, 0)
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		l.TextSize = bold and 20 or 16
		l.TextColor3 = color or TW
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top
		l.TextWrapped = true
		l.Text = text
		l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		l.TextStrokeTransparency = 0.55
		l.LayoutOrder = order
		l.ZIndex = (tip.ZIndex or 90) + 1
		l.Parent = tip
		return l
	end

	--[[
		Structured like ref:
		  Title
		  Rarity: Common
		  (gap)
		  Power: …
		  Sell: …
		  Level: …
		  ● Equipped  (inside bounds, wrapped)
	]]
	local function setTooltip(title: string, rarity: string?, desc: string?, extra: string?, borderCol: Color3?)
		clearTipBody()
		local order = 1
		tipRow(order, title, borderCol or TW, true)
		order += 1
		if rarity and rarity ~= "" then
			local r = tipRow(order, "Rarity: " .. rarity, borderCol or rarityBorder(rarity), false)
			r.TextSize = 18
			order += 1
		end
		-- small spacer
		local sp = Instance.new("Frame")
		sp.Name = "Gap"
		sp.BackgroundTransparency = 1
		sp.Size = UDim2.new(1, 0, 0, 10)
		sp.LayoutOrder = order
		sp.ZIndex = tip.ZIndex
		sp.Parent = tip
		order += 1

		if desc and desc ~= "" then
			-- desc may be multi-line "Power: …\nSell: …"
			for line in string.gmatch(desc .. "\n", "([^\n]*)\n") do
				if line ~= "" then
					tipRow(order, line, Color3.fromRGB(100, 160, 220), false)
					order += 1
				end
			end
		end
		if extra and extra ~= "" then
			local e = tipRow(order, extra, CYAN, false)
			e.TextTruncate = Enum.TextTruncate.AtEnd
		end

		local st = tip:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = borderCol or rarityBorder(rarity) or BD2
		end
		tip.Visible = true
		-- layout needs a frame before AbsoluteSize is correct
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

	local function ensureScale(gui: GuiObject): UIScale
		local sc = gui:FindFirstChildOfClass("UIScale")
		if not sc then
			sc = Instance.new("UIScale")
			sc.Scale = 1
			sc.Parent = gui
		end
		return sc
	end

	-- Hover tracking. IMPORTANT: when moving A→B the old leave handler used to
	-- bail on hoverGen mismatch and NEVER reset A — neon stuck forever.
	local hoverGen = 0
	local activeHover: GuiObject? = nil
	type SlotHoverMeta = { stroke: UIStroke?, baseCol: Color3, baseZ: number, grid: Instance? }
	local slotHover: { [GuiObject]: SlotHoverMeta } = {}

	-- Neon hover: bright core stroke + soft outer glow (rarity color), idle = quiet edge
	local SLOT_STROKE_THICK = 2
	local SLOT_NEON_CORE = 2.6
	local SLOT_NEON_GLOW = 8
	local NEON_IN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function neonBright(c: Color3): Color3
		return c:Lerp(Color3.new(1, 1, 1), 0.32)
	end

	local function ensureNeonGlow(btn: GuiObject, col: Color3): UIStroke
		local existing = btn:FindFirstChild("NeonGlow")
		if existing and existing:IsA("UIStroke") then
			existing.Color = col
			return existing
		end
		local glow = Instance.new("UIStroke")
		glow.Name = "NeonGlow"
		glow.Color = col
		glow.Thickness = SLOT_NEON_GLOW
		glow.Transparency = 1
		glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		glow.LineJoinMode = Enum.LineJoinMode.Round
		glow.Parent = btn
		return glow
	end

	--- Hard idle: set values immediately so neon can never stick mid-tween
	local function forceIdleVisual(btn: GuiObject)
		if not btn.Parent then
			slotHover[btn] = nil
			return
		end
		local meta = slotHover[btn]
		local baseCol = if meta then meta.baseCol else BD
		local baseZ = if meta then meta.baseZ else 35
		local stroke = if meta then meta.stroke else btn:FindFirstChild("Edge")

		local sc = btn:FindFirstChildOfClass("UIScale")
		if sc then
			sc.Scale = 1
		end
		if stroke and stroke:IsA("UIStroke") then
			stroke.Thickness = SLOT_STROKE_THICK
			stroke.Color = baseCol
			stroke.Transparency = 0.08
		end
		local glow = btn:FindFirstChild("NeonGlow")
		if glow and glow:IsA("UIStroke") then
			glow.Color = baseCol
			glow.Thickness = SLOT_NEON_GLOW
			glow.Transparency = 1
		end
		local plate = btn:FindFirstChild("Plate")
		if plate and plate:IsA("GuiObject") then
			plate.BackgroundColor3 = BG_SLOT
		end
		btn.ZIndex = baseZ
	end

	local function applyHoverVisual(btn: GuiObject, stroke: UIStroke?, baseZ: number, baseCol: Color3)
		local sc = ensureScale(btn)
		TweenService:Create(sc, NEON_IN, { Scale = HOVER_SCALE }):Play()

		local coreCol = neonBright(baseCol)

		if stroke then
			stroke.Thickness = SLOT_NEON_CORE
			stroke.Color = coreCol
			stroke.Transparency = 0
		end

		local glow = ensureNeonGlow(btn, baseCol)
		glow.Color = baseCol
		glow.Thickness = SLOT_NEON_GLOW
		glow.Transparency = 0.42

		local plate = btn:FindFirstChild("Plate")
		if plate and plate:IsA("GuiObject") then
			plate.BackgroundColor3 = BG_SLOT:Lerp(baseCol, 0.14)
		end

		btn.ZIndex = baseZ + 8
	end

	local function setNeighborsScale(gridParent: Instance?, except: GuiObject?, scale: number)
		if not gridParent then
			return
		end
		for _, ch in gridParent:GetChildren() do
			if ch:IsA("GuiButton") and ch ~= except then
				local nsc = ensureScale(ch)
				nsc.Scale = scale
			end
		end
	end

	local function clearAllSlotHovers(gridParent: Instance?)
		if gridParent then
			for _, ch in gridParent:GetChildren() do
				if ch:IsA("GuiButton") then
					forceIdleVisual(ch)
					local nsc = ch:FindFirstChildOfClass("UIScale")
					if nsc then
						nsc.Scale = 1
					end
				end
			end
		end
	end

	--- Neon rarity glow on hover only. Leave / switch ALWAYS kills neon on that slot.
	local function bindHover(btn: GuiObject, stroke: UIStroke?, baseStroke: Color3?, gridParent: Instance?)
		ensureScale(btn)
		local baseCol = baseStroke or BD
		local baseZ = btn.ZIndex
		if stroke then
			stroke.Color = baseCol
			stroke.Thickness = SLOT_STROKE_THICK
			stroke.Transparency = 0.08
		end
		ensureNeonGlow(btn, baseCol)
		slotHover[btn] = { stroke = stroke, baseCol = baseCol, baseZ = baseZ, grid = gridParent }

		btn.Destroying:Connect(function()
			if activeHover == btn then
				activeHover = nil
			end
			slotHover[btn] = nil
		end)

		btn.MouseEnter:Connect(function()
			hoverGen += 1
			local prev = activeHover
			activeHover = btn
			-- Switching slots: kill previous neon immediately (this was the sticky bug)
			if prev and prev ~= btn then
				forceIdleVisual(prev)
			end
			applyHoverVisual(btn, stroke, baseZ, baseCol)
			setNeighborsScale(gridParent, btn, NEIGHBOR_SCALE)
		end)

		btn.MouseLeave:Connect(function()
			local gen = hoverGen
			-- Short delay only to avoid flicker when crossing cell gap into neighbor
			task.delay(HOVER_LEAVE_DELAY, function()
				if not btn.Parent then
					return
				end
				if activeHover == btn and hoverGen == gen then
					-- Left into empty space — fully idle grid
					activeHover = nil
					forceIdleVisual(btn)
					clearAllSlotHovers(gridParent)
					return
				end
				-- Entered another slot (gen changed) OR activeHover moved on —
				-- this button must still go idle. Never bail without reset.
				if activeHover ~= btn then
					forceIdleVisual(btn)
				end
			end)
		end)
	end

	--- Opaque filled slot (grid CellSize drives size)
	local function makeItemSlot(parent: Instance, order: number, edge: Color3): (TextButton, Frame, UIStroke)
		local btn = Instance.new("TextButton")
		btn.Name = "Slot" .. order
		btn.Size = UDim2.fromOffset(80, 80)
		btn.BackgroundColor3 = BG_SLOT
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		-- false so scaled hover/neon glow are not clipped mid-edge
		btn.ClipsDescendants = false
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

		local stroke = UIKit.Stroke(btn, edge, SLOT_STROKE_THICK, 0.08)
		stroke.Name = "Edge"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		ensureNeonGlow(btn, edge)
		bindHover(btn, stroke, edge, parent)
		return btn, plate, stroke
	end

	local function emptySlot(parent: Instance, order: number)
		local btn = Instance.new("TextButton")
		btn.Name = "E" .. order
		btn.Size = UDim2.fromOffset(80, 80)
		btn.BackgroundColor3 = BG_SLOT_MT
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Active = false
		btn.LayoutOrder = order
		btn.ZIndex = 35
		btn.Parent = parent
		UIKit.Stroke(btn, BD, SLOT_STROKE_THICK, 0.2)
	end

	--- Full-page scroll for Shop / Profile: top air so first row is not clipped by Main
	local function makePageScroll(parent: Instance): ScrollingFrame
		local scroll = UIKit.Scroll(parent, UDim2.new(1, -16, 1, -22))
		scroll.Position = UDim2.fromOffset(8, 14)
		scroll.ZIndex = 34
		scroll.ClipsDescendants = true
		scroll.ScrollBarThickness = 8
		scroll.ScrollBarImageColor3 = BD2
		-- UIKit.Scroll seeds Pad(2) + List(VerticalAlignment.Center) — both clip the top
		for _, c in scroll:GetChildren() do
			if c:IsA("UIPadding") then
				c.PaddingTop = UDim.new(0, 16)
				c.PaddingBottom = UDim.new(0, 14)
				c.PaddingLeft = UDim.new(0, 10)
				c.PaddingRight = UDim.new(0, 10)
			elseif c:IsA("UIListLayout") then
				c.Padding = UDim.new(0, 12)
				c.VerticalAlignment = Enum.VerticalAlignment.Top
				c.HorizontalAlignment = Enum.HorizontalAlignment.Left
				c.SortOrder = Enum.SortOrder.LayoutOrder
			end
		end
		return scroll
	end

	--- Grid that fills the whole tab width (cells scale to fit COLS columns).
	local function makeSlotGrid(parent: Instance): ScrollingFrame
		local scroll = Instance.new("ScrollingFrame")
		scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		scroll.BackgroundTransparency = 0
		scroll.BorderSizePixel = 0
		scroll.Size = UDim2.new(1, -8, 1, -8)
		scroll.Position = UDim2.fromOffset(4, 4)
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 8
		scroll.ScrollBarImageColor3 = BD2
		scroll.ZIndex = 34
		-- clip canvas content but leave a little pad so mild hover scale is not cut off
		scroll.ClipsDescendants = true
		scroll.Parent = parent
		local pad = 12
		UIKit.Pad(scroll, pad)
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = UDim2.fromOffset(SLOT_GAP, SLOT_GAP)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = COLS
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
		grid.Parent = scroll

		local function relayout()
			local w = scroll.AbsoluteSize.X
			if w < 40 then
				return
			end
			local inner = w - pad * 2 - scroll.ScrollBarThickness
			local cell = math.floor((inner - SLOT_GAP * (COLS - 1)) / COLS)
			cell = math.clamp(cell, 52, 140)
			grid.CellSize = UDim2.fromOffset(cell, cell)
		end
		scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
		task.defer(relayout)
		return scroll
	end

	--- Shop / card grid fills width with adaptive cell size
	local function makeFillCardGrid(scroll: ScrollingFrame, preferW: number, preferH: number, maxCols: number)
		for _, ch in scroll:GetChildren() do
			if ch:IsA("UIListLayout") or ch:IsA("UIGridLayout") then
				ch:Destroy()
			end
		end
		local pad = 10
		UIKit.Pad(scroll, pad)
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = UDim2.fromOffset(10, 10)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
		grid.Parent = scroll
		local function relayout()
			local w = scroll.AbsoluteSize.X
			if w < 40 then
				return
			end
			local inner = w - pad * 2 - scroll.ScrollBarThickness
			local cols = math.clamp(math.floor(inner / (preferW + 10)), 1, maxCols)
			local cellW = math.floor((inner - 10 * (cols - 1)) / cols)
			local cellH = math.floor(cellW * (preferH / preferW))
			grid.CellSize = UDim2.fromOffset(cellW, cellH)
			grid.FillDirectionMaxCells = cols
		end
		scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
		task.defer(relayout)
		return grid
	end

	--- Action chips (Equip best, etc.) — large readable buttons every tab
	local function actBtn(parent: Instance, text: string, color: Color3, order: number, onClick: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(0, 52)
		b.AutomaticSize = Enum.AutomaticSize.X
		b.BackgroundColor3 = color
		b.BackgroundTransparency = 0
		b.BorderSizePixel = 0
		b.Text = text
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 17
		b.AutoButtonColor = false
		b.LayoutOrder = order
		b.ZIndex = 35
		b.Parent = parent
		UIKit.Corner(b, 10)
		UIKit.Stroke(b, Color3.fromRGB(255, 255, 255), 1.5, 0.55)
		UIKit.Pad(b, nil, 20, 6, 20, 6)
		local sc = ensureScale(b)
		b.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1.06,
			}):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1 }):Play()
		end)
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	local function actionsRow(): Frame
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -24, 1, -6)
		row.Position = UDim2.fromOffset(14, 6)
		row.ZIndex = 34
		row.Parent = actions
		UIKit.List(row, 10, true, Enum.HorizontalAlignment.Left)
		return row
	end

	local function setPreviewAvatar(userId: number?, glyphFallback: string)
		-- Left strip removed — avatar only on Profile tab body (if built)
		if previewImg and previewLab then
			if userId and userId > 0 then
				previewImg.Image = avatarBustUrl(userId)
				previewImg.Visible = true
				previewLab.Visible = false
			else
				previewImg.Visible = false
				previewLab.Visible = true
				previewLab.Text = glyphFallback
			end
		end
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

		-- Variant B: single header row — tab title left, Title|Nick + Loc chips right (no grey info strip)
		local HEADER_H = 56
		local header = solid(canvas, "Header", UDim2.new(1, 0, 0, HEADER_H), UDim2.fromOffset(0, 0), Color3.fromRGB(18, 18, 18), 32)
		solid(header, "Line", UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), BD, 33)

		titleLab = lbl(header, "Inventory — Weapons", UDim2.new(0.38, 0, 1, 0), UDim2.fromOffset(16, 0), 16, TW, 34, Enum.Font.GothamBold)
		titleLab.Name = "Title"
		titleLab.TextXAlignment = Enum.TextXAlignment.Left
		titleLab.TextTruncate = Enum.TextTruncate.AtEnd

		local close = Instance.new("TextButton")
		close.Name = "Close"
		close.Size = UDim2.fromOffset(32, 32)
		close.Position = UDim2.new(1, -42, 0.5, 0)
		close.AnchorPoint = Vector2.new(0, 0.5)
		close.BackgroundColor3 = RED_CLOSE
		close.BackgroundTransparency = 0
		close.Text = "✕"
		close.TextColor3 = Color3.new(1, 1, 1)
		close.Font = Enum.Font.GothamBold
		close.TextSize = 14
		close.AutoButtonColor = false
		close.BorderSizePixel = 0
		close.ZIndex = 36
		close.Parent = header
		UIKit.Corner(close, 99)
		close.MouseButton1Click:Connect(onClose)

		-- Right cluster: count · Title|Nick · Loc  (before close)
		local right = Instance.new("Frame")
		right.Name = "HeaderRight"
		right.BackgroundTransparency = 1
		right.Size = UDim2.new(0.58, -56, 1, -10)
		right.Position = UDim2.new(1, -48, 0.5, 0)
		right.AnchorPoint = Vector2.new(1, 0.5)
		right.ZIndex = 34
		right.Parent = header
		local rightList = UIKit.List(right, 8, true, Enum.HorizontalAlignment.Right)
		rightList.VerticalAlignment = Enum.VerticalAlignment.Center
		rightList.Padding = UDim.new(0, 8)

		countLab = lbl(right, "", UDim2.fromOffset(90, 28), nil, 13, TL, 35, Enum.Font.Gotham)
		countLab.Name = "Count"
		countLab.LayoutOrder = 1
		countLab.TextXAlignment = Enum.TextXAlignment.Right
		countLab.AutomaticSize = Enum.AutomaticSize.X
		countLab.Size = UDim2.fromOffset(0, 28)

		local function headerChip(name: string, order: number, edge: Color3, w: number): (Frame, TextLabel)
			local chip = Instance.new("Frame")
			chip.Name = name
			chip.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
			chip.BackgroundTransparency = 0.05
			chip.BorderSizePixel = 0
			chip.Size = UDim2.fromOffset(w, 34)
			chip.AutomaticSize = Enum.AutomaticSize.X
			chip.LayoutOrder = order
			chip.ZIndex = 35
			chip.Parent = right
			UIKit.Corner(chip, 8)
			UIKit.Stroke(chip, edge, 1.4, 0.2)
			UIKit.Pad(chip, nil, 12, 0, 12, 0)

			local lab = Instance.new("TextLabel")
			lab.Name = "Text"
			lab.BackgroundTransparency = 1
			lab.Size = UDim2.fromOffset(0, 34)
			lab.AutomaticSize = Enum.AutomaticSize.X
			lab.Font = Titles.Font
			lab.TextSize = 15
			lab.TextColor3 = TW
			lab.TextXAlignment = Enum.TextXAlignment.Center
			lab.TextYAlignment = Enum.TextYAlignment.Center
			lab.RichText = true
			lab.Text = ""
			lab.ZIndex = 36
			lab.Parent = chip
			return chip, lab
		end

		local _, idLab = headerChip("Identity", 2, Titles.TitleColor, 200)
		identityLab = idLab
		identityLab.TextSize = 16
		identityLab.Font = Titles.Font

		local _, lLab = headerChip("Loc", 3, Color3.fromRGB(90, 160, 255), 100)
		locLab = lLab
		locLab.Font = Enum.Font.GothamBold
		locLab.TextSize = 14
		locLab.TextColor3 = Color3.fromRGB(170, 210, 255)
		locLab.RichText = false

		local actionH = 68 -- room for larger Equip best / action chips
		local contentH = HEADER_H + actionH + 100
		-- Full-width main (info strip removed — more room for slots)
		main = solid(canvas, "Main", UDim2.new(1, 0, 1, -contentH), UDim2.fromOffset(0, HEADER_H), Color3.fromRGB(20, 20, 20), 32)
		main.BackgroundTransparency = 0
		main.ClipsDescendants = true
		main.Name = "Main"

		actions = solid(canvas, "Actions", UDim2.new(1, 0, 0, actionH), UDim2.new(0, 0, 1, -(actionH + 100)), Color3.fromRGB(16, 16, 16), 32)
		actions.Name = "Actions"
		solid(actions, "Line", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, 0), BD, 33)

		local tabs = solid(canvas, "Tabs", UDim2.new(1, 0, 0, 100), UDim2.new(0, 0, 1, -100), Color3.fromRGB(12, 12, 12), 32)
		solid(tabs, "Line", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, 0), BD, 33)
		local tabRow = Instance.new("Frame")
		tabRow.BackgroundTransparency = 1
		tabRow.Size = UDim2.new(1, -16, 1, -12)
		tabRow.Position = UDim2.fromOffset(8, 10)
		tabRow.ZIndex = 33
		tabRow.Parent = tabs
		UIKit.List(tabRow, 14, true, Enum.HorizontalAlignment.Center)

		for _, def in ipairs(TABS) do
			local col = Instance.new("Frame")
			col.Name = def.id .. "Col"
			col.BackgroundTransparency = 1
			col.Size = UDim2.fromOffset(TAB_R + 12, 88)
			col.ZIndex = 34
			col.Parent = tabRow

			--[[
				nobackground.png style:
				- rounded icon tile (not a solid black plate under art)
				- semi-transparent dark fill so game/UI peeks through
				- ImageButton always clickable; glyph always readable if image fails
			]]
			local b = Instance.new("ImageButton")
			b.Name = def.id
			b.Size = UDim2.fromOffset(TAB_R, TAB_R)
			b.Position = UDim2.new(0.5, 0, 0, 0)
			b.AnchorPoint = Vector2.new(0.5, 0)
			b.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
			b.BackgroundTransparency = 0.22 -- soft round tile, not opaque plate
			b.BorderSizePixel = 0
			b.Image = def.image
			b.ImageTransparency = 0
			b.ImageColor3 = Color3.new(1, 1, 1)
			b.ScaleType = Enum.ScaleType.Fit
			b.AutoButtonColor = false
			b.ZIndex = 36
			b.Parent = col
			UIKit.Corner(b, 14) -- rounded square like ref icons

			local glyph = Instance.new("TextLabel")
			glyph.Name = "Glyph"
			glyph.BackgroundTransparency = 1
			glyph.Size = UDim2.fromScale(1, 1)
			glyph.Font = Enum.Font.Arcade
			glyph.TextSize = 28
			glyph.Text = def.glyph
			glyph.TextColor3 = Color3.fromRGB(235, 235, 240)
			glyph.TextTransparency = 0.15
			glyph.ZIndex = 37
			glyph.Parent = b
			glyph.TextXAlignment = Enum.TextXAlignment.Center
			glyph.TextYAlignment = Enum.TextYAlignment.Center
			-- If image loads, soft-hide glyph so art shows; keep clickable either way
			-- Glyph stays readable; image draws on top when asset loads in place
			task.spawn(function()
				local ContentProvider = game:GetService("ContentProvider")
				pcall(function()
					ContentProvider:PreloadAsync({ def.image })
				end)
			end)

			local hoverScale = Instance.new("UIScale")
			hoverScale.Scale = 1
			hoverScale.Parent = b
			b.MouseEnter:Connect(function()
				TweenService:Create(hoverScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Scale = 1.14,
				}):Play()
				TweenService:Create(b, TweenInfo.new(0.1), { BackgroundTransparency = 0.05 }):Play()
			end)
			b.MouseLeave:Connect(function()
				TweenService:Create(hoverScale, TweenInfo.new(0.1), { Scale = 1 }):Play()
				TweenService:Create(b, TweenInfo.new(0.1), { BackgroundTransparency = 0.22 }):Play()
			end)

			local lab = lbl(col, def.label, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), 12, Color3.fromRGB(90, 90, 90), 35)
			lab.TextXAlignment = Enum.TextXAlignment.Center
			lab.Font = Enum.Font.Arcade

			tabButtons[def.id] = b
			tabLabels[def.id] = lab
			b.MouseButton1Click:Connect(function()
				tab = def.id
				api:Refresh()
			end)
		end

		-- Tooltip: readable but not too wide (less empty space)
		tip = solid(canvas, "Tooltip", UDim2.fromOffset(240, 0), UDim2.fromOffset(0, 0), Color3.fromRGB(22, 22, 28), 120)
		tip.Visible = false
		tip.BackgroundTransparency = 0.04
		tip.ClipsDescendants = true
		tip.AutomaticSize = Enum.AutomaticSize.XY
		UIKit.Stroke(tip, BD2, 2, 0.08)
		UIKit.Pad(tip, 12)
		local pad = tip:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.Name = "Pad"
			pad.PaddingTop = UDim.new(0, 12)
			pad.PaddingBottom = UDim.new(0, 12)
			pad.PaddingLeft = UDim.new(0, 12)
			pad.PaddingRight = UDim.new(0, 12)
		end
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 4)
		list.Parent = tip
		local tipMax = Instance.new("UISizeConstraint")
		tipMax.MinSize = Vector2.new(200, 72)
		tipMax.MaxSize = Vector2.new(280, 280)
		tipMax.Parent = tip

		if mouseMove then
			mouseMove:Disconnect()
		end
		mouseMove = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible then
				placeTooltip()
			end
		end)
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

		-- Drop any stuck hover before rebuild (destroyed slots can't leave cleanly)
		activeHover = nil
		hoverGen += 1
		table.clear(slotHover)

		ensureShell()
		clearMainAndActions()
		hideTooltip()
		preloadPrices()

		for id, b in tabButtons do
			local on = id == tab
			b.ImageTransparency = on and 0 or 0.28
			local lab = tabLabels[id]
			if lab then
				lab.TextColor3 = on and CYAN or Color3.fromRGB(74, 74, 74)
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
		local showNick = inspectName
			or (lp and ((lp.DisplayName ~= "" and lp.DisplayName) or lp.Name))
			or "Player"
		-- Future: inspect profile.title when viewing others; for now local title only when not inspecting
		local showTitle = if inspectName then Titles.DEFAULT else Titles.Of(profile)
		local showLoc = inspectLocation or profile.currentLocation or 1
		local locMeta = WorldConfig.GetMeta(showLoc)
		local locName = (locMeta and locMeta.name) or ("Loc " .. tostring(showLoc))

		if identityLab then
			identityLab.Text = Titles.Rich(showTitle, showNick)
		end
		if locLab then
			locLab.Text = locName
			if inspectName then
				locLab.Text = locName .. " · VIEW"
			end
		end

		local function setMini(i: number, text: string, col: Color3?)
			local m = miniSlots[i]
			if not m then
				return
			end
			local icon = m:FindFirstChild("Icon")
			if icon and icon:IsA("TextLabel") then
				icon.Text = text
				icon.TextColor3 = col or TL
			end
		end
		setMini(1, "M", CYAN)
		setMini(2, "O", profile.unlocks and profile.unlocks.offhand and GOLD or TL)
		setMini(3, "A", profile.equippedAura and GREEN or TL)

		---------------------------------------------------------------- WEAPONS
		if tab == "weapons" then
			setPreviewAvatar(nil, "⚔")
			local weapons = profile.weapons or {}
			countLab.Text = string.format("%d OF %d", #weapons, INV_CAP)

			local scroll = makeSlotGrid(main)
			local offUnlocked = (stats and stats.offhandUnlocked) == true
				or (profile.unlocks and profile.unlocks.offhand) == true

			local function makeWeaponSlot(i: number, w: any?)
				if not w then
					emptySlot(scroll, i)
					return
				end
				local def = WeaponConfig.Get(w.id)
				local edge = rarityBorder(def and def.rarity)
				-- Always rarity stroke (idle + hover). No sticky cyan "selected" border.
				local btn, plate = makeItemSlot(scroll, i, edge)
				plate.BackgroundColor3 = BG_SLOT
				btn.Name = "W_" .. w.uid

				local img = Instance.new("ImageLabel")
				img.BackgroundColor3 = BG_SLOT
				img.BackgroundTransparency = 0
				img.BorderSizePixel = 0
				img.Size = UDim2.fromScale(0.78, 0.78)
				img.Position = UDim2.fromScale(0.5, 0.48)
				img.AnchorPoint = Vector2.new(0.5, 0.5)
				img.Image = IconConfig.GetWeaponImage(w.id)
				img.ScaleType = Enum.ScaleType.Fit
				img.ZIndex = 36
				img.Parent = btn

				if profile.equippedMain == w.uid or profile.equippedOffhand == w.uid then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(8, 8)
					dot.Position = UDim2.fromOffset(5, 5)
					-- Equipped marker uses rarity edge, not cyan selection
					dot.BackgroundColor3 = edge
					dot.BackgroundTransparency = 0
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end

				local name = (def and def.name) or WeaponConfig.GetDisplayName(w.id)
				local rar = (def and def.rarity) or "Common"
				local mult = (def and def.powerMult) or 1
				local sellP = (def and def.sellPrice) or 5
				local wLevel = w.level or 1
				btn.MouseEnter:Connect(function()
					local eq = profile.equippedMain == w.uid and "● Equipped main"
						or (profile.equippedOffhand == w.uid and "● Equipped off" or nil)
					setTooltip(
						name,
						rar,
						string.format("Power: ×%.2f\nSell: %d\nLevel: %d", mult, sellP, wLevel),
						eq,
						edge
					)
				end)
				btn.MouseLeave:Connect(hideTooltip)
				btn.MouseButton1Click:Connect(function()
					-- Logical pick for action bar only — no grid recolor / sticky border
					selectedWeaponUid = w.uid
					api:Refresh()
				end)
			end

			for i, w in ipairs(weapons) do
				makeWeaponSlot(i, w)
			end
			for i = #weapons + 1, MAX_SLOTS do
				makeWeaponSlot(i, nil)
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
			-- Equip best: highest powerMult → main; 2nd → offhand if pass/unlock
			actBtn(row, "Equip best", Color3.fromRGB(0, 110, 95), 1, function()
				local ranked: { { uid: string, power: number, level: number } } = {}
				for _, w in ipairs(weapons) do
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
				if ranked[1] then
					Net.EquipWeapon(ranked[1].uid, "main")
				end
				if offUnlocked and ranked[2] and ranked[2].uid ~= ranked[1].uid then
					Net.EquipWeapon(ranked[2].uid, "offhand")
				end
			end)
			if selected then
				local def = WeaponConfig.Get(selected.id)
				lbl(row, (def and def.name) or WeaponConfig.GetDisplayName(selected.id), UDim2.fromOffset(110, 32), nil, 12, rarityBorder(def and def.rarity), 35)
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
			else
				keybind(row, 1, "LMB", "Select weapon")
			end
			actBtn(row, "Sell all unequipped", Color3.fromRGB(140, 40, 40), 10, function()
				Net.SellAllWeapons()
			end)

		---------------------------------------------------------------- PETS
		elseif tab == "pets" then
			setPreviewAvatar(nil, "🐾")
			local pets = profile.pets or {}
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
				local edge = rarityBorder(rar)
				local btn = makeItemSlot(scroll, i, edge)
				btn.Name = "P_" .. tostring(p.uid)
				local glyph = lbl(btn, "🐾", UDim2.fromScale(1, 0.75), UDim2.fromScale(0, 0.08), 28, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				if inTeam then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(8, 8)
					dot.Position = UDim2.fromOffset(5, 5)
					dot.BackgroundColor3 = edge
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end
				btn.MouseEnter:Connect(function()
					local power = def and def.powerPct or p.powerPct or 0
					setTooltip(
						name,
						rar,
						string.format("Power: +%d%%", math.floor(power)),
						inTeam and "● On team" or nil,
						rarityBorder(rar)
					)
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
			for i = #pets + 1, MAX_SLOTS do
				emptySlot(scroll, i)
			end
			local row = actionsRow()
			keybind(row, 1, "LMB", "Equip / Unequip")
			actBtn(row, "Open pet case", Color3.fromRGB(0, 90, 80), 2, function()
				openModal("case", { kind = "pet" })
			end)

		---------------------------------------------------------------- AURAS
		elseif tab == "auras" then
			setPreviewAvatar(nil, "✨")
			local auras = profile.auras or {}
			countLab.Text = string.format("%d auras", #auras)
			local scroll = makeSlotGrid(main)
			for i, a in ipairs(auras) do
				local def = AuraConfig.Get(a.id)
				local name = (def and def.name) or a.name or a.id
				local rar = (def and def.rarity) or a.rarity or "Common"
				local active = profile.equippedAura == a.uid
				local edge = rarityBorder(rar)
				local btn = makeItemSlot(scroll, i, edge)
				btn.Name = "A_" .. tostring(a.uid)
				local glyph = lbl(btn, "✨", UDim2.fromScale(1, 0.75), UDim2.fromScale(0, 0.08), 28, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				if active then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(8, 8)
					dot.Position = UDim2.fromOffset(5, 5)
					dot.BackgroundColor3 = edge
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end
				btn.MouseEnter:Connect(function()
					setTooltip(
						name,
						rar,
						def and string.format("Power: +%d%%", math.floor(def.powerPct or 0)) or nil,
						active and "● Active" or nil,
						edge
					)
				end)
				btn.MouseLeave:Connect(hideTooltip)
				btn.MouseButton1Click:Connect(function()
					Net.EquipAura(a.uid)
				end)
			end
			for i = #auras + 1, MAX_SLOTS do
				emptySlot(scroll, i)
			end
			local row = actionsRow()
			keybind(row, 1, "LMB", "Equip aura")
			actBtn(row, "Open aura case", Color3.fromRGB(80, 50, 120), 2, function()
				openModal("case", { kind = "aura" })
			end)

		---------------------------------------------------------------- RELICS
		elseif tab == "relics" then
			setPreviewAvatar(nil, "💎")
			local relics = profile.relics or {}
			countLab.Text = string.format("%d relics", #relics)
			local scroll = makeSlotGrid(main)
			for i, r in ipairs(relics) do
				local btn = makeItemSlot(scroll, i, BD)
				btn.Name = "R" .. i
				local glyph = lbl(btn, "💎", UDim2.fromScale(1, 0.65), nil, 26, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				local stars = lbl(btn, "★" .. tostring(r.stars or 1), UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 1, -16), 11, GOLD, 37)
				stars.TextXAlignment = Enum.TextXAlignment.Center
				btn.MouseEnter:Connect(function()
					setTooltip(tostring(r.name or r.id), nil, "Dungeon drop", "★" .. tostring(r.stars or 1))
				end)
				btn.MouseLeave:Connect(hideTooltip)
			end
			for i = #relics + 1, MAX_SLOTS do
				emptySlot(scroll, i)
			end
			local row = actionsRow()
			lbl(row, "Relics are read-only (dungeon drops)", UDim2.fromOffset(300, 32), nil, 13, TL, 35)

		---------------------------------------------------------------- CASES — small fixed-width cards (not full page)
		elseif tab == "cases" then
			setPreviewAvatar(nil, "📦")
			countLab.Text = ""
			local wrap = Instance.new("Frame")
			wrap.BackgroundTransparency = 1
			wrap.Size = UDim2.fromOffset(380, 160)
			wrap.Position = UDim2.new(0.5, 0, 0, 24)
			wrap.AnchorPoint = Vector2.new(0.5, 0)
			wrap.ZIndex = 34
			wrap.Parent = main
			UIKit.List(wrap, 10, false)

			local function caseCard(order: number, title: string, kind: string, color: Color3)
				local c = solid(wrap, kind, UDim2.new(1, 0, 0, 56), nil, BG_SECTION, 35)
				c.LayoutOrder = order
				UIKit.Stroke(c, color, 1.2, 0.2)
				UIKit.Corner(c, 10)

				local icon = lbl(c, if kind == "pet" then "🐾" else "✨", UDim2.fromOffset(44, 44), UDim2.fromOffset(8, 6), 22, TW, 36, Enum.Font.Arcade)
				icon.TextXAlignment = Enum.TextXAlignment.Center

				lbl(c, title, UDim2.new(1, -130, 1, 0), UDim2.fromOffset(56, 0), 16, TW, 36, Enum.Font.Arcade)

				local b = Instance.new("TextButton")
				b.Size = UDim2.fromOffset(88, 34)
				b.Position = UDim2.new(1, -98, 0.5, 0)
				b.AnchorPoint = Vector2.new(0, 0.5)
				b.BackgroundColor3 = color
				b.BackgroundTransparency = 0
				b.Text = "Open"
				b.TextColor3 = Color3.new(1, 1, 1)
				b.Font = Enum.Font.Arcade
				b.TextSize = 14
				b.BorderSizePixel = 0
				b.ZIndex = 37
				b.Parent = c
				UIKit.Corner(b, 10)
				UIKit.Stroke(b, Color3.new(1, 1, 1), 1.5, 0.5)
				b.MouseButton1Click:Connect(function()
					openModal("case", { kind = kind })
				end)
			end
			caseCard(1, "Pet Case", "pet", Color3.fromRGB(40, 120, 80))
			caseCard(2, "Aura Case", "aura", Color3.fromRGB(100, 60, 160))
			local row = actionsRow()
			lbl(row, "LMB · Open case", UDim2.fromOffset(200, 32), nil, 14, TL, 35, Enum.Font.Arcade)

		---------------------------------------------------------------- SHOP — compact horizontal rows (less empty space)
		elseif tab == "shop" then
			setPreviewAvatar(nil, "🪙")
			countLab.Text = "Gamepasses"
			local scroll = makePageScroll(main)

			local unlocks = profile.unlocks or {}
			for i, key in ipairs(GamePassConfig.Order) do
				local def = GamePassConfig.Get(key)
				if def then
					local owned = (def.feature and unlocks[def.feature] == true)
						or (def.feature == "autoClicker" and profile.purchasedAutoClicker == true)

					local card = solid(scroll, key, UDim2.new(1, -8, 0, 88), nil, Color3.fromRGB(30, 30, 36), 35)
					card.LayoutOrder = i
					card.BackgroundTransparency = 0
					UIKit.Corner(card, 10)
					UIKit.Stroke(card, owned and GREEN or GOLD, 1.5, owned and 0.12 or 0.22)

					local imgBtn = Instance.new("ImageButton")
					imgBtn.Name = "Buy"
					imgBtn.Size = UDim2.fromOffset(72, 72)
					imgBtn.Position = UDim2.fromOffset(8, 8)
					imgBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
					imgBtn.BackgroundTransparency = 0
					imgBtn.BorderSizePixel = 0
					imgBtn.Image = GamePassConfig.ThumbUrl(def.gamePassId, 150)
					imgBtn.ScaleType = Enum.ScaleType.Fit
					imgBtn.AutoButtonColor = not owned
					imgBtn.ZIndex = 36
					imgBtn.Parent = card
					UIKit.Corner(imgBtn, 8)
					UIKit.Stroke(imgBtn, BD2, 1, 0.2)

					local titleL = lbl(card, def.title, UDim2.new(1, -200, 0, 26), UDim2.fromOffset(92, 10), 18, TW, 36, Enum.Font.GothamBold)
					titleL.TextTruncate = Enum.TextTruncate.AtEnd

					local descL = lbl(card, def.desc, UDim2.new(1, -200, 0, 36), UDim2.fromOffset(92, 38), 14, TD, 36, Enum.Font.Gotham)
					descL.TextWrapped = true
					descL.TextYAlignment = Enum.TextYAlignment.Top

					local priceLab = lbl(
						card,
						owned and "OWNED" or (priceCache[def.gamePassId] or "…"),
						UDim2.fromOffset(100, 32),
						UDim2.new(1, -112, 0.5, -16),
						18,
						owned and GREEN or GOLD,
						36,
						Enum.Font.GothamBold
					)
					priceLab.TextXAlignment = Enum.TextXAlignment.Right
					if not owned then
						fetchPrice(def.gamePassId, priceLab)
					end

					local buyHit = Instance.new("TextButton")
					buyHit.Name = "BuyHit"
					buyHit.Size = UDim2.fromScale(1, 1)
					buyHit.BackgroundTransparency = 1
					buyHit.Text = ""
					buyHit.ZIndex = 37
					buyHit.Parent = card
					buyHit.MouseButton1Click:Connect(function()
						if not owned then
							Net.PromptGamePass(def.gamePassId)
						end
					end)
					buyHit.MouseEnter:Connect(function()
						setTooltip(def.title, nil, def.desc, owned and "● Already owned" or (priceCache[def.gamePassId] or "LMB purchase"))
					end)
					buyHit.MouseLeave:Connect(hideTooltip)
				end
			end
			local row = actionsRow()
			lbl(row, "LMB · Purchase gamepass", UDim2.fromOffset(260, 36), nil, 15, TL, 35)

		---------------------------------------------------------------- PROFILE — large FullHD-friendly type + layout
		else
			local viewUserId = inspectUserId or (lp and lp.UserId) or 0
			setPreviewAvatar(viewUserId, "👤")
			countLab.Text = inspectName and ("@" .. inspectName) or "You"
			local scroll = makePageScroll(main)

			-- Search bar (tall)
			local searchBar = solid(scroll, "Search", UDim2.new(1, -8, 0, 64), nil, BG_SECTION, 35)
			searchBar.LayoutOrder = 0
			searchBar.BackgroundTransparency = 0
			UIKit.Stroke(searchBar, BD2, 1, 0.15)
			UIKit.Pad(searchBar, 10)

			local box = Instance.new("TextBox")
			box.Name = "UserSearch"
			box.Size = UDim2.new(1, -130, 1, 0)
			box.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
			box.BackgroundTransparency = 0
			box.BorderSizePixel = 0
			box.PlaceholderText = "@username (online players)"
			box.PlaceholderColor3 = TL
			box.Text = inspectName and ("@" .. inspectName) or ""
			box.TextColor3 = TW
			box.Font = Enum.Font.Arcade
			box.TextSize = 20
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.ClearTextOnFocus = false
			box.ZIndex = 37
			box.Parent = searchBar
			UIKit.Corner(box, 6)
			UIKit.Pad(box, nil, 14, 0, 14, 0)
			UIKit.Stroke(box, BD, 1, 0.2)

			local searchBtn = Instance.new("TextButton")
			searchBtn.Size = UDim2.fromOffset(118, 44)
			searchBtn.Position = UDim2.new(1, -118, 0.5, 0)
			searchBtn.AnchorPoint = Vector2.new(0, 0.5)
			searchBtn.BackgroundColor3 = Color3.fromRGB(0, 90, 80)
			searchBtn.BackgroundTransparency = 0
			searchBtn.BorderSizePixel = 0
			searchBtn.Text = "Search"
			searchBtn.TextColor3 = TW
			searchBtn.Font = Enum.Font.Arcade
			searchBtn.TextSize = 18
			searchBtn.ZIndex = 37
			searchBtn.Parent = searchBar
			UIKit.Corner(searchBtn, 6)

			local statusLab = lbl(
				scroll,
				inspectStatus or "Your stats · search an online player",
				UDim2.new(1, -8, 0, 28),
				nil,
				16,
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

			-- Avatar + name (large)
			local headRow = solid(scroll, "HeadRow", UDim2.new(1, -8, 0, 180), nil, BG_SECTION, 35)
			headRow.LayoutOrder = 2
			headRow.BackgroundTransparency = 0
			UIKit.Stroke(headRow, BD, 1, 0.15)

			local bust = Instance.new("ImageLabel")
			bust.Name = "Bust"
			bust.Size = UDim2.fromOffset(150, 150)
			bust.Position = UDim2.fromOffset(16, 15)
			bust.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			bust.BackgroundTransparency = 0
			bust.BorderSizePixel = 0
			bust.Image = avatarBustUrl(viewUserId)
			bust.ScaleType = Enum.ScaleType.Crop
			bust.ZIndex = 36
			bust.Parent = headRow
			UIKit.Corner(bust, 12)
			UIKit.Stroke(bust, CYAN, 2, 0.25)

			local headNick = inspectName or (lp and ((lp.DisplayName ~= "" and lp.DisplayName) or lp.Name)) or "Player"
			local headTitle = if inspectName then Titles.DEFAULT else Titles.Of(profile)
			local idLine = Instance.new("TextLabel")
			idLine.Name = "TitleNick"
			idLine.BackgroundTransparency = 1
			idLine.Size = UDim2.new(1, -190, 0, 40)
			idLine.Position = UDim2.fromOffset(184, 28)
			idLine.Font = Titles.Font
			idLine.TextSize = 26
			idLine.TextXAlignment = Enum.TextXAlignment.Left
			idLine.TextYAlignment = Enum.TextYAlignment.Center
			idLine.RichText = true
			idLine.Text = Titles.Rich(headTitle, headNick)
			idLine.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			idLine.TextStrokeTransparency = 0.45
			idLine.ZIndex = 36
			idLine.Parent = headRow
			lbl(
				headRow,
				"@" .. (inspectName or (lp and lp.Name) or "player"),
				UDim2.new(1, -190, 0, 28),
				UDim2.fromOffset(184, 72),
				18,
				CYAN,
				36,
				Enum.Font.Gotham
			)
			if inspectName then
				local meBtn = Instance.new("TextButton")
				meBtn.Size = UDim2.fromOffset(140, 40)
				meBtn.Position = UDim2.fromOffset(184, 116)
				meBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				meBtn.BackgroundTransparency = 0
				meBtn.Text = "Back to me"
				meBtn.TextColor3 = TW
				meBtn.Font = Enum.Font.Arcade
				meBtn.TextSize = 16
				meBtn.BorderSizePixel = 0
				meBtn.ZIndex = 37
				meBtn.Parent = headRow
				UIKit.Corner(meBtn, 6)
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
			cols.Size = UDim2.new(1, -8, 0, 380)
			cols.LayoutOrder = 3
			cols.ZIndex = 35
			cols.Parent = scroll
			UIKit.List(cols, 16, true)

			local function colPanel(name: string, order: number): Frame
				local p = solid(cols, name, UDim2.new(0.5, -10, 1, 0), nil, BG_SECTION, 36)
				p.LayoutOrder = order
				p.BackgroundTransparency = 0
				UIKit.Stroke(p, BD, 1, 0.15)
				UIKit.Pad(p, 16)
				local list = Instance.new("UIListLayout")
				list.Padding = UDim.new(0, 10)
				list.SortOrder = Enum.SortOrder.LayoutOrder
				list.Parent = p
				return p
			end

			local leftCol = colPanel("Mods", 1)
			local rightCol = colPanel("Combat", 2)
			lbl(leftCol, "MODIFIERS", UDim2.new(1, 0, 0, 28), nil, 16, TL, 37).LayoutOrder = 0
			lbl(rightCol, "COMBAT STATS", UDim2.new(1, 0, 0, 28), nil, 16, TL, 37).LayoutOrder = 0

			local function statLine(parent: Frame, order: number, label: string, value: string, dot: Color3, vcol: Color3?)
				local line = solid(parent, "L" .. order, UDim2.new(1, 0, 0, 36), nil, BG_SECTION, 37)
				line.BackgroundTransparency = 1
				line.LayoutOrder = order
				local d = Instance.new("Frame")
				d.Size = UDim2.fromOffset(12, 12)
				d.Position = UDim2.new(0, 0, 0.5, 0)
				d.AnchorPoint = Vector2.new(0, 0.5)
				d.BackgroundColor3 = dot
				d.BorderSizePixel = 0
				d.ZIndex = 38
				d.Parent = line
				UIKit.Corner(d, 99)
				lbl(line, label, UDim2.new(0.55, -16, 1, 0), UDim2.fromOffset(22, 0), 18, TD, 38, Enum.Font.Arcade)
				local v = lbl(line, value, UDim2.new(0.42, 0, 1, 0), UDim2.new(0.55, 0, 0, 0), 20, vcol or TW, 38, Enum.Font.Arcade)
				v.TextXAlignment = Enum.TextXAlignment.Right
			end

			statLine(leftCol, 1, "Click power", Format.Num(s and (s.damagePerClick or s.totalPower) or 0), Color3.fromRGB(204, 68, 68), TW)
			statLine(leftCol, 2, "CPS", string.format("%.2f", s and s.cps or 0), GREEN, GREEN)
			statLine(leftCol, 3, "Crit chance", Format.Pct(s and s.crit or 0), GOLD, GOLD)
			statLine(leftCol, 4, "Luck", Format.Pct(s and s.luck or 0), CYAN, GREEN)
			statLine(leftCol, 5, "Rebirth", string.format("R%d %s", s and (s.rebirthLevel or 0) or 0, s and Format.Mult(s.rebirthMult) or "x1"), GOLD, GOLD)

			statLine(rightCol, 1, "DPS", Format.Num(s and s.dps or 0), Color3.fromRGB(204, 68, 68), TW)
			statLine(rightCol, 2, "Coins", Format.Num(s and s.coins or 0), GOLD, GOLD)
			statLine(rightCol, 3, "Total clicks", Format.Num(s and s.totalClicks or 0), GREEN, TW)
			statLine(rightCol, 4, "Lifetime dmg", Format.Num(s and s.lifetimeDamage or 0), Color3.fromRGB(144, 112, 192), TW)
			statLine(rightCol, 5, "Location", tostring(inspectLocation or profile.currentLocation or 1), CYAN, CYAN)

			local row = actionsRow()
			lbl(row, inspectName and ("Viewing @" .. inspectName) or "Your live profile", UDim2.fromOffset(360, 36), nil, 17, TL, 35)
		end
	end

	return api
end

return Inventory
