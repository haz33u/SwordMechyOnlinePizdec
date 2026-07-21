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
	-- LOC 1 — Starter Village: exactly 4 combat mobs + boss at the end
	-- Boss is NOT a normal pack mob: bossId + zone "Boss" (gate / portal area later)
	----------------------------------------------------------------------
	[1] = {
		mobs = {
			{ mobId = "L1_Goblin", count = 12, zone = "A" },
			{ mobId = "L1_DarkGoblin", count = 8, zone = "B" },
			{ mobId = "L1_GoblinWarrior", count = 5, zone = "C" },
			{ mobId = "L1_GoblinScout", count = 4, zone = "D" },
		},
		bossId = "L1_Boss",
		debugMobs = {},
		questIds = {
			"Q1_Slimes", -- T1 Goblin (quest id legacy)
			"Q1_Skeletons", -- T2 Dark Goblin
			"Q2_Wolves", -- T3 Warrior
			"Q2_GoblinWarriors", -- T4 Scout
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
	[4] = {
		mobs = {},
		bossId = nil,
		debugMobs = {},
		questIds = {},
		caseId = "Case_Loc4",
	},
}

local LocationConfig = {
	COUNT = #WorldConfig.Locations,
	List = {} :: { LocationDef },
	ById = {} :: { [number]: LocationDef },
}

for _, meta in WorldConfig.Locations do
	local ov = MOB_OVERRIDES[meta.id]
	local def: LocationDef = {
		id = meta.id,
		name = meta.name,
		theme = meta.theme,
		unlockPower = meta.unlockPower,
		unlockRebirth = meta.unlockRebirth,
		travelCostCoins = meta.travelCostCoins,
		coinMult = meta.coinMult,
		powerMult = meta.powerMult,
		status = meta.status,
		mobs = if ov then ov.mobs else {},
		bossId = if ov then ov.bossId else nil,
		debugMobs = if ov and ov.debugMobs then ov.debugMobs else {},
		questIds = if ov then ov.questIds else {},
		caseId = if ov and ov.caseId then ov.caseId else ("Case_Loc" .. tostring(meta.id)),
	}
	table.insert(LocationConfig.List, def)
	LocationConfig.ById[def.id] = def
end

function LocationConfig.Get(id: number): LocationDef?
	return LocationConfig.ById[id]
end

function LocationConfig.GetAll(): { LocationDef }
	return LocationConfig.List
end

return LocationConfig
