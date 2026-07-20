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
		Shared palm offset in hand-grip space (both hands). NOT per-mesh hilt.
		  X = side · Y = along knuckles / "up" of grip · Z = into-out of palm
		Slight +Y and small Z push = hilt sits in the palm (clips hand a bit = OK).
	]]
	PalmOffsetRight = Vector3.new(0.04, 0.1, 0.06),
	PalmOffsetLeft = Vector3.new(-0.04, 0.1, 0.06),

	--[[
		Palm tilt (degrees, applied as CFrame.Angles(rx, ry, rz) on the palm attachment).
		Turns the free mesh from a flat "plank" into a cutting sword:
		  X = pitch (tip up/down)
		  Y = yaw
		  Z = roll (blade edge into cut plane — main anti-flat fix)
		Left hand mirrors Z.
	]]
	PalmTiltRight = Vector3.new(18, -8, -55),
	PalmTiltLeft = Vector3.new(18, 8, 55),

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
