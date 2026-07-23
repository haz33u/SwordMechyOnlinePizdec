--!strict
--[[
	Auras — balance dump (player screenshots 2026-07-21), English display names.
	Stats below are LEVEL 1 exact dump values.
	Upgrade: each level multiplies power/damage/coin by LEVEL_STAT_BONUS (crit scales slower).

	Dump drop % used as roll weights (sum ≈ 100%).
	Sources: docs/ref/balance/captures/auras_dump/
]]

export type AuraDef = {
	id: string,
	name: string,
	rarity: string,
	-- level-1 dump %
	powerPct: number, -- сила
	damagePct: number, -- урон
	coinPct: number, -- деньги
	critPct: number, -- шанс крита (points, not 0–1)
	multiCritPct: number, -- мультикрит points
	dropWeight: number, -- dump case weight
}

local AuraConfig = {
	MAX_LEVEL = 10,
	-- +12% of base power/damage/coin per level above 1 (L10 ≈ ×2.08 base combat %)
	LEVEL_STAT_BONUS = 0.12,
	-- crit / multicrit grow slower so they do not hard-cap at L10
	LEVEL_CRIT_BONUS = 0.06,

	Auras = {
		----------------------------------------------------------------------
		-- COMMON (~6.648% each)
		----------------------------------------------------------------------
		A_Test = {
			id = "A_Test",
			name = "Test",
			rarity = "Mythic",
			powerPct = 250,
			damagePct = 250,
			coinPct = 100,
			critPct = 50,
			multiCritPct = 25,
			dropWeight = 1.0,
		},
		A_Ice = {
			id = "A_Ice",
			name = "Ice Aura",
			rarity = "Common",
			powerPct = 5,
			damagePct = 0,
			coinPct = 2,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 6.648,
		},
		A_Christmas = {
			id = "A_Christmas",
			name = "Christmas Aura",
			rarity = "Common",
			powerPct = 0,
			damagePct = 3,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 6.648,
		},
		A_Light = {
			id = "A_Light",
			name = "Light Aura",
			rarity = "Common",
			powerPct = 0,
			damagePct = 20,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 6.648,
		},
		A_IceBreath = {
			id = "A_IceBreath",
			name = "Ice Breath Aura",
			rarity = "Common",
			powerPct = 0,
			damagePct = 7,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 6.648,
		},
		A_Leaf = {
			id = "A_Leaf",
			name = "Leaf Aura",
			rarity = "Common",
			powerPct = 3,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 6.648,
		},
		A_Darkness = {
			id = "A_Darkness",
			name = "Darkness Aura",
			rarity = "Common",
			powerPct = 0,
			damagePct = 0,
			coinPct = 3,
			critPct = 20,
			multiCritPct = 0,
			dropWeight = 6.648,
		},

		----------------------------------------------------------------------
		-- RARE (~4.299% each)
		----------------------------------------------------------------------
		A_Protection = {
			id = "A_Protection",
			name = "Protection Aura",
			rarity = "Rare",
			powerPct = 0,
			damagePct = 4,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 7,
			dropWeight = 4.299,
		},
		A_Lightning = {
			id = "A_Lightning",
			name = "Lightning Aura",
			rarity = "Rare",
			powerPct = 0,
			damagePct = 12,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 4.299,
		},
		A_Earth = {
			id = "A_Earth",
			name = "Earth Aura",
			rarity = "Rare",
			powerPct = 0,
			damagePct = 25,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 4.299,
		},
		A_Exhaustion = {
			id = "A_Exhaustion",
			name = "Exhaustion Aura",
			rarity = "Rare",
			powerPct = 20,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 4.299,
		},
		A_Wrath = {
			id = "A_Wrath",
			name = "Wrath Aura",
			rarity = "Rare",
			powerPct = 0,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 10,
			dropWeight = 4.299,
		},
		A_Dragon = {
			id = "A_Dragon",
			name = "Dragon Aura",
			rarity = "Rare",
			powerPct = 14,
			damagePct = 0,
			coinPct = 0,
			critPct = 10,
			multiCritPct = 0,
			dropWeight = 4.299,
		},
		A_Kind = {
			id = "A_Kind",
			name = "Kind Aura",
			rarity = "Rare",
			powerPct = 10,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 4.299,
		},

		----------------------------------------------------------------------
		-- EPIC (~2.399% each)
		----------------------------------------------------------------------
		A_Rebirth = {
			id = "A_Rebirth",
			name = "Rebirth Aura",
			rarity = "Epic",
			powerPct = 55,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 2.399,
		},
		A_Lava = {
			id = "A_Lava",
			name = "Lava Aura",
			rarity = "Epic",
			powerPct = 0,
			damagePct = 0,
			coinPct = 5,
			critPct = 40,
			multiCritPct = 0,
			dropWeight = 2.399,
		},
		A_Confrontation = {
			id = "A_Confrontation",
			name = "Confrontation Aura",
			rarity = "Epic",
			powerPct = 0,
			damagePct = 55,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 2.399,
		},
		A_Blaze = {
			id = "A_Blaze",
			name = "Blaze Aura",
			rarity = "Epic",
			powerPct = 0,
			damagePct = 50,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 2.399,
		},
		A_Knowledge = {
			id = "A_Knowledge",
			name = "Knowledge Aura",
			rarity = "Epic",
			powerPct = 45,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 2.399,
		},
		A_Magic = {
			id = "A_Magic",
			name = "Magic Aura",
			rarity = "Epic",
			powerPct = 65,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 2.399,
		},
		A_Earthen = {
			id = "A_Earthen",
			name = "Earthen Aura",
			rarity = "Epic",
			powerPct = 0,
			damagePct = 0,
			coinPct = 0,
			critPct = 15,
			multiCritPct = 15,
			dropWeight = 2.399,
		},

		----------------------------------------------------------------------
		-- LEGENDARY (~0.7016% each)
		----------------------------------------------------------------------
		A_Vampirism = {
			id = "A_Vampirism",
			name = "Vampirism Aura",
			rarity = "Legendary",
			powerPct = 90,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.7016,
		},
		A_Fire = {
			id = "A_Fire",
			name = "Fire Aura",
			rarity = "Legendary",
			powerPct = 0,
			damagePct = 30,
			coinPct = 0,
			critPct = 20,
			multiCritPct = 20,
			dropWeight = 0.7016,
		},
		A_Water = {
			id = "A_Water",
			name = "Water Aura",
			rarity = "Legendary",
			powerPct = 0,
			damagePct = 90,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.7016,
		},
		A_Nature = {
			id = "A_Nature",
			name = "Nature Aura",
			rarity = "Legendary",
			powerPct = 75,
			damagePct = 0,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.7016,
		},
		A_Voodoo = {
			id = "A_Voodoo",
			name = "Voodoo Aura",
			rarity = "Legendary",
			powerPct = 0,
			damagePct = 100,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.7016,
		},
		A_Pumpkin = {
			id = "A_Pumpkin",
			name = "Pumpkin Aura",
			rarity = "Legendary",
			powerPct = 85,
			damagePct = 0,
			coinPct = 10,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.7016,
		},
		A_Science = {
			id = "A_Science",
			name = "Science Aura",
			rarity = "Legendary",
			powerPct = 0,
			damagePct = 80,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.7016,
		},
		A_Consciousness = {
			id = "A_Consciousness",
			name = "Consciousness Aura",
			rarity = "Legendary",
			powerPct = 0,
			damagePct = 75,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.7016,
		},

		----------------------------------------------------------------------
		-- MYTHIC (~0.1603% each)
		----------------------------------------------------------------------
		A_Blade = {
			id = "A_Blade",
			name = "Blade Aura",
			rarity = "Mythic",
			powerPct = 0,
			damagePct = 125,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.1603,
		},
		A_Humility = {
			id = "A_Humility",
			name = "Humility Aura",
			rarity = "Mythic",
			powerPct = 100,
			damagePct = 0,
			coinPct = 0,
			critPct = 40,
			multiCritPct = 0,
			dropWeight = 0.1603,
		},
		A_Instrumental = {
			id = "A_Instrumental",
			name = "Instrumental Aura",
			rarity = "Mythic",
			powerPct = 0,
			damagePct = 145,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.1603,
		},
		A_Bone = {
			id = "A_Bone",
			name = "Bone Aura",
			rarity = "Mythic",
			powerPct = 100,
			damagePct = 100,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.1603,
		},
		A_Cosmic = {
			id = "A_Cosmic",
			name = "Cosmic Aura",
			rarity = "Mythic",
			powerPct = 0,
			damagePct = 110,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 0,
			dropWeight = 0.1603,
		},
		A_Snowflake = {
			id = "A_Snowflake",
			name = "Snowflake Aura",
			rarity = "Mythic",
			powerPct = 0,
			damagePct = 100,
			coinPct = 0,
			critPct = 0,
			multiCritPct = 10,
			dropWeight = 0.1603,
		},
		----------------------------------------------------------------------
		-- PLACE1 EXRACTED TOP-TIER AURAS
		----------------------------------------------------------------------
		A_Galaxy = {
			id = "A_Galaxy",
			name = "Galaxy Aura",
			rarity = "Mythic",
			powerPct = 300,
			damagePct = 300,
			coinPct = 150,
			critPct = 60,
			multiCritPct = 30,
			dropWeight = 0.08,
		},
		A_DarkMatter = {
			id = "A_DarkMatter",
			name = "Dark Matter Aura",
			rarity = "Mythic",
			powerPct = 350,
			damagePct = 350,
			coinPct = 200,
			critPct = 70,
			multiCritPct = 35,
			dropWeight = 0.05,
		},
		A_Empyrus = {
			id = "A_Empyrus",
			name = "Empyrus Aura",
			rarity = "Mythic",
			powerPct = 400,
			damagePct = 400,
			coinPct = 250,
			critPct = 80,
			multiCritPct = 40,
			dropWeight = 0.03,
		},
		A_Glitched = {
			id = "A_Glitched",
			name = "Glitched Aura",
			rarity = "Legendary",
			powerPct = 220,
			damagePct = 220,
			coinPct = 100,
			critPct = 40,
			multiCritPct = 20,
			dropWeight = 0.3,
		},
		A_God = {
			id = "A_God",
			name = "God Aura",
			rarity = "Mythic",
			powerPct = 500,
			damagePct = 500,
			coinPct = 300,
			critPct = 100,
			multiCritPct = 50,
			dropWeight = 0.01,
		},
		A_Ultraverse = {
			id = "A_Ultraverse",
			name = "Ultraverse Aura",
			rarity = "Mythic",
			powerPct = 450,
			damagePct = 450,
			coinPct = 280,
			critPct = 90,
			multiCritPct = 45,
			dropWeight = 0.02,
		},
		A_Blackhole = {
			id = "A_Blackhole",
			name = "Blackhole Aura",
			rarity = "Legendary",
			powerPct = 200,
			damagePct = 200,
			coinPct = 90,
			critPct = 35,
			multiCritPct = 15,
			dropWeight = 0.4,
		},
		A_Flamethrower = {
			id = "A_Flamethrower",
			name = "Flamethrower Aura",
			rarity = "Epic",
			powerPct = 150,
			damagePct = 150,
			coinPct = 70,
			critPct = 25,
			multiCritPct = 10,
			dropWeight = 1.2,
		},
		A_DeepGalaxy = {
			id = "A_DeepGalaxy",
			name = "Deep Galaxy Aura",
			rarity = "Legendary",
			powerPct = 250,
			damagePct = 250,
			coinPct = 120,
			critPct = 45,
			multiCritPct = 22,
			dropWeight = 0.25,
		},
		A_Hell = {
			id = "A_Hell",
			name = "Hell Aura",
			rarity = "Epic",
			powerPct = 140,
			damagePct = 140,
			coinPct = 60,
			critPct = 20,
			multiCritPct = 8,
			dropWeight = 1.5,
		},
		A_RedScarlet = {
			id = "A_RedScarlet",
			name = "Red Scarlet Aura",
			rarity = "Legendary",
			powerPct = 180,
			damagePct = 180,
			coinPct = 80,
			critPct = 30,
			multiCritPct = 12,
			dropWeight = 0.5,
		},
	} :: { [string]: AuraDef },

	-- coin cost to open (keys primary)
	OPEN_COST = 0,

	RARITY_UPGRADE_MULT = {
		Common = 1,
		Uncommon = 1.4,
		Rare = 2.2,
		Epic = 3.8,
		Legendary = 6.5,
		Mythic = 11,
	} :: { [string]: number },
}

