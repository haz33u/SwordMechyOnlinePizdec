--!strict
--[[
	Weapon image assets — keys match dump weapon slugs (WeaponConfig ids).
]]

local IconConfig = {
	FallbackWeapon = "rbxassetid://6035056476",
	FallbackFrame = "",

	--[[
		Legacy flat Decals (old Cristalix-style art).
		Inventory prefers 3D Viewport when WeaponModels mesh exists.
		These ids kept ONLY as backup if PreferLegacyDecals = true OR no mesh.
	]]
	PreferLegacyDecals = false,

	WeaponAssetIds = {
		-- Loc1 — legacy PNGs parked (empty = don't show wrong art when 3D fails)
		-- Restore ids here if PreferLegacyDecals = true
		starter_weapon = "",
		old_sword = "",
		bone_dagger = "",
		wooden_mace = "",
		double_edged_sword = "",
		forest_spirit_staff = "",
		ardite = "",
		forest_sword = "",
		forest_shadow = "",
		-- Loc2
		pirate_hook = "",
		pirate_hammer = "",
		pirate_saber = "",
		golden_plated_sword = "",
		captain_axe = "",
		element_blade = "",
		emerald_blade = "",
		sea_dagger = "",
	} :: { [string]: string },

	-- Parked legacy rbxassetid (do not delete — re-enable via PreferLegacyDecals + paste back)
	LegacyWeaponAssetIds = {
		starter_weapon = "rbxassetid://116982617153585",
		old_sword = "rbxassetid://85575954431015",
		bone_dagger = "rbxassetid://82149069182844",
		wooden_mace = "rbxassetid://140029944614319",
		double_edged_sword = "rbxassetid://72874627405282",
		forest_spirit_staff = "rbxassetid://113405820939595",
		ardite = "rbxassetid://92192514816761",
		forest_sword = "rbxassetid://75341679116800",
		forest_shadow = "rbxassetid://122837329722306",
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
	if IconConfig.PreferLegacyDecals then
		local legacy = IconConfig.LegacyWeaponAssetIds[resolved] or IconConfig.LegacyWeaponAssetIds[weaponId]
		if type(legacy) == "string" and legacy ~= "" then
			return legacy
		end
	end
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
