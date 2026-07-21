--!strict
--[[
	Gameplay data per location (spawn TABLES only: who / how many / zone id).

	WHERE mobs stand in the world:
	  Primary  → Studio markers under LocXX.MobSpawns (absolute positions)
	  Fallback → WorldConfig.GetZonePoint (city-scale fractions; Loc1 needs markers)

	Mob stats live in MobConfig. Island meta (name/theme) in WorldConfig.
]]

local WorldConfig = require(script.Parent.WorldConfig)

export type MobSpawn = {
	mobId: string,
	count: number,
	-- Camp / ring id used by markers + fallback math:
	-- A | B | C | D | Boss | Debug
	zone: string,
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
	debugMobs: { MobSpawn }?, -- empty ok; optional test dummies
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
	-- LOC 1 — Goblin city: 4 camps (tiers) + boss arena at the far end
	-- Positions are NOT here — place via tools/studio_loc1_level_layout.lua
	-- on Loc01.Art scale (hundreds of studs between camps).
	-- Boss is NOT a normal pack mob: bossId + zone "Boss".
	----------------------------------------------------------------------
	[1] = {
		mobs = {
			{ mobId = "L1_Goblin", count = 12, zone = "A" }, -- Camp A entrance
			{ mobId = "L1_DarkGoblin", count = 8, zone = "B" }, -- Camp B mid city
			{ mobId = "L1_GoblinWarrior", count = 5, zone = "C" }, -- Camp C hard
			{ mobId = "L1_GoblinScout", count = 4, zone = "D" }, -- Camp D elite gate
		},
		bossId = "L1_Boss",
		debugMobs = {},
		questIds = {
			"Q1_Slimes", -- legacy id → Goblin (display/target in QuestConfig)
			"Q1_Skeletons", -- legacy id → Dark Goblin
			"Q2_Wolves", -- legacy id → Goblin Warrior
			"Q2_GoblinWarriors", -- → Goblin Scout
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
		-- Approx T-scale after Loc2 B (docs/SCALE_LOCS.md)
		mobs = {
			{ mobId = "L3_Scout", count = 12, zone = "A" },
			{ mobId = "L3_Adept", count = 8, zone = "B" },
			{ mobId = "L3_Warden", count = 5, zone = "C" },
			{ mobId = "L3_Elite", count = 4, zone = "D" },
		},
		bossId = "L3_Boss",
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
