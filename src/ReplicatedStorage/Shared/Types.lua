--!strict
--[[
	Shared type aliases for Sword Masters skeleton.
]]

export type WeaponInstance = {
	uid: string,
	id: string,
	enchants: { EnchantRoll },
}

export type EnchantRoll = {
	id: string,
	value: number, -- percent, can be negative (debuff)
	quality: string,
}

export type PetInstance = {
	uid: string,
	id: string,
	level: number,
	enchants: { EnchantRoll },
}

export type AuraInstance = {
	uid: string,
	id: string,
	level: number,
}

export type RelicInstance = {
	uid: string,
	id: string,
	stars: number,
}

export type QuestState = {
	id: string,
	progress: number,
	completed: boolean,
	claimed: boolean,
}

export type PlayerProfile = {
	-- currencies (soft only for skeleton)
	coins: number,

	-- core progression
	lifetimePower: number,
	lifetimeDamage: number,
	rebirthLevel: number,
	rebirthMult: number,

	-- character upgrades
	upgradeLevels: { [string]: number },

	-- equipment
	weapons: { WeaponInstance },
	equippedMain: string?,
	equippedOffhand: string?,
	pets: { PetInstance },
	petTeam: { string }, -- uids, max slots
	petSlots: number,
	auras: { AuraInstance },
	equippedAura: string?,
	relics: { RelicInstance },
	equippedRelics: { string },

	-- world
	locationsUnlocked: { number },
	currentLocation: number,
	quests: { [string]: QuestState },

	-- dungeon progress (skeleton)
	dungeonStage: { easy: number, medium: number, hard: number },

	-- drop bans (filter trash)
	bannedWeaponIds: { [string]: boolean },
	bannedPetIds: { [string]: boolean },
	bannedAuraIds: { [string]: boolean },

	-- clicks (core)
	totalClicks: number,
	autoClicker: boolean,
	autoClickerUnlocked: boolean,
}

return nil
