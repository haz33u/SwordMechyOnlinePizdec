--!strict
--[[
	Relic equip / unequip / star upgrade.
	Free slots = 2; paid gamepass relicSlot = 3rd slot.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RelicConfig = require(Shared.Config.RelicConfig)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local RelicService = {}

function RelicService.Init()
	Remotes.Event("EquipRelic").OnServerEvent:Connect(function(player, uid)
		RelicService.Equip(player, uid)
	end)
	Remotes.Event("UnequipRelic").OnServerEvent:Connect(function(player, uid)
		RelicService.Unequip(player, uid)
	end)
	Remotes.Event("UpgradeRelic").OnServerEvent:Connect(function(player, uid)
		RelicService.UpgradeStars(player, uid)
	end)
end

local function findRelic(profile: any, uid: string): any?
	for _, r in profile.relics or {} do
		if r.uid == uid then
			return r
		end
	end
	return nil
end

local function isEquipped(profile: any, uid: string): boolean
	for _, e in profile.equippedRelics or {} do
		if e == uid then
			return true
		end
	end
	return false
end

function RelicService.Equip(player: Player, uid: any): boolean
	local profile = ProfileService.Get(player)
	if not profile or type(uid) ~= "string" then
		return false
	end
	profile.equippedRelics = profile.equippedRelics or {}
	if not findRelic(profile, uid) then
		return false
	end
	-- toggle off
	if isEquipped(profile, uid) then
		return RelicService.Unequip(player, uid)
	end
	local maxSlots = Formulas.GetMaxRelicSlots(profile)
	if #profile.equippedRelics >= maxSlots then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Relic slots full (%d). Buy 3rd slot in Shop or unequip one.", maxSlots),
			color = "yellow",
		})
		return false
	end
	table.insert(profile.equippedRelics, uid)
	ProfileService.Push(player)
	return true
end

function RelicService.Unequip(player: Player, uid: any): boolean
	local profile = ProfileService.Get(player)
	if not profile or type(uid) ~= "string" then
		return false
	end
	profile.equippedRelics = profile.equippedRelics or {}
	for i, e in profile.equippedRelics do
		if e == uid then
			table.remove(profile.equippedRelics, i)
			ProfileService.Push(player)
			return true
		end
	end
	return false
end

function RelicService.UpgradeStars(player: Player, uid: any): boolean
	local profile = ProfileService.Get(player)
	if not profile or type(uid) ~= "string" then
		return false
	end
	local r = findRelic(profile, uid)
	if not r then
		return false
	end
	local id = RelicConfig.ResolveId(r.id)
	local def = RelicConfig.Get(id) or RelicConfig.Get(r.id)
	if not def then
		Remotes.Event("Notify"):FireClient(player, { text = "Unknown relic", color = "red" })
		return false
	end
	local stars = r.stars or 0
	if stars >= RelicConfig.MAX_STARS then
		Remotes.Event("Notify"):FireClient(player, { text = "Relic already max stars", color = "yellow" })
		return false
	end
	local cost = RelicConfig.StarUpgradeCost(def, stars)
	if (profile.coins or 0) < cost then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need %d coins for next star", cost),
			color = "red",
		})
		return false
	end
	profile.coins -= cost
	r.stars = stars + 1
	local p, d = RelicConfig.EffectiveStats(def, r.stars)
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("%s ★%d  (P%.0f%% D%.0f%%)", def.name, r.stars, p, d),
		color = "gold",
	})
	ProfileService.Push(player)
	return true
end

function RelicService.TryAutoEquip(profile: any, ruid: string)
	profile.equippedRelics = profile.equippedRelics or {}
	local maxSlots = Formulas.GetMaxRelicSlots(profile)
	if #profile.equippedRelics < maxSlots then
		table.insert(profile.equippedRelics, ruid)
	end
end

return RelicService
