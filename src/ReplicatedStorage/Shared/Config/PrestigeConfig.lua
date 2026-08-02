--!strict
--[[
	Prestige layers on top of Rebirth.

	Rebirth 0..60 -> Ascension -> Transcendence.
	Each layer resets the layer below and grants permanent tokens.
]]

export type PrestigeBonus = {
	damagePct: number,
	coinPct: number,
	luckPct: number,
	petSlots: number,
}

local PrestigeConfig = {
	-- Rebirth required to perform first Ascension
	ASCENSION_REBIRTH_REQ = 60,

	-- Tokens granted per Ascension
	ASCENSION_BONUS_PER_TOKEN = {
		damagePct = 10,
		coinPct = 5,
		luckPct = 1,
		petSlots = 1,
	} :: PrestigeBonus,

	-- Ascension tokens required for first Transcendence
	TRANSCENDENCE_REQ = 10,

	-- Shards granted per Transcendence
	TRANSCENDENCE_BONUS_PER_SHARD = {
		damagePct = 25,
		coinPct = 10,
		luckPct = 5,
		petSlots = 0,
	} :: PrestigeBonus,
}

function PrestigeConfig.GetAscensionBonus(ascensionTokens: number): PrestigeBonus
	local n = math.max(0, ascensionTokens)
	local b = PrestigeConfig.ASCENSION_BONUS_PER_TOKEN
	return {
		damagePct = b.damagePct * n,
		coinPct = b.coinPct * n,
		luckPct = b.luckPct * n,
		petSlots = b.petSlots * n,
	}
end

function PrestigeConfig.GetTranscendenceBonus(transcendenceShards: number): PrestigeBonus
	local n = math.max(0, transcendenceShards)
	local b = PrestigeConfig.TRANSCENDENCE_BONUS_PER_SHARD
	return {
		damagePct = b.damagePct * n,
		coinPct = b.coinPct * n,
		luckPct = b.luckPct * n,
		petSlots = b.petSlots * n,
	}
end

function PrestigeConfig.GetTotalBonus(profile: any): PrestigeBonus
	local ascTokens = profile and profile.ascensionTokens or 0
	local trShards = profile and profile.transcendenceShards or 0
	local a = PrestigeConfig.GetAscensionBonus(ascTokens)
	local t = PrestigeConfig.GetTranscendenceBonus(trShards)
	return {
		damagePct = a.damagePct + t.damagePct,
		coinPct = a.coinPct + t.coinPct,
		luckPct = a.luckPct + t.luckPct,
		petSlots = a.petSlots + t.petSlots,
	}
end

return PrestigeConfig