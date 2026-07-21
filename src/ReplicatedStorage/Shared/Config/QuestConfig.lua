--!strict

export type QuestDef = {
	id: string,
	name: string,
	description: string,
	type: string, -- kill | power | rebirth | boss | dungeon | clicks
	targetId: string?, -- mob id, dungeon tier, or "any"
	amount: number,
	rewards: {
		coins: number?,
		power: number?,
		powerPct: number?,
		weaponId: string?,
		petSlot: number?,
		petKeys: number?,
		auraKeys: number?,
		unlockLocation: number?,
		samCpsTier: number?, -- set profile.samClickTier to this on claim
	},
	location: number,
	chain: string?, -- "sam"
	chainIndex: number?, -- 1..21
	npc: string?,
}

local QuestConfig = {
	SAM_CHAIN = "sam",
	SAM_COUNT = 21,
	SAM_NPC = "Sam",

	-- Display click targets (step 3 = 5K, step 21 = 2B)
	SAM_CLICK_AMOUNTS = {
		1_000,
		2_500,
		5_000,
		12_000,
		28_000,
		65_000,
		150_000,
		350_000,
		800_000,
		1_800_000,
		4_000_000,
		9_000_000,
		20_000_000,
		45_000_000,
		100_000_000,
		220_000_000,
		450_000_000,
		800_000_000,
		1_200_000_000,
		1_600_000_000,
		2_000_000_000,
	} :: { number },

	SAM_COIN_REWARDS = {
		5_000,
		12_000,
		25_000,
		50_000,
		100_000,
		200_000,
		400_000,
		750_000,
		1_200_000,
		2_000_000,
		4_000_000,
		8_000_000,
		15_000_000,
		30_000_000,
		60_000_000,
		120_000_000,
		250_000_000,
		400_000_000,
		600_000_000,
		800_000_000,
		1_000_000_000,
	} :: { number },

	Quests = {
		-- Loc1: 4 goblin tiers + boss (quest *ids* kept for profile progress)
		Q1_Slimes = {
			id = "Q1_Slimes",
			name = "Goblins",
			description = "Kill 25 Goblins · reward +3% Power",
			type = "kill",
			targetId = "L1_Goblin",
			amount = 25,
			rewards = { coins = 2_000, powerPct = 3 },
			location = 1,
		},
		Q1_Skeletons = {
			id = "Q1_Skeletons",
			name = "Dark Goblins",
			description = "Kill 15 Dark Goblins · reward +3% Power",
			type = "kill",
			targetId = "L1_DarkGoblin",
			amount = 15,
			rewards = { coins = 3_000, powerPct = 3 },
			location = 1,
		},
		Q2_Wolves = {
			id = "Q2_Wolves",
			name = "Goblin Warriors",
			description = "Kill 8 Goblin Warriors · reward +3% Power",
			type = "kill",
			targetId = "L1_GoblinWarrior",
			amount = 8,
			rewards = { coins = 8_000, powerPct = 3, weaponId = "wooden_mace" },
			location = 1,
		},
		Q2_GoblinWarriors = {
			id = "Q2_GoblinWarriors",
			name = "Goblin Scouts",
			description = "Kill 5 Goblin Scouts · reward +3% Power",
			type = "kill",
			targetId = "L1_GoblinScout",
			amount = 5,
			rewards = { coins = 12_000, powerPct = 3 },
			location = 1,
		},
		Q3_Boss = {
			id = "Q3_Boss",
			name = "Forest Guardian",
			description = "Defeat the Forest Guardian at the end of Loc1 · reward +3% Power",
			type = "boss",
			targetId = "L1_Boss",
			amount = 1,
			rewards = { coins = 50_000, powerPct = 3 },
			location = 1,
		},
		Q4_Power = {
			id = "Q4_Power",
			name = "Novice Power",
			description = "Reach 200 lifetime power · reward +3% Power",
			type = "power",
			targetId = nil,
			amount = 200,
			rewards = { coins = 5_000, powerPct = 3 },
			location = 1,
		},
		Q5_Rebirth = {
			id = "Q5_Rebirth",
			name = "First Rebirth",
			description = "Complete 1 rebirth · reward +3% Power",
			type = "rebirth",
			targetId = nil,
			amount = 1,
			rewards = { coins = 10_000, powerPct = 3 },
			location = 1,
		},

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

-- Build Sam 21-chain
do
	local amounts = QuestConfig.SAM_CLICK_AMOUNTS
	local coins = QuestConfig.SAM_COIN_REWARDS
	for i = 1, QuestConfig.SAM_COUNT do
		local id = string.format("Q_SAM_%02d", i)
		local need = amounts[i] or 1000
		local coinR = coins[i] or 5_000
		local powerPct = if i % 5 == 0 then 1 else nil
		local auraKeys = if i == 21 then 2 else nil
		local descExtra = if i == 21 then " · MASTER 20 CPS" else " · raises attack speed (CPS)"
		QuestConfig.Quests[id] = {
			id = id,
			name = "Click.. Click.. More Clicks!",
			description = string.format(
				"Sam (%d/21): land %s clicks%s",
				i,
				tostring(need),
				descExtra
			),
			type = "clicks",
			targetId = nil,
			amount = need,
			rewards = {
				coins = coinR,
				powerPct = powerPct,
				auraKeys = auraKeys,
				samCpsTier = i,
			},
			location = 2,
			chain = QuestConfig.SAM_CHAIN,
			chainIndex = i,
			npc = QuestConfig.SAM_NPC,
		}
	end
end

function QuestConfig.Get(id: string): QuestDef?
	return QuestConfig.Quests[id]
end

function QuestConfig.SamId(index: number): string
	return string.format("Q_SAM_%02d", index)
end

--- First unclaimed Sam quest (sequential). Nil if chain done or Loc2 locked.
function QuestConfig.GetActiveSamQuestId(profile: any): string?
	if not profile then
		return nil
	end
	local unlocked = false
	for _, loc in profile.locationsUnlocked or {} do
		if loc >= 2 then
			unlocked = true
			break
		end
	end
	if not unlocked and (profile.currentLocation or 1) < 2 then
		return nil
	end
	-- also allow if Loc2 unlocked via gate even if current is 1
	if not unlocked then
		return nil
	end
	for i = 1, QuestConfig.SAM_COUNT do
		local id = QuestConfig.SamId(i)
		local state = profile.quests and profile.quests[id]
		if state and not state.claimed then
			return id
		end
	end
	return nil
end

function QuestConfig.GetSamProgress(profile: any): (number, number)
	local claimed = 0
	for i = 1, QuestConfig.SAM_COUNT do
		local id = QuestConfig.SamId(i)
		local state = profile.quests and profile.quests[id]
		if state and state.claimed then
			claimed += 1
		end
	end
	return claimed, QuestConfig.SAM_COUNT
end

return QuestConfig
