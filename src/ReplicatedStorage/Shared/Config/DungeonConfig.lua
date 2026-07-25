--!strict
--[[
	Dungeon skeleton: Easy / Medium / Hard.
	Gates on a simple timer. Rewards: coins, relics, keys.
	Pet slots: ProgressConfig.PetSlotsFromDungeon (not every-N spam).
]]

export type DungeonTier = {
	id: string,
	name: string,
	durationSeconds: number,
	hpMult: number,
	coinReward: number,
	powerReward: number,
	relicSource: string,
	petSlotEveryStages: number?, -- deprecated / ignored
	gateSeconds: number, -- reopen cooldown
}

local DungeonConfig = {
	Tiers = {
		easy = {
			id = "easy",
			name = "Easy Dungeon",
			durationSeconds = 45,
			hpMult = 5,
			coinReward = 400,
			powerReward = 50,
			relicSource = "easy",
			petSlotEveryStages = nil,
			gateSeconds = 60,
		},
		medium = {
			id = "medium",
			name = "Medium Dungeon",
			durationSeconds = 75,
			hpMult = 25,
			coinReward = 2_000,
			powerReward = 250,
			relicSource = "medium",
			petSlotEveryStages = nil,
			gateSeconds = 90,
		},
		hard = {
			id = "hard",
			name = "Hard Dungeon",
			durationSeconds = 120,
			hpMult = 100,
			coinReward = 8_000,
			powerReward = 1_000,
			relicSource = "hard",
			petSlotEveryStages = nil,
			gateSeconds = 120,
		},
	} :: { [string]: DungeonTier },

	Floors = {
		{ floor = 1, name = "Floor 1: Grasslands Tower", mobsToKill = 5, timeLimitSeconds = 120, coinReward = 1_000, powerReward = 100 },
		{ floor = 2, name = "Floor 2: Goblin Keep", mobsToKill = 8, timeLimitSeconds = 120, coinReward = 5_000, powerReward = 300 },
		{ floor = 3, name = "Floor 3: Pirate Cavern", mobsToKill = 10, timeLimitSeconds = 120, coinReward = 25_000, powerReward = 1_000 },
		{ floor = 4, name = "Floor 4: Sea Fortress", mobsToKill = 12, timeLimitSeconds = 120, coinReward = 120_000, powerReward = 4_000 },
		{ floor = 5, name = "Floor 5: Shinobi Pagoda", mobsToKill = 15, timeLimitSeconds = 120, coinReward = 600_000, powerReward = 15_000 },
		{ floor = 6, name = "Floor 6: Shadow Temple", mobsToKill = 18, timeLimitSeconds = 120, coinReward = 3_000_000, powerReward = 60_000 },
		{ floor = 7, name = "Floor 7: Frost Citadel", mobsToKill = 20, timeLimitSeconds = 120, coinReward = 15_000_000, powerReward = 250_000 },
		{ floor = 8, name = "Floor 8: Glacier Spire", mobsToKill = 22, timeLimitSeconds = 120, coinReward = 80_000_000, powerReward = 1_000_000 },
		{ floor = 9, name = "Floor 9: Obsidian Gate", mobsToKill = 25, timeLimitSeconds = 120, coinReward = 400_000_000, powerReward = 5_000_000 },
		{ floor = 10, name = "Floor 10: Aincrad Peak Boss", mobsToKill = 30, timeLimitSeconds = 180, coinReward = 2_500_000_000, powerReward = 25_000_000 },
	},
}

return DungeonConfig
