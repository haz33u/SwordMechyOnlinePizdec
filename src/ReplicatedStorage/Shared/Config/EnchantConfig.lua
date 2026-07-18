--!strict
--[[
	Enchant roulette (skeleton).
	Roll costs shards-as-coins for now (single soft currency).
]]

export type EnchantDef = {
	id: string,
	name: string,
	stat: string, -- power | damage | attackSpeed | crit | coins | luck
	minValue: number,
	maxValue: number,
	weight: number,
	canDebuff: boolean?,
}

local EnchantConfig = {
	ROLL_COST = 200, -- coins fallback if no dust
	ROLL_COST_DUST = 1, -- preferred: boss enchant dust
	TRANSFER_COST = 500,
	TRANSFER_SUCCESS = 0.35,

	Qualities = {
		{ id = "Tiny", name = "Tiny", mult = 0.55, weight = 40 },
		{ id = "Normal", name = "Normal", mult = 0.80, weight = 30 },
		{ id = "Strong", name = "Strong", mult = 1.00, weight = 18 },
		{ id = "Huge", name = "Huge", mult = 1.25, weight = 9 },
		{ id = "Mighty", name = "Mighty", mult = 1.55, weight = 3 },
	},

	Enchants = {
		{ id = "PowerBoost", name = "Power Boost", stat = "power", minValue = 10, maxValue = 120, weight = 25 },
		{ id = "DamageBoost", name = "Damage Boost", stat = "damage", minValue = 10, maxValue = 100, weight = 25 },
		{ id = "AttackSpeed", name = "Attack Speed", stat = "attackSpeed", minValue = 10, maxValue = 90, weight = 20 },
		{ id = "Crit", name = "Crit Chance", stat = "crit", minValue = 5, maxValue = 80, weight = 12 },
		{ id = "Coins", name = "Coin Boost", stat = "coins", minValue = 5, maxValue = 50, weight = 12 },
		{ id = "Luck", name = "Luck", stat = "luck", minValue = 2, maxValue = 25, weight = 6 },
		-- debuff templates applied sometimes as second roll
		{ id = "Slow", name = "Slow", stat = "attackSpeed", minValue = -50, maxValue = -15, weight = 8, canDebuff = true },
	} :: { EnchantDef },

	MAX_ENCHANTS_PER_WEAPON = 3,
}

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

function EnchantConfig.Roll(): { id: string, value: number, quality: string }
	local quality = weightedPick(EnchantConfig.Qualities, "weight")
	local ench = weightedPick(EnchantConfig.Enchants, "weight")
	local base = ench.minValue + math.random() * (ench.maxValue - ench.minValue)
	local value = base * quality.mult
	-- 12% chance add as debuff if canDebuff type rolled already negative
	if ench.canDebuff then
		value = math.min(value, -10)
	end
	value = math.floor(value + 0.5)
	return {
		id = ench.id,
		value = value,
		quality = quality.id,
	}
end

return EnchantConfig
