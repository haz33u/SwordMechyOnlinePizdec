--!strict
--[[
	MasteryConfig.lua
	Config for Mastery System (Weapon Mastery & Mob Kill Mastery).
]]

export type MasteryDef = {
	id: string,
	name: string,
	category: "weapon" | "mob",
	maxLevel: number,
	xpPerLevel: { number },
	bonusPowerPctPerLevel: number,
	bonusCritPctPerLevel: number,
}

local MasteryConfig = {}

MasteryConfig.Defs = {
	weapon_sword = {
		id = "weapon_sword",
		name = "Sword Mastery",
		category = "weapon",
		maxLevel = 10,
		xpPerLevel = { 50, 120, 250, 500, 1000, 2000, 4000, 8000, 15000, 30000 },
		bonusPowerPctPerLevel = 2, -- +2% power per level
		bonusCritPctPerLevel = 0.5, -- +0.5% crit per level
	},
	mob_simple = {
		id = "mob_simple",
		name = "Slime & Beast Slayer",
		category = "mob",
		maxLevel = 10,
		xpPerLevel = { 20, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800 },
		bonusPowerPctPerLevel = 1.5,
		bonusCritPctPerLevel = 0.25,
	},
	mob_boss = {
		id = "mob_boss",
		name = "Boss Slayer Mastery",
		category = "mob",
		maxLevel = 10,
		xpPerLevel = { 5, 12, 25, 50, 100, 200, 400, 800, 1500, 3000 },
		bonusPowerPctPerLevel = 3.0,
		bonusCritPctPerLevel = 1.0,
	},
} :: { [string]: MasteryDef }

function MasteryConfig.Get(id: string): MasteryDef?
	return MasteryConfig.Defs[id]
end

function MasteryConfig.GetLevel(xp: number, def: MasteryDef): (number, number, number)
	local curLevel = 0
	local reqForNext = def.xpPerLevel[1] or 100
	local accumulated = 0

	for lvl, req in ipairs(def.xpPerLevel) do
		if xp >= req then
			curLevel = lvl
			accumulated = req
		else
			reqForNext = req
			break
		end
	end

	curLevel = math.clamp(curLevel, 0, def.maxLevel)
	local currentXpInLevel = math.max(0, xp - accumulated)
	local xpNeeded = math.max(1, reqForNext - accumulated)

	return curLevel, currentXpInLevel, xpNeeded
end

return MasteryConfig
