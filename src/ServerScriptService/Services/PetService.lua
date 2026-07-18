--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
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

function PetService.OpenCase(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	if profile.coins < PetConfig.OPEN_COST then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Нужно " .. tostring(PetConfig.OPEN_COST) .. " монет",
			color = "red",
		})
		return
	end
	profile.coins -= PetConfig.OPEN_COST

	local loc = profile.currentLocation or 1
	local petId = PetConfig.RollForLocation(loc)
	-- respect ban: reroll up to 5 times
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
	Remotes.Event("Notify"):FireClient(player, {
		text = "Питомец: " .. (def and def.name or petId) .. " [" .. (def and def.rarity or "?") .. "]",
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
		Remotes.Event("Notify"):FireClient(player, { text = "Нет слотов петов", color = "red" })
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
				Remotes.Event("Notify"):FireClient(player, { text = "Мало монет (" .. cost .. ")", color = "red" })
				return
			end
			profile.coins -= cost
			pet.level += 1
			ProfileService.Push(player)
			return
		end
	end
end

function PetService.GrantSlot(profile: any, amount: number?)
	amount = amount or 1
	profile.petSlots = math.min(GameConfig.MAX_PET_SLOTS, profile.petSlots + amount)
end

return PetService
