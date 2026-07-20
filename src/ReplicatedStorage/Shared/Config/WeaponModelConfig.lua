--!strict
--[[
	Weapon 3D models + hold / inventory icon contract.
	See docs/WEAPON_HOLD.md

	IMPORTANT: hiltEnd is evaluated AFTER DefaultScale on the live part Size.
	Do NOT store absolute stud offsets from unscaled Toolbox sizes (they break after ScaleTo).

	Inventory icons use ONE fit-to-slot standard (see Icon* fields). Per-model
	overrides are ONLY for grip (hiltEnd) and rare flip (iconInvert) — never size.
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
	-- Inventory only: 180° after tip-up when mesh still looks upside-down
	iconInvert: boolean?,
	iconEuler: Vector3?,
	iconFlip: (boolean | string)?,
	-- DEPRECATED: size is global fit-to-slot. Kept optional for one-off debug.
	iconScaleMult: number?,
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

	--[[
		ONE icon standard for every weapon ViewportFrame:
		  tip up → fixed yaw → fit projected height + min width to the slot.
		Thin blades get a closer camera automatically (min width rule).
		Do not add per-sword zoom lists — change these knobs only.
	]]
	IconYawDeg = -35,
	IconFov = 28,
	-- Target: sword height fills this fraction of the vertical view
	IconFillHeight = 0.80,
	-- Target: blade width fills at least this fraction (stops hairline icons)
	IconMinWidth = 0.22,
	IconCamDir = Vector3.new(0.5, 0.28, 0.8),
	IconDistMin = 0.55,
	IconDistMax = 14,

	-- Legacy fields (unused by fit-to-slot; kept so old requires don't nil)
	IconScale = 1,
	IconTargetExtent = 0,

	HiltEndBias = 0.96,

	--[[
		hiltEnd: hand grip which geometric end is HANDLE (+1 / -1).
		iconInvert: inventory flip only when tip-up still looks wrong.
	]]
	HiltOverrides = {
		IronSword = { iconInvert = true },
		RubySword = { iconInvert = true },
		SupeSport = {
			hiltEnd = -1,
			hiltBias = 0.98,
			iconInvert = true,
		},
		KawashimaSword = {
			hiltEnd = -1,
			hiltBias = 0.98,
			iconInvert = true,
		},
		-- LastSword: grip tip-up only; size comes from global fit
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
