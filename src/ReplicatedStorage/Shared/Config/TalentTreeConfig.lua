--!strict
--[[
	TALENT TREE CONFIG (RNG-Style Hexagonal Skill Network — 114 Nodes Scaling to Loc 19)
	
	Extensive node graph with 5 radiating constellations from central C_Core hub:
	  1. COMBAT (Up-Left): 32 Nodes (Damage I..X, Crit I..VIII, Multi-Crit I..V, Keystones)
	  2. LUCK & RNG (Up-Right): 24 Nodes (Luck I..X, Pet Luck I..V, Key Finder I..V, Keystones)
	  3. SPEED (Down-Left): 19 Nodes (Walk Speed I..VIII, Attack Speed I..VIII, Keystones)
	  4. UTILITY (Down-Right): 21 Nodes (Coins I..X, Backpack I..VIII, Relic Keystones)
	  5. PRESTIGE (Straight Up): 17 Nodes (Rebirth Dmg, Luck, Coins, Master Ascendant)
]]

export type NodeType = "minor" | "major" | "keystone"
export type CurrencyType = "coins" | "talentPoints"

export type TalentNodeDef = {
	id: string,
	name: string,
	desc: string,
	branch: "combat" | "luck" | "speed" | "utility" | "prestige",
	nodeType: NodeType,
	gridPos: Vector2,
	icon: string,
	parents: { string },
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
local Nodes: { [string]: TalentNodeDef } = {}

-- Costs for Tiers 1..10 (Loc 1 to Loc 19 Economy Curve)
local COIN_TIERS = {
	[1] = 100,
	[2] = 1_000,
	[3] = 15_000,
	[4] = 150_000,
	[5] = 2_000_000, -- 2M
	[6] = 35_000_000, -- 35M
	[7] = 500_000_000, -- 500M
	[8] = 10_000_000_000, -- 10B
	[9] = 250_000_000_000, -- 250B
	[10] = 5_000_000_000_000, -- 5T
}

-- ═══════════════════════════════════════
-- CENTRAL CORE HUB
-- ═══════════════════════════════════════
Nodes["C_Core"] = {
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
}

-- ═══════════════════════════════════════
-- 1. COMBAT CONSTELLATION (Up-Left / Left)
-- ═══════════════════════════════════════
local prevDmg = "C_Core"
for i = 1, 10 do
	local id = "C_Dmg_" .. i
	local isMajor = (i % 3 == 0)
	local isKeystone = (i == 10)
	Nodes[id] = {
		id = id,
		name = "Sharp Blade " .. string.rep("I", i),
		desc = string.format("+%d%% Damage", if isKeystone then 100 elseif isMajor then 25 else 5),
		branch = "combat",
		nodeType = if isKeystone then "keystone" elseif isMajor then "major" else "minor",
		gridPos = Vector2.new(-100 * i - 20, -50 * i - 30),
		icon = if isKeystone then "👑" elseif isMajor then "💥" else "⚔",
		parents = { prevDmg },
		costType = "coins",
		cost = COIN_TIERS[i],
		effects = { damagePct = if isKeystone then 100 elseif isMajor then 25 else 5 },
	}
	prevDmg = id
end

-- Crit Branch off Dmg_2
local prevCrit = "C_Dmg_2"
for i = 1, 8 do
	local id = "C_Crit_" .. i
	local isMajor = (i % 4 == 0)
	Nodes[id] = {
		id = id,
		name = "Lethal Precision " .. i,
		desc = string.format("+%d%% Crit Chance", if isMajor then 5 else 2),
		branch = "combat",
		nodeType = if isMajor then "major" else "minor",
		gridPos = Vector2.new(-220 - 70 * i, -200 - 60 * i),
		icon = "🎯",
		parents = { prevCrit },
		costType = "coins",
		cost = COIN_TIERS[math.min(10, i + 1)],
		effects = { critChance = if isMajor then 5 else 2 },
	}
	prevCrit = id
end

-- Multi-Crit Branch off Crit_3
local prevMulti = "C_Crit_3"
for i = 1, 5 do
	local id = "C_MultiCrit_" .. i
	Nodes[id] = {
		id = id,
		name = "Overkill Multi-Crit " .. i,
		desc = "+1% Multi-Crit Chance",
		branch = "combat",
		nodeType = if i == 5 then "keystone" else "major",
		gridPos = Vector2.new(-380 - 80 * i, -320 - 40 * i),
		icon = "🔥",
		parents = { prevMulti },
		costType = "coins",
		cost = COIN_TIERS[math.min(10, i + 3)],
		effects = { multiCrit = 1 },
	}
	prevMulti = id
end

-- ═══════════════════════════════════════
-- 2. LUCK & RNG CONSTELLATION (Up-Right / Right)
-- ═══════════════════════════════════════
local prevLuck = "C_Core"
for i = 1, 10 do
	local id = "L_Luck_" .. i
	local isMajor = (i % 3 == 0)
	local isKeystone = (i == 5 or i == 10)
	local effectVal = if isKeystone then 50 elseif isMajor then 20 else 5
	local icon = if i == 5 then "🐾" elseif i == 10 then "👑" elseif isMajor then "🌟" else "🍀"
	
	Nodes[id] = {
		id = id,
		name = if i == 5 then "Beastmaster Domain" elseif i == 10 then "PET EMPEROR" else ("Four-Leaf Clover " .. i),
		desc = if i == 5 then "+1 Pet Equip Slot & +25% Luck" elseif i == 10 then "+1 Pet Equip Slot & +100% Luck" else string.format("+%d%% Luck", effectVal),
		branch = "luck",
		nodeType = if isKeystone then "keystone" elseif isMajor then "major" else "minor",
		gridPos = Vector2.new(100 * i + 20, -50 * i - 30),
		icon = icon,
		parents = { prevLuck },
		costType = "coins",
		cost = COIN_TIERS[i],
		effects = {
			luckPct = effectVal,
			petSlots = if isKeystone then 1 else nil,
		},
	}
	prevLuck = id
end

-- Key Finder Branch off Luck_2
local prevKeyLuck = "L_Luck_2"
for i = 1, 5 do
	local id = "L_KeyLuck_" .. i
	Nodes[id] = {
		id = id,
		name = "Key Finder " .. i,
		desc = "+5% Case Key Drop Luck",
		branch = "luck",
		nodeType = if i == 5 then "major" else "minor",
		gridPos = Vector2.new(220 + 70 * i, -200 - 60 * i),
		icon = "🔑",
		parents = { prevKeyLuck },
		costType = "coins",
		cost = COIN_TIERS[math.min(10, i + 2)],
		effects = { luckPct = 5 },
	}
	prevKeyLuck = id
end

-- ═══════════════════════════════════════
-- 3. SPEED & AGILITY CONSTELLATION (Down-Left)
-- ═══════════════════════════════════════
local prevSpeed = "C_Core"
for i = 1, 8 do
	local id = "S_Speed_" .. i
	local isKeystone = (i == 8)
	Nodes[id] = {
		id = id,
		name = if isKeystone then "LIGHT FOOTING" else ("Swift Boots " .. i),
		desc = if isKeystone then "+5 Walk Speed & +10% Attack Speed" else "+1 Walk Speed",
		branch = "speed",
		nodeType = if isKeystone then "keystone" elseif i % 3 == 0 then "major" else "minor",
		gridPos = Vector2.new(-90 * i - 20, 80 * i + 30),
		icon = if isKeystone then "🌪" else "⚡",
		parents = { prevSpeed },
		costType = "coins",
		cost = COIN_TIERS[math.min(10, i)],
		effects = {
			walkSpeed = if isKeystone then 5 else 1,
			clickSpeed = if isKeystone then 10 else nil,
		},
	}
	prevSpeed = id
end

-- Attack Speed Branch off Speed_2
local prevAtkSpeed = "S_Speed_2"
for i = 1, 8 do
	local id = "S_AtkSpeed_" .. i
	Nodes[id] = {
		id = id,
		name = "Quick Hands " .. i,
		desc = "+2% Attack Speed",
		branch = "speed",
		nodeType = if i % 3 == 0 then "major" else "minor",
		gridPos = Vector2.new(-180 - 60 * i, 160 + 70 * i),
		icon = "🗡",
		parents = { prevAtkSpeed },
		costType = "coins",
		cost = COIN_TIERS[math.min(10, i + 1)],
		effects = { clickSpeed = 2 },
	}
	prevAtkSpeed = id
end

-- ═══════════════════════════════════════
-- 4. UTILITY & COINS CONSTELLATION (Down-Right)
-- ═══════════════════════════════════════
local prevCoins = "C_Core"
for i = 1, 10 do
	local id = "U_Coins_" .. i
	local isKeystone = (i == 5 or i == 10)
	local isMajor = (i % 3 == 0)
	Nodes[id] = {
		id = id,
		name = if i == 5 then "RELIC MASTERY I" elseif i == 10 then "RELIC MASTERY II" else ("Golden Pouch " .. i),
		desc = if i == 5 then "+1 Relic Equip Slot & +25% Coins" elseif i == 10 then "+1 Relic Equip Slot & +100% Coins" else string.format("+%d%% Coins", if isMajor then 15 else 5),
		branch = "utility",
		nodeType = if isKeystone then "keystone" elseif isMajor then "major" else "minor",
		gridPos = Vector2.new(90 * i + 20, 80 * i + 30),
		icon = if isKeystone then "🔮" elseif isMajor then "💎" else "💰",
		parents = { prevCoins },
		costType = "coins",
		cost = COIN_TIERS[i],
		effects = {
			coinPct = if isKeystone then 50 elseif isMajor then 15 else 5,
			relicSlots = if isKeystone then 1 else nil,
		},
	}
	prevCoins = id
end

-- Backpack Branch off Coins_2
local prevBag = "U_Coins_2"
for i = 1, 8 do
	local id = "U_Backpack_" .. i
	Nodes[id] = {
		id = id,
		name = "Expanded Bag " .. i,
		desc = "+4 Inventory Slots to all Bags",
		branch = "utility",
		nodeType = if i % 3 == 0 then "major" else "minor",
		gridPos = Vector2.new(180 + 60 * i, 160 + 70 * i),
		icon = "🎒",
		parents = { prevBag },
		costType = "coins",
		cost = COIN_TIERS[math.min(10, i + 1)],
		effects = { bagSlots = 4 },
	}
	prevBag = id
end

-- ═══════════════════════════════════════
-- 5. PRESTIGE & REBIRTH CONSTELLATION (Straight Up)
-- Uses Talent Points from Rebirths!
-- ═══════════════════════════════════════
local prevPrestigeDmg = "C_Core"
for i = 1, 5 do
	local id = "P_RebirthDmg_" .. i
	Nodes[id] = {
		id = id,
		name = "Ascendant Might " .. i,
		desc = "+25% All Damage",
		branch = "prestige",
		nodeType = if i == 5 then "keystone" else "major",
		gridPos = Vector2.new(-60, -140 * i),
		icon = "🔱",
		parents = { prevPrestigeDmg },
		costType = "talentPoints",
		cost = i,
		effects = { damagePct = 25 },
	}
	prevPrestigeDmg = id
end

local prevPrestigeLuck = "C_Core"
for i = 1, 5 do
	local id = "P_RebirthLuck_" .. i
	Nodes[id] = {
		id = id,
		name = "Divine Fortune " .. i,
		desc = "+25% Luck",
		branch = "prestige",
		nodeType = if i == 5 then "keystone" else "major",
		gridPos = Vector2.new(60, -140 * i),
		icon = "☀️",
		parents = { prevPrestigeLuck },
		costType = "talentPoints",
		cost = i,
		effects = { luckPct = 25 },
	}
	prevPrestigeLuck = id
end

-- Master Ascendant Keystone (requires RebirthDmg_5 AND RebirthLuck_5)
Nodes["P_KeystoneMaster"] = {
	id = "P_KeystoneMaster",
	name = "MASTER ASCENDANT",
	desc = "+200% Global Power Multiplier",
	branch = "prestige",
	nodeType = "keystone",
	gridPos = Vector2.new(0, -840),
	icon = "🌌",
	parents = { "P_RebirthDmg_5", "P_RebirthLuck_5" },
	costType = "talentPoints",
	cost = 10,
	effects = { damagePct = 200 },
}

TalentTreeConfig.Nodes = Nodes

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
