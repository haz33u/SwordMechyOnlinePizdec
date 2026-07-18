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
		Location squeeze (Cristalix-like tables stay real, but later locs
		slightly nerf Epic+ then re-normalize to 100%).
	]]
	LocationProgression = {
		[1] = { dropChanceMult = 1.00, highRarityMult = 1.00, timeHint = "Loc1 = reference Cristalix % tables" },
		[2] = { dropChanceMult = 1.00, highRarityMult = 0.88, timeHint = "high tiers −12% weight, still drop" },
		[3] = { dropChanceMult = 1.00, highRarityMult = 0.75, timeHint = "high tiers −25%" },
		[4] = { dropChanceMult = 1.00, highRarityMult = 0.62, timeHint = "high tiers −38%, Secret still real" },
	} :: { [number]: LocationProgression },

	--[[
		Cristalix model: ~1 weapon per kill (weights sum ≈ 100).
		Screenshots: simple / medium / hard mob inspect tables.
		Aliases: trash=simple, normal=medium, elite=hard
	]]
	TierDropChance = {
		-- guaranteed weapon roll (table is the distribution)
		simple = 1.0,
		medium = 1.0,
		hard = 1.0,
		boss = 1.0, -- boss also always rolls weapon + dust
		debug = 0,
		-- legacy aliases
		trash = 1.0,
		normal = 1.0,
		elite = 1.0,
	},

	--[[
		Absolute % from Cristalix HUD (Loc1 reference). Limited never here.
		simple ≈ mob1: 55 / 35 / 8 / 2
		medium ≈ mob2: 25 / 32 / 22 / 16 / 5
		hard   ≈ mob3: 15.84 / 29.70 / 33.66 / 16.83 / 2.88 / 0.99 / 0.10
	]]
	TierRarityWeights = {
		simple = {
			Common = 54.998,
			Uncommon = 34.999,
			Rare = 8.0,
			Epic = 2.003,
		},
		medium = {
			Common = 24.998,
			Uncommon = 31.997,
			Rare = 21.998,
			Epic = 15.998,
			Legendary = 5.009,
		},
		hard = {
			Common = 15.84,
			Uncommon = 29.701,
			Rare = 33.661,
			Epic = 16.830,
			Legendary = 2.877,
			Mythic = 0.992,
			Secret = 0.099,
		},
		boss = {
			-- boss: better mid/high + dust (dust is separate)
			Rare = 28.0,
			Epic = 35.0,
			Legendary = 25.0,
			Mythic = 10.0,
			Secret = 2.0,
		},
		-- aliases → same tables (filled below after normalize helper)
	} :: { [string]: DropWeightTable },

	-- Boss enchant dust (material for weapon enchant)
	BossDustMin = 2,
	BossDustMax = 5,
	BossDustAlways = true,

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
add("W1_C1", "Rusty Blade", "Common", 1, 1)
add("W1_C2", "Oak Sword", "Common", 1, 2)
add("W1_U1", "Bandit Blade", "Uncommon", 1, 1)
add("W1_U2", "Silver Cleaver", "Uncommon", 1, 2)
add("W1_R1", "Shadow Sword", "Rare", 1, 1)
add("W1_R2", "Wolf Fang", "Rare", 1, 2)
add("W1_E1", "Guardian Blade", "Epic", 1, 1)
add("W1_E2", "Emerald Guard", "Epic", 1, 2)
add("W1_L1", "Firstborn", "Legendary", 1, 1)
add("W1_L2", "Grove Heart", "Legendary", 1, 2)
add("W1_M1", "Ancestor Shadow", "Mythic", 1, 1)
add("W1_M2", "Abyss Fang", "Mythic", 1, 2)
add("W1_S1", "Ancient Forest Echo", "Secret", 1, 1)
add("W1_S2", "Forgotten King Blade", "Secret", 1, 2)
add("W1_X1", "Forest Dawn Arc", "Limited", 1, 1, {
	description = "LIMITED — seasonal/event. Fancy VFX, not from mobs.",
	vfxProfile = "limited_forest_dawn",
})

----------------------------------------------------------------------
-- LOC 2 — Пиратский берег
----------------------------------------------------------------------
add("W2_C1", "Boarding Saber", "Common", 2, 1)
add("W2_C2", "Hold Knife", "Common", 2, 2)
add("W2_U1", "Corsair Blade", "Uncommon", 2, 1)
add("W2_U2", "Sailor Hook", "Uncommon", 2, 2)
add("W2_R1", "Shark Cutter", "Rare", 2, 1)
add("W2_R2", "Storm Saber", "Rare", 2, 2)
add("W2_E1", "Admiral Saber", "Epic", 2, 1)
add("W2_E2", "Black Cove Blade", "Epic", 2, 2)
add("W2_L1", "Black Flag", "Legendary", 2, 1)
add("W2_L2", "Neptune Wrath", "Legendary", 2, 2)
add("W2_M1", "Kraken Scourge", "Mythic", 2, 1)
add("W2_M2", "Tidal Executioner", "Mythic", 2, 2)
add("W2_S1", "Maelstrom Heart", "Secret", 2, 1)
add("W2_S2", "Lost Fleet Blade", "Secret", 2, 2)
add("W2_X1", "Sunset Flagship", "Limited", 2, 1, {
	description = "LIMITED — pirate showcase VFX.",
	vfxProfile = "limited_pirate_sunset",
})

