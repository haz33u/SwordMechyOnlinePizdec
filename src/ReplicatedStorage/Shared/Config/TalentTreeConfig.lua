--!strict
--[[
	TALENT TREE CONFIG (RNG-Style Hexagonal Skill Network)
	
	Nodes radiate outward from central hub ("C_Core").
	Branches:
	  - Combat (Red / Orange): Damage, Crit, MultiCrit
	  - Luck (Green / Cyan): Luck, Case Drop Rates
	  - Speed (Yellow / Gold): Walk Speed, Attack Speed
	  - Utility (Blue / Purple): Coins, Backpack Slots
	  - Rebirth / Prestige (Gold / Magenta): Uses Talent Points from Rebirths
]]

export type NodeType = "minor" | "major" | "keystone"
export type CurrencyType = "coins" | "talentPoints"

export type TalentNodeDef = {
	id: string,
	name: string,
	desc: string,
	branch: "combat" | "luck" | "speed" | "utility" | "prestige",
	nodeType: NodeType,
	gridPos: Vector2, -- Relative canvas coordinates (X, Y)
	icon: string,
	parents: { string }, -- Prerequisite node IDs
	costType: CurrencyType,
	cost: number,
	effects: {
		damagePct: number?,
		coinPct: number?,
		luckPct: number?,
		critChance: number?,
		multiCrit: number?,
		clickSpeed: number?,
		walkSpeed: number?,
		bagSlots: number?,
		petSlots: number?,
		relicSlots: number?,
	},
}

local TalentTreeConfig = {}

