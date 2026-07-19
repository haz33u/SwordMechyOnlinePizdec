--!strict
--[[
	Pets — Loc1 + Loc2 1:1 from Cristalix dumps only.

	Мощь = pure powerMult (x1.1, x4.5, x290…) — NOT stored as %.
	caseWeight = dump drop % for that case pool.
	casePool = which chest rolls this pet.
]]

export type PetDef = {
	id: string,
	name: string,
	rarity: string,
	powerMult: number, -- Cristalix "Мощь xN" pure (combat)
	coinMult: number?, -- pure, default 1
	speedMult: number?, -- pure, default 1
	-- UI-compat only (Inventory/CaseOpening still read these; combat ignores)
	powerPct: number?,
	coinPct: number?,
	speedPct: number?,
	location: number,
	casePool: string,
	caseWeight: number,
	sellPrice: number?,
}

local PetConfig = {
	--[[
		case pools (dump chests):
		  loc1_500     — 500 coins
		  loc1_50k     — 50K coins
		  loc1_key49   — 49 keys (donate)
		  loc2_3_75m   — 3.75M coins
		  loc2_key54   — 54 keys (donate)
	]]
	CasePools = {
		loc1_500 = { coinCost = 500, keyCost = 0, location = 1 },
		loc1_50k = { coinCost = 50_000, keyCost = 0, location = 1 },
		loc1_key49 = { coinCost = 0, keyCost = 49, location = 1 },
		loc2_3_75m = { coinCost = 3_750_000, keyCost = 0, location = 2 },
		loc2_key54 = { coinCost = 0, keyCost = 54, location = 2 },
	},

	-- default open for current location = main coin case
	DefaultPoolByLocation = {
		[1] = "loc1_500",
		[2] = "loc2_3_75m",
	},

	Pets = {} :: { [string]: PetDef },

	-- legacy alias
	OPEN_COST = 500,
	FEED_BASE_COST = 500,
	FEED_GROWTH = 1.25,
	MAX_LEVEL = 30,
	-- +2% of (powerMult-1) contribution per feed level
	LEVEL_POWER_PER = 0.02,
}

local function add(
	id: string,
	name: string,
	rarity: string,
	powerMult: number,
	location: number,
	casePool: string,
	caseWeight: number,
	sellPrice: number?
)
	PetConfig.Pets[id] = {
		id = id,
		name = name,
		rarity = rarity,
		powerMult = powerMult,
		coinMult = 1,
		speedMult = 1,
		-- derived for old UI readers only — combat uses powerMult
		powerPct = (powerMult - 1) * 100,
		coinPct = 0,
		speedPct = 0,
		location = location,
		casePool = casePool,
		caseWeight = caseWeight,
		sellPrice = sellPrice,
	}
end

----------------------------------------------------------------------
-- Loc1 coin 500
----------------------------------------------------------------------
add("P1_C1", "Woodling", "Common", 1.1, 1, "loc1_500", 39.972, 50)
add("P1_C2", "Lurk", "Common", 1.2, 1, "loc1_500", 29.979, 80)
add("P1_R1", "Forestling", "Rare", 1.35, 1, "loc1_500", 15.02, 150)
add("P1_R2", "Hekata", "Rare", 1.5, 1, "loc1_500", 10.013, 250)
add("P1_L1", "Stiko", "Legendary", 1.75, 1, "loc1_500", 5.017, 500)

----------------------------------------------------------------------
-- Loc1 coin 50K
----------------------------------------------------------------------
add("P1_50_R1", "Charon", "Rare", 1.75, 1, "loc1_50k", 39.996, 500)
add("P1_50_R2", "Morpheus", "Rare", 2.5, 1, "loc1_50k", 29.997, 800)
add("P1_50_E1", "Torn", "Epic", 3.33, 1, "loc1_50k", 14.999, 1500)
add("P1_50_E2", "Nifel", "Epic", 4.5, 1, "loc1_50k", 9.999, 2500)
add("P1_50_L1", "Nightmare", "Legendary", 6, 1, "loc1_50k", 4.008, 5000)
add("P1_50_M1", "Grommash", "Mythic", 8, 1, "loc1_50k", 1.002, 10000)

