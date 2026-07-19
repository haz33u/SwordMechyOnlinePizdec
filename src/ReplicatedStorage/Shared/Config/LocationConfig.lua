--!strict
--[[
	Gameplay data per location (spawn tables).
	Mob stats live in MobConfig.
	World positions: WorldConfig (math) + Studio map (PlayerSpawn).
]]

local WorldConfig = require(script.Parent.WorldConfig)

export type MobSpawn = {
	mobId: string,
	count: number,
	zone: string, -- A | B | C | Boss | Debug
}

export type LocationDef = {
	id: number,
	name: string,
	theme: string,
	unlockPower: number,
	unlockRebirth: number?,
	travelCostCoins: number?,
	coinMult: number,
	powerMult: number,
	status: string,
	mobs: { MobSpawn },
	bossId: string?,
	debugMobs: { MobSpawn }?, -- always available for tests
	questIds: { string },
	caseId: string?,
}

local MOB_OVERRIDES: {
	[number]: {
		mobs: { MobSpawn },
		bossId: string?,
		debugMobs: { MobSpawn }?,
		questIds: { string },
		caseId: string?,
	},
} = {
	----------------------------------------------------------------------
	-- LOC 1 — Тёмный лес (full roster)
	----------------------------------------------------------------------
	[1] = {
		-- Counts by tier: T1=13 · T2=15 · T3=11 · T4=9
		-- Dump-aligned roster (counts for playtest density, all feature tiers)
		mobs = {
			-- T1 simple — Goblin (dump 1K/200)
			{ mobId = "L1_Slime", count = 10, zone = "A" },
			-- T2 medium — Skeleton / Wolf
			{ mobId = "L1_Skeleton", count = 8, zone = "B" },
			{ mobId = "L1_Wolf", count = 7, zone = "B" },
			-- T3 hard — Warrior (dump 5.68M/100K)
			{ mobId = "L1_GoblinWarrior", count = 6, zone = "C" },
			-- T4 elite — Scout 300K + Elite (secret 0.0001%)
			{ mobId = "L1_Knight", count = 4, zone = "D" },
			{ mobId = "L1_Elite", count = 3, zone = "D" },
		},
		bossId = "L1_Boss",
		-- Dummy only via DebugSpawnDummy remote — not auto-spawn
		debugMobs = {},
		questIds = {
			"Q1_Slimes",
			"Q1_Skeletons",
			"Q2_Wolves",
			"Q2_GoblinWarriors",
			"Q3_Boss",
			"Q4_Power",
			"Q5_Rebirth",
		},
		caseId = "Case_Loc1",
	},

	----------------------------------------------------------------------
	-- LOC 2–3 stubs
	----------------------------------------------------------------------
	[2] = {
		-- Dump: Sailor / Gunner / Captain (no Admiral in screenshots)
		-- Dump: Sailor / Gunner / Captain only
		mobs = {
			{ mobId = "L2_Sailor", count = 10, zone = "A" },
			{ mobId = "L2_Gunner", count = 6, zone = "B" },
			{ mobId = "L2_Captain", count = 2, zone = "C" },
		},
		bossId = nil,
		debugMobs = {},
		questIds = { "Q_L2_Intro" },
		caseId = "Case_Loc2",
	},
	[3] = {
		-- No Loc3 dump yet — empty combat
		mobs = {},
		bossId = nil,
		debugMobs = {},
		questIds = {},
		caseId = "Case_Loc3",
	},
}

local LocationConfig = {
	COUNT = #WorldConfig.Locations,
	List = {} :: { LocationDef },
}

for _, meta in WorldConfig.Locations do
	local ov = MOB_OVERRIDES[meta.id]
	local def: LocationDef = {
		id = meta.id,
		name = meta.name,
		theme = meta.theme,
		unlockPower = meta.unlockPower,
		unlockRebirth = meta.unlockRebirth or 0,
		travelCostCoins = meta.travelCostCoins or 0,
		coinMult = meta.coinMult,
		powerMult = meta.powerMult,
		status = meta.status,
		mobs = ov and ov.mobs or {},
		bossId = ov and ov.bossId or nil,
		debugMobs = ov and ov.debugMobs or {},
		questIds = ov and ov.questIds or {},
		caseId = ov and ov.caseId or ("Case_Loc" .. meta.id),
	}
	table.insert(LocationConfig.List, def)
end

function LocationConfig.Get(id: number): LocationDef?
	return LocationConfig.List[id]
end

function LocationConfig.GetAll(): { LocationDef }
	return LocationConfig.List
end

return LocationConfig
