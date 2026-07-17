--!strict

export type QuestDef = {
	id: string,
	name: string,
	description: string,
	type: string, -- kill | power | rebirth | boss
	targetId: string?, -- mob id or "any"
	amount: number,
	rewards: {
		coins: number?,
		power: number?,
		weaponId: string?,
		petSlot: number?,
		unlockLocation: number?,
	},
	location: number,
}

local QuestConfig = {
	Quests = {
		-- Loc1 chain
		Q1_Slimes = {
			id = "Q1_Slimes",
			name = "Слизни",
			description = "Убей 25 теневых слизней",
			type = "kill",
			targetId = "L1_Slime",
			amount = 25,
			rewards = { coins = 100, power = 20 },
			location = 1,
		},
		Q1_GoblinScouts = {
			id = "Q1_GoblinScouts",
			name = "Разведчики",
			description = "Убей 15 гоблинов-разведчиков",
			type = "kill",
			targetId = "L1_GoblinScout",
			amount = 15,
			rewards = { coins = 120, power = 25 },
			location = 1,
		},
		Q2_Wolves = {
			id = "Q2_Wolves",
			name = "Волки",
			description = "Убей 15 тёмных волков",
			type = "kill",
			targetId = "L1_Wolf",
			amount = 15,
			rewards = { coins = 250, weaponId = "W1_U1" },
			location = 1,
		},
		Q2_GoblinWarriors = {
			id = "Q2_GoblinWarriors",
			name = "Воины",
			description = "Убей 10 гоблинов-воинов",
			type = "kill",
			targetId = "L1_GoblinWarrior",
			amount = 10,
			rewards = { coins = 300, power = 40 },
			location = 1,
		},
		Q3_Boss = {
			id = "Q3_Boss",
			name = "Хранитель",
			description = "Победи Хранителя леса",
			type = "boss",
			targetId = "L1_Boss",
			amount = 1,
			rewards = { coins = 500, power = 100 },
			location = 1,
		},
		Q4_Power = {
			id = "Q4_Power",
			name = "Сила новичка",
			description = "Набери 200 lifetime power",
			type = "power",
			targetId = nil,
			amount = 200,
			rewards = { coins = 300 },
			location = 1,
		},
		Q5_Rebirth = {
			id = "Q5_Rebirth",
			name = "Первое перерождение",
			description = "Сделай 1 перерождение",
			type = "rebirth",
			targetId = nil,
			amount = 1,
			rewards = { coins = 500, unlockLocation = 2, petSlot = 1 },
			location = 1,
		},

		Q_L2_Intro = {
			id = "Q_L2_Intro",
			name = "Матросы",
			description = "Убей 20 матросов",
			type = "kill",
			targetId = "L2_Sailor",
			amount = 20,
			rewards = { coins = 1_000, power = 200 },
			location = 2,
		},
	} :: { [string]: QuestDef },
}

function QuestConfig.Get(id: string): QuestDef?
	return QuestConfig.Quests[id]
end

return QuestConfig
