--!strict
--[[
	Paid unlocks via Roblox gamepasses (GamePassConfig).
	On join + after purchase: sync ownership → profile.unlocks.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ProgressConfig = require(Shared.Config.ProgressConfig)
local GamePassConfig = require(Shared.Config.GamePassConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)

local UnlockService = {}

local VALID_FEATURES = {
	offhand = true,
	paidPetSlot = true,
	relicSlot = true,
	autoClicker = true,
	teleporter = true,
	openChest3 = true,
	openChest5 = true,
}

local function ensureUnlocks(profile: any)
	profile.unlocks = profile.unlocks or {}
	local u = profile.unlocks
	if u.offhand == nil then
		u.offhand = false
	end
	if u.paidPetSlot == nil then
		u.paidPetSlot = false
	end
	if u.relicSlot == nil then
		u.relicSlot = false
	end
	if u.autoClicker == nil then
		u.autoClicker = false
	end
	if u.teleporter == nil then
		u.teleporter = false
	end
	if u.openChest3 == nil then
		u.openChest3 = false
	end
	if u.openChest5 == nil then
		u.openChest5 = false
	end
end

local function applyFeature(profile: any, feature: string): boolean
	ensureUnlocks(profile)
	if feature == "offhand" then
		if profile.unlocks.offhand then
			return false
		end
		profile.unlocks.offhand = true
		return true
	elseif feature == "paidPetSlot" then
		if profile.unlocks.paidPetSlot then
			return false
		end
		profile.unlocks.paidPetSlot = true
		PetService.SyncSlots(profile)
		return true
	elseif feature == "relicSlot" then
		if profile.unlocks.relicSlot then
			return false
		end
		profile.unlocks.relicSlot = true
		return true
	elseif feature == "autoClicker" then
		if profile.unlocks.autoClicker and profile.purchasedAutoClicker then
			return false
		end
		profile.unlocks.autoClicker = true
		-- ClickConfig.IsAutoPurchased checks purchasedAutoClicker first
		profile.purchasedAutoClicker = true
		profile.autoClickerUnlocked = true
		-- turn ON after purchase so player feels the pass immediately
		profile.autoClicker = true
		return true
	elseif feature == "teleporter" then
		if profile.unlocks.teleporter then
			return false
		end
		profile.unlocks.teleporter = true
		return true
	elseif feature == "openChest3" then
		if profile.unlocks.openChest3 then
			return false
		end
		profile.unlocks.openChest3 = true
		return true
	elseif feature == "openChest5" then
		if profile.unlocks.openChest5 then
			return false
		end
		profile.unlocks.openChest5 = true
		return true
	end
	return false
end

function UnlockService.SyncPlayerPasses(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	ensureUnlocks(profile)
	local changed = false

	if ProgressConfig.DEBUG_FREE_PAID then
		-- playtest: do not auto-grant all; only ownership path when DEBUG false
	end

	for _, def in GamePassConfig.Passes do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.gamePassId)
		end)
		if ok and owns and def.feature then
			if applyFeature(profile, def.feature) then
				changed = true
			end
		end
	end

	if changed then
		ProfileService.Push(player)
	end
end

function UnlockService.Init()
	Remotes.Event("UnlockPaidFeature").OnServerEvent:Connect(function(player, featureId)
		UnlockService.Unlock(player, featureId)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end
		local def = GamePassConfig.ByPassId(gamePassId)
		if not def or not def.feature then
			return
		end
		local profile = ProfileService.Get(player)
		if not profile then
			return
		end
		if applyFeature(profile, def.feature) then
			Remotes.Event("Notify"):FireClient(player, {
				text = "Purchased: " .. def.title,
				color = "gold",
			})
			ProfileService.Push(player)
		else
			UnlockService.SyncPlayerPasses(player)
			Remotes.Event("Notify"):FireClient(player, {
				text = "Already owned: " .. def.title,
				color = "green",
			})
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			task.wait(1)
			UnlockService.SyncPlayerPasses(player)
		end)
	end)
	for _, p in Players:GetPlayers() do
		task.defer(function()
			UnlockService.SyncPlayerPasses(p)
		end)
	end
end

--- Legacy stub unlock (DEBUG_FREE_PAID or already owned)
function UnlockService.Unlock(player: Player, featureId: any): boolean
	if type(featureId) ~= "string" or not VALID_FEATURES[featureId] then
		return false
	end
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end
	ensureUnlocks(profile)

	-- Prefer real ownership when pass exists
	local passDef = GamePassConfig.Get(featureId)
	if passDef then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passDef.gamePassId)
		end)
		if ok and owns then
			applyFeature(profile, featureId)
			ProfileService.Push(player)
			return true
		end
	end

	if not ProgressConfig.DEBUG_FREE_PAID then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Buy this in the Donate Shop (gamepass)",
			color = "red",
		})
		return false
	end

	if applyFeature(profile, featureId) then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Unlocked (debug free): " .. featureId,
			color = "gold",
		})
		ProfileService.Push(player)
		return true
	end
	Remotes.Event("Notify"):FireClient(player, { text = "Already unlocked", color = "yellow" })
	ProfileService.Push(player)
	return true
end

return UnlockService
