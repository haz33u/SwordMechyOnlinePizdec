--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local PetService = {}

function PetService.Init()
	Remotes.Event("OpenPetCase").OnServerEvent:Connect(function(player, poolId, count)
		PetService.OpenCase(player, poolId, count)
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
	Remotes.Event("SellPet").OnServerEvent:Connect(function(player, petUid)
		PetService.Sell(player, petUid)
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

local function findPet(profile: any, petUid: string): any?
	if type(petUid) ~= "string" then
		return nil
	end
	for _, pet in profile.pets or {} do
		if pet.uid == petUid then
			return pet
		end
	end
	return nil
end

local function removeFromTeam(profile: any, petUid: string)
	for i, uid in profile.petTeam or {} do
		if uid == petUid then
			table.remove(profile.petTeam, i)
			return
		end
	end
end

function PetService.OpenCase(player: Player, poolIdArg: any?, countArg: any?)
	local count = math.clamp(math.floor(tonumber(countArg) or 1), 1, 5)
	if count ~= 1 and count ~= 3 and count ~= 5 then
		count = 1
	end

	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	if count == 3 then
		local ok3 = (profile.unlocks and profile.unlocks.openChest3 == true) or ProgressConfig.DEBUG_FREE_PAID
		if not ok3 then
			Remotes.Event("Notify"):FireClient(player, { text = "Unlock Open 3x GamePass first", color = "red" })
			fireCaseFail(player, "gamepass_required")
			return
		end
	elseif count == 5 then
		local ok5 = (profile.unlocks and profile.unlocks.openChest5 == true) or ProgressConfig.DEBUG_FREE_PAID
		if not ok5 then
			Remotes.Event("Notify"):FireClient(player, { text = "Unlock Open 5x GamePass first", color = "red" })
			fireCaseFail(player, "gamepass_required")
			return
		end
	end

	local loc = profile.currentLocation or 1
	local poolId = PetConfig.GetDefaultPoolId(loc)
	if type(poolIdArg) == "string" and PetConfig.IsValidPool(poolIdArg) then
		local meta = PetConfig.CasePools[poolIdArg]
		if meta and (meta.location or 1) <= math.max(loc, 1) then
			poolId = poolIdArg
		end
	end

	local singleCoinCost, singleKeyCost = PetConfig.GetCaseCosts(poolId)
	if singleCoinCost == 0 and singleKeyCost == 0 then
		singleKeyCost = CaseConfig.PET_KEY_COST or 0
		singleCoinCost = CaseConfig.PET_COIN_COST or PetConfig.OPEN_COST or 0
	end

	local keyCost = singleKeyCost * count
	local coinCost = singleCoinCost * count

	local keys = profile.petKeys or 0
	local coins = profile.coins or 0

	local needKeys = keyCost > 0 and keys < keyCost
	local needCoins = coinCost > 0 and coins < coinCost

	if needKeys then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need %d pet key(s) (have %d)", keyCost, keys),
			color = "red",
		})
		fireCaseFail(player, "need_keys", keyCost, coinCost)
		return
	end
	if needCoins then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Need " .. tostring(coinCost) .. " coins for pet case",
			color = "red",
		})
		fireCaseFail(player, "need_coins", keyCost, coinCost)
		return
	end

	local Formulas = require(Shared.Formulas)
	local maxOwned = Formulas.GetPetBagCap(profile)
	if #(profile.pets or {}) + count > maxOwned then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Pet bag full (need %d slots) — upgrade Backpack", count),
			color = "red",
		})
		fireCaseFail(player, "bag_full", keyCost, coinCost)
		return
	end

	if keyCost > 0 then
		profile.petKeys = keys - keyCost
	end
	if coinCost > 0 then
		profile.coins = coins - coinCost
	end

	local rolledItems = {}
	profile.pets = profile.pets or {}

	for _ = 1, count do
		local petId = PetConfig.RollFromPool(poolId)
		for _b = 1, 5 do
			if not (profile.bannedPetIds and profile.bannedPetIds[petId]) then
				break
			end
			petId = PetConfig.RollFromPool(poolId)
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
		local powerMult = if def then PetConfig.GetPowerMult(def) else 1
		local powerPct = (powerMult - 1) * 100

		table.insert(rolledItems, {
			id = petId,
			uid = puid,
			name = name,
			rarity = rarity,
			powerMult = powerMult,
			powerPct = powerPct,
			coinPct = 0,
		})
	end

	local QuestService = require(script.Parent.QuestService)
	QuestService.OnEvent(player, "case_open", count)
	ProfileService.Push(player)

	local first = rolledItems[1]
	Remotes.Event("CaseResult"):FireClient(player, {
		kind = "pet",
		success = true,
		count = count,
		items = rolledItems,
		id = first.id,
		uid = first.uid,
		name = first.name,
		rarity = first.rarity,
		powerMult = first.powerMult,
		powerPct = first.powerPct,
		coinPct = 0,
		keysLeft = profile.petKeys,
		location = loc,
		casePool = poolId,
	})
	profile.petTeam = profile.petTeam or {}
	PetService.SyncSlots(profile)
	if #profile.petTeam < (profile.petSlots or 3) and first then
		table.insert(profile.petTeam, first.uid)
	end
	ProfileService.Push(player)
