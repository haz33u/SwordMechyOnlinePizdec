--!strict
--[[
	Weapon 3D models + hold / inventory icon contract.
	See docs/WEAPON_HOLD.md and docs/WEAPON_ICONS.md

	IMPORTANT: hiltEnd is evaluated AFTER DefaultScale on the live part Size.
	Do NOT store absolute stud offsets from unscaled Toolbox sizes (they break after ScaleTo).

	Inventory = equal-size CARDS (Minecraft rule). World/hand scale is independent.
	Per-model overrides: hiltEnd (hand) + iconInvert (inventory flip only). Never size lists.
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
	-- DEPRECATED — size is global card fit. Do not use for new weapons.
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

	-- Hand / world size only (does NOT drive inventory card size)
	DefaultScale = 0.52,

	--[[
		ICON CARD standard (same for every weapon, including future giants):
		1) tip up + fixed yaw
		2) icon-only ScaleTo so lateral thickness is readable
		3) camera fits HEIGHT to IconFillHeight — never zoom into the mesh face
	]]
	IconYawDeg = -35,
	IconFov = 28,
	-- Silhouette height as fraction of viewport (equal card fill)
	IconFillHeight = 0.82,
	-- After pose: if min(X,Z) < this, ScaleTo icon clone up until lateral floor
	-- (stops hairlines without pulling camera into the blade)
	IconMinLateralStuds = 0.48,
	-- Cap how much we may enlarge a needle (avoid giant flat cards)
	IconLateralScaleMax = 4.5,
	IconCamDir = Vector3.new(0.55, 0.22, 0.85),
	IconDistMin = 1.2,
	IconDistMax = 16,
	-- Camera must stay outside half-diagonal * this factor
	IconNearClipFactor = 1.2,

	-- Legacy unused
	IconScale = 1,
	IconTargetExtent = 0,
	IconMinWidth = 0,

	HiltEndBias = 0.96,

	--[[
		hiltEnd: hand which end is HANDLE.
		iconInvert: one-bit inventory flip after tip-up (QA once per mesh).
		Old Sword: tip-up from Tool.Grip is correct — do NOT invert (was true → looked upside-down).
	]]
	HiltOverrides = {
		IronSword = { iconInvert = false },
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
