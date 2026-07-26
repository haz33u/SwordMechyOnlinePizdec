--!strict
--[[
	Catalog of Titles with Rebirth requirements, shimmers, and power bonuses.
]]

local TitleConfig = {}

export type TitleDef = {
	id: string,
	name: string,
	rarity: string,
	shimmer: string, -- "rainbow" | "emerald" | "gold" | "fire" | "purple" | "cyan" | "silver"
	minRebirth: number,
	powerPct: number,
	description: string,
}

TitleConfig.Titles = {
	{
		id = "Rookie",
		name = "Rookie",
		rarity = "Common",
		shimmer = "silver",
		minRebirth = 0,
		powerPct = 0,
		description = "Default starter title",
	},
	{
		id = "NoviceSwordsman",
		name = "Novice Swordsman",
		rarity = "Uncommon",
		shimmer = "silver",
		minRebirth = 1,
		powerPct = 0.05,
		description = "Achieve Rebirth 1",
	},
	{
		id = "BladeInitiate",
		name = "Blade Initiate",
		rarity = "Rare",
		shimmer = "cyan",
		minRebirth = 2,
		powerPct = 0.10,
		description = "Achieve Rebirth 2",
	},
	{
		id = "Stormbane",
		name = "Stormbane",
		rarity = "Epic",
		shimmer = "gold",
		minRebirth = 4,
		powerPct = 0.15,
		description = "Achieve Rebirth 4",
	},
	{
		id = "EmeraldSlayer",
		name = "Emerald Slayer",
		rarity = "Legendary",
		shimmer = "emerald",
		minRebirth = 6,
		powerPct = 0.25,
		description = "Achieve Rebirth 6",
	},
	{
		id = "FireLord",
		name = "Fire Lord",
		rarity = "Mythic",
		shimmer = "fire",
		minRebirth = 10,
		powerPct = 0.40,
		description = "Achieve Rebirth 10",
	},
	{
		id = "VoidMonarch",
		name = "Void Monarch",
		rarity = "Secret",
		shimmer = "purple",
		minRebirth = 15,
		powerPct = 0.60,
		description = "Achieve Rebirth 15",
	},
	{
		id = "DragonGod",
		name = "Dragon God",
		rarity = "Limited",
		shimmer = "rainbow",
		minRebirth = 25,
		powerPct = 1.00,
		description = "Achieve Rebirth 25",
	},
} :: { TitleDef }

function TitleConfig.Get(id: string): TitleDef?
	for _, t in TitleConfig.Titles do
		if t.id == id or t.name == id then
			return t
		end
	end
	return nil
end

function TitleConfig.IsUnlocked(profile: any, titleId: string): boolean
	local def = TitleConfig.Get(titleId)
	if not def then
		return false
	end
	if def.minRebirth == 0 then
		return true
	end
	local reb = (profile and profile.rebirthLevel) or 0
	if reb >= def.minRebirth then
		return true
	end
	if profile and profile.unlockedTitles then
		for _, ut in profile.unlockedTitles do
			if ut == titleId or ut == def.id then
				return true
			end
		end
	end
	return false
end

return TitleConfig
