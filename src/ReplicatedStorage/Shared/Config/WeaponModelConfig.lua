--!strict
--[[
	Maps WeaponConfig ids → Model names under ReplicatedStorage.WeaponModels.

	Place folder (not in git):
	  ReplicatedStorage.WeaponModels.<ModelName>

	Naming: Studio models are free-set PascalCase (StarterSword, …).
	Code weapon ids stay dump snake_case (starter_weapon, …).

	Ladder Loc1 (weak → strong). First 6 models wired; last 3 empty until art added.
]]

local WeaponModelConfig = {
	FolderName = "WeaponModels",

	--[[
		weaponId → Model.Name in WeaponModels
		Empty / missing = placeholder Part in WeaponVisual + IconConfig image in UI.
	]]
	ModelByWeaponId = {
		-- Loc1 rarity ladder bottom → top (6 free models, 2026-07-20)
		starter_weapon = "StarterSword", -- wooden / weakest
		old_sword = "IronSword",
		bone_dagger = "PixelIronSword",
		wooden_mace = "GoldSword", -- Rare
		double_edged_sword = "RubySword", -- Epic
		forest_spirit_staff = "DiamondSword", -- Epic (best of current 6)

		-- Loc1 top 3 — add models later
		ardite = "",
		forest_sword = "",
		forest_shadow = "",

		-- Loc2 — later
		pirate_hook = "",
		pirate_hammer = "",
		pirate_saber = "",
		golden_plated_sword = "",
		captain_axe = "",
		element_blade = "",
		emerald_blade = "",
		sea_dagger = "",
	} :: { [string]: string },

	-- Optional uniform scale after clone (1 = keep free-asset size). Tune in Play.
	DefaultScale = 0.85,
}

function WeaponModelConfig.GetModelName(weaponId: string): string?
	local WeaponConfig = require(script.Parent.WeaponConfig)
	local id = WeaponConfig.ResolveId(weaponId)
	local name = WeaponModelConfig.ModelByWeaponId[id]
	if type(name) == "string" and name ~= "" then
		return name
	end
	return nil
end

function WeaponModelConfig.HasModel(weaponId: string): boolean
	return WeaponModelConfig.GetModelName(weaponId) ~= nil
end

return WeaponModelConfig
