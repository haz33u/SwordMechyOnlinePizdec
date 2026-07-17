--!strict

export type AuraDef = {
	id: string,
	name: string,
	rarity: string,
	powerPct: number,
	damagePct: number,
	coinPct: number,
}

local AuraConfig = {
	Auras = {
		A_C1 = { id = "A_C1", name = "Искра", rarity = "Common", powerPct = 5, damagePct = 0, coinPct = 0 },
		A_C2 = { id = "A_C2", name = "Листва", rarity = "Common", powerPct = 3, damagePct = 0, coinPct = 5 },
		A_U1 = { id = "A_U1", name = "Волчья дымка", rarity = "Uncommon", powerPct = 12, damagePct = 5, coinPct = 0 },
		A_R1 = { id = "A_R1", name = "Теневой круг", rarity = "Rare", powerPct = 25, damagePct = 10, coinPct = 5 },
		A_E1 = { id = "A_E1", name = "Пламя", rarity = "Epic", powerPct = 45, damagePct = 20, coinPct = 0 },
		A_L1 = { id = "A_L1", name = "Крылья Хранителя", rarity = "Legendary", powerPct = 80, damagePct = 30, coinPct = 10 },
		A_M1 = { id = "A_M1", name = "Разлом", rarity = "Mythic", powerPct = 140, damagePct = 50, coinPct = 15 },
	} :: { [string]: AuraDef },

	OPEN_COST = 500, -- coins in skeleton (later Robux shop separate)
	Weights = {
		Common = 55,
		Uncommon = 25,
		Rare = 12,
		Epic = 5,
		Legendary = 2.5,
		Mythic = 0.5,
	},
}

function AuraConfig.Get(id: string): AuraDef?
	return AuraConfig.Auras[id]
end

function AuraConfig.Roll(): string
	local pool = {}
	for id, def in AuraConfig.Auras do
		local w = AuraConfig.Weights[def.rarity] or 1
		table.insert(pool, { id = id, weight = w })
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
	return "A_C1"
end

return AuraConfig
