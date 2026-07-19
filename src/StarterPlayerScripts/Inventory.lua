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

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(Shared.Config.WeaponConfig)
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local IconConfig = require(Shared.Config.IconConfig)
local GamePassConfig = require(Shared.Config.GamePassConfig)

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

local SLOT = 76
local SLOT_GAP = 6
local COLS = 9
local MAX_SLOTS = 45
local INV_CAP = 32
local TAB_R = 68
local HOVER_SCALE = 1.1

-- Bottom section tabs: ImageButton icons (no circle plate). Free Creator Store IDs.
local TABS = {
	{ id = "weapons", glyph = "⚔", label = "Weapons", image = "rbxassetid://114848036963361" },
	{ id = "pets", glyph = "🐾", label = "Pets", image = "rbxassetid://92327170909498" },
	{ id = "auras", glyph = "✨", label = "Auras", image = "rbxassetid://133879685799043" },
	{ id = "relics", glyph = "💎", label = "Relics", image = "rbxassetid://9650296120" },
	{ id = "cases", glyph = "📦", label = "Cases", image = "rbxassetid://7181747872" },
	{ id = "shop", glyph = "🪙", label = "Shop", image = "rbxassetid://16009435598" },
	{ id = "profile", glyph = "👤", label = "Profile", image = "rbxassetid://7492903668" },
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
	l.Font = font or Enum.Font.GothamBold
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
	badge.Font = Enum.Font.GothamBold
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
	d.Font = Enum.Font.Gotham
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
	local infoLab: TextLabel
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
		if tipSz.X < 2 then
			tipSz = Vector2.new(240, 130)
		end
		local gap = 14
		-- Prefer right of cursor
		local localX = (screenX - abs.X) + gap
		local localY = (screenY - abs.Y) + gap
		if localX + tipSz.X > canvasSz.X - 6 then
			-- flip to left of cursor
			localX = (screenX - abs.X) - tipSz.X - gap
		end
		if localY + tipSz.Y > canvasSz.Y - 6 then
			localY = canvasSz.Y - tipSz.Y - 6
		end
		localX = math.clamp(localX, 4, math.max(4, canvasSz.X - tipSz.X - 4))
		localY = math.clamp(localY, 4, math.max(4, canvasSz.Y - tipSz.Y - 4))
		tip.Position = UDim2.fromOffset(localX, localY)
	end

	--- Compact labeled tooltip (title + rarity + stats lines — less empty space)
	local function setTooltip(title: string, rarity: string?, desc: string?, extra: string?, borderCol: Color3?)
		local tLab = tip:FindFirstChild("Title") :: TextLabel
		local rLab = tip:FindFirstChild("Rarity") :: TextLabel
		local dLab = tip:FindFirstChild("Desc") :: TextLabel
		local eLab = tip:FindFirstChild("Extra") :: TextLabel
		tLab.Text = title
		rLab.Text = rarity and ("Rarity: " .. rarity) or ""
		rLab.TextColor3 = borderCol or rarityBorder(rarity)
		dLab.Text = desc or ""
		eLab.Text = extra or ""
		local st = tip:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = borderCol or rarityBorder(rarity) or BD2
		end
		-- tighter fixed height when lines empty
		local lines = 1 + (rarity and 1 or 0) + ((desc and desc ~= "") and 2 or 0) + ((extra and extra ~= "") and 1 or 0)
		tip.Size = UDim2.fromOffset(220, math.clamp(18 + lines * 20, 70, 140))
		tip.Visible = true
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
			TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = HOVER_SCALE,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.12), {
					Color = CYAN,
					Thickness = 2.5,
					Transparency = 0,
				}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.12), {
					Color = baseCol,
					Thickness = 1.5,
					Transparency = 0.1,
				}):Play()
			end
		end)
	end

	--- Opaque filled slot (prevents inventory bg showing through icons)
	local function makeItemSlot(parent: Instance, order: number, edge: Color3): (TextButton, Frame, UIStroke)
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

		-- full opaque plate under any transparent icon pixels
		local plate = Instance.new("Frame")
		plate.Name = "Plate"
		plate.Size = UDim2.fromScale(1, 1)
		plate.BackgroundColor3 = BG_SLOT
		plate.BackgroundTransparency = 0
		plate.BorderSizePixel = 0
		plate.ZIndex = 35
		plate.Parent = btn

		local stroke = UIKit.Stroke(btn, edge, 1.5, 0.1)
		bindHover(btn, stroke, edge)
		return btn, plate, stroke
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
		UIKit.Stroke(btn, BD, 1, 0.3)
	end

	local function makeSlotGrid(parent: Instance): ScrollingFrame
		local scroll = Instance.new("ScrollingFrame")
		scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		scroll.BackgroundTransparency = 0
		scroll.BorderSizePixel = 0
		scroll.Size = UDim2.new(1, -10, 1, -10)
		scroll.Position = UDim2.fromOffset(5, 5)
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 6
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
		UIKit.Pad(scroll, 8)
		return scroll
	end

	local function actBtn(parent: Instance, text: string, color: Color3, order: number, onClick: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(0, 34)
		b.AutomaticSize = Enum.AutomaticSize.X
		b.BackgroundColor3 = color
		b.BackgroundTransparency = 0
		b.BorderSizePixel = 0
		b.Text = text
		b.TextColor3 = TW
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
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

		local header = solid(canvas, "Header", UDim2.new(1, 0, 0, 48), UDim2.fromOffset(0, 0), Color3.fromRGB(18, 18, 18), 32)
		solid(header, "Line", UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), BD, 33)
		titleLab = lbl(header, "Inventory — Weapons", UDim2.new(0.55, 0, 1, 0), UDim2.fromOffset(18, 0), 15, TW, 34)
		titleLab.Name = "Title"
		countLab = lbl(header, "", UDim2.new(0.28, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), 12, TL, 34)
		countLab.TextXAlignment = Enum.TextXAlignment.Right
		countLab.Name = "Count"

		local close = Instance.new("TextButton")
		close.Name = "Close"
		close.Size = UDim2.fromOffset(30, 30)
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
		close.ZIndex = 35
		close.Parent = header
		UIKit.Corner(close, 99)
		close.MouseButton1Click:Connect(onClose)

		local info = solid(canvas, "Info", UDim2.new(1, 0, 0, 32), UDim2.fromOffset(0, 48), Color3.fromRGB(16, 16, 16), 32)
		infoLab = lbl(info, "", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(18, 0), 13, TD, 34, Enum.Font.Gotham)
		infoLab.Name = "InfoText"

		local contentH = 48 + 32 + 56 + 100
		-- Full-width main content (left preview strip intentionally removed)
		main = solid(canvas, "Main", UDim2.new(1, 0, 1, -contentH), UDim2.fromOffset(0, 80), Color3.fromRGB(20, 20, 20), 32)
		main.BackgroundTransparency = 0
		main.ClipsDescendants = true
		main.Name = "Main"

		actions = solid(canvas, "Actions", UDim2.new(1, 0, 0, 56), UDim2.new(0, 0, 1, -(56 + 100)), Color3.fromRGB(16, 16, 16), 32)
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
			col.Size = UDim2.fromOffset(TAB_R + 10, 86)
			col.ZIndex = 34
			col.Parent = tabRow

			-- ImageButton only — no circle/plate background (sits on tab frame)
			local b = Instance.new("ImageButton")
			b.Name = def.id
			b.Size = UDim2.fromOffset(TAB_R, TAB_R)
			b.Position = UDim2.new(0.5, 0, 0, 0)
			b.AnchorPoint = Vector2.new(0.5, 0)
			b.BackgroundTransparency = 1
			b.BorderSizePixel = 0
			b.Image = def.image
			b.ScaleType = Enum.ScaleType.Fit
			b.AutoButtonColor = false
			b.ZIndex = 35
			b.Parent = col

			local hoverScale = Instance.new("UIScale")
			hoverScale.Scale = 1
			hoverScale.Parent = b
			b.MouseEnter:Connect(function()
				TweenService:Create(hoverScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Scale = 1.16,
				}):Play()
			end)
			b.MouseLeave:Connect(function()
				TweenService:Create(hoverScale, TweenInfo.new(0.1), { Scale = 1 }):Play()
			end)

			local lab = lbl(col, def.label, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), 11, Color3.fromRGB(74, 74, 74), 35)
			lab.TextXAlignment = Enum.TextXAlignment.Center
			lab.Font = Enum.Font.GothamBold

			tabButtons[def.id] = b
			tabLabels[def.id] = lab
			b.MouseButton1Click:Connect(function()
				tab = def.id
				api:Refresh()
			end)
		end

		tip = solid(canvas, "Tooltip", UDim2.fromOffset(250, 130), UDim2.fromOffset(0, 0), Color3.fromRGB(12, 12, 12), 90)
		tip.Visible = false
		tip.BackgroundTransparency = 0
		UIKit.Stroke(tip, BD2, 1.5, 0.05)
		UIKit.Pad(tip, 12)
		lbl(tip, "", UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 0), 13, TW, 91).Name = "Title"
		lbl(tip, "", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 24), 13, TD, 91, Enum.Font.Gotham).Name = "Rarity"
		local td = lbl(tip, "", UDim2.new(1, 0, 0, 48), UDim2.fromOffset(0, 46), 13, TD, 91, Enum.Font.Gotham)
		td.Name = "Desc"
		td.TextWrapped = true
		td.TextYAlignment = Enum.TextYAlignment.Top
		lbl(tip, "", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 100), 13, GOLD, 91, Enum.Font.Gotham).Name = "Extra"

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
				local isSel = w.uid == selectedWeaponUid
				local btn, plate = makeItemSlot(scroll, i, isSel and CYAN or edge)
				plate.BackgroundColor3 = BG_SLOT
				btn.Name = "W_" .. w.uid
				if isSel then
					local st = btn:FindFirstChildOfClass("UIStroke")
					if st then
						st.Color = CYAN
						st.Thickness = 2.5
					end
				end

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
					dot.BackgroundColor3 = CYAN
					dot.BackgroundTransparency = 0
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end

				local name = (def and def.name) or w.id
				local rar = (def and def.rarity) or "Common"
				local mult = (def and def.powerMult) or 1
				btn.MouseEnter:Connect(function()
					local eq = profile.equippedMain == w.uid and "● Equipped main"
						or (profile.equippedOffhand == w.uid and "● Equipped off" or nil)
					setTooltip(name, rar, string.format("Power mult ×%.2f", mult), eq, edge)
				end)
				btn.MouseLeave:Connect(hideTooltip)
				btn.MouseButton1Click:Connect(function()
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
			if selected then
				local def = WeaponConfig.Get(selected.id)
				lbl(row, (def and def.name) or selected.id, UDim2.fromOffset(120, 32), nil, 12, rarityBorder(def and def.rarity), 35)
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
				local btn = makeItemSlot(scroll, i, rarityBorder(rar))
				btn.Name = "P_" .. tostring(p.uid)
				local glyph = lbl(btn, "🐾", UDim2.fromScale(1, 0.75), UDim2.fromScale(0, 0.08), 28, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				if inTeam then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(8, 8)
					dot.Position = UDim2.fromOffset(5, 5)
					dot.BackgroundColor3 = CYAN
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end
				btn.MouseEnter:Connect(function()
					local power = def and def.powerPct or p.powerPct or 0
					setTooltip(name, rar, string.format("+%d%% power", math.floor(power)), inTeam and "● On team" or "LMB equip/unequip", rarityBorder(rar))
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
				local btn = makeItemSlot(scroll, i, rarityBorder(rar))
				btn.Name = "A_" .. tostring(a.uid)
				local glyph = lbl(btn, "✨", UDim2.fromScale(1, 0.75), UDim2.fromScale(0, 0.08), 28, TW, 37)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				if active then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(8, 8)
					dot.Position = UDim2.fromOffset(5, 5)
					dot.BackgroundColor3 = CYAN
					dot.BorderSizePixel = 0
					dot.ZIndex = 38
					dot.Parent = btn
					UIKit.Corner(dot, 99)
				end
				btn.MouseEnter:Connect(function()
					setTooltip(
						name,
						rar,
						def and string.format("+%d%% power", math.floor(def.powerPct or 0)) or nil,
						active and "● Active" or "LMB equip",
						rarityBorder(rar)
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

		---------------------------------------------------------------- CASES
		elseif tab == "cases" then
			setPreviewAvatar(nil, "📦")
			countLab.Text = ""
			local scroll = UIKit.Scroll(main, UDim2.new(1, -10, 1, -10))
			scroll.Position = UDim2.fromOffset(5, 5)
			local function caseCard(order: number, title: string, kind: string, color: Color3)
				local c = solid(scroll, kind, UDim2.new(1, -8, 0, 100), nil, BG_SECTION, 35)
				c.LayoutOrder = order
				UIKit.Stroke(c, color, 1.5, 0.2)
				UIKit.Pad(c, 12)
				lbl(c, title, UDim2.new(1, 0, 0, 28), nil, 16, TW, 36)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 38)
				b.Position = UDim2.new(0, 0, 1, -38)
				b.BackgroundColor3 = color
				b.BackgroundTransparency = 0
				b.Text = "Open"
				b.TextColor3 = Color3.new(1, 1, 1)
				b.Font = Enum.Font.GothamBold
				b.TextSize = 14
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
			keybind(row, 1, "LMB", "Open case")

		---------------------------------------------------------------- SHOP
		elseif tab == "shop" then
			setPreviewAvatar(nil, "🪙")
			countLab.Text = "Gamepasses"
			local scroll = UIKit.Scroll(main, UDim2.new(1, -10, 1, -10))
			scroll.Position = UDim2.fromOffset(5, 5)
			for _, ch in scroll:GetChildren() do
				if ch:IsA("UIListLayout") then
					ch:Destroy()
				end
			end
			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.fromOffset(168, 210)
			grid.CellPadding = UDim2.fromOffset(12, 12)
			grid.SortOrder = Enum.SortOrder.LayoutOrder
			grid.FillDirectionMaxCells = 4
			grid.Parent = scroll
			UIKit.Pad(scroll, 8)

			local unlocks = profile.unlocks or {}
			for i, key in ipairs(GamePassConfig.Order) do
				local def = GamePassConfig.Get(key)
				if def then
					local owned = def.feature and unlocks[def.feature] == true
					local card = solid(scroll, key, UDim2.fromOffset(168, 210), nil, BG_SECTION, 35)
					card.LayoutOrder = i
					card.BackgroundTransparency = 0
					UIKit.Stroke(card, owned and GREEN or BD2, 1.5, owned and 0.05 or 0.12)

					local imgBtn = Instance.new("ImageButton")
					imgBtn.Name = "Buy"
					imgBtn.Size = UDim2.fromOffset(128, 128)
					imgBtn.Position = UDim2.new(0.5, 0, 0, 10)
					imgBtn.AnchorPoint = Vector2.new(0.5, 0)
					imgBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
					imgBtn.BackgroundTransparency = 0
					imgBtn.BorderSizePixel = 0
					imgBtn.Image = GamePassConfig.ThumbUrl(def.gamePassId, 150)
					imgBtn.ScaleType = Enum.ScaleType.Fit
					imgBtn.AutoButtonColor = not owned
					imgBtn.ZIndex = 36
					imgBtn.Parent = card
					UIKit.Corner(imgBtn, 8)
					UIKit.Stroke(imgBtn, BD, 1, 0.15)
					bindHover(imgBtn, imgBtn:FindFirstChildOfClass("UIStroke"), BD)

					-- price pill on image (always visible)
					local pricePill = Instance.new("TextLabel")
					pricePill.Name = "PricePill"
					pricePill.Size = UDim2.new(1, -8, 0, 22)
					pricePill.Position = UDim2.new(0.5, 0, 1, -26)
					pricePill.AnchorPoint = Vector2.new(0.5, 0)
					pricePill.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
					pricePill.BackgroundTransparency = 0.15
					pricePill.BorderSizePixel = 0
					pricePill.Font = Enum.Font.GothamBold
					pricePill.TextSize = 13
					pricePill.TextColor3 = owned and GREEN or GOLD
					pricePill.ZIndex = 39
					pricePill.Parent = imgBtn
					UIKit.Corner(pricePill, 4)
					if owned then
						pricePill.Text = "OWNED"
						imgBtn.ImageTransparency = 0.2
					else
						pricePill.Text = priceCache[def.gamePassId] or "…"
						fetchPrice(def.gamePassId, pricePill)
					end

					local titleL = lbl(card, def.title, UDim2.new(1, -10, 0, 22), UDim2.fromOffset(5, 144), 12, TW, 36)
					titleL.TextXAlignment = Enum.TextXAlignment.Center
					titleL.TextTruncate = Enum.TextTruncate.AtEnd

					local priceLab = lbl(
						card,
						owned and "Owned" or (priceCache[def.gamePassId] or "…"),
						UDim2.new(1, -10, 0, 22),
						UDim2.fromOffset(5, 172),
						14,
						owned and GREEN or GOLD,
						36,
						Enum.Font.GothamBold
					)
					priceLab.TextXAlignment = Enum.TextXAlignment.Center
					if not owned then
						fetchPrice(def.gamePassId, priceLab)
						-- keep pill in sync when cache fills
						task.spawn(function()
							for _ = 1, 20 do
								task.wait(0.15)
								if priceCache[def.gamePassId] and pricePill.Parent then
									pricePill.Text = priceCache[def.gamePassId]
									priceLab.Text = priceCache[def.gamePassId]
									break
								end
							end
						end)
					end

					imgBtn.MouseButton1Click:Connect(function()
						if not owned then
							Net.PromptGamePass(def.gamePassId)
						end
					end)
					imgBtn.MouseEnter:Connect(function()
						setTooltip(def.title, nil, def.desc, owned and "● Already owned" or (priceCache[def.gamePassId] or "LMB purchase"))
					end)
					imgBtn.MouseLeave:Connect(hideTooltip)
				end
			end
			local row = actionsRow()
			keybind(row, 1, "LMB", "Purchase")
			lbl(row, "Roblox gamepasses", UDim2.fromOffset(180, 32), nil, 13, TL, 35)

		---------------------------------------------------------------- PROFILE
		else
			local viewUserId = inspectUserId or (lp and lp.UserId) or 0
			setPreviewAvatar(viewUserId, "👤")
			countLab.Text = inspectName and ("@" .. inspectName) or "You"
			local scroll = UIKit.Scroll(main, UDim2.new(1, -10, 1, -10))
			scroll.Position = UDim2.fromOffset(5, 5)

			-- Search bar
			local searchBar = solid(scroll, "Search", UDim2.new(1, -8, 0, 48), nil, BG_SECTION, 35)
			searchBar.LayoutOrder = 0
			searchBar.BackgroundTransparency = 0
			UIKit.Stroke(searchBar, BD2, 1, 0.15)
			UIKit.Pad(searchBar, 8)

			local box = Instance.new("TextBox")
			box.Name = "UserSearch"
			box.Size = UDim2.new(1, -100, 1, 0)
			box.Position = UDim2.fromOffset(0, 0)
			box.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
			box.BackgroundTransparency = 0
			box.BorderSizePixel = 0
			box.PlaceholderText = "@username (online players)"
			box.PlaceholderColor3 = TL
			box.Text = inspectName and ("@" .. inspectName) or ""
			box.TextColor3 = TW
			box.Font = Enum.Font.Gotham
			box.TextSize = 14
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.ClearTextOnFocus = false
			box.ZIndex = 37
			box.Parent = searchBar
			UIKit.Corner(box, 4)
			UIKit.Pad(box, nil, 10, 0, 10, 0)
			UIKit.Stroke(box, BD, 1, 0.2)

			local searchBtn = Instance.new("TextButton")
			searchBtn.Size = UDim2.fromOffset(88, 32)
			searchBtn.Position = UDim2.new(1, -88, 0.5, 0)
			searchBtn.AnchorPoint = Vector2.new(0, 0.5)
			searchBtn.BackgroundColor3 = Color3.fromRGB(0, 90, 80)
			searchBtn.BackgroundTransparency = 0
			searchBtn.BorderSizePixel = 0
			searchBtn.Text = "Search"
			searchBtn.TextColor3 = TW
			searchBtn.Font = Enum.Font.GothamBold
			searchBtn.TextSize = 12
			searchBtn.ZIndex = 37
			searchBtn.Parent = searchBar
			UIKit.Corner(searchBtn, 4)

			local statusLab = lbl(scroll, inspectStatus or "View your stats or search an online player", UDim2.new(1, -8, 0, 22), nil, 12, inspectStatus and GOLD or TL, 35)
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

			-- Avatar + name row
			local headRow = solid(scroll, "HeadRow", UDim2.new(1, -8, 0, 120), nil, BG_SECTION, 35)
			headRow.LayoutOrder = 2
			headRow.BackgroundTransparency = 0
			UIKit.Stroke(headRow, BD, 1, 0.15)

			local bust = Instance.new("ImageLabel")
			bust.Name = "Bust"
			bust.Size = UDim2.fromOffset(100, 100)
			bust.Position = UDim2.fromOffset(12, 10)
			bust.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			bust.BackgroundTransparency = 0
			bust.BorderSizePixel = 0
			bust.Image = avatarBustUrl(viewUserId)
			bust.ScaleType = Enum.ScaleType.Crop
			bust.ZIndex = 36
			bust.Parent = headRow
			UIKit.Corner(bust, 8)
			UIKit.Stroke(bust, CYAN, 1.5, 0.3)

			lbl(headRow, inspectName or (lp and lp.DisplayName) or "Player", UDim2.new(1, -130, 0, 28), UDim2.fromOffset(124, 20), 18, TW, 36)
			lbl(headRow, "@" .. (inspectName or (lp and lp.Name) or "player"), UDim2.new(1, -130, 0, 22), UDim2.fromOffset(124, 50), 13, CYAN, 36, Enum.Font.Gotham)
			if inspectName then
				local meBtn = Instance.new("TextButton")
				meBtn.Size = UDim2.fromOffset(110, 28)
				meBtn.Position = UDim2.fromOffset(124, 78)
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
				p.BackgroundTransparency = 0
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
				lbl(line, label, UDim2.new(0.58, -12, 1, 0), UDim2.fromOffset(14, 0), 12, TD, 38, Enum.Font.Gotham)
				local v = lbl(line, value, UDim2.new(0.42, 0, 1, 0), UDim2.new(0.58, 0, 0, 0), 13, vcol or TW, 38, Enum.Font.GothamBold)
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
			lbl(row, inspectName and ("Viewing @" .. inspectName) or "Your live profile", UDim2.fromOffset(240, 32), nil, 13, TL, 35)
		end
	end

	return api
end

return Inventory
