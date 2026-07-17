--!strict
--[[
	Gameplay data per location (mobs, quests).
	Positions / bounds live in WorldConfig (18 islands).
]]

local WorldConfig = require(script.Parent.WorldConfig)

export type MobSpawn = {
	mobId: string,
	count: number,
	zone: string,
}

export type LocationDef = {
	id: number,
	name: string,
	theme: string,
	unlockPower: number,
	coinMult: number,
	powerMult: number,
	status: string,
	mobs: { MobSpawn },
	bossId: string?,
	questIds: { string },
	caseId: string?,
}

-- Detailed mobs only for early locs; rest get generic stubs until filled
local MOB_OVERRIDES: { [number]: { mobs: { MobSpawn }, bossId: string?, questIds: { string }, caseId: string? } } = {
	[1] = {
		mobs = {
			{ mobId = "L1_Slime", count = 12, zone = "A" },
			{ mobId = "L1_Skeleton", count = 8, zone = "B" },
			{ mobId = "L1_Wolf", count = 6, zone = "B" },
			{ mobId = "L1_Knight", count = 3, zone = "C" },
		},
		bossId = "L1_Boss",
		questIds = { "Q1_Slimes", "Q2_Wolves", "Q3_Boss", "Q4_Power", "Q5_Rebirth" },
		caseId = "Case_Loc1",
	},
	[2] = {
		mobs = {
			{ mobId = "L2_Sailor", count = 10, zone = "A" },
			{ mobId = "L2_Captain", count = 4, zone = "B" },
		},
		bossId = "L2_Admiral",
		questIds = { "Q_L2_Intro" },
		caseId = "Case_Loc2",
	},
	[3] = {
		mobs = {
			{ mobId = "L3_Samurai", count = 10, zone = "A" },
		},
		bossId = nil,
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
		coinMult = meta.coinMult,
		powerMult = meta.powerMult,
		status = meta.status,
		mobs = ov and ov.mobs or {},
		bossId = ov and ov.bossId or nil,
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
