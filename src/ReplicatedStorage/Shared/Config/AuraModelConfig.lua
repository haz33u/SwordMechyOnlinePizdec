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

	-- Template name under AuraVfx (or empty = procedural only)
	ModelByAuraId = {
		A_Test = "",
		A_C1 = "Spark",
		A_C2 = "Foliage",
		A_U1 = "WolfMist",
		A_R1 = "ShadowRing",
		A_E1 = "Flame",
		A_L1 = "GuardianWings",
		A_M1 = "Rift",
		A_Galaxy = "GalaxyAura",
		A_DarkMatter = "DarkMatterAura",
		A_Empyrus = "EmpyrusAura",
		A_Glitched = "GlitchedAura",
		A_God = "GodAura",
		A_Ultraverse = "UltraverseAura",
		A_Blackhole = "BlackholeAura",
		A_Flamethrower = "FlamethrowerAura",
		A_DeepGalaxy = "DeepGalaxyAura",
		A_Hell = "HellAura",
		A_RedScarlet = "RedScarletAura",
	} :: { [string]: string },

	-- How to attach (mesh / procedural)
	AttachMode = {
		A_Test = "feet",
		A_C1 = "hrp",
		A_C2 = "feet",
		A_U1 = "hrp",
		A_R1 = "feet",
		A_E1 = "hrp",
		A_L1 = "back",
		A_M1 = "hrp",
		A_Galaxy = "hrp",
		A_DarkMatter = "feet",
		A_Empyrus = "back",
		A_Glitched = "hrp",
		A_God = "back",
		A_Ultraverse = "hrp",
		A_Blackhole = "feet",
		A_Flamethrower = "hrp",
		A_DeepGalaxy = "hrp",
		A_Hell = "feet",
		A_RedScarlet = "hrp",
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
