--!strict
--[[
	Aura visuals under ReplicatedStorage.AuraVfx (Place folder).
	Missing template → AuraVisual builds procedural ring + particles.
]]

export type AttachMode = "hrp" | "feet" | "back"

local AuraModelConfig = {
	FolderName = "AuraVfx",
	-- Mesh auras normalized (particle auras often small parts + big FX)
	TargetExtent = 2.2,
	TargetExtentMinFactor = 0.04,
	TargetExtentMaxFactor = 20,

	-- Exact template model name under ReplicatedStorage.AuraVfx
	ModelByAuraId = {
		A_Test = "Greenpower",
		A_Ice = "COOLVAPOR",
		A_Christmas = "SWEETWAVE",
		A_Light = "Spark",
		A_IceBreath = "COOLVAPOR",
		A_Leaf = "Foliage",
		A_Darkness = "PureDarknessREVAMP",
		A_Protection = "Purity",
		A_Lightning = "ElectricalCharge",
		A_Earth = "Crystaldetermination",
		A_Exhaustion = "PLAGUEFUMES",
		A_Wrath = "CrimsonMoon",
		A_Dragon = "RoarofTheJungleDragon",
		A_Kind = "WolfMist",
		A_Rebirth = "InfiniteReality",
		A_Lava = "FlameBarrage",
		A_Confrontation = "Battleship",
		A_Blaze = "BlueHeat",
		A_Knowledge = "DaemonofCards",
		A_Magic = "PSYCHIC",
		A_Earthen = "ObsidianHeart",
		A_Vampirism = "RedRingofDeath",
		A_Fire = "FireEyes",
		A_Water = "AuroraBorealis",
		A_Nature = "GuardianWings",
		A_Voodoo = "POISON",
		A_Pumpkin = "HonoringFlame",
		A_Science = "NANO",
		A_Consciousness = "InfiniteVortex",
		A_Blade = "Wano",
		A_Humility = "PureVessel",
		A_Instrumental = "Bass",
		A_Bone = "Rift",
		A_Cosmic = "CELESTIALBODY",
		A_Snowflake = "CRYOGEN",
		A_Blackhole = "Blackhole",
		A_Armageddon = "ARMAGEDDON",
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
		A_C1 = "COOLVAPOR",
		A_C2 = "Foliage",
		A_U1 = "WolfMist",
		A_R1 = "RoarofTheJungleDragon",
		A_E1 = "BlueHeat",
		A_L1 = "GuardianWings",
		A_M1 = "Rift",
	} :: { [string]: string },

	-- How to attach (mesh / procedural)
	AttachMode = {
		A_Test = "feet",
		A_Ice = "hrp",
		A_Christmas = "hrp",
		A_Light = "hrp",
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
		A_Nature = "back",
		A_Voodoo = "hrp",
		A_Pumpkin = "hrp",
		A_Science = "hrp",
		A_Consciousness = "hrp",
		A_Blade = "back",
		A_Humility = "hrp",
		A_Instrumental = "feet",
		A_Bone = "hrp",
		A_Cosmic = "hrp",
		A_Snowflake = "feet",
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
		A_C2 = "feet",
		A_U1 = "hrp",
		A_R1 = "feet",
		A_E1 = "hrp",
		A_L1 = "back",
		A_M1 = "hrp",
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
