--!strict
--[[
	Character upgrades (NPC style from MM):
	RunSpeed, Backpack, Power, ClickSpeed, CritChance, Luck
	Paid with Coins only (skeleton).
]]

export type UpgradeDef = {
	id: string,
	name: string,
	maxLevel: number,
	baseCost: number,
	growth: number,
	-- effect per level
	effectPerLevel: number,
	effectType: string, -- "add" | "mult_add" (adds to a 1+x mult pool)
	statKey: string,
}

local UpgradeConfig = {
	Order = { "RunSpeed", "Backpack", "Power", "ClickSpeed", "CritChance", "Luck" },

	Defs = {
		RunSpeed = {
			id = "RunSpeed",
			name = "Run Speed",
			maxLevel = 50,
			baseCost = 50,
			growth = 1.35,
			effectPerLevel = 0.5, -- WalkSpeed +0.5 / lvl (from base 16)
			effectType = "add",
			statKey = "walkSpeedBonus",
		},
		Backpack = {
			id = "Backpack",
			name = "Backpack",
			maxLevel = 30,
			baseCost = 80,
			growth = 1.4,
			effectPerLevel = 2, -- +2 inventory slots display
			effectType = "add",
			statKey = "bagSlots",
		},
		Power = {
			id = "Power",
			name = "Power",
			maxLevel = 100,
			baseCost = 100,
			growth = 1.28,
			effectPerLevel = 0.02, -- +2% power mult pool per level
			effectType = "mult_add",
			statKey = "upgradePower",
		},
		ClickSpeed = {
			id = "ClickSpeed",
			name = "Attack Speed",
			maxLevel = 40,
			baseCost = 120,
			growth = 1.32,
			effectPerLevel = 0.015, -- -1.5% swing CD per level
			effectType = "mult_add",
			statKey = "clickSpeed",
		},
		CritChance = {
			id = "CritChance",
			name = "Crit",
			maxLevel = 25,
			baseCost = 200,
			growth = 1.45,
			effectPerLevel = 0.01, -- +1% crit
			effectType = "add",
			statKey = "critChance",
		},
		Luck = {
			id = "Luck",
			name = "Luck",
			maxLevel = 30,
			baseCost = 150,
			growth = 1.4,
			effectPerLevel = 0.02, -- +2% rare drop weight
			effectType = "add",
			statKey = "luck",
		},
	} :: { [string]: UpgradeDef },
}

function UpgradeConfig.GetCost(id: string, nextLevel: number): number
	local def = UpgradeConfig.Defs[id]
	if not def then
		return math.huge
	end
	if nextLevel > def.maxLevel then
		return math.huge
	end
	return math.floor(def.baseCost * (def.growth ^ (nextLevel - 1)))
end

return UpgradeConfig
