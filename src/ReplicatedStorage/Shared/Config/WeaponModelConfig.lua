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
	MinecraftHiltFactor = 0.12,

	-- Unit-ish direction of the BLADE tip from the fist (right / left hand)
	-- Right: slightly outward (+X), mostly up (+Y), a bit forward (-Z in grip space)
	MinecraftBladeDirRight = Vector3.new(0.25, 1.0, -0.55),
	MinecraftBladeDirLeft = Vector3.new(-0.25, 1.0, -0.55),

	-- Nudge fist point (studs, grip space). +X = away from chest on right hand.
	MinecraftRightOffset = Vector3.new(0.12, 0.0, 0.0),
	MinecraftLeftOffset = Vector3.new(-0.12, 0.0, 0.0),

	-- Legacy euler fields (unused when BladeDir is set; kept for docs/old “forward” mode)
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
