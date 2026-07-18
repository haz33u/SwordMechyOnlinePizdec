--!strict
--[[
	All game windows share Theme design system:
	header (icon + title + close) | body sections | cards with semantic CTAs
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)
local Rarity = require(script.Parent.Rarity)
local Layout = require(script.Parent.Layout)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UpgradeConfig = require(Shared.Config.UpgradeConfig)
local WorldConfig = require(Shared.Config.WorldConfig)
local QuestConfig = require(Shared.Config.QuestConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local IconConfig = require(Shared.Config.IconConfig)

local Windows = {}

-- Interior upscale for left-rail panels only (HUD bottom untouched)
local S = 1.42
local function px(n: number): number
	return math.floor(n * S + 0.5)
end

local function surfaceCard(parent: Instance, h: number, order: number, edge: Color3?): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	f.Size = UDim2.new(1, -6, 0, px(h))
	f.LayoutOrder = order
	f.ZIndex = 32
	f.ClipsDescendants = true
	f.Parent = parent
	UIKit.Corner(f, T.R.sm)
	UIKit.Stroke(f, edge or T.Stroke, edge and 1.5 or 1.1, edge and 0.25 or 0.2)
	UIKit.Gradient(f, T.Surface3, T.Surface2, 105)
	UIKit.Pad(f, px(12))
	return f
end

local function sectionLabel(parent: Instance, text: string, order: number)
	return UIKit.Label({
		Parent = parent,
		Text = text,
		Size = UDim2.new(1, 0, 0, px(28)),
		SizePx = px(16),
		Font = T.Font.Title,
		Color = T.TextMuted,
		Order = order,
		Z = 33,
	})
end


function Windows.Mount(gui: ScreenGui, store: any, openModal: (string, any?) -> ())
	local folder = Instance.new("Folder")
	folder.Name = "Windows"
	folder.Parent = gui

	local frames: { [string]: Frame } = {}
	local bodies: { [string]: Frame } = {}

	local titles = {
		character = "Profile",
		weapons = "Weapon Inventory",
		pets = "Pets",
		auras = "Auras",
		cases = "Cases",
		relics = "Relics",
		quests = "Quests",
		locations = "Teleport",
		dungeons = "Dungeons",
		shop = "Donate Shop",
	}

	for id, title in titles do
		local icon = (T.WindowIcon and T.WindowIcon[id]) or "◆"
		local root, body = UIKit.Window(folder, title, function()
			store:ClosePanel()
		end, icon)
		root.Name = id
		frames[id] = root
		bodies[id] = body
	end

	-- Larger shells so upscaled interiors fit (HUD layout metrics untouched)
	Layout.Bind(function(m)
		local ww = math.clamp((m.windowW or 0.5) + 0.10, 0.56, 0.68)
		local wh = math.clamp((m.windowH or 0.62) + 0.10, 0.66, 0.80)
		for _, root in frames do
			root.Size = UDim2.fromScale(ww, wh)
		end
	end)

	local function showOnly(active: string)
		for id, f in frames do
			f.Visible = id == active
		end
	end

	---------------------------------------------------------------- Character = profile stats + upgrades
	local function refreshCharacter()
		local body = bodies.character
		UIKit.Clear(body)
		UIKit.List(body, px(8), false)
		local stats = store:PeekStats()
		local profile = store:PeekProfile()
		if not stats or not profile then
			return
		end

		-- Full stats list (moved from HUD: CPS/DPS/Clicks + more)
		sectionLabel(body, "PROFILE / STATS", 1)
		local statsScroll = UIKit.Scroll(body, UDim2.new(1, 0, 0, px(200)))
		statsScroll.LayoutOrder = 2
		local rows = {
			{ "Power (click)", Format.Num(stats.damagePerClick or stats.totalPower) },
			{ "CPS", string.format("%.2f", stats.cps or 0) },
			{ "DPS", Format.Num(stats.dps) },
			{ "Clicks", Format.Num(stats.totalClicks) },
			{ "Coins", Format.Num(stats.coins) },
			{ "Crit chance", Format.Pct(stats.crit) },
			{ "Luck", Format.Pct(stats.luck) },
			{ "Rebirth", string.format("R%d  %s", stats.rebirthLevel or 0, Format.Mult(stats.rebirthMult)) },
			{ "Lifetime damage", Format.Num(stats.lifetimeDamage or 0) },
			{ "Location", tostring(stats.location or profile.currentLocation or 1) },
			{ "Swing CD", string.format("%.2fs", stats.swingCd or 1) },
			{ "Auto", stats.autoClicker and "ON" or "OFF" },
		}
		for i, r in ipairs(rows) do
			local line = Instance.new("Frame")
			line.BackgroundTransparency = 1
			line.Size = UDim2.new(1, -4, 0, px(22))
			line.LayoutOrder = i
			line.ZIndex = 33
			line.Parent = statsScroll
			UIKit.Label({
				Parent = line,
				Text = r[1],
				Size = UDim2.new(0.55, 0, 1, 0),
				SizePx = px(13),
				Color = T.TextMuted,
				Z = 34,
			})
			UIKit.Label({
				Parent = line,
				Text = r[2],
				Size = UDim2.new(0.45, 0, 1, 0),
				Position = UDim2.new(0.55, 0, 0, 0),
				SizePx = px(13),
				Font = T.Font.Title,
				Color = T.Text,
				X = Enum.TextXAlignment.Right,
				Z = 34,
			})
		end

		sectionLabel(body, "UPGRADES", 3)

		-- horizontal upgrade cards like UIУлучшений
		local rowHost = Instance.new("ScrollingFrame")
		rowHost.Name = "UpgradesRow"
		rowHost.BackgroundTransparency = 1
		rowHost.BorderSizePixel = 0
		rowHost.Size = UDim2.new(1, 0, 0, px(260))
		rowHost.LayoutOrder = 4
		rowHost.ScrollBarThickness = 4
		rowHost.ScrollBarImageColor3 = T.StrokeLight
		rowHost.CanvasSize = UDim2.new(0, 0, 0, 0)
		rowHost.AutomaticCanvasSize = Enum.AutomaticSize.X
		rowHost.ScrollingDirection = Enum.ScrollingDirection.X
		rowHost.ZIndex = 32
		rowHost.Parent = body
		local rowList = UIKit.List(rowHost, px(10), true)
		rowList.VerticalAlignment = Enum.VerticalAlignment.Top
		UIKit.Pad(rowHost, 2)

		local coins = stats.coins or 0
		local cardW = px(148)
		for i, upId in UpgradeConfig.Order do
			local def = UpgradeConfig.Defs[upId]
			if def then
				local lvl = (profile.upgradeLevels and profile.upgradeLevels[upId]) or 0
				local cost = UpgradeConfig.GetCost(upId, lvl + 1)
				local canBuy = lvl < def.maxLevel and coins >= cost
				local maxed = lvl >= def.maxLevel
				local icon = (T.UpgradeIcon and T.UpgradeIcon[upId]) or "◆"
				local col = (T.UpgradeColor and T.UpgradeColor[upId]) or T.Accent

				-- effect preview text
				local effectLine = ""
				if def.effectType == "mult_add" then
					effectLine = string.format("+%s%%", tostring(math.floor((def.effectPerLevel or 0) * 100 * math.max(lvl, 0))))
				elseif def.statKey == "bagSlots" then
					effectLine = string.format("%d slots", math.floor((def.effectPerLevel or 0) * lvl))
				else
					effectLine = string.format("+%s", Format.Num((def.effectPerLevel or 0) * lvl))
				end

				local card = Instance.new("Frame")
				card.Name = upId
				card.BackgroundColor3 = Color3.new(1, 1, 1)
				card.BorderSizePixel = 0
				card.Size = UDim2.fromOffset(cardW, px(268))
				card.LayoutOrder = i
				card.ZIndex = 33
				card.ClipsDescendants = true
				card.Parent = rowHost
				UIKit.Corner(card, T.R.sm)
				UIKit.Stroke(card, T.Stroke, 1.1, 0.15)
				UIKit.Gradient(card, T.Surface2, T.Surface, 105)

				-- title
				UIKit.Label({
					Parent = card,
					Text = def.name,
					Size = UDim2.new(1, -8, 0, px(24)),
					Position = UDim2.fromOffset(4, px(6)),
					SizePx = px(13),
					Font = T.Font.Title,
					Color = T.Text,
					X = Enum.TextXAlignment.Center,
					Z = 34,
				})

				-- colored icon block
				local iconBox = Instance.new("Frame")
				iconBox.BackgroundColor3 = col
				iconBox.BorderSizePixel = 0
				iconBox.Size = UDim2.new(1, -16, 0, px(88))
				iconBox.Position = UDim2.fromOffset(8, px(34))
				iconBox.ZIndex = 34
				iconBox.Parent = card
				UIKit.Corner(iconBox, T.R.sm)
				UIKit.Label({
					Parent = iconBox,
					Text = icon,
					Size = UDim2.fromScale(1, 1),
					SizePx = px(40),
					X = Enum.TextXAlignment.Center,
					Z = 35,
				})

				-- level / effect
				UIKit.Label({
					Parent = card,
					Text = string.format("Level  %d / %d", lvl, def.maxLevel),
					Size = UDim2.new(1, -12, 0, px(18)),
					Position = UDim2.fromOffset(6, px(130)),
					SizePx = px(12),
					Color = T.TextMuted,
					Z = 34,
				})
				UIKit.Label({
					Parent = card,
					Text = effectLine,
					Size = UDim2.new(1, -12, 0, px(18)),
					Position = UDim2.fromOffset(6, px(148)),
					SizePx = px(13),
					Color = T.TextSoft,
					Z = 34,
				})
				UIKit.Label({
					Parent = card,
					Text = maxed and "MAX" or ("Cost  " .. Format.Num(cost) .. " 🪙"),
					Size = UDim2.new(1, -12, 0, px(18)),
					Position = UDim2.fromOffset(6, px(172)),
					SizePx = px(13),
					Color = maxed and T.TextMuted or T.Gold,
					Font = T.Font.Title,
					Z = 34,
				})

				UIKit.Button({
					Parent = card,
					Text = maxed and "MAX" or "Upgrade",
					Size = UDim2.new(1, -16, 0, px(36)),
					Position = UDim2.new(0, 8, 1, -px(44)),
					Color = maxed and T.Disabled or (canBuy and T.Accent or T.Disabled),
					Color2 = maxed and (T.Colors and T.Colors.DisabledDeep)
						or (canBuy and T.AccentDeep or (T.Colors and T.Colors.DisabledDeep)),
					Primary = canBuy and not maxed,
					Disabled = maxed or not canBuy,
					SizePx = px(14),
					Z = 35,
					OnClick = function()
						if canBuy and not maxed then
							Net.BuyUpgrade(upId)
						end
					end,
				})
			end
		end
	end

	---------------------------------------------------------------- Weapons — slot inventory (no paper doll)
	local selectedWeaponUid: string? = nil
	local INV_CAP = 32

	local function refreshWeapons()
		local body = bodies.weapons
		UIKit.Clear(body)
		UIKit.List(body, px(8), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local weapons = profile.weapons or {}
		local count = #weapons

		local function weaponLabel(uid: any): string
			if type(uid) ~= "string" then
				return "—"
			end
			for _, w in ipairs(weapons) do
				if w.uid == uid then
					local def = WeaponConfig.Get(w.id)
					return ((def and def.name) or w.id):sub(1, 14)
				end
			end
			return "—"
		end

		-- header: equipped + count
		local head = surfaceCard(body, 48, 1, T.Stroke)
		local stats = store:PeekStats()
		local offUnlocked = (stats and stats.offhandUnlocked) == true
			or (profile.unlocks and profile.unlocks.offhand) == true
		UIKit.Label({
			Parent = head,
			Text = string.format(
				"Main: %s   ·   Off: %s",
				weaponLabel(profile.equippedMain),
				if offUnlocked then weaponLabel(profile.equippedOffhand) else "🔒 paid"
			),
			Size = UDim2.new(0.72, 0, 1, 0),
			SizePx = px(14),
			Color = T.TextSoft,
			Z = 33,
		})
		UIKit.Label({
			Parent = head,
			Text = string.format("%d of %d", count, INV_CAP),
			Size = UDim2.new(0.28, 0, 1, 0),
			Position = UDim2.new(0.72, 0, 0, 0),
			SizePx = px(14),
			Color = T.TextMuted,
			X = Enum.TextXAlignment.Right,
			Z = 33,
		})

		-- action bar for selected
		local act = surfaceCard(body, 52, 2, T.Stroke)
		local selected: any = nil
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
		if selected then
			local def = WeaponConfig.Get(selected.id)
			local name = (def and def.name) or selected.id
			UIKit.Label({
				Parent = act,
				Text = name,
				Size = UDim2.new(0.28, 0, 1, 0),
				SizePx = px(13),
				Font = T.Font.Title,
				Color = Rarity.Of(def and def.rarity),
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(0.72, 0, 1, 0)
			row.Position = UDim2.new(0.28, 0, 0, 0)
			row.ZIndex = 33
			row.Parent = act
			UIKit.List(row, px(6), true, Enum.HorizontalAlignment.Right)
			UIKit.Button({
				Parent = row,
				Text = "Equip main",
				Size = UDim2.fromOffset(px(100), px(34)),
				SizePx = px(12),
				Primary = true,
				OnClick = function()
					Net.EquipWeapon(selected.uid, "main")
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = if offUnlocked then "Equip off" else "Off 🔒",
				Size = UDim2.fromOffset(px(100), px(34)),
				SizePx = px(12),
				Disabled = not offUnlocked,
				OnClick = function()
					if offUnlocked then
						Net.EquipWeapon(selected.uid, "offhand")
					else
						Net.UnlockPaidFeature("offhand")
					end
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Enchant",
				Size = UDim2.fromOffset(px(56), px(34)),
				SizePx = px(12),
				Color = Color3.fromRGB(90, 60, 140),
				Color2 = Color3.fromRGB(55, 35, 90),
				OnClick = function()
					Net.EnchantWeapon(selected.uid)
					openModal("enchant", selected)
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Sell",
				Size = UDim2.fromOffset(px(72), px(34)),
				SizePx = px(12),
				Color = T.Danger,
				Color2 = T.Colors and T.Colors.DangerDeep,
				OnClick = function()
					openModal("sell", selected)
				end,
			})
		else
			UIKit.Label({
				Parent = act,
				Text = "Empty — loot weapons from mobs",
				Size = UDim2.new(1, 0, 1, 0),
				SizePx = px(14),
				Color = T.TextMuted,
				Z = 33,
			})
		end

		-- slot grid
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(120)))
		scroll.LayoutOrder = 3
		-- replace default vertical list with grid
		for _, ch in scroll:GetChildren() do
			if ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(px(78), px(78))
		grid.CellPadding = UDim2.fromOffset(px(8), px(8))
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = 6
		grid.Parent = scroll
		UIKit.Pad(scroll, px(4))

		local function makeSlot(order: number, w: any?)
			local rarity = "Common"
			local edge = T.Stroke
			if w then
				local def = WeaponConfig.Get(w.id)
				rarity = (def and def.rarity) or "Common"
				edge = Rarity.Of(rarity)
			end
			local isSel = w and w.uid == selectedWeaponUid
			local slot = Instance.new("TextButton")
			slot.Name = w and ("W_" .. tostring(w.uid)) or ("Empty_" .. order)
			slot.AutoButtonColor = false
			slot.Text = ""
			slot.BackgroundColor3 = Color3.new(1, 1, 1)
			slot.BorderSizePixel = 0
			slot.LayoutOrder = order
			slot.ZIndex = 33
			slot.Parent = scroll
			UIKit.Corner(slot, T.R.sm)
			UIKit.Stroke(slot, isSel and T.Accent or edge, isSel and 2 or 1.3, isSel and 0.15 or 0.25)
			UIKit.Gradient(slot, T.Surface3, T.Surface2, 110)

			if w then
				local img = Instance.new("ImageLabel")
				img.BackgroundTransparency = 1
				img.Size = UDim2.fromScale(0.72, 0.72)
				img.Position = UDim2.fromScale(0.5, 0.42)
				img.AnchorPoint = Vector2.new(0.5, 0.5)
				img.Image = IconConfig.GetWeaponImage(w.id)
				img.ScaleType = Enum.ScaleType.Fit
				img.ZIndex = 34
				img.Parent = slot
				local def = WeaponConfig.Get(w.id)
				UIKit.Label({
					Parent = slot,
					Text = (def and def.name or w.id):sub(1, 8),
					Size = UDim2.new(1, -4, 0, px(14)),
					Position = UDim2.new(0, 2, 1, -px(16)),
					SizePx = px(10),
					Color = edge,
					X = Enum.TextXAlignment.Center,
					Z = 34,
				})
				-- equipped badge (profile stores weapon uid)
				local eq = ""
				if profile.equippedMain == w.uid then
					eq = "M"
				elseif profile.equippedOffhand == w.uid then
					eq = "O"
				end
				if eq ~= "" then
					UIKit.Label({
						Parent = slot,
						Text = eq,
						Size = UDim2.fromOffset(px(16), px(16)),
						Position = UDim2.fromOffset(px(4), px(2)),
						SizePx = px(11),
						Color = T.Accent,
						Font = T.Font.Title,
						Z = 35,
					})
				end
				slot.MouseButton1Click:Connect(function()
					selectedWeaponUid = w.uid
					refreshWeapons()
				end)
			else
				UIKit.Label({
					Parent = slot,
					Text = "",
					Size = UDim2.fromScale(1, 1),
					Z = 34,
				})
				slot.Active = false
			end
		end

		for i, w in ipairs(weapons) do
			makeSlot(i, w)
		end
		for i = count + 1, INV_CAP do
			makeSlot(i, nil)
		end
	end

	---------------------------------------------------------------- Pets
	local function refreshPets()
		local body = bodies.pets
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local btnW = px(110)
		local head = surfaceCard(body, 56, 1, T.Gold)
		local pStats = store:PeekStats()
		local slots = profile.petSlots or 3
		local hint = (pStats and pStats.nextPetSlotHint) or ""
		UIKit.Label({
			Parent = head,
			Text = string.format("Team %d / %d", #(profile.petTeam or {}), slots),
			Size = UDim2.new(1, -btnW - 12, 0, px(22)),
			SizePx = px(16),
			Color = T.Text,
			Z = 33,
		})
		if hint ~= "" then
			UIKit.Label({
				Parent = head,
				Text = hint,
				Size = UDim2.new(1, -btnW - 12, 0, px(18)),
				Position = UDim2.fromOffset(0, px(24)),
				SizePx = px(11),
				Color = T.TextMuted,
				Z = 33,
			})
		end
		UIKit.Button({
			Parent = head,
			Text = "Case",
			Size = UDim2.fromOffset(btnW, px(40)),
			Position = UDim2.new(1, -btnW, 0.5, -px(20)),
			Color = T.GoldDeep,
			Color2 = Color3.fromRGB(180, 110, 25),
			Primary = true,
			SizePx = px(15),
			Z = 34,
			OnClick = function()
				openModal("case", { kind = "pet" })
			end,
		})
		-- paid +1 slot (7th)
		local paidOwned = (pStats and pStats.paidPetSlot) == true
			or (profile.unlocks and profile.unlocks.paidPetSlot) == true
		if not paidOwned and slots < 7 then
			local payRow = surfaceCard(body, 44, 2, T.Stroke)
			UIKit.Label({
				Parent = payRow,
				Text = "Paid: +1 pet slot",
				Size = UDim2.new(0.6, 0, 1, 0),
				SizePx = px(13),
				Color = T.TextSoft,
				Z = 33,
			})
			UIKit.Button({
				Parent = payRow,
				Text = "Unlock (debug)",
				Size = UDim2.fromOffset(px(130), px(32)),
				Position = UDim2.new(1, -px(130), 0.5, -px(16)),
				SizePx = px(12),
				Primary = true,
				Z = 34,
				OnClick = function()
					Net.UnlockPaidFeature("paidPetSlot")
				end,
			})
		end
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(120)))
		scroll.LayoutOrder = 2
		for i, p in ipairs(profile.pets or {}) do
			local inTeam = false
			for _, uid in ipairs(profile.petTeam or {}) do
				if uid == p.uid then
					inTeam = true
					break
				end
			end
			local sideW = px(150)
			local c = surfaceCard(scroll, 88, i, Rarity.Of(p.rarity))
			UIKit.Label({
				Parent = c,
				Text = string.format(
					"%s · %s · lv%s%s",
					tostring(p.name or p.id),
					tostring(p.rarity or "Common"),
					tostring(p.level or 1),
					inTeam and " · TEAM" or ""
				),
				Size = UDim2.new(1, -sideW - 8, 0, px(22)),
				SizePx = px(15),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format(
					"+%s%% power   +%s%% coins",
					tostring(math.floor((p.powerPct or 0) * 100)),
					tostring(math.floor((p.coinPct or 0) * 100))
				),
				Size = UDim2.new(1, -sideW - 8, 0, px(18)),
				Position = UDim2.fromOffset(0, px(32)),
				SizePx = px(13),
				Color = T.TextMuted,
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.fromOffset(sideW, px(38))
			row.Position = UDim2.new(1, -sideW, 0.5, -px(19))
			row.ZIndex = 34
			row.Parent = c
			UIKit.List(row, px(8), true)
			UIKit.Button({
				Parent = row,
				Text = inTeam and "Unequip" or "Equip",
				Size = UDim2.fromOffset(px(72), px(36)),
				SizePx = px(13),
				Color = inTeam and T.Disabled or T.Success,
				Color2 = inTeam and (T.Colors and T.Colors.DisabledDeep) or (T.Colors and T.Colors.SuccessDeep),
				OnClick = function()
					if inTeam then
						Net.UnequipPet(p.uid)
					else
						Net.EquipPet(p.uid)
					end
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Feed",
				Size = UDim2.fromOffset(px(64), px(36)),
				SizePx = px(13),
				OnClick = function()
					Net.FeedPet(p.uid)
				end,
			})
		end
		if #(profile.pets or {}) == 0 then
			UIKit.Label({
				Parent = scroll,
				Text = "Empty — open a case.",
				Size = UDim2.new(1, 0, 0, px(48)),
				Color = T.TextMuted,
				SizePx = px(15),
			})
		end
	end

	---------------------------------------------------------------- Auras
	local function refreshAuras()
		local body = bodies.auras
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local btnW = px(110)
		local head = surfaceCard(body, 56, 1, T.Gold)
		UIKit.Label({
			Parent = head,
			Text = "Active: " .. tostring(profile.equippedAura or "none"),
			Size = UDim2.new(1, -btnW - 12, 1, 0),
			SizePx = px(16),
			Color = T.Text,
			Z = 33,
		})
		UIKit.Button({
			Parent = head,
			Text = "Case",
			Size = UDim2.fromOffset(btnW, px(40)),
			Position = UDim2.new(1, -btnW, 0.5, -px(20)),
			Color = Color3.fromRGB(100, 70, 160),
			Color2 = Color3.fromRGB(60, 40, 100),
			Primary = true,
			SizePx = px(15),
			Z = 34,
			OnClick = function()
				Net.OpenAuraCase()
				openModal("case", { kind = "aura" })
			end,
		})
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(72)))
		scroll.LayoutOrder = 2
		for i, a in ipairs(profile.auras or {}) do
			local c = surfaceCard(scroll, 72, i, Rarity.Of(a.rarity))
			UIKit.Label({
				Parent = c,
				Text = string.format("%s · %s", tostring(a.name or a.id), tostring(a.rarity or "Common")),
				Size = UDim2.new(1, -px(110), 1, 0),
				SizePx = px(16),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Equip",
				Size = UDim2.fromOffset(px(96), px(38)),
				Position = UDim2.new(1, -px(96), 0.5, -px(19)),
				Color = T.Success,
				Color2 = T.Colors and T.Colors.SuccessDeep,
				SizePx = px(14),
				Z = 34,
				OnClick = function()
					Net.EquipAura(a.uid)
				end,
			})
		end
	end

	---------------------------------------------------------------- Relics
	local function refreshRelics()
		local body = bodies.relics
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		sectionLabel(body, "FROM DUNGEONS (read-only)", 1)
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(40)))
		scroll.LayoutOrder = 2
		for i, r in ipairs(profile.relics or {}) do
			local c = surfaceCard(scroll, 62, i)
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ★%s", tostring(r.name or r.id), tostring(r.stars or 1)),
				Size = UDim2.new(1, 0, 1, 0),
				SizePx = px(16),
				Color = T.Text,
				Z = 33,
			})
		end
		if #(profile.relics or {}) == 0 then
			UIKit.Label({
				Parent = scroll,
				Text = "Empty — clear dungeons.",
				Size = UDim2.new(1, 0, 0, px(48)),
				Color = T.TextMuted,
				SizePx = px(15),
			})
		end
	end

	---------------------------------------------------------------- Quests
	local function refreshQuests()
		local body = bodies.quests
		UIKit.Clear(body)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local scroll = UIKit.Scroll(body, UDim2.fromScale(1, 1))
		local order = 0
		for id, state in pairs(profile.quests or {}) do
			order += 1
			local def = QuestConfig.Get(id)
			local name = (def and def.name) or id
			local desc = (def and def.description) or ""
			local amount = (def and def.amount) or 1
			local progress = state.progress or 0
			local done = state.completed == true
			local claimed = state.claimed == true
			local needBtn = done and not claimed

			local c = surfaceCard(scroll, needBtn and 118 or 100, claimed and (500 + order) or order, needBtn and T.Success or nil)
			UIKit.Label({
				Parent = c,
				Text = name,
				Size = UDim2.new(1, 0, 0, px(22)),
				SizePx = px(17),
				Font = T.Font.Title,
				Color = claimed and T.TextMuted or T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ·  %d/%d", desc, progress, amount),
				Size = UDim2.new(1, 0, 0, px(18)),
				Position = UDim2.fromOffset(0, px(26)),
				SizePx = px(13),
				Color = T.TextMuted,
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, px(36))
			row.Position = UDim2.fromOffset(0, px(56))
			row.ZIndex = 33
			row.Parent = c
			UIKit.List(row, px(10), true)
			local track = Instance.new("Frame")
			track.BackgroundColor3 = T.Surface
			track.BorderSizePixel = 0
			track.Size = UDim2.new(needBtn and 0.65 or 1, 0, 0, px(14))
			track.LayoutOrder = 1
			track.ZIndex = 33
			track.Parent = row
			UIKit.Corner(track, 99)
			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = done and T.Success or T.Gold
			fill.BorderSizePixel = 0
			fill.Size = UDim2.new(amount > 0 and math.clamp(progress / amount, 0, 1) or 0, 0, 1, 0)
			fill.Parent = track
			UIKit.Corner(fill, 99)
			if needBtn then
				UIKit.Button({
					Parent = row,
					Text = "Claim",
					Size = UDim2.fromOffset(px(100), px(36)),
					Color = T.Success,
					Color2 = T.Colors and T.Colors.SuccessDeep,
					SizePx = px(14),
					Order = 2,
					Z = 34,
					OnClick = function()
						Net.ClaimQuest(id)
					end,
				})
			elseif claimed then
				UIKit.Label({
					Parent = row,
					Text = "done",
					Size = UDim2.fromOffset(px(72), px(32)),
					Color = T.Success,
					SizePx = px(13),
					Order = 2,
				})
			end
		end
	end

	---------------------------------------------------------------- Locations / Teleport (existing SetLocation)
	local function refreshLocations()
		local body = bodies.locations
		UIKit.Clear(body)
		UIKit.List(body, px(10), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local current = profile.currentLocation or 1
		local stats = store:PeekStats()
		local power = (stats and (stats.totalPower or stats.damagePerClick)) or 0

		sectionLabel(body, "ENTER LOCATION", 1)
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(36)))
		scroll.LayoutOrder = 2
		-- 2-col grid like SCREEENS teleport
		for _, ch in scroll:GetChildren() do
			if ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.5, -px(8), 0, px(200))
		grid.CellPadding = UDim2.fromOffset(px(10), px(10))
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = 2
		grid.Parent = scroll
		UIKit.Pad(scroll, px(4))

		local themeTint = {
			Color3.fromRGB(40, 90, 50),
			Color3.fromRGB(40, 70, 110),
			Color3.fromRGB(90, 50, 40),
			Color3.fromRGB(50, 80, 110),
		}

		for i, meta in ipairs(WorldConfig.Locations) do
			local unlocked = false
			for _, id in ipairs(profile.locationsUnlocked or { 1 }) do
				if id == meta.id then
					unlocked = true
					break
				end
			end
			-- also allow if power enough (display unlock affordability)
			local canUnlock = power >= (meta.unlockPower or 0)
			local here = current == meta.id
			local tint = themeTint[((i - 1) % #themeTint) + 1]

			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.new(1, 1, 1)
			card.BorderSizePixel = 0
			card.LayoutOrder = i
			card.ZIndex = 33
			card.ClipsDescendants = true
			card.Parent = scroll
			UIKit.Corner(card, T.R.sm)
			UIKit.Stroke(card, here and T.Accent or T.Stroke, here and 1.8 or 1.1, 0.2)
			UIKit.Gradient(card, T.Surface2, T.Surface, 105)

			-- preview block
			local prev = Instance.new("Frame")
			prev.BackgroundColor3 = tint
			prev.BorderSizePixel = 0
			prev.Size = UDim2.new(1, -px(16), 0, px(72))
			prev.Position = UDim2.fromOffset(px(8), px(8))
			prev.ZIndex = 34
			prev.Parent = card
			UIKit.Corner(prev, T.R.sm)
			UIKit.Label({
				Parent = prev,
				Text = (T.WindowIcon and T.WindowIcon.locations) or "🗺",
				Size = UDim2.fromScale(1, 1),
				SizePx = px(28),
				X = Enum.TextXAlignment.Center,
				Z = 35,
			})

			UIKit.Label({
				Parent = card,
				Text = meta.name .. (here and "  ·  HERE" or ""),
				Size = UDim2.new(1, -px(16), 0, px(22)),
				Position = UDim2.fromOffset(px(8), px(88)),
				SizePx = px(14),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 34,
			})
			UIKit.Label({
				Parent = card,
				Text = (meta.blurb or meta.theme or ""):sub(1, 64),
				Size = UDim2.new(1, -px(16), 0, px(32)),
				Position = UDim2.fromOffset(px(8), px(110)),
				SizePx = px(11),
				Color = T.TextMuted,
				Wrap = true,
				Z = 34,
			})

			local btnText = "Teleport"
			local canGo = unlocked
			local disabled = not unlocked
			if not unlocked then
				btnText = canUnlock and ("Need power " .. Format.Num(meta.unlockPower)) or ("Power " .. Format.Num(meta.unlockPower))
			elseif here then
				btnText = "You are here"
				disabled = true
			end

			UIKit.Button({
				Parent = card,
				Text = btnText,
				Size = UDim2.new(1, -px(16), 0, px(34)),
				Position = UDim2.new(0, px(8), 1, -px(42)),
				Primary = canGo and not here,
				Disabled = disabled,
				Color = disabled and T.Disabled or nil,
				Color2 = disabled and (T.Colors and T.Colors.DisabledDeep) or nil,
				SizePx = px(12),
				Z = 35,
				OnClick = function()
					if unlocked and not here then
						Net.SetLocation(meta.id)
					end
				end,
			})
		end
	end

	---------------------------------------------------------------- Dungeons
	local function refreshDungeons()
		local body = bodies.dungeons
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local tiers = {
			{ id = "easy", name = "Easy", color = T.Success },
			{ id = "medium", name = "Medium", color = T.Gold },
			{ id = "hard", name = "Hard", color = T.Danger },
		}
		local btnW = px(112)
		for i, tier in ipairs(tiers) do
			local stage = (profile.dungeonStage and profile.dungeonStage[tier.id]) or 0
			local c = surfaceCard(body, 86, i, tier.color)
			UIKit.Label({
				Parent = c,
				Text = tier.name,
				Size = UDim2.new(1, -btnW - 12, 0, px(24)),
				SizePx = px(18),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = "Stage " .. tostring(stage),
				Size = UDim2.new(1, -btnW - 12, 0, px(18)),
				Position = UDim2.fromOffset(0, px(34)),
				SizePx = px(14),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Enter",
				Size = UDim2.fromOffset(btnW, px(42)),
				Position = UDim2.new(1, -btnW, 0.5, -px(21)),
				Color = tier.color,
				Color2 = Color3.fromRGB(80, 30, 40),
				Primary = true,
				SizePx = px(15),
				Z = 34,
				OnClick = function()
					Net.StartDungeon(tier.id)
				end,
			})
		end
	end

	---------------------------------------------------------------- Cases + odds (1 sample per rarity, scroll)
	local function weightOdds(weights: { [string]: number }): { { rarity: string, pct: number } }
		local total = 0
		for _, w in pairs(weights) do
			total += w
		end
		if total <= 0 then
			total = 1
		end
		local out = {}
		for _, r in ipairs(Rarity.Order) do
			local w = weights[r]
			if w and w > 0 then
				table.insert(out, { rarity = r, pct = (w / total) * 100 })
			end
		end
		return out
	end

	local function firstOfRarity(kind: string, rarity: string, loc: number): string
		if kind == "pet" then
			for _, def in PetConfig.Pets do
				if def.rarity == rarity and (def.location == loc or loc == 0) then
					return def.name
				end
			end
			for _, def in PetConfig.Pets do
				if def.rarity == rarity then
					return def.name
				end
			end
		else
			for _, def in AuraConfig.Auras do
				if def.rarity == rarity then
					return def.name
				end
			end
		end
		return rarity
	end

	local function addOddsSection(parent: Instance, title: string, kind: string, weights: any, loc: number, order: number)
		sectionLabel(parent, title, order)
		local odds = weightOdds(weights)
		local wrap = Instance.new("Frame")
		wrap.BackgroundTransparency = 1
		wrap.Size = UDim2.new(1, 0, 0, px(100))
		wrap.LayoutOrder = order + 1
		wrap.ZIndex = 32
		wrap.Parent = parent
		local g = Instance.new("UIGridLayout")
		g.CellSize = UDim2.fromOffset(px(92), px(88))
		g.CellPadding = UDim2.fromOffset(px(8), px(8))
		g.SortOrder = Enum.SortOrder.LayoutOrder
		g.FillDirectionMaxCells = 6
		g.Parent = wrap

		for i, o in ipairs(odds) do
			local col = Rarity.Of(o.rarity)
			local cell = Instance.new("Frame")
			cell.BackgroundColor3 = Color3.new(1, 1, 1)
			cell.BorderSizePixel = 0
			cell.LayoutOrder = i
			cell.ZIndex = 33
			cell.Parent = wrap
			UIKit.Corner(cell, T.R.sm)
			UIKit.Stroke(cell, col, 1.5, 0.2)
			UIKit.Gradient(cell, T.Surface3, T.Surface2, 110)
			UIKit.Label({
				Parent = cell,
				Text = kind == "pet" and "🐾" or "✨",
				Size = UDim2.new(1, 0, 0, px(28)),
				Position = UDim2.fromOffset(0, px(6)),
				SizePx = px(20),
				X = Enum.TextXAlignment.Center,
				Z = 34,
			})
			UIKit.Label({
				Parent = cell,
				Text = firstOfRarity(kind, o.rarity, loc):sub(1, 10),
				Size = UDim2.new(1, -4, 0, px(22)),
				Position = UDim2.fromOffset(2, px(34)),
				SizePx = px(10),
				Color = T.TextSoft,
				X = Enum.TextXAlignment.Center,
				Wrap = true,
				Z = 34,
			})
			UIKit.Label({
				Parent = cell,
				Text = string.format("%.2f%%", o.pct),
				Size = UDim2.new(1, 0, 0, px(18)),
				Position = UDim2.fromOffset(0, px(62)),
				SizePx = px(12),
				Font = T.Font.Title,
				Color = col,
				X = Enum.TextXAlignment.Center,
				Z = 34,
			})
		end
	end

	local function refreshCases()
		local body = bodies.cases
		UIKit.Clear(body)
		UIKit.List(body, px(10), false)
		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0
		local petKeys = (stats and stats.petKeys) or (profile and profile.petKeys) or 0
		local auraKeys = (stats and stats.auraKeys) or (profile and profile.auraKeys) or 0
		local loc = (profile and profile.currentLocation) or 1
		local petKeyCost = CaseConfig.PET_KEY_COST or 1
		local auraKeyCost = CaseConfig.AURA_KEY_COST or 1

		local head = surfaceCard(body, 48, 1, T.Stroke)
		UIKit.Label({
			Parent = head,
			Text = string.format(
				"Keys  🐾 %d   ✨ %d   ·   🪙 %s   ·   loc %d",
				petKeys,
				auraKeys,
				Format.Num(coins),
				loc
			),
			Size = UDim2.new(1, 0, 1, 0),
			SizePx = px(15),
			Color = T.TextSoft,
			Z = 33,
		})

		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(60)))
		scroll.LayoutOrder = 2

		-- Pet case
		do
			local can = petKeys >= petKeyCost
			local costTxt = string.format("%d key", petKeyCost)
			local c = surfaceCard(scroll, 110, 1, T.Success)
			UIKit.Label({
				Parent = c,
				Text = "🐾  Pet Case",
				Size = UDim2.new(1, 0, 0, px(24)),
				SizePx = px(17),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("Keys: %d  ·  pet for current location", petKeys),
				Size = UDim2.new(1, 0, 0, px(20)),
				Position = UDim2.fromOffset(0, px(28)),
				SizePx = px(12),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = can and ("Open · " .. costTxt) or ("Need " .. costTxt),
				Size = UDim2.new(1, 0, 0, px(38)),
				Position = UDim2.new(0, 0, 1, -px(4)),
				Anchor = Vector2.new(0, 1),
				Primary = can,
				Disabled = not can,
				SizePx = px(14),
				Z = 34,
				OnClick = function()
					if can then
						openModal("case", { kind = "pet" })
					end
				end,
			})
		end
		addOddsSection(scroll, "POSSIBLE REWARDS · PETS", "pet", PetConfig.CaseWeights, loc, 10)

		-- Aura case
		do
			local can = auraKeys >= auraKeyCost
			local costTxt = string.format("%d key", auraKeyCost)
			local c = surfaceCard(scroll, 110, 20, Color3.fromRGB(140, 90, 210))
			UIKit.Label({
				Parent = c,
				Text = "✨  Aura Case",
				Size = UDim2.new(1, 0, 0, px(24)),
				SizePx = px(17),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("Keys: %d  ·  random aura", auraKeys),
				Size = UDim2.new(1, 0, 0, px(20)),
				Position = UDim2.fromOffset(0, px(28)),
				SizePx = px(12),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = can and ("Open · " .. costTxt) or ("Need " .. costTxt),
				Size = UDim2.new(1, 0, 0, px(38)),
				Position = UDim2.new(0, 0, 1, -px(4)),
				Anchor = Vector2.new(0, 1),
				Primary = can,
				Disabled = not can,
				SizePx = px(14),
				Z = 34,
				OnClick = function()
					if can then
						openModal("case", { kind = "aura" })
					end
				end,
			})
		end
		addOddsSection(scroll, "POSSIBLE REWARDS · AURAS", "aura", AuraConfig.Weights, loc, 30)
	end

	---------------------------------------------------------------- Donate shop (UI stubs only)
	local function refreshShop()
		local body = bodies.shop
		UIKit.Clear(body)
		UIKit.List(body, px(10), false)

		local tabs = { "Packs", "Boosts", "Misc", "Game currency" }
		local tabRow = Instance.new("Frame")
		tabRow.BackgroundTransparency = 1
		tabRow.Size = UDim2.new(1, 0, 0, px(40))
		tabRow.LayoutOrder = 1
		tabRow.ZIndex = 32
		tabRow.Parent = body
		UIKit.List(tabRow, px(8), true)

		local activeTab = (store :: any)._shopTab or "Boosts"
		for i, name in ipairs(tabs) do
			local on = name == activeTab
			UIKit.Button({
				Parent = tabRow,
				Text = name,
				Size = UDim2.fromOffset(px(120), px(34)),
				SizePx = px(12),
				Primary = on,
				Color = on and nil or T.Surface3,
				Color2 = on and nil or T.Surface2,
				Order = i,
				OnClick = function()
					(store :: any)._shopTab = name
					refreshShop()
				end,
			})
		end

		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(52)))
		scroll.LayoutOrder = 2

		-- Luau: Cyrillic keys must be quoted ["..."], not bare identifiers
		local stubs = {
			["Packs"] = {
				{ name = "Starter pack", price = "99 R$", desc = "Coins + keys (stub)" },
				{ name = "Warrior pack", price = "199 R$", desc = "Power x2 1h (stub)" },
				{ name = "VIP pack", price = "499 R$", desc = "Cosmetics + bonuses (stub)" },
			},
			["Boosts"] = {
				{ name = "Local power boost x2", price = "149 R$", desc = "30 min · soon" },
				{ name = "Global power boost x1.5", price = "199 R$", desc = "30 min · soon" },
				{ name = "Local damage boost x2", price = "149 R$", desc = "30 min · soon" },
				{ name = "Global damage boost x1.5", price = "199 R$", desc = "30 min · soon" },
				{ name = "Local coin boost x1.5", price = "149 R$", desc = "30 min · soon" },
				{ name = "Global coin boost x1.5", price = "199 R$", desc = "30 min · soon" },
				{ name = "Local luck boost x1.25", price = "149 R$", desc = "30 min · soon" },
				{ name = "Global luck boost x1.25", price = "199 R$", desc = "30 min · soon" },
			},
			["Misc"] = {
				{ name = "Sword skins", price = "--", desc = "Soon" },
				{ name = "Emotes", price = "--", desc = "Soon" },
				{ name = "Name frames", price = "--", desc = "Soon" },
			},
			["Game currency"] = {
				{ name = "5,000 coins", price = "49 R$", desc = "Stub" },
				{ name = "25,000 coins", price = "149 R$", desc = "Stub" },
				{ name = "100,000 coins", price = "399 R$", desc = "Stub" },
			},
		}

		local list = stubs[activeTab] or stubs["Boosts"]
		for i, item in ipairs(list) do
			local c = surfaceCard(scroll, 96, i, T.Stroke)
			UIKit.Label({
				Parent = c,
				Text = "🧪  " .. item.name,
				Size = UDim2.new(1, -px(100), 0, px(24)),
				SizePx = px(15),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = item.desc,
				Size = UDim2.new(1, -px(100), 0, px(20)),
				Position = UDim2.fromOffset(0, px(28)),
				SizePx = px(12),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = item.price,
				Size = UDim2.new(1, -px(100), 0, px(18)),
				Position = UDim2.fromOffset(0, px(50)),
				SizePx = px(13),
				Color = T.Accent,
				Font = T.Font.Title,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Soon",
				Size = UDim2.fromOffset(px(90), px(36)),
				Position = UDim2.new(1, -px(90), 0.5, -px(18)),
				Primary = true,
				SizePx = px(13),
				Z = 34,
				OnClick = function()
					openModal("stub", { title = item.name, text = "Purchase not wired yet.\nSoon: " .. item.price })
				end,
			})
		end
	end

	local refreshers = {
		character = refreshCharacter,
		weapons = refreshWeapons,
		pets = refreshPets,
		auras = refreshAuras,
		cases = refreshCases,
		relics = refreshRelics,
		quests = refreshQuests,
		locations = refreshLocations,
		dungeons = refreshDungeons,
		shop = refreshShop,
	}

	local api = {}
	function api.RefreshAll()
		local panel = store:PeekPanel()
		if panel and panel ~= "none" and refreshers[panel] then
			showOnly(panel)
			refreshers[panel]()
		else
			showOnly("")
		end
	end
	return api
end

return Windows
