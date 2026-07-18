--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local WeaponConfig = require(Shared.Config.WeaponConfig)
local EnchantConfig = require(Shared.Config.EnchantConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local WeaponService = {}

function WeaponService.Init()
	Remotes.Event("EquipWeapon").OnServerEvent:Connect(function(player, weaponUid, slot)
		WeaponService.Equip(player, weaponUid, slot)
	end)
	Remotes.Event("SellWeapon").OnServerEvent:Connect(function(player, weaponUid)
		WeaponService.Sell(player, weaponUid)
	end)
	Remotes.Event("EnchantWeapon").OnServerEvent:Connect(function(player, weaponUid)
		WeaponService.Enchant(player, weaponUid)
	end)
	Remotes.Event("BanDrop").OnServerEvent:Connect(function(player, kind, id, banned)
		WeaponService.Ban(player, kind, id, banned)
	end)
end

local function findWeapon(profile: any, uid: string)
	for i, w in profile.weapons do
		if w.uid == uid then
			return w, i
		end
	end
	return nil, nil
end

function WeaponService.Equip(player: Player, weaponUid: string, slot: string?)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local w = findWeapon(profile, weaponUid)
	if not w then
		return
	end
	slot = slot or "main"
	if slot == "offhand" then
		if profile.equippedMain == weaponUid then
			return
		end
		profile.equippedOffhand = weaponUid
	else
		if profile.equippedOffhand == weaponUid then
			profile.equippedOffhand = nil
		end
		profile.equippedMain = weaponUid
	end
	ProfileService.Push(player)
end

function WeaponService.Sell(player: Player, weaponUid: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local w, idx = findWeapon(profile, weaponUid)
	if not w or not idx then
		return
	end
	if profile.equippedMain == weaponUid or profile.equippedOffhand == weaponUid then
		Remotes.Event("Notify"):FireClient(player, { text = "Unequip weapon first", color = "red" })
		return
	end
	if #profile.weapons <= 1 then
		return
	end
	local def = WeaponConfig.Get(w.id)
	local price = def and def.sellPrice or 5
	profile.coins += price
	table.remove(profile.weapons, idx)
	ProfileService.Push(player)
end

function WeaponService.Enchant(player: Player, weaponUid: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local w = findWeapon(profile, weaponUid)
	if not w then
		return
	end
	local dustCost = EnchantConfig.ROLL_COST_DUST or 1
	local coinCost = EnchantConfig.ROLL_COST
	local paidWith = "coins"
	if (profile.enchantDust or 0) >= dustCost then
		profile.enchantDust -= dustCost
		paidWith = "dust"
	elseif profile.coins >= coinCost then
		profile.coins -= coinCost
	else
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need enchant dust (%d) or %d coins", dustCost, coinCost),
			color = "red",
		})
		return
	end
	local roll = EnchantConfig.Roll()
	if #w.enchants >= EnchantConfig.MAX_ENCHANTS_PER_WEAPON then
		w.enchants[math.random(1, #w.enchants)] = roll
	else
		table.insert(w.enchants, roll)
	end
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format(
			"Enchant: %s %+d%% (%s) [%s]",
			roll.id,
			roll.value,
			roll.quality,
			if paidWith == "dust" then "dust" else "coins"
		),
		color = "orange",
	})
	ProfileService.Push(player)
end

function WeaponService.Ban(player: Player, kind: string, id: string, banned: boolean)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	if kind == "weapon" then
		profile.bannedWeaponIds[id] = banned and true or nil
	elseif kind == "pet" then
		profile.bannedPetIds[id] = banned and true or nil
	elseif kind == "aura" then
		profile.bannedAuraIds[id] = banned and true or nil
	end
	ProfileService.Push(player)
end

return WeaponService