function AuraConfig.Get(id: string): AuraDef?
	return AuraConfig.Auras[id]
end

--- Level mult for power / damage / coins (dump is L1)
function AuraConfig.StatLevelMult(level: number): number
	local lv = math.max(1, math.floor(level or 1))
	return 1 + (lv - 1) * AuraConfig.LEVEL_STAT_BONUS
end

function AuraConfig.CritLevelMult(level: number): number
	local lv = math.max(1, math.floor(level or 1))
	return 1 + (lv - 1) * AuraConfig.LEVEL_CRIT_BONUS
end

export type AuraEffective = {
	powerPct: number,
	damagePct: number,
	coinPct: number,
	critPct: number,
	multiCritPct: number,
}

function AuraConfig.GetEffective(def: AuraDef, level: number?): AuraEffective
	local sm = AuraConfig.StatLevelMult(level or 1)
	local cm = AuraConfig.CritLevelMult(level or 1)
	return {
		powerPct = def.powerPct * sm,
		damagePct = def.damagePct * sm,
		coinPct = def.coinPct * sm,
		critPct = def.critPct * cm,
		multiCritPct = def.multiCritPct * cm,
	}
end

function AuraConfig.UpgradeCost(def: AuraDef, currentLevel: number): number
	local lv = math.max(1, math.floor(currentLevel))
	if lv >= AuraConfig.MAX_LEVEL then
		return 0
	end
	local r = AuraConfig.RARITY_UPGRADE_MULT[def.rarity] or 2
	-- L1→2 cheap; scales for long F2P grind
	return math.floor(800 * r * (1.55 ^ (lv - 1)))
end

function AuraConfig.Roll(): string
	local pool = {}
	local total = 0
	for id, def in AuraConfig.Auras do
		local w = def.dropWeight or 1
		table.insert(pool, { id = id, weight = w })
		total += w
	end
	if total <= 0 then
		return "A_Ice"
	end
	local r = math.random() * total
	local acc = 0
	for _, p in pool do
		acc += p.weight
		if r <= acc then
			return p.id
		end
	end
	return pool[1].id
end

-- legacy id map (old skeleton → dump)
AuraConfig.LegacyIdMap = {
	A_C1 = "A_Ice",
	A_C2 = "A_Leaf",
	A_U1 = "A_Kind",
	A_R1 = "A_Dragon",
	A_E1 = "A_Blaze",
	A_L1 = "A_Nature",
	A_M1 = "A_Bone",
}

function AuraConfig.ResolveId(id: string): string
	return AuraConfig.LegacyIdMap[id] or id
end

return AuraConfig
