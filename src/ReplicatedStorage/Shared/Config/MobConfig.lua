--!strict

export type MobDef = {
	id: string,
	name: string,
	hp: number,
	powerReward: number,
	coinReward: number,
	weaponDropChance: number, -- 0..1
	weaponPool: { string }, -- weapon ids
	isBoss: boolean?,
	respawnSeconds: number,
}

local MobConfig = {
	Mobs = {
		-- Location 1
		L1_Slime = {
			id = "L1_Slime",
			name = "Теневой слизень",
			hp = 40,
			powerReward = 1,
			coinReward = 3,
			weaponDropChance = 0.03,
			weaponPool = { "W1_C1", "W1_C2" },
			respawnSeconds = 3,
		},
		L1_Skeleton = {
			id = "L1_Skeleton",
			name = "Лесной скелет",
			hp = 120,
			powerReward = 3,
			coinReward = 6,
			weaponDropChance = 0.05,
			weaponPool = { "W1_C2", "W1_U1" },
			respawnSeconds = 3.5,
		},
		L1_Wolf = {
			id = "L1_Wolf",
			name = "Тёмный волк",
			hp = 350,
			powerReward = 8,
			coinReward = 14,
			weaponDropChance = 0.07,
			weaponPool = { "W1_U1", "W1_U2", "W1_R1" },
			respawnSeconds = 4,
		},
		L1_Knight = {
			id = "L1_Knight",
			name = "Проклятый рыцарь",
			hp = 1_200,
			powerReward = 25,
			coinReward = 40,
			weaponDropChance = 0.12,
			weaponPool = { "W1_R1", "W1_R2" },
			respawnSeconds = 8,
		},
		L1_Boss = {
			id = "L1_Boss",
			name = "Хранитель леса",
			hp = 8_000,
			powerReward = 200,
			coinReward = 300,
			weaponDropChance = 0.40,
			weaponPool = { "W1_R2", "W1_E1", "W1_L1" },
			isBoss = true,
			respawnSeconds = 45,
		},

		-- Location 2 stubs
		L2_Sailor = {
			id = "L2_Sailor",
			name = "Матрос",
			hp = 2_500,
			powerReward = 40,
			coinReward = 60,
			weaponDropChance = 0.08,
			weaponPool = { "W2_C1", "W2_U1" },
			respawnSeconds = 4,
		},
		L2_Captain = {
			id = "L2_Captain",
			name = "Капитан",
			hp = 8_000,
			powerReward = 100,
			coinReward = 150,
			weaponDropChance = 0.12,
			weaponPool = { "W2_R1", "W2_E1" },
			respawnSeconds = 10,
		},
		L2_Admiral = {
			id = "L2_Admiral",
			name = "Адмирал",
			hp = 40_000,
			powerReward = 600,
			coinReward = 800,
			weaponDropChance = 0.35,
			weaponPool = { "W2_E1", "W2_L1" },
			isBoss = true,
			respawnSeconds = 60,
		},

		L3_Samurai = {
			id = "L3_Samurai",
			name = "Самурай",
			hp = 15_000,
			powerReward = 180,
			coinReward = 250,
			weaponDropChance = 0.10,
			weaponPool = { "W3_U1", "W3_R1" },
			respawnSeconds = 5,
		},
	} :: { [string]: MobDef },
}

function MobConfig.Get(id: string): MobDef?
	return MobConfig.Mobs[id]
end

return MobConfig
