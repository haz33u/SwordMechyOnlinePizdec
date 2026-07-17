--!strict

export type WeaponDef = {
	id: string,
	name: string,
	rarity: string, -- Common Uncommon Rare Epic Legendary Mythic Secret
	powerMult: number,
	location: number,
	sellPrice: number,
}

local WeaponConfig = {
	RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },

	Weapons = {
		-- Loc1
		W1_C1 = { id = "W1_C1", name = "Ржавый клинок", rarity = "Common", powerMult = 1.05, location = 1, sellPrice = 10 },
		W1_C2 = { id = "W1_C2", name = "Дубовый меч", rarity = "Common", powerMult = 1.12, location = 1, sellPrice = 20 },
		W1_U1 = { id = "W1_U1", name = "Клинок разбойника", rarity = "Uncommon", powerMult = 1.25, location = 1, sellPrice = 60 },
		W1_U2 = { id = "W1_U2", name = "Серебряный тесак", rarity = "Uncommon", powerMult = 1.40, location = 1, sellPrice = 100 },
		W1_R1 = { id = "W1_R1", name = "Меч теней", rarity = "Rare", powerMult = 1.75, location = 1, sellPrice = 350 },
		W1_R2 = { id = "W1_R2", name = "Клык волка", rarity = "Rare", powerMult = 2.10, location = 1, sellPrice = 600 },
		W1_E1 = { id = "W1_E1", name = "Клинок Хранителя", rarity = "Epic", powerMult = 3.00, location = 1, sellPrice = 2_000 },
		W1_L1 = { id = "W1_L1", name = "Перворождённый", rarity = "Legendary", powerMult = 5.00, location = 1, sellPrice = 8_000 },

		-- Loc2
		W2_C1 = { id = "W2_C1", name = "Абордажная сабля", rarity = "Common", powerMult = 2.00, location = 2, sellPrice = 80 },
		W2_U1 = { id = "W2_U1", name = "Корсарский клинок", rarity = "Uncommon", powerMult = 2.80, location = 2, sellPrice = 250 },
		W2_R1 = { id = "W2_R1", name = "Акула-резак", rarity = "Rare", powerMult = 4.00, location = 2, sellPrice = 1_200 },
		W2_E1 = { id = "W2_E1", name = "Сабля адмирала", rarity = "Epic", powerMult = 6.50, location = 2, sellPrice = 5_000 },
		W2_L1 = { id = "W2_L1", name = "Чёрный флаг", rarity = "Legendary", powerMult = 10.0, location = 2, sellPrice = 20_000 },

		-- Loc3
		W3_U1 = { id = "W3_U1", name = "Катана ученика", rarity = "Uncommon", powerMult = 8.0, location = 3, sellPrice = 800 },
		W3_R1 = { id = "W3_R1", name = "Катана тени", rarity = "Rare", powerMult = 12.0, location = 3, sellPrice = 3_000 },
	} :: { [string]: WeaponDef },

	-- starter
	STARTER_WEAPON = "W1_C1",
}

function WeaponConfig.Get(id: string): WeaponDef?
	return WeaponConfig.Weapons[id]
end

return WeaponConfig
