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
		{ floor = 1, name = "Floor 1: Grasslands Tower", mobsToKill = 5, timeLimitSeconds = 120, coinReward = 1_000, powerReward = 100, hpScaleFactor = 1.0 },
		{ floor = 2, name = "Floor 2: Goblin Keep", mobsToKill = 8, timeLimitSeconds = 120, coinReward = 5_000, powerReward = 300, hpScaleFactor = 1.2 },
		{ floor = 3, name = "Floor 3: Pirate Cavern", mobsToKill = 10, timeLimitSeconds = 120, coinReward = 25_000, powerReward = 1_000, hpScaleFactor = 1.5 },
		{ floor = 4, name = "Floor 4: Sea Fortress", mobsToKill = 12, timeLimitSeconds = 120, coinReward = 120_000, powerReward = 4_000, hpScaleFactor = 2.0 },
		{ floor = 5, name = "Floor 5: Shinobi Pagoda", mobsToKill = 15, timeLimitSeconds = 120, coinReward = 600_000, powerReward = 15_000, hpScaleFactor = 2.8 },
		{ floor = 6, name = "Floor 6: Shadow Temple", mobsToKill = 18, timeLimitSeconds = 120, coinReward = 3_000_000, powerReward = 60_000, hpScaleFactor = 4.0 },
		{ floor = 7, name = "Floor 7: Frost Citadel", mobsToKill = 20, timeLimitSeconds = 120, coinReward = 15_000_000, powerReward = 250_000, hpScaleFactor = 6.0 },
		{ floor = 8, name = "Floor 8: Glacier Spire", mobsToKill = 22, timeLimitSeconds = 120, coinReward = 80_000_000, powerReward = 1_000_000, hpScaleFactor = 9.0 },
		{ floor = 9, name = "Floor 9: Obsidian Gate", mobsToKill = 25, timeLimitSeconds = 120, coinReward = 400_000_000, powerReward = 5_000_000, hpScaleFactor = 14.0 },
		{ floor = 10, name = "Floor 10: Aincrad Mid Boss", mobsToKill = 30, timeLimitSeconds = 180, coinReward = 2_500_000_000, powerReward = 25_000_000, hpScaleFactor = 22.0 },
		{ floor = 11, name = "Floor 11: Ash Canyon Ruins", mobsToKill = 32, timeLimitSeconds = 180, coinReward = 12_000_000_000, powerReward = 100_000_000, hpScaleFactor = 35.0 },
		{ floor = 12, name = "Floor 12: Lava Core", mobsToKill = 34, timeLimitSeconds = 180, coinReward = 60_000_000_000, powerReward = 450_000_000, hpScaleFactor = 55.0 },
		{ floor = 13, name = "Floor 13: Neon Docks Fortress", mobsToKill = 36, timeLimitSeconds = 180, coinReward = 300_000_000_000, powerReward = 2_000_000_000, hpScaleFactor = 85.0 },
		{ floor = 14, name = "Floor 14: Cyber Spire", mobsToKill = 38, timeLimitSeconds = 180, coinReward = 1_500_000_000_000, powerReward = 9_000_000_000, hpScaleFactor = 130.0 },
		{ floor = 15, name = "Floor 15: Bone Cathedral", mobsToKill = 40, timeLimitSeconds = 180, coinReward = 8_000_000_000_000, powerReward = 40_000_000_000, hpScaleFactor = 200.0 },
		{ floor = 16, name = "Floor 16: Crypt of Shadows", mobsToKill = 42, timeLimitSeconds = 180, coinReward = 40_000_000_000_000, powerReward = 180_000_000_000, hpScaleFactor = 300.0 },
		{ floor = 17, name = "Floor 17: Storm Pinnacle", mobsToKill = 44, timeLimitSeconds = 180, coinReward = 200_000_000_000_000, powerReward = 800_000_000_000, hpScaleFactor = 450.0 },
		{ floor = 18, name = "Floor 18: Lightning Peak", mobsToKill = 46, timeLimitSeconds = 180, coinReward = 1_000_000_000_000_000, powerReward = 3_500_000_000_000, hpScaleFactor = 700.0 },
		{ floor = 19, name = "Floor 19: Ruby Palace Gate", mobsToKill = 50, timeLimitSeconds = 240, coinReward = 5_000_000_000_000_000, powerReward = 15_000_000_000_000, hpScaleFactor = 1000.0 },
	},
}

function DungeonConfig.GetFloor(floorLevel: number): any
	local targetFloor = math.max(1, math.floor(floorLevel or 1))
	if targetFloor <= 19 then
		for _, f in ipairs(DungeonConfig.Floors) do
			if f.floor == targetFloor then
				return f
			end
		end
	end

	-- Dynamic scaling for floors > 19 (5% compound increase per floor beyond 19)
	local base19 = DungeonConfig.Floors[19] or DungeonConfig.Floors[#DungeonConfig.Floors]
	local extraFloors = targetFloor - 19
	local scaleFactor = (1.05) ^ extraFloors

	return {
		floor = targetFloor,
		name = string.format("Floor %d: Endless Tower (+%d%%)", targetFloor, math.floor((scaleFactor - 1) * 100)),
		mobsToKill = math.min(60, base19.mobsToKill + math.floor(extraFloors * 0.5)),
		timeLimitSeconds = 240,
		coinReward = math.floor(base19.coinReward * scaleFactor),
		powerReward = math.floor(base19.powerReward * scaleFactor),
		hpScaleFactor = base19.hpScaleFactor * scaleFactor,
	}
end

return DungeonConfig
