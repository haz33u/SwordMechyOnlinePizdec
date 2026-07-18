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
}

return DungeonConfig
