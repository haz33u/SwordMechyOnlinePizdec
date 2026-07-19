--!strict
--[[
	Character Upgrade icons (Figma MainCharacterUpgrader).

	PNG sources (git): art/icons/upgrades/
	  icon_strength.png, icon_backpack.png, icon_speed.png,
	  icon_crit.png, icon_multicrit.png, coin.png, close.png, shop.png

	Canonical IDs also listed in docs/MASTER_PLAN.md § UI Asset Registry.

	HOW TO GET rbxassetid (Studio, once):
	1. Open Asset Manager → Images → Bulk Import
	2. Select folder art/icons/upgrades/*.png
	3. After upload, right-click image → Copy Asset ID
	4. Paste below as "rbxassetid://NUMBER"

	Agent cannot auto-upload: Studio MCP upload_image only trusts
	specific CDNs (Figma/GitHub/local rejected).
]]

local UpgradeIconConfig = {
	-- Uploaded from art/icons/upgrades/ (leave "" for gradient+glyph fallback)
	Power = "rbxassetid://93071491476836", -- icon_strength.png
	Backpack = "rbxassetid://113695116998745", -- icon_backpack.png
	ClickSpeed = "rbxassetid://101300421089207", -- icon_speed.png (WalkSpeed)
	WalkSpeed = "rbxassetid://101300421089207", -- alias of ClickSpeed
	CritChance = "rbxassetid://94418234037518", -- icon_crit.png
	MultiCrit = "rbxassetid://75432680898371", -- icon_multicrit.png
	Coin = "rbxassetid://80023959014102", -- coin.png
	Close = "rbxassetid://94627396642381", -- close.png
	Shop = "rbxassetid://133565026221740", -- shop.png
}

function UpgradeIconConfig.Get(key: string): string
	local id = UpgradeIconConfig[key]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return ""
end

return UpgradeIconConfig
