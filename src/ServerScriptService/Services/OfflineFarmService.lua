--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local OfflineFarmService = {}

local MIN_OFFLINE_SECONDS = 60
local MAX_OFFLINE_SECONDS = 28800 -- 8 hours max AFK cap

function OfflineFarmService.Init()
	Players.PlayerAdded:Connect(function(player)
		task.wait(1.5) -- wait for profile load
		OfflineFarmService.CheckOfflineEarnings(player)
	end)
end

function OfflineFarmService.CheckOfflineEarnings(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local now = os.time()
	local lastSave = profile.lastSaveTime or now
	profile.lastSaveTime = now

	local elapsed = now - lastSave
	if elapsed < MIN_OFFLINE_SECONDS then
		return
	end

	local afkSeconds = math.min(elapsed, MAX_OFFLINE_SECONDS)
	local hrs = math.floor(afkSeconds / 3600)
	local mins = math.floor((afkSeconds % 3600) / 60)

	local timeStr = if hrs > 0 then string.format("%dh %dm", hrs, mins) else string.format("%dm", mins)

	-- Calculate offline farm rate (20% of online farm output)
	local power = Formulas.GetTotalPower(profile, player)
	local coinMult = Formulas.GetCoinMult(profile)
	local cps = Formulas.GetCPS(profile)

	local earnedCoins = math.floor(afkSeconds * 0.15 * cps * coinMult)
	local earnedPower = math.floor(afkSeconds * 0.05 * (power / 100))

	if earnedCoins > 0 then
		profile.coins = (profile.coins or 0) + earnedCoins
	end
	if earnedPower > 0 then
		profile.lifetimePower = (profile.lifetimePower or 0) + earnedPower
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Welcome back! AFK Earnings (%s): +%d coins, +%d power", timeStr, earnedCoins, earnedPower),
		color = "gold",
	})

	ProfileService.Push(player)
end

return OfflineFarmService
