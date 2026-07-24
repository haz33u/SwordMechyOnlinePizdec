--!strict
--[[
	Progression unlocks: pet slots + offhand (second sword).

	Pet equip slots (max 8 on character):
	  3  — start (free)
	  +1 — rebirth R2
	  +1 — rebirth R6
	  +1 — dungeon easy ×5
	  +1 — rebirth R12
	  +1 — paid (gamepass / shop stub)
	  ─────────────────
	  8 total

	Pet EQUIP slots max 8 (team). Pet BAG size = Backpack upgrade (base 32).

	Offhand (second sword 50% power):
	  PAID only — not free via rebirth/dungeon.

	Tune thresholds here only.
]]

local ProgressConfig = {
	----------------------------------------------------------------------
	-- Pet slots (equip team) — bag size is UpgradeConfig.BASE_BAG_SLOTS
	----------------------------------------------------------------------
	START_PET_SLOTS = 3,
	MAX_PET_SLOTS = 8, -- equip team hard cap
	MAX_PETS_OWNED = 32, -- legacy default; runtime uses Formulas.GetPetBagCap

	-- When rebirthLevel reaches `rebirth`, +`slots` (recalculated, not stacked spam)
	PetSlotsFromRebirth = {
		{ rebirth = 2, slots = 1, id = "rb_r2" }, -- 4th
		{ rebirth = 6, slots = 1, id = "rb_r6" }, -- 5th
		{ rebirth = 12, slots = 1, id = "rb_r12" }, -- 7th before paid fills 8
	} :: { { rebirth: number, slots: number, id: string } },

	-- Dungeon clears (profile.dungeonStage[tier] >= clears)
	PetSlotsFromDungeon = {
		{ tier = "easy", clears = 5, slots = 1, id = "dg_easy_5" }, -- 6th
	} :: { { tier: string, clears: number, slots: number, id: string } },

	-- Paid extra pet slot (8th if free path incomplete, else fills remaining)
	PAID_PET_SLOT = 1,

	----------------------------------------------------------------------
	-- Offhand (second sword for power) — paid only
	----------------------------------------------------------------------
	OFFHAND_PAID = true,

	----------------------------------------------------------------------
	-- DEBUG: free unlock paid features without R$ (playtest)
	----------------------------------------------------------------------
	-- Studio playtest: true = free unlock via UnlockPaidFeature.
	-- Live: false + real GamePass ownership (UnlockService).
	DEBUG_FREE_PAID = false,
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

	-- Frost case-open quest rewards (+1 at 10K opens step)
	local qSlots = profile.questPetSlots or 0
	if type(qSlots) == "number" and qSlots > 0 then
		slots += math.floor(qSlots)
	end

	-- Talent Tree Keystone Perks (+1 Pet Slot)
	local TalentTreeConfig = require(script.Parent.TalentTreeConfig)
	local talentStats = TalentTreeConfig.ComputeStats(profile and profile.unlockedTalents)
	if (talentStats.petSlots or 0) > 0 then
		slots += talentStats.petSlots
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
