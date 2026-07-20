--!strict
--[[
	Maps WeaponConfig ids → Model names under ReplicatedStorage.WeaponModels.

	Place folder (not in git):
	  ReplicatedStorage.WeaponModels.<ModelName>

	Hold: free Tools use huge meshes + R6-ish Tool.Grip. We scale down and apply
	HoldTune so the handle sits in the R15 palm instead of through the torso.
]]

local WeaponModelConfig = {
	FolderName = "WeaponModels",

	ModelByWeaponId = {
		-- Loc1 rarity ladder bottom → top (6 free models)
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

	-- Free Toolbox swords are ~5–7 studs; ~0.45 keeps them hand-sized on R15.
	DefaultScale = 0.45,

	--[[
		Extra CFrame on top of (scaled) Tool.Grip when welding to hand.
		Tune in Play if a blade still clips the arm.
		Right: slight pitch so blade sits along the forearm / up.
	]]
	HoldTuneRight = CFrame.new(0, 0.05, 0.02) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	HoldTuneLeft = CFrame.new(0, 0.05, 0.02) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),

	-- If Tool.Grip still looks broken for a set, ignore it and use palm hold only.
	PreferPalmHold = true,

	-- Palm hold when PreferPalmHold (or no usable grip). Attachment-local CFrame.
	-- Handle long axis is usually +Y on free swords; grip near bottom of mesh.
	PalmHoldRight = CFrame.new(0, 0.9, 0) * CFrame.Angles(math.rad(90), math.rad(90), 0),
	PalmHoldLeft = CFrame.new(0, 0.9, 0) * CFrame.Angles(math.rad(90), math.rad(-90), 0),
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

return WeaponModelConfig
