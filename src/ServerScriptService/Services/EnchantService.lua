--!strict
--[[
	Server-side weapon enchant management.

	Remotes:
	  RollEnchant       → returns a roll preview (does not apply yet)
	  ApplyEnchant      → adds rolled enchant to weapon if dust paid
	  TransferEnchant   → moves one enchant between weapons with success chance
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local EnchantConfig = require(Shared.Config.EnchantConfig)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)

local EnchantService = {}

local function findWeapon(profile: any, uid: string): (any?, number?)
	for i, w in profile.weapons or {} do
		if w.uid == uid then
			return w, i
		end
	end
	return nil, nil
end

local function countEnchants(weapon: any): number
	return #(weapon.enchants or {})
end

function EnchantService.Init()
	Remotes.Event("RollEnchant").OnServerEvent:Connect(function(player, weaponUid)
		EnchantService.RollPreview(player, weaponUid)
	end)

	Remotes.Event("ApplyEnchant").OnServerEvent:Connect(function(player, weaponUid)
		EnchantService.ApplyRolledEnchant(player, weaponUid)
	end)

	Remotes.Event("TransferEnchant").OnServerEvent:Connect(function(player, fromUid, toUid, enchantIndex)
		EnchantService.Transfer(player, fromUid, toUid, enchantIndex)
	end)
end

function EnchantService.RollPreview(player: Player, weaponUid: string)
	local profile = ProfileService.Get(player)
	local weapon = profile and findWeapon(profile, weaponUid)
	if not weapon then
		Remotes.Event("Notify"):FireClient(player, { text = "Weapon not found", color = "red" })
		return
	end
	if countEnchants(weapon) >= EnchantConfig.MAX_ENCHANTS_PER_WEAPON then
		Remotes.Event("Notify"):FireClient(player, { text = "Weapon enchant slots full", color = "red" })
		return
	end

	local rerolls = weapon.enchantRerolls or 0
	local cost = EnchantConfig.GetRollDustCost(rerolls)
	local roll = EnchantConfig.Roll()

	weapon._pendingEnchant = roll
	Remotes.Event("EnchantRollPreview"):FireClient(player, {
		weaponUid = weaponUid,
		enchant = roll,
		dustCost = cost,
		hasDust = (profile.enchantDust or 0) >= cost,
	})
end

function EnchantService.ApplyRolledEnchant(player: Player, weaponUid: string)
	local profile = ProfileService.Get(player)
	local weapon = profile and findWeapon(profile, weaponUid)
	if not weapon or not weapon._pendingEnchant then
		Remotes.Event("Notify"):FireClient(player, { text = "No pending enchant", color = "red" })
		return
	end
	if countEnchants(weapon) >= EnchantConfig.MAX_ENCHANTS_PER_WEAPON then
		Remotes.Event("Notify"):FireClient(player, { text = "Weapon enchant slots full", color = "red" })
		return
	end

	local rerolls = weapon.enchantRerolls or 0
	local cost = EnchantConfig.GetRollDustCost(rerolls)
	if (profile.enchantDust or 0) < cost then
		Remotes.Event("Notify"):FireClient(player, { text = string.format("Need %d enchant dust", cost), color = "red" })
		return
	end

	profile.enchantDust -= cost
	weapon.enchantRerolls = rerolls + 1
	if not weapon.enchants then
		weapon.enchants = {}
	end

	local roll = weapon._pendingEnchant
	weapon._pendingEnchant = nil

	-- Stack same-family enchants
	local def = EnchantConfig.Get(roll.id)
	local stacked = false
	for _, e in weapon.enchants do
		if e.family == roll.family then
			e.value += roll.value
			stacked = true
			break
		end
	end
	if not stacked then
		table.insert(weapon.enchants, {
			id = roll.id,
			family = roll.family,
			value = roll.value,
		})
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Enchanted: %s +%d%%", def and def.name or roll.id, roll.value),
		color = "purple",
	})
	ProfileService.Push(player)
end

function EnchantService.Transfer(player: Player, fromUid: string, toUid: string, enchantIndex: number)
	local profile = ProfileService.Get(player)
	local fromW = profile and findWeapon(profile, fromUid)
	local toW = profile and findWeapon(profile, toUid)
	if not fromW or not toW then
		Remotes.Event("Notify"):FireClient(player, { text = "Weapon not found", color = "red" })
		return
	end
	local enchants = fromW.enchants or {}
	local src = enchants[enchantIndex]
	if not src then
		Remotes.Event("Notify"):FireClient(player, { text = "Enchant slot empty", color = "red" })
		return
	end
	if countEnchants(toW) >= EnchantConfig.MAX_ENCHANTS_PER_WEAPON then
		Remotes.Event("Notify"):FireClient(player, { text = "Target weapon full", color = "red" })
		return
	end
	if (profile.enchantDust or 0) < EnchantConfig.TRANSFER_DUST then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need %d dust to transfer", EnchantConfig.TRANSFER_DUST),
			color = "red",
		})
		return
	end

	profile.enchantDust -= EnchantConfig.TRANSFER_DUST
	if math.random() > EnchantConfig.TRANSFER_SUCCESS then
		Remotes.Event("Notify"):FireClient(player, { text = "Transfer failed! Dust consumed.", color = "red" })
		ProfileService.Push(player)
		return
	end

	table.remove(fromW.enchants, enchantIndex)
	if not toW.enchants then
		toW.enchants = {}
	end
	table.insert(toW.enchants, {
		id = src.id,
		family = src.family,
		value = src.value,
	})

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Transferred %s enchant", src.id),
		color = "purple",
	})
	ProfileService.Push(player)
end

return EnchantService