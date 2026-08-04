--!strict
--[[
	The unused slots are named after pets — Woodling, Forestling, Hekata and so
	on. That is the half-finished rename the brief describes: someone started
	giving Loc1-2 slots real pet names and stopped.

	Before deleting or reusing any of them, find out for each one whether it is
	a copy of the slot that pet actually uses, a BETTER model than that slot, or
	unrelated junk.

	Read only.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local PetModelConfig = require(ReplicatedStorage.Shared.Config.PetModelConfig)

local folder = ReplicatedStorage.PetModels

-- Same signature the audit uses, so "identical" means the same thing in both.
local function signature(model: Instance): (string, number)
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

local UNUSED = {
	"Forestling",
	"Lurk",
	"Woodling",
	"Hekata",
	"Stiko",
	"Charon",
	"Morpheus",
	"Torn",
	"Nifel",
	"Nightmare",
	"Grommash",
	"S-A",
}

for _, slotName in UNUSED do
	local unused = folder:FindFirstChild(slotName)
	if not unused then
		continue
	end
	local usig, uparts = signature(unused)

	-- Find the pet this slot is named after, and the slot it really uses.
	local matchedPet: string? = nil
	local matchedId: string? = nil
	for id, def in PetConfig.Pets do
		if def.name == slotName then
			matchedPet = def.name
			matchedId = id
			break
		end
	end

	if not matchedId then
		print(string.format("%s (%d parts): no pet with this name -> pure leftover", slotName, uparts))
		continue
	end

	local realSlot = PetModelConfig.GetModelName(matchedId)
	local real = realSlot and folder:FindFirstChild(realSlot)
	if not real then
		print(string.format("%s (%d parts): pet %s maps to %s which is MISSING", slotName, uparts, matchedId, tostring(realSlot)))
		continue
	end

	local rsig, rparts = signature(real)
	local verdict
	if rsig == usig then
		verdict = "IDENTICAL to the live slot -> safe leftover"
	elseif uparts > rparts then
		verdict = string.format("DIFFERENT and richer (%d vs %d parts) -> possible upgrade", uparts, rparts)
	else
		verdict = string.format("DIFFERENT and simpler (%d vs %d parts)", uparts, rparts)
	end

	print(
		string.format(
			"%s (%d parts) | pet %s (%s) uses slot '%s' (%d parts) | %s",
			slotName,
			uparts,
			matchedPet or "?",
			matchedId,
			realSlot or "?",
			rparts,
			verdict
		)
	)
end
