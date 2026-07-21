--!strict
--[[
	Relics — designed for long F2P (~1–2 months to clear ~25 location rungs)
	with a hard wall on each new world (weapons/pets do the big jumps; relics = % glue).

	Slots:
	  Free: 2 equipped (GameConfig.START_RELIC_SLOTS)
	  Paid gamepass relicSlot: +1 → 3 total

	Budget (level/stars = 0, all slots filled with "on-band" relics):
	  Early (Loc1–2):   ~2×(12–40)  →  ~24–80% power pool
	  Mid:              ~2×(40–90)  →  ~80–180%
	  Late band:        ~2×(90–140) →  ~180–280%
	  Paid 3rd slot:    +same band  →  ~1.5× free relic contribution
	  Stars: +20% of base per star, max 5 → up to ×2.0 on that piece

	Sources: dungeon tiers + later world bands (not Loc1 open-world spam).
]]

export type RelicDef = {
	id: string,
	name: string,
	rarity: string,
	powerPct: number,
	damagePct: number,
	coinPct: number?,
	source: string, -- easy | medium | hard | world
	band: number, -- 1..5 progression band (for future 25-loc ladder)
}

local RelicConfig = {
	Relics = {
		----------------------------------------------------------------------
		-- Band 1 — Loc1 / Easy dungeon (first month days 1–7)
		----------------------------------------------------------------------
		R_B1_Ring = {
			id = "R_B1_Ring",
			name = "Goblin Signet",
			rarity = "Common",
			powerPct = 12,
			damagePct = 0,
			coinPct = 0,
			source = "easy",
			band = 1,
		},
		R_B1_Amulet = {
			id = "R_B1_Amulet",
			name = "Forest Charm",
			rarity = "Uncommon",
			powerPct = 22,
			damagePct = 8,
			coinPct = 0,
			source = "easy",
			band = 1,
		},
		R_B1_Coin = {
			id = "R_B1_Coin",
			name = "Leaf Brooch",
			rarity = "Uncommon",
			powerPct = 10,
			damagePct = 0,
			coinPct = 8,
			source = "easy",
			band = 1,
		},

		----------------------------------------------------------------------
		-- Band 2 — Loc2 / Medium dungeon
		----------------------------------------------------------------------
		R_B2_Hook = {
			id = "R_B2_Hook",
			name = "Pirate Hook Charm",
			rarity = "Rare",
			powerPct = 40,
			damagePct = 18,
			coinPct = 0,
			source = "medium",
			band = 2,
		},
		R_B2_Compass = {
			id = "R_B2_Compass",
			name = "Captain Compass",
			rarity = "Rare",
			powerPct = 28,
			damagePct = 12,
			coinPct = 10,
			source = "medium",
			band = 2,
		},
		R_B2_Crest = {
			id = "R_B2_Crest",
			name = "Sea Crest",
			rarity = "Epic",
			powerPct = 55,
			damagePct = 30,
			coinPct = 0,
			source = "medium",
			band = 2,
		},

		----------------------------------------------------------------------
		-- Band 3 — Loc3 / Hard dungeon
		----------------------------------------------------------------------
		R_B3_Seal = {
			id = "R_B3_Seal",
			name = "Shinobi Seal",
			rarity = "Epic",
			powerPct = 70,
			damagePct = 35,
			coinPct = 0,
			source = "hard",
			band = 3,
		},
		R_B3_Mask = {
			id = "R_B3_Mask",
			name = "Shadow Mask",
			rarity = "Legendary",
			powerPct = 90,
			damagePct = 45,
			coinPct = 0,
			source = "hard",
			band = 3,
		},
		R_B3_Scroll = {
			id = "R_B3_Scroll",
			name = "War Scroll",
			rarity = "Legendary",
			powerPct = 60,
			damagePct = 55,
			coinPct = 5,
			source = "hard",
			band = 3,
		},

		----------------------------------------------------------------------
		-- Band 4 — Loc4+ / deep hard (late F2P month 1–2)
		----------------------------------------------------------------------
		R_B4_Core = {
			id = "R_B4_Core",
			name = "Frost Core",
			rarity = "Legendary",
			powerPct = 110,
			damagePct = 55,
			coinPct = 0,
			source = "hard",
			band = 4,
		},
		R_B4_Crown = {
			id = "R_B4_Crown",
			name = "Tundra Crown",
			rarity = "Mythic",
			powerPct = 130,
			damagePct = 70,
			coinPct = 0,
			source = "hard",
			band = 4,
		},

		----------------------------------------------------------------------
		-- Band 5 — endgame placeholder for loc 10–25 rungs
		----------------------------------------------------------------------
		R_B5_Heart = {
			id = "R_B5_Heart",
			name = "Worldheart Relic",
			rarity = "Mythic",
			powerPct = 150,
			damagePct = 80,
			coinPct = 0,
			source = "hard",
			band = 5,
		},
		R_B5_Eclipse = {
			id = "R_B5_Eclipse",
			name = "Eclipse Medallion",
			rarity = "Mythic",
			powerPct = 120,
			damagePct = 100,
			coinPct = 8,
			source = "hard",
			band = 5,
		},
	} :: { [string]: RelicDef },

	STAR_BONUS = 0.20, -- +20% of base per star
	MAX_STARS = 5,
	UPGRADE_COST_BASE = 2_500,

	-- soft budget caps (sum equipped effective power%) — tuning rails
	BUDGET_POWER_SOFT_CAP = {
		free2 = 280, -- 2 slots, mid-late before stars
		paid3 = 420, -- 3 slots
	},
}

