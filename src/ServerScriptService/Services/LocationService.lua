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

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.4)
			local profile = ProfileService.Get(player)
			local locId = (profile and profile.currentLocation) or 1
			WorldService.TeleportToLocation(player, locId)
		end)
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

	local power = Formulas.GetTotalPower(profile, player)
	local unlocked = ProfileService.IsLocationUnlocked(profile, locId)
	local travelCost = loc.travelCostCoins or 0
	local needRebirth = loc.unlockRebirth or 0
	local rb = profile.rebirthLevel or 0

	-- First-time unlock: rebirth gate (Loc2 = R2) + coins (500K) and/or power
	if not unlocked then
		if needRebirth > 0 and rb < needRebirth then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format(
					"%s — need rebirth %d (you are R%d)",
					loc.name,
					needRebirth,
					rb
				),
				color = "red",
			})
			return
		end

		local unlockPower = loc.unlockPower or 0
		local canPower = unlockPower <= 0 or power >= unlockPower
		local canBuy = travelCost <= 0 or (profile.coins or 0) >= travelCost

		if travelCost > 0 then
			if not canBuy then
				Remotes.Event("Notify"):FireClient(player, {
					text = string.format(
						"%s — buy for %s coins (have %s)%s",
						loc.name,
						tostring(travelCost),
						tostring(math.floor(profile.coins or 0)),
						if needRebirth > 0 then string.format(" · need R%d", needRebirth) else ""
					),
					color = "red",
				})
				return
			end
			profile.coins -= travelCost
			ProfileService.UnlockLocation(profile, locId)
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("Unlocked %s (−%s coins)", loc.name, tostring(travelCost)),
				color = "gold",
			})
		elseif canPower then
			ProfileService.UnlockLocation(profile, locId)
		else
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format(
					"[%d] %s — need power %s (have %s)",
					locId,
					loc.name,
					tostring(unlockPower),
					tostring(math.floor(power))
				),
				color = "red",
			})
			return
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
