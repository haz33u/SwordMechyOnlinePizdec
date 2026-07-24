--!strict
--[[
	Aura visuals under ReplicatedStorage.AuraVfx (Place folder).
	All old placeholder models replaced with NEW high-tier VFX models from Workspace.Auras.
]]

export type AttachMode = "hrp" | "feet" | "back"

local AuraModelConfig = {
	FolderName = "AuraVfx",
	-- Mesh auras normalized (particle auras often small parts + big FX)
	TargetExtent = 2.2,
	TargetExtentMinFactor = 0.04,
	TargetExtentMaxFactor = 20,

	-- Exact NEW template model name under ReplicatedStorage.AuraVfx
	ModelByAuraId = {
		A_Test = "CORVUS",
		A_Ice = "CRYOGEN",
		A_Christmas = "COOLVAPOR",
		A_Light = "HEAVENLY",
		A_IceBreath = "InfiniteVortex",
		A_Leaf = "CELESTIALBODY",
		A_Darkness = "PureDarknessREVAMP",
		A_Protection = "ChainGod",
		A_Lightning = "CloakofLightning",
		A_Earth = "ObsidianHeart",
		A_Exhaustion = "PLAGUEFUMES",
		A_Wrath = "MUTANTSRAGE",
		A_Dragon = "RoarofTheJungleDragon",
		A_Kind = "ARMAGEDDON",
		A_Rebirth = "InfiniteReality",
		A_Lava = "FlameBarrage",
		A_Confrontation = "Battleship",
		A_Blaze = "BlueHeat",
		A_Knowledge = "DaemonofCards",
		A_Magic = "PsychicOrbs",
		A_Earthen = "Crystaldetermination",
		A_Vampirism = "RedRingofDeath",
		A_Fire = "FireEyes",
		A_Water = "AuroraBorealis",
		A_Nature = "BEAST",
		A_Voodoo = "POISON",
		A_Pumpkin = "HonoringFlame",
		A_Science = "NANO",
		A_Consciousness = "MUI",
		A_Blade = "Wano",
		A_Humility = "PureVessel",
		A_Instrumental = "Bass",
		A_Bone = "Rift",
		A_Cosmic = "SSJG",
		A_Snowflake = "CRYOGEN",
		A_Blackhole = "Blackhole",
		A_Armageddon = "ULTIMATEEVIL",
		A_SuperSonic = "SUPERSONIC",
		A_UltimateEvil = "ULTIMATEEVIL",
		A_UltraEgo = "ULTRAEGO",
		A_Corvus = "CORVUS",
		A_Insanity = "INSANITY",
		A_SunNecromancer = "SunNecromancer",
		A_SolarEclipse = "SolarEclipse",
		A_LunarEclipse = "LunarEclipse",
		A_DemonDrive = "DemonicDrive",
		A_Heavenly = "HEAVENLY",
		A_Angel = "ANGEL",
		A_Wormhole = "Wormhole",

		-- legacy aliases
		A_C1 = "CRYOGEN",
		A_C2 = "CELESTIALBODY",
		A_U1 = "ARMAGEDDON",
		A_R1 = "MUTANTSRAGE",
		A_E1 = "BlueHeat",
		A_L1 = "BEAST",
		A_M1 = "Wano",
	} :: { [string]: string },

	-- How to attach (mesh / procedural)
	AttachMode = {
		A_Test = "hrp",
		A_Ice = "hrp",
		A_Christmas = "hrp",
		A_Light = "back",
		A_IceBreath = "hrp",
		A_Leaf = "hrp",
		A_Darkness = "hrp",
		A_Protection = "hrp",
		A_Lightning = "hrp",
		A_Earth = "feet",
		A_Exhaustion = "hrp",
		A_Wrath = "hrp",
		A_Dragon = "hrp",
		A_Kind = "hrp",
		A_Rebirth = "hrp",
		A_Lava = "feet",
		A_Confrontation = "hrp",
		A_Blaze = "hrp",
		A_Knowledge = "hrp",
		A_Magic = "hrp",
		A_Earthen = "feet",
		A_Vampirism = "feet",
		A_Fire = "hrp",
		A_Water = "feet",
		A_Nature = "hrp",
		A_Voodoo = "hrp",
		A_Pumpkin = "hrp",
		A_Science = "hrp",
		A_Consciousness = "hrp",
		A_Blade = "back",
		A_Humility = "hrp",
		A_Instrumental = "feet",
		A_Bone = "hrp",
		A_Cosmic = "hrp",
		A_Snowflake = "hrp",
		A_Blackhole = "feet",
		A_Armageddon = "hrp",
		A_SuperSonic = "hrp",
		A_UltimateEvil = "hrp",
		A_UltraEgo = "hrp",
		A_Corvus = "hrp",
		A_Insanity = "hrp",
		A_SunNecromancer = "back",
		A_SolarEclipse = "back",
		A_LunarEclipse = "back",
		A_DemonDrive = "hrp",
		A_Heavenly = "back",
		A_Angel = "back",
		A_Wormhole = "feet",

		-- legacy aliases
		A_C1 = "hrp",
		A_C2 = "hrp",
		A_U1 = "hrp",
		A_R1 = "hrp",
		A_E1 = "hrp",
		A_L1 = "hrp",
		A_M1 = "back",
	} :: { [string]: AttachMode },

	-- Local offset from HRP (feet = lower Y, back = +Z behind)
	OffsetByMode = {
		hrp = Vector3.new(0, 0.1, 0),
		feet = Vector3.new(0, -2.2, 0),
		back = Vector3.new(0, 0.3, 0.65),
	},

	RarityColor = {
		Common = Color3.fromRGB(180, 190, 100),
		Uncommon = Color3.fromRGB(80, 200, 120),
		Rare = Color3.fromRGB(80, 140, 240),
		Epic = Color3.fromRGB(170, 90, 230),
		Legendary = Color3.fromRGB(240, 170, 60),
		Mythic = Color3.fromRGB(240, 80, 120),
	},
}

function AuraModelConfig.GetModelName(auraId: string): string?
	local n = AuraModelConfig.ModelByAuraId[auraId]
	if type(n) == "string" and n ~= "" then
		return n
	end
	return nil
end

function AuraModelConfig.GetAttachMode(auraId: string): AttachMode
	return AuraModelConfig.AttachMode[auraId] or "hrp"
end

function AuraModelConfig.GetOffset(auraId: string): Vector3
	local mode = AuraModelConfig.GetAttachMode(auraId)
	local o = AuraModelConfig.OffsetByMode[mode]
	return o or Vector3.new(0, 0.2, 0)
end

return AuraModelConfig