----------------------------------------------------------------------
-- Loc1 key 49
----------------------------------------------------------------------
add("P1_K_R1", "Nocturne", "Rare", 14.5, 1, "loc1_key49", 43.995, 5000)
add("P1_K_E1", "Moron", "Epic", 18.85, 1, "loc1_key49", 34.996, 8000)
add("P1_K_L1", "Heka", "Legendary", 31.9, 1, "loc1_key49", 14.998, 15000)
add("P1_K_L2", "Monster", "Legendary", 50.75, 1, "loc1_key49", 5.009, 25000)
add("P1_K_M1", "Freya", "Mythic", 72.5, 1, "loc1_key49", 1.002, 50000)

----------------------------------------------------------------------
-- Loc2 coin 3.75M
----------------------------------------------------------------------
add("P2_C1", "Proteus", "Common", 4.5, 2, "loc2_3_75m", 44.995, 50_000)
add("P2_C2", "Atlas", "Common", 6.75, 2, "loc2_3_75m", 34.999, 80_000)
add("P2_R1", "Hermes", "Rare", 12, 2, "loc2_3_75m", 14, 150_000)
add("P2_E1", "Arix", "Epic", 18, 2, "loc2_3_75m", 4.87, 500_000)
add("P2_L1", "Ceres", "Legendary", 31, 2, "loc2_3_75m", 1.002, 2_000_000)
add("P2_M1", "Nereus", "Mythic", 89.9, 2, "loc2_3_75m", 0.1303, 10_000_000)

----------------------------------------------------------------------
-- Loc2 key 54
----------------------------------------------------------------------
add("P2_K_R1", "Eridan", "Rare", 50.75, 2, "loc2_key54", 43.995, 5_000_000)
add("P2_K_E1", "Calypso", "Epic", 65.25, 2, "loc2_key54", 34.996, 10_000_000)
add("P2_K_L1", "Argus", "Legendary", 100.05, 2, "loc2_key54", 14.998, 25_000_000)
add("P2_K_L2", "Nereid", "Legendary", 150.8, 2, "loc2_key54", 5.009, 50_000_000)
add("P2_K_M1", "Triton", "Mythic", 290, 2, "loc2_key54", 1.002, 100_000_000)

----------------------------------------------------------------------
-- API
----------------------------------------------------------------------

function PetConfig.Get(id: string): PetDef?
	return PetConfig.Pets[id]
end

--- Pure Мощь xN
function PetConfig.GetPowerMult(def: PetDef): number
	return def.powerMult or 1
end

--- Compatibility for UI that still shows +% (not used in combat math)
function PetConfig.GetPowerPctDisplay(def: PetDef): number
	return (PetConfig.GetPowerMult(def) - 1) * 100
end

function PetConfig.GetPool(casePool: string): { PetDef }
	local out = {}
	for _, def in PetConfig.Pets do
		if def.casePool == casePool then
			table.insert(out, def)
		end
	end
	table.sort(out, function(a, b)
		return (a.caseWeight or 0) > (b.caseWeight or 0)
	end)
	return out
end

function PetConfig.GetPoolForLocation(locationId: number): { PetDef }
	local poolId = PetConfig.DefaultPoolByLocation[locationId] or "loc1_500"
	return PetConfig.GetPool(poolId)
end

function PetConfig.RollFromPool(casePool: string): string
	local pool = {}
	for id, def in PetConfig.Pets do
		if def.casePool == casePool then
			table.insert(pool, { id = id, weight = def.caseWeight or 1 })
		end
	end
	if #pool == 0 then
		return "P1_C1"
	end
	local total = 0
	for _, p in pool do
		total += p.weight
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

function PetConfig.RollForLocation(locationId: number): string
	local poolId = PetConfig.DefaultPoolByLocation[locationId] or "loc1_500"
	return PetConfig.RollFromPool(poolId)
end

function PetConfig.GetCaseCosts(casePool: string): (number, number)
	local c = PetConfig.CasePools[casePool]
	if not c then
		return 500, 0
	end
	return c.coinCost or 0, c.keyCost or 0
end

function PetConfig.GetDefaultPoolId(locationId: number): string
	return PetConfig.DefaultPoolByLocation[locationId] or "loc1_500"
end

return PetConfig
