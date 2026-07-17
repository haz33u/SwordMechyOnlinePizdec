--!strict
--[[
	Global tunables for the skeleton. All balance lives here.
	No donate / no premium currency in skeleton phase.
]]

local GameConfig = {
	DISPLAY_NAME = "Sword Masters",
	VERSION = "0.4.1-hpbar-near-spawn",

	-- combat
	BASE_POWER = 10,
	BASE_SWING_COOLDOWN = 0.50, -- seconds
	MIN_SWING_COOLDOWN = 0.12,
	HIT_RANGE = 12,
	-- auto-clicker defaults live in ClickConfig.lua

	-- inventory
	START_PET_SLOTS = 1,
	MAX_PET_SLOTS = 7,
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
}

return GameConfig
