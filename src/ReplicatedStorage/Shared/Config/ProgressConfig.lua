--!strict
--[[
	Progression unlocks: pet slots + offhand (second sword).

	Pet slots (max 7):
	  3  — start (free)
	  +1 — rebirth R2
	  +1 — rebirth R6
	  +1 — dungeon track (easy clears threshold)
	  +1 — paid (gamepass / shop stub)
	  ─────────────────
	  7 total

	Offhand (second sword 50% power):
	  PAID only — not free via rebirth/dungeon.

	Tune thresholds here only.
]]

local ProgressConfig = {
	----------------------------------------------------------------------
	-- Pet slots
	----------------------------------------------------------------------
	START_PET_SLOTS = 3,
	MAX_PET_SLOTS = 7,

	-- When rebirthLevel reaches `rebirth`, +`slots` (recalculated, not stacked spam)
	PetSlotsFromRebirth = {
		{ rebirth = 2, slots = 1, id = "rb_r2" }, -- 4th slot
		{ rebirth = 6, slots = 1, id = "rb_r6" }, -- 5th slot
	} :: { { rebirth: number, slots: number, id: string } },

	-- Dungeon clears (profile.dungeonStage[tier] >= clears)
	-- Separate from rebirth track. One-time thresholds.
	PetSlotsFromDungeon = {
		{ tier = "easy", clears = 5, slots = 1, id = "dg_easy_5" }, -- 6th slot
		-- hard path kept free for later; paid is 7th
	} :: { { tier: string, clears: number, slots: number, id: string } },

	-- Paid extra pet slot
	PAID_PET_SLOT = 1,

	----------------------------------------------------------------------
	-- Offhand (second sword for power) — paid only
	----------------------------------------------------------------------
	OFFHAND_PAID = true,

	----------------------------------------------------------------------
	-- DEBUG: free unlock paid features without R$ (playtest)
	----------------------------------------------------------------------
	DEBUG_FREE_PAID = true, -- set false when real gamepasses exist
}

--- Total pet slots for current progress (pure function)
function ProgressConfig.ComputePetSlots(profile: any): number
	local slots = ProgressConfig.START_PET_SLOTS

	local rb = profile.rebirthLevel or 0
	for _, m in ProgressConfig.PetSlotsFromRebirth do
		if rb >= m.rebirth then
			slots += m.slots
		end
	end

	local stages = profile.dungeonStage or {}
	for _, m in ProgressConfig.PetSlotsFromDungeon do
		local clears = stages[m.tier] or 0
		if clears >= m.clears then
			slots += m.slots
		end
	end

	local unlocks = profile.unlocks or {}
	if unlocks.paidPetSlot == true then
		slots += ProgressConfig.PAID_PET_SLOT
	end

	return math.clamp(slots, ProgressConfig.START_PET_SLOTS, ProgressConfig.MAX_PET_SLOTS)
end

function ProgressConfig.IsOffhandUnlocked(profile: any): boolean
	if not ProgressConfig.OFFHAND_PAID then
		return true
	end
	local unlocks = profile.unlocks or {}
	return unlocks.offhand == true
end

--- Next free unlock hint for UI (rebirth or dungeon), not paid
function ProgressConfig.GetNextPetSlotHint(profile: any): string?
	local rb = profile.rebirthLevel or 0
	for _, m in ProgressConfig.PetSlotsFromRebirth do
		if rb < m.rebirth then
			return string.format("Pet slot +1 at rebirth %d (now R%d)", m.rebirth, rb)
		end
	end
	local stages = profile.dungeonStage or {}
	for _, m in ProgressConfig.PetSlotsFromDungeon do
		local clears = stages[m.tier] or 0
		if clears < m.clears then
			return string.format(
				"Pet slot +1: dungeon %s %d/%d clears",
				m.tier,
				clears,
				m.clears
			)
		end
	end
	local unlocks = profile.unlocks or {}
	if unlocks.paidPetSlot ~= true then
		return "Pet slot +1: paid unlock"
	end
	return nil
end

return ProgressConfig
