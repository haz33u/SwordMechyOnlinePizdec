--!strict
--[[
	StrayPetModelService.lua

	Pet models belong to a player, not to the world.

	Generating pet models leaves the source Model sitting in the Workspace root:
	the generator builds it there so you can look at it, and nothing ever cleans
	it up. Players then walk past dozens of loose pets standing in the grass with
	no owner, no purpose and no way to interact with them — and every one of them
	is streamed, lit and rendered for every client.

	The real pets are handled entirely by PetVisual on the client, which clones
	from ReplicatedStorage.PetModels into a SM_PetVisuals folder parented to the
	player's own character, and only for pets in profile.petTeam. So the world
	copies are pure leftovers: deleting them cannot affect an equipped pet.

	This service removes them at boot. It is deliberately conservative — it only
	touches a Workspace ROOT child whose name matches a real PetModels slot, or
	which carries the generator's own structure. Anything a person placed on the
	map on purpose is left alone.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetModelConfig = require(Shared.Config.PetModelConfig)

local StrayPetModelService = {}

--[[
	Names that must survive even if they look like a pet.

	Map authors reuse pet-ish names for scenery and NPCs. Rather than guess, keep
	an explicit allowlist and log anything it saves, so the list stays honest.

	"Nereid" is here on purpose: it is a unique 34-part merfolk model that has NOT
	yet been installed into PetModels (slot E-D, pet P2_K_L2 — see
	docs/PET_GENERATION_BRIEF.md). Play-mode deletions do not persist to the saved
	place, so losing it would not be permanent, but it would vanish mid-session and
	confuse anyone inspecting it. Remove this entry once it is installed.
]]
local KEEP_NAMES: { [string]: boolean } = {
	NPCs = true,
	Mobs = true,
	MobTemplates = true,
	MobSpawns = true,
	Terrain = true,
	Camera = true,
	Nereid = true,
}

--- Slot names that PetModelConfig actually maps a pet to.
local function mappedSlotNames(): { [string]: boolean }
	local set: { [string]: boolean } = {}
	for _, slot in PetModelConfig.ModelByPetId do
		set[slot] = true
	end
	return set
end

--[[
	The generator's fingerprint.

	Every procedurally generated model keeps a "ProceduralGeneration" ModuleScript
	and a "Generated" folder — the same structure the PetModels slots carry. A
	hand-placed prop never has both.
]]
local function looksGenerated(model: Model): boolean
	return model:FindFirstChild("ProceduralGeneration") ~= nil and model:FindFirstChild("Generated") ~= nil
end

--[[
	Decide whether a Workspace root child is an orphaned pet model.

	Only root children are considered. A pet model nested inside a set piece was
	put there by a person and is scenery, not a leftover.
]]
local function isStrayPetModel(inst: Instance, slots: { [string]: boolean }): boolean
	if not inst:IsA("Model") then
		return false
	end
	if KEEP_NAMES[inst.Name] then
		return false
	end
	-- A character standing in the world is a Model with a Humanoid; never touch one.
	if inst:FindFirstChildOfClass("Humanoid") then
		return false
	end
	-- Placed on purpose: authors tag keepers so a future cleanup pass respects them.
	if inst:GetAttribute("KeepInWorld") == true then
		return false
	end
	return slots[inst.Name] == true or looksGenerated(inst)
end

--[[
	Sweep once at boot, then keep watching.

	Watching matters because Rojo syncs and Team Create edits can re-introduce a
	stray copy mid-session, and a player joining afterwards would see it.
]]
function StrayPetModelService.Init()
	local slots = mappedSlotNames()
	local removed = 0
	local kept: { string } = {}

	local function sweep(inst: Instance)
		-- Root children only — Parent is Workspace itself, not something inside it.
		if inst.Parent ~= Workspace then
			return
		end
		if isStrayPetModel(inst, slots) then
			removed += 1
			inst:Destroy()
		elseif inst:IsA("Model") and slots[inst.Name] and #kept < 12 then
			table.insert(kept, inst.Name)
		end
	end

	for _, child in Workspace:GetChildren() do
		sweep(child)
	end

	Workspace.ChildAdded:Connect(function(child)
		-- A model streams in part by part; let it settle before judging its structure.
		task.defer(sweep, child)
	end)

	if removed > 0 then
		print(string.format("[StrayPetModels] Removed %d orphaned pet model(s) from the Workspace root.", removed))
	end
	if #kept > 0 then
		print(string.format("[StrayPetModels] Kept (protected): %s", table.concat(kept, ", ")))
	end
end

return StrayPetModelService
