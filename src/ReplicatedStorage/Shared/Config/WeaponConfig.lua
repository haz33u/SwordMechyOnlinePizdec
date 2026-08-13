--!strict
--[[
	WEAPON CATALOG — Loc1 + Loc2 ONLY, 1:1 from balance dumps.
	Source: docs/ref/balance/DUMP_CATALOG.md (player screenshots).

	Сила = absolute powerMult (pure number, not %).
	No filler / Loc3 / Loc4 / Limited skeletons.
]]

export type WeaponDef = {
	id: string,
	name: string,
	rarity: string,
	powerMult: number, -- reference game "Сила" at L1
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

	MAX_WEAPON_LEVEL = 3,

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
		[3] = { dropChanceMult = 1.00, highRarityMult = 0.90, timeHint = "Loc3 T-scale" },
		[4] = { dropChanceMult = 1.00, highRarityMult = 0.80, timeHint = "Loc4 Tundra" },
		[5] = { dropChanceMult = 1.00, highRarityMult = 0.70, timeHint = "Loc5 Ash" },
		[6] = { dropChanceMult = 1.00, highRarityMult = 0.60, timeHint = "Loc6 Neon" },
		[7] = { dropChanceMult = 1.00, highRarityMult = 0.50, timeHint = "Loc7 Cathedral (soft wall)" },
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
			Legendary = 2.5045,
		},
		hard = {
			Common = 45.541, -- 15.84+29.701
			Rare = 33.661,
			Epic = 16.830,
			Legendary = 1.4385,
			Mythic = 1.091,
		},
		elite = {
			Common = 36.0, -- 12+24
			Rare = 30.0,
			Epic = 20.0,
			Legendary = 5.0,
			Mythic = 3.9999,
			Secret = 0.0001,
		},
		boss = {
			Rare = 28.0,
			Epic = 35.0,
			Legendary = 12.5,
			Mythic = 10.0,
			Secret = 2.0,
		},
	} :: { [string]: DropWeightTable },

	BossDustMin = 2,
	BossDustMax = 5,
	BossDustAlways = true,

	Weapons = {} :: { [string]: WeaponDef },

	STARTER_WEAPON = "starter_weapon",

	--[[
		Legacy codes (old W1_U2-style fillers + previous dump codes) → current dump slug.
		Unknown fillers without a dump twin map to nearest dump common of same loc.
	]]
	LegacyIdMap = {
		-- Loc1 dump codes
		W1_C1 = "starter_weapon",
		W1_C2 = "old_sword",
		W1_C3 = "bone_dagger",
		W1_R1 = "wooden_mace",
		W1_E1 = "double_edged_sword",
		W1_E2 = "forest_spirit_staff",
		W1_L1 = "ardite",
		W1_M1 = "forest_sword",
		W1_S1 = "forest_shadow",
		-- Loc1 fillers (removed) → closest dump
		W1_U1 = "old_sword",
		W1_U2 = "bone_dagger",
		W1_R2 = "wooden_mace",
		W1_L2 = "ardite",
		W1_M2 = "forest_sword",
		W1_S2 = "forest_shadow",
		W1_X1 = "forest_shadow",
		-- Loc2 dump codes
		W2_C1 = "pirate_hook",
		W2_C2 = "pirate_hammer",
		W2_C3 = "pirate_saber",
		W2_R1 = "golden_plated_sword",
		W2_R2 = "captain_axe",
		W2_E1 = "element_blade",
		W2_E2 = "emerald_blade",
		W2_L1 = "sea_dagger",
		-- Loc2 old stubs
		W2_U1 = "pirate_hook",
		W2_U2 = "pirate_hammer",
		W2_L2 = "sea_dagger",
		W2_M1 = "sea_dagger",
		W2_M2 = "sea_dagger",
		W2_S1 = "sea_dagger",
		W2_S2 = "sea_dagger",
		W2_X1 = "sea_dagger",
	} :: { [string]: string },

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
-- LOC 1 — dump names (id = readable slug, name = player-facing English)
----------------------------------------------------------------------
add("starter_weapon", "Starter Weapon", "Common", 1, 50, 10, "A worn blade given to every newcomer. Strength 50.")
add("old_sword", "Old Sword", "Common", 1, 100, 40, "Slightly better than bare hands. Strength 100.")
add("bone_dagger", "Bone Dagger", "Common", 1, 175, 50, "Goblin-carved bone. Strength 175.")
add("wooden_mace", "Wooden Mace", "Rare", 1, 400, 150, "Heavy and reliable. Strength 400.")
add("double_edged_sword", "Double-Edged Sword", "Epic", 1, 900, 200, "Two edges, twice the trouble. Strength 900.")
add("forest_spirit_staff", "Forest Spirit Staff", "Epic", 1, 1_500, 250, "Channelled forest magic. Strength 1.5K.")
add("ardite", "Ardite", "Legendary", 1, 3_500, 500, "Gleaming green alloy. Strength 3.5K.")
add("forest_sword", "Forest Sword", "Mythic", 1, 8_000, 1000, "Blade of the deep woods. Strength 8K.")
add("forest_shadow", "Forest Shadow", "Secret", 1, 15_000, 1500, "A whisper made steel. Strength 15K.")

