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

	-- Free Toolbox swords are ~5–7 studs; ~0.5 is hand-sized on R15.
	DefaultScale = 0.5,

	--[[
		Hold mode (how C1 is built — same idea as Roblox Tool equip):

		  "tool"    — use free asset Tool.Grip (scaled). Best when each mesh
		              has its own grip authored in Toolbox.
		  "forward" — ignore Tool.Grip; force Y-long blade to point roughly
		              forward/up like classic sword sims (adequate, not perfect).

		Use "forward" for a consistent dual-wield look across mixed free models.
	]]
	HoldMode = "forward",

	-- Extra nudge after the base hold (both modes). Identity = no extra.
	HoldTuneRight = CFrame.new(),
	HoldTuneLeft = CFrame.new(),

	--[[
		"forward" mode: free swords usually have longest axis = local Y (blade).
		We put the palm near the hilt (along +Y into the mesh) and rotate so
		the blade leaves the hand forward/up — NOT out to the side.

		Recipe (R15 RightGripAttachment as C0):
		  C1 = CFrame.new(0, hiltAlongY, 0) * CFrame.Angles(rx, ry, rz)

		If a set still looks wrong, tweak only these angles (degrees in comments):
		  Right: -90 X, +90 Y  → blade along tool-forward of the grip attachment
		  Left:  mirror Y sign
	]]
	ForwardHiltFactor = 0.32, -- fraction of longest axis toward hilt from center
	ForwardRightAngles = Vector3.new(-90, 90, 0), -- degrees Euler XYZ
	ForwardLeftAngles = Vector3.new(-90, -90, 0),
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
