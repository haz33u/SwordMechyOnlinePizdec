--!strict
--[[
	Weapon (and later pet/aura) image asset IDs.

	FILL WeaponAssetIds AFTER uploading PNGs in Studio (Asset Manager).
	Until filled, UI uses fallback rbxassetid (generic sword).

	Upload guide: docs/ICON_UPLOAD.md
	Source PNGs: art/icons/weapons/W1_*.png
]]

local IconConfig = {
	-- Generic fallbacks (public toolbox-style icons already used in UI)
	FallbackWeapon = "rbxassetid://6035056476",
	FallbackFrame = "", -- optional rarity frame later

	--[[
		weaponId → "rbxassetid://123456789"
		Example after upload:
		  W1_C1 = "rbxassetid://1234567890",
	]]
	WeaponAssetIds = {
		W1_C1 = "",
		W1_C2 = "",
		W1_U1 = "",
		W1_U2 = "",
		W1_R1 = "",
		W1_R2 = "",
		W1_E1 = "",
		W1_E2 = "",
		W1_L1 = "",
		W1_L2 = "",
		W1_M1 = "",
		W1_M2 = "",
		W1_S1 = "",
		W1_S2 = "",
		W1_X1 = "",
		-- Loc2+ fill when art ready
		W2_C1 = "",
		W2_C2 = "",
		W2_U1 = "",
		W2_U2 = "",
		W2_R1 = "",
		W2_R2 = "",
		W2_E1 = "",
		W2_E2 = "",
		W2_L1 = "",
		W2_L2 = "",
		W2_M1 = "",
		W2_M2 = "",
		W2_S1 = "",
		W2_S2 = "",
		W2_X1 = "",
		W3_C1 = "",
		W3_C2 = "",
		W3_U1 = "",
		W3_U2 = "",
		W3_R1 = "",
		W3_R2 = "",
		W3_E1 = "",
		W3_E2 = "",
		W3_L1 = "",
		W3_L2 = "",
		W3_M1 = "",
		W3_M2 = "",
		W3_S1 = "",
		W3_S2 = "",
		W3_X1 = "",
		W4_C1 = "",
		W4_C2 = "",
		W4_U1 = "",
		W4_U2 = "",
		W4_R1 = "",
		W4_R2 = "",
		W4_E1 = "",
		W4_E2 = "",
		W4_L1 = "",
		W4_L2 = "",
		W4_M1 = "",
		W4_M2 = "",
		W4_S1 = "",
		W4_S2 = "",
		W4_X1 = "",
	} :: { [string]: string },

	-- Optional rarity frame asset ids (empty = UIStroke only)
	FrameAssetIds = {
		Common = "",
		Uncommon = "",
		Rare = "",
		Epic = "",
		Legendary = "",
		Mythic = "",
		Secret = "",
		Limited = "",
	} :: { [string]: string },
}

function IconConfig.GetWeaponImage(weaponId: string?): string
	if weaponId then
		local id = IconConfig.WeaponAssetIds[weaponId]
		if type(id) == "string" and id ~= "" then
			return id
		end
	end
	return IconConfig.FallbackWeapon
end

function IconConfig.GetFrameImage(rarity: string?): string?
	if not rarity then
		return nil
	end
	local id = IconConfig.FrameAssetIds[rarity]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return nil
end

function IconConfig.HasCustomWeapon(weaponId: string): boolean
	local id = IconConfig.WeaponAssetIds[weaponId]
	return type(id) == "string" and id ~= ""
end

return IconConfig
