--!strict
--[[
	BattlePassService — Backend XP progression, tier unlocks, and reward claiming.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local RelicConfig = require(Shared.Config.RelicConfig)

local BattlePassService = {}

local XP_PER_LEVEL = 100
local MAX_LEVEL = 50

-- Rewards table for 50 levels (free & premium)
local BP_REWARDS = {}
for i = 1, MAX_LEVEL do
	BP_REWARDS[i] = {
		level = i,
		free = {
			kind = if i % 5 == 0 then "dust" else "coins",
			amount = if i % 5 == 0 then i * 2 else i * 200,
			title = if i % 5 == 0 then string.format("+%d Dust", i * 2) else string.format("+%d Coins", i * 200),
		},
		premium = {
			kind = if i % 10 == 0 then "petKey" elseif i % 5 == 0 then "relic" else "coins",
			amount = if i % 10 == 0 then 2 elseif i % 5 == 0 then 1 else i * 500,
			title = if i % 10 == 0 then "+2 Pet Keys" elseif i % 5 == 0 then "Rare Relic" else string.format("+%d Coins", i * 500),
		},
	}
end

function BattlePassService.Init()
	Remotes.Event("ClaimBPReward").OnServerEvent:Connect(function(player, level, isPremium)
		BattlePassService.ClaimReward(player, level, isPremium)
	end)
end

function BattlePassService.GetXPForLevel(level: number): number
	return XP_PER_LEVEL
end

function BattlePassService.AddXP(player: Player, amount: number)
	local profile = ProfileService.Get(player)
	if not profile or amount <= 0 then
		return
	end
	profile.battlePass = profile.battlePass or { level = 1, xp = 0, claimedFree = {}, claimedPremium = {} }
	local bp = profile.battlePass
	if bp.level >= MAX_LEVEL then
		return
	end

	bp.xp += amount
	local needed = XP_PER_LEVEL
	while bp.xp >= needed and bp.level < MAX_LEVEL do
		bp.xp -= needed
		bp.level += 1
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("★ Battle Pass Level Up! (Level %d)", bp.level),
			color = "gold",
		})
	end
	ProfileService.Push(player)
end

function BattlePassService.ClaimReward(player: Player, level: number, isPremium: boolean)
	local profile = ProfileService.Get(player)
	if not profile then return end
	profile.battlePass = profile.battlePass or { level = 1, xp = 0, claimedFree = {}, claimedPremium = {} }
	local bp = profile.battlePass

	if level > bp.level then
		Remotes.Event("Notify"):FireClient(player, { text = "Level not unlocked yet!", color = "red" })
		return
	end

	local rewardDef = BP_REWARDS[level]
	if not rewardDef then return end

	local reward = if isPremium then rewardDef.premium else rewardDef.free
	local claimedTable = if isPremium then bp.claimedPremium else bp.claimedFree

	if claimedTable[tostring(level)] then
		Remotes.Event("Notify"):FireClient(player, { text = "Reward already claimed!", color = "yellow" })
		return
	end

	if isPremium and not (profile.unlocks and profile.unlocks.battlePass) then
		Remotes.Event("Notify"):FireClient(player, { text = "Premium Battle Pass required!", color = "red" })
		return
	end

	claimedTable[tostring(level)] = true

	-- Grant reward
	if reward.kind == "coins" then
		profile.coins = (profile.coins or 0) + reward.amount
	elseif reward.kind == "dust" then
		profile.enchantDust = (profile.enchantDust or 0) + reward.amount
	elseif reward.kind == "petKey" then
		profile.petKeys = (profile.petKeys or 0) + reward.amount
	elseif reward.kind == "auraKey" then
		profile.auraKeys = (profile.auraKeys or 0) + reward.amount
	elseif reward.kind == "relic" then
		local relicId = RelicConfig.ResolveId("R_Common1")
		table.insert(profile.relics, { uid = ProfileService.NewUid(), id = relicId, stars = 0 })
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Claimed BP Reward: %s", reward.title),
		color = "gold",
	})
	ProfileService.Push(player)
end

return BattlePassService
