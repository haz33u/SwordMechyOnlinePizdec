--!strict

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LocationConfig = require(Shared.Config.LocationConfig)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local WorldService = require(script.Parent.WorldService)

local LocationService = {}

function LocationService.Init()
	Remotes.Event("SetLocation").OnServerEvent:Connect(function(player, locId)
		LocationService.Set(player, locId)
	end)
end

function LocationService.Set(player: Player, locId: number)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local loc = LocationConfig.Get(locId)
	if not loc then
		return
	end

	local unlocked = ProfileService.IsLocationUnlocked(profile, locId)
	local travelCost = loc.travelCostCoins or 0
	local needRebirth = loc.unlockRebirth or 0
	local rb = profile.rebirthLevel or 0
	local NumberFormat = require(Shared.NumberFormat)

	-- First-time unlock: rebirth gate + one-time coin cost
	if not unlocked then
		if needRebirth > 0 and rb < needRebirth then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format(
					"%s locked — need Rebirth %d (you are R%d)",
					loc.name,
					needRebirth,
					rb
				),
				color = "red",
			})
			return
		end

		local canBuy = travelCost <= 0 or (profile.coins or 0) >= travelCost
		if not canBuy then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format(
					"%s locked — need %s coins (have %s)",
					loc.name,
					NumberFormat.Num(travelCost),
					NumberFormat.Num(profile.coins or 0)
				),
				color = "red",
			})
			return
		end

		if travelCost > 0 then
			profile.coins -= travelCost
		end
		ProfileService.UnlockLocation(profile, locId)
		if travelCost > 0 then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("Unlocked %s for %s coins", loc.name, NumberFormat.Num(travelCost)),
				color = "gold",
			})
		end
	end

	if not ProfileService.IsLocationUnlocked(profile, locId) then
		return
	end

	profile.currentLocation = locId
	local teleported = WorldService.TeleportToLocation(player, locId)
	if not teleported then
		Remotes.Event("Notify"):FireClient(player, {
			text = "No PlayerSpawn on map for this location (Studio)",
			color = "yellow",
		})
	end

	local CombatService = require(script.Parent.CombatService)
	CombatService.SpawnLocationMobs(locId)
	Remotes.Event("MobsUpdate"):FireClient(player, CombatService.GetMobsForClient(locId))

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Location %d: %s", locId, loc.name),
		color = "cyan",
	})
	ProfileService.Push(player)
end

return LocationService
