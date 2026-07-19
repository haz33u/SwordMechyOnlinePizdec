--!strict
--[[
	Inventory UI from Figma Make INVETAR (App_FINAL.tsx scales preserved):
	  - panel dark charcoal, 56px slots, 9-col grid, max 45 pad / 32 capacity
	  - bottom round tabs with labels (project features only)
	  - hover tooltips; live profile data (no demo Make items)
	  - shop = Roblox gamepasses (ImageButton + rbxthumb + R$ price)
	Tabs: weapons | pets | auras | relics | cases | shop | profile
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
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

-- Fixed design tokens from Make (do NOT apply S=1.42 rail scale)
local BG_PANEL = Color3.fromRGB(24, 24, 24)
local BG_SECTION = Color3.fromRGB(32, 32, 32)
local BG_SLOT = Color3.fromRGB(28, 28, 28)
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

local SLOT = 56
local SLOT_GAP = 4
local COLS = 9
local MAX_SLOTS = 45
local INV_CAP = 32
local TAB_R = 54

local TABS = {
	{ id = "weapons", glyph = "⚔", label = "Weapons" },
	{ id = "pets", glyph = "🐾", label = "Pets" },
	{ id = "auras", glyph = "✨", label = "Auras" },
	{ id = "relics", glyph = "💎", label = "Relics" },
	{ id = "cases", glyph = "📦", label = "Cases" },
	{ id = "shop", glyph = "🪙", label = "Shop" },
	{ id = "profile", glyph = "👤", label = "Profile" },
}

local function rarityBorder(r: string?): Color3
	return Rarity.Of(r)
end

local function solid(parent: Instance, name: string, size: UDim2, pos: UDim2?, bg: Color3?, z: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = bg or BG_SECTION
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
	l.TextSize = sizePx or 12
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
	wrap.Size = UDim2.fromOffset(0, 28)
	wrap.AutomaticSize = Enum.AutomaticSize.X
	wrap.LayoutOrder = order
	wrap.ZIndex = 35
	wrap.Parent = parent
	UIKit.List(wrap, 5, true)

	local badge = Instance.new("TextLabel")
	badge.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	badge.BorderSizePixel = 0
	badge.Text = key
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.TextColor3 = TD
	badge.Size = UDim2.fromOffset(0, 22)
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.ZIndex = 36
	badge.Parent = wrap
	UIKit.Pad(badge, 0, 7, 2, 7, 2)
	UIKit.Stroke(badge, BD2, 1, 0.15)

	local d = Instance.new("TextLabel")
	d.BackgroundTransparency = 1
	d.Text = desc
	d.Font = Enum.Font.Gotham
	d.TextSize = 12
	d.TextColor3 = TL
	d.Size = UDim2.fromOffset(0, 22)
	d.AutomaticSize = Enum.AutomaticSize.X
	d.ZIndex = 36
	d.Parent = wrap
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

	-- shell nodes (set in ensureShell)
	local canvas: Frame
	local titleLab: TextLabel
	local countLab: TextLabel
	local infoLab: TextLabel
	local main: Frame
	local actions: Frame
	local tip: Frame
	local previewLab: TextLabel
	local miniSlots: { Frame } = {}
	local tabButtons: { [string]: TextButton } = {}
	local tabLabels: { [string]: TextLabel } = {}

	local function fetchPrice(passId: number, label: TextLabel)
		if priceCache[passId] then
			label.Text = priceCache[passId]
			return
		end
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

	local function setTooltip(title: string, rarity: string?, desc: string?, extra: string?, borderCol: Color3?)
		local tLab = tip:FindFirstChild("Title") :: TextLabel
		local rLab = tip:FindFirstChild("Rarity") :: TextLabel
		local dLab = tip:FindFirstChild("Desc") :: TextLabel
		local eLab = tip:FindFirstChild("Extra") :: TextLabel
		tLab.Text = title
		rLab.Text = rarity and ("◆ " .. rarity) or ""
		rLab.TextColor3 = borderCol or rarityBorder(rarity)
		dLab.Text = desc or ""
		eLab.Text = extra or ""
		local st = tip:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = borderCol or rarityBorder(rarity) or BD2
		end
		tip.Visible = true
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

	local function makeSlotGrid(parent: Instance): ScrollingFrame
		local scroll = Instance.new("ScrollingFrame")
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.Size = UDim2.new(1, -8, 1, -8)
		scroll.Position = UDim2.fromOffset(4, 4)
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = BD2
		scroll.ZIndex = 34
		scroll.Parent = parent
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(SLOT, SLOT)
		grid.CellPadding = UDim2.fromOffset(SLOT_GAP, SLOT_GAP)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = COLS
		grid.Parent = scroll
		UIKit.Pad(scroll, 4)
		return scroll
	end

	local function emptySlot(parent: Instance, order: number)
		local btn = Instance.new("TextButton")
		btn.Name = "E" .. order
		btn.Size = UDim2.fromOffset(SLOT, SLOT)
		btn.BackgroundColor3 = BG_SLOT_MT
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Active = false
		btn.LayoutOrder = order
		btn.ZIndex = 35
		btn.Parent = parent
		UIKit.Stroke(btn, BD, 1, 0.25)
	end

	local function actBtn(parent: Instance, text: string, color: Color3, order: number, onClick: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(0, 30)
		b.AutomaticSize = Enum.AutomaticSize.X
		b.BackgroundColor3 = color
		b.BorderSizePixel = 0
		b.Text = text
		b.TextColor3 = TW
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11
		b.AutoButtonColor = false
		b.LayoutOrder = order
		b.ZIndex = 35
		b.Parent = parent
		UIKit.Corner(b, 4)
		UIKit.Stroke(b, BD2, 1, 0.2)
		UIKit.Pad(b, 0, 12, 0, 12, 0)
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	local function actionsRow(): Frame
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -20, 1, -8)
		row.Position = UDim2.fromOffset(12, 6)
		row.ZIndex = 34
		row.Parent = actions
		UIKit.List(row, 8, true, Enum.HorizontalAlignment.Left)
		return row
	end

	local api: Api

	local function ensureShell()
		if shellBuilt then
			return
		end
		shellBuilt = true
		body.ClipsDescendants = false
		for _, c in body:GetChildren() do
			c:Destroy()
		end

		canvas = solid(body, "InvCanvas", UDim2.new(1, 0, 1, 0), nil, BG_PANEL, 31)
		UIKit.Stroke(canvas, BD2, 2, 0.1)

		-- Header (Make: 10–16px pad feel)
		local header = solid(canvas, "Header", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 0), Color3.fromRGB(20, 20, 20), 32)
		solid(header, "Line", UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), BD, 33)
		titleLab = lbl(header, "Inventory — Weapons", UDim2.new(0.55, 0, 1, 0), UDim2.fromOffset(16, 0), 12, TW, 34)
		titleLab.Name = "Title"
		countLab = lbl(header, "", UDim2.new(0.28, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), 10, TL, 34)
		countLab.TextXAlignment = Enum.TextXAlignment.Right
		countLab.Name = "Count"

		local close = Instance.new("TextButton")
		close.Name = "Close"
		close.Size = UDim2.fromOffset(24, 24)
		close.Position = UDim2.new(1, -36, 0.5, 0)
		close.AnchorPoint = Vector2.new(0, 0.5)
		close.BackgroundColor3 = RED_CLOSE
		close.Text = "✕"
		close.TextColor3 = Color3.new(1, 1, 1)
		close.Font = Enum.Font.GothamBold
		close.TextSize = 12
		close.AutoButtonColor = false
		close.BorderSizePixel = 0
		close.ZIndex = 35
		close.Parent = header
		UIKit.Corner(close, 99)
		close.MouseButton1Click:Connect(onClose)

		-- Info bar
		local info = solid(canvas, "Info", UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 40), Color3.fromRGB(18, 18, 18), 32)
		infoLab = lbl(info, "", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(16, 0), 12, TD, 34, Enum.Font.Gotham)
		infoLab.Name = "InfoText"

		-- Content
		local content = solid(canvas, "Content", UDim2.new(1, 0, 1, -(40 + 28 + 48 + 88)), UDim2.fromOffset(0, 68), BG_PANEL, 32)
		content.BackgroundTransparency = 1
		content.ClipsDescendants = true

		local left = solid(content, "Left", UDim2.new(0, 120, 1, 0), UDim2.fromOffset(0, 0), Color3.fromRGB(16, 16, 16), 33)
		UIKit.Stroke(left, BD, 1, 0.2)

		local preview = solid(left, "Preview", UDim2.fromOffset(94, 140), UDim2.new(0.5, 0, 0.42, 0), Color3.fromRGB(12, 12, 12), 34)
		preview.AnchorPoint = Vector2.new(0.5, 0.5)
		UIKit.Stroke(preview, BD, 1, 0.15)
		previewLab = lbl(preview, "⚔", UDim2.fromScale(1, 1), nil, 36, TW, 35)
		previewLab.TextXAlignment = Enum.TextXAlignment.Center
		previewLab.Name = "PreviewIcon"

		-- 3 mini slots under preview (Make left strip)
		local miniRow = Instance.new("Frame")
		miniRow.BackgroundTransparency = 1
		miniRow.Size = UDim2.new(1, -12, 0, 28)
		miniRow.Position = UDim2.new(0.5, 0, 1, -40)
		miniRow.AnchorPoint = Vector2.new(0.5, 0)
		miniRow.ZIndex = 34
		miniRow.Parent = left
		UIKit.List(miniRow, 5, true, Enum.HorizontalAlignment.Center)
		for i = 1, 3 do
			local m = solid(miniRow, "Mini" .. i, UDim2.fromOffset(28, 28), nil, BG_SLOT_MT, 35)
			UIKit.Stroke(m, BD, 1, 0.2)
			local ml = lbl(m, tostring(i), UDim2.fromScale(1, 1), nil, 9, TL, 36)
			ml.TextXAlignment = Enum.TextXAlignment.Center
			ml.Name = "Icon"
			miniSlots[i] = m
		end

		main = solid(content, "Main", UDim2.new(1, -128, 1, 0), UDim2.fromOffset(124, 0), BG_PANEL, 33)
		main.BackgroundTransparency = 1
		main.ClipsDescendants = true
		main.Name = "Main"

		actions = solid(canvas, "Actions", UDim2.new(1, 0, 0, 48), UDim2.new(0, 0, 1, -(48 + 88)), Color3.fromRGB(18, 18, 18), 32)
		actions.Name = "Actions"
		solid(actions, "Line", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, 0), BD, 33)

		-- Bottom round tabs + labels (Make)
		local tabs = solid(canvas, "Tabs", UDim2.new(1, 0, 0, 88), UDim2.new(0, 0, 1, -88), Color3.fromRGB(14, 14, 14), 32)
		solid(tabs, "Line", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, 0), BD, 33)
		local tabRow = Instance.new("Frame")
		tabRow.BackgroundTransparency = 1
		tabRow.Size = UDim2.new(1, -16, 1, -10)
		tabRow.Position = UDim2.fromOffset(8, 8)
		tabRow.ZIndex = 33
		tabRow.Parent = tabs
		UIKit.List(tabRow, 10, true, Enum.HorizontalAlignment.Center)

		for _, def in ipairs(TABS) do
			local col = Instance.new("Frame")
			col.Name = def.id .. "Col"
			col.BackgroundTransparency = 1
			col.Size = UDim2.fromOffset(TAB_R + 4, 74)
			col.ZIndex = 34
			col.Parent = tabRow

			local b = Instance.new("TextButton")
			b.Name = def.id
			b.Size = UDim2.fromOffset(TAB_R, TAB_R)
			b.Position = UDim2.new(0.5, 0, 0, 0)
			b.AnchorPoint = Vector2.new(0.5, 0)
			b.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
			b.BorderSizePixel = 0
			b.Text = def.glyph
			b.TextSize = 20
			b.Font = Enum.Font.GothamBold
			b.TextColor3 = Color3.fromRGB(102, 102, 102)
			b.AutoButtonColor = false
			b.ZIndex = 35
			b.Parent = col
			UIKit.Corner(b, 99)
			UIKit.Stroke(b, Color3.fromRGB(58, 58, 58), 2, 0.1)

			local lab = lbl(col, def.label, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 1, -14), 9, Color3.fromRGB(74, 74, 74), 35)
			lab.TextXAlignment = Enum.TextXAlignment.Center
			lab.Font = Enum.Font.GothamBold

			tabButtons[def.id] = b
			tabLabels[def.id] = lab

			b.MouseButton1Click:Connect(function()
				tab = def.id
				api:Refresh()
			end)
		end

		-- Tooltip
		tip = solid(canvas, "Tooltip", UDim2.fromOffset(220, 118), UDim2.fromOffset(0, 0), Color3.fromRGB(14, 14, 14), 80)
		tip.Visible = false
		UIKit.Stroke(tip, BD2, 1, 0.1)
		UIKit.Pad(tip, 10)
		lbl(tip, "", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 0), 11, TW, 81).Name = "Title"
		lbl(tip, "", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 22), 12, TD, 81, Enum.Font.Gotham).Name = "Rarity"
		local td = lbl(tip, "", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 42), 12, TD, 81, Enum.Font.Gotham)
		td.Name = "Desc"
		td.TextWrapped = true
		td.TextYAlignment = Enum.TextYAlignment.Top
		lbl(tip, "", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 90), 12, GOLD, 81, Enum.Font.Gotham).Name = "Extra"

		if mouseMove then
			mouseMove:Disconnect()
		end
		mouseMove = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible then
				local p = UserInputService:GetMouseLocation()
				local abs = canvas.AbsolutePosition
				local sz = tip.AbsoluteSize
				local x = p.X - abs.X + 14
				local y = p.Y - abs.Y + 14
				-- keep on canvas
				if canvas.AbsoluteSize.X > 0 then
					x = math.clamp(x, 4, math.max(4, canvas.AbsoluteSize.X - sz.X - 4))
					y = math.clamp(y, 4, math.max(4, canvas.AbsoluteSize.Y - sz.Y - 4))
				end
				tip.Position = UDim2.fromOffset(x, y)
			end
		end)
	end

	api = {} :: Api

	function api:GetTab(): string
		return tab
	end

	function api:SetTab(t: string)
		local ok = false
		for _, def in ipairs(TABS) do
			if def.id == t then
				ok = true
				break
			end
		end
		if ok then
			tab = t
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

		-- tab highlight
		for id, b in tabButtons do
			local on = id == tab
			b.BackgroundColor3 = on and Color3.fromRGB(38, 38, 38) or Color3.fromRGB(28, 28, 28)
			b.TextColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(102, 102, 102)
			local st = b:FindFirstChildOfClass("UIStroke")
			if st then
				st.Color = on and CYAN or Color3.fromRGB(58, 58, 58)
			end
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
		infoLab.Text = string.format(
			"● %s  |  R%d %s   ●  Loc %s",
			lp and lp.Name or "Player",
			stats and (stats.rebirthLevel or 0) or 0,
			stats and Format.Mult(stats.rebirthMult) or "x1",
			tostring(profile.currentLocation or 1)
		)

		-- mini slots: main / off / aura glyphs
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
			previewLab.Text = "⚔"
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
				local btn = Instance.new("TextButton")
				btn.Name = "W_" .. w.uid
				btn.Size = UDim2.fromOffset(SLOT, SLOT)
				btn.BackgroundColor3 = BG_SLOT
				btn.BorderSizePixel = 0
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.LayoutOrder = i
				btn.ZIndex = 35
				btn.Parent = scroll
				local def = WeaponConfig.Get(w.id)
				local edge = rarityBorder(def and def.rarity)
				local isSel = w.uid == selectedWeaponUid
				UIKit.Stroke(btn, isSel and CYAN or edge, isSel and 2 or 1, 0.15)

				local img = Instance.new("ImageLabel")
				img.BackgroundTransparency = 1
				img.Size = UDim2.fromScale(0.7, 0.7)
				img.Position = UDim2.fromScale(0.5, 0.45)
				img.AnchorPoint = Vector2.new(0.5, 0.5)
				img.Image = IconConfig.GetWeaponImage(w.id)
				img.ScaleType = Enum.ScaleType.Fit
				img.ZIndex = 36
				img.Parent = btn

				if profile.equippedMain == w.uid or profile.equippedOffhand == w.uid then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(6, 6)
					dot.Position = UDim2.fromOffset(4, 4)
					dot.BackgroundColor3 = CYAN
					dot.BorderSizePixel = 0
					dot.ZIndex = 37
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
				lbl(row, (def and def.name) or selected.id, UDim2.fromOffset(110, 28), nil, 11, rarityBorder(def and def.rarity), 35)
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
				lbl(row, "Empty — loot weapons from mobs", UDim2.fromOffset(220, 28), nil, 12, TL, 35)
			end

		---------------------------------------------------------------- PETS (slot grid like Make)
		elseif tab == "pets" then
			previewLab.Text = "🐾"
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
				local btn = Instance.new("TextButton")
				btn.Name = "P_" .. tostring(p.uid)
				btn.Size = UDim2.fromOffset(SLOT, SLOT)
				btn.BackgroundColor3 = BG_SLOT
				btn.BorderSizePixel = 0
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.LayoutOrder = i
				btn.ZIndex = 35
				btn.Parent = scroll
				UIKit.Stroke(btn, rarityBorder(rar), 1, 0.15)

				local glyph = lbl(btn, "🐾", UDim2.fromScale(1, 0.7), UDim2.fromScale(0, 0.05), 22, TW, 36)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				if inTeam then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(6, 6)
					dot.Position = UDim2.fromOffset(4, 4)
					dot.BackgroundColor3 = CYAN
					dot.BorderSizePixel = 0
					dot.ZIndex = 37
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
			if #pets == 0 then
				lbl(row, "Empty — open a pet case", UDim2.fromOffset(180, 28), nil, 12, TL, 35)
			end

		---------------------------------------------------------------- AURAS
		elseif tab == "auras" then
			previewLab.Text = "✨"
			local auras = profile.auras or {}
			countLab.Text = string.format("%d auras", #auras)
			local scroll = makeSlotGrid(main)

			for i, a in ipairs(auras) do
				local def = AuraConfig.Get(a.id)
				local name = (def and def.name) or a.name or a.id
				local rar = (def and def.rarity) or a.rarity or "Common"
				local active = profile.equippedAura == a.uid
				local btn = Instance.new("TextButton")
				btn.Name = "A_" .. tostring(a.uid)
				btn.Size = UDim2.fromOffset(SLOT, SLOT)
				btn.BackgroundColor3 = BG_SLOT
				btn.BorderSizePixel = 0
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.LayoutOrder = i
				btn.ZIndex = 35
				btn.Parent = scroll
				UIKit.Stroke(btn, rarityBorder(rar), 1, 0.15)
				local glyph = lbl(btn, "✨", UDim2.fromScale(1, 0.7), UDim2.fromScale(0, 0.05), 22, TW, 36)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				if active then
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(6, 6)
					dot.Position = UDim2.fromOffset(4, 4)
					dot.BackgroundColor3 = CYAN
					dot.BorderSizePixel = 0
					dot.ZIndex = 37
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
			previewLab.Text = "💎"
			local relics = profile.relics or {}
			countLab.Text = string.format("%d relics", #relics)
			local scroll = makeSlotGrid(main)
			for i, r in ipairs(relics) do
				local btn = Instance.new("TextButton")
				btn.Name = "R" .. i
				btn.Size = UDim2.fromOffset(SLOT, SLOT)
				btn.BackgroundColor3 = BG_SLOT
				btn.BorderSizePixel = 0
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.LayoutOrder = i
				btn.ZIndex = 35
				btn.Parent = scroll
				UIKit.Stroke(btn, BD, 1, 0.2)
				local glyph = lbl(btn, "💎", UDim2.fromScale(1, 0.65), nil, 20, TW, 36)
				glyph.TextXAlignment = Enum.TextXAlignment.Center
				local stars = lbl(btn, "★" .. tostring(r.stars or 1), UDim2.new(1, 0, 0, 12), UDim2.new(0, 0, 1, -14), 9, GOLD, 36)
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
			lbl(row, "Relics are read-only (dungeon drops)", UDim2.fromOffset(280, 28), nil, 12, TL, 35)

		---------------------------------------------------------------- CASES
		elseif tab == "cases" then
			previewLab.Text = "📦"
			countLab.Text = ""
			local scroll = UIKit.Scroll(main, UDim2.new(1, -8, 1, -8))
			scroll.Position = UDim2.fromOffset(4, 4)
			local function caseCard(order: number, title: string, kind: string, color: Color3)
				local c = solid(scroll, kind, UDim2.new(1, -8, 0, 90), nil, BG_SECTION, 35)
				c.LayoutOrder = order
				UIKit.Stroke(c, color, 1.5, 0.25)
				UIKit.Pad(c, 10)
				lbl(c, title, UDim2.new(1, 0, 0, 24), nil, 14, TW, 36)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 34)
				b.Position = UDim2.new(0, 0, 1, -34)
				b.BackgroundColor3 = color
				b.Text = "Open"
				b.TextColor3 = Color3.new(1, 1, 1)
				b.Font = Enum.Font.GothamBold
				b.TextSize = 13
				b.BorderSizePixel = 0
				b.ZIndex = 37
				b.Parent = c
				UIKit.Corner(b, 4)
				b.MouseButton1Click:Connect(function()
					openModal("case", { kind = kind })
				end)
			end
			caseCard(1, "🐾  Pet Case", "pet", Color3.fromRGB(40, 120, 80))
			caseCard(2, "✨  Aura Case", "aura", Color3.fromRGB(100, 60, 160))
			local row = actionsRow()
			keybind(row, 1, "LMB", "Open case")

		---------------------------------------------------------------- SHOP (gamepasses)
		elseif tab == "shop" then
			previewLab.Text = "🪙"
			countLab.Text = "Gamepasses"
			local scroll = UIKit.Scroll(main, UDim2.new(1, -8, 1, -8))
			scroll.Position = UDim2.fromOffset(4, 4)
			for _, ch in scroll:GetChildren() do
				if ch:IsA("UIListLayout") then
					ch:Destroy()
				end
			end
			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.fromOffset(140, 176)
			grid.CellPadding = UDim2.fromOffset(10, 10)
			grid.SortOrder = Enum.SortOrder.LayoutOrder
			grid.FillDirectionMaxCells = 4
			grid.Parent = scroll
			UIKit.Pad(scroll, 6)

			local unlocks = profile.unlocks or {}
			for i, key in ipairs(GamePassConfig.Order) do
				local def = GamePassConfig.Get(key)
				if def then
					local owned = def.feature and unlocks[def.feature] == true
					local card = solid(scroll, key, UDim2.fromOffset(140, 176), nil, BG_SECTION, 35)
					card.LayoutOrder = i
					UIKit.Stroke(card, owned and GREEN or BD2, 1, owned and 0.05 or 0.15)

					local imgBtn = Instance.new("ImageButton")
					imgBtn.Name = "Buy"
					imgBtn.Size = UDim2.fromOffset(110, 110)
					imgBtn.Position = UDim2.new(0.5, 0, 0, 8)
					imgBtn.AnchorPoint = Vector2.new(0.5, 0)
					imgBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
					imgBtn.BorderSizePixel = 0
					imgBtn.Image = GamePassConfig.ThumbUrl(def.gamePassId, 150)
					imgBtn.ScaleType = Enum.ScaleType.Fit
					imgBtn.AutoButtonColor = not owned
					imgBtn.ZIndex = 36
					imgBtn.Parent = card
					UIKit.Corner(imgBtn, 6)
					UIKit.Stroke(imgBtn, BD, 1, 0.2)
					if owned then
						imgBtn.ImageTransparency = 0.15
						local badge = lbl(imgBtn, "OWNED", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -18), 10, GREEN, 38)
						badge.TextXAlignment = Enum.TextXAlignment.Center
						badge.BackgroundColor3 = Color3.fromRGB(10, 20, 12)
						badge.BackgroundTransparency = 0.25
					end

					local titleL = lbl(card, def.title, UDim2.new(1, -8, 0, 16), UDim2.fromOffset(4, 120), 10, TW, 36)
					titleL.TextXAlignment = Enum.TextXAlignment.Center
					titleL.TextTruncate = Enum.TextTruncate.AtEnd
					local priceLab = lbl(
						card,
						owned and "Owned" or "…",
						UDim2.new(1, -8, 0, 16),
						UDim2.fromOffset(4, 148),
						11,
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
						setTooltip(def.title, nil, def.desc, owned and "● Already owned" or "LMB purchase")
					end)
					imgBtn.MouseLeave:Connect(hideTooltip)
				end
			end
			local row = actionsRow()
			keybind(row, 1, "LMB", "Purchase")
			lbl(row, "Roblox gamepasses", UDim2.fromOffset(160, 28), nil, 12, TL, 35)

		---------------------------------------------------------------- PROFILE
		else
			previewLab.Text = "👤"
			countLab.Text = ""
			local scroll = UIKit.Scroll(main, UDim2.new(1, -8, 1, -8))
			scroll.Position = UDim2.fromOffset(4, 4)

			-- two columns like Make (mods + combat)
			local cols = Instance.new("Frame")
			cols.BackgroundTransparency = 1
			cols.Size = UDim2.new(1, -8, 0, 320)
			cols.LayoutOrder = 1
			cols.ZIndex = 35
			cols.Parent = scroll
			UIKit.List(cols, 10, true)

			local function colPanel(name: string, order: number): Frame
				local p = solid(cols, name, UDim2.new(0.5, -8, 1, 0), nil, BG_SECTION, 36)
				p.LayoutOrder = order
				UIKit.Stroke(p, BD, 1, 0.2)
				UIKit.Pad(p, 10)
				local list = Instance.new("UIListLayout")
				list.Padding = UDim.new(0, 4)
				list.SortOrder = Enum.SortOrder.LayoutOrder
				list.Parent = p
				return p
			end

			local leftCol = colPanel("Mods", 1)
			local rightCol = colPanel("Combat", 2)
			lbl(leftCol, "MODIFIERS", UDim2.new(1, 0, 0, 16), nil, 9, TL, 37).LayoutOrder = 0
			lbl(rightCol, "COMBAT STATS", UDim2.new(1, 0, 0, 16), nil, 9, TL, 37).LayoutOrder = 0

			local function statLine(parent: Frame, order: number, label: string, value: string, dot: Color3, vcol: Color3?)
				local line = solid(parent, "L" .. order, UDim2.new(1, 0, 0, 22), nil, BG_SECTION, 37)
				line.BackgroundTransparency = 1
				line.LayoutOrder = order
				local d = Instance.new("Frame")
				d.Size = UDim2.fromOffset(7, 7)
				d.Position = UDim2.new(0, 0, 0.5, 0)
				d.AnchorPoint = Vector2.new(0, 0.5)
				d.BackgroundColor3 = dot
				d.BorderSizePixel = 0
				d.ZIndex = 38
				d.Parent = line
				UIKit.Corner(d, 99)
				lbl(line, label, UDim2.new(0.62, -12, 1, 0), UDim2.fromOffset(14, 0), 11, TD, 38, Enum.Font.Gotham)
				local v = lbl(line, value, UDim2.new(0.38, 0, 1, 0), UDim2.new(0.62, 0, 0, 0), 12, vcol or TW, 38, Enum.Font.GothamBold)
				v.TextXAlignment = Enum.TextXAlignment.Right
			end

			statLine(leftCol, 1, "Click power", Format.Num(stats and (stats.damagePerClick or stats.totalPower) or 0), Color3.fromRGB(204, 68, 68), TW)
			statLine(leftCol, 2, "CPS", string.format("%.2f", stats and stats.cps or 0), GREEN, GREEN)
			statLine(leftCol, 3, "Crit chance", Format.Pct(stats and stats.crit or 0), GOLD, GOLD)
			statLine(leftCol, 4, "Luck", Format.Pct(stats and stats.luck or 0), CYAN, GREEN)
			statLine(leftCol, 5, "Rebirth", string.format("R%d %s", stats and (stats.rebirthLevel or 0) or 0, stats and Format.Mult(stats.rebirthMult) or "x1"), GOLD, GOLD)

			statLine(rightCol, 1, "DPS", Format.Num(stats and stats.dps or 0), Color3.fromRGB(204, 68, 68), TW)
			statLine(rightCol, 2, "Coins", Format.Num(stats and stats.coins or 0), GOLD, GOLD)
			statLine(rightCol, 3, "Total clicks", Format.Num(stats and stats.totalClicks or 0), GREEN, TW)
			statLine(rightCol, 4, "Lifetime dmg", Format.Num(stats and stats.lifetimeDamage or 0), Color3.fromRGB(144, 112, 192), TW)
			statLine(rightCol, 5, "Location", tostring(profile.currentLocation or 1), CYAN, CYAN)

			local row = actionsRow()
			lbl(row, "Stats from live profile", UDim2.fromOffset(220, 28), nil, 12, TL, 35)
		end
	end

	return api
end

return Inventory
