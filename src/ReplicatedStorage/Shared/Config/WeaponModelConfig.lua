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
	-- Custom scale multiplier (1.0 = standard ~4.2 studs, 0.7 = dagger, 1.3 = giant weapon)
	scaleMult: number?,
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

	-- Loc1 Dark Forest meshes (import FBX from art/meshes/loc1_dark_forest into Place).
	-- Until Place has DF_* models, keep free Toolbox names as runtime fallback via LegacyModelNames.
	ModelByWeaponId = {
		starter_weapon = "TrainingClubSword",
		old_sword = "BattleWornLongsword",
		bone_dagger = "TribalBoneDagger",
		wooden_mace = "Stone Ha.",
		double_edged_sword = "Iron Sw.",
		forest_spirit_staff = "Iron Sp.",
		ardite = "Gold Sw.",
		forest_sword = "Emerald Sw.",
		forest_shadow = "Ruby Sw.",

		pirate_hook = "PirateHook",
		pirate_hammer = "PirateHammer",
		pirate_saber = "PirateSaber",
		golden_plated_sword = "GoldenPlatedSword",
		captain_axe = "CaptainAxe",
		element_blade = "ElementBlade",
		emerald_blade = "EmeraldBlade",
		sea_dagger = "SeaDagger",

		shinobi_katana = "ShinobiKatana",
		shadow_kunai = "ShadowKunai",
		dragon_tanto = "DragonTanto",
		muramasa_blade = "MuramasaBlade",
		samurai_god_katana = "SamuraiGodKatana",
		shadow_shogun_blade = "ShadowShogunBlade",

		ice_dagger = "IceDagger",
		frost_cleaver = "FrostCleaver",
		glacier_scythe = "GlacierScythe",
		blizzard_sword = "BlizzardSword",
		ice_dragon_fang = "IceDragonFang",
		polar_sovereign_blade = "PolarSovereignBlade",

		ash_shiv = "AshShiv",
		magma_maul = "MagmaMaul",
		obsidian_glaive = "ObsidianGlaive",
		inferno_blade = "InfernoBlade",
		volcano_god_sword = "VolcanoGodSword",
		phoenix_ash_blade = "PhoenixAshBlade",

		neon_dagger = "NeonDagger",
		plasma_cutlass = "PlasmaCutlass",
		cyber_katana = "CyberKatana",
		lightning_greatsword = "LightningGreatsword",
		overseer_proto_blade = "OverseerProtoBlade",
		dimensional_edge = "DimensionalEdge",

		bone_knife = "BoneKnife",
		crypt_rapier = "CryptRapier",
		soul_reaver_scythe = "SoulReaverScythe",
		cathedral_longsword = "CathedralLongsword",
		bone_overlord_cleaver = "BoneOverlordCleaver",
		celestial_void_blade = "CelestialVoidBlade",

		stone_sword = "Stone Sw.",
		stone_scythe = "Stone Sy.",
		stone_spear = "Stone Sp.",
		stone_hammer = "Stone Ha.",
		iron_sword = "Iron Sw.",
		iron_scythe = "Iron Sy.",
		iron_spear = "Iron Sp.",
		iron_hammer = "Iron Ha.",
		gold_sword = "Gold Sw.",
		gold_scythe = "Gold Sy.",
		gold_spear = "Gold Sp.",
		gold_hammer = "Gold Ha.",
		titanium_sword = "Titanium Sw.",
		titanium_scythe = "Titanium Sy.",
		titanium_spear = "Titanium Sp.",
		titanium_hammer = "Titanium Ha.",
		emerald_sword = "Emerald Sw.",
		emerald_scythe = "Emerald Sy.",
		emerald_spear = "Emerald Sp.",
		emerald_hammer = "Emerald Ha.",
		ruby_sword = "Ruby Sw.",
		ruby_scythe = "Ruby Sy.",
		ruby_spear = "Ruby Sp.",
		ruby_hammer = "Ruby Ha.",
		atherite_sword = "Atherite Sw.",
		celestium_sword = "Celestium Sw.",
		voidsteel_sword = "Voidsteel Sw.",
	} :: { [string]: string },

	-- If DF_* missing in Place, WeaponModels may resolve these (optional fallbacks).
	LegacyModelNames = {
		DF_StarterStick = "StarterSword",
		DF_MossRust = "IronSword",
		DF_BoneThorn = "PixelIronSword",
		DF_RootMace = "GoldSword",
		DF_Twinleaf = "RubySword",
		DF_SpiritBranch = "DiamondSword",
		DF_Amberheart = "KawashimaSword",
		DF_CanopyFang = "SupeSport",
		DF_UmbralBough = "LastSword",
	} :: { [string]: string },

	-- Automatic length normalization: target total sword length in world studs (~6.0 studs for 2x size weapons).
	-- Any imported FBX / Toolbox mesh is automatically scaled so its total physical length matches this target.
	TargetLengthStuds = 6.0,
	DefaultScale = 0.50,

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
	-- DF_* authored +Y tip / origin grip — default bake is fine.
	HiltOverrides = {
		IronSword = { iconInvert = false },
		RubySword = { iconInvert = true },
		SupeSport = {
			hiltBias = 0.98,
			iconInvert = true,
		},
		KawashimaSword = {
			hiltBias = 0.98,
			iconInvert = true,
		},
		-- Dark Forest set (automatic size normalization with category variance)
		DF_StarterStick = { iconInvert = false },
		DF_MossRust = { iconInvert = false },
		DF_BoneThorn = { scaleMult = 0.72, iconInvert = false }, -- Dagger ~3.0 studs
		DF_RootMace = { scaleMult = 0.92, iconInvert = false },
		DF_Twinleaf = { iconInvert = false },
		DF_SpiritBranch = { scaleMult = 1.22, iconInvert = false }, -- Staff ~5.1 studs
		DF_Amberheart = { iconInvert = false },
		DF_CanopyFang = { scaleMult = 1.10, iconInvert = false }, -- Greatsword ~4.6 studs
		DF_UmbralBough = { scaleMult = 1.15, iconInvert = false },

		-- Incremental Hammers (reduce wide hammer heads so they don't block screen)
		["Stone Ha."] = { scaleMult = 0.80 },
		["Iron Ha."] = { scaleMult = 0.80 },
		["Gold Ha."] = { scaleMult = 0.80 },
		["Emerald Ha."] = { scaleMult = 0.80 },
		["Ruby Ha."] = { scaleMult = 0.80 },
		["Titanium Ha."] = { scaleMult = 0.80 },

		-- Incremental Scythes
		["Stone Sy."] = { scaleMult = 0.90 },
		["Iron Sy."] = { scaleMult = 0.90 },
		["Gold Sy."] = { scaleMult = 0.90 },
		["Emerald Sy."] = { scaleMult = 0.90 },
		["Ruby Sy."] = { scaleMult = 0.90 },
		["Titanium Sy."] = { scaleMult = 0.90 },

		-- Incremental Spears
		["Stone Sp."] = { scaleMult = 1.05 },
		["Iron Sp."] = { scaleMult = 1.05 },
		["Gold Sp."] = { scaleMult = 1.05 },
		["Emerald Sp."] = { scaleMult = 1.05 },
		["Ruby Sp."] = { scaleMult = 1.05 },
		["Titanium Sp."] = { scaleMult = 1.05 },
	} :: { [string]: HiltOverride },

	-- Optional recolor if Place mesh is grey after FBX import (not used for multi-part DF builds).
	MaterialLooks = {
		DF_StarterStick = { color = Color3.fromRGB(90, 65, 48), material = Enum.Material.Wood },
		DF_MossRust = { color = Color3.fromRGB(55, 60, 68), material = Enum.Material.Metal },
		DF_BoneThorn = { color = Color3.fromRGB(200, 185, 150), material = Enum.Material.SmoothPlastic },
		DF_RootMace = { color = Color3.fromRGB(70, 50, 35), material = Enum.Material.Wood },
		DF_Twinleaf = { color = Color3.fromRGB(120, 128, 135), material = Enum.Material.Metal },
		DF_SpiritBranch = { color = Color3.fromRGB(90, 230, 140), material = Enum.Material.Neon },
		DF_Amberheart = { color = Color3.fromRGB(220, 130, 40), material = Enum.Material.Neon },
		DF_CanopyFang = { color = Color3.fromRGB(100, 140, 90), material = Enum.Material.Metal },
		DF_UmbralBough = { color = Color3.fromRGB(100, 65, 160), material = Enum.Material.Neon },
	} :: { [string]: { color: Color3, material: Enum.Material } },

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
