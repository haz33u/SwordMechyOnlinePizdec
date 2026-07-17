--!strict
--[[
	WEAPON CATALOG + DROP TEMPLATE (all locations)

	Rarity ladder (Cristalix-like + our LIMITED):
	  Common → Uncommon → Rare → Epic → Legendary → Mythic → Secret → Limited

	Limited = special tier (events / seasons / cosmetics+VFX). NEVER normal mob drop.
	Secret  = lottery from elite/boss (tiny weights, worse on later locs).

	Progression philosophy:
	  Loc1 = easy onboarding (generous drops, small mults)
	  Loc2+ = each step longer: lower dropChanceMult, lower highRarityMult
	  Sword power matches ITS location — LocN Common ≈ mid Loc(N-1) gear
	  Competition flex = Mythic / Secret / Limited, not trash spam

	powerMult is RECONSTRUCTED skeleton (not Cristalix HUD dump).
	Tune via LOCATION_BASE + RARITY_REL and drop tables — not ad-hoc per sword.
]]

export type WeaponDef = {
	id: string,
	name: string,
	rarity: string,
	powerMult: number,
	location: number,
	sellPrice: number,
	iconKey: string?, -- stable key for NN icons later (default = id)
	vfxProfile: string?, -- client FX profile (Limited / Secret)
	dropDisabled: boolean?, -- true = never rolls from mobs
	description: string?,
}

export type DropWeightTable = { [string]: number }

export type LocationProgression = {
	dropChanceMult: number, -- overall weapon drop rate
	highRarityMult: number, -- Epic+ weight scale (competition grind)
	timeHint: string,
}

local WeaponConfig = {
	--[[
		Order used by UI / sort / "better than".
		Limited sits above Secret for flex; power may be hand-tuned.
	]]
	RarityOrder = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Secret",
		"Limited",
	},

	-- Rarities that receive highRarityMult on later locations
	HighRarities = {
		Epic = true,
		Legendary = true,
		Mythic = true,
		Secret = true,
	},

	--[[
		Base Common midpoint ≈ LOCATION_BASE[loc]
		Actual sword mult = LOCATION_BASE * RARITY_REL[rarity][variant]
		(stored already expanded in Weapons table for clarity / tuning)
	]]
	LOCATION_BASE = {
		[1] = 1.10,
		[2] = 4.40,
		[3] = 19.0,
		[4] = 95.0,
		-- Loc5+ template: base ≈ prev * (4.2 + 0.3*(n-1))
	},

	--[[
		Relative mult within a location (two variants A/B per tier when possible).
		Secret/Limited are the chase pieces.
	]]
	RARITY_REL = {
		Common = { 0.95, 1.08 },
		Uncommon = { 1.30, 1.48 },
		Rare = { 1.90, 2.25 },
		Epic = { 3.15, 3.85 },
		Legendary = { 5.40, 6.70 },
		Mythic = { 9.80, 12.20 },
		Secret = { 17.5, 21.5 },
		Limited = { 28.0 }, -- single flagship per loc phase
	},

	--[[
		How hard / long each location feels for sword progression.
		Loc1 generous; later locs squeeze high rarities so players push longer.
	]]
	LocationProgression = {
		[1] = { dropChanceMult = 1.00, highRarityMult = 1.00, timeHint = "easy — 15–45 min to solid Rare/Epic" },
		[2] = { dropChanceMult = 0.82, highRarityMult = 0.62, timeHint = "medium — longer grind for Legend+" },
		[3] = { dropChanceMult = 0.68, highRarityMult = 0.40, timeHint = "long — Mythic is a chase" },
		[4] = { dropChanceMult = 0.55, highRarityMult = 0.26, timeHint = "very long — Secret is flex" },
	} :: { [number]: LocationProgression },

	--[[
		Base drop chance BEFORE luck / location mult.
		Final: chance = base * loc.dropChanceMult * (1 + luck)
	]]
	TierDropChance = {
		trash = 0.045,
		normal = 0.075,
		elite = 0.13,
		boss = 0.48,
		debug = 0,
	},

	--[[
		Relative weights when a drop happens (re-normalized after highRarityMult).
		Limited is intentionally absent — never normal loot.
	]]
	TierRarityWeights = {
		trash = {
			Common = 74,
			Uncommon = 22,
			Rare = 4,
		},
		normal = {
			Common = 32,
			Uncommon = 34,
			Rare = 24,
			Epic = 8.5,
			Legendary = 1.5,
		},
		elite = {
			Uncommon = 18,
			Rare = 36,
			Epic = 28,
			Legendary = 13,
			Mythic = 4,
			Secret = 1,
		},
		boss = {
			Rare = 18,
			Epic = 30,
			Legendary = 32,
			Mythic = 14,
			Secret = 6,
		},
	} :: { [string]: DropWeightTable },

	Weapons = {} :: { [string]: WeaponDef },

	STARTER_WEAPON = "W1_C1",
}

