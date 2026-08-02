--!strict
--[[
	Ascension + Transcendence prestige system.

	Ascension: at Rebirth 60, reset rebirth/power/coins/talents -> +1 Ascension Token.
	Transcendence: at 10 Ascension Tokens, reset ascensions -> +1 Transcendence Shard.

	Weapons, pets, auras, relics, locations, and collection index are preserved.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PrestigeConfig = require(Shared.Config.PrestigeConfig)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)

local PrestigeService = {}

local function resetRebirthLayer(profile: any)
	profile.rebirthLevel = 0
	profile.rebirthMult = 1
	profile.lifetimePower = 0
	profile.lifetimeDamage = 0
	profile.coins = 0
	profile.power = 0
	profile.talentPoints = 0
	profile.unlockedTalents = { C_Core = 1, TheStart = 1 }
	profile.upgradeLevels = {
		RunSpeed = 0,
		Backpack = 0,
		Power = 0,
		ClickSpeed = 0,
		CritChance = 0,
		MultiCrit = 0,
		Luck = 0,
	}
end

function PrestigeService.Init()
	Remotes.Event("RequestAscension").OnServerEvent:Connect(function(player)
		PrestigeService.TryAscend(player)
	end)

	Remotes.Event("RequestTranscendence").OnServerEvent:Connect(function(player)
		PrestigeService.TryTranscend(player)
	end)
end

function PrestigeService.TryAscend(player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end

	local rb = profile.rebirthLevel or 0
	if rb < PrestigeConfig.ASCENSION_REBIRTH_REQ then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Ascension requires Rebirth %d (you are R%d)", PrestigeConfig.ASCENSION_REBIRTH_REQ, rb),
			color = "red",
		})
		return false
	end

	profile.ascensionTokens = (profile.ascensionTokens or 0) + 1
	profile.ascensionCount = (profile.ascensionCount or 0) + 1
	resetRebirthLayer(profile)
	PetService.SyncSlots(profile)

	local bonus = PrestigeConfig.GetAscensionBonus(profile.ascensionTokens)
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format(
			"ASCENSION %d!  +%d%% dmg  +%d%% coins  +%d%% luck  +%d pet slots",
			profile.ascensionTokens,
			bonus.damagePct,
			bonus.coinPct,
			bonus.luckPct,
			bonus.petSlots
		),
		color = "gold",
	})
	ProfileService.Push(player)
	return true
end

function PrestigeService.TryTranscend(player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end

	local tokens = profile.ascensionTokens or 0
	if tokens < PrestigeConfig.TRANSCENDENCE_REQ then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Transcendence requires %d Ascension Tokens (you have %d)", PrestigeConfig.TRANSCENDENCE_REQ, tokens),
			color = "red",
		})
		return false
	end

	profile.transcendenceShards = (profile.transcendenceShards or 0) + 1
	profile.transcendenceCount = (profile.transcendenceCount or 0) + 1
	profile.ascensionTokens = 0
	resetRebirthLayer(profile)
	PetService.SyncSlots(profile)

	local bonus = PrestigeConfig.GetTranscendenceBonus(profile.transcendenceShards)
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format(
			"TRANSCENDENCE %d!  +%d%% dmg  +%d%% coins  +%d%% luck",
			profile.transcendenceShards,
			bonus.damagePct,
			bonus.coinPct,
			bonus.luckPct
		),
		color = "gold",
	})
	ProfileService.Push(player)
	return true
end

return PrestigeService