--!strict
--[[
	Weapon 3D models + hold / inventory icon contract.
	See docs/WEAPON_HOLD.md

	IMPORTANT: hiltEnd is evaluated AFTER DefaultScale on the live part Size.
	Do NOT store absolute stud offsets from unscaled Toolbox sizes (they break after ScaleTo).
]]

export type HiltOverride = {
	-- Which end of the longest local axis is the HANDLE: +1 or -1
	hiltEnd: number?,
	-- 0.9–0.99 = near geometric end (handle). Default HiltEndBias.
	hiltBias: number?,
	-- Absolute local position AFTER scale (rare). Prefer hiltEnd.
	hiltPosition: Vector3?,
	tipDirection: Vector3?,
	tipSign: number?, -- legacy
	flipTip: boolean?,
	-- Inventory: flip 180° after tip-up (upside-down icons when hand is already OK)
	iconInvert: boolean?,
	iconEuler: Vector3?,
	iconFlip: (boolean | string)?,
}

local WeaponModelConfig = {
	FolderName = "WeaponModels",
	HiltAttachmentName = "SM_Hilt",

	ModelByWeaponId = {
		starter_weapon = "StarterSword",
		old_sword = "IronSword",
		bone_dagger = "PixelIronSword",
		wooden_mace = "GoldSword",
		double_edged_sword = "RubySword",
		forest_spirit_staff = "DiamondSword",
		ardite = "KawashimaSword",
		forest_sword = "SupeSport",
		forest_shadow = "LastSword",

		pirate_hook = "",
		pirate_hammer = "",
		pirate_saber = "",
		golden_plated_sword = "",
		captain_axe = "",
		element_blade = "",
		emerald_blade = "",
		sea_dagger = "",
	} :: { [string]: string },

	DefaultScale = 0.52,
	-- Base scale before fill-normalize in viewport
	IconScale = 1,
	-- Normalize every icon so max bbox ≈ this (studs) → small swords look as big as fat ones
	IconTargetExtent = 2.4,

	HiltEndBias = 0.96,

	--[[
		hiltEnd: +1 = positive local long-axis end is HANDLE, -1 = negative end.
		Screenshot 231434: previous +offsets still blade → use -1 for Ardite/Forest.
	]]
	HiltOverrides = {
		-- Hand OK after hiltEnd fix; icons still upside-down → iconInvert
		IronSword = { iconInvert = true }, -- Old Sword
		RubySword = { iconInvert = true }, -- Double-Edged
		SupeSport = {
			hiltEnd = -1,
			hiltBias = 0.98,
			iconInvert = true, -- Forest Sword
		},
		KawashimaSword = {
			hiltEnd = -1,
			hiltBias = 0.98,
			iconInvert = true, -- Ardite
		},
	} :: { [string]: HiltOverride },

	PalmOffsetRight = Vector3.new(0.04, 0.08, 0.04),
	PalmOffsetLeft = Vector3.new(-0.04, 0.08, 0.04),
	PalmTiltRight = Vector3.zero,
	PalmTiltLeft = Vector3.zero,
	BladeRollRight = 90,
	BladeRollLeft = -90,
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

function WeaponModelConfig.GetOverride(modelName: string): HiltOverride?
	local o = WeaponModelConfig.HiltOverrides[modelName]
	if type(o) == "table" then
		return o
	end
	return nil
end

function WeaponModelConfig.ResolveOverride(modelOrCloneName: string): HiltOverride?
	local name = string.gsub(modelOrCloneName, "^Weapon_", "")
	local o = WeaponModelConfig.GetOverride(name)
	if o then
		return o
	end
	local mapped = WeaponModelConfig.GetModelName(name)
	if mapped then
		return WeaponModelConfig.GetOverride(mapped)
	end
	return nil
end

return WeaponModelConfig
