--!strict
--[[
	Maps WeaponConfig ids → Model names under ReplicatedStorage.WeaponModels.

	Minecraft-style hold (target look):
	  - Arm raised (WeaponVisual READY pose) — not hanging at hip
	  - Blade leaves the FIST up/diagonal (can clip through hand mesh like MC)
	  - Must NOT originate from shoulder / stick out of the elbow sideways
]]

local WeaponModelConfig = {
	FolderName = "WeaponModels",

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

	-- Slightly larger than 0.45 — MC swords read better when chunky
	DefaultScale = 0.55,

	--[[
		HoldMode:
		  "minecraft" — blade from fist up/diagonal (with arm READY pose)
		  "forward"   — classic sim side/forward hold
		  "tool"      — free asset Tool.Grip
	]]
	HoldMode = "minecraft",

	HoldTuneRight = CFrame.new(),
	HoldTuneLeft = CFrame.new(),

	-- Shared hilt: small factor = more blade "through" the hand (MC-like clip)
	ForwardHiltFactor = 0.18,
	ForwardRightAngles = Vector3.new(-90, 90, 0),
	ForwardLeftAngles = Vector3.new(-90, -90, 0),

	--[[
		Minecraft mode (arm is in READY ≈ pitch -90, hand in front of torso).
		Free swords: longest axis usually local +Y (blade).

		Hilt near palm; blade extends out of the fist (through hand mesh is OK).
		Tune only these if tip still points wrong:
	]]
	MinecraftHiltFactor = 0.14,
	-- degrees Euler applied as CFrame.Angles(rx, ry, rz) after hilt offset on +Y
	MinecraftRightAngles = Vector3.new(0, 0, 90),
	MinecraftLeftAngles = Vector3.new(0, 0, -90),
	-- Extra shift in grip-attachment space (studs): push blade out of fist, not into shoulder
	MinecraftRightOffset = Vector3.new(0, 0, -0.05),
	MinecraftLeftOffset = Vector3.new(0, 0, -0.05),
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
