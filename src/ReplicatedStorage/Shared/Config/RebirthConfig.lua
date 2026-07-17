--!strict
--[[
	Rebirth (перерождение) — skeleton curve.
	Not claimed as 1:1 Cristalix math; tunable for playtests.
	Cost = lifetime damage dealt. Soft rebirth (no inventory wipe).
]]

local RebirthConfig = {
	MAX_LEVEL = 30, -- skeleton cap (expand later)

	-- Cost(n) = BASE * GROWTH^(n-1)
	BASE_COST = 25_000,
	GROWTH = 2.2,

	-- Mult added as product: RebirthMult *= (1 + BONUS[n]) if BONUS table
	-- fallback: BONUS = BASE_BONUS + STEP * (n-1)
	BASE_BONUS = 0.25, -- R1 = +25% => x1.25
	BONUS_STEP = 0.05, -- each next +5%

	-- hard coded overrides (optional)
	BONUS_OVERRIDE = {
		-- [10] = 0.70,
	} :: { [number]: number },
}

function RebirthConfig.GetCost(level: number): number
	if level < 1 then
		return 0
	end
	return math.floor(RebirthConfig.BASE_COST * (RebirthConfig.GROWTH ^ (level - 1)))
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

return RebirthConfig
