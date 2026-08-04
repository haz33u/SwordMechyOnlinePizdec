--!strict
--[[
	List what is actually inside PetModels.F.

	The audit reported slot F as a 3003-part pet. It is not a pet: it is an
	imported asset pack of ~290 separate models spanning 586 studs. Charon maps
	to this slot, so in game the client clones the entire pack and squeezes it
	into a 2-stud cube.

	If the pack contains a usable Charon-like model, fixing Charon costs zero
	generations — we just point the slot at that one child.

	Read only.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local f = ReplicatedStorage.PetModels:FindFirstChild("F")
if not f then
	print("PetModels.F not found")
	return
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

print(string.format("PetModels.F has %d children", #f:GetChildren()))
print("")

-- Anything reading as a ferryman of the dead: Charon is a hooded skeletal boatman.
local CHARON_WORDS = { "charon", "reaper", "ferry", "boat", "skull", "skeleton", "death", "grim", "soul", "wraith" }

local hits: { string } = {}
for _, c in f:GetChildren() do
	local lower = string.lower(c.Name)
	for _, w in CHARON_WORDS do
		if string.find(lower, w, 1, true) then
			table.insert(hits, string.format("  %s (%s, %d parts)", c.Name, c.ClassName, partCount(c)))
			break
		end
	end
end

print("--- CHARON CANDIDATES INSIDE THE PACK ---")
if #hits == 0 then
	print("  none")
end
for _, h in hits do
	print(h)
end
print("")

print("--- ALL CHILDREN (name / class / parts) ---")
local rows: { string } = {}
for _, c in f:GetChildren() do
	table.insert(rows, string.format("%s|%s|%d", c.Name, c.ClassName, partCount(c)))
end
table.sort(rows)
for _, r in rows do
	print("  " .. r)
end
