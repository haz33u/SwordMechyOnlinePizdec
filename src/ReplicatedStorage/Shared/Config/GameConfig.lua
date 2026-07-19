--!strict
--[[
	Global tunables for the skeleton. All balance lives here.
	No donate / no premium currency in skeleton phase.
]]

local GameConfig = {
	DISPLAY_NAME = "Sword Masters",
	VERSION = "0.5.13-bags-power-costs-crit-lock",

	-- combat
	-- With Loc1 weapon "Сила" as powerMult (1–150), BASE≈250 → starter kills 1K HP goblin in ~4 hits (~2s at 2 CPS)
	BASE_POWER = 250,
	BASE_SWING_COOLDOWN = 0.50, -- seconds
	MIN_SWING_COOLDOWN = 0.12,
	HIT_RANGE = 12,
	-- auto-clicker defaults live in ClickConfig.lua

	-- inventory — pet slots in ProgressConfig (max 8)
	START_PET_SLOTS = 3,
	MAX_PET_SLOTS = 8, -- equip team
	MAX_PETS_OWNED = 32, -- bag base; +Backpack upgrade (see UpgradeConfig.BASE_BAG_SLOTS)
	START_WEAPON_BAG = 32,
	START_ITEM_BAG = 32,
	START_RELIC_SLOTS = 3,
	MAX_RELIC_SLOTS = 6,

	-- soft currency name
	COIN_NAME = "Coins",

	-- save
	DATASTORE_NAME = "SwordMasters_Skeleton_v1",
	AUTOSAVE_SECONDS = 60,

	-- debug
	DEBUG = true,
	GIVE_STARTER_KIT = true,
	STARTER_COINS = 2_000, -- faster first tests
	-- case keys: see CaseConfig.STARTER_PET_KEYS / STARTER_AURA_KEYS
}

return GameConfig
