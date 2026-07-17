--!strict
--[[
	Rarity colors for weapons / pets / auras.
	Ladder: Common → … → Mythic → Secret → Limited
]]

local Rarity = {
	Order = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Secret",
		"Limited",
	},

	Colors = {
		Common = Color3.fromRGB(170, 175, 185),
		Uncommon = Color3.fromRGB(72, 180, 100),
		Rare = Color3.fromRGB(70, 130, 230),
		Epic = Color3.fromRGB(160, 80, 220),
		Legendary = Color3.fromRGB(230, 160, 50),
		Mythic = Color3.fromRGB(230, 70, 110),
		Secret = Color3.fromRGB(255, 230, 120),
		-- Limited: hot pink / cyan flex (client can animate)
		Limited = Color3.fromRGB(255, 80, 200),
	},
}

function Rarity.Of(name: string?): Color3
	if name and Rarity.Colors[name] then
		return Rarity.Colors[name]
	end
	return Rarity.Colors.Common
end

function Rarity.Index(name: string?): number
	if not name then
		return 1
	end
	for i, r in Rarity.Order do
		if r == name then
			return i
		end
	end
	return 1
end

return Rarity
