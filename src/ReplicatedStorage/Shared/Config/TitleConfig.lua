--!strict
--[[
	Catalog of Titles with Rebirth requirements, shimmers, and power bonuses.
	Color Progression:
	  - R0..R3: Pure White (no shimmer)
	  - R4..R9: Ice Cyan Shimmer
	  - R10..R19: Emerald Green Shimmer
	  - R20..R29: Gold Yellow Shimmer
	  - R30..R39: Fire Orange Shimmer
	  - R40..R49: Void Purple Shimmer
	  - R50..R60: Full Rainbow 60FPS Shimmer
]]

local RebirthConfig = require(script.Parent.RebirthConfig)

local TitleConfig = {}

export type TitleDef = {
	id: string,
	name: string,
	rarity: string,
	shimmer: string, -- "none" | "rainbow" | "emerald" | "gold" | "fire" | "purple" | "cyan" | "silver"
	minRebirth: number,
	powerPct: number,
	description: string,
}

local list: { TitleDef } = {}

-- Add all 60 Rebirth Ranks
for r = 0, RebirthConfig.MAX_LEVEL do
	local name = RebirthConfig.GetRankName(r)
	local shimmer = "none"
	local rarity = "Common"

	if r <= 3 then
		shimmer = "none"
		rarity = "Common"
	elseif r <= 9 then
		shimmer = "cyan"
		rarity = "Rare"
	elseif r <= 19 then
		shimmer = "emerald"
		rarity = "Epic"
	elseif r <= 29 then
		shimmer = "gold"
		rarity = "Legendary"
	elseif r <= 39 then
		shimmer = "fire"
		rarity = "Mythic"
	elseif r <= 49 then
		shimmer = "purple"
		rarity = "Secret"
	else
		shimmer = "rainbow"
		rarity = "Limited"
	end

	local bonus = if r > 0 then (r * 0.05) else 0

	table.insert(list, {
		id = name:gsub("%s+", ""),
		name = name,
		rarity = rarity,
		shimmer = shimmer,
		minRebirth = r,
		powerPct = bonus,
		description = if r == 0 then "Starter rank" else string.format("Achieve Rebirth Rank %d", r),
	})
end

-- Add Special custom titles
table.insert(list, {
	id = "EmeraldSlayer",
	name = "Emerald Slayer",
	rarity = "Legendary",
	shimmer = "emerald",
	minRebirth = 6,
	powerPct = 0.35,
	description = "Master of the Emerald Realm",
})

table.insert(list, {
	id = "DragonGod",
	name = "Dragon God",
	rarity = "Limited",
	shimmer = "rainbow",
	minRebirth = 25,
	powerPct = 1.00,
	description = "Legendary Dragon Sovereign",
})

TitleConfig.Titles = list

function TitleConfig.Get(id: string): TitleDef?
	local cleanId = id:gsub("%s+", "")
	for _, t in TitleConfig.Titles do
		if t.id == cleanId or t.id == id or t.name == id then
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
			if ut == titleId or ut == def.id or ut == def.name then
				return true
			end
		end
	end
	return false
end

return TitleConfig
