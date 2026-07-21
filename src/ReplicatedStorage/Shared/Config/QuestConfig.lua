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
		frostTier: number?, -- Frost case-open chain tier
		grimTier: number?, -- Grim kill-any chain tier
		luckPct: number?, -- permanent luck points
		petSlots: number?, -- +N equip pet slots (quest path)
	},
	location: number,
	chain: string?, -- "sam" | "frost"
	chainIndex: number?, -- 1..21
	npc: string?,
}

local QuestConfig = {
	SAM_CHAIN = "sam",
	SAM_COUNT = 21,
	-- Display labels (swap to real NPC names later)
	SAM_NPC = "Click Quester",
	FROST_CHAIN = "frost",
	FROST_COUNT = 21,
	FROST_NPC = "Case Quester",
	GRIM_CHAIN = "grim",
	GRIM_COUNT = 21,
	GRIM_NPC = "Power Quester",

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
		75_000_000, -- step 15 — live ref ~56M/75M
		220_000_000,
		450_000_000,
		800_000_000,
		1_200_000_000,
		1_600_000_000,
		2_000_000_000, -- step 21
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
			name = "More Clicks!",
			description = string.format(
				"Click Quester (%d/21): land %s clicks%s",
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

----------------------------------------------------------------------
-- Frost — open pet cases (any location). Step 13 = 1M (dump-like).
-- x3/x5 multi-open counts as 3/5 progress when wired.
-- Luck rises with chain; loc drop tables still tighten by location.
----------------------------------------------------------------------
QuestConfig.FROST_CASE_AMOUNTS = {
	500,
	1_500,
	3_000,
	6_000,
	10_000, -- step 5: milestone often paired with pet slot feel
	25_000,
	50_000,
	100_000,
	200_000,
	350_000,
	500_000,
	750_000,
	1_000_000, -- step 13 — ref ~1M
	2_500_000, -- step 14 — ref ~103K/2.5M
	4_000_000,
	8_000_000,
	15_000_000,
	30_000_000,
	60_000_000,
	100_000_000,
	200_000_000,
} :: { number }

QuestConfig.FROST_COIN_REWARDS = {
	2_000,
	5_000,
	10_000,
	20_000,
	40_000,
	80_000,
	150_000,
	300_000,
	600_000,
	1_200_000,
	2_500_000,
	5_000_000,
	10_000_000,
	20_000_000,
	40_000_000,
	80_000_000,
	150_000_000,
	300_000_000,
	500_000_000,
	800_000_000,
	1_200_000_000,
} :: { number }

-- Permanent luck points per claim (Formulas.GetLuck uses /100)
QuestConfig.FROST_LUCK_PCT = {
	0.5,
	0.5,
	0.5,
	0.5,
	1.0, -- 5
	0.5,
	0.5,
	1.0,
	0.5,
	1.0, -- 10
	0.5,
	1.0,
	1.0, -- 13
	1.0,
	1.5,
	1.0,
	1.5,
	1.0,
	2.0,
	1.5,
	2.0, -- 21
} :: { number }

do
	local amounts = QuestConfig.FROST_CASE_AMOUNTS
	local coins = QuestConfig.FROST_COIN_REWARDS
	local lucks = QuestConfig.FROST_LUCK_PCT
	for i = 1, QuestConfig.FROST_COUNT do
		local id = string.format("Q_FROST_%02d", i)
		local need = amounts[i] or 1000
		local coinR = coins[i] or 5_000
		local luck = lucks[i] or 0.5
		-- Step 5 = 10K opens → +1 pet equip slot (x3/x5 multi helps)
		local petSlots = if i == 5 then 1 else nil
		local extra = if i == 5
			then " · +1 pet slot"
			elseif i == 21 then " · CASE MASTER"
			else " · +luck"
		end
		QuestConfig.Quests[id] = {
			id = id,
			name = "Open Pet Cases",
			description = string.format(
				"Case Quester (%d/21): open %s pet cases (any location)%s",
				i,
				tostring(need),
				extra
			),
			type = "case_open",
			targetId = "pet", -- pet cases only
			amount = need,
			rewards = {
				coins = coinR,
				luckPct = luck,
				petSlots = petSlots,
				frostTier = i,
			},
			location = 1, -- visible from Loc1; progress on any loc
			chain = QuestConfig.FROST_CHAIN,
			chainIndex = i,
			npc = QuestConfig.FROST_NPC,
		}
	end
end

function QuestConfig.FrostId(index: number): string
	return string.format("Q_FROST_%02d", index)
end

function QuestConfig.GetActiveFrostQuestId(profile: any): string?
	if not profile or not profile.quests then
		return nil
	end
	for i = 1, QuestConfig.FROST_COUNT do
		local id = QuestConfig.FrostId(i)
		local state = profile.quests[id]
		if state and not state.claimed then
			return id
		end
	end
	return nil
end

function QuestConfig.GetFrostProgress(profile: any): (number, number)
	local claimed = 0
	for i = 1, QuestConfig.FROST_COUNT do
		local id = QuestConfig.FrostId(i)
		local state = profile.quests and profile.quests[id]
		if state and state.claimed then
			claimed += 1
		end
	end
	return claimed, QuestConfig.FROST_COUNT
end

----------------------------------------------------------------------
-- Grim — kill any mobs. Step 7 = 50K (screenshot). Rewards +% power.
-- Motivates faster respawn / Swarm anomaly / AFK farm.
----------------------------------------------------------------------
QuestConfig.GRIM_KILL_AMOUNTS = {
	1_000,
	2_500,
	5_000,
	10_000,
	20_000,
	35_000,
	50_000, -- step 7 — dump-like
	80_000,
	120_000,
	200_000,
	350_000,
	500_000,
	750_000,
	1_200_000,
	2_000_000,
	3_500_000,
	6_000_000,
	10_000_000,
	15_000_000,
	25_000_000,
	40_000_000,
} :: { number }

QuestConfig.GRIM_COIN_REWARDS = {
	3_000,
	6_000,
	12_000,
	25_000,
	50_000,
	100_000,
	200_000,
	400_000,
	800_000,
	1_500_000,
	3_000_000,
	6_000_000,
	12_000_000,
	25_000_000,
	50_000_000,
	100_000_000,
	200_000_000,
	400_000_000,
	700_000_000,
	1_000_000_000,
	1_500_000_000,
} :: { number }

-- Permanent power % (same pool as other quest powerPct)
QuestConfig.GRIM_POWER_PCT = {
	1,
	1,
	1,
	1,
	2,
	1,
	2, -- 7
	1,
	2,
	2, -- 10
	1,
	2,
	2,
	2,
	3, -- 15
	2,
	3,
	2,
	3,
	3,
	5, -- 21 mastery
} :: { number }

do
	local amounts = QuestConfig.GRIM_KILL_AMOUNTS
	local coins = QuestConfig.GRIM_COIN_REWARDS
	local powers = QuestConfig.GRIM_POWER_PCT
	for i = 1, QuestConfig.GRIM_COUNT do
		local id = string.format("Q_GRIM_%02d", i)
		local need = amounts[i] or 1000
		local coinR = coins[i] or 5_000
		local pPct = powers[i] or 1
		local extra = if i == 21 then " · SLAYER MASTER" else string.format(" · +%g%% Power", pPct)
		QuestConfig.Quests[id] = {
			id = id,
			name = "Kill Any Mobs",
			description = string.format("Power Quester (%d/21): kill %s mobs (any)%s", i, tostring(need), extra),
			type = "kill",
			targetId = "any",
			amount = need,
			rewards = {
				coins = coinR,
				powerPct = pPct,
				grimTier = i,
			},
			location = 1,
			chain = QuestConfig.GRIM_CHAIN,
			chainIndex = i,
			npc = QuestConfig.GRIM_NPC,
		}
	end
end

function QuestConfig.GrimId(index: number): string
	return string.format("Q_GRIM_%02d", index)
end

function QuestConfig.GetActiveGrimQuestId(profile: any): string?
	if not profile or not profile.quests then
		return nil
	end
	for i = 1, QuestConfig.GRIM_COUNT do
		local id = QuestConfig.GrimId(i)
		local state = profile.quests[id]
		if state and not state.claimed then
			return id
		end
	end
	return nil
end

function QuestConfig.GetGrimProgress(profile: any): (number, number)
	local claimed = 0
	for i = 1, QuestConfig.GRIM_COUNT do
		local id = QuestConfig.GrimId(i)
		local state = profile.quests and profile.quests[id]
		if state and state.claimed then
			claimed += 1
		end
	end
	return claimed, QuestConfig.GRIM_COUNT
end

return QuestConfig


