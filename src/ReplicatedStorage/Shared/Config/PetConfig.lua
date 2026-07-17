--!strict

export type PetDef = {
	id: string,
	name: string,
	rarity: string,
	powerPct: number, -- +% power
	coinPct: number,
	speedPct: number,
	location: number,
}

local PetConfig = {
	Pets = {
		P1_C1 = { id = "P1_C1", name = "Слизнёнок", rarity = "Common", powerPct = 5, coinPct = 5, speedPct = 0, location = 1 },
		P1_U1 = { id = "P1_U1", name = "Волчонок", rarity = "Uncommon", powerPct = 12, coinPct = 8, speedPct = 0, location = 1 },
		P1_R1 = { id = "P1_R1", name = "Теневой кот", rarity = "Rare", powerPct = 25, coinPct = 15, speedPct = 5, location = 1 },
		P1_E1 = { id = "P1_E1", name = "Дух Хранителя", rarity = "Epic", powerPct = 50, coinPct = 30, speedPct = 8, location = 1 },
		P1_L1 = { id = "P1_L1", name = "Лесной мифик", rarity = "Legendary", powerPct = 90, coinPct = 50, speedPct = 12, location = 1 },
		P1_M1 = { id = "P1_M1", name = "Мифик тени", rarity = "Mythic", powerPct = 160, coinPct = 80, speedPct = 18, location = 1 },

		P2_C1 = { id = "P2_C1", name = "Краб", rarity = "Common", powerPct = 10, coinPct = 10, speedPct = 0, location = 2 },
		P2_L1 = { id = "P2_L1", name = "Попугай капитана", rarity = "Legendary", powerPct = 120, coinPct = 70, speedPct = 15, location = 2 },
	} :: { [string]: PetDef },

	-- case drop weights by rarity for loc cases
	CaseWeights = {
		Common = 70,
		Uncommon = 18,
		Rare = 8,
		Epic = 3,
		Legendary = 0.9,
		Mythic = 0.1,
	},

	OPEN_COST = 0, -- free open from kill-drop keys later; skeleton free
	FEED_BASE_COST = 100,
	FEED_GROWTH = 1.25,
	MAX_LEVEL = 30,
	LEVEL_POWER_PER = 0.02, -- +2% of base pet power per level
}

function PetConfig.Get(id: string): PetDef?
	return PetConfig.Pets[id]
end

function PetConfig.RollForLocation(locationId: number): string
	local pool = {}
	for id, def in PetConfig.Pets do
		if def.location == locationId then
			local w = PetConfig.CaseWeights[def.rarity] or 1
			table.insert(pool, { id = id, weight = w })
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

return PetConfig