----------------------------------------------------------------------
-- LOC 2 — Crystal Mine (Theme: mine)
----------------------------------------------------------------------
add("pirate_hook", "Miner Pickaxe", "Common", 2, 50, 50_000, "Sturdy pickaxe for mining crystal veins.")
add("pirate_hammer", "Stone Breaker", "Common", 2, 100, 100_000, "Heavy hammer that crushes cavern ore.")
add("pirate_saber", "Iron Digger Blade", "Common", 2, 150, 250_000, "Forged iron blade for mine guards.")
add("golden_plated_sword", "Golden Mine Blade", "Rare", 2, 300, 500_000, "Golden plated sword from deep shafts.")
add("captain_axe", "Miner Heavy Axe", "Rare", 2, 500, 1_000_000, "Heavy axe used by mine overseers.")
add("element_blade", "Crystal Shard Sword", "Epic", 2, 800, 25_000_000, "Glowing crystal blade with earth magic.")
add("emerald_blade", "Emerald Crystal Blade", "Epic", 2, 1500, 50_000_000, "Carved from pure emerald ore.")
add("sea_dagger", "Crystal Core Dagger", "Legendary", 2, 4250, 120_000_000, "Pulsing dagger forged in the mine core.")

----------------------------------------------------------------------
-- LOC 3 — Desert Outpost (Theme: desert)
----------------------------------------------------------------------
add("shinobi_katana", "Sand Scimitar", "Common", 3, 80, 2_500_000, "Curved scimitar forged for desert heat.")
add("shadow_kunai", "Desert Dagger", "Rare", 3, 250, 10_000_000, "Sharp blade that strikes like a scorpion.")
add("dragon_tanto", "Dune Khopesh", "Epic", 3, 600, 50_000_000, "Ancient sickle-sword buried in the dunes.")
add("muramasa_blade", "Oasis Glaive", "Legendary", 3, 1_500, 250_000_000, "Glaive tempered in desert springs.")
add("samurai_god_katana", "Sunfire Scimitar", "Mythic", 3, 4_000, 750_000_000, "Blazing scimitar imbued with sunfire.")
add("shadow_shogun_blade", "Desert Emperor Blade", "Secret", 3, 6_000, 1_500_000_000, "Relic of the ancient desert empire.")

----------------------------------------------------------------------
-- LOC 4 — Winter Tundra (Theme: winter)
----------------------------------------------------------------------
add("ice_dagger", "Ice Dagger", "Common", 4, 400, 5_000_000, "Frostbitten dagger forged of solid ice.")
add("frost_cleaver", "Frost Cleaver", "Rare", 4, 1_200, 20_000_000, "Heavy cleaver coated in permafrost.")
add("glacier_scythe", "Glacier Scythe", "Epic", 4, 3_000, 100_000_000, "Scythe that reaps frozen souls.")
add("blizzard_sword", "Blizzard Sword", "Legendary", 4, 8_000, 500_000_000, "Blade that summons howling blizzards.")
add("ice_dragon_fang", "Ice Dragon Fang", "Mythic", 4, 20_000, 2_000_000_000, "Fang carved from the glacier dragon.")
add("polar_sovereign_blade", "Polar Sovereign Blade", "Secret", 4, 30_000, 5_000_000_000, "Sovereign sword of the arctic throne.")