----------------------------------------------------------------------
-- LOC 3 — Земли шиноби
----------------------------------------------------------------------
add("W3_C1", "Training Wakizashi", "Common", 3, 1)
add("W3_C2", "Bamboo Blade", "Common", 3, 2)
add("W3_U1", "Apprentice Katana", "Uncommon", 3, 1)
add("W3_U2", "Guard Tanto", "Uncommon", 3, 2)
add("W3_R1", "Shadow Katana", "Rare", 3, 1)
add("W3_R2", "Moon Slash", "Rare", 3, 2)
add("W3_E1", "Clan Blade", "Epic", 3, 1)
add("W3_E2", "Shinobi-no-Yari", "Epic", 3, 2)
add("W3_L1", "Dragon Katana", "Legendary", 3, 1)
add("W3_L2", "Storm Seal", "Legendary", 3, 2)
add("W3_M1", "Thousand Shadows Blade", "Mythic", 3, 1)
add("W3_M2", "Temple Breaker", "Mythic", 3, 2)
add("W3_S1", "Eternal Tsukuyomi", "Secret", 3, 1)
add("W3_S2", "First Shinobi Sword", "Secret", 3, 2)
add("W3_X1", "Eternal Sakura", "Limited", 3, 1, {
	description = "LIMITED — sakura particles, not from mobs.",
	vfxProfile = "limited_sakura_eternity",
})

----------------------------------------------------------------------
-- LOC 4 — Полярная тундра
----------------------------------------------------------------------
add("W4_C1", "Ice Cleaver", "Common", 4, 1)
add("W4_C2", "Bone Knife", "Common", 4, 2)
add("W4_U1", "Frost Broadsword", "Uncommon", 4, 1)
add("W4_U2", "Polar Wolf Fang", "Uncommon", 4, 2)
add("W4_R1", "Northern Spear-Sword", "Rare", 4, 1)
add("W4_R2", "Blizzard Blade", "Rare", 4, 2)
add("W4_E1", "Glacier Breaker", "Epic", 4, 1)
add("W4_E2", "Eternal Winter Rune", "Epic", 4, 2)
add("W4_L1", "Polar Night Crown", "Legendary", 4, 1)
add("W4_L2", "Iceberg Hammer", "Legendary", 4, 2)
add("W4_M1", "Permafrost Heart", "Mythic", 4, 1)
add("W4_M2", "White Terror Fang", "Mythic", 4, 2)
add("W4_S1", "Polar Star Whisper", "Secret", 4, 1)
add("W4_S2", "End of Winter Blade", "Secret", 4, 2)
add("W4_X1", "Absolute Aurora", "Limited", 4, 1, {
	description = "LIMITED — aurora VFX, season flex.",
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

--- Normalize tier name (Cristalix 3 types + boss)
function WeaponConfig.NormalizeTier(tier: string): string
	if tier == "trash" then
		return "simple"
	elseif tier == "normal" then
		return "medium"
	elseif tier == "elite" then
		return "hard"
	end
	return tier
end

--- Effective rarity weights % (sum ≈ 100) after location high-tier squeeze.
function WeaponConfig.GetEffectiveWeights(tier: string, locationId: number): DropWeightTable
	local key = WeaponConfig.NormalizeTier(tier)
	local base = WeaponConfig.TierRarityWeights[key]
	if not base then
		return { Common = 100 }
	end
	local prog = WeaponConfig.GetLocationProgression(locationId)
	local out: DropWeightTable = {}
	local total = 0
	for rarity, w in base do
		local weight = w
		if WeaponConfig.HighRarities[rarity] then
			weight *= prog.highRarityMult
		end
		if weight > 0 then
			out[rarity] = weight
			total += weight
		end
	end
	-- re-normalize to 100 so later locs stay "real" percentages
	if total > 0 then
		for rarity, w in out do
			out[rarity] = (w / total) * 100
		end
	end
	return out
end

--- Absolute chance 0..1 that a weapon drop attempt succeeds (Cristalix ≈ always).
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

--- Full inspect table for UI (Shift+RMB on mob). Chances sum ≈ 100.
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
					chancePercent = math.floor(w * 1000 + 0.5) / 1000, -- 3 decimals like Cristalix
					weaponIds = ids,
					weapons = weapons,
				})
			end
		end
	end
	return list
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
