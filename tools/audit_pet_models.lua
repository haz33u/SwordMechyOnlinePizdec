--!strict
--[[
	Pet model audit — run from the Studio command bar in Edit mode.

	Answers one question: which pets are visually indistinguishable from each
	other, and what exactly has to be generated to make all 53 unique?

	Reads only. Deletes nothing, moves nothing.

	Why this exists: PetModelConfig maps every pet to a DIFFERENT slot name, so
	no code check can catch the problem. The duplicates live in the CONTENT of
	differently-named slots — "Waifu", "E-D" and "S-A" are three names for one
	216-part Nereus model. Only comparing geometry finds them.

	Output: paste the printed report back into the chat, or into
	docs/ref/PET_MODEL_AUDIT.md, so the generation queue lives in the repo
	instead of in someone's memory.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local PetModelConfig = require(ReplicatedStorage.Shared.Config.PetModelConfig)

local PART_BUDGET = 250

local folder = ReplicatedStorage:FindFirstChild(PetModelConfig.FolderName or "PetModels")
if not folder then
	error("PetModels folder not found in ReplicatedStorage")
end

--[[
	Content signature.

	Two models are "the same" when their parts have the same names, the same
	rounded sizes and the same rounded colors. Rounding absorbs float noise and
	uniform rescaling; sorting makes the signature independent of child order,
	which differs between clones of one source.
]]
local function signature(model: Model): (string, number)
	local rows: { string } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local s, c = d.Size, d.Color
			table.insert(
				rows,
				string.format(
					"%s|%.1f,%.1f,%.1f|%d,%d,%d",
					d.Name,
					s.X,
					s.Y,
					s.Z,
					math.round(c.R * 255),
					math.round(c.G * 255),
					math.round(c.B * 255)
				)
			)
		end
	end
	table.sort(rows)
	return table.concat(rows, ";"), #rows
end

-- petId → {name, rarity, slot}
type Row = { petId: string, name: string, rarity: string, slot: string, parts: number }

local bySig: { [string]: { Row } } = {}
local missing: { Row } = {}
local heavy: { Row } = {}
local order: { string } = {}

--[[
	PetConfig.Pets is keyed by id, so iteration order is arbitrary. Sort by id so
	two runs of this audit produce byte-identical reports and can be diffed.
]]
local petIds: { string } = {}
for id in PetConfig.Pets do
	table.insert(petIds, id)
end
table.sort(petIds)

for _, id in petIds do
	local def = PetConfig.Pets[id]
	local slot = PetModelConfig.GetModelName(id)
	local row: Row = {
		petId = id,
		name = def.name,
		rarity = def.rarity,
		slot = slot or "(none)",
		parts = 0,
	}

	local model = if slot then folder:FindFirstChild(slot) else nil
	if not model or not model:IsA("Model") then
		table.insert(missing, row)
	else
		local sig, parts = signature(model)
		row.parts = parts
		if parts > PART_BUDGET then
			table.insert(heavy, row)
		end
		if not bySig[sig] then
			bySig[sig] = {}
			table.insert(order, sig)
		end
		table.insert(bySig[sig], row)
	end
end

print("========== PET MODEL AUDIT ==========")
print(string.format("Pets in PetConfig: %d | slots in %s: %d", #petIds, folder.Name, #folder:GetChildren()))
print("")

local dupGroups = 0
local dupPets = 0
print("--- IDENTICAL LOOKS (these need new models) ---")
for _, sig in order do
	local group = bySig[sig]
	if #group > 1 then
		dupGroups += 1
		dupPets += #group
		local labels: { string } = {}
		for _, r in group do
			table.insert(labels, string.format("%s [%s] (%s, slot %s)", r.name, r.rarity, r.petId, r.slot))
		end
		print(string.format("  GROUP %d — %d parts each:", dupGroups, group[1].parts))
		for _, l in labels do
			print("      " .. l)
		end
		print(string.format("      -> keep 1, generate %d new", #group - 1))
	end
end
if dupGroups == 0 then
	print("  none — every pet is visually unique")
end
print("")

print("--- NO MODEL AT ALL (placeholder shown in game) ---")
if #missing == 0 then
	print("  none")
end
for _, r in missing do
	print(string.format("  %s [%s] (%s) -> slot %s", r.name, r.rarity, r.petId, r.slot))
end
print("")

print(string.format("--- OVER PART BUDGET (>%d parts) ---", PART_BUDGET))
if #heavy == 0 then
	print("  none")
end
for _, r in heavy do
	print(string.format("  %s (%s, slot %s): %d parts", r.name, r.petId, r.slot, r.parts))
end
print("")

print("--- UNUSED SLOTS (in PetModels, no pet maps to them) ---")
local used: { [string]: boolean } = {}
for _, slot in PetModelConfig.ModelByPetId do
	used[slot] = true
end
local unusedCount = 0
for _, child in folder:GetChildren() do
	if child:IsA("Model") and not used[child.Name] then
		unusedCount += 1
		local _, parts = signature(child)
		print(string.format("  %s (%d parts)", child.Name, parts))
	end
end
if unusedCount == 0 then
	print("  none")
end
print("")

local toGenerate = (dupPets - dupGroups) + #missing
print("========== VERDICT ==========")
print(string.format("Models to generate for 100%% unique pets: %d", toGenerate))
print(string.format("  from duplicate groups: %d", dupPets - dupGroups))
print(string.format("  from missing models:   %d", #missing))
if toGenerate == 0 and #heavy == 0 then
	print("PETS ARE DONE — every pet is unique, has a model, and fits the part budget.")
end
print("=============================")
