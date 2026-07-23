--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RebirthConfig = require(Shared.Config.RebirthConfig)
local NumberFormat = require(Shared.NumberFormat)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local Formulas = require(Shared.Formulas)
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

	local powerCost, coinCost = RebirthConfig.GetCosts(nextLevel)
	local currentPower = Formulas.GetTotalPower(profile, player)
	local coins = profile.coins or 0

	local ok, reason = RebirthConfig.CanAfford(currentPower, coins, nextLevel)
	if not ok then
		Remotes.Event("Notify"):FireClient(player, {
			text = reason or "Not enough resources",
			color = "red",
		})
		return false
	end

	if coinCost > 0 then
		profile.coins = coins - coinCost
	end
	if RebirthConfig.WIPE_COINS_ON_REBIRTH then
		profile.coins = 0
	end
	if RebirthConfig.WIPE_POWER_ON_REBIRTH then
		profile.lifetimePower = 0
	end

	profile.rebirthLevel = nextLevel
	profile.rebirthMult = RebirthConfig.GetMultAfter(nextLevel)
	local rankName = RebirthConfig.GetRankName(nextLevel)

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
			"Rebirth %d — %s ×%s%s",
			nextLevel,
			rankName,
			NumberFormat.Num(profile.rebirthMult),
			slotNote
		),
		color = "purple",
	})
	ProfileService.Push(player)
	return true
end

return RebirthService
