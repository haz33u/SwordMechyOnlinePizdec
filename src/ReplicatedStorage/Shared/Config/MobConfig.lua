--!strict
--[[
	Mob catalog — data only (no visuals).

	Loc1 (Тёмный лес): tier ladder trash → elite → boss
	DEBUG_Dummy: infinite training bag for combat/UI tests
]]

export type MobVisualHint = {
	-- hints for Studio / client visual layer (not enforced by backend)
	preferredModelName: string?, -- Workspace/ReplicatedStorage model name
	color: string?, -- hex for placeholder
	scale: number?, -- relative size
	shape: string?, -- "ball" | "r6" | "quad" | "humanoid"
}

export type MobDef = {
	id: string,
	name: string,
	location: number, -- 0 = global/debug, 1+ = location id
	tier: string, -- trash | normal | elite | boss | debug
	defaultZone: string, -- A | B | C | Boss | Debug
	hp: number,
	powerReward: number,
	coinReward: number,
	weaponDropChance: number,
	weaponPool: { string },
	respawnSeconds: number,
	isBoss: boolean?,
	isDebug: boolean?,
	-- combat modifiers
	armorFlat: number?, -- subtract from hit damage (min 1 dmg)
	-- presentation
	visual: MobVisualHint?,
	description: string?,
}

