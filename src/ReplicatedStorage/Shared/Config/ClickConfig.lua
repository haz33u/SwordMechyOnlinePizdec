--!strict
--[[
	CLICKS = core earning loop.

	WITHOUT purchased auto-clicker:
	  - Absolute max CPS = 20
	  - Loc1 hard cap = 4
	  - Loc2+: Sam Click Mastery quest raises cap 6 → 20 (see SAM_CPS_BY_TIER)
	WITH purchased auto-clicker:
	  - MAX_CPS_PURCHASED (50)

	Sam quest uses Click Credit so display amounts can reach 2B without multi-year grind.
]]

local ClickConfig = {
	MIN_CPS = 1.0,

	MAX_CPS_WITHOUT_AUTO = 20,
	MAX_CPS_PURCHASED = 50,

	--[[
		Loc1 only until Sam / Loc2.
		Loc2+ free cap comes from samClickTier (SAM_CPS_BY_TIER).
	]]
	LOC1_CPS_CAP = 4,
	LOC_CPS_CAP = {
		[1] = 4,
		[2] = 6,
		[3] = 6,
		[4] = 6,
	} :: { [number]: number },

	-- After claiming Sam step N, tier = N. Index 0 = not started (Loc2 base).
	-- 22 entries: tiers 0..21
	SAM_CPS_BY_TIER = {
		[0] = 6,
		[1] = 7,
		[2] = 8,
		[3] = 9,
		[4] = 10,
		[5] = 11,
		[6] = 12,
		[7] = 13,
		[8] = 14,
		[9] = 15,
		[10] = 16,
		[11] = 16,
		[12] = 17,
		[13] = 17,
		[14] = 18,
		[15] = 18,
		[16] = 19,
		[17] = 19,
		[18] = 19,
		[19] = 20,
		[20] = 20,
		[21] = 20,
	} :: { [number]: number },

	--[[
		Progress credit while working on Sam step (tier = claims done = step-1).
		Display amounts stay huge; real swings stay finishable.
	]]
	SAM_CREDIT_BY_TIER = {
		[0] = 1,
		[1] = 1,
		[2] = 1,
		[3] = 2,
		[4] = 2,
		[5] = 2,
		[6] = 5,
		[7] = 5,
		[8] = 5,
		[9] = 15,
		[10] = 15,
		[11] = 15,
		[12] = 40,
		[13] = 40,
		[14] = 40,
		[15] = 100,
		[16] = 100,
		[17] = 300,
		[18] = 300,
		[19] = 800,
		[20] = 2000, -- on final 2B step
		[21] = 2000,
	} :: { [number]: number },

	AUTO_UNLOCKED_BY_DEFAULT = false,
	AUTO_UNLOCK_REBIRTH = 999,
	AUTO_UNLOCK_QUEST = nil :: string?,

	AUTO_USES_FULL_CPS = true,
	AUTO_DAMAGE_MULT = 1.0,
	AFK_CLICK_MULT = 1.0,
}

function ClickConfig.IsAutoPurchased(profile: any): boolean
	if not profile then
		return false
	end
	if ClickConfig.AUTO_UNLOCKED_BY_DEFAULT then
		return true
	end
	if profile.purchasedAutoClicker == true then
		return true
	end
	if profile.autoClickerUnlocked == true then
		return true
	end
	local unlocks = profile.unlocks
	if type(unlocks) == "table" and unlocks.autoClicker == true then
		return true
	end
	return false
end

function ClickConfig.GetSamTier(profile: any): number
	local t = profile and profile.samClickTier
	if type(t) ~= "number" then
		return 0
	end
	return math.clamp(math.floor(t), 0, 21)
end

function ClickConfig.GetSamCpsCap(profile: any): number
	local tier = ClickConfig.GetSamTier(profile)
	return ClickConfig.SAM_CPS_BY_TIER[tier] or 6
end

--- Credit applied to Sam click-quest progress per successful swing.
function ClickConfig.GetSamClickCredit(profile: any): number
	local tier = ClickConfig.GetSamTier(profile)
	return ClickConfig.SAM_CREDIT_BY_TIER[tier] or 1
end

--- Max CPS for this profile (Sam mastery + Loc1 + purchase)
function ClickConfig.GetMaxCPS(profile: any): number
	if ClickConfig.IsAutoPurchased(profile) then
		return ClickConfig.MAX_CPS_PURCHASED
	end
	local loc = (profile and profile.currentLocation) or 1
	if loc <= 1 then
		-- Loc1: hard 4 unless already has Sam progress from visit Loc2
		local sam = ClickConfig.GetSamCpsCap(profile)
		if (profile and profile.samClickTier or 0) > 0 then
			return math.min(ClickConfig.MAX_CPS_WITHOUT_AUTO, sam)
		end
		return ClickConfig.LOC1_CPS_CAP
	end
	-- Loc2+: Sam track is the free CPS path
	return math.min(ClickConfig.MAX_CPS_WITHOUT_AUTO, ClickConfig.GetSamCpsCap(profile))
end

ClickConfig.MAX_CPS = ClickConfig.MAX_CPS_WITHOUT_AUTO

return ClickConfig
