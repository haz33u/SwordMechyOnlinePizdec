--!strict
--[[
	CLICKS = core earning loop.

	WITHOUT purchased auto-clicker:
	  - Absolute max CPS in whole game = 20 (raised gradually by location)
	  - Loc1 hard cap = 4 CPS
	WITH purchased auto-clicker (later donat):
	  - Higher cap (MAX_CPS_PURCHASED)

	Manual + auto share the same server rate-limit (GetSwingCooldown).
]]

local ClickConfig = {
	MIN_CPS = 1.0,

	-- Absolute ceilings
	MAX_CPS_WITHOUT_AUTO = 20, -- never exceed without purchase (whole game)
	MAX_CPS_PURCHASED = 50, -- with bought auto-clicker (tune later)

	--[[
		Per-location CPS cap WITHOUT purchased auto.
		Ramps toward MAX_CPS_WITHOUT_AUTO = 20.
		Loc1 dump/feel = 4.
	]]
	LOC_CPS_CAP = {
		[1] = 4,
		[2] = 6,
		[3] = 8,
		[4] = 10,
		[5] = 12,
		[6] = 14,
		[7] = 16,
		[8] = 18,
		[9] = 20,
		-- Loc10+ stays at 20 without purchase
	} :: { [number]: number },

	-- AutoClicker purchase / unlock (NOT free by default)
	AUTO_UNLOCKED_BY_DEFAULT = false,
	AUTO_UNLOCK_REBIRTH = 999, -- not via rebirth; use purchase flag
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
	-- gamepass / UnlockService / legacy flags all count as purchased
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

--- Max CPS for this profile (location + purchase)
function ClickConfig.GetMaxCPS(profile: any): number
	if ClickConfig.IsAutoPurchased(profile) then
		return ClickConfig.MAX_CPS_PURCHASED
	end
	local loc = (profile and profile.currentLocation) or 1
	local locCap = ClickConfig.LOC_CPS_CAP[loc]
	if not locCap then
		locCap = math.min(ClickConfig.MAX_CPS_WITHOUT_AUTO, 4 + 2 * math.max(0, loc - 1))
	end
	return math.min(locCap, ClickConfig.MAX_CPS_WITHOUT_AUTO)
end

-- legacy alias
ClickConfig.MAX_CPS = ClickConfig.MAX_CPS_WITHOUT_AUTO

return ClickConfig

