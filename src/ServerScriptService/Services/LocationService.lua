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

	-- first spawn → Loc1 island
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

	local power = Formulas.GetTotalPower(profile)
	if power >= loc.unlockPower then
		ProfileService.UnlockLocation(profile, locId)
	end

	if not ProfileService.IsLocationUnlocked(profile, locId) then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format(
				"[%d] %s — need power %s (have %s)",
				locId,
				loc.name,
				tostring(loc.unlockPower),
				tostring(math.floor(power))
			),
			color = "red",
		})
		return
	end

	profile.currentLocation = locId
	WorldService.TeleportToLocation(player, locId)

	-- ensure logical mobs for this location (+ debug dummy)
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
