--!strict
--[[
	Case economy from dumps:
	  Loc1 pet coin = 500
	  Loc1 pet coin premium = 50K
	  Loc1 pet keys = 49
	  Loc2 pet coin = 3.75M
	  Loc2 pet keys = 54
	Default open uses PetConfig.DefaultPoolByLocation.
]]

local CaseConfig = {
	PET_KEY_COST = 0,
	AURA_KEY_COST = 1,
	PET_COIN_COST = 500, -- Loc1 default dump
	AURA_COIN_COST = 0,

	STARTER_PET_KEYS = 0,
	STARTER_AURA_KEYS = 2,

	PetKeyChance = {
		simple = 0.05,
		medium = 0.09,
		hard = 0.15,
		elite = 0.22,
		boss = 0.60,
		debug = 0,
	} :: { [string]: number },

	AuraKeyChance = {
		simple = 0.02,
		medium = 0.05,
		hard = 0.10,
		elite = 0.15,
		boss = 0.40,
		debug = 0,
	} :: { [string]: number },

	PetKeyAmount = {
		simple = { 1, 1 },
		medium = { 1, 1 },
		hard = { 1, 2 },
		elite = { 1, 2 },
		boss = { 1, 3 },
	} :: { [string]: { number } },

	AuraKeyAmount = {
		simple = { 1, 1 },
		medium = { 1, 1 },
		hard = { 1, 1 },
		elite = { 1, 2 },
		boss = { 1, 2 },
	} :: { [string]: { number } },
}

function CaseConfig.RollAmount(tableByTier: { [string]: { number } }, tier: string): number
	local range = tableByTier[tier] or tableByTier.medium or { 1, 1 }
	local a, b = range[1] or 1, range[2] or 1
	if b < a then
		b = a
	end
	return math.random(a, b)
end

return CaseConfig