----------------------------------------------------------------------
-- Catalog builder (keeps numbers consistent with LOCATION_BASE * REL)
----------------------------------------------------------------------

local function sellOf(powerMult: number, location: number): number
	return math.max(5, math.floor(powerMult * 45 * (1 + (location - 1) * 0.35)))
end

local function multOf(location: number, rarity: string, variant: number): number
	local base = WeaponConfig.LOCATION_BASE[location]
	local rels = WeaponConfig.RARITY_REL[rarity]
	if not base or not rels then
		return 1
	end
	local rel = rels[variant] or rels[1]
	-- 2 decimals for UI cleanliness on small, 0–1 on huge
	local m = base * rel
	if m < 20 then
		return math.floor(m * 100 + 0.5) / 100
	elseif m < 200 then
		return math.floor(m * 10 + 0.5) / 10
	else
		return math.floor(m + 0.5)
	end
end

local function add(
	id: string,
	name: string,
	rarity: string,
	location: number,
	variant: number,
	opts: { dropDisabled: boolean?, vfxProfile: string?, description: string? }?
)
	local power = multOf(location, rarity, variant)
	local def: WeaponDef = {
		id = id,
		name = name,
		rarity = rarity,
		powerMult = power,
		location = location,
		sellPrice = sellOf(power, location),
		iconKey = id,
		vfxProfile = opts and opts.vfxProfile or nil,
		dropDisabled = opts and opts.dropDisabled or false,
		description = opts and opts.description or nil,
	}
	-- Secret gets subtle vfx tag by default; Limited always has flashy profile
	if rarity == "Secret" and not def.vfxProfile then
		def.vfxProfile = "secret_glow"
	end
	if rarity == "Limited" then
		def.dropDisabled = true
		def.vfxProfile = def.vfxProfile or "limited_showcase"
	end
	WeaponConfig.Weapons[id] = def
end

----------------------------------------------------------------------
-- LOC 1 — Тёмный лес (easy onboarding)
----------------------------------------------------------------------
add("W1_C1", "Ржавый клинок", "Common", 1, 1)
add("W1_C2", "Дубовый меч", "Common", 1, 2)
add("W1_U1", "Клинок разбойника", "Uncommon", 1, 1)
add("W1_U2", "Серебряный тесак", "Uncommon", 1, 2)
add("W1_R1", "Меч теней", "Rare", 1, 1)
add("W1_R2", "Клык волка", "Rare", 1, 2)
add("W1_E1", "Клинок Хранителя", "Epic", 1, 1)
add("W1_E2", "Изумрудный страж", "Epic", 1, 2)
add("W1_L1", "Перворождённый", "Legendary", 1, 1)
add("W1_L2", "Сердце рощи", "Legendary", 1, 2)
add("W1_M1", "Тень Прародителя", "Mythic", 1, 1)
add("W1_M2", "Клык Бездны", "Mythic", 1, 2)
add("W1_S1", "Эхо Древнего Леса", "Secret", 1, 1)
add("W1_S2", "Клинок Забытого Короля", "Secret", 1, 2)
add("W1_X1", "Арк Лесного Рассвета", "Limited", 1, 1, {
	description = "LIMITED — сезонный/ивент. Красивые VFX, не с мобов.",
	vfxProfile = "limited_forest_dawn",
})

