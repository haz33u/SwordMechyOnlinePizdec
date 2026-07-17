--!strict
--[[
	Dungeon skeleton: Easy / Medium / Hard.
	Gates on a simple timer. Rewards: coins, relics, pet slots (milestones).
]]

export type DungeonTier = {
	id: string,
	name: string,
	durationSeconds: number,
	hpMult: number,
	coinReward: number,
	powerReward: number,
	relicSource: string,
	petSlotEveryStages: number?, -- grant +1 slot every N clears (capped)
	gateSeconds: number, -- reopen cooldown
}

local DungeonConfig = {
	Tiers = {
		easy = {
			id = "easy",
			name = "Лёгкое подземелье",
			durationSeconds = 45,
			hpMult = 5,
			coinReward = 400,
			powerReward = 50,
			relicSource = "easy",
			petSlotEveryStages = 5,
			gateSeconds = 60,
		},
		medium = {
			id = "medium",
			name = "Среднее подземелье",
			durationSeconds = 75,
			hpMult = 25,
			coinReward = 2_000,
			powerReward = 250,
			relicSource = "medium",
			petSlotEveryStages = 3,
			gateSeconds = 90,
		},
		hard = {
			id = "hard",
			name = "Сложное подземелье",
			durationSeconds = 120,
			hpMult = 100,
			coinReward = 8_000,
			powerReward = 1_000,
			relicSource = "hard",
			petSlotEveryStages = 2,
			gateSeconds = 120,
		},
	} :: { [string]: DungeonTier },
}

return DungeonConfig
