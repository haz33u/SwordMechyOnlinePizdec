--!strict
--[[
	Weapon image assets — dump Loc1/Loc2 ids only.
]]

local IconConfig = {
	FallbackWeapon = "rbxassetid://6035056476",
	FallbackFrame = "",

	WeaponAssetIds = {
		-- Loc1 dump (uploaded)
		W1_C1 = "rbxassetid://116982617153585",
		W1_C2 = "rbxassetid://85575954431015",
		W1_C3 = "rbxassetid://82149069182844", -- reuse knife art until Bone Dagger upload
		W1_R1 = "rbxassetid://140029944614319",
		W1_E1 = "rbxassetid://72874627405282",
		W1_E2 = "rbxassetid://113405820939595",
		W1_L1 = "rbxassetid://92192514816761",
		W1_M1 = "rbxassetid://75341679116800",
		W1_S1 = "rbxassetid://122837329722306",
		-- Loc2 dump (fill when art ready)
		W2_C1 = "",
		W2_C2 = "",
		W2_C3 = "",
		W2_R1 = "",
		W2_R2 = "",
		W2_E1 = "",
		W2_E2 = "",
		W2_L1 = "",
	} :: { [string]: string },

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

function IconConfig.GetWeaponImage(weaponId: string): string
	local id = IconConfig.WeaponAssetIds[weaponId]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return IconConfig.FallbackWeapon
end

function IconConfig.GetFrameImage(rarity: string): string
	local id = IconConfig.FrameAssetIds[rarity]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return IconConfig.FallbackFrame
end

return IconConfig
