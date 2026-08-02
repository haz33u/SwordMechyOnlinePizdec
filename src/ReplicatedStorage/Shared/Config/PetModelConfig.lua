--!strict
--[[
	Pet 3D models in ReplicatedStorage.PetModels (Place folder, like WeaponModels).
	Missing model → client builds rarity-colored placeholder.
]]

local PetModelConfig = {
	FolderName = "PetModels",
	-- Optional pre-scale before normalize (usually leave 1)
	DefaultScale = 1,
	-- ALL pets forced to this max bbox extent (studs) — slime-sized, no giants
	TargetExtent = 2.0,
	TargetExtentMinFactor = 0.04,
	TargetExtentMaxFactor = 25,

	-- Behind player (studs, local HRP space: +Z = behind LookVector on Roblox)
	FollowBack = 3.0,
	FollowHeight = 0.6,
	FollowSpread = 1.65,
	LerpAlpha = 0.16,
	BobAmp = 0.12,
	BobSpeed = 2.2,

	--[[
		petId → Model.Name under PetModels
		Loc1_500 first; higher tiers can share or add later.
	]]
	ModelByPetId = {
		P1_C1 = "A",
		P1_C2 = "B",
		P1_R1 = "C",
		P1_R2 = "D",
		P1_L1 = "E",

		P1_50_R1 = "F",
		P1_50_R2 = "G",
		P1_50_E1 = "2-A",
		P1_50_E2 = "2-B",
		P1_50_L1 = "2-C",
		P1_50_M1 = "2-D",

		P1_K_R1 = "2-E",
		P1_K_E1 = "2-F",
		P1_K_L1 = "2-G",
		P1_K_L2 = "3-A",
		P1_K_M1 = "3-B",

		P2_C1 = "3-C",
		P2_C2 = "3-D",
		P2_R1 = "3-E",
		P2_E1 = "3-F",
		P2_L1 = "3-G",
		P2_M1 = "Waifu",

		P2_K_R1 = "E-A",
		P2_K_E1 = "E-B",
		P2_K_L1 = "E-C",
		P2_K_L2 = "E-D",

		P3_C1 = "Kirin",
		P3_C2 = "ShinobiFox",
		P3_R1 = "ShadowRaven",
		P3_E1 = "DragonKin",
		P3_L1 = "SamuraiTiger",
		P3_M1 = "KitsuneGod",

		P4_C1 = "FrostBunny",
		P4_C2 = "IceBear",
		P4_R1 = "GlacierPenguin",
		P4_E1 = "TundraWolf",
		P4_L1 = "PolarDrake",
		P4_M1 = "YetiKing",

		P5_C1 = "Scarab",
		P5_R1 = "AnubisGuard",
		P5_E1 = "Sphinx",
		P5_L1 = "SunDrake",
		P5_M1 = "PharaohGod",

		P6_C1 = "CyberCat",
		P6_R1 = "NeonHawk",
		P6_E1 = "MechaWolf",
		P6_L1 = "PlasmaDragon",
		P6_M1 = "CyberValkyrie",

		P7_C1 = "StarlightSpirit",
		P7_R1 = "Seraphim",
		P7_E1 = "SolarPhoenix",
		P7_L1 = "CelestialDragon",
		P7_M1 = "ArchangelPrime",
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
