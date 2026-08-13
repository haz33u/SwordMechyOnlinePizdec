--!strict
--[[
	ACTIVE mob catalog — Loc1 + Loc2 dump roster only.
	Extras / old fillers → Config/Spare/MobConfigSpare.lua
	DEBUG_Dummy: debug remote only, not world location spawns.
]]

export type MobVisualHint = {
	preferredModelName: string?,
	color: string?,
	scale: number?,
	shape: string?,
}

export type MobDef = {
	id: string,
	name: string,
	location: number,
	tier: string,
	defaultZone: string,
	hp: number,
	powerReward: number,
	coinReward: number,
	weaponDropChance: number,
	weaponDropScale: number?,
	weaponPool: { string },
	-- exact dump % per weapon id (Loc2); if set, LootService uses this instead of rarity roll
	dropTable: { [string]: number }?,
	respawnSeconds: number,
	isBoss: boolean?,
	isDebug: boolean?,
	armorFlat: number?,
	visual: MobVisualHint?,
	description: string?,
}

local MobConfig = {
	Tiers = { "simple", "medium", "hard", "elite", "boss", "debug" },
	TierLabels = {
		simple = "Tier 1",
		medium = "Tier 2",
		hard = "Tier 3",
		elite = "Tier 4",
		boss = "Boss",
		debug = "Debug",
	},

	Mobs = {
		DEBUG_Dummy = {
			id = "DEBUG_Dummy",
			name = "Training Dummy",
			location = 0,
			tier = "debug",
			defaultZone = "Debug",
			hp = 50_000,
			powerReward = 0,
			coinReward = 0,
			weaponDropChance = 0,
			weaponPool = {},
			respawnSeconds = 1.5,
			isDebug = true,
			armorFlat = 0,
			visual = {
				preferredModelName = "Dummy",
				color = "#FFAA00",
				scale = 1.3,
				shape = "r6",
			},
			description = "Debug bag. No loot."
		},

		----------------------------------------------------------------------
		-- LOC 1 — 4 goblins + boss (clear ids; no Slime/Skeleton/Knight)
		-- Legacy ids resolve via LegacyIdMap (old markers / quests / profiles)
		----------------------------------------------------------------------
		L1_Goblin = {
			id = "L1_Goblin",
			name = "Goblin",
			location = 1,
			tier = "simple",
			defaultZone = "A",
			hp = 3_000,
			powerReward = 75,
			coinReward = 250,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 3,
			visual = { preferredModelName = "Goblin", color = "#52BE80", scale = 1.0, shape = "goblin" },
			description = "T1 green smiling goblin. HP 3K / coins 250 / power 75.",
		},
		L1_DarkGoblin = {
			id = "L1_DarkGoblin",
			name = "Dark Goblin",
			location = 1,
			tier = "medium",
			defaultZone = "B",
			hp = 25_000,
			powerReward = 400,
			coinReward = 1_500,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "DarkGoblin", color = "#2C3E50", scale = 1.15, shape = "goblin" },
			description = "T2 dark purple goblin. HP 25K / coins 1.5K / power 400.",
		},
		L1_GoblinWarrior = {
			id = "L1_GoblinWarrior",
			name = "Goblin Warrior",
			location = 1,
			tier = "hard",
			defaultZone = "C",
			hp = 120_000,
			powerReward = 2_000,
			coinReward = 8_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 6,
			visual = { preferredModelName = "GoblinWarrior", color = "#1E8449", scale = 1.35, shape = "goblin" },
			description = "T3 heavy armored goblin warrior. HP 120K / coins 8K / power 2K.",
		},
		L1_GoblinScout = {
			id = "L1_GoblinScout",
			name = "Goblin Scout",
			location = 1,
			tier = "elite",
			defaultZone = "D",
			hp = 600_000,
			powerReward = 8_000,
			coinReward = 35_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 8,
			visual = { preferredModelName = "GoblinScout", color = "#2ECC71", scale = 1.1, shape = "goblin" },
			description = "T4 elite goblin scout. HP 600K / coins 35K / power 8K.",
		},
		-- L1_Boss disabled per user order
		--[[
		L1_Boss = {
			id = "L1_Boss",
			name = "Forest Guardian",
			location = 1,
			tier = "boss",
			defaultZone = "Boss",
			hp = 1_200_000,
			powerReward = 5_000,
			coinReward = 25_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "Supreme Shadow Lord", color = "#145A32", scale = 2.0, shape = "humanoid" },
			description = "Loc1 boss at end of path. Dump HP 1.2M / coins 25K.",
		},
				----------------------------------------------------------------------
		-- LOC 2 — Crystal Mine (Theme: mine)
		----------------------------------------------------------------------
		L2_Sailor = {
			id = "L2_Sailor",
			name = "Cave Miner",
			location = 2,
			tier = "simple",
			defaultZone = "A",
			hp = 9_000_000,
			powerReward = 2_000,
			coinReward = 750_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			dropTable = {
				pirate_hook = 54.998,
				pirate_hammer = 34.999,
				pirate_saber = 8.0,
				golden_plated_sword = 2.004,
			},
			respawnSeconds = 4,
			visual = { preferredModelName = "L2_Sailor", color = "#85929E", scale = 1.0, shape = "humanoid" },
			description = "Dump: 9M HP / 750K coins",
		},
		L2_Gunner = {
			id = "L2_Gunner",
			name = "Crystal Crawler",
			location = 2,
			tier = "medium",
			defaultZone = "B",
			hp = 70_640_000,
			powerReward = 8_000,
			coinReward = 5_770_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			dropTable = {
				pirate_hook = 18.182,
				pirate_hammer = 36.363,
				pirate_saber = 31.818,
				golden_plated_sword = 10.454,
				captain_axe = 2.727,
				element_blade = 0.456,
			},
			respawnSeconds = 8,
			visual = { preferredModelName = "L2_Gunner", color = "#A569BD", scale = 1.15, shape = "humanoid" },
			description = "Dump: 70.64M HP / 5.77M coins",
		},
		L2_Captain = {
			id = "L2_Captain",
			name = "Mine Overseer",
			location = 2,
			tier = "hard",
			defaultZone = "C",
			hp = 4_750_000_000, -- 4.75B
			powerReward = 50_000,
			coinReward = 46_400_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			dropTable = {
				pirate_hook = 2.997,
				pirate_hammer = 21.98,
				pirate_saber = 29.973,
				golden_plated_sword = 26.976,
				captain_axe = 13.388,
				element_blade = 3.996,
				emerald_blade = 0.59,
				sea_dagger = 0.1,
			},
			respawnSeconds = 15,
			visual = { preferredModelName = "L2_Captain", color = "#34495E", scale = 1.4, shape = "humanoid" },
			description = "Dump: 4.75B HP / 46.4M coins",
		},

		----------------------------------------------------------------------
		-- LOC 2 final boss (Crystal Golem)
		----------------------------------------------------------------------
		L2_Corsair = {
			id = "L2_Corsair",
			name = "Crystal Golem Boss",
			location = 2,
			tier = "boss",
			defaultZone = "Boss",
			hp = 25_000_000_000, -- 25B
			powerReward = 250_000,
			coinReward = 250_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			dropTable = {
				pirate_hook = 3.0,
				pirate_hammer = 22.0,
				pirate_saber = 30.0,
				golden_plated_sword = 27.0,
				captain_axe = 14.0,
				element_blade = 4.0,
				corsair_cutlass = 0.5,
			},
			respawnSeconds = 20,
			visual = { preferredModelName = "L2_Corsair", color = "#BB8FCE", scale = 1.6, shape = "humanoid" },
			description = "Loc2 final boss ~25B HP",
		},

		----------------------------------------------------------------------
		-- LOC 3 — Desert Outpost (Theme: desert)
		----------------------------------------------------------------------
		L3_Scout = {
			id = "L3_Scout",
			name = "Desert Scorpion",
			location = 3,
			tier = "simple",
			defaultZone = "A",
			hp = 80_000_000_000, -- 80B
			powerReward = 20_000,
			coinReward = 8_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "L3_Scout", color = "#F4D03F", scale = 1.0, shape = "quad" },
			description = "Loc3 T1 ~80B HP.",
		},
		L3_Adept = {
			id = "L3_Adept",
			name = "Sand Nomad",
			location = 3,
			tier = "medium",
			defaultZone = "B",
			hp = 400_000_000_000, -- 400B
			powerReward = 80_000,
			coinReward = 40_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 6,
			visual = { preferredModelName = "L3_Adept", color = "#D4AC0D", scale = 1.15, shape = "humanoid" },
			description = "Loc3 T2 ~400B HP.",
		},
		L3_Warden = {
			id = "L3_Warden",
			name = "Dune Warden",
			location = 3,
			tier = "hard",
			defaultZone = "C",
			hp = 2_500_000_000_000, -- 2.5T
			powerReward = 400_000,
			coinReward = 200_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 10,
			visual = { preferredModelName = "L3_Warden", color = "#B7950B", scale = 1.3, shape = "humanoid" },
			description = "Loc3 T3 ~2.5T HP.",
		},
		L3_Elite = {
			id = "L3_Elite",
			name = "Desert Bandit Chief",
			location = 3,
			tier = "elite",
			defaultZone = "D",
			hp = 15_000_000_000_000, -- 15T
			powerReward = 1_200_000,
			coinReward = 800_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 14,
			visual = { preferredModelName = "L3_Elite", color = "#78281F", scale = 1.4, shape = "humanoid" },
			description = "Loc3 T4 ~15T HP.",
		},
		L3_Boss = {
			id = "L3_Boss",
			name = "Sunfire Shogun Boss",
			location = 3,
			tier = "boss",
			defaultZone = "Boss",
			hp = 50_000_000_000_000, -- 50T
			powerReward = 5_000_000,
			coinReward = 2_500_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L3_Boss", color = "#E67E22", scale = 2.0, shape = "humanoid" },
			description = "Loc3 boss ~50T HP.",
		},

		----------------------------------------------------------------------
		-- LOC 4 — Polar Tundra (4 mobs + boss)
		----------------------------------------------------------------------
		L4_FrostWolf = {
			id = "L4_FrostWolf",
			name = "Frost Wolf",
			location = 4,
			tier = "simple",
			defaultZone = "A",
			hp = 2_500_000_000_000, -- 2.5T
			powerReward = 120_000,
			coinReward = 50_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "L4_FrostWolf", color = "#85C1E9", scale = 1.3, shape = "quad" },
			description = "Loc4 T1 ~2.5T HP.",
		},
		L4_IceGolem = {
			id = "L4_IceGolem",
			name = "Ice Golem",
			location = 4,
			tier = "medium",
			defaultZone = "B",
			hp = 12_000_000_000_000, -- 12T
			powerReward = 600_000,
			coinReward = 250_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 5,
			visual = { preferredModelName = "L4_IceGolem", color = "#5DADE2", scale = 1.6, shape = "humanoid" },
			description = "Loc4 T2 ~12T HP.",
		},
		L4_TundraYeti = {
			id = "L4_TundraYeti",
			name = "Tundra Yeti",
			location = 4,
			tier = "hard",
			defaultZone = "C",
			hp = 80_000_000_000_000, -- 80T
			powerReward = 3_500_000,
			coinReward = 1_500_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 7,
			visual = { preferredModelName = "L4_TundraYeti", color = "#EBF5FB", scale = 1.8, shape = "humanoid" },
			description = "Loc4 T3 ~80T HP.",
		},
		L4_GlacierDragonBoss = {
			id = "L4_GlacierDragonBoss",
			name = "Glacier Dragon",
			location = 4,
			tier = "boss",
			defaultZone = "Boss",
			hp = 1_200_000_000_000_000, -- 1.2Qa
			powerReward = 60_000_000,
			coinReward = 40_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L4_GlacierDragonBoss", color = "#2874A6", scale = 2.4, shape = "humanoid" },
			description = "Loc4 Boss ~1.2Qa HP.",
		},

		----------------------------------------------------------------------
		-- LOC 5 — Candy Land (Theme: candy)
		----------------------------------------------------------------------
		L5_CinderWolf = {
			id = "L5_CinderWolf",
			name = "Gummy Bear",
			location = 5,
			tier = "simple",
			defaultZone = "A",
			hp = 60_000_000_000_000, -- 60T
			powerReward = 4_000_000,
			coinReward = 800_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "L5_CinderWolf", color = "#FF69B4", scale = 1.3, shape = "quad" },
			description = "Loc5 T1 ~60T HP.",
		},
		L5_MagmaScout = {
			id = "L5_MagmaScout",
			name = "Lollipop Guard",
			location = 5,
			tier = "medium",
			defaultZone = "B",
			hp = 300_000_000_000_000, -- 300T
			powerReward = 16_000_000,
			coinReward = 4_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 5,
			visual = { preferredModelName = "L5_MagmaScout", color = "#FF1493", scale = 1.15, shape = "humanoid" },
			description = "Loc5 T2 ~300T HP.",
		},
		L5_AshBrute = {
			id = "L5_AshBrute",
			name = "Cupcake Brute",
			location = 5,
			tier = "hard",
			defaultZone = "C",
			hp = 2_000_000_000_000_000, -- 2Qa
			powerReward = 80_000_000,
			coinReward = 25_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 7,
			visual = { preferredModelName = "L5_AshBrute", color = "#DA70D6", scale = 1.5, shape = "humanoid" },
			description = "Loc5 T3 ~2Qa HP.",
		},
		L5_EmberLord = {
			id = "L5_EmberLord",
			name = "Candy Knight",
			location = 5,
			tier = "elite",
			defaultZone = "D",
			hp = 12_000_000_000_000_000, -- 12Qa
			powerReward = 250_000_000,
			coinReward = 120_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 10,
			visual = { preferredModelName = "L5_EmberLord", color = "#C71585", scale = 1.4, shape = "humanoid" },
			description = "Loc5 T4 ~12Qa HP.",
		},
		L5_VolcanoKingBoss = {
			id = "L5_VolcanoKingBoss",
			name = "King Gummy Boss",
			location = 5,
			tier = "boss",
			defaultZone = "Boss",
			hp = 40_000_000_000_000_000, -- 40Qa
			powerReward = 1_000_000_000,
			coinReward = 500_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L5_VolcanoKingBoss", color = "#FF007F", scale = 2.2, shape = "humanoid" },
			description = "Loc5 Boss ~40Qa HP.",
		},

		----------------------------------------------------------------------
		-- LOC 6 — Water Haven (Theme: water)
		----------------------------------------------------------------------
		L6_DockRat = {
			id = "L6_DockRat",
			name = "Water Nymph",
			location = 6,
			tier = "simple",
			defaultZone = "A",
			hp = 1_500_000_000_000_000, -- 1.5Qa
			powerReward = 12_000_000,
			coinReward = 8_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "L6_DockRat", color = "#1ABC9C", scale = 1.1, shape = "quad" },
			description = "Loc6 T1 ~1.5Qa HP.",
		},
		L6_NeonThug = {
			id = "L6_NeonThug",
			name = "Ocean Pirate",
			location = 6,
			tier = "medium",
			defaultZone = "B",
			hp = 8_000_000_000_000_000, -- 8Qa
			powerReward = 50_000_000,
			coinReward = 40_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 5,
			visual = { preferredModelName = "L6_NeonThug", color = "#3498DB", scale = 1.2, shape = "humanoid" },
			description = "Loc6 T2 ~8Qa HP.",
		},
		L6_CyberSamurai = {
			id = "L6_CyberSamurai",
			name = "Tide Warden",
			location = 6,
			tier = "hard",
			defaultZone = "C",
			hp = 50_000_000_000_000_000, -- 50Qa
			powerReward = 200_000_000,
			coinReward = 250_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 7,
			visual = { preferredModelName = "L6_CyberSamurai", color = "#2980B9", scale = 1.35, shape = "humanoid" },
			description = "Loc6 T3 ~50Qa HP.",
		},
		L6_NeonBoss = {
			id = "L6_NeonBoss",
			name = "Sea Serpent",
			location = 6,
			tier = "elite",
			defaultZone = "D",
			hp = 300_000_000_000_000_000, -- 300Qa
			powerReward = 600_000_000,
			coinReward = 1_200_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 10,
			visual = { preferredModelName = "L6_NeonBoss", color = "#16A085", scale = 1.45, shape = "humanoid" },
			description = "Loc6 T4 ~300Qa HP.",
		},
		L6_DockOverseerBoss = {
			id = "L6_DockOverseerBoss",
			name = "Ocean Leviathan Boss",
			location = 6,
			tier = "boss",
			defaultZone = "Boss",
			hp = 1_000_000_000_000_000_000, -- 1Qi
			powerReward = 2_500_000_000,
			coinReward = 6_000_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L6_DockOverseerBoss", color = "#1B4F72", scale = 2.3, shape = "humanoid" },
			description = "Loc6 Boss ~1Qi HP.",
		},

		----------------------------------------------------------------------
		-- LOC 7 — Hell Gate (Theme: hell)
		----------------------------------------------------------------------
		L7_BoneImp = {
			id = "L7_BoneImp",
			name = "Hell Imp",
			location = 7,
			tier = "simple",
			defaultZone = "A",
			hp = 40_000_000_000_000_000, -- 40Qa
			powerReward = 40_000_000,
			coinReward = 80_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "L7_BoneImp", color = "#E74C3C", scale = 1.1, shape = "humanoid" },
			description = "Loc7 T1 ~40Qa HP.",
		},
		L7_CryptGuard = {
			id = "L7_CryptGuard",
			name = "Demon Guard",
			location = 7,
			tier = "medium",
			defaultZone = "B",
			hp = 200_000_000_000_000_000, -- 200Qa
			powerReward = 150_000_000,
			coinReward = 400_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 5,
			visual = { preferredModelName = "L7_CryptGuard", color = "#C0392B", scale = 1.25, shape = "humanoid" },
			description = "Loc7 T2 ~200Qa HP.",
		},
		L7_SoulReaper = {
			id = "L7_SoulReaper",
			name = "Infernal Reaper",
			location = 7,
			tier = "hard",
			defaultZone = "C",
			hp = 1_200_000_000_000_000_000, -- 1.2Qi
			powerReward = 600_000_000,
			coinReward = 2_500_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 7,
			visual = { preferredModelName = "L7_SoulReaper", color = "#900C3F", scale = 1.4, shape = "humanoid" },
			description = "Loc7 T3 ~1.2Qi HP.",
		},
		L7_CathedralWraith = {
			id = "L7_CathedralWraith",
			name = "Hell Wraith",
			location = 7,
			tier = "elite",
			defaultZone = "D",
			hp = 8_000_000_000_000_000_000, -- 8Qi
			powerReward = 2_000_000_000,
			coinReward = 12_000_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 10,
			visual = { preferredModelName = "L7_CathedralWraith", color = "#581845", scale = 1.5, shape = "humanoid" },
			description = "Loc7 T4 ~8Qi HP.",
		},
		L7_BoneOverlordBoss = {
			id = "L7_BoneOverlordBoss",
			name = "Demon Overlord Boss",
			location = 7,
			tier = "boss",
			defaultZone = "Boss",
			hp = 25_000_000_000_000_000_000, -- 25Qi
			powerReward = 8_000_000_000,
			coinReward = 50_000_000_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L7_BoneOverlordBoss", color = "#641E16", scale = 2.4, shape = "humanoid" },
			description = "Loc7 Boss ~25Qi HP.",
		},
	} :: { [string]: MobDef },

	--[[
		Old ids → new Loc1 ladder (markers, quests, any saved kill trackers)
	]]
	LegacyIdMap = {
		L1_Slime = "L1_Goblin",
		L1_Skeleton = "L1_DarkGoblin",
		L1_Knight = "L1_GoblinScout",
		-- L1_GoblinWarrior / L1_Boss unchanged
	} :: { [string]: string },
}

