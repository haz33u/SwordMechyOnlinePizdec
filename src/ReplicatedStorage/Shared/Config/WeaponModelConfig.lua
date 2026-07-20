--!strict
--[[
	Weapon 3D models (Place) + hold contract.

	Grip: SM_Hilt on PrimaryPart at HANDLE end.
	Runtime: RigidConstraint hand grip ↔ SM_Hilt (+ BladeRoll).
	See docs/WEAPON_HOLD.md
]]

export type HiltOverride = {
	-- Absolute tip direction along longest local axis: +1 or -1 (preferred over flipTip)
	tipSign: number?,
	-- Relative invert of computed tipSign (legacy)
	flipTip: boolean?,
	-- 0.5 = center, 0.98 = near geometric end (handle/pommel). Higher = farther from mid-blade.
	hiltBias: number?,
	-- Inventory Viewport: extra Euler degrees (X,Y,Z) after framing — fix upside-down / on-side
	iconEuler: Vector3?,
	-- Legacy icon 180 flip: true|"x"|"y"|"z"
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
	IconScale = 0.7,

	--[[
		Per Model.Name — QA 2026-07-20:
		  Ardite / Forest: were gripping BLADE → force tipSign opposite + high hiltBias
		  Icons: explicit iconEuler (not random flip axes)
	]]
	HiltOverrides = {
		-- Old Sword: hand OK; icon upside-down
		IronSword = {
			iconEuler = Vector3.new(180, 0, 0),
		},
		-- Double-Edged: icon only
		RubySword = {
			iconEuler = Vector3.new(180, 0, 0),
		},
		-- Forest Sword: was gripping blade with flipTip/-1 → force +end + high bias
		SupeSport = {
			tipSign = 1,
			hiltBias = 0.985,
			iconEuler = Vector3.new(180, 0, 0), -- upright tip-up in icon
		},
		-- Ardite (long Z): same — palm at geometric handle end, not mid-blade
		KawashimaSword = {
			tipSign = 1,
			hiltBias = 0.985,
			iconEuler = Vector3.new(90, 0, 0), -- was on side → pitch up
		},
	} :: { [string]: HiltOverride },

	PalmOffsetRight = Vector3.new(0.04, 0.08, 0.04),
	PalmOffsetLeft = Vector3.new(-0.04, 0.08, 0.04),
	PalmTiltRight = Vector3.zero,
	PalmTiltLeft = Vector3.zero,

	BladeRollRight = 90,
	BladeRollLeft = -90,

	HiltEndBias = 0.94,
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

--- Resolve override from template name or Weapon_<id> clone name.
function WeaponModelConfig.ResolveOverride(modelOrCloneName: string): HiltOverride?
	local name = string.gsub(modelOrCloneName, "^Weapon_", "")
	local o = WeaponModelConfig.GetOverride(name)
	if o then
		return o
	end
	-- name may be weapon id (ardite)
	local mapped = WeaponModelConfig.GetModelName(name)
	if mapped then
		return WeaponModelConfig.GetOverride(mapped)
	end
	return nil
end

return WeaponModelConfig
