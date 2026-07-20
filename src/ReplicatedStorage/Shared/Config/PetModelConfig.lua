--!strict
--[[
	Pet 3D models in ReplicatedStorage.PetModels (Place folder, like WeaponModels).
	Missing model → client builds rarity-colored placeholder.
]]

local PetModelConfig = {
	FolderName = "PetModels",
	DefaultScale = 0.55,

	-- Behind player (studs, local HRP space: -Z = behind)
	FollowBack = 4.2,
	FollowHeight = 2.35,
	FollowSpread = 1.65,
	LerpAlpha = 0.16,
	BobAmp = 0.14,
	BobSpeed = 2.2,

	--[[
		petId → Model.Name under PetModels
		Loc1_500 first; higher tiers can share or add later.
	]]
	ModelByPetId = {
		P1_C1 = "Woodling",
		P1_C2 = "Lurk",
		P1_R1 = "Forestling",
		P1_R2 = "Hekata",
		P1_L1 = "Stiko",

		P1_50_R1 = "Charon",
		P1_50_R2 = "Morpheus",
		P1_50_E1 = "Torn",
		P1_50_E2 = "Nifel",
		P1_50_L1 = "Nightmare",
		P1_50_M1 = "Grommash",

		P1_K_R1 = "Nocturne",
		P1_K_E1 = "Moron",
		P1_K_L1 = "Heka",
		P1_K_L2 = "Monster",
		P1_K_M1 = "Freya",

		P2_C1 = "Proteus",
		P2_C2 = "Atlas",
		P2_R1 = "Hermes",
		P2_E1 = "Arix",
		P2_L1 = "Ceres",
		P2_M1 = "Nereus",

		P2_K_R1 = "Eridan",
		P2_K_E1 = "Calypso",
		P2_K_L1 = "Argus",
		P2_K_L2 = "Nereid",
		P2_K_M1 = "Triton",
	} :: { [string]: string },

	-- Placeholder colors by rarity (when mesh missing)
	RarityColor = {
		Common = Color3.fromRGB(120, 160, 100),
		Uncommon = Color3.fromRGB(80, 190, 110),
		Rare = Color3.fromRGB(70, 130, 230),
		Epic = Color3.fromRGB(160, 80, 220),
		Legendary = Color3.fromRGB(230, 160, 50),
		Mythic = Color3.fromRGB(230, 70, 110),
		Secret = Color3.fromRGB(255, 230, 120),
		Limited = Color3.fromRGB(255, 80, 200),
	},
}

function PetModelConfig.GetModelName(petId: string): string?
	local name = PetModelConfig.ModelByPetId[petId]
	if type(name) == "string" and name ~= "" then
		return name
	end
	return nil
end

return PetModelConfig
