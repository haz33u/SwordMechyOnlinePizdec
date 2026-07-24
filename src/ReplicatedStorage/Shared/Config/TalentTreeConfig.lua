--!strict
--[[
	TALENT TREE CONFIG (Hexagonal Honeycomb Lattice — Chemical Table Skill Grid)
	
	Nodes arranged on a tight axial hex grid (q, r).
	Hexes touch edge-to-edge without connecting line gaps.
	
	Branches radiating from central "C_Core" (0, 0):
	  - Combat (Left / Up-Left): Damage, Crit, Multi-Crit, Boss Slayer
	  - Luck & RNG (Right / Up-Right): Luck, Pet Slots, Key Drop
	  - Speed & Agility (Down-Left): Walk Speed, Attack Speed
	  - Utility & Coins (Down-Right): Coins, Backpack, Relic Slots
	  - Prestige / Rebirth (Straight Up): Talent Points Perks
]]

export type NodeType = "minor" | "major" | "keystone"
export type CurrencyType = "coins" | "talentPoints"

export type TalentNodeDef = {
	id: string,
	name: string,
	desc: string,
	branch: "combat" | "luck" | "speed" | "utility" | "prestige",
	nodeType: NodeType,
	hexPos: Vector2, -- Axial coordinates (q, r)
	icon: string,
	parents: { string },
	costType: CurrencyType,
	baseCost: number,
	costGrowth: number,
	maxLevel: number,
	reqSamTier: number?,
	reqFrostTier: number?,
	reqGrimTier: number?,
	reqLocation: number?,
	effectsPerLevel: {
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

-- ═══════════════════════════════════════
-- CENTRAL CORE HUB (0, 0)
-- ═══════════════════════════════════════
Nodes["C_Core"] = {
	id = "C_Core",
	name = "Player Core",
	desc = "The origin of your inner power.",
	branch = "combat",
	nodeType = "keystone",
	hexPos = Vector2.new(0, 0),
	icon = "☸",
	parents = {},
	costType = "coins",
	baseCost = 0,
	costGrowth = 1.0,
	maxLevel = 1,
	effectsPerLevel = {},
}

-- ═══════════════════════════════════════
-- 1. COMBAT BRANCH (Up-Left / Left Hex Lattice)
-- ═══════════════════════════════════════
-- Chain: q = -1..-8, r = 0..-4
local prevDmg = "C_Core"
for i = 1, 8 do
	local id = "C_Dmg_" .. i
	local q = -i
	local r = -math.floor(i / 2)
	Nodes[id] = {
		id = id,
		name = "Sharp Blade " .. string.rep("I", i),
		desc = "+5% Damage per level",
		branch = "combat",
		nodeType = if i % 3 == 0 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = if i % 3 == 0 then "💥" else "⚔",
		parents = { prevDmg },
		costType = "coins",
		baseCost = 100 * (4 ^ (i - 1)),
		costGrowth = 1.35,
		maxLevel = 50,
		reqLocation = if i > 3 then math.min(19, i * 2) else nil,
		effectsPerLevel = { damagePct = 5 },
	}
	prevDmg = id
end

-- Crit Branch (Adjacent to Dmg_2: q = -2, r = -2)
local prevCrit = "C_Dmg_2"
for i = 1, 6 do
	local id = "C_Crit_" .. i
	local q = -2 - i
	local r = -1 - i
	Nodes[id] = {
		id = id,
		name = "Lethal Precision " .. i,
		desc = "+1% Crit Chance per level",
		branch = "combat",
		nodeType = if i % 3 == 0 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = "🎯",
		parents = { prevCrit },
		costType = "coins",
		baseCost = 1000 * (5 ^ (i - 1)),
		costGrowth = 1.4,
		maxLevel = 25,
		effectsPerLevel = { critChance = 1 },
	}
	prevCrit = id
end

-- Multi-Crit Branch off Crit_3
local prevMulti = "C_Crit_3"
for i = 1, 4 do
	local id = "C_MultiCrit_" .. i
	local q = -5 - i
	local r = -4
	Nodes[id] = {
		id = id,
		name = "Overkill Multi-Crit " .. i,
		desc = "+1% Multi-Crit Chance per level",
		branch = "combat",
		nodeType = if i == 4 then "keystone" else "major",
		hexPos = Vector2.new(q, r),
		icon = "🔥",
		parents = { prevMulti },
		costType = "coins",
		baseCost = 50000 * (8 ^ (i - 1)),
		costGrowth = 1.5,
		maxLevel = 10,
		effectsPerLevel = { multiCrit = 1 },
	}
	prevMulti = id
end

-- ═══════════════════════════════════════
-- 2. LUCK & RNG BRANCH (Up-Right / Right Hex Lattice)
-- ═══════════════════════════════════════
local prevLuck = "C_Core"
for i = 1, 8 do
	local id = "L_Luck_" .. i
	local q = i
	local r = -math.floor(i / 2)
	local isKeystone = (i == 4 or i == 8)
	
	Nodes[id] = {
		id = id,
		name = if i == 4 then "Beastmaster Domain" elseif i == 8 then "PET EMPEROR" else ("Four-Leaf Clover " .. i),
		desc = if i == 4 then "+1 Pet Slot & +5% Luck/lvl [Case Quester Step 5]" elseif i == 8 then "+1 Pet Slot & +10% Luck/lvl [Case Quester Step 15]" else "+5% Luck per level",
		branch = "luck",
		nodeType = if isKeystone then "keystone" elseif i % 3 == 0 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = if i == 4 then "🐾" elseif i == 8 then "👑" else "🍀",
		parents = { prevLuck },
		costType = "coins",
		baseCost = 150 * (4 ^ (i - 1)),
		costGrowth = 1.35,
		maxLevel = if isKeystone then 1 else 40,
		reqFrostTier = if i == 4 then 5 elseif i == 8 then 15 else nil,
		effectsPerLevel = {
			luckPct = 5,
			petSlots = if isKeystone then 1 else nil,
		},
	}
	prevLuck = id
end

-- Key Finder Branch off Luck_2
local prevKeyLuck = "L_Luck_2"
for i = 1, 4 do
	local id = "L_KeyLuck_" .. i
	local q = 2 + i
	local r = -1 - i
	Nodes[id] = {
		id = id,
		name = "Key Finder " .. i,
		desc = "+5% Key Drop Luck per level",
		branch = "luck",
		nodeType = if i == 4 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = "🔑",
		parents = { prevKeyLuck },
		costType = "coins",
		baseCost = 2000 * (6 ^ (i - 1)),
		costGrowth = 1.4,
		maxLevel = 20,
		effectsPerLevel = { luckPct = 5 },
	}
	prevKeyLuck = id
end

-- ═══════════════════════════════════════
-- 3. SPEED & AGILITY BRANCH (Down-Left Hex Lattice)
-- ═══════════════════════════════════════
local prevSpeed = "C_Core"
for i = 1, 6 do
	local id = "S_Speed_" .. i
	local q = -math.floor(i / 2)
	local r = i
	Nodes[id] = {
		id = id,
		name = if i == 6 then "LIGHT FOOTING" else ("Swift Boots " .. i),
		desc = if i == 6 then "+5 Walk Speed & +10% Atk Speed" else "+1 Walk Speed per level",
		branch = "speed",
		nodeType = if i == 6 then "keystone" elseif i % 3 == 0 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = if i == 6 then "🌪" else "⚡",
		parents = { prevSpeed },
		costType = "coins",
		baseCost = 80 * (4 ^ (i - 1)),
		costGrowth = 1.3,
		maxLevel = if i == 6 then 1 else 30,
		effectsPerLevel = {
			walkSpeed = if i == 6 then 5 else 1,
			clickSpeed = if i == 6 then 10 else nil,
		},
	}
	prevSpeed = id
end

-- Attack Speed Branch off Speed_2 (Gated by Click Quester Sam Tier)
local prevAtkSpeed = "S_Speed_2"
for i = 1, 6 do
	local id = "S_AtkSpeed_" .. i
	local q = -1 - i
	local r = 2 + i
	Nodes[id] = {
		id = id,
		name = "Quick Hands " .. i,
		desc = string.format("+2%% Attack Speed per level [Click Quester Step %d]", i),
		branch = "speed",
		nodeType = if i % 3 == 0 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = "🗡",
		parents = { prevAtkSpeed },
		costType = "coins",
		baseCost = 1500 * (5 ^ (i - 1)),
		costGrowth = 1.35,
		maxLevel = 20,
		reqSamTier = i,
		effectsPerLevel = { clickSpeed = 2 },
	}
	prevAtkSpeed = id
end

-- ═══════════════════════════════════════
-- 4. UTILITY & COINS BRANCH (Down-Right Hex Lattice)
-- ═══════════════════════════════════════
local prevCoins = "C_Core"
for i = 1, 8 do
	local id = "U_Coins_" .. i
	local q = math.floor(i / 2)
	local r = i
	local isKeystone = (i == 4 or i == 8)
	Nodes[id] = {
		id = id,
		name = if i == 4 then "RELIC MASTERY I" elseif i == 8 then "RELIC MASTERY II" else ("Golden Pouch " .. i),
		desc = if i == 4 then "+1 Relic Slot & +25% Coins [Power Quester Step 8]" elseif i == 8 then "+1 Relic Slot & +100% Coins [Power Quester Step 15]" else "+5% Coins per level",
		branch = "utility",
		nodeType = if isKeystone then "keystone" elseif i % 3 == 0 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = if isKeystone then "🔮" else "💰",
		parents = { prevCoins },
		costType = "coins",
		baseCost = 100 * (4 ^ (i - 1)),
		costGrowth = 1.35,
		maxLevel = if isKeystone then 1 else 50,
		reqGrimTier = if i == 4 then 8 elseif i == 8 then 15 else nil,
		effectsPerLevel = {
			coinPct = if isKeystone then 25 else 5,
			relicSlots = if isKeystone then 1 else nil,
		},
	}
	prevCoins = id
end

-- Backpack Branch off Coins_2
local prevBag = "U_Coins_2"
for i = 1, 6 do
	local id = "U_Backpack_" .. i
	local q = 1 + i
	local r = 2 + i
	Nodes[id] = {
		id = id,
		name = "Expanded Bag " .. i,
		desc = "+2 Inventory Slots per level to all Bags",
		branch = "utility",
		nodeType = if i % 3 == 0 then "major" else "minor",
		hexPos = Vector2.new(q, r),
		icon = "🎒",
		parents = { prevBag },
		costType = "coins",
		costGrowth = 1.35,
		baseCost = 800 * (5 ^ (i - 1)),
		maxLevel = 30,
		effectsPerLevel = { bagSlots = 2 },
	}
	prevBag = id
end

-- ═══════════════════════════════════════
-- 5. PRESTIGE & REBIRTH BRANCH (Straight Up: q = 0, r = -1..-5)
-- Uses Talent Points from Rebirths!
-- ═══════════════════════════════════════
local prevPrestigeDmg = "C_Core"
for i = 1, 5 do
	local id = "P_RebirthDmg_" .. i
	Nodes[id] = {
		id = id,
		name = "Ascendant Might " .. i,
		desc = "+20% All Damage per level",
		branch = "prestige",
		nodeType = if i == 5 then "keystone" else "major",
		hexPos = Vector2.new(0, -i),
		icon = "🔱",
		parents = { prevPrestigeDmg },
		costType = "talentPoints",
		baseCost = i,
		costGrowth = 1.0,
		maxLevel = 10,
		effectsPerLevel = { damagePct = 20 },
	}
	prevPrestigeDmg = id
end

TalentTreeConfig.Nodes = Nodes

function TalentTreeConfig.Get(nodeId: string): TalentNodeDef?
	return TalentTreeConfig.Nodes[nodeId]
end

function TalentTreeConfig.GetAll(): { [string]: TalentNodeDef }
	return TalentTreeConfig.Nodes
end

--- Calculates cost for upgrading a node to next level
function TalentTreeConfig.GetUpgradeCost(def: TalentNodeDef, currentLevel: number): number
	if currentLevel >= def.maxLevel then
		return 0
	end
	if def.costType == "talentPoints" then
		return def.baseCost
	end
	return math.floor(def.baseCost * (def.costGrowth ^ currentLevel))
end

--- Aggregates all stat bonuses from an array or map of node levels
function TalentTreeConfig.ComputeStats(unlockedTalents: { [string]: any }?)
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
	for nodeId, levelVal in unlockedTalents do
		local lvl = if type(levelVal) == "number" then levelVal else (if levelVal == true then 1 else 0)
		if lvl > 0 then
			local def = TalentTreeConfig.Nodes[nodeId]
			if def and def.effectsPerLevel then
				for stat, val in def.effectsPerLevel do
					if type(val) == "number" and totals[stat] ~= nil then
						totals[stat] += val * lvl
					end
				end
			end
		end
	end
	return totals
end

return TalentTreeConfig