----------------------------------------------------------------------
-- LOC 2 — Пиратский берег
----------------------------------------------------------------------
add("W2_C1", "Абордажная сабля", "Common", 2, 1)
add("W2_C2", "Нож трюма", "Common", 2, 2)
add("W2_U1", "Корсарский клинок", "Uncommon", 2, 1)
add("W2_U2", "Крюк матроса", "Uncommon", 2, 2)
add("W2_R1", "Акула-резак", "Rare", 2, 1)
add("W2_R2", "Сабля шторма", "Rare", 2, 2)
add("W2_E1", "Сабля адмирала", "Epic", 2, 1)
add("W2_E2", "Клинок чёрной бухты", "Epic", 2, 2)
add("W2_L1", "Чёрный флаг", "Legendary", 2, 1)
add("W2_L2", "Гнев Нептуна", "Legendary", 2, 2)
add("W2_M1", "Кракен-бич", "Mythic", 2, 1)
add("W2_M2", "Приливный палач", "Mythic", 2, 2)
add("W2_S1", "Сердце Маэлстрома", "Secret", 2, 1)
add("W2_S2", "Клинок Потерянного Флота", "Secret", 2, 2)
add("W2_X1", "Флагман Заката", "Limited", 2, 1, {
	description = "LIMITED — пиратский showcase VFX.",
	vfxProfile = "limited_pirate_sunset",
})

----------------------------------------------------------------------
-- LOC 3 — Земли шиноби
----------------------------------------------------------------------
add("W3_C1", "Учебный вакидзаси", "Common", 3, 1)
add("W3_C2", "Бамбуковый клинок", "Common", 3, 2)
add("W3_U1", "Катана ученика", "Uncommon", 3, 1)
add("W3_U2", "Танто стража", "Uncommon", 3, 2)
add("W3_R1", "Катана тени", "Rare", 3, 1)
add("W3_R2", "Лунный разрез", "Rare", 3, 2)
add("W3_E1", "Клинок клана", "Epic", 3, 1)
add("W3_E2", "Шиноби-но-яри", "Epic", 3, 2)
add("W3_L1", "Драконья катана", "Legendary", 3, 1)
add("W3_L2", "Печать бури", "Legendary", 3, 2)
add("W3_M1", "Клинок тысячи теней", "Mythic", 3, 1)
add("W3_M2", "Храм-разрушитель", "Mythic", 3, 2)
add("W3_S1", "Вечная Цукуёми", "Secret", 3, 1)
add("W3_S2", "Меч Первого Шиноби", "Secret", 3, 2)
add("W3_X1", "Сакура Вечности", "Limited", 3, 1, {
	description = "LIMITED — сакура-партиклы, не с мобов.",
	vfxProfile = "limited_sakura_eternity",
})

----------------------------------------------------------------------
-- LOC 4 — Полярная тундра
----------------------------------------------------------------------
add("W4_C1", "Ледяной тесак", "Common", 4, 1)
add("W4_C2", "Костяной нож", "Common", 4, 2)
add("W4_U1", "Морозный палаш", "Uncommon", 4, 1)
add("W4_U2", "Клык полярного волка", "Uncommon", 4, 2)
add("W4_R1", "Северное копьё-меч", "Rare", 4, 1)
add("W4_R2", "Клинок вьюги", "Rare", 4, 2)
add("W4_E1", "Ледник-разрушитель", "Epic", 4, 1)
add("W4_E2", "Руна вечной зимы", "Epic", 4, 2)
add("W4_L1", "Корона Полярной Ночи", "Legendary", 4, 1)
add("W4_L2", "Молот Айсберга", "Legendary", 4, 2)
add("W4_M1", "Сердце Вечной Мерзлоты", "Mythic", 4, 1)
add("W4_M2", "Клык Белого Ужаса", "Mythic", 4, 2)
add("W4_S1", "Шёпот Полярной Звезды", "Secret", 4, 1)
add("W4_S2", "Клинок Конца Зимы", "Secret", 4, 2)
add("W4_X1", "Аврора Абсолюта", "Limited", 4, 1, {
	description = "LIMITED — aurora VFX, флекс сезона.",
	vfxProfile = "limited_aurora_absolute",
})

