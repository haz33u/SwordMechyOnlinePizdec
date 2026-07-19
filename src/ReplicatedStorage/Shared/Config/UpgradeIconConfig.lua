--!strict
--[[
	Character Upgrade icons (Figma MainCharacterUpgrader).

	PNG sources (git): art/icons/upgrades/
	  icon_strength.png, icon_backpack.png, icon_speed.png,
	  icon_crit.png, icon_multicrit.png, coin.png, close.png

	HOW TO GET rbxassetid (Studio, once):
	1. Open Asset Manager → Images → Bulk Import
	2. Select folder art/icons/upgrades/*.png
	3. After upload, right-click image → Copy Asset ID
	4. Paste below as "rbxassetid://NUMBER"

	Agent cannot auto-upload: Studio MCP upload_image only trusts
	specific CDNs (Figma/GitHub/local rejected).
]]

local UpgradeIconConfig = {
	-- Fill after Bulk Import (leave "" for gradient+glyph fallback)
	Power = "", -- icon_strength.png
	Backpack = "", -- icon_backpack.png
	ClickSpeed = "", -- icon_speed.png
	CritChance = "", -- icon_crit.png
	MultiCrit = "", -- icon_multicrit.png
	Coin = "", -- coin.png
	Close = "", -- close.png
}

function UpgradeIconConfig.Get(key: string): string
	local id = UpgradeIconConfig[key]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return ""
end

return UpgradeIconConfig
