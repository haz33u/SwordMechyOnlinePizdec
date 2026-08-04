--!strict
--[[
	Inspect the Charon replacement candidates found inside the PetModels.F pack.

	Charon is Rare rarity, so per docs/PET_GENERATION_BRIEF.md the palette should
	be blue-ish with one accent and no strong emissive. Print colors and
	materials so the pick is made on what the model actually looks like rather
	than on its name.

	Read only.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local pack = ReplicatedStorage.PetModels:FindFirstChild("F")
if not pack then
	print("PetModels.F not found")
	return
end

local CANDIDATES = { "Skull Reaper", "Mythic Skull Reaper", "Dark Soul", "Ghostlord", "Phantom", "King Skull" }

for _, name in CANDIDATES do
	local m = pack:FindFirstChild(name)
	if not m then
		print(name .. ": not in pack")
		continue
	end
	local _, size = m:GetBoundingBox()
	local rows: { string } = {}
	local emissive = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			local c = d.Color
			if #rows < 8 then
				table.insert(
					rows,
					string.format(
						"%s[%s rgb(%d,%d,%d)]",
						d.Name,
						d.Material.Name,
						math.round(c.R * 255),
						math.round(c.G * 255),
						math.round(c.B * 255)
					)
				)
			end
			if d:FindFirstChildOfClass("PointLight") or d:FindFirstChildOfClass("SurfaceLight") then
				emissive += 1
			end
		end
	end
	print(
		string.format(
			"%s: extent %.1f x %.1f x %.1f, primary=%s, %d lit parts",
			name,
			size.X,
			size.Y,
			size.Z,
			m.PrimaryPart and m.PrimaryPart.Name or "NONE",
			emissive
		)
	)
	print("    " .. table.concat(rows, " "))
end
