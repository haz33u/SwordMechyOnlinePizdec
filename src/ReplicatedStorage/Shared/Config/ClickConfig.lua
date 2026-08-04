--!strict
--[[
	CLICKS = core earning loop.

	WITHOUT the autoClicker gamepass:
	  - No auto-clicking at all (enforced server-side in CombatService)
	  - Max CPS = flat F2P_MAX_CPS (10). Talent-Tree maxCps bonuses do NOT apply;
	    this deliberately replaces MASTER_PLAN §6.5's 4→8 progression.
	WITH the gamepass:
	  - Base 4 + Talent-Tree bonuses, ceilinged by MAX_CPS_PURCHASED and the
	    per-location LOC_CPS_CAP.

	Sam quest uses Click Credit so display amounts can reach 2B without multi-year grind.
	NOTE: SAM_CPS_BY_TIER / GetSamCpsCap now only feed quest notification text
	(QuestService.lua:181) — they do not raise the cap.
]]

local ClickConfig = {
	MIN_CPS = 1.0,

	MAX_CPS_WITHOUT_AUTO = 20,

	--[[
		>>> PAID TIER CPS CAP — TUNE HERE <<<
		The gamepass tier's ceiling. Conceptually "unlimited": at 50 CPS the swing
		cooldown floor is 0.02s, far past what a client can drive, so in practice
		only the per-location LOC_CPS_CAP binds for paying players. This is the number
		to change when tuning the paid tier — see GetMaxCPS below for how it applies.
	]]
	MAX_CPS_PURCHASED = 50,

	--[[
		F2P (no gamepass) cap: a flat 10 CPS.
		Deliberately REPLACES MASTER_PLAN §6.5's 4→8 Talent-Tree CPS progression —
		product decision, not a bug. Talent maxCps bonuses no longer raise the free
		cap; the flat value is the whole story for players without the pass.
	]]
	F2P_MAX_CPS = 10,

	--[[
		Loc1 only until Sam / Loc2.
		Loc2+ free cap comes from samClickTier (SAM_CPS_BY_TIER).
	]]
	LOC1_CPS_CAP = 4,
	LOC_CPS_CAP = {
		[1] = 4,
		[2] = 6,
		[3] = 8,
		[4] = 10,
		[5] = 12,
		[6] = 16,
		[7] = 20,
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

	--[[
		Auto-clicker is gamepass-gated (MASTER_PLAN §6.5). This was flipped to true in
		ca6c706 to hand everyone a free auto-clicker, which short-circuited
		IsAutoPurchased and made the ownership check below dead code. Reverted.
	]]
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

--- Max CPS for this profile. Paid tier = talent-scaled up to MAX_CPS_PURCHASED;
--- free tier = flat F2P_MAX_CPS (see the constant for why talents don't apply).
function ClickConfig.GetMaxCPS(profile: any): number
	local baseCps = 4.0 -- Base CPS cap is 4 clicks per second for everyone
	if not profile then
		return baseCps
	end

	if not ClickConfig.IsAutoPurchased(profile) then
		-- Flat free-tier cap: no talent bonuses, no per-location scaling. This
		-- deliberately replaces §6.5's 4→8 Talent-Tree progression.
		return ClickConfig.F2P_MAX_CPS
	end

	-- Location-based hard cap (Loc1=4, Loc2+ raises via LOC_CPS_CAP)
	local locId = profile.currentLocation or 1
	local locCap = ClickConfig.LOC_CPS_CAP[locId] or ClickConfig.LOC1_CPS_CAP

	local ok, TalentTreeConfig = pcall(function()
		return require(script.Parent.TalentTreeConfig)
	end)
	local talentStats = if ok and TalentTreeConfig then TalentTreeConfig.ComputeStats(profile.unlockedTalents) else nil
	local bonusCps = (talentStats and talentStats.maxCps) or 0

	-- Paid tier ceiling — MAX_CPS_PURCHASED is the value to tune (see its comment).
	local totalCps = baseCps + bonusCps
	return math.min(ClickConfig.MAX_CPS_PURCHASED, locCap, math.max(baseCps, totalCps))
end

ClickConfig.MAX_CPS = ClickConfig.MAX_CPS_WITHOUT_AUTO

return ClickConfig