end

function PetService.Equip(player: Player, petUid: any)
	local profile = ProfileService.Get(player)
	if not profile or type(petUid) ~= "string" then
		return
	end
	profile.petTeam = profile.petTeam or {}
	PetService.SyncSlots(profile)

	for _, uid in profile.petTeam do
		if uid == petUid then
			return
		end
	end
	if #profile.petTeam >= (profile.petSlots or 3) then
		Remotes.Event("Notify"):FireClient(player, { text = "No pet slots", color = "red" })
		return
	end
	if not findPet(profile, petUid) then
		return
	end
	table.insert(profile.petTeam, petUid)
	ProfileService.Push(player)
end

function PetService.Unequip(player: Player, petUid: any)
	local profile = ProfileService.Get(player)
	if not profile or type(petUid) ~= "string" then
		return
	end
	removeFromTeam(profile, petUid)
	ProfileService.Push(player)
end

function PetService.Feed(player: Player, petUid: any)
	local profile = ProfileService.Get(player)
	if not profile or type(petUid) ~= "string" then
		return
	end
	local pet = findPet(profile, petUid)
	if not pet then
		return
	end
	if (pet.level or 1) >= PetConfig.MAX_LEVEL then
		Remotes.Event("Notify"):FireClient(player, { text = "Pet max level", color = "yellow" })
		return
	end
	local lv = pet.level or 1
	local cost = math.floor(PetConfig.FEED_BASE_COST * (PetConfig.FEED_GROWTH ^ (lv - 1)))
	if (profile.coins or 0) < cost then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Not enough coins (" .. tostring(cost) .. ")",
			color = "red",
		})
		return
	end
	profile.coins -= cost
	pet.level = lv + 1
	local def = PetConfig.Get(pet.id)
	local name = def and def.name or pet.id
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Fed %s → Lv %d (−%d coins)", name, pet.level, cost),
		color = "green",
	})
	ProfileService.Push(player)
end

function PetService.Sell(player: Player, petUid: any)
	local profile = ProfileService.Get(player)
	if not profile or type(petUid) ~= "string" then
		return
	end
	local idx: number? = nil
	local pet: any = nil
	for i, p in profile.pets or {} do
		if p.uid == petUid then
			idx = i
			pet = p
			break
		end
	end
	if not idx or not pet then
		return
	end
	removeFromTeam(profile, petUid)
	local price = PetConfig.GetSellPrice(pet.id)
	table.remove(profile.pets, idx)
	profile.coins = (profile.coins or 0) + price
	local def = PetConfig.Get(pet.id)
	local name = def and def.name or pet.id
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Sold %s for %d coins", name, price),
		color = "gold",
	})
	ProfileService.Push(player)
end

--- Recalculate petSlots from rebirth / dungeon / paid.
function PetService.SyncSlots(profile: any): boolean
	local before = profile.petSlots or ProgressConfig.START_PET_SLOTS
	local after = ProgressConfig.ComputePetSlots(profile)
	profile.petSlots = after
	profile.petTeam = profile.petTeam or {}
	while #profile.petTeam > after do
		table.remove(profile.petTeam)
	end
	return after > before
end

function PetService.GrantSlot(profile: any, _amount: number?)
	PetService.SyncSlots(profile)
	return profile.petSlots
end

function PetService.GrantKeys(profile: any, amount: number)
	if amount <= 0 then
		return
	end
	profile.petKeys = (profile.petKeys or 0) + amount
end

--- DEV / loot helper: grant pet by id, auto-team if slot free.
function PetService.GrantPet(player: Player, profile: any, petId: string): string?
	if not PetConfig.Get(petId) then
		return nil
	end
	local Formulas = require(Shared.Formulas)
	local maxOwned = Formulas.GetPetBagCap(profile)
	profile.pets = profile.pets or {}
	if #profile.pets >= maxOwned then
		return nil
	end
	local puid = ProfileService.NewUid()
	table.insert(profile.pets, {
		uid = puid,
		id = petId,
		level = 1,
		enchants = {},
	})
	PetService.SyncSlots(profile)
	profile.petTeam = profile.petTeam or {}
	if #profile.petTeam < (profile.petSlots or 3) then
		table.insert(profile.petTeam, puid)
	end
	return puid
end

return PetService
