--!strict

export type RelicDef = {
	id: string,
	name: string,
	rarity: string,
	powerPct: number,
	damagePct: number,
	source: string, -- easy | medium | hard
}

local RelicConfig = {
	Relics = {
		R_E1 = { id = "R_E1", name = "Novice Ring", rarity = "Common", powerPct = 15, damagePct = 0, source = "easy" },
		R_E2 = { id = "R_E2", name = "Forest Amulet", rarity = "Uncommon", powerPct = 40, damagePct = 20, source = "easy" },
		R_M1 = { id = "R_M1", name = "Power Earring", rarity = "Rare", powerPct = 100, damagePct = 50, source = "medium" },
		R_M2 = { id = "R_M2", name = "Strike Relic", rarity = "Epic", powerPct = 150, damagePct = 100, source = "medium" },
		R_H1 = { id = "R_H1", name = "Mana Ring", rarity = "Legendary", powerPct = 250, damagePct = 150, source = "hard" },
	} :: { [string]: RelicDef },

	STAR_BONUS = 0.20, -- +20% of base per star
	MAX_STARS = 5,
	UPGRADE_COST_BASE = 1_000,
}

function RelicConfig.Get(id: string): RelicDef?
	return RelicConfig.Relics[id]
end

function RelicConfig.Roll(source: string): string
	local pool = {}
	for id, def in RelicConfig.Relics do
		if def.source == source then
			table.insert(pool, id)
		end
	end
	if #pool == 0 then
		return "R_E1"
	end
	return pool[math.random(1, #pool)]
end

return RelicConfig
