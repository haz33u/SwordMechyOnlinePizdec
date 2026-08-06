--!strict
--[[
	Strip any runtime scripts/ProceduralGeneration scripts inside ReplicatedStorage.PetModels
	so cloning pets in game causes ZERO lag or frame drops.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local petFolder = ReplicatedStorage:FindFirstChild("PetModels")

if not petFolder then
	error("ReplicatedStorage.PetModels missing")
end

local removed = 0

for _, descendant in petFolder:GetDescendants() do
	if descendant:IsA("LuaSourceContainer") or descendant.Name == "ProceduralGeneration" or descendant.Name == "ProceduralModel" then
		print(string.format("Removing script '%s' from %s", descendant.Name, descendant.Parent and descendant.Parent.Name or "nil"))
		descendant:Destroy()
		removed += 1
	end
end

print(string.format("========== PET SCRIPT CLEANUP COMPLETE: Removed %d scripts ==========", removed))
