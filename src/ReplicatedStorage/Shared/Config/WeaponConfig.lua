--!strict
--[[
	WEAPON CATALOG — Loc1 + Loc2 ONLY, 1:1 from Cristalix dumps.
	Source: docs/ref/cristalix/DUMP_CATALOG.md (player screenshots).

	Сила = absolute powerMult (pure number, not %).
	No filler / Loc3 / Loc4 / Limited skeletons.
]]

export type WeaponDef = {
	id: string,
	name: string,
	rarity: string,
	powerMult: number, -- Cristalix "Сила" at L1
	location: number,
	sellPrice: number,
	iconKey: string?,
	vfxProfile: string?,
	dropDisabled: boolean?,
	description: string?,
}

export type DropWeightTable = { [string]: number }

export type LocationProgression = {
	dropChanceMult: number,
	highRarityMult: number,
	timeHint: string,
}

local WeaponConfig = {
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

	HighRarities = {
		Epic = true,
		Legendary = true,
		Mythic = true,
		Secret = true,
	},

	-- No artificial squeeze — dump tables are authority
	LocationProgression = {
		[1] = { dropChanceMult = 1.00, highRarityMult = 1.00, timeHint = "Loc1 dump" },
		[2] = { dropChanceMult = 1.00, highRarityMult = 1.00, timeHint = "Loc2 dump" },
	} :: { [number]: LocationProgression },

	TierDropChance = {
		simple = 1.0,
		medium = 1.0,
		hard = 1.0,
		elite = 1.0,
		boss = 1.0,
		debug = 0,
		trash = 1.0,
		normal = 1.0,
	},

	--[[
		Loc1 rarity tables from dump inspects.
		No Uncommon in dump weapon list → Uncommon weight folded into Common.
	]]
	TierRarityWeights = {
		simple = {
			Common = 89.997, -- 54.998+34.999 (no Uncommon swords in dump)
			Rare = 8.0,
			Epic = 2.003,
		},
		medium = {
			Common = 56.995, -- 24.998+31.997
			Rare = 21.998,
			Epic = 15.998,
			Legendary = 5.009,
		},
		hard = {
			Common = 45.541, -- 15.84+29.701
			Rare = 33.661,
			Epic = 16.830,
			Legendary = 2.877,
			Mythic = 1.091,
		},
		elite = {
			Common = 36.0, -- 12+24
			Rare = 30.0,
			Epic = 20.0,
			Legendary = 10.0,
			Mythic = 3.9999,
			Secret = 0.0001,
		},
		boss = {
			Rare = 28.0,
			Epic = 35.0,
			Legendary = 25.0,
			Mythic = 10.0,
			Secret = 2.0,
		},
	} :: { [string]: DropWeightTable },

	BossDustMin = 2,
	BossDustMax = 5,
	BossDustAlways = true,

	Weapons = {} :: { [string]: WeaponDef },

	STARTER_WEAPON = "W1_C1",

	MAX_WEAPON_LEVEL = 3,
	-- Double-edged dump: 17 → 34 → 51 = × level
	LEVEL_POWER_MULT = {
		[1] = 1.0,
		[2] = 2.0,
		[3] = 3.0,
	},
	MERGE_COUNT = {
		[1] = 5,
		[2] = 3,
	},
	LEVEL_SELL_MULT = {
		[1] = 1.0,
		[2] = 2.0,
		[3] = 3.0,
	},
}

function WeaponConfig.GetLevelMult(level: number): number
	local lv = math.clamp(math.floor(level or 1), 1, WeaponConfig.MAX_WEAPON_LEVEL)
	return WeaponConfig.LEVEL_POWER_MULT[lv] or 1
end

function WeaponConfig.GetEffectivePower(def: WeaponDef, level: number?): number
	return def.powerMult * WeaponConfig.GetLevelMult(level or 1)
end

function WeaponConfig.GetSellPrice(def: WeaponDef, level: number?): number
	local lv = math.clamp(math.floor(level or 1), 1, WeaponConfig.MAX_WEAPON_LEVEL)
	local m = WeaponConfig.LEVEL_SELL_MULT[lv] or 1
	return math.floor((def.sellPrice or 5) * m)
end

function WeaponConfig.GetMergeNeed(fromLevel: number): number?
	return WeaponConfig.MERGE_COUNT[fromLevel]
end

local function add(
	id: string,
	name: string,
	rarity: string,
	location: number,
	powerMult: number,
	sellPrice: number,
	description: string?
)
	WeaponConfig.Weapons[id] = {
		id = id,
		name = name,
		rarity = rarity,
		powerMult = powerMult,
		location = location,
		sellPrice = sellPrice,
		iconKey = id,
		description = description,
	}
end

