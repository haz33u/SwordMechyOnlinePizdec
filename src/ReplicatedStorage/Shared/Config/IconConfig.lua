--!strict
--[[
	Weapon image assets — keys match WeaponConfig ids.

	Inventory priority (docs/WEAPON_ICONS.md):
	  1) Live 3D Viewport if WeaponModels mesh exists
	  2) Authored pro 2D only if WeaponAssetIds[id] non-empty (NEW renders)
	  3) "?"

	LegacyWeaponAssetIds = ARCHIVE only (old balance dumps).
	Do NOT feed them into the bag — they look like wrong "stubs" vs current meshes.
]]

local IconConfig = {
	FallbackWeapon = "rbxassetid://6035056476",
	FallbackFrame = "",

	-- false: never auto-pick legacy dump art for inventory
	Prefer2DWhenAvailable = false,
	PreferLegacyDecals = false,

	--[[
		NEW pro cards only (512² PNG from Icon Render Stage).
		Empty string = use 3D mesh if present.
	]]
	WeaponAssetIds = {
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

	-- ARCHIVE — old dump art. Not used by inventory unless PreferLegacyDecals.
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

--- Authored pro card id, or "" if none. Never returns legacy archive unless PreferLegacyDecals.
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
	return ""
end

--- true only for NEW WeaponAssetIds entries (not legacy archive, not fallback)
function IconConfig.HasWeaponImage(weaponId: string): boolean
	local resolved = resolveId(weaponId)
	local primary = IconConfig.WeaponAssetIds[resolved] or IconConfig.WeaponAssetIds[weaponId]
	if type(primary) == "string" and primary ~= "" then
		return true
	end
	if IconConfig.PreferLegacyDecals then
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
