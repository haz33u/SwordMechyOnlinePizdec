--!strict
--[[
	Daily login reward + streak.
	Claim via remote. Streak shown in profile snapshot and side HUD.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DailyConfig = require(Shared.Config.DailyConfig)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)

local DailyRewardService = {}

function DailyRewardService.Init()
	Remotes.Event("ClaimDaily").OnServerEvent:Connect(function(player)
		DailyRewardService.Claim(player)
	end)
end

function DailyRewardService.OnJoin(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	profile.dailyStreak = profile.dailyStreak or 0
	profile.dailyLastClaim = profile.dailyLastClaim or 0
end

function DailyRewardService.Claim(player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end

	local now = os.time()
	local last = profile.dailyLastClaim or 0
	local daySeconds = 24 * 3600
	local elapsed = now - last

	if elapsed < daySeconds then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Daily reward already claimed. Come back tomorrow!",
			color = "yellow",
		})
		return false
	end

	if elapsed > DailyConfig.STREAK_GRACE_SECONDS then
		profile.dailyStreak = 0
	end

	profile.dailyStreak = (profile.dailyStreak or 0) + 1
	profile.dailyLastClaim = now

	local reward = DailyConfig.GetReward(profile, profile.dailyStreak)
	profile.coins = (profile.coins or 0) + reward.coins
	profile.auraKeys = (profile.auraKeys or 0) + reward.keys
	profile.enchantDust = (profile.enchantDust or 0) + reward.dust
	profile.petKeys = (profile.petKeys or 0) + reward.petKeys

	Remotes.Event("DailyClaimed"):FireClient(player, {
		streak = profile.dailyStreak,
		reward = reward,
	})
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Daily Day %d! +%s coins, +%d keys, +%d dust", profile.dailyStreak, tostring(reward.coins), reward.keys, reward.dust),
		color = "gold",
	})
	ProfileService.Push(player)
	return true
end

return DailyRewardService