----------------------------------------------------------------------
-- API
----------------------------------------------------------------------

function WeaponConfig.Get(id: string): WeaponDef?
	return WeaponConfig.Weapons[id]
end

function WeaponConfig.RarityIndex(rarity: string): number
	for i, r in WeaponConfig.RarityOrder do
		if r == rarity then
			return i
		end
	end
	return 1
end

function WeaponConfig.GetByLocation(locationId: number, includeLimited: boolean?): { WeaponDef }
	local list = {}
	for _, def in WeaponConfig.Weapons do
		if def.location == locationId then
			local isLimited = def.rarity == "Limited"
			if includeLimited or not isLimited then
				table.insert(list, def)
			end
		end
	end
	table.sort(list, function(a, b)
		local ra = WeaponConfig.RarityIndex(a.rarity)
		local rb = WeaponConfig.RarityIndex(b.rarity)
		if ra ~= rb then
			return ra < rb
		end
		return a.powerMult < b.powerMult
	end)
	return list
end

function WeaponConfig.GetDropCandidates(locationId: number, rarity: string): { WeaponDef }
	local list = {}
	for _, def in WeaponConfig.Weapons do
		if def.location == locationId and def.rarity == rarity and not def.dropDisabled then
			table.insert(list, def)
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

function WeaponConfig.GetLocationProgression(locationId: number): LocationProgression
	local p = WeaponConfig.LocationProgression[locationId]
	if p then
		return p
	end
	-- Loc5+ template: each step harder
	local steps = math.max(0, locationId - 4)
	return {
		dropChanceMult = math.max(0.35, 0.55 * (0.9 ^ steps)),
		highRarityMult = math.max(0.12, 0.26 * (0.85 ^ steps)),
		timeHint = "extended — use formula for Loc5+",
	}
end

--- Effective rarity weights for a mob tier on a location (after highRarity squeeze).
function WeaponConfig.GetEffectiveWeights(tier: string, locationId: number): DropWeightTable
	local base = WeaponConfig.TierRarityWeights[tier]
	if not base then
		return { Common = 1 }
	end
	local prog = WeaponConfig.GetLocationProgression(locationId)
	local out: DropWeightTable = {}
	for rarity, w in base do
		local weight = w
		if WeaponConfig.HighRarities[rarity] then
			weight *= prog.highRarityMult
		end
		if weight > 0 then
			out[rarity] = weight
		end
	end
	return out
end

function WeaponConfig.GetBaseDropChance(tier: string, locationId: number): number
	local base = WeaponConfig.TierDropChance[tier] or 0
	local prog = WeaponConfig.GetLocationProgression(locationId)
	return base * prog.dropChanceMult
end

function WeaponConfig.RollRarity(tier: string, locationId: number): string?
	local weights = WeaponConfig.GetEffectiveWeights(tier, locationId)
	local total = 0
	for _, w in weights do
		total += w
	end
	if total <= 0 then
		return nil
	end
	local r = math.random() * total
	local acc = 0
	-- stable order by RarityOrder
	for _, rarity in WeaponConfig.RarityOrder do
		local w = weights[rarity]
		if w then
			acc += w
			if r <= acc then
				return rarity
			end
		end
	end
	return "Common"
end

--- Public catalog for UI / Studio (icons, names, mults — no drop secrets required)
function WeaponConfig.GetPublicCatalog(): { any }
	local out = {}
	for _, def in WeaponConfig.Weapons do
		table.insert(out, {
			id = def.id,
			name = def.name,
			rarity = def.rarity,
			powerMult = def.powerMult,
			location = def.location,
			sellPrice = def.sellPrice,
			iconKey = def.iconKey or def.id,
			vfxProfile = def.vfxProfile,
			dropDisabled = def.dropDisabled == true,
			description = def.description,
		})
	end
	table.sort(out, function(a, b)
		if a.location ~= b.location then
			return a.location < b.location
		end
		local ra = WeaponConfig.RarityIndex(a.rarity)
		local rb = WeaponConfig.RarityIndex(b.rarity)
		if ra ~= rb then
			return ra < rb
		end
		return a.powerMult < b.powerMult
	end)
	return out
end

return WeaponConfig