function RelicConfig.Get(id: string): RelicDef?
	return RelicConfig.Relics[id]
end

function RelicConfig.EffectiveStats(def: RelicDef, stars: number): (number, number, number)
	local s = math.clamp(stars or 0, 0, RelicConfig.MAX_STARS)
	local m = 1 + RelicConfig.STAR_BONUS * s
	return def.powerPct * m, def.damagePct * m, (def.coinPct or 0) * m
end

function RelicConfig.StarUpgradeCost(def: RelicDef, currentStars: number): number
	local s = math.max(0, math.floor(currentStars))
	if s >= RelicConfig.MAX_STARS then
		return 0
	end
	local rarityMult = ({
		Common = 1,
		Uncommon = 1.5,
		Rare = 2.5,
		Epic = 4,
		Legendary = 7,
		Mythic = 12,
	})[def.rarity] or 2
	return math.floor(RelicConfig.UPGRADE_COST_BASE * rarityMult * (1.7 ^ s))
end

function RelicConfig.Roll(source: string): string
	local pool = {}
	for id, def in RelicConfig.Relics do
		if def.source == source then
			table.insert(pool, id)
		end
	end
	if #pool == 0 then
		-- fallback: any band 1
		for id, def in RelicConfig.Relics do
			if def.band == 1 then
				table.insert(pool, id)
			end
		end
	end
	if #pool == 0 then
		return "R_B1_Ring"
	end
	return pool[math.random(1, #pool)]
end

function RelicConfig.RollForBand(maxBand: number): string
	local pool = {}
	for id, def in RelicConfig.Relics do
		if def.band <= maxBand then
			table.insert(pool, id)
		end
	end
	if #pool == 0 then
		return "R_B1_Ring"
	end
	return pool[math.random(1, #pool)]
end

-- legacy placeholder ids → new catalog
RelicConfig.LegacyIdMap = {
	R_E1 = "R_B1_Ring",
	R_E2 = "R_B1_Amulet",
	R_M1 = "R_B2_Hook",
	R_M2 = "R_B2_Crest",
	R_H1 = "R_B3_Mask",
}

function RelicConfig.ResolveId(id: string): string
	return RelicConfig.LegacyIdMap[id] or id
end

return RelicConfig