function MobConfig.ResolveId(id: string): string
	if type(id) ~= "string" or id == "" then
		return id
	end
	if MobConfig.Mobs[id] then
		return id
	end
	local mapped = MobConfig.LegacyIdMap[id]
	if type(mapped) == "string" and mapped ~= "" and MobConfig.Mobs[mapped] then
		return mapped
	end
	-- Strip trailing numbers e.g. L1_DarkGoblin_01 -> L1_DarkGoblin
	local stripped = string.gsub(id, "_%d+$", "")
	if MobConfig.Mobs[stripped] then
		return stripped
	end
	local mappedStripped = MobConfig.LegacyIdMap[stripped]
	if type(mappedStripped) == "string" and mappedStripped ~= "" and MobConfig.Mobs[mappedStripped] then
		return mappedStripped
	end
	return id
end

function MobConfig.Get(id: string): MobDef?
	local resolved = MobConfig.ResolveId(id)
	return MobConfig.Mobs[resolved]
end

function MobConfig.GetByLocation(locationId: number): { MobDef }
	local out: { MobDef } = {}
	for _, def in pairs(MobConfig.Mobs) do
		if def.location == locationId then
			table.insert(out, def)
		end
	end
	return out
end

function MobConfig.GetPublicCatalog(): { any }
	local out: { any } = {}
	for _, def in pairs(MobConfig.Mobs) do
		table.insert(out, {
			id = def.id,
			name = def.name,
			location = def.location,
			tier = def.tier,
			hp = def.hp,
			coinReward = def.coinReward,
			powerReward = def.powerReward,
			isBoss = def.isBoss == true,
			isDebug = def.isDebug == true,
			description = def.description,
		})
	end
	table.sort(out, function(a, b)
		if a.location ~= b.location then
			return a.location < b.location
		end
		return a.hp < b.hp
	end)
	return out
end

return MobConfig
