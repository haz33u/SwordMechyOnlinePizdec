--!strict
--[[
	Optional barrel for Config. Prefer requiring specific modules.
]]
return {
	Game = require(script.GameConfig),
	World = require(script.WorldConfig),
	Click = require(script.ClickConfig),
	Rebirth = require(script.RebirthConfig),
	Upgrade = require(script.UpgradeConfig),
	Location = require(script.LocationConfig),
	Mob = require(script.MobConfig),
	Weapon = require(script.WeaponConfig),
	Enchant = require(script.EnchantConfig),
	Pet = require(script.PetConfig),
	Aura = require(script.AuraConfig),
	Relic = require(script.RelicConfig),
	Quest = require(script.QuestConfig),
	Dungeon = require(script.DungeonConfig),
}
