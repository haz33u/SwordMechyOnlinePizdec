--!strict
--[[
	Paid unlocks (gamepass stub):
	  - offhand      → second sword 50% power
	  - paidPetSlot  → +1 pet slot (7th)

	DEBUG_FREE_PAID in ProgressConfig: grants without R$ for playtest.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ProgressConfig = require(Shared.Config.ProgressConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)

local UnlockService = {}

local VALID = {
	offhand = true,
	paidPetSlot = true,
}

function UnlockService.Init()
	Remotes.Event("UnlockPaidFeature").OnServerEvent:Connect(function(player, featureId)
		UnlockService.Unlock(player, featureId)
	end)
end

function UnlockService.Unlock(player: Player, featureId: any): boolean
	if type(featureId) ~= "string" or not VALID[featureId] then
		return false
	end
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end

	if not ProgressConfig.DEBUG_FREE_PAID then
		-- TODO: MarketplaceService gamepass check
		Remotes.Event("Notify"):FireClient(player, {
			text = "Paid unlocks not wired to Robux yet",
			color = "red",
		})
		return false
	end

	profile.unlocks = profile.unlocks or { offhand = false, paidPetSlot = false }

	if featureId == "offhand" then
		if profile.unlocks.offhand then
			Remotes.Event("Notify"):FireClient(player, { text = "Offhand already unlocked", color = "yellow" })
			ProfileService.Push(player)
			return true
		end
		profile.unlocks.offhand = true
		Remotes.Event("Notify"):FireClient(player, {
			text = "Unlocked: Offhand (2nd sword 50% power)",
			color = "gold",
		})
	elseif featureId == "paidPetSlot" then
		if profile.unlocks.paidPetSlot then
			Remotes.Event("Notify"):FireClient(player, { text = "Paid pet slot already owned", color = "yellow" })
			ProfileService.Push(player)
			return true
		end
		profile.unlocks.paidPetSlot = true
		PetService.SyncSlots(profile)
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Unlocked: +1 pet slot (now %d)", profile.petSlots or 0),
			color = "pink",
		})
	end

	ProfileService.Push(player)
	return true
end

return UnlockService
