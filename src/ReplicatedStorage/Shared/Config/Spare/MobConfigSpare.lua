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
		description = "SPARE — not Loc1 world roster (4 goblins + boss only)",
	},

	-- Removed from Loc1 world spawn (kept for art / old markers / tests)
	L1_Wolf = {
		id = "L1_Wolf",
		name = "Wolf",
		location = 1,
		tier = "medium",
		defaultZone = "B",
		hp = 12_000,
		powerReward = 20,
		coinReward = 1_200,
		weaponDropChance = 1,
		weaponDropScale = 1,
		weaponPool = {},
		respawnSeconds = 5,
		visual = { preferredModelName = "L1_Wolf", color = "#85929E", scale = 1.15, shape = "quad" },
		description = "SPARE — Loc1 trimmed to 4 mobs + boss",
	},
	L1_Elite = {
		id = "L1_Elite",
		name = "Forest Warden",
		location = 1,
		tier = "elite",
		defaultZone = "D",
		hp = 450_000,
		powerReward = 160,
		coinReward = 18_000,
		weaponDropChance = 1,
		weaponDropScale = 1,
		weaponPool = {},
		respawnSeconds = 10,
		visual = { preferredModelName = "L1_Elite", color = "#6C3483", scale = 1.45, shape = "humanoid" },
		description = "SPARE — Loc1 trimmed to 4 mobs + boss",
	},

	NOTE = "DEBUG_Dummy stays in MobConfig for DebugSpawnDummy; not in world spawn tables.",
}

return Spare
