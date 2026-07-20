--!strict
--[[
	General UI icons (Quest, Coin Shop packs, etc.).

	Canonical IDs also in docs/MASTER_PLAN.md §8.3 UI Asset Registry (extra).
	Uploaded via Studio Asset Manager — do not lose / re-upload casually.

	Agent rule: use UiIconConfig.Get(key) or GetCoinShop(n) — never invent
	placeholder decals for these keys.
]]

local UiIconConfig = {
	-- Quest chrome / rail / panel
	QuestIcon = "rbxassetid://111972532166796",

	-- Coin shop product tiers (1 = primary CoinShop)
	CoinShop = "rbxassetid://126265387260987", -- CoinShop / tier 1
	CoinShop1 = "rbxassetid://126265387260987", -- alias of CoinShop
	CoinShop2 = "rbxassetid://92652371656965",
	CoinShop3 = "rbxassetid://122342766899212",
	CoinShop4 = "rbxassetid://107120449770577",
	CoinShop5 = "rbxassetid://70679769514889",
}

function UiIconConfig.Get(key: string): string
	local id = UiIconConfig[key]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return ""
end

--- Coin shop tier icon by index 1..5 (0 or out of range → CoinShop1).
function UiIconConfig.GetCoinShop(tier: number): string
	local n = math.clamp(math.floor(tier), 1, 5)
	local key = "CoinShop" .. tostring(n)
	return UiIconConfig.Get(key)
end

return UiIconConfig
