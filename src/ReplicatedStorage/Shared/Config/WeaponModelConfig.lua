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
		Minecraft mode — WHERE TO TUNE (this file only):

		  src/ReplicatedStorage/Shared/Config/WeaponModelConfig.lua

		Blade direction is in **grip-attachment space** (not world):
		  X = right of palm · Y = out of knuckles / “up” of grip · Z = into/out of palm
		We point the mesh long axis (+Y on free swords) along MinecraftBladeDir*.

		If tip goes INTO the torso → more +Y / less toward body (see values below).
		If tip too vertical → add a bit of -Z (forward).
		If tip too far from body → lower |X|.
	]]
	--[[
		WHERE the palm sits on the mesh (fraction of longest axis from CENTER).
		  0.12 ≈ mid-blade  (bad — “holding the edge”)
		  0.40–0.48 ≈ hilt / pommel end (hold the HANDLE)
		Tip is opposite that end along the long axis.
	]]
	MinecraftHiltFactor = 0.42,

	--[[
		Blade TIP direction from the fist (grip space):
		  +X outward (right) · +Y up · -Z forward (out of knuckles)
	]]
	MinecraftBladeDirRight = Vector3.new(0.2, 0.9, -1.0),
	MinecraftBladeDirLeft = Vector3.new(-0.2, 0.9, -1.0),

	-- true = free mesh tip is opposite local +Y
	MinecraftFlipBladeRight = true,
	MinecraftFlipBladeLeft = false,

	--[[
		Push the whole sword in grip space (studs). Applied on the HAND side (C0)
		so position is “in front of the fist”, not along the blade into the chest.
		  -Z = forward  ·  ±X = away from torso
	]]
	MinecraftRightOffset = Vector3.new(0.1, 0.05, -0.55),
	MinecraftLeftOffset = Vector3.new(-0.1, 0.05, -0.55),

	MinecraftRightAngles = Vector3.new(0, 0, 0),
	MinecraftLeftAngles = Vector3.new(0, 0, 0),
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
