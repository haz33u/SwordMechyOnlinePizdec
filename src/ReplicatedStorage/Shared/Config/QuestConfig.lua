--!strict

export type QuestDef = {
	id: string,
	name: string,
	description: string,
	type: string, -- kill | power | rebirth | boss | dungeon
	targetId: string?, -- mob id, dungeon tier, or "any"
	amount: number,
	rewards: {
		coins: number?,
		power: number?,
		weaponId: string?,
		petSlot: number?, -- avoided: slots from ProgressConfig
		petKeys: number?,
		auraKeys: number?,
		unlockLocation: number?,
	},
	location: number,
}

local QuestConfig = {
	Quests = {
		-- Loc1 chain
		Q1_Slimes = {
			id = "Q1_Slimes",
			name = "Slimes",
			description = "Kill 25 shadow slimes",
			type = "kill",
			targetId = "L1_Slime",
			amount = 25,
			rewards = { coins = 100, power = 20 },
			location = 1,
		},
		Q1_GoblinScouts = {
			id = "Q1_GoblinScouts",
			name = "Scouts",
			description = "Kill 15 goblin scouts",
			type = "kill",
			targetId = "L1_GoblinScout",
			amount = 15,
			rewards = { coins = 120, power = 25 },
			location = 1,
		},
		Q2_Wolves = {
			id = "Q2_Wolves",
			name = "Wolves",
			description = "Kill 15 dark wolves",
			type = "kill",
			targetId = "L1_Wolf",
			amount = 15,
			rewards = { coins = 250, weaponId = "W1_U1" },
			location = 1,
		},
		Q2_GoblinWarriors = {
			id = "Q2_GoblinWarriors",
			name = "Warriors",
			description = "Kill 10 goblin warriors",
			type = "kill",
			targetId = "L1_GoblinWarrior",
			amount = 10,
			rewards = { coins = 300, power = 40 },
			location = 1,
		},
		Q3_Boss = {
			id = "Q3_Boss",
			name = "Guardian",
			description = "Defeat the Forest Guardian",
			type = "boss",
			targetId = "L1_Boss",
			amount = 1,
			rewards = { coins = 500, power = 100 },
			location = 1,
		},
		Q4_Power = {
			id = "Q4_Power",
			name = "Novice Power",
			description = "Reach 200 lifetime power",
			type = "power",
			targetId = nil,
			amount = 200,
			rewards = { coins = 300 },
			location = 1,
		},
		Q5_Rebirth = {
			id = "Q5_Rebirth",
			name = "First Rebirth",
			description = "Complete 1 rebirth (pet slot at R2 via progress, not this reward)",
			type = "rebirth",
			targetId = nil,
			amount = 1,
			rewards = { coins = 500, unlockLocation = 2 },
			location = 1,
		},

		-- Dungeon track (slot at easy×5 via ProgressConfig; quest = coins + keys)
		Q_D_Easy_Slots = {
			id = "Q_D_Easy_Slots",
			name = "Dungeon practice",
			description = "Clear easy dungeon 5 times → +1 pet slot (6th)",
			type = "dungeon",
			targetId = "easy",
			amount = 5,
			rewards = { coins = 1_500, petKeys = 2 },
			location = 1,
		},
		Q_D_Medium_Intro = {
			id = "Q_D_Medium_Intro",
			name = "Dungeon trial",
			description = "Clear medium dungeon 3 times",
			type = "dungeon",
			targetId = "medium",
			amount = 3,
			rewards = { coins = 4_000, auraKeys = 1 },
			location = 1,
		},

		Q_L2_Intro = {
			id = "Q_L2_Intro",
			name = "Sailors",
			description = "Kill 20 sailors",
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
