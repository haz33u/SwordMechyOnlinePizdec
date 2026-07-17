--!strict
--[[
	CLICKS = core earning loop (as in Мастера Мечей).

	Manual click  → 1 attack (if off cooldown)
	AutoClicker   → server-validated attacks at max CPS
	Each successful hit:
	  +1 totalClicks
	  +damage → lifetimeDamage (rebirth)
	  on kill → power + coins + loot
]]

local ClickConfig = {
	-- theoretical CPS = 1 / swingCooldown
	-- hard caps (anti-cheat + feel)
	MIN_CPS = 1.0,
	MAX_CPS = 50.0, -- skeleton cap; MM videos go 60–140 with endgame gear

	-- AutoClicker (F2P in skeleton — later can gate behind quest / soft unlock)
	AUTO_UNLOCKED_BY_DEFAULT = true,
	AUTO_UNLOCK_REBIRTH = 0, -- if not default: unlock at this rebirth
	AUTO_UNLOCK_QUEST = nil :: string?, -- e.g. "Q5_Rebirth"

	-- how auto works
	AUTO_USES_FULL_CPS = true, -- fire every swingCooldown
	AUTO_DAMAGE_MULT = 1.0, -- 1.0 = same as manual (true AFK farm)

	-- optional: offline / AFK bonus later
	AFK_CLICK_MULT = 1.0,
}

return ClickConfig
