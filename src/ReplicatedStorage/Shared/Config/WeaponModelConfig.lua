--!strict
--[[
	Weapon 3D models (Place) + hold contract.

	Grip system (systematic):
	  Each sword gets Attachment "SM_Hilt" on PrimaryPart at the HANDLE end.
	  Runtime: RigidConstraint hand GripAttachment ↔ SM_Hilt.
	  See docs/WEAPON_HOLD.md

	Do NOT tune per-mesh hilt with one global factor — bake/find SM_Hilt instead.
]]

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

	-- Uniform scale for free Toolbox swords (~5–7 stud → hand size)
	DefaultScale = 0.52,

	--[[
		Rare per-MODEL overrides (Model.Name keys). Used only when auto-hilt
		picks the wrong tip end. flipTip = reverse blade axis after Tool.Grip heuristic.
	]]
	HiltOverrides = {
		-- Example: GoldSword = { flipTip = true },
	} :: { [string]: { flipTip: boolean? } },

	--[[
		Palm OFFSET only (position in hand-grip space). Do NOT use this to spin the blade.
		  X = side · Y = along grip · Z = into palm
	]]
	PalmOffsetRight = Vector3.new(0.04, 0.08, 0.04),
	PalmOffsetLeft = Vector3.new(-0.04, 0.08, 0.04),

	--[[
		PalmTilt — KEEP NEAR ZERO. Pitch/yaw of the whole hand attach.
		Wrong knob for “edge vs flat”; that is BladeRoll below.
	]]
	PalmTiltRight = Vector3.zero,
	PalmTiltLeft = Vector3.zero,

	--[[
		BladeRoll — THE correct knob for “режет / плашмя”.
		Degrees around the SWORD long axis (SM_Hilt local +Y = tip).
		  +90 / -90 ≈ edge-on (cut) for most free meshes; flip sign if still flat.
		This is CFrame.Angles(0, rad(BladeRoll), 0) on the hilt attachment — NOT palm XYZ.
	]]
	BladeRollRight = 90,
	BladeRollLeft = -90,

	-- Fraction of half-length back from tip-axis end → sit on handle (0.85–0.95 = near pommel)
	HiltEndBias = 0.92,
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

function WeaponModelConfig.GetOverride(modelName: string): { flipTip: boolean? }?
	local o = WeaponModelConfig.HiltOverrides[modelName]
	if type(o) == "table" then
		return o
	end
	return nil
end

return WeaponModelConfig
