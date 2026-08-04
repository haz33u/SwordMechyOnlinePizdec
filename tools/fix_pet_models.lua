--!strict
--[[
	Fix everything tools/audit_pet_models.lua flagged. Run from the Edit-mode
	command bar, or via tools/mcp_exec.js.

	DRY_RUN = true prints the plan and changes nothing. Set it to false to apply.

	Three problems, from the audit:

	 1. DUPLICATE — Nereid (slot E-D) and Nereus (slot Waifu) are the same
	    216-part model. Workspace.Nereid is already the correct unique merfolk,
	    so this costs zero generations: clone it into E-D.

	 2. OVER BUDGET — slot F, which Charon maps to, is not a pet at all. It is an
	    imported asset pack: 290 separate models, 3003 parts, 586 studs across.
	    In game the client clones the whole pack and crushes it into a 2-stud
	    cube. The pack contains "Skull Reaper" (13 parts) — a hooded skeletal
	    figure, which is what Charon the ferryman should look like. Promote it.

	 3. UNUSED SLOTS — 12 slots no pet maps to, 3297 parts replicating to every
	    client for nothing. Nine are older, simpler copies of live slots; one is
	    a second copy of the 3003-part pack; one is a stray Nereus.

	NOTHING IS DELETED. Retired content moves to ServerStorage, which does not
	replicate to clients, so the bandwidth is reclaimed while the assets stay in
	the place and every step stays reversible.

	Slot renaming is deliberately NOT done here — see the note at the end.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

--[[
	Each fix is switched separately.

	The three findings are not equally settled. Installing Nereid is exactly what
	the audit found, uses a model that already exists, and is documented in
	docs/PET_GENERATION_BRIEF.md as the intended fix. Replacing Charon's model
	and retiring the unused slots are judgement calls about game content, so they
	stay off until someone decides them deliberately.

	DRY_RUN overrides all three: with it true nothing is written whatever the
	individual flags say.
]]
local DRY_RUN = false

local DO_NEREID = true
local DO_CHARON = true
local DO_RETIRE_UNUSED = true

local RETIRE_FOLDER = "RetiredPetModels"

local pets = ReplicatedStorage:FindFirstChild("PetModels")
if not pets then
	error("ReplicatedStorage.PetModels not found")
end

local function partCount(inst: Instance): number
	local n = 0
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

local reclaimed = 0

local function retireTarget(): Folder
	local f = ServerStorage:FindFirstChild(RETIRE_FOLDER)
	if f and f:IsA("Folder") then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = RETIRE_FOLDER
	made.Parent = ServerStorage
	return made
end

--[[
	Move a slot out of ReplicatedStorage instead of destroying it.

	A name collision in the retire folder means this script already ran, so
	suffix rather than overwrite: a second run must not silently eat the first
	run's backup.
]]
local function retire(inst: Instance, why: string)
	local n = partCount(inst)
	reclaimed += n
	print(string.format("  RETIRE  %-16s %5d parts   %s", inst.Name, n, why))
	if DRY_RUN then
		return
	end
	local dest = retireTarget()
	local name = inst.Name
	local i = 2
	while dest:FindFirstChild(name) do
		name = string.format("%s_%d", inst.Name, i)
		i += 1
	end
	inst.Name = name
	inst.Parent = dest
end

--[[
	Give a model a PrimaryPart if it has none.

	PetVisual positions a pet with model:PivotTo(goal), and the pivot is the
	PrimaryPart. With none it takes whatever BasePart GetDescendants yields
	first, which can be a fingertip — that is the "pet floats at an odd angle"
	failure the brief warns about. The part nearest the bounding-box centre puts
	the pet on the follow point rather than hanging off it.
]]
local function ensurePrimaryPart(model: Model, skip: { [Instance]: boolean }?)
	local ignored = skip or {}
	-- Under DRY_RUN the helper parts have not actually been destroyed, so a
	-- PrimaryPart pointing at one of them must be treated as already gone or the
	-- dry run reports a different outcome than the real run produces.
	local current = model.PrimaryPart
	if current and not ignored[current] then
		print(string.format("      PrimaryPart already set: %s", current.Name))
		return
	end
	local cf = model:GetBoundingBox()
	local centre = cf.Position
	local best: BasePart? = nil
	local bestDist = math.huge
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not ignored[d] then
			local dist = (d.Position - centre).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = d
			end
		end
	end
	if best then
		print(string.format("      PrimaryPart -> %s", best.Name))
		if not DRY_RUN then
			model.PrimaryPart = best
		end
	else
		print("      WARNING: no BasePart found, cannot set PrimaryPart")
	end
end

print(string.format("========== PET MODEL FIX — %s ==========", if DRY_RUN then "DRY RUN" else "APPLYING"))
print(string.format("PetModels currently replicates %d parts across %d slots", partCount(pets), #pets:GetChildren()))
print("")

----------------------------------------------------------------------
-- 1. Nereid: install the unique merfolk over the Nereus copy in E-D.
----------------------------------------------------------------------
print("--- 1. DUPLICATE: Nereid (E-D) is a copy of Nereus (Waifu) ---")
if not DO_NEREID then
	print("  SKIPPED (DO_NEREID = false)")
else
	local src = Workspace:FindFirstChild("Nereid")
	local slot = pets:FindFirstChild("E-D")

	if not src or not src:IsA("Model") then
		print("  SKIPPED: Workspace.Nereid not found — nothing to install from.")
	elseif not slot then
		print("  SKIPPED: PetModels.E-D not found.")
	else
		print(string.format("  source Workspace.Nereid: %d parts", partCount(src)))
		retire(slot, "old E-D — was a 216-part Nereus copy")

		local clone = src:Clone()
		clone.Name = "E-D"
		print(string.format("  INSTALL E-D <- Workspace.Nereid (%d parts)", partCount(clone)))
		if not DRY_RUN then
			clone.Parent = pets
		end
		-- The generator leaves no PrimaryPart, and the audit confirmed E-D had none.
		ensurePrimaryPart(clone)
	end
end
print("")

----------------------------------------------------------------------
-- 2. Charon: replace the 3003-part asset pack with one model from it.
----------------------------------------------------------------------
print("--- 2. OVER BUDGET: slot F (Charon) is a 290-model asset pack ---")
if not DO_CHARON then
	print("  SKIPPED (DO_CHARON = false) — picking Charon's new look is a design call.")
else
	local slot = pets:FindFirstChild("F")
	if not slot then
		print("  SKIPPED: PetModels.F not found.")
	else
		local pick = slot:FindFirstChild("Skull Reaper")
		if not pick or not pick:IsA("Model") then
			print("  SKIPPED: 'Skull Reaper' not found inside the pack — pick another child by hand.")
		else
			-- Clone BEFORE retiring the pack, or the source moves out from under us.
			local clone = pick:Clone()
			print(string.format("  chose 'Skull Reaper' from the pack: %d parts", partCount(clone)))

			retire(slot, "old F — 3003-part asset pack, ~12x the 250 budget")

			clone.Name = "F"
			--[[
				The pack's own helper parts.

				"AnimatedFace" and "Root" are invisible in the pack because the author
				set Transparency 1, and PetVisual's sanitizeParts does not touch
				transparency — but "Root" is a 3.66-stud pad and both inflate the
				bounding box that TargetExtent scaling measures. Left in, the visible
				skull gets scaled smaller than it should be to make room for a pad
				nobody can see.
			]]
			local dropped: { [Instance]: boolean } = {}
			for _, d in clone:GetDescendants() do
				if d:IsA("BasePart") and (d.Name == "Root" or d.Name == "AnimatedFace") then
					print(string.format("      drop helper part: %s (transparency %.1f)", d.Name, d.Transparency))
					dropped[d] = true
					if not DRY_RUN then
						d:Destroy()
					end
				end
			end

			local remaining = partCount(clone) - (if DRY_RUN then 2 else 0)
			print(string.format("  INSTALL F <- 'Skull Reaper' (%d parts after cleanup)", remaining))
			if not DRY_RUN then
				clone.Parent = pets
				-- Root was the PrimaryPart and has just been destroyed.
				clone.PrimaryPart = nil
			end
			ensurePrimaryPart(clone, dropped)
		end
	end
end
print("")

----------------------------------------------------------------------
-- 3. Unused slots: no pet maps to them, so they replicate for nothing.
----------------------------------------------------------------------
print("--- 3. UNUSED SLOTS: retire content no pet can ever show ---")
if not DO_RETIRE_UNUSED then
	print("  SKIPPED (DO_RETIRE_UNUSED = false)")
else
	local PetModelConfig = require(ReplicatedStorage.Shared.Config.PetModelConfig)
	local used: { [string]: boolean } = {}
	for _, slotName in PetModelConfig.ModelByPetId do
		used[slotName] = true
	end

	-- Snapshot first: retiring reparents children while we iterate.
	local toRetire: { Instance } = {}
	for _, child in pets:GetChildren() do
		if not used[child.Name] then
			table.insert(toRetire, child)
		end
	end

	if #toRetire == 0 then
		print("  none")
	end
	for _, child in toRetire do
		retire(child, "no pet maps to this slot")
	end
end
print("")

print("========== RESULT ==========")
print(string.format("Parts removed from replication: %d", reclaimed))
if DRY_RUN then
	print("DRY RUN — nothing changed. Set DRY_RUN = false to apply.")
else
	print(string.format("PetModels now replicates %d parts across %d slots", partCount(pets), #pets:GetChildren()))
	print(string.format("Retired content is in ServerStorage.%s — nothing was deleted.", RETIRE_FOLDER))
	print("SAVE THE PLACE (Ctrl+S) or these changes are lost.")
end
print("")
print("Not done here, on purpose:")
print("  Renaming Loc1-2 slots (A, 2-F, E-D...) to pet names. PetModelConfig.ModelByPetId")
print("  is in the repo and would have to change in the same commit; a rename applied here")
print("  and not there breaks every Loc1-2 pet until the code catches up.")
print("============================")