----------------------------------------------------------------------
-- LOC 5 — Candy Land (Theme: candy)
----------------------------------------------------------------------
add("ash_shiv", "Candy Cane Dagger", "Common", 5, 2_000, 50_000_000, "Sharp candy cane blade.")
add("magma_maul", "Lollipop Hammer", "Rare", 5, 6_000, 200_000_000, "Giant lollipop that smashes enemies.")
add("obsidian_glaive", "Sugar Slash Blade", "Epic", 5, 15_000, 1_000_000_000, "Crystallized sugar blade.")
add("inferno_blade", "Cupcake Sword", "Legendary", 5, 40_000, 5_000_000_000, "Sweet yet deadly cupcake sword.")
add("volcano_god_sword", "Gummy Bear Greatsword", "Mythic", 5, 100_000, 25_000_000_000, "Massive gummy sword of power.")
add("phoenix_ash_blade", "Sweet Sovereign Edge", "Secret", 5, 150_000, 80_000_000_000, "Masterpiece of the Candy Kingdom.")

----------------------------------------------------------------------
-- LOC 6 — Water Haven (Theme: water)
----------------------------------------------------------------------
add("neon_dagger", "Coral Dagger", "Common", 6, 10_000, 1_000_000_000, "Sharp dagger carved from ocean coral.")
add("plasma_cutlass", "Pirate Cutlass", "Rare", 6, 30_000, 4_000_000_000, "Classic pirate cutlass of the high seas.")
add("cyber_katana", "Tide Blade", "Epic", 6, 80_000, 20_000_000_000, "Blade that flows like ocean tides.")
add("lightning_greatsword", "Ocean Trident", "Legendary", 6, 200_000, 100_000_000_000, "Three-pronged trident of ocean lords.")
add("overseer_proto_blade", "Deep Sea Saber", "Mythic", 6, 500_000, 500_000_000_000, "Forged in the abyss of the deep sea.")
add("dimensional_edge", "Leviathan Edge", "Secret", 6, 800_000, 1_500_000_000_000, "Power of the leviathan in steel.")

----------------------------------------------------------------------
-- LOC 7 — Hell Gate (Theme: hell)
----------------------------------------------------------------------
add("bone_knife", "Demon Dagger", "Common", 7, 50_000, 20_000_000_000, "Dagger forged in nether flames.")
add("crypt_rapier", "Infernal Rapier", "Rare", 7, 150_000, 80_000_000_000, "Rapier that burns with hellfire.")
add("soul_reaver_scythe", "Hellfire Scythe", "Epic", 7, 400_000, 400_000_000_000, "Fiery scythe of nether demons.")
add("cathedral_longsword", "Nether Longsword", "Legendary", 7, 1_000_000, 2_000_000_000_000, "Dark longsword of demon lords.")
add("bone_overlord_cleaver", "Demon Overlord Cleaver", "Mythic", 7, 2_500_000, 10_000_000_000_000, "Cleaver of the Hell Overlord.")
add("celestial_void_blade", "Hell Sovereign Void Blade", "Secret", 7, 4_000_000, 35_000_000_000_000, "Supreme void sword of infernal realm.")

