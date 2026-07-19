--!strict
--[[
	Weapon image assets — keys match dump weapon slugs (WeaponConfig ids).
]]

local IconConfig = {
	FallbackWeapon = "rbxassetid://6035056476",
	FallbackFrame = "",

	WeaponAssetIds = {
		-- Loc1 dump
		starter_weapon = "rbxassetid://116982617153585",
		old_sword = "rbxassetid://85575954431015",
		bone_dagger = "rbxassetid://82149069182844",
		wooden_mace = "rbxassetid://140029944614319",
		double_edged_sword = "rbxassetid://72874627405282",
		forest_spirit_staff = "rbxassetid://113405820939595",
		ardite = "rbxassetid://92192514816761",
		forest_sword = "rbxassetid://75341679116800",
		forest_shadow = "rbxassetid://122837329722306",
		-- Loc2 dump (upload when art ready)
		pirate_hook = "",
		pirate_hammer = "",
		pirate_saber = "",
		golden_plated_sword = "",
		captain_axe = "",
		element_blade = "",
		emerald_blade = "",
		sea_dagger = "",
	} :: { [string]: string },

	FrameAssetIds = {
		Common = "",
		Uncommon = "",
		Rare = "",
		Epic = "",
		Legendary = "",
		Mythic = "",
		Secret = "",
		Limited = "",
	} :: { [string]: string },
}

function IconConfig.GetWeaponImage(weaponId: string): string
	local WeaponConfig = require(script.Parent.WeaponConfig)
	local resolved = WeaponConfig.ResolveId(weaponId)
	local id = IconConfig.WeaponAssetIds[resolved] or IconConfig.WeaponAssetIds[weaponId]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return IconConfig.FallbackWeapon
end

function IconConfig.GetFrameImage(rarity: string): string
	local id = IconConfig.FrameAssetIds[rarity]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return IconConfig.FallbackFrame
end

return IconConfig
