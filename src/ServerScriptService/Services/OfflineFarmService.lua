--!strict
--[[
	Offline / AFK farm reward.

	Rules:
	  - Max 8 hours of offline earnings.
	  - Earns ~0.5% of active DPS as offline power, converted to coins.
	  - Bonuses from talents/titles can raise the rate.
	  - Not a replacement for active play; rewards returning.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local TalentTreeConfig = require(Shared.Config.TalentTreeConfig)
local LocationConfig = require(Shared.Config.LocationConfig)

local OfflineFarmService = {}

local MAX_OFFLINE_SECONDS = 8 * 3600
local BASE_OFFLINE_RATE = 0.005 -- 0.5% of active DPS
local COINS_PER_OFFLINE_POWER = 0.08

local function compact(n: number): string
	if n >= 1e18 then
		return string.format("%.2fQi", n / 1e18)
	elseif n >= 1e15 then
		return string.format("%.2fQa", n / 1e15)
	elseif n >= 1e12 then
		return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.2fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

local function getOfflineRateMult(profile: any): number
	local mult = 1
	local talentStats = TalentTreeConfig.ComputeStats(profile.unlockedTalents)
	mult += (talentStats.offlineRate or 0) / 100
	return mult
end

function OfflineFarmService.Collect(player: Player, profile: any)
	local now = os.time()
	local lastOnline = profile.lastOnlineAt
	if type(lastOnline) ~= "number" then
		lastOnline = now
	end

	local rawOffline = now - lastOnline
	if rawOffline <= 60 then
		profile.lastOnlineAt = now
		return
	end

	local offlineSeconds = math.min(rawOffline, MAX_OFFLINE_SECONDS)
	local offlineMinutes = math.floor(offlineSeconds / 60)
	local dps = Formulas.GetDPS(profile, player)
	local rate = BASE_OFFLINE_RATE * getOfflineRateMult(profile)
	local offlinePower = math.max(0, dps * rate * offlineSeconds)
	local coinMult = Formulas.GetCoinMult(profile)
	local offlineCoins = math.floor(offlinePower * COINS_PER_OFFLINE_POWER * coinMult)

	profile.lifetimePower = (profile.lifetimePower or 0) + offlinePower
	profile.coins = (profile.coins or 0) + offlineCoins
	profile.lastOnlineAt = now

	local hours = math.floor(offlineSeconds / 3600)
	local minutes = math.floor((offlineSeconds % 3600) / 60)
	local timeText
	if hours > 0 then
		timeText = string.format("%dh %dm", hours, minutes)
	else
		timeText = string.format("%dm", minutes)
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format(
			"Welcome back! Offline %s: +%s power, +%s coins",
			timeText,
			compact(offlinePower),
			compact(offlineCoins)
		),
		color = "cyan",
	})
end

function OfflineFarmService.Touch(player: Player)
	local profile = nil
	local ps = script.Parent:FindFirstChild("ProfileService")
	if ps then
		profile = require(ps).Get(player)
	end
	if not profile then
		return
	end
	OfflineFarmService.Collect(player, profile)
end

function OfflineFarmService.Init()
	-- heartbeat: update lastOnlineAt for online players so offline calc is fair
	task.spawn(function()
		while true do
			task.wait(60)
			local ps = script.Parent:FindFirstChild("ProfileService")
			if not ps then
				continue
			end
			local ProfileService = require(ps)
			for _, player in Players:GetPlayers() do
				local profile = ProfileService.Get(player)
				if profile then
					profile.lastOnlineAt = os.time()
				end
			end
		end
	end)
end

return OfflineFarmService