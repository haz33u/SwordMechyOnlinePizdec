--!strict
--[[
	SPARE / TEST mobs — NOT in active spawn roster.
	Kept for debug tools, old quests, or temporary tests.
	Do not require this from CombatService LocationConfig.

	To use: temporarily copy a def into MobConfig.Mobs or spawn via custom debug.
]]

local Spare = {
	-- Was Loc1 T1 filler (not on dump screenshots as separate type)
	L1_GoblinScout = {
		id = "L1_GoblinScout",
		name = "Goblin Runner",
		location = 1,
		tier = "simple",
		defaultZone = "A",
		hp = 2_500,
		powerReward = 8,
		coinReward = 350,
		weaponDropChance = 1,
		weaponDropScale = 1,
		weaponPool = {},
		respawnSeconds = 3.5,
		visual = { preferredModelName = "L1_GoblinScout", color = "#52BE80", scale = 1.05, shape = "humanoid" },
		description = "SPARE — not dump roster",
	},

	-- Training bag (still spawnable via DebugSpawnDummy if wired to MobConfig)
	-- Prefer keeping DEBUG_Dummy in main MobConfig for remote; this is a copy reference.
	NOTE = "DEBUG_Dummy stays in MobConfig for DebugSpawnDummy; not in world spawn tables.",
}

return Spare
