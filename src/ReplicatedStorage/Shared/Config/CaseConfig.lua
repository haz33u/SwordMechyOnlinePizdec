--!strict
--[[
	Case economy (P1): keys + open costs.
	Pets/auras open with KEYS (not free infinite). Coins optional secondary.
]]

local CaseConfig = {
	-- cost to open one case
	PET_KEY_COST = 1,
	AURA_KEY_COST = 1,
	-- optional coin surcharge (0 = keys only)
	PET_COIN_COST = 0,
	AURA_COIN_COST = 0,

	-- starter kit (new profiles / first session)
	STARTER_PET_KEYS = 5,
	STARTER_AURA_KEYS = 2,

	-- drop chance of +1 key on kill (by weapon tier family)
	-- tiers: simple / medium / hard / boss (WeaponConfig.NormalizeTier)
	PetKeyChance = {
		simple = 0.05,
		medium = 0.09,
		hard = 0.15,
		boss = 0.60,
		debug = 0,
	} :: { [string]: number },

	AuraKeyChance = {
		simple = 0.02,
		medium = 0.05,
		hard = 0.10,
		boss = 0.40,
		debug = 0,
	} :: { [string]: number },

	-- amount when key drops
	PetKeyAmount = {
		simple = { 1, 1 },
		medium = { 1, 1 },
		hard = { 1, 2 },
		boss = { 1, 3 },
	} :: { [string]: { number } },

	AuraKeyAmount = {
		simple = { 1, 1 },
		medium = { 1, 1 },
		hard = { 1, 1 },
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
