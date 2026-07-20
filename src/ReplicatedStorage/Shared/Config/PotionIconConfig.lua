--!strict
--[[
	Potion icons (Figma ACCETSPOTIONS batch).

	RULE (LOCKED):
	  - *Potion (closed)  → inventory idle + shop texture
	  - *PotionOpen       → inventory hover only (swap Image on MouseEnter/Leave)

	Sizes: Small | Mid | Big | Globall (global server-wide potions)
	Stats: Coin | Damage | Luck | Power
	Backgrounds: BigBackGround, GloballBackground, MidBackground (solid black plate)
	Small cover: Group1261154050 (black cover for Small variant)

	Canonical IDs: docs/MASTER_PLAN.md §8.2
	PNG source folder: ACCETSPOTIONS (Downloads / art when copied)
]]

export type PotionSize = "Small" | "Mid" | "Big" | "Globall"
export type PotionStat = "Coin" | "Damage" | "Luck" | "Power"

local PotionIconConfig = {
	-- Background plates
	BigBackground = "rbxassetid://87813480175029", -- BigBackGroundPotion.png
	GloballBackground = "rbxassetid://124907509434472", -- GloballBackgroundPotion.png
	MidBackground = "rbxassetid://83821392234258", -- MidBackgroundPotion.png (solid black; park for later)
	SmallCover = "rbxassetid://71540050000210", -- Group 1261154050.png (black cover for Small)

	-- Big
	BigCoin = "rbxassetid://123525448642522",
	BigCoinOpen = "rbxassetid://85471490348637",
	BigDamage = "rbxassetid://77976545014734",
	BigDamageOpen = "rbxassetid://100846431333192",
	BigLuck = "rbxassetid://93921132820014",
	BigLuckOpen = "rbxassetid://114236597813508",
	BigPower = "rbxassetid://81684258283596",
	BigPowerOpen = "rbxassetid://112355517693170",

	-- Globall (global) — filename typo "Globall" kept in keys
	GloballCoin = "rbxassetid://128739216534711",
	GloballCoinOpen = "rbxassetid://85854368587544",
	GloballDamage = "rbxassetid://74581058727863",
	GloballDamageOpen = "rbxassetid://87264874596741",
	GloballLuck = "rbxassetid://138279482261455",
	GloballLuckOpen = "rbxassetid://113062484961240",
	GloballPower = "rbxassetid://109834286119069",
	GloballPowerOpen = "rbxassetid://120037569836057",

	-- Mid
	MidCoin = "rbxassetid://92630530796611",
	MidCoinOpen = "rbxassetid://73785912682549",
	MidDamage = "rbxassetid://109446287175098",
	MidDamageOpen = "rbxassetid://132235301402853",
	MidLuck = "rbxassetid://76287598017023",
	MidLuckOpen = "rbxassetid://115289485411140",
	MidPower = "rbxassetid://98113276595328",
	MidPowerOpen = "rbxassetid://85900601718525",

	-- Small
	SmallCoin = "rbxassetid://129754362855584",
	SmallCoinOpen = "rbxassetid://135452551473185",
	SmallDamage = "rbxassetid://126425760044867",
	SmallDamageOpen = "rbxassetid://131125671762922",
	SmallLuck = "rbxassetid://97002801957265",
	SmallLuckOpen = "rbxassetid://127967918786290",
	SmallPower = "rbxassetid://115507101515088",
	SmallPowerOpen = "rbxassetid://81848929788674",
}

local function key(size: string, stat: string, open: boolean): string
	return size .. stat .. (if open then "Open" else "")
end

function PotionIconConfig.Get(configKey: string): string
	local id = PotionIconConfig[configKey]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return ""
end

--- Idle / shop texture (closed bottle)
function PotionIconConfig.GetIdle(size: PotionSize, stat: PotionStat): string
	return PotionIconConfig.Get(key(size, stat, false))
end

--- Inventory hover only (open bottle)
function PotionIconConfig.GetHover(size: PotionSize, stat: PotionStat): string
	return PotionIconConfig.Get(key(size, stat, true))
end

return PotionIconConfig
