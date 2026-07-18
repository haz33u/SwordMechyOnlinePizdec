--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local GameConfig = require(Shared.Config.GameConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local PetService = {}

function PetService.Init()
	Remotes.Event("OpenPetCase").OnServerEvent:Connect(function(player)
		PetService.OpenCase(player)
	end)
	Remotes.Event("EquipPet").OnServerEvent:Connect(function(player, petUid)
		PetService.Equip(player, petUid)
	end)
	Remotes.Event("UnequipPet").OnServerEvent:Connect(function(player, petUid)
		PetService.Unequip(player, petUid)
	end)
	Remotes.Event("FeedPet").OnServerEvent:Connect(function(player, petUid)
		PetService.Feed(player, petUid)
	end)
end

local function fireCaseFail(player: Player, reason: string, needKeys: number?, needCoins: number?)
	Remotes.Event("CaseResult"):FireClient(player, {
		kind = "pet",
		success = false,
		reason = reason,
		needKeys = needKeys,
		needCoins = needCoins,
	})
end

function PetService.OpenCase(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local keyCost = CaseConfig.PET_KEY_COST or 1
	local coinCost = CaseConfig.PET_COIN_COST or PetConfig.OPEN_COST or 0
	local keys = profile.petKeys or 0
	local coins = profile.coins or 0

	if keys < keyCost then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need %d pet key(s) (have %d)", keyCost, keys),
			color = "red",
		})
		fireCaseFail(player, "need_keys", keyCost, coinCost)
		return
	end
	if coinCost > 0 and coins < coinCost then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Need " .. tostring(coinCost) .. " coins",
			color = "red",
		})
		fireCaseFail(player, "need_coins", keyCost, coinCost)
		return
	end

	profile.petKeys = keys - keyCost
	if coinCost > 0 then
		profile.coins = coins - coinCost
	end

	local loc = profile.currentLocation or 1
	local petId = PetConfig.RollForLocation(loc)
	for _ = 1, 5 do
		if not profile.bannedPetIds[petId] then
			break
		end
		petId = PetConfig.RollForLocation(loc)
	end

	local puid = ProfileService.NewUid()
	table.insert(profile.pets, {
		uid = puid,
		id = petId,
		level = 1,
		enchants = {},
	})

	local def = PetConfig.Get(petId)
	local name = def and def.name or petId
	local rarity = def and def.rarity or "Common"
	local powerPct = def and def.powerPct or 0
	local coinPct = def and def.coinPct or 0

	Remotes.Event("CaseResult"):FireClient(player, {
		kind = "pet",
		success = true,
		id = petId,
		uid = puid,
		name = name,
		rarity = rarity,
		powerPct = powerPct,
		coinPct = coinPct,
		keysLeft = profile.petKeys,
		location = loc,
	})

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Pet: %s [%s]  (keys left: %d)", name, rarity, profile.petKeys or 0),
		color = "pink",
	})

	-- auto equip if slot free
	if #profile.petTeam < profile.petSlots then
		table.insert(profile.petTeam, puid)
	end
	ProfileService.Push(player)
end

function PetService.Equip(player: Player, petUid: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	for _, uid in profile.petTeam do
		if uid == petUid then
			return
		end
	end
	if #profile.petTeam >= profile.petSlots then
		Remotes.Event("Notify"):FireClient(player, { text = "No pet slots", color = "red" })
		return
	end
	local found = false
	for _, p in profile.pets do
		if p.uid == petUid then
			found = true
			break
		end
	end
	if not found then
		return
	end
	table.insert(profile.petTeam, petUid)
	ProfileService.Push(player)
end

function PetService.Unequip(player: Player, petUid: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	for i, uid in profile.petTeam do
		if uid == petUid then
			table.remove(profile.petTeam, i)
			break
		end
	end
	ProfileService.Push(player)
end

function PetService.Feed(player: Player, petUid: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	for _, pet in profile.pets do
		if pet.uid == petUid then
			if pet.level >= PetConfig.MAX_LEVEL then
				return
			end
			local cost = math.floor(PetConfig.FEED_BASE_COST * (PetConfig.FEED_GROWTH ^ (pet.level - 1)))
			if profile.coins < cost then
				Remotes.Event("Notify"):FireClient(player, { text = "Not enough coins (" .. cost .. ")", color = "red" })
				return
			end
			profile.coins -= cost
			pet.level += 1
			ProfileService.Push(player)
			return
		end
	end
end

--- Recalculate petSlots from rebirth / dungeon / paid (source of truth).
--- Returns true if slots increased.
function PetService.SyncSlots(profile: any): boolean
	local before = profile.petSlots or ProgressConfig.START_PET_SLOTS
	local after = ProgressConfig.ComputePetSlots(profile)
	profile.petSlots = after

	-- trim team if over capacity
	while #profile.petTeam > after do
		table.remove(profile.petTeam)
	end

	return after > before
end

-- legacy: prefer SyncSlots; still clamps if something external adds
function PetService.GrantSlot(profile: any, amount: number?)
	amount = amount or 1
	-- do not permanently inflate beyond formula — re-sync from progress
	PetService.SyncSlots(profile)
	-- if caller expected a grant outside formula, only paid path should set unlocks
	if amount > 0 then
		-- no-op for free grants; use ProgressConfig + unlocks.paidPetSlot
	end
	return profile.petSlots
end

function PetService.GrantKeys(profile: any, amount: number)
	if amount <= 0 then
		return
	end
	profile.petKeys = (profile.petKeys or 0) + amount
end

return PetService