----------------------------------------------------------------------
-- INCREMENTAL & SPECIAL WEAPONS (Stone, Iron, Gold, Titanium, Emerald, Ruby, Atherite, Celestium, Voidsteel)
----------------------------------------------------------------------
add("stone_sword", "Stone Sword", "Common", 1, 4, 60, "Incremental Stone Sword")
add("stone_scythe", "Stone Scythe", "Common", 1, 5, 80, "Incremental Stone Scythe")
add("stone_spear", "Stone Spear", "Common", 1, 6, 90, "Incremental Stone Spear")
add("stone_hammer", "Stone Hammer", "Common", 1, 8, 120, "Incremental Stone Hammer")
add("iron_sword", "Iron Sword", "Rare", 1, 15, 200, "Incremental Iron Sword")
add("iron_scythe", "Iron Scythe", "Rare", 1, 20, 250, "Incremental Iron Scythe")
add("iron_spear", "Iron Spear", "Rare", 1, 25, 300, "Incremental Iron Spear")
add("iron_hammer", "Iron Hammer", "Rare", 1, 35, 400, "Incremental Iron Hammer")
add("gold_sword", "Gold Sword", "Epic", 2, 400, 600_000, "Incremental Gold Sword")
add("gold_scythe", "Gold Scythe", "Epic", 2, 600, 1_000_000, "Incremental Gold Scythe")
add("gold_spear", "Gold Spear", "Epic", 2, 900, 2_000_000, "Incremental Gold Spear")
add("gold_hammer", "Gold Hammer", "Epic", 2, 1200, 5_000_000, "Incremental Gold Hammer")
add("titanium_sword", "Titanium Sword", "Legendary", 2, 2500, 30_000_000, "Incremental Titanium Sword")
add("titanium_scythe", "Titanium Scythe", "Legendary", 2, 3500, 60_000_000, "Incremental Titanium Scythe")
add("titanium_spear", "Titanium Spear", "Legendary", 2, 5000, 100_000_000, "Incremental Titanium Spear")
add("titanium_hammer", "Titanium Hammer", "Legendary", 2, 8000, 180_000_000, "Incremental Titanium Hammer")
add("emerald_sword", "Emerald Sword", "Mythic", 3, 50_000, 15_000_000, "Incremental Emerald Sword")
add("emerald_scythe", "Emerald Scythe", "Mythic", 3, 80_000, 30_000_000, "Incremental Emerald Scythe")
add("emerald_spear", "Emerald Spear", "Mythic", 3, 150_000, 75_000_000, "Incremental Emerald Spear")
add("emerald_hammer", "Emerald Hammer", "Mythic", 3, 300_000, 150_000_000, "Incremental Emerald Hammer")
add("ruby_sword", "Ruby Sword", "Secret", 3, 1_000_000, 500_000_000, "Incremental Ruby Sword")
add("ruby_scythe", "Ruby Scythe", "Secret", 3, 1_500_000, 800_000_000, "Incremental Ruby Scythe")
add("ruby_spear", "Ruby Spear", "Secret", 3, 2_500_000, 1_500_000_000, "Incremental Ruby Spear")
add("ruby_hammer", "Ruby Hammer", "Secret", 3, 5_000_000, 3_000_000_000, "Incremental Ruby Hammer")
add("atherite_sword", "Atherite Sword", "Secret", 4, 150_000_000, 75_000_000_000, "Incremental Atherite Sword")
add("celestium_sword", "Celestium Sword", "Secret", 4, 3_500_000_000, 1_500_000_000_000, "Incremental Celestium Sword")
add("voidsteel_sword", "Voidsteel Sword", "Secret", 4, 87_500_000_000, 35_000_000_000_000, "Incremental Voidsteel Sword")

----------------------------------------------------------------------
-- API
----------------------------------------------------------------------

--- Resolve legacy W1_U2 / W1_C1 codes → dump slug; pass through if already valid
function WeaponConfig.ResolveId(id: string): string
	if type(id) ~= "string" or id == "" then
		return WeaponConfig.STARTER_WEAPON
	end
	if WeaponConfig.Weapons[id] then
		return id
	end
	local mapped = WeaponConfig.LegacyIdMap[id]
	if mapped and WeaponConfig.Weapons[mapped] then
		return mapped
	end
	return id
end

function WeaponConfig.Get(id: string): WeaponDef?
	local resolved = WeaponConfig.ResolveId(id)
	return WeaponConfig.Weapons[resolved] or WeaponConfig.Weapons[id]
end

function WeaponConfig.GetDisplayName(id: string): string
	local def = WeaponConfig.Get(id)
	if def then
		return def.name
	end
	return "Unknown Sword"
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
	-- Loc2 uses per-mob exact tables in LootService; rarity weights for Loc1/3+ fallback
	local prog = WeaponConfig.GetLocationProgression(locationId)
	local highMult = prog.highRarityMult or 1

	local out: DropWeightTable = {}
	local total = 0
	for rarity, w in base do
		if w > 0 then
			local multiplier = if WeaponConfig.HighRarities[rarity] then highMult else 1
			out[rarity] = w * multiplier
			total += out[rarity]
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
function WeaponConfig.GetMergeNeed(level: number): number?
	local lv = math.clamp(math.floor(level or 1), 1, 3)
	if lv == 1 then
		return 5
	elseif lv == 2 then
		return 3
	end
	return nil
end

function WeaponConfig.GetLevelPowerMult(level: number): number
	local lv = math.clamp(math.floor(level or 1), 1, 3)
	if lv == 2 then
		return 1.8
	elseif lv == 3 then
		return 3.0
	end
	return 1.0
end

return WeaponConfig
