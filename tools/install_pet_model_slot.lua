--!strict
--[[
	Install a Workspace root ProceduralModel as a pet model slot.
	Run from Edit mode command bar.

	Clones from Workspace into ReplicatedStorage.PetModels, preserving the
	same structure existing slots use (ProceduralGeneration + Generated).
	Never deletes or moves the Workspace source.

	After running, update PetModelConfig.ModelByPetId in the repo so the
	pet id points at SLOT_NAME.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SRC_NAME = "Nereid"
local SLOT_NAME = "E-D"
local FOLDER_NAME = "PetModels"

local src = workspace:FindFirstChild(SRC_NAME)
if not src then
	error("Source model not found in Workspace: " .. SRC_NAME)
end

local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
if not folder then
	error("Folder not found in ReplicatedStorage: " .. FOLDER_NAME)
end

local old = folder:FindFirstChild(SLOT_NAME)
if old then
	old.Name = SLOT_NAME .. "_old"
	old.Parent = nil
end

local clone = src:Clone()
clone.Name = SLOT_NAME
clone.Parent = folder

print(
	string.format(
		"Installed %s <- Workspace.%s (%d descendants)",
		SLOT_NAME,
		SRC_NAME,
		#clone:GetDescendants()
	)
)