----------------------------------------------------------------------
-- LOC 1 — dump «Мечи статы» (Сила / sell exact)
----------------------------------------------------------------------
add("W1_C1", "Starter Weapon", "Common", 1, 1, 10, "Dump Сила 1")
add("W1_C2", "Old Sword", "Common", 1, 2, 40, "Dump Сила 2")
add("W1_C3", "Bone Dagger", "Common", 1, 3, 50, "Dump Сила 3")
add("W1_R1", "Wooden Mace", "Rare", 1, 10, 150, "Dump Сила 10")
add("W1_E1", "Double-Edged Sword", "Epic", 1, 17, 200, "Dump Сила 17")
add("W1_E2", "Forest Spirit Staff", "Epic", 1, 28, 250, "Dump Сила 28")
add("W1_L1", "Ardite", "Legendary", 1, 50, 500, "Dump Сила 50")
add("W1_M1", "Forest Sword", "Mythic", 1, 125, 1000, "Dump Сила 125")
add("W1_S1", "Forest Shadow", "Secret", 1, 150, 1500, "Dump Сила 150")

----------------------------------------------------------------------
-- LOC 2 — dump «Мечи2ялока»
----------------------------------------------------------------------
add("W2_C1", "Pirate Hook", "Common", 2, 50, 50_000, "Dump Сила 50")
add("W2_C2", "Pirate Hammer", "Common", 2, 100, 100_000, "Dump Сила 100")
add("W2_C3", "Pirate Saber", "Common", 2, 150, 250_000, "Dump Сила 150")
add("W2_R1", "Golden-plated Sword", "Rare", 2, 300, 500_000, "Dump Сила 300")
add("W2_R2", "Captain Axe", "Rare", 2, 500, 1_000_000, "Dump Сила 500")
add("W2_E1", "Element Blade", "Epic", 2, 800, 25_000_000, "Dump Сила 800")
add("W2_E2", "Emerald Blade", "Epic", 2, 1500, 50_000_000, "Dump Сила 1.5K")
add("W2_L1", "Sea Dagger", "Legendary", 2, 4250, 120_000_000, "Dump Сила 4.25K")

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
	return WeaponConfig.LocationProgression[locationId]
		or { dropChanceMult = 1, highRarityMult = 1, timeHint = "no dump" }
end

function WeaponConfig.NormalizeTier(tier: string): string
	if tier == "trash" or tier == "t1" then
		return "simple"
	elseif tier == "normal" or tier == "t2" then
		return "medium"
	elseif tier == "t3" then
		return "hard"
	elseif tier == "t4" then
		return "elite"
	end
	return tier
end

function WeaponConfig.GetEffectiveWeights(tier: string, locationId: number): DropWeightTable
	local key = WeaponConfig.NormalizeTier(tier)
	local base = WeaponConfig.TierRarityWeights[key]
	if not base then
		return { Common = 100 }
	end
	-- Loc2 uses per-mob exact tables in LootService; rarity weights only for Loc1 fallback
	local out: DropWeightTable = {}
	local total = 0
	for rarity, w in base do
		if w > 0 then
			out[rarity] = w
			total += w
		end
	end
	if total > 0 then
		for rarity, w in out do
			out[rarity] = (w / total) * 100
		end
	end
	return out
end

function WeaponConfig.GetBaseDropChance(tier: string, locationId: number): number
	local key = WeaponConfig.NormalizeTier(tier)
	local base = WeaponConfig.TierDropChance[key] or WeaponConfig.TierDropChance[tier] or 0
	local prog = WeaponConfig.GetLocationProgression(locationId)
	return math.clamp(base * prog.dropChanceMult, 0, 1)
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

export type DropPreviewEntry = {
	rarity: string,
	chancePercent: number,
	weaponIds: { string },
	weapons: { { id: string, name: string, powerMult: number } },
}

function WeaponConfig.BuildDropPreview(tier: string, locationId: number): { DropPreviewEntry }
	local weights = WeaponConfig.GetEffectiveWeights(tier, locationId)
	local list: { DropPreviewEntry } = {}
	for _, rarity in WeaponConfig.RarityOrder do
		local w = weights[rarity]
		if w and w > 0 and rarity ~= "Limited" then
			local cands = WeaponConfig.GetDropCandidates(locationId, rarity)
			local weapons = {}
			local ids = {}
			for _, def in cands do
				table.insert(ids, def.id)
				table.insert(weapons, {
					id = def.id,
					name = def.name,
					powerMult = def.powerMult,
				})
			end
			if #ids > 0 then
				table.insert(list, {
					rarity = rarity,
					chancePercent = if w > 0 and w < 0.001
						then math.floor(w * 1e7 + 0.5) / 1e7
						else math.floor(w * 1000 + 0.5) / 1000,
					weaponIds = ids,
					weapons = weapons,
				})
			end
		end
	end
	return list
end

--- Exact weapon weights from Loc2 mob inspect screenshots (sum ≈ 100)
function WeaponConfig.BuildDropPreviewFromTable(dropTable: { [string]: number }): { DropPreviewEntry }
	local list: { DropPreviewEntry } = {}
	for id, chance in dropTable do
		local def = WeaponConfig.Get(id)
		if def and chance > 0 then
			table.insert(list, {
				rarity = def.rarity,
				chancePercent = chance,
				weaponIds = { id },
				weapons = {
					{ id = def.id, name = def.name, powerMult = def.powerMult },
				},
			})
		end
	end
	table.sort(list, function(a, b)
		return a.chancePercent > b.chancePercent
	end)
	return list
end

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
		return a.powerMult < b.powerMult
	end)
	return out
end

return WeaponConfig
