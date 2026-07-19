--!strict
--[[
	Character upgrades (Loc1 dumps + later locks).

	Power costs L1–L9 (dump):
	  500 · 2.25K · 15K · 50K · 125K · 1.95M · 8.77M · 58.5M · 195M
	L10+: Cost(n) = 195_000_000 * 3.33^(n-9)

	Power: +5% total power / level (global)
	Attack Speed: +1% / level
	Backpack: base 32 per bag (weapons / pets / items), +1 slot each bag / level
	Crit + MultiCrit: locked until unlockLocation (not on Loc2)
]]

export type UpgradeDef = {
	id: string,
	name: string,
	maxLevel: number,
	baseCost: number,
	growth: number,
	effectPerLevel: number,
	effectType: string, -- "add" | "mult_add"
	statKey: string,
	costTable: { [number]: number }?,
	growthAfter: number?,
	unlockLocation: number?, -- min location id that must be unlocked
	unlockRebirth: number?,
}

local UpgradeConfig = {
	-- Base inventory size for each separate bag (weapons / pets / items)
	BASE_BAG_SLOTS = 32,

	Order = { "RunSpeed", "Backpack", "Power", "ClickSpeed", "CritChance", "MultiCrit", "Luck" },

	Defs = {
		RunSpeed = {
			id = "RunSpeed",
			name = "Run Speed",
			maxLevel = 50,
			baseCost = 50,
			growth = 1.35,
			effectPerLevel = 0.5, -- WalkSpeed +0.5 / lvl
			effectType = "add",
			statKey = "walkSpeedBonus",
		},
		Backpack = {
			id = "Backpack",
			name = "Backpack",
			maxLevel = 50,
			baseCost = 80,
			growth = 1.4,
			effectPerLevel = 1, -- +1 slot to EACH bag (weapons, pets, items)
			effectType = "add",
			statKey = "bagSlots",
		},
		Power = {
			id = "Power",
			name = "Power",
			maxLevel = 50,
			baseCost = 500,
			growth = 3.33,
			effectPerLevel = 0.05, -- +5% permanent power / level
			effectType = "mult_add",
			statKey = "upgradePower",
			costTable = {
				[1] = 500,
				[2] = 2_250,
				[3] = 15_000,
				[4] = 50_000,
				[5] = 125_000,
				[6] = 1_950_000, -- 1.95M
				[7] = 8_770_000, -- 8.77M
				[8] = 58_500_000, -- 58.5M
				[9] = 195_000_000, -- 195M
			},
			growthAfter = 3.33, -- L10+ from 195M
		},
		ClickSpeed = {
			id = "ClickSpeed",
			name = "Attack Speed",
			maxLevel = 40,
			baseCost = 120,
			growth = 1.32,
			effectPerLevel = 0.01, -- +1% attack speed / level
			effectType = "mult_add",
			statKey = "clickSpeed",
		},
		CritChance = {
			id = "CritChance",
			name = "Crit",
			maxLevel = 25,
			baseCost = 200,
			growth = 1.45,
			effectPerLevel = 0.01, -- +1% crit chance / level
			effectType = "add",
			statKey = "critChance",
			unlockLocation = 3, -- not on Loc1–2
		},
		MultiCrit = {
			id = "MultiCrit",
			name = "Multi Crit",
			maxLevel = 20,
			baseCost = 500,
			growth = 1.5,
			effectPerLevel = 0.01, -- +1% chance crit becomes multi (×3 dmg)
			effectType = "add",
			statKey = "multiCritChance",
			unlockLocation = 3, -- opens later (not Loc2)
		},
		Luck = {
			id = "Luck",
			name = "Luck",
			maxLevel = 30,
			baseCost = 150,
			growth = 1.4,
			effectPerLevel = 0.02,
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
	if nextLevel < 1 or nextLevel > def.maxLevel then
		return math.huge
	end
	if def.costTable and def.costTable[nextLevel] then
		return def.costTable[nextLevel]
	end
	if def.costTable then
		local lastKey = 0
		local lastCost = def.baseCost
		for k, v in def.costTable do
			if k > lastKey then
				lastKey = k
				lastCost = v
			end
		end
		if nextLevel > lastKey then
			local g = def.growthAfter or def.growth or 2.5
			return math.floor(lastCost * (g ^ (nextLevel - lastKey)) + 0.5)
		end
	end
	return math.floor(def.baseCost * (def.growth ^ (nextLevel - 1)))
end

--- Whether player may buy this upgrade (location / rebirth gates)
function UpgradeConfig.IsUnlocked(profile: any, id: string): (boolean, string?)
	local def = UpgradeConfig.Defs[id]
	if not def then
		return false, "Unknown upgrade"
	end
	local needLoc = def.unlockLocation
	if needLoc and needLoc > 0 then
		local ok = false
		for _, loc in profile.locationsUnlocked or { 1 } do
			if loc >= needLoc then
				ok = true
				break
			end
		end
		if not ok and (profile.currentLocation or 1) >= needLoc then
			ok = true
		end
		if not ok then
			return false, string.format("Unlocks on location %d+", needLoc)
		end
	end
	local needRb = def.unlockRebirth
	if needRb and needRb > 0 and (profile.rebirthLevel or 0) < needRb then
		return false, string.format("Need rebirth %d", needRb)
	end
	return true, nil
end

function UpgradeConfig.GetBagCap(profile: any, _kind: string?): number
	-- Separate bags share the same upgrade level (+1 each bag per Backpack level)
	local lvl = 0
	if profile and profile.upgradeLevels then
		lvl = profile.upgradeLevels.Backpack or 0
	end
	return UpgradeConfig.BASE_BAG_SLOTS + lvl * (UpgradeConfig.Defs.Backpack.effectPerLevel or 1)
end

return UpgradeConfig
