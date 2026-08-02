--!strict
--[[
	Named weapon enchant system.

	Each enchant has a family (damage, speed, coins, luck, lifesteal, boss, crit).
	Weapons can hold up to 3 enchants; duplicates stack by adding value.
	Rolling costs enchant dust (boss drops) and scales with reroll count.
]]

export type EnchantFamily =
	"sharpness"
	| "swiftness"
	| "fortune"
	| "luck"
	| "vampirism"
	| "bossSlayer"
	| "critEye"

export type EnchantDef = {
	id: string,
	name: string,
	family: EnchantFamily,
	stat: string,
	minValue: number,
	maxValue: number,
	weight: number,
}

export type EnchantRoll = {
	id: string,
	family: EnchantFamily,
	value: number,
	quality: string,
}

local EnchantConfig = {
	MAX_ENCHANTS_PER_WEAPON = 3,
	BASE_ROLL_DUST = 5,
	ROLL_DUST_GROWTH = 1.15,
	TRANSFER_DUST = 25,
	TRANSFER_SUCCESS = 0.35,

	Qualities = {
		{ id = "Tiny", name = "Tiny", mult = 0.50, weight = 40 },
		{ id = "Normal", name = "Normal", mult = 0.75, weight = 30 },
		{ id = "Strong", name = "Strong", mult = 1.00, weight = 18 },
		{ id = "Huge", name = "Huge", mult = 1.30, weight = 9 },
		{ id = "Mighty", name = "Mighty", mult = 1.70, weight = 3 },
	} :: { { id: string, name: string, mult: number, weight: number } },

	Enchants = {
		{
			id = "Sharpness",
			name = "Sharpness",
			family = "sharpness" :: EnchantFamily,
			stat = "damage",
			minValue = 5,
			maxValue = 25,
			weight = 25,
		},
		{
			id = "Swiftness",
			name = "Swiftness",
			family = "swiftness" :: EnchantFamily,
			stat = "attackSpeed",
			minValue = 4,
			maxValue = 20,
			weight = 20,
		},
		{
			id = "Fortune",
			name = "Fortune",
			family = "fortune" :: EnchantFamily,
			stat = "coins",
			minValue = 4,
			maxValue = 18,
			weight = 18,
		},
		{
			id = "Luck",
			name = "Luck",
			family = "luck" :: EnchantFamily,
			stat = "luck",
			minValue = 2,
			maxValue = 12,
			weight = 14,
		},
		{
			id = "Vampirism",
			name = "Vampirism",
			family = "vampirism" :: EnchantFamily,
			stat = "lifesteal",
			minValue = 1,
			maxValue = 5,
			weight = 10,
		},
		{
			id = "BossSlayer",
			name = "Boss Slayer",
			family = "bossSlayer" :: EnchantFamily,
			stat = "bossDamage",
			minValue = 6,
			maxValue = 30,
			weight = 8,
		},
		{
			id = "CritEye",
			name = "Critical Eye",
			family = "critEye" :: EnchantFamily,
			stat = "crit",
			minValue = 2,
			maxValue = 10,
			weight = 5,
		},
	} :: { EnchantDef },
}

function EnchantConfig.Get(id: string): EnchantDef?
	for _, e in EnchantConfig.Enchants do
		if e.id == id then
			return e
		end
	end
	return nil
end

function EnchantConfig.GetByFamily(family: string): EnchantDef?
	for _, e in EnchantConfig.Enchants do
		if e.family == family then
			return e
		end
	end
	return nil
end

local function weightedPick(list: { any }, weightKey: string): any
	local total = 0
	for _, item in list do
		total += item[weightKey]
	end
	local r = math.random() * total
	local acc = 0
	for _, item in list do
		acc += item[weightKey]
		if r <= acc then
			return item
		end
	end
	return list[#list]
end

function EnchantConfig.Roll(): EnchantRoll
	local quality = weightedPick(EnchantConfig.Qualities, "weight")
	local ench = weightedPick(EnchantConfig.Enchants, "weight")
	local base = ench.minValue + math.random() * (ench.maxValue - ench.minValue)
	local value = math.floor(base * quality.mult + 0.5)
	return {
		id = ench.id,
		family = ench.family,
		value = value,
		quality = quality.id,
	}
end

function EnchantConfig.GetRollDustCost(rerollCount: number): number
	local base = EnchantConfig.BASE_ROLL_DUST
	local growth = EnchantConfig.ROLL_DUST_GROWTH
	return math.floor(base * (growth ^ math.max(0, rerollCount)))
end

return EnchantConfig