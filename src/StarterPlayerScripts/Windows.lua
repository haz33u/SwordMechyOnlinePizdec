--!strict
--[[ B-windows — clean cards, rarity edge, no emoji spam. ]]

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

local function card(parent: Instance, h: number, order: number, edge: Color3?): Frame
	local f = UIKit.Glass({
		Parent = parent,
		Size = UDim2.new(1, -4, 0, h),
		Radius = T.R.md,
		Z = 32,
	})
	f.LayoutOrder = order
	UIKit.Stroke(f, edge or T.Stroke, edge and 1.4 or 1, edge and 0.35 or T.StrokeA)
	UIKit.Pad(f, 10)
	return f
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
		local root, body = UIKit.Window(folder, title, function()
			store:ClosePanel()
		end)
		root.Name = id
		frames[id] = root
		bodies[id] = body
	end

	Layout.Bind(function(m)
		for _, root in frames do
			root.Size = UDim2.fromScale(m.windowW, m.windowH)
		end
	end)

	local function showOnly(active: string)
		for id, f in frames do
			f.Visible = id == active
		end
	end

	local function refreshCharacter()
		local body = bodies.character
		UIKit.Clear(body)
		UIKit.List(body, 8, false)
		local stats = store:PeekStats()
		local profile = store:PeekProfile()
		if not stats or not profile then
			return
		end

		local ov = card(body, 72, 1, T.Accent)
		UIKit.Label({
			Parent = ov,
			Text = string.format(
				"Сила %s · CPS %.1f · DPS %s\nКрит %s · Удача %s · R%d %s",
				Format.Num(stats.damagePerClick or stats.totalPower),
				stats.cps or 0,
				Format.Num(stats.dps),
				Format.Pct(stats.crit),
				Format.Pct(stats.luck),
				stats.rebirthLevel or 0,
				Format.Mult(stats.rebirthMult)
			),
			Size = UDim2.new(1, 0, 1, 0),
			SizePx = 13,
			Color = T.TextSoft,
			Wrap = true,
			Z = 33,
		})

		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -84))
		scroll.LayoutOrder = 2
		for i, upId in UpgradeConfig.Order do
			local def = UpgradeConfig.Defs[upId]
			if def then
				local lvl = (profile.upgradeLevels and profile.upgradeLevels[upId]) or 0
				local cost = math.floor(def.baseCost * (def.growth ^ lvl) + 0.5)
				local c = card(scroll, 58, i)
				UIKit.Label({
					Parent = c,
					Text = string.format("%s  ·  %d/%d", def.name, lvl, def.maxLevel),
					Size = UDim2.new(1, -110, 0, 18),
					SizePx = 14,
					Font = T.Font.Title,
					Z = 33,
				})
				UIKit.Label({
					Parent = c,
					Text = Format.Num(cost) .. " монет",
					Size = UDim2.new(1, -110, 0, 16),
					Position = UDim2.fromOffset(0, 24),
					Color = T.Accent,
					SizePx = 12,
					Z = 33,
				})
				UIKit.Button({
					Parent = c,
					Text = "Ап",
					Size = UDim2.fromOffset(84, 32),
					Position = UDim2.new(1, -84, 0.5, -16),
					Color = T.AccentDeep,
					Color2 = Color3.fromRGB(70, 50, 16),
					TextColor = T.Accent,
					SizePx = 13,
					Z = 34,
					OnClick = function()
						Net.BuyUpgrade(upId)
					end,
				})
			end
		end
	end

	local function refreshWeapons()
		local body = bodies.weapons
		UIKit.Clear(body)
		UIKit.List(body, 8, false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local head = card(body, 40, 1)
		UIKit.Label({
			Parent = head,
			Text = string.format("Осн. %s  ·  Втор. %s", tostring(profile.equippedMain or "—"):sub(1, 12), tostring(profile.equippedOffhand or "—"):sub(1, 12)),
			Size = UDim2.new(1, 0, 1, 0),
			SizePx = 12,
			Color = T.TextSoft,
			Z = 33,
		})
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -52))
		scroll.LayoutOrder = 2
		for i, w in ipairs(profile.weapons or {}) do
			local def = WeaponConfig.Get(w.id)
			local name = (def and def.name) or w.id
			local rarity = (def and def.rarity) or "Common"
			local mult = (def and def.powerMult) or 1
			local c = card(scroll, 86, i, Rarity.Of(rarity))
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ·  %s  ·  ×%.2f", name, rarity, mult),
				Size = UDim2.new(1, 0, 0, 18),
				Color = Rarity.Of(rarity),
				SizePx = 13,
				Font = T.Font.Title,
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 32)
			row.Position = UDim2.fromOffset(0, 40)
			row.ZIndex = 33
			row.Parent = c
			UIKit.List(row, 6, true)
			UIKit.Button({
				Parent = row,
				Text = "Осн",
				Size = UDim2.fromOffset(58, 28),
				SizePx = 11,
				OnClick = function()
					Net.EquipWeapon(w.uid, "main")
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Втор",
				Size = UDim2.fromOffset(58, 28),
				SizePx = 11,
				OnClick = function()
					Net.EquipWeapon(w.uid, "offhand")
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Чар",
				Size = UDim2.fromOffset(52, 28),
				Color = Color3.fromRGB(70, 50, 100),
				Color2 = Color3.fromRGB(40, 30, 60),
				SizePx = 11,
				OnClick = function()
					Net.EnchantWeapon(w.uid)
					openModal("enchant", w)
				end,
			})
			UIKit.Button({
				Parent = row,
				Text = "Прод",
				Size = UDim2.fromOffset(52, 28),
				Color = Color3.fromRGB(90, 36, 36),
				Color2 = Color3.fromRGB(50, 20, 20),
				SizePx = 11,
				OnClick = function()
					openModal("sell", w)
				end,
			})
		end
	end

	local function refreshPets()
		local body = bodies.pets
		UIKit.Clear(body)
		UIKit.List(body, 8, false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local head = card(body, 44, 1)
		UIKit.Label({
			Parent = head,
			Text = string.format("Команда %d/%d", #(profile.petTeam or {}), profile.petSlots or 1),
			Size = UDim2.new(1, -120, 1, 0),
			SizePx = 13,
			Z = 33,
		})
		UIKit.Button({
			Parent = head,
			Text = "Кейс",
			Size = UDim2.fromOffset(100, 30),
			Position = UDim2.new(1, -100, 0.5, -15),
			Color = T.AccentDeep,
			Color2 = Color3.fromRGB(70, 50, 16),
			TextColor = T.Accent,
			SizePx = 12,
			Z = 34,
			OnClick = function()
				Net.OpenPetCase()
				openModal("case", { kind = "pet" })
			end,
		})
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -56))
		scroll.LayoutOrder = 2
		for i, p in ipairs(profile.pets or {}) do
			local inTeam = false
			for _, uid in ipairs(profile.petTeam or {}) do
				if uid == p.uid then
					inTeam = true
					break
				end
			end
			local c = card(scroll, 64, i, Rarity.Of(p.rarity))
			UIKit.Label({
				Parent = c,
				Text = string.format(
					"%s · %s · lv%s%s",
					tostring(p.name or p.id),
					tostring(p.rarity or "Common"),
					tostring(p.level or 1),
					inTeam and " · IN" or ""
				),
				Size = UDim2.new(1, -140, 0, 18),
				SizePx = 12,
				Font = T.Font.Title,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format(
					"+%s%% сила  +%s%% монеты",
					tostring(math.floor((p.powerPct or 0) * 100)),
					tostring(math.floor((p.coinPct or 0) * 100))
				),
				Size = UDim2.new(1, -140, 0, 16),
				Position = UDim2.fromOffset(0, 28),
				Color = T.TextDim,
				SizePx = 11,
				Z = 33,
			})
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.fromOffset(130, 28)
			row.Position = UDim2.new(1, -130, 0.5, -14)
			row.ZIndex = 34
			row.Parent = c
			UIKit.List(row, 4, true)
			UIKit.Button({
				Parent = row,
				Text = inTeam and "Снять" or "Экип",
				Size = UDim2.fromOffset(62, 28),
				SizePx = 11,
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
				Size = UDim2.fromOffset(52, 28),
				SizePx = 11,
				OnClick = function()
					Net.FeedPet(p.uid)
				end,
			})
		end
		if #(profile.pets or {}) == 0 then
			UIKit.Label({
				Parent = scroll,
				Text = "Пусто — открой кейс.",
				Size = UDim2.new(1, 0, 0, 36),
				Color = T.TextDim,
				SizePx = 13,
			})
		end
	end

	local function refreshAuras()
		local body = bodies.auras
		UIKit.Clear(body)
		UIKit.List(body, 8, false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local head = card(body, 44, 1)
		UIKit.Label({
			Parent = head,
			Text = "Активная: " .. tostring(profile.equippedAura or "нет"),
			Size = UDim2.new(1, -110, 1, 0),
			SizePx = 13,
			Z = 33,
		})
		UIKit.Button({
			Parent = head,
			Text = "Кейс",
			Size = UDim2.fromOffset(100, 30),
			Position = UDim2.new(1, -100, 0.5, -15),
			Color = Color3.fromRGB(70, 50, 110),
			Color2 = Color3.fromRGB(40, 30, 70),
			SizePx = 12,
			Z = 34,
			OnClick = function()
				Net.OpenAuraCase()
				openModal("case", { kind = "aura" })
			end,
		})
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -56))
		scroll.LayoutOrder = 2
		for i, a in ipairs(profile.auras or {}) do
			local c = card(scroll, 56, i, Rarity.Of(a.rarity))
			UIKit.Label({
				Parent = c,
				Text = string.format("%s · %s", tostring(a.name or a.id), tostring(a.rarity or "Common")),
				Size = UDim2.new(1, -90, 0, 18),
				SizePx = 13,
				Font = T.Font.Title,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Экип",
				Size = UDim2.fromOffset(76, 28),
				Position = UDim2.new(1, -76, 0.5, -14),
				SizePx = 12,
				Z = 34,
				OnClick = function()
					Net.EquipAura(a.uid)
				end,
			})
		end
	end

	local function refreshRelics()
		local body = bodies.relics
		UIKit.Clear(body)
		UIKit.List(body, 8, false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		UIKit.Label({
			Parent = body,
			Text = "Только просмотр (remote экипа позже).",
			Size = UDim2.new(1, 0, 0, 28),
			Color = T.TextDim,
			SizePx = 12,
			Order = 1,
		})
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -36))
		scroll.LayoutOrder = 2
		for i, r in ipairs(profile.relics or {}) do
			local c = card(scroll, 48, i)
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ★%s", tostring(r.name or r.id), tostring(r.stars or 1)),
				Size = UDim2.new(1, 0, 1, 0),
				SizePx = 13,
				Z = 33,
			})
		end
		if #(profile.relics or {}) == 0 then
			UIKit.Label({
				Parent = scroll,
				Text = "Пусто — ходи в данжи.",
				Size = UDim2.new(1, 0, 0, 36),
				Color = T.TextDim,
			})
		end
	end

	local function refreshQuests()
		local body = bodies.quests
		UIKit.Clear(body)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, 0))
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
			local c = card(scroll, 78, claimed and (500 + order) or order, done and not claimed and T.Good or nil)
			UIKit.Label({
				Parent = c,
				Text = name,
				Size = UDim2.new(1, claimed and 0 or -90, 0, 16),
				SizePx = 13,
				Font = T.Font.Title,
				Color = claimed and T.TextDim or T.Text,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("%s  ·  %d/%d", desc, progress, amount),
				Size = UDim2.new(1, claimed and 0 or -90, 0, 14),
				Position = UDim2.fromOffset(0, 20),
				SizePx = 11,
				Color = T.TextDim,
				Z = 33,
			})
			local track, fill = UIKit.Bar(c, amount > 0 and progress / amount or 0, done and T.Good or T.Accent, 6)
			track.Position = UDim2.new(0, 0, 1, -10)
			track.Size = UDim2.new(1, claimed and 0 or -90, 0, 6)
			if done and not claimed then
				UIKit.Button({
					Parent = c,
					Text = "Сдать",
					Size = UDim2.fromOffset(78, 30),
					Position = UDim2.new(1, -78, 0.5, -15),
					Color = T.Good,
					Color2 = Color3.fromRGB(30, 100, 60),
					SizePx = 12,
					Z = 34,
					OnClick = function()
						Net.ClaimQuest(id)
					end,
				})
			end
		end
	end

	local function refreshLocations()
		local body = bodies.locations
		UIKit.Clear(body)
		UIKit.List(body, 8, false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local current = profile.currentLocation or 1
		for i, meta in ipairs(WorldConfig.Locations) do
			local unlocked = false
			for _, id in ipairs(profile.locationsUnlocked or { 1 }) do
				if id == meta.id then
					unlocked = true
					break
				end
			end
			local here = current == meta.id
			local c = card(body, 70, i, here and T.Accent or nil)
			UIKit.Label({
				Parent = c,
				Text = meta.name .. (here and "  ·  здесь" or ""),
				Size = UDim2.new(1, -120, 0, 18),
				SizePx = 14,
				Font = T.Font.Title,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = string.format("%s · сила %s", unlocked and "Открыта" or "Закрыта", Format.Num(meta.unlockPower)),
				Size = UDim2.new(1, -120, 0, 14),
				Position = UDim2.fromOffset(0, 28),
				Color = T.TextDim,
				SizePx = 11,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = unlocked and "Идти" or "🔒",
				Size = UDim2.fromOffset(100, 32),
				Position = UDim2.new(1, -100, 0.5, -16),
				Color = unlocked and T.AccentDeep or T.Glass3,
				Color2 = unlocked and Color3.fromRGB(70, 50, 16) or T.Glass2,
				TextColor = unlocked and T.Accent or T.TextDim,
				SizePx = 12,
				Z = 34,
				OnClick = function()
					if unlocked then
						Net.SetLocation(meta.id)
					end
				end,
			})
		end
	end

	local function refreshDungeons()
		local body = bodies.dungeons
		UIKit.Clear(body)
		UIKit.List(body, 10, false)
		local profile = store:PeekProfile()
		if not profile then
			return
		end
		local tiers = {
			{ id = "easy", name = "Лёгкое" },
			{ id = "medium", name = "Среднее" },
			{ id = "hard", name = "Сложное" },
		}
		for i, tier in ipairs(tiers) do
			local stage = (profile.dungeonStage and profile.dungeonStage[tier.id]) or 0
			local c = card(body, 64, i)
			UIKit.Label({
				Parent = c,
				Text = tier.name,
				Size = UDim2.new(1, -110, 0, 18),
				SizePx = 15,
				Font = T.Font.Title,
				Z = 33,
			})
			UIKit.Label({
				Parent = c,
				Text = "Стадия " .. tostring(stage),
				Size = UDim2.new(1, -110, 0, 14),
				Position = UDim2.fromOffset(0, 28),
				Color = T.TextDim,
				SizePx = 12,
				Z = 33,
			})
			UIKit.Button({
				Parent = c,
				Text = "Войти",
				Size = UDim2.fromOffset(96, 34),
				Position = UDim2.new(1, -96, 0.5, -17),
				Color = Color3.fromRGB(90, 36, 40),
				Color2 = Color3.fromRGB(50, 20, 24),
				SizePx = 13,
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
