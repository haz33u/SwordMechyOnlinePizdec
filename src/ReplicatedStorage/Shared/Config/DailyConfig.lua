--!strict
--[[
	Daily login rewards and streak logic.
	Streak resets if gap > 48 hours. Rewards scale by location/rebirth.
]]

local DailyConfig = {
	-- seconds allowed between claims before streak resets
	STREAK_GRACE_SECONDS = 48 * 3600,

	-- base rewards per day (soft-scaled by GetReward)
	BaseRewards = {
		{ day = 1, coinsPct = 0.05, keys = 1, dust = 0 },
		{ day = 2, coinsPct = 0.06, keys = 1, dust = 5 },
		{ day = 3, coinsPct = 0.08, keys = 2, dust = 10 },
		{ day = 4, coinsPct = 0.10, keys = 2, dust = 15 },
		{ day = 5, coinsPct = 0.12, keys = 3, dust = 20 },
		{ day = 6, coinsPct = 0.15, keys = 3, dust = 25 },
		{ day = 7, coinsPct = 0.25, keys = 5, dust = 50, petKeys = 1 },
	} :: { { day: number, coinsPct: number, keys: number, dust: number, petKeys: number? } },

	-- streak milestone bonus (every N days)
	STREAK_BONUS_EVERY = 7,
	STREAK_BONUS_MULT = 1.5,
}

function DailyConfig.GetDayReward(day: number): { coinsPct: number, keys: number, dust: number, petKeys: number }
	local d = math.clamp((day - 1) % 7 + 1, 1, 7)
	for _, r in DailyConfig.BaseRewards do
		if r.day == d then
			return {
				coinsPct = r.coinsPct,
				keys = r.keys,
				dust = r.dust,
				petKeys = r.petKeys or 0,
			}
		end
	end
	return { coinsPct = 0.05, keys = 1, dust = 0, petKeys = 0 }
end

function DailyConfig.GetReward(profile: any, day: number): { coins: number, keys: number, dust: number, petKeys: number }
	local r = DailyConfig.GetDayReward(day)
	local loc = profile.currentLocation or 1
	local baseCoins = 500 * (10 ^ (loc - 1))
	local coins = math.floor(baseCoins * r.coinsPct * (1 + (profile.rebirthLevel or 0) * 0.1))
	local streakMult = 1.0
	if day > 0 and day % DailyConfig.STREAK_BONUS_EVERY == 0 then
		streakMult = DailyConfig.STREAK_BONUS_MULT
	end
	return {
		coins = math.floor(coins * streakMult),
		keys = math.floor(r.keys * streakMult),
		dust = math.floor(r.dust * streakMult),
		petKeys = math.floor(r.petKeys * streakMult),
	}
end

return DailyConfig