local MobConfig = {
	Tiers = { "trash", "normal", "elite", "boss", "debug" },

	Mobs = {
		----------------------------------------------------------------------
		-- DEBUG
		----------------------------------------------------------------------
		DEBUG_Dummy = {
			id = "DEBUG_Dummy",
			name = "Тренировочный манекен",
			location = 0,
			tier = "debug",
			defaultZone = "Debug",
			-- Easier to see HP bar move; still tanky for long tests
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
			description = "Debug bag near spawn. No loot/quests. HP bar test target.",
		},

		----------------------------------------------------------------------
		-- LOCATION 1 — Тёмный лес
		-- Zone A (слабые) → B → C (элита) → Boss
		----------------------------------------------------------------------
		L1_Slime = {
			id = "L1_Slime",
			name = "Теневой слизень",
			location = 1,
			tier = "trash",
			defaultZone = "A",
			hp = 40,
			powerReward = 1,
			coinReward = 3,
			weaponDropChance = 0.03,
			weaponPool = { "W1_C1", "W1_C2" },
			respawnSeconds = 3,
			visual = {
				preferredModelName = "L1_Slime",
				color = "#5B2C6F",
				scale = 0.7,
				shape = "ball",
			},
			description = "Стартовый моб. Зона A.",
		},

		L1_GoblinScout = {
			id = "L1_GoblinScout",
			name = "Гоблин-разведчик",
			location = 1,
			tier = "trash",
			defaultZone = "A",
			hp = 70,
			powerReward = 2,
			coinReward = 4,
			weaponDropChance = 0.04,
			weaponPool = { "W1_C1", "W1_C2" },
			respawnSeconds = 3.2,
			visual = {
				preferredModelName = "L1_GoblinScout",
				color = "#27AE60",
				scale = 0.85,
				shape = "humanoid",
			},
			description = "Квестовый trash. Зона A.",
		},

		L1_Skeleton = {
			id = "L1_Skeleton",
			name = "Лесной скелет",
			location = 1,
			tier = "normal",
			defaultZone = "B",
			hp = 120,
			powerReward = 3,
			coinReward = 6,
			weaponDropChance = 0.05,
			weaponPool = { "W1_C2", "W1_U1" },
			respawnSeconds = 3.5,
			visual = {
				preferredModelName = "L1_Skeleton",
				color = "#D5D8DC",
				scale = 1.0,
				shape = "humanoid",
			},
			description = "Средний моб. Зона B.",
		},

		L1_Wolf = {
			id = "L1_Wolf",
			name = "Тёмный волк",
			location = 1,
			tier = "normal",
			defaultZone = "B",
			hp = 350,
			powerReward = 8,
			coinReward = 14,
			weaponDropChance = 0.07,
			weaponPool = { "W1_U1", "W1_U2", "W1_R1" },
			respawnSeconds = 4,
			visual = {
				preferredModelName = "L1_Wolf",
				color = "#1C2833",
				scale = 1.1,
				shape = "quad",
			},
			description = "Квестовый mid. Зона B.",
		},

		L1_GoblinWarrior = {
			id = "L1_GoblinWarrior",
			name = "Гоблин-воин",
			location = 1,
			tier = "normal",
			defaultZone = "B",
			hp = 500,
			powerReward = 12,
			coinReward = 18,
			weaponDropChance = 0.08,
			weaponPool = { "W1_U2", "W1_R1" },
			respawnSeconds = 5,
			visual = {
				preferredModelName = "L1_GoblinWarrior",
				color = "#1E8449",
				scale = 1.0,
				shape = "humanoid",
			},
			description = "Финиш стартовой цепочки квестов. Зона B/C.",
		},

		L1_Knight = {
			id = "L1_Knight",
			name = "Проклятый рыцарь",
			location = 1,
			tier = "elite",
			defaultZone = "C",
			hp = 1_200,
			powerReward = 25,
			coinReward = 40,
			weaponDropChance = 0.12,
			weaponPool = { "W1_R1", "W1_R2" },
			respawnSeconds = 8,
			armorFlat = 2,
			visual = {
				preferredModelName = "L1_Knight",
				color = "#5D6D7E",
				scale = 1.25,
				shape = "humanoid",
			},
			description = "Элита. Зона C.",
		},

		L1_Boss = {
			id = "L1_Boss",
			name = "Хранитель леса",
			location = 1,
			tier = "boss",
			defaultZone = "Boss",
			hp = 8_000,
			powerReward = 200,
			coinReward = 300,
			weaponDropChance = 0.40,
			weaponPool = { "W1_R2", "W1_E1", "W1_L1" },
			respawnSeconds = 45,
			isBoss = true,
			armorFlat = 5,
			visual = {
				preferredModelName = "L1_Boss",
				color = "#145A32",
				scale = 2.0,
				shape = "humanoid",
			},
			description = "Босс локации 1. Арена Boss.",
		},

		----------------------------------------------------------------------
		-- LOCATION 2 stubs (keep for later)
		----------------------------------------------------------------------
		L2_Sailor = {
			id = "L2_Sailor",
			name = "Матрос",
			location = 2,
			tier = "trash",
			defaultZone = "A",
			hp = 2_500,
			powerReward = 40,
			coinReward = 60,
			weaponDropChance = 0.08,
			weaponPool = { "W2_C1", "W2_U1" },
			respawnSeconds = 4,
			visual = { preferredModelName = "L2_Sailor", color = "#5DADE2", scale = 1.0, shape = "humanoid" },
		},
		L2_Captain = {
			id = "L2_Captain",
			name = "Капитан",
			location = 2,
			tier = "elite",
			defaultZone = "B",
			hp = 8_000,
			powerReward = 100,
			coinReward = 150,
			weaponDropChance = 0.12,
			weaponPool = { "W2_R1", "W2_E1" },
			respawnSeconds = 10,
			visual = { preferredModelName = "L2_Captain", color = "#2874A6", scale = 1.2, shape = "humanoid" },
		},
		L2_Admiral = {
			id = "L2_Admiral",
			name = "Адмирал",
			location = 2,
			tier = "boss",
			defaultZone = "Boss",
			hp = 40_000,
			powerReward = 600,
			coinReward = 800,
			weaponDropChance = 0.35,
			weaponPool = { "W2_E1", "W2_L1" },
			respawnSeconds = 60,
			isBoss = true,
			visual = { preferredModelName = "L2_Admiral", color = "#1A5276", scale = 1.8, shape = "humanoid" },
		},

		L3_Samurai = {
			id = "L3_Samurai",
			name = "Самурай",
			location = 3,
			tier = "normal",
			defaultZone = "A",
			hp = 15_000,
			powerReward = 180,
			coinReward = 250,
			weaponDropChance = 0.10,
			weaponPool = { "W3_U1", "W3_R1" },
			respawnSeconds = 5,
			visual = { preferredModelName = "L3_Samurai", color = "#922B21", scale = 1.0, shape = "humanoid" },
		},
	} :: { [string]: MobDef },
}

function MobConfig.Get(id: string): MobDef?
	return MobConfig.Mobs[id]
end

function MobConfig.GetByLocation(locationId: number): { MobDef }
	local list = {}
	for _, def in MobConfig.Mobs do
		if def.location == locationId and not def.isDebug then
			table.insert(list, def)
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

function MobConfig.GetDebugMobs(): { MobDef }
	local list = {}
	for _, def in MobConfig.Mobs do
		if def.isDebug then
			table.insert(list, def)
		end
	end
	return list
end

--- Catalog for client / Studio Agent (no secrets)
function MobConfig.GetPublicCatalog(): { any }
	local out = {}
	for _, def in MobConfig.Mobs do
		table.insert(out, {
			id = def.id,
			name = def.name,
			location = def.location,
			tier = def.tier,
			defaultZone = def.defaultZone,
			hp = def.hp,
			isBoss = def.isBoss == true,
			isDebug = def.isDebug == true,
			visual = def.visual,
			description = def.description,
		})
	end
	table.sort(out, function(a, b)
		if a.location ~= b.location then
			return a.location < b.location
		end
		return a.id < b.id
	end)
	return out
end

return MobConfig
