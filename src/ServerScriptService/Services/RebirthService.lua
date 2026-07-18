--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RebirthConfig = require(Shared.Config.RebirthConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local QuestService = require(script.Parent.QuestService)
local PetService = require(script.Parent.PetService)

local RebirthService = {}

function RebirthService.Init()
	Remotes.Event("RequestRebirth").OnServerEvent:Connect(function(player)
		RebirthService.Try(player)
	end)
end

function RebirthService.Try(player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end

	local nextLevel = (profile.rebirthLevel or 0) + 1
	if nextLevel > RebirthConfig.MAX_LEVEL then
		Remotes.Event("Notify"):FireClient(player, { text = "Max rebirth", color = "red" })
		return false
	end

	local dmgCost, coinCost = RebirthConfig.GetCosts(nextLevel)
	local dmg = profile.lifetimeDamage or 0
	local coins = profile.coins or 0

	local ok, reason = RebirthConfig.CanAfford(dmg, coins, nextLevel)
	if not ok then
		Remotes.Event("Notify"):FireClient(player, {
			text = reason or "Not enough resources",
			color = "red",
		})
		return false
	end

	-- spend coins (damage is lifetime metric — not spent, only threshold)
	profile.coins = coins - coinCost
	profile.rebirthLevel = nextLevel
	local bonus = RebirthConfig.GetBonus(nextLevel)
	profile.rebirthMult = (profile.rebirthMult or 1) * (1 + bonus)

	-- soft: do NOT wipe weapons/pets/locations
	QuestService.OnRebirth(profile)

	local slotsGrew = PetService.SyncSlots(profile)
	local slotNote = ""
	if slotsGrew then
		slotNote = string.format("  · pet slots %d", profile.petSlots or 0)
	else
		local hint = ProgressConfig.GetNextPetSlotHint(profile)
		if hint and string.find(hint, "rebirth") then
			slotNote = "  · " .. hint
		end
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format(
			"Rebirth %d! Mult x%.2f (+%.0f%%)  −%s coins%s",
			nextLevel,
			profile.rebirthMult,
			bonus * 100,
			tostring(coinCost),
			slotNote
		),
		color = "purple",
	})
	ProfileService.Push(player)
	return true
end

return RebirthService
