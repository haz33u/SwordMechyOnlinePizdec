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
		-- LOC 1 — exactly 4 combat mobs + boss (ids stable; names = goblin ladder)
		-- Wolf / Elite → Spare (not world-spawned)
		----------------------------------------------------------------------
		-- T1 simple — green
		L1_Slime = {
			id = "L1_Slime",
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
			visual = { preferredModelName = "L1_Slime", color = "#58D68D", scale = 1.0, shape = "humanoid" },
			description = "T1 green goblin. Dump HP 1K / coins 200.",
		},
		-- L1_GoblinScout (Runner) → Spare/MobConfigSpare.lua
		-- T2 medium — blue
		L1_Skeleton = {
			id = "L1_Skeleton",
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
			visual = { preferredModelName = "L1_Skeleton", color = "#5DADE2", scale = 1.1, shape = "humanoid" },
			description = "T2 blue dark goblin. HP 8K / coins 800.",
		},
		-- T3 hard — purple/dark green warrior (dump scale)
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
		-- T4 elite — red scout
		L1_Knight = {
			id = "L1_Knight",
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
			visual = { preferredModelName = "L1_Knight", color = "#922B21", scale = 1.35, shape = "humanoid" },
			description = "T4 elite scout. Dump HP 300K / coins 12.5K.",
		},
		-- Boss — end of loc / portal area (not a normal pack spawn row)
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
			respawnSeconds = 600, -- 10 min boss respawn (project rule)
			isBoss = true,
			armorFlat = 0,
			visual = { preferredModelName = "L1_Boss", color = "#145A32", scale = 2.0, shape = "humanoid" },
			description = "Loc1 boss. Dump HP 1.2M / coins 25K. Own zone — polish later.",
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
	} :: { [string]: MobDef },
}

function MobConfig.Get(id: string): MobDef?
	return MobConfig.Mobs[id]
end

function MobConfig.GetByLocation(locationId: number): { MobDef }
	local out = {}
	for _, def in MobConfig.Mobs do
		if def.location == locationId then
			table.insert(out, def)
		end
	end
	return out
end

function MobConfig.GetPublicCatalog(): { any }
	local out = {}
	for _, def in MobConfig.Mobs do
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
