--!strict
--[[
	Rebirth (перерождение) — dual cost: lifetimeDamage + Coins.

	Why coins:
	  Killing mobs must pay for progression (not only "hit dummy for damage").
	  Soft rebirth still keeps weapons/pets/locations.

	Numbers are RECONSTRUCTED skeleton, tunable for playtest.
]]

local RebirthConfig = {
	MAX_LEVEL = 30,

	----------------------------------------------------------------------
	-- DAMAGE cost: CostDmg(n) = BASE_DMG * GROWTH_DMG^(n-1)
	----------------------------------------------------------------------
	BASE_DMG_COST = 25_000,
	GROWTH_DMG = 2.2,

	----------------------------------------------------------------------
	-- COIN cost: CostCoins(n) = BASE_COINS * GROWTH_COINS^(n-1)
	-- Slightly softer than damage so both levers matter.
	----------------------------------------------------------------------
	BASE_COIN_COST = 5_000,
	GROWTH_COINS = 2.0,

	-- Mult: RebirthMult *= (1 + bonus)
	BASE_BONUS = 0.25, -- R1 → +25%
	BONUS_STEP = 0.05, -- each next +5%

	BONUS_OVERRIDE = {
		-- [10] = 0.70,
	} :: { [number]: number },
}

function RebirthConfig.GetCost(level: number): number
	-- alias: damage cost (back-compat name used across client)
	return RebirthConfig.GetDamageCost(level)
end

function RebirthConfig.GetDamageCost(level: number): number
	if level < 1 then
		return 0
	end
	return math.floor(RebirthConfig.BASE_DMG_COST * (RebirthConfig.GROWTH_DMG ^ (level - 1)))
end

function RebirthConfig.GetCoinCost(level: number): number
	if level < 1 then
		return 0
	end
	return math.floor(RebirthConfig.BASE_COIN_COST * (RebirthConfig.GROWTH_COINS ^ (level - 1)))
end

--- Returns damageCost, coinCost
function RebirthConfig.GetCosts(level: number): (number, number)
	return RebirthConfig.GetDamageCost(level), RebirthConfig.GetCoinCost(level)
end

function RebirthConfig.GetBonus(level: number): number
	local override = RebirthConfig.BONUS_OVERRIDE[level]
	if override then
		return override
	end
	return RebirthConfig.BASE_BONUS + RebirthConfig.BONUS_STEP * (level - 1)
end

function RebirthConfig.GetMultAfter(level: number): number
	local mult = 1
	for i = 1, level do
		mult *= (1 + RebirthConfig.GetBonus(i))
	end
	return mult
end

--- Overall readiness 0..1 (both resources; limited by the worse one)
function RebirthConfig.GetProgress(lifetimeDamage: number, coins: number, level: number): number
	local dmgCost, coinCost = RebirthConfig.GetCosts(level)
	local pDmg = if dmgCost > 0 then math.clamp(lifetimeDamage / dmgCost, 0, 1) else 1
	local pCoin = if coinCost > 0 then math.clamp(coins / coinCost, 0, 1) else 1
	return math.min(pDmg, pCoin)
end

function RebirthConfig.CanAfford(lifetimeDamage: number, coins: number, level: number): (boolean, string?)
	local dmgCost, coinCost = RebirthConfig.GetCosts(level)
	if lifetimeDamage < dmgCost then
		return false, string.format("Нужно %s урона (есть %s)", tostring(dmgCost), tostring(math.floor(lifetimeDamage)))
	end
	if coins < coinCost then
		return false, string.format("Нужно %s монет (есть %s)", tostring(coinCost), tostring(math.floor(coins)))
	end
	return true, nil
end

return RebirthConfig
