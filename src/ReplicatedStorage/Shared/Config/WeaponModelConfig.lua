--!strict
--[[
	Weapon 3D models + hold / inventory icon contract.
	See docs/WEAPON_HOLD.md
]]

export type HiltOverride = {
	-- Absolute tip along longest axis: +1 or -1. Palm at opposite end.
	tipSign: number?,
	flipTip: boolean?, -- relative invert (avoid if tipSign set)
	hiltBias: number?, -- 0.55–0.995, default ~0.94; higher = closer to geometric end
	-- Absolute local hilt position on PrimaryPart (overrides tipSign/bias if set)
	hiltPosition: Vector3?,
	-- Tip direction for attachment +Y (defaults to -hiltPosition.Unit)
	tipDirection: Vector3?,
	-- Inventory: applied AFTER camera framing (must not be wiped by PivotTo)
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
	IconScale = 0.7,
	HiltEndBias = 0.94,

	--[[
		QA locks 2026-07-20 (re-tested until correct):
		  tipSign +1 put palm on BLADE for Ardite/Forest → use -1 + high bias.
		  Icons: euler applied AFTER framing (see WeaponModels.frameModelInViewport).
	]]
	HiltOverrides = {
		-- Old Sword: hand OK; icon upside-down
		IronSword = {
			iconEuler = Vector3.new(180, 0, 0),
		},
		-- Double-Edged: icon upside-down
		RubySword = {
			iconEuler = Vector3.new(180, 0, 0),
		},
		-- Forest Sword (Y-long ~4.73): absolute palm at +Y end = handle
		SupeSport = {
			hiltPosition = Vector3.new(0, 2.30, 0),
			tipDirection = Vector3.new(0, -1, 0),
			iconEuler = Vector3.new(180, 0, 0),
		},
		-- Ardite (Z-long ~5.60): absolute palm at +Z end = handle
		KawashimaSword = {
			hiltPosition = Vector3.new(0, 0, 2.70),
			tipDirection = Vector3.new(0, 0, -1),
			iconEuler = Vector3.new(0, 0, -90),
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
