--!strict
--[[
	Weapon image assets — keys match dump weapon slugs (WeaponConfig ids).

	Inventory priority (see Inventory + docs/WEAPON_ICONS.md):
	  1) Authored 2D if HasWeaponImage (Minecraft-style card)
	  2) Else 3D Viewport card from WeaponModels
	  3) Else placeholder

	Prefer2DWhenAvailable: when true, LegacyWeaponAssetIds count as authored 2D.
]]

local IconConfig = {
	FallbackWeapon = "rbxassetid://6035056476",
	FallbackFrame = "",

	--[[
		When true (default): use LegacyWeaponAssetIds / WeaponAssetIds as ImageLabel
		BEFORE trying live 3D — matches Minecraft bag quality when art exists.
		When false: 3D mesh wins whenever present (old behavior).
	]]
	Prefer2DWhenAvailable = true,

	-- Global switch: force legacy table only (rarely needed)
	PreferLegacyDecals = false,

	WeaponAssetIds = {
		-- Fill with new uploads for Loc2 / custom art. Empty = fall through to legacy or 3D.
		starter_weapon = "",
		old_sword = "",
		bone_dagger = "",
		wooden_mace = "",
		double_edged_sword = "",
		forest_spirit_staff = "",
		ardite = "",
		forest_sword = "",
		forest_shadow = "",
		pirate_hook = "",
		pirate_hammer = "",
		pirate_saber = "",
		golden_plated_sword = "",
		captain_axe = "",
		element_blade = "",
		emerald_blade = "",
		sea_dagger = "",
	} :: { [string]: string },

	-- Loc1 Cristalix-style flat icons (used when Prefer2DWhenAvailable)
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

local function resolveId(weaponId: string): string
	local WeaponConfig = require(script.Parent.WeaponConfig)
	return WeaponConfig.ResolveId(weaponId)
end

function IconConfig.GetWeaponImage(weaponId: string): string
	local resolved = resolveId(weaponId)
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
	-- Prefer2D: also accept legacy as authored card
	if IconConfig.Prefer2DWhenAvailable then
		local legacy = IconConfig.LegacyWeaponAssetIds[resolved] or IconConfig.LegacyWeaponAssetIds[weaponId]
		if type(legacy) == "string" and legacy ~= "" then
			return legacy
		end
	end
	return IconConfig.FallbackWeapon
end

--- true if we have a real 2D card (not generic fallback) for this weapon
function IconConfig.HasWeaponImage(weaponId: string): boolean
	local resolved = resolveId(weaponId)
	local primary = IconConfig.WeaponAssetIds[resolved] or IconConfig.WeaponAssetIds[weaponId]
	if type(primary) == "string" and primary ~= "" then
		return true
	end
	if IconConfig.Prefer2DWhenAvailable or IconConfig.PreferLegacyDecals then
		local legacy = IconConfig.LegacyWeaponAssetIds[resolved] or IconConfig.LegacyWeaponAssetIds[weaponId]
		if type(legacy) == "string" and legacy ~= "" then
			return true
		end
	end
	return false
end

function IconConfig.GetFrameImage(rarity: string): string
	local id = IconConfig.FrameAssetIds[rarity]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return IconConfig.FallbackFrame
end

return IconConfig
