--!strict
--[[
	SPARE / TEST mobs — NOT in active spawn roster.
	Kept for debug tools, old quests, or temporary tests.
	Do not require this from CombatService LocationConfig.

	To use: temporarily copy a def into MobConfig.Mobs or spawn via custom debug.
]]

local Spare = {
	-- Old runner filler (L1_GoblinScout is now active T4 elite in MobConfig)
	L1_GoblinRunner = {
		id = "L1_GoblinRunner",
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
		visual = { preferredModelName = "L1_GoblinRunner", color = "#52BE80", scale = 1.05, shape = "humanoid" },
		description = "SPARE — not world roster",
	},
	-- Legacy ids (pre-rename) for reference only
	L1_Slime = {
		id = "L1_Slime",
		name = "Goblin (legacy id)",
		location = 1,
		tier = "simple",
		defaultZone = "A",
		hp = 1_000,
		powerReward = 5,
		coinReward = 200,
		weaponDropChance = 1,
		weaponPool = {},
		respawnSeconds = 3,
		description = "LEGACY — use L1_Goblin (MobConfig.ResolveId)",
	},
	L1_Skeleton = {
		id = "L1_Skeleton",
		name = "Dark Goblin (legacy id)",
		location = 1,
		tier = "medium",
		defaultZone = "B",
		hp = 8_000,
		powerReward = 15,
		coinReward = 800,
		weaponDropChance = 1,
		weaponPool = {},
		respawnSeconds = 4,
		description = "LEGACY — use L1_DarkGoblin",
	},
	L1_Knight = {
		id = "L1_Knight",
		name = "Goblin Scout (legacy id)",
		location = 1,
		tier = "elite",
		defaultZone = "D",
		hp = 300_000,
		powerReward = 120,
		coinReward = 12_500,
		weaponDropChance = 1,
		weaponPool = {},
		respawnSeconds = 8,
		description = "LEGACY — use L1_GoblinScout",
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