TalentTreeConfig.Nodes = {
	-- ═══════════════════════════════════════
	-- CENTRAL CORE HUB
	-- ═══════════════════════════════════════
	C_Core = {
		id = "C_Core",
		name = "Player Core",
		desc = "The origin of your inner power.",
		branch = "combat",
		nodeType = "keystone",
		gridPos = Vector2.new(0, 0),
		icon = "☸",
		parents = {},
		costType = "coins",
		cost = 0,
		effects = {},
	},

	-- ═══════════════════════════════════════
	-- COMBAT BRANCH (LEFT / UP-LEFT)
	-- ═══════════════════════════════════════
	C_Dmg1 = {
		id = "C_Dmg1",
		name = "Sharp Blade I",
		desc = "+5% Damage",
		branch = "combat",
		nodeType = "minor",
		gridPos = Vector2.new(-120, -80),
		icon = "⚔",
		parents = { "C_Core" },
		costType = "coins",
		cost = 100,
		effects = { damagePct = 5 },
	},
	C_Dmg2 = {
		id = "C_Dmg2",
		name = "Sharp Blade II",
		desc = "+5% Damage",
		branch = "combat",
		nodeType = "minor",
		gridPos = Vector2.new(-240, -120),
		icon = "⚔",
		parents = { "C_Dmg1" },
		costType = "coins",
		cost = 500,
		effects = { damagePct = 5 },
	},
	C_Crit1 = {
		id = "C_Crit1",
		name = "Lethal Precision",
		desc = "+2% Crit Chance",
		branch = "combat",
		nodeType = "minor",
		gridPos = Vector2.new(-220, -220),
		icon = "🎯",
		parents = { "C_Dmg1" },
		costType = "coins",
		cost = 2500,
		effects = { critChance = 2 },
	},
	C_Dmg3 = {
		id = "C_Dmg3",
		name = "Heavy Strike",
		desc = "+10% Damage",
		branch = "combat",
		nodeType = "major",
		gridPos = Vector2.new(-360, -160),
		icon = "💥",
		parents = { "C_Dmg2" },
		costType = "coins",
		cost = 15000,
		effects = { damagePct = 10 },
	},
	C_MultiCrit1 = {
		id = "C_MultiCrit1",
		name = "Overkill Multi-Crit",
		desc = "+1% Multi-Crit Chance",
		branch = "combat",
		nodeType = "major",
		gridPos = Vector2.new(-340, -280),
		icon = "🔥",
		parents = { "C_Crit1" },
		costType = "coins",
		cost = 75000,
		effects = { multiCrit = 1 },
	},
	C_KeystonePower = {
		id = "C_KeystonePower",
		name = "Power Overwhelming",
		desc = "+50% Global Damage",
		branch = "combat",
		nodeType = "keystone",
		gridPos = Vector2.new(-480, -220),
		icon = "👑",
		parents = { "C_Dmg3" },
		costType = "coins",
		cost = 500000,
		effects = { damagePct = 50 },
	},

	-- ═══════════════════════════════════════
	-- LUCK & RNG BRANCH (RIGHT / UP-RIGHT)
	-- ═══════════════════════════════════════
	L_Luck1 = {
		id = "L_Luck1",
		name = "Four-Leaf Clover I",
		desc = "+5% Luck",
		branch = "luck",
		nodeType = "minor",
		gridPos = Vector2.new(120, -80),
		icon = "🍀",
		parents = { "C_Core" },
		costType = "coins",
		cost = 150,
		effects = { luckPct = 5 },
	},
	L_Luck2 = {
		id = "L_Luck2",
		name = "Four-Leaf Clover II",
		desc = "+5% Luck",
		branch = "luck",
		nodeType = "minor",
		gridPos = Vector2.new(240, -120),
		icon = "🍀",
		parents = { "L_Luck1" },
		costType = "coins",
		cost = 800,
		effects = { luckPct = 5 },
	},
	L_Luck3 = {
		id = "L_Luck3",
		name = "Fortune Blessing",
		desc = "+10% Luck",
		branch = "luck",
		nodeType = "major",
		gridPos = Vector2.new(360, -160),
		icon = "✨",
		parents = { "L_Luck2" },
		costType = "coins",
		cost = 12000,
		effects = { luckPct = 10 },
	},
	L_MajorLuck = {
		id = "L_MajorLuck",
		name = "RNG Mastery",
		desc = "+25% Luck",
		branch = "luck",
		nodeType = "major",
		gridPos = Vector2.new(480, -220),
		icon = "🌟",
		parents = { "L_Luck3" },
		costType = "coins",
		cost = 100000,
		effects = { luckPct = 25 },
	},
	L_KeystonePetSlot = {
		id = "L_KeystonePetSlot",
		name = "Beastmaster Domain",
		desc = "+1 Pet Equip Slot",
		branch = "luck",
		nodeType = "keystone",
		gridPos = Vector2.new(600, -280),
		icon = "🐾",
		parents = { "L_MajorLuck" },
		costType = "coins",
		cost = 1500000,
		effects = { petSlots = 1 },
	},

	-- ═══════════════════════════════════════
	-- SPEED BRANCH (DOWN-LEFT)
	-- ═══════════════════════════════════════
	S_Speed1 = {
		id = "S_Speed1",
		name = "Swift Boots I",
		desc = "+1 Walk Speed",
		branch = "speed",
		nodeType = "minor",
		gridPos = Vector2.new(-120, 100),
		icon = "⚡",
		parents = { "C_Core" },
		costType = "coins",
		cost = 80,
		effects = { walkSpeed = 1 },
	},
	S_Speed2 = {
		id = "S_Speed2",
		name = "Swift Boots II",
		desc = "+1 Walk Speed",
		branch = "speed",
		nodeType = "minor",
		gridPos = Vector2.new(-240, 150),
		icon = "⚡",
		parents = { "S_Speed1" },
		costType = "coins",
		cost = 400,
		effects = { walkSpeed = 1 },
	},
	S_AtkSpeed1 = {
		id = "S_AtkSpeed1",
		name = "Quick Hands",
		desc = "+2% Attack Speed",
		branch = "speed",
		nodeType = "minor",
		gridPos = Vector2.new(-220, 250),
		icon = "🗡",
		parents = { "S_Speed2" },
		costType = "coins",
		cost = 3000,
		effects = { clickSpeed = 2 },
	},
	S_KeystoneSpeed = {
		id = "S_KeystoneSpeed",
		name = "Light Footing",
		desc = "+4 Walk Speed & +5% Attack Speed",
		branch = "speed",
		nodeType = "keystone",
		gridPos = Vector2.new(-360, 300),
		icon = "🌪",
		parents = { "S_AtkSpeed1" },
		costType = "coins",
		cost = 250000,
		effects = { walkSpeed = 4, clickSpeed = 5 },
	},

	-- ═══════════════════════════════════════
	-- UTILITY & COINS BRANCH (DOWN-RIGHT)
	-- ═══════════════════════════════════════
	U_Coins1 = {
		id = "U_Coins1",
		name = "Golden Pouch I",
		desc = "+5% Coins",
		branch = "utility",
		nodeType = "minor",
		gridPos = Vector2.new(120, 100),
		icon = "💰",
		parents = { "C_Core" },
		costType = "coins",
		cost = 100,
		effects = { coinPct = 5 },
	},
	U_Coins2 = {
		id = "U_Coins2",
		name = "Golden Pouch II",
		desc = "+5% Coins",
		branch = "utility",
		nodeType = "minor",
		gridPos = Vector2.new(240, 150),
		icon = "💰",
		parents = { "U_Coins1" },
		costType = "coins",
		cost = 600,
		effects = { coinPct = 5 },
	},
	U_Backpack1 = {
		id = "U_Backpack1",
		name = "Expanded Bag",
		desc = "+4 Inventory Slots to all Bags",
		branch = "utility",
		nodeType = "minor",
		gridPos = Vector2.new(220, 250),
		icon = "🎒",
		parents = { "U_Coins2" },
		costType = "coins",
		cost = 10000,
		effects = { bagSlots = 4 },
	},
	U_Coins3 = {
		id = "U_Coins3",
		name = "Treasure Magnet",
		desc = "+15% Coins",
		branch = "utility",
		nodeType = "major",
		gridPos = Vector2.new(360, 200),
		icon = "💎",
		parents = { "U_Coins2" },
		costType = "coins",
		cost = 40000,
		effects = { coinPct = 15 },
	},
	U_KeystoneRelic = {
		id = "U_KeystoneRelic",
		name = "Relic Mastery",
		desc = "+1 Relic Equip Slot",
		branch = "utility",
		nodeType = "keystone",
		gridPos = Vector2.new(380, 320),
		icon = "🔮",
		parents = { "U_Coins3" },
		costType = "coins",
		cost = 2000000,
		effects = { relicSlots = 1 },
	},

	-- ═══════════════════════════════════════
	-- PRESTIGE / TALENT POINTS BRANCH (STRAIGHT UP)
	-- Uses Talent Points earned from Rebirths!
	-- ═══════════════════════════════════════
	P_RebirthDmg = {
		id = "P_RebirthDmg",
		name = "Ascendant Might",
		desc = "+20% All Damage",
		branch = "prestige",
		nodeType = "major",
		gridPos = Vector2.new(-60, -220),
		icon = "🔱",
		parents = { "C_Core" },
		costType = "talentPoints",
		cost = 1,
		effects = { damagePct = 20 },
	},
	P_RebirthLuck = {
		id = "P_RebirthLuck",
		name = "Divine Fortune",
		desc = "+20% Luck",
		branch = "prestige",
		nodeType = "major",
		gridPos = Vector2.new(60, -220),
		icon = "☀️",
		parents = { "C_Core" },
		costType = "talentPoints",
		cost = 1,
		effects = { luckPct = 20 },
	},
	P_KeystonePrestige = {
		id = "P_KeystonePrestige",
		name = "Master Ascendant",
		desc = "+100% Global Power Multiplier",
		branch = "prestige",
		nodeType = "keystone",
		gridPos = Vector2.new(0, -360),
		icon = "🌌",
		parents = { "P_RebirthDmg", "P_RebirthLuck" },
		costType = "talentPoints",
		cost = 5,
		effects = { damagePct = 100 },
	},
} :: { [string]: TalentNodeDef }

function TalentTreeConfig.Get(nodeId: string): TalentNodeDef?
	return TalentTreeConfig.Nodes[nodeId]
end

function TalentTreeConfig.GetAll(): { [string]: TalentNodeDef }
	return TalentTreeConfig.Nodes
end

--- Aggregates all stat bonuses from an array of unlocked node IDs
function TalentTreeConfig.ComputeStats(unlockedTalents: { [string]: boolean }?)
	local totals = {
		damagePct = 0,
		coinPct = 0,
		luckPct = 0,
		critChance = 0,
		multiCrit = 0,
		clickSpeed = 0,
		walkSpeed = 0,
		bagSlots = 0,
		petSlots = 0,
		relicSlots = 0,
	}
	if not unlockedTalents then
		return totals
	end
	for nodeId, isUnlocked in unlockedTalents do
		if isUnlocked then
			local def = TalentTreeConfig.Nodes[nodeId]
			if def and def.effects then
				for stat, val in def.effects do
					if type(val) == "number" and totals[stat] ~= nil then
						totals[stat] += val
					end
				end
			end
		end
	end
	return totals
end

return TalentTreeConfig
