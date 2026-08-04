--!strict
--[[
	Read-only inspection for the three things the audit flagged:
	the Nereid source model, the over-budget Charon, and the unused slots.

	Deletes nothing. Its job is to tell us whether the fixes are safe before
	anything is written.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local folder = ReplicatedStorage:FindFirstChild("PetModels")

local function describe(model: Instance?, label: string)
	if not model or not model:IsA("Model") then
		print(string.format("%s: MISSING", label))
		return
	end
	local parts = 0
	local scripts = 0
	local sounds = 0
	local meshes = 0
	local tiny = 0
	local cf, size = model:GetBoundingBox()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			-- At TargetExtent 2.0 the whole pet is 2 studs across, so a part whose
			-- largest dimension is under 2% of the model is sub-pixel on screen.
			local maxDim = math.max(d.Size.X, d.Size.Y, d.Size.Z)
			if maxDim < math.max(size.X, size.Y, size.Z) * 0.02 then
				tiny += 1
			end
			if d:IsA("MeshPart") then
				meshes += 1
			end
		elseif d:IsA("BaseScript") or d:IsA("ModuleScript") then
			scripts += 1
		elseif d:IsA("Sound") then
			sounds += 1
		end
	end
	print(
		string.format(
			"%s: %d parts (%d mesh, %d sub-2%%-size), %d scripts, %d sounds, primary=%s, extent=%.1f x %.1f x %.1f",
			label,
			parts,
			meshes,
			tiny,
			scripts,
			sounds,
			model.PrimaryPart and model.PrimaryPart.Name or "NONE",
			size.X,
			size.Y,
			size.Z
		)
	)
	local kids: { string } = {}
	for _, c in model:GetChildren() do
		if #kids < 14 then
			table.insert(kids, string.format("%s(%s)", c.Name, c.ClassName))
		end
	end
	print("    children: " .. table.concat(kids, ", "))
end

print("--- SOURCE FOR THE DUPLICATE FIX ---")
describe(Workspace:FindFirstChild("Nereid"), "Workspace.Nereid")
describe(folder and folder:FindFirstChild("E-D"), "PetModels.E-D  (Nereid's slot, currently a Nereus copy)")
describe(folder and folder:FindFirstChild("Waifu"), "PetModels.Waifu (Nereus, the one to keep)")

print("")
print("--- OVER BUDGET ---")
describe(folder and folder:FindFirstChild("F"), "PetModels.F (Charon, mapped)")
describe(folder and folder:FindFirstChild("Charon"), "PetModels.Charon (unused duplicate)")

print("")
print("--- UNUSED SLOTS: are they referenced anywhere? ---")
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
for _, name in UNUSED do
	local m = folder and folder:FindFirstChild(name)
	if m then
		local parts = 0
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		print(string.format("  %s: %d parts, %d children", name, parts, #m:GetChildren()))
	end
end
