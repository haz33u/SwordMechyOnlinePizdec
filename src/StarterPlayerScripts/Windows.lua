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
local GamePassConfig = require(Shared.Config.GamePassConfig)
local Inventory = require(script.Parent.Inventory)

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
		weapons = "Inventory", -- INVETAR shell (E key)
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

	-- Inventory uses fixed design scale (Make ~920 panel); hide outer Window chrome
	-- so INVETAR shell provides its own header/close (no double title bar).
	do
		local invRoot = frames.weapons
		local invHeader = invRoot:FindFirstChild("Header")
		if invHeader and invHeader:IsA("GuiObject") then
			invHeader.Visible = false
		end
		local invBody = bodies.weapons
		invBody.Size = UDim2.new(1, 0, 1, 0)
		invBody.Position = UDim2.fromOffset(0, 0)
		invRoot.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
		-- drop outer gradient/stroke feel for Make flat panel
		local stroke = invRoot:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Color3.fromRGB(62, 62, 62)
			stroke.Thickness = 2
			stroke.Transparency = 0.1
		end
		local sc = invRoot:FindFirstChildOfClass("UISizeConstraint")
		if sc then
			-- Responsive: fill most of the screen on any resolution
			sc.MinSize = Vector2.new(720, 480)
			sc.MaxSize = Vector2.new(1920, 1200)
		end
	end

	Layout.Bind(function(m)
		local ww = math.clamp((m.windowW or 0.5) + 0.10, 0.56, 0.68)
		local wh = math.clamp((m.windowH or 0.62) + 0.10, 0.66, 0.80)
		for id, root in frames do
			if id == "weapons" then
				-- Near-fullscreen inventory, same relative size on every resolution
				root.Size = UDim2.fromScale(0.94, 0.93)
				root.Position = UDim2.fromScale(0.5, 0.5)
				root.AnchorPoint = Vector2.new(0.5, 0.5)
			else
				root.Size = UDim2.fromScale(ww, wh)
			end
		end
	end)

	-- Unified inventory (Figma Make INVETAR) on weapons body
	local invApi = Inventory.Bind(bodies.weapons, frames.weapons, store, openModal, function()
		store:ClosePanel()
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
				local unlocked, lockReason = UpgradeConfig.IsUnlocked(profile, upId)
				local canBuy = unlocked and lvl < def.maxLevel and coins >= cost
				local maxed = lvl >= def.maxLevel
				local icon = (T.UpgradeIcon and T.UpgradeIcon[upId]) or "◆"
				local col = (T.UpgradeColor and T.UpgradeColor[upId]) or T.Accent

				-- effect preview text
				local effectLine = ""
				if not unlocked then
					effectLine = lockReason or "Locked"
				elseif def.effectType == "mult_add" then
					local per = math.floor((def.effectPerLevel or 0) * 100 + 0.5)
					local total = per * lvl
					effectLine = if lvl > 0
						then string.format("+%d%% total (+%d%%/lv)", total, per)
						else string.format("+%d%% per level", per)
				elseif def.statKey == "bagSlots" then
					local cap = UpgradeConfig.GetBagCap(profile)
					effectLine = string.format("%d / bag (+1 each)", cap)
				elseif def.statKey == "critChance" or def.statKey == "multiCritChance" then
					local per = math.floor((def.effectPerLevel or 0) * 100 + 0.5)
					effectLine = string.format("+%d%% (%d%% total)", per, per * lvl)
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
					Text = if not unlocked
						then "LOCKED"
						elseif maxed
						then "MAX"
						else ("Cost  " .. Format.Num(cost) .. " 🪙"),
					Size = UDim2.new(1, -12, 0, px(18)),
					Position = UDim2.fromOffset(6, px(172)),
					SizePx = px(13),
					Color = (not unlocked or maxed) and T.TextMuted or T.Gold,
					Font = T.Font.Title,
					Z = 34,
				})

				UIKit.Button({
					Parent = card,
					Text = if not unlocked then "Locked" elseif maxed then "MAX" else "Upgrade",
					Size = UDim2.new(1, -16, 0, px(36)),
					Position = UDim2.new(0, 8, 1, -px(44)),
					Color = maxed and T.Disabled or (canBuy and T.Accent or T.Disabled),
					Color2 = maxed and (T.Colors and T.Colors.DisabledDeep)
						or (canBuy and T.AccentDeep or (T.Colors and T.Colors.DisabledDeep)),
					Primary = canBuy and not maxed,
					Disabled = maxed or not canBuy or not unlocked,
					SizePx = px(14),
					Z = 35,
					OnClick = function()
						if canBuy and not maxed and unlocked then
							Net.BuyUpgrade(upId)
						end
					end,
				})
			end
		end
	end

	---------------------------------------------------------------- Inventory (INVETAR Make) — E key
	-- Merge = MMB on sword slot only (Inventory.lua). No extra buttons / inventory UI redesign.
	local function refreshWeapons()
		local invStore = store :: any
		local t = invStore._invTab
		if type(t) == "string" and t ~= "" then
			invApi:SetTab(t)
			invStore._invTab = nil
		end
		invApi:Refresh()
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
		if not paidOwned and slots < 8 then
			local payRow = surfaceCard(body, 44, 2, T.Stroke)
			UIKit.Label({
				Parent = payRow,
				Text = "Paid: +1 pet slot (max 8)",
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
			local def = PetConfig.Get(p.id)
			local inTeam = false
			for _, uid in ipairs(profile.petTeam or {}) do
				if uid == p.uid then
					inTeam = true
					break
				end
			end
			local sideW = px(150)
			local rarity = (def and def.rarity) or p.rarity or "Common"
			local c = surfaceCard(scroll, 88, i, Rarity.Of(rarity))
			local dispName = (def and def.name) or p.name or p.id
			UIKit.Label({
				Parent = c,
				Text = string.format(
					"%s · %s · lv%s%s",
					tostring(dispName),
					tostring(rarity),
					tostring(p.level or 1),
					inTeam and " · TEAM" or ""
				),
				Size = UDim2.new(1, -sideW - 8, 0, px(22)),
				SizePx = px(15),
				Font = T.Font.Title,
				Color = T.Text,
				Z = 33,
			})
			local pMult = if def then PetConfig.GetPowerMult(def) else 1
			local coinPct = (def and def.coinPct) or 0
			UIKit.Label({
				Parent = c,
				Text = string.format("Power x%.2f   +%d%% coins", pMult, math.floor(coinPct)),
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

		local coins = (stats and stats.coins) or (profile.coins or 0)
		for i, meta in ipairs(WorldConfig.Locations) do
			local unlocked = false
			for _, id in ipairs(profile.locationsUnlocked or { 1 }) do
				if id == meta.id then
					unlocked = true
					break
				end
			end
			local travelCost = meta.travelCostCoins or 0
			local needRb = meta.unlockRebirth or 0
			local myRb = profile.rebirthLevel or 0
			local rbOk = needRb <= 0 or myRb >= needRb
			local canBuy = travelCost > 0 and coins >= travelCost and rbOk
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
			local canClick = false
			local disabled = true
			if here then
				btnText = "You are here"
			elseif unlocked then
				btnText = "Teleport"
				canClick = true
				disabled = false
			elseif not rbOk then
				btnText = "Need R" .. tostring(needRb)
				disabled = true
			elseif travelCost > 0 then
				btnText = "Buy for " .. Format.Num(travelCost)
				canClick = canBuy
				disabled = not canBuy
			else
				btnText = "Teleport"
				canClick = true
				disabled = false
			end

			UIKit.Button({
				Parent = card,
				Text = btnText,
				Size = UDim2.new(1, -px(16), 0, px(34)),
				Position = UDim2.new(0, px(8), 1, -px(42)),
				Primary = canClick and not here,
				Disabled = disabled,
				Color = disabled and T.Disabled or nil,
				Color2 = disabled and (T.Colors and T.Colors.DisabledDeep) or nil,
				SizePx = px(12),
				Z = 35,
				OnClick = function()
					if here then
						return
					end
					-- SetLocation buys (if needed) + teleports
					Net.SetLocation(meta.id)
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
		local petKeyCost = CaseConfig.PET_KEY_COST or 0
		local petCoinCost = CaseConfig.PET_COIN_COST or PetConfig.OPEN_COST or 0
		local auraKeyCost = CaseConfig.AURA_KEY_COST or 1

		local head = surfaceCard(body, 48, 1, T.Stroke)
		UIKit.Label({
			Parent = head,
			Text = string.format(
				"Keys 🐾 %d  ✨ %d  ·  🪙 %s  ·  loc %d",
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

		-- Pet case (Loc1: 500 coins)
		do
			local can = true
			if petKeyCost > 0 and petKeys < petKeyCost then
				can = false
			end
			if petCoinCost > 0 and coins < petCoinCost then
				can = false
			end
			local costParts = {}
			if petKeyCost > 0 then
				table.insert(costParts, string.format("%d key", petKeyCost))
			end
			if petCoinCost > 0 then
				table.insert(costParts, Format.Num(petCoinCost) .. " coins")
			end
			local costTxt = if #costParts > 0 then table.concat(costParts, " + ") else "Free"
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
				Text = string.format("Loc %d pets  ·  cost %s", loc, costTxt),
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
		-- Per-pet odds from dumps (not only rarity weights)
		do
			local oddsCard = surfaceCard(scroll, 0, 5, T.Stroke)
			oddsCard.AutomaticSize = Enum.AutomaticSize.Y
			UIKit.List(oddsCard, px(4), false)
			UIKit.Label({
				Parent = oddsCard,
				Text = "PET ODDS (this location)",
				Size = UDim2.new(1, 0, 0, px(20)),
				SizePx = px(13),
				Font = T.Font.Title,
				Color = T.TextSoft,
				Z = 33,
			})
			local pool = PetConfig.GetPool(loc)
			local sumW = 0
			for _, def in pool do
				sumW += def.caseWeight or PetConfig.CaseWeights[def.rarity] or 1
			end
			for _, def in pool do
				local w = def.caseWeight or PetConfig.CaseWeights[def.rarity] or 1
				local pct = if sumW > 0 then (w / sumW) * 100 else 0
				local mult = PetConfig.GetPowerMult(def)
				UIKit.Label({
					Parent = oddsCard,
					Text = string.format(
						"%.2f%%  %s  [%s]  power x%.2f  +%d%% coins",
						pct,
						def.name,
						def.rarity,
						mult,
						math.floor(def.coinPct or 0)
					),
					Size = UDim2.new(1, 0, 0, px(18)),
					SizePx = px(12),
					Color = Rarity.Of(def.rarity),
					Z = 33,
				})
			end
			if #pool == 0 then
				UIKit.Label({
					Parent = oddsCard,
					Text = "(no pets for this location)",
					Size = UDim2.new(1, 0, 0, px(18)),
					SizePx = px(12),
					Color = T.TextMuted,
					Z = 33,
				})
			end
		end

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

	---------------------------------------------------------------- Donate shop — gamepass ImageButtons
	local function refreshShop()
		local body = bodies.shop
		UIKit.Clear(body)
		UIKit.List(body, px(12), false)
		sectionLabel(body, "GAMEPASSES", 1)
		local scroll = UIKit.Scroll(body, UDim2.new(1, 0, 1, -px(40)))
		scroll.LayoutOrder = 2
		for _, ch in scroll:GetChildren() do
			if ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(px(150), px(180))
		grid.CellPadding = UDim2.fromOffset(px(12), px(12))
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = 4
		grid.Parent = scroll
		UIKit.Pad(scroll, px(6))

		local MarketplaceService = game:GetService("MarketplaceService")
		local profile = store:PeekProfile()
		local unlocks = (profile and profile.unlocks) or {}
		for i, key in ipairs(GamePassConfig.Order) do
			local def = GamePassConfig.Get(key)
			if def then
				local owned = def.feature and unlocks[def.feature] == true
				local card = surfaceCard(scroll, 170, i, owned and T.Success or T.Stroke)
				card.Size = UDim2.fromOffset(px(140), px(168))

				local img = Instance.new("ImageButton")
				img.Name = "Buy"
				img.Size = UDim2.fromOffset(px(100), px(100))
				img.Position = UDim2.new(0.5, 0, 0, px(8))
				img.AnchorPoint = Vector2.new(0.5, 0)
				img.BackgroundColor3 = T.Surface2
				img.BorderSizePixel = 0
				img.Image = GamePassConfig.ThumbUrl(def.gamePassId, 150)
				img.ScaleType = Enum.ScaleType.Fit
				img.AutoButtonColor = not owned
				img.ImageTransparency = owned and 0.2 or 0
				img.ZIndex = 34
				img.Parent = card
				UIKit.Corner(img, T.R.sm)

				UIKit.Label({
					Parent = card,
					Text = def.title,
					Size = UDim2.new(1, -8, 0, px(28)),
					Position = UDim2.fromOffset(4, px(112)),
					SizePx = px(11),
					Color = T.Text,
					X = Enum.TextXAlignment.Center,
					Wrap = true,
					Z = 34,
				})
				local priceLab = UIKit.Label({
					Parent = card,
					Text = owned and "Owned" or "…",
					Size = UDim2.new(1, 0, 0, px(18)),
					Position = UDim2.fromOffset(0, px(142)),
					SizePx = px(12),
					Color = owned and (T.Success or Color3.fromRGB(100, 200, 120)) or T.Gold,
					Font = T.Font.Title,
					X = Enum.TextXAlignment.Center,
					Z = 34,
				})
				if not owned then
					task.spawn(function()
						local ok, info = pcall(function()
							return MarketplaceService:GetProductInfo(def.gamePassId, Enum.InfoType.GamePass)
						end)
						if priceLab.Parent then
							if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
								priceLab.Text = "R$ " .. tostring(info.PriceInRobux)
							else
								priceLab.Text = "R$ —"
							end
						end
					end)
				end
				img.MouseButton1Click:Connect(function()
					if not owned then
						Net.PromptGamePass(def.gamePassId)
					end
				end)
			end
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
