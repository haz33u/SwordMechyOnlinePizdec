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
			description = "Debug bag. No loot.",
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
			hp = 1_000,
			powerReward = 5,
			coinReward = 200,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 3,
			visual = { preferredModelName = "L1_Goblin", color = "#58D68D", scale = 1.0, shape = "humanoid" },
			description = "T1 green goblin. Dump HP 1K / coins 200.",
		},
		L1_DarkGoblin = {
			id = "L1_DarkGoblin",
			name = "Dark Goblin",
			location = 1,
			tier = "medium",
			defaultZone = "B",
			hp = 8_000,
			powerReward = 15,
			coinReward = 800,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "L1_DarkGoblin", color = "#5DADE2", scale = 1.1, shape = "humanoid" },
			description = "T2 blue dark goblin. HP 8K / coins 800.",
		},
		L1_GoblinWarrior = {
			id = "L1_GoblinWarrior",
			name = "Goblin Warrior",
			location = 1,
			tier = "hard",
			defaultZone = "C",
			hp = 5_680_000,
			powerReward = 80,
			coinReward = 100_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 6,
			visual = { preferredModelName = "L1_GoblinWarrior", color = "#8E44AD", scale = 1.25, shape = "humanoid" },
			description = "T3 warrior. Dump HP 5.68M / coins 100K.",
		},
		L1_GoblinScout = {
			id = "L1_GoblinScout",
			name = "Goblin Scout",
			location = 1,
			tier = "elite",
			defaultZone = "D",
			hp = 300_000,
			powerReward = 120,
			coinReward = 12_500,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 8,
			visual = { preferredModelName = "L1_GoblinScout", color = "#922B21", scale = 1.35, shape = "humanoid" },
			description = "T4 elite scout. Dump HP 300K / coins 12.5K.",
		},
		L1_Boss = {
			id = "L1_Boss",
			name = "Forest Guardian",
			location = 1,
			tier = "boss",
			defaultZone = "Boss",
			hp = 1_200_000,
			powerReward = 500,
			coinReward = 25_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L1_Boss", color = "#145A32", scale = 2.0, shape = "humanoid" },
			description = "Loc1 boss at end of path. Dump HP 1.2M / coins 25K.",
		},

		----------------------------------------------------------------------
		-- LOC 2 — dump «Мобы» exact HP/coins + drop %
		----------------------------------------------------------------------
		L2_Sailor = {
			id = "L2_Sailor",
			name = "Sailor",
			location = 2,
			tier = "simple",
			defaultZone = "A",
			hp = 9_000_000,
			powerReward = 200,
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
			visual = { preferredModelName = "L2_Sailor", color = "#5DADE2", scale = 1.0, shape = "humanoid" },
			description = "Dump: 9M HP / 750K coins",
		},
		L2_Gunner = {
			id = "L2_Gunner",
			name = "Gunner",
			location = 2,
			tier = "medium",
			defaultZone = "B",
			hp = 70_640_000,
			powerReward = 800,
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
			visual = { preferredModelName = "L2_Gunner", color = "#2874A6", scale = 1.15, shape = "humanoid" },
			description = "Dump: 70.64M HP / 5.77M coins",
		},
		L2_Captain = {
			id = "L2_Captain",
			name = "Captain",
			location = 2,
			tier = "hard",
			defaultZone = "C",
			hp = 4_750_000_000, -- 4.75B
			powerReward = 5000,
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
			visual = { preferredModelName = "L2_Captain", color = "#1A5276", scale = 1.4, shape = "humanoid" },
			description = "Dump: 4.75B HP / 46.4M coins",
		},

		----------------------------------------------------------------------
		-- LOC 3 — first T (trillion) scale after Loc2 B-peak
		-- Approx playtest; tune TTK in Studio (±×2–3 OK)
		----------------------------------------------------------------------
		L3_Scout = {
			id = "L3_Scout",
			name = "Shadow Scout",
			location = 3,
			tier = "simple",
			defaultZone = "A",
			hp = 80_000_000_000, -- 80B
			powerReward = 2_000,
			coinReward = 8_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 4,
			visual = { preferredModelName = "L3_Scout", color = "#5D6D7E", scale = 1.0, shape = "humanoid" },
			description = "Loc3 T1 ~80B HP (after Loc2 max 4.75B).",
		},
		L3_Adept = {
			id = "L3_Adept",
			name = "Blade Adept",
			location = 3,
			tier = "medium",
			defaultZone = "B",
			hp = 400_000_000_000, -- 400B
			powerReward = 8_000,
			coinReward = 40_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 6,
			visual = { preferredModelName = "L3_Adept", color = "#7D3C98", scale = 1.15, shape = "humanoid" },
			description = "Loc3 T2 ~400B HP.",
		},
		L3_Warden = {
			id = "L3_Warden",
			name = "Temple Warden",
			location = 3,
			tier = "hard",
			defaultZone = "C",
			hp = 2_500_000_000_000, -- 2.5T  ← first T on open hard
			powerReward = 40_000,
			coinReward = 200_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 10,
			visual = { preferredModelName = "L3_Warden", color = "#1A5276", scale = 1.3, shape = "humanoid" },
			description = "Loc3 T3 ~2.5T HP — UI shows T.",
		},
		L3_Elite = {
			id = "L3_Elite",
			name = "Silent Elite",
			location = 3,
			tier = "elite",
			defaultZone = "D",
			hp = 15_000_000_000_000, -- 15T
			powerReward = 120_000,
			coinReward = 800_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 14,
			visual = { preferredModelName = "L3_Elite", color = "#922B21", scale = 1.4, shape = "humanoid" },
			description = "Loc3 T4 ~15T HP.",
		},
		L3_Boss = {
			id = "L3_Boss",
			name = "Shogun Shade",
			location = 3,
			tier = "boss",
			defaultZone = "Boss",
			hp = 50_000_000_000_000, -- 50T
			powerReward = 500_000,
			coinReward = 2_500_000_000,
			weaponDropChance = 1,
			weaponDropScale = 1,
			weaponPool = {},
			respawnSeconds = 600,
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L3_Boss", color = "#4A235A", scale = 2.0, shape = "humanoid" },
			description = "Loc3 boss ~50T HP.",
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
	local mapped = MobConfig.LegacyIdMap[id]
	if type(mapped) == "string" and mapped ~= "" then
		return mapped
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
