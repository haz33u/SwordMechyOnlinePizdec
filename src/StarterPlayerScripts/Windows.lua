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
	UIKit.Corner(f, T.R.lg)
	UIKit.Stroke(f, edge or T.Stroke, edge and 1.8 or 1.4, edge and 0.28 or 0.48)
	UIKit.Gradient(f, T.Surface3, T.Surface2, 105)
	UIKit.Pad(f, px(16))
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
		character = "Персонаж",
		weapons = "Оружие",
		pets = "Питомцы",
		auras = "Ауры",
		relics = "Реликвии",
		quests = "Задания",
		locations = "Локации",
		dungeons = "Подземелья",
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

	---------------------------------------------------------------- Character / Upgrades
	local function refreshCharacter()
		local body = bodies.character
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local stats = store:PeekStats()
		local profile = store:PeekProfile()
		if not stats or not profile then
			return
		end

		sectionLabel(body, "ОБЗОР", 1)
		local ov = surfaceCard(body, 88, 2, T.Gold)
		UIKit.Label({
			Parent = ov,
			Text = string.format(
				"Сила %s   CPS %.1f   DPS %s\nКрит %s   Удача %s   R%d %s",
				Format.Num(stats.damagePerClick or stats.totalPower),
				stats.cps or 0,
				Format.Num(stats.dps),
				Format.Pct(stats.crit),
				Format.Pct(stats.luck),
				stats.rebirthLevel or 0,
				Format.Mult(stats.rebirthMult)
			),
			Size = UDim2.new(1, 0, 1, 0),
			SizePx = px(16),
			Color = T.Text,
			Font = T.Font.Body,
			Wrap = true,
			Z = 33,
		})

		sectionLabel(body, "УЛУЧШЕНИЯ", 3)

		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(140)))
		scroll.LayoutOrder = 4

		local coins = stats.coins or 0
		for i, upId in UpgradeConfig.Order do
			local def = UpgradeConfig.Defs[upId]
			if def then
				local lvl = (profile.upgradeLevels and profile.upgradeLevels[upId]) or 0
				local cost = UpgradeConfig.GetCost(upId, lvl + 1)
				local canBuy = lvl < def.maxLevel and coins >= cost
				local maxed = lvl >= def.maxLevel
				local pct = def.maxLevel > 0 and (lvl / def.maxLevel) or 0
				local icon = (T.UpgradeIcon and T.UpgradeIcon[upId]) or "◆"
				local btnW = px(100)

				local c = surfaceCard(scroll, 104, i)
				UIKit.Label({
					Parent = c,
					Text = icon .. "  " .. def.name,
					Size = UDim2.new(1, -btnW - 8, 0, px(22)),
					SizePx = px(17),
					Font = T.Font.Title,
					Color = T.Text,
					Z = 33,
				})
				UIKit.Label({
					Parent = c,
					Text = maxed and "МАКС" or (Format.Num(cost) .. " монет"),
					Size = UDim2.new(1, -btnW - 8, 0, px(18)),
					Position = UDim2.fromOffset(0, px(26)),
					SizePx = px(14),
					Color = maxed and T.TextMuted or T.Gold,
					Z = 33,
				})

				local track = Instance.new("Frame")
				track.BackgroundColor3 = T.Surface
				track.BorderSizePixel = 0
				track.Size = UDim2.new(1, -btnW - 8, 0, px(12))
				track.Position = UDim2.fromOffset(0, px(52))
				track.ZIndex = 33
				track.Parent = c
				UIKit.Corner(track, 99)
				local fill = Instance.new("Frame")
				fill.BackgroundColor3 = T.Gold
				fill.BorderSizePixel = 0
				fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
				fill.Parent = track
				UIKit.Corner(fill, 99)
				UIKit.Label({
					Parent = c,
					Text = string.format("%d / %d", lvl, def.maxLevel),
					Size = UDim2.new(1, -btnW - 8, 0, px(16)),
					Position = UDim2.fromOffset(0, px(68)),
					SizePx = px(13),
					Color = T.TextMuted,
					Z = 33,
				})

				UIKit.Button({
					Parent = c,
					Text = maxed and "MAX" or "Купить",
					Size = UDim2.fromOffset(btnW, px(42)),
					Position = UDim2.new(1, -btnW, 0.5, -px(21)),
					Color = maxed and T.Disabled or (canBuy and T.Success or T.Disabled),
					Color2 = maxed and (T.Colors and T.Colors.DisabledDeep) or (canBuy and (T.Colors and T.Colors.SuccessDeep) or (T.Colors and T.Colors.DisabledDeep)),
					SizePx = px(16),
					Disabled = maxed or not canBuy,
					Z = 34,
					OnClick = function()
						if canBuy and not maxed then
							Net.BuyUpgrade(upId)
						end
					end,
				})
			end
		end
	end

	---------------------------------------------------------------- Weapons
	local function refreshWeapons()
		local body = bodies.weapons
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		sectionLabel(body, "ЭКИП", 1)
		local head = surfaceCard(body, 52, 2, T.Gold)
		UIKit.Label({
			Parent = head,
			Text = string.format(
				"Осн. %s   ·   Втор. %s",
				tostring(profile.equippedMain or "—"):sub(1, 14),
				tostring(profile.equippedOffhand or "—"):sub(1, 14)
			),
			Size = UDim2.new(1, 0, 1, 0),
			SizePx = px(15),
			Color = T.Text,
			Z = 33,
		})
		sectionLabel(body, "ИНВЕНТАРЬ", 3)
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(120)))
		scroll.LayoutOrder = 4
		for i, w in ipairs(profile.weapons or {}) do
			local def = WeaponConfig.Get(w.id)
			local name = (def and def.name) or w.id
			local rarity = (def and def.rarity) or "Common"
			local mult = (def and def.powerMult) or 1
			local c = surfaceCard(scroll, 108, i, Rarity.Of(rarity))
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ·  %s  ·  ×%.2f", name, rarity, mult),
				Size = UDim2.new(1, 0, 0, px(22)),
				Color = Rarity.Of(rarity),
				SizePx = px(16),
				Font = T.Font.Title,
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, px(42))
			row.Position = UDim2.fromOffset(0, px(48))
			row.ZIndex = 33
			row.Parent = c
			UIKit.List(row, px(8), true)
			UIKit.Button({
				Parent = row,
				Text = "Осн",
				Size = UDim2.fromOffset(px(72), px(38)),
				SizePx = px(14),
				OnClick = function()
					Net.EquipWeapon(w.uid, "main")
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Втор",
				Size = UDim2.fromOffset(px(72), px(38)),
				SizePx = px(14),
				OnClick = function()
					Net.EquipWeapon(w.uid, "offhand")
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Чар",
				Size = UDim2.fromOffset(px(64), px(38)),
				Color = Color3.fromRGB(90, 60, 140),
				Color2 = Color3.fromRGB(55, 35, 90),
				SizePx = px(14),
				OnClick = function()
					Net.EnchantWeapon(w.uid)
					openModal("enchant", w)
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Прод",
				Size = UDim2.fromOffset(px(64), px(38)),
				Color = T.Danger,
				Color2 = T.Colors and T.Colors.DangerDeep or Color3.fromRGB(140, 40, 40),
				SizePx = px(14),
				OnClick = function()
					openModal("sell", w)
				end,
			})
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
		UIKit.Label({
			Parent = head,
			Text = string.format("Команда %d / %d", #(profile.petTeam or {}), profile.petSlots or 1),
			Size = UDim2.new(1, -btnW - 12, 1, 0),
			SizePx = px(16),
			Color = T.Text,
			Z = 33,
		})
		UIKit.Button({
			Parent = head,
			Text = "Кейс",
			Size = UDim2.fromOffset(btnW, px(40)),
			Position = UDim2.new(1, -btnW, 0.5, -px(20)),
			Color = T.GoldDeep,
			Color2 = Color3.fromRGB(180, 110, 25),
			Primary = true,
			SizePx = px(15),
			Z = 34,
			OnClick = function()
				Net.OpenPetCase()
				openModal("case", { kind = "pet" })
			end,
		})
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(72)))
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
					inTeam and " · В КОМАНДЕ" or ""
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
					"+%s%% сила   +%s%% монеты",
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
				Text = inTeam and "Снять" or "Экип",
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
				Text = "Пусто — открой кейс.",
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
			Text = "Активная: " .. tostring(profile.equippedAura or "нет"),
			Size = UDim2.new(1, -btnW - 12, 1, 0),
			SizePx = px(16),
			Color = T.Text,
			Z = 33,
		})
		UIKit.Button({
			Parent = head,
			Text = "Кейс",
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
				Text = "Экип",
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
		sectionLabel(body, "ИЗ ДАНЖЕЙ (read-only)", 1)
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
				Text = "Пусто — ходи в данжи.",
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
					Text = "Сдать",
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
					Text = "готово",
					Size = UDim2.fromOffset(px(72), px(32)),
					Color = T.Success,
					SizePx = px(13),
					Order = 2,
				})
			end
		end
	end

	---------------------------------------------------------------- Locations
	local function refreshLocations()
		local body = bodies.locations
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local current = profile.currentLocation or 1
		local btnW = px(112)
		for i, meta in ipairs(WorldConfig.Locations) do
			local unlocked = false
			for _, id in ipairs(profile.locationsUnlocked or { 1 }) do
				if id == meta.id then
					unlocked = true
					break
				end
			end
			local here = current == meta.id
			local c = surfaceCard(body, 88, i, here and T.Gold or nil)
			UIKit.Label({
				Parent = c,
				Text = meta.name .. (here and "  ·  ВЫ ЗДЕСЬ" or ""),
				Size = UDim2.new(1, -btnW - 12, 0, px(24)),
				SizePx = px(17),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("%s · сила %s", unlocked and "Открыта" or "Закрыта", Format.Num(meta.unlockPower)),
				Size = UDim2.new(1, -btnW - 12, 0, px(18)),
				Position = UDim2.fromOffset(0, px(32)),
				SizePx = px(13),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = unlocked and "Идти" or "Закрыто",
				Size = UDim2.fromOffset(btnW, px(42)),
				Position = UDim2.new(1, -btnW, 0.5, -px(21)),
				Color = unlocked and T.Success or T.Disabled,
				Color2 = unlocked and (T.Colors and T.Colors.SuccessDeep) or (T.Colors and T.Colors.DisabledDeep),
				Disabled = not unlocked,
				SizePx = px(14),
				Z = 34,
				OnClick = function()
					if unlocked then
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
			{ id = "easy", name = "Лёгкое", color = T.Success },
			{ id = "medium", name = "Среднее", color = T.Gold },
			{ id = "hard", name = "Сложное", color = T.Danger },
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
				Text = "Стадия " .. tostring(stage),
				Size = UDim2.new(1, -btnW - 12, 0, px(18)),
				Position = UDim2.fromOffset(0, px(34)),
				SizePx = px(14),
				Color = T.TextMuted,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Войти",
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

	local refreshers = {
		character = refreshCharacter,
		weapons = refreshWeapons,
		pets = refreshPets,
		auras = refreshAuras,
		relics = refreshRelics,
		quests = refreshQuests,
		locations = refreshLocations,
		dungeons = refreshDungeons,
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
