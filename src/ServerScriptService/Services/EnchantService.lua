--!strict
--[[
	Server-side weapon enchant management.

	Remotes:
	  RollEnchant       → returns a roll preview (does not apply yet)
	  ApplyEnchant      → adds rolled enchant to weapon if dust paid
	  TransferEnchant   → moves one enchant between weapons with success chance
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local EnchantConfig = require(Shared.Config.EnchantConfig)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)

local EnchantService = {}

--[[
	Pending rolls live in server memory, NOT on the profile.

	Putting them on profile.weapons[i] would persist transient state into the
	DataStore (ProfileService.Save writes the whole profile), so a roll previewed
	and never applied would survive rejoins forever.

	Keyed by userId → weaponUid → EnchantRoll. Cleared on leave.
]]
local _pending: { [number]: { [string]: any } } = {}

local function getPending(player: Player, weaponUid: string): any?
	local byWeapon = _pending[player.UserId]
	return byWeapon and byWeapon[weaponUid]
end

local function setPending(player: Player, weaponUid: string, roll: any?)
	local byWeapon = _pending[player.UserId]
	if not byWeapon then
		if roll == nil then
			return
		end
		byWeapon = {}
		_pending[player.UserId] = byWeapon
	end
	byWeapon[weaponUid] = roll
end

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

	Players.PlayerRemoving:Connect(function(player)
		_pending[player.UserId] = nil
	end)
end

--[[
	Roll a new enchant. Dust is charged HERE, per roll — that is what makes
	rerolling expensive. Previously dust was only taken on apply, so a client
	could spam RollEnchant for free until a good roll appeared and pay once.

	Applying an already-paid-for roll is free (see ApplyRolledEnchant).
]]
function EnchantService.RollPreview(player: Player, weaponUid: string)
	if type(weaponUid) ~= "string" then
		return
	end
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
	local dust = profile.enchantDust or 0
	if dust < cost then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need %d enchant dust to roll (have %d)", cost, dust),
			color = "red",
		})
		return
	end

	profile.enchantDust = dust - cost
	weapon.enchantRerolls = rerolls + 1

	local roll = EnchantConfig.Roll()
	setPending(player, weaponUid, roll)

	Remotes.Event("EnchantRollPreview"):FireClient(player, {
		weaponUid = weaponUid,
		enchant = roll,
		dustCost = cost,
		nextDustCost = EnchantConfig.GetRollDustCost(rerolls + 1),
		hasDust = true,
	})
	ProfileService.Push(player)
end

function EnchantService.ApplyRolledEnchant(player: Player, weaponUid: string)
	if type(weaponUid) ~= "string" then
		return
	end
	local profile = ProfileService.Get(player)
	local weapon = profile and findWeapon(profile, weaponUid)
	local roll = getPending(player, weaponUid)
	if not weapon or not roll then
		Remotes.Event("Notify"):FireClient(player, { text = "No pending enchant", color = "red" })
		return
	end
	if countEnchants(weapon) >= EnchantConfig.MAX_ENCHANTS_PER_WEAPON then
		Remotes.Event("Notify"):FireClient(player, { text = "Weapon enchant slots full", color = "red" })
		return
	end

	-- Dust was already charged by RollPreview; applying is free.
	setPending(player, weaponUid, nil)
	if not weapon.enchants then
		weapon.enchants = {}
	end

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
	if type(fromUid) ~= "string" or type(toUid) ~= "string" or type(enchantIndex) ~= "number" then
		return
	end
	if fromUid == toUid then
		Remotes.Event("Notify"):FireClient(player, { text = "Pick a different target weapon", color = "red" })
		return
	end
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
	local dust = profile.enchantDust or 0
	if dust < EnchantConfig.TRANSFER_DUST then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need %d dust to transfer", EnchantConfig.TRANSFER_DUST),
			color = "red",
		})
		return
	end

	profile.enchantDust = dust - EnchantConfig.TRANSFER_DUST
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