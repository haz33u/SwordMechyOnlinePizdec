--!strict
--[[
	Rebirth — from Cristalix dumps (docs/ref/cristalix/captures/rebirth_r1/r2.png)

	R1: Novice x1 → Beginner x3, progress 75K, ETA bar
	R2: Beginner x3 → Amateur x7, progress 2.5M

	UI shows ONE progress bar (damage/power dealt). After rebirth:
	  damage progress + coin balance wiped; swords/pets stay.
]]

local RebirthConfig = {
	MAX_LEVEL = 30,

	----------------------------------------------------------------------
	-- Absolute damage thresholds from dumps (level = next rebirth index)
	----------------------------------------------------------------------
	DAMAGE_COST = {
		[1] = 75_000, -- 75K (R1 dump)
		[2] = 2_500_000, -- 2.5M (R2 dump)
		[3] = 87_500_000, -- 87.5M (R3 dump)
	} :: { [number]: number },

	-- R2→R3 ≈ ×35; use for R4+
	GROWTH_AFTER_R3 = 35,

	----------------------------------------------------------------------
	-- Coin cost: dump UI has no coin bar — requirement is damage only.
	-- Coins still wipe on rebirth (balance lost).
	----------------------------------------------------------------------
	COIN_COST = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
	} :: { [number]: number },
	WIPE_COINS_ON_REBIRTH = true,
	WIPE_DAMAGE_ON_REBIRTH = true,

	----------------------------------------------------------------------
	-- Rank mult: Novice x1 → Beginner x3 → Amateur x7 → Strong x18
	----------------------------------------------------------------------
	RANK_MULT = {
		[0] = 1,
		[1] = 3,
		[2] = 7,
		[3] = 18,
	} :: { [number]: number },
	-- R4+: multiply last by this each step (18→~45→…)
	RANK_GROWTH = 2.5,

	RANK_NAME = {
		[0] = "Novice",
		[1] = "Beginner",
		[2] = "Amateur",
		[3] = "Strong", -- Сильный
		[4] = "Expert",
		[5] = "Master",
	} :: { [number]: string },

	-- ETA: coins/sec estimate if coinCost>0 (damage dealt → coins via farm ratio)
	ETA_COINS_PER_DAMAGE = 0.12,
}

function RebirthConfig.GetDamageCost(level: number): number
	if level < 1 then
		return 0
	end
	local fixed = RebirthConfig.DAMAGE_COST[level]
	if fixed then
		return fixed
	end
	local base = RebirthConfig.DAMAGE_COST[3] or 87_500_000
	local g = RebirthConfig.GROWTH_AFTER_R3 or 35
	return math.floor(base * (g ^ (level - 3)))
end

function RebirthConfig.GetCoinCost(level: number): number
	if level < 1 then
		return 0
	end
	local fixed = RebirthConfig.COIN_COST[level]
	if fixed ~= nil then
		return fixed
	end
	return 0
end

function RebirthConfig.GetCost(level: number): number
	return RebirthConfig.GetDamageCost(level)
end

function RebirthConfig.GetCosts(level: number): (number, number)
	return RebirthConfig.GetDamageCost(level), RebirthConfig.GetCoinCost(level)
end

function RebirthConfig.GetMultAfter(level: number): number
	if level <= 0 then
		return 1
	end
	local fixed = RebirthConfig.RANK_MULT[level]
	if fixed then
		return fixed
	end
	local m = RebirthConfig.RANK_MULT[3] or 18
	for _ = 4, level do
		m *= RebirthConfig.RANK_GROWTH
	end
	return m
end

function RebirthConfig.GetBonus(level: number): number
	-- delta from previous rank (for notify “+X%”)
	local prev = RebirthConfig.GetMultAfter(level - 1)
	local cur = RebirthConfig.GetMultAfter(level)
	if prev <= 0 then
		return 0
	end
	return (cur / prev) - 1
end

function RebirthConfig.GetRankName(level: number): string
	local n = RebirthConfig.RANK_NAME[level]
	if n then
		return n
	end
	if level > 5 then
		return "Master " .. tostring(level)
	end
	return "Rank " .. tostring(level)
end

function RebirthConfig.GetProgress(lifetimeDamage: number, coins: number, level: number): number
	local dmgCost, coinCost = RebirthConfig.GetCosts(level)
	local pDmg = if dmgCost > 0 then math.clamp(lifetimeDamage / dmgCost, 0, 1) else 1
	local pCoin = if coinCost > 0 then math.clamp(coins / coinCost, 0, 1) else 1
	return math.min(pDmg, pCoin)
end

function RebirthConfig.CanAfford(lifetimeDamage: number, coins: number, level: number): (boolean, string?)
	local dmgCost, coinCost = RebirthConfig.GetCosts(level)
	if lifetimeDamage < dmgCost then
		return false, string.format("Need %s damage (have %s)", tostring(dmgCost), tostring(math.floor(lifetimeDamage)))
	end
	if coinCost > 0 and coins < coinCost then
		return false, string.format("Need %s coins (have %s)", tostring(coinCost), tostring(math.floor(coins)))
	end
	return true, nil
end

return RebirthConfig
