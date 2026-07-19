--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local WeaponConfig = require(Shared.Config.WeaponConfig)
local EnchantConfig = require(Shared.Config.EnchantConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
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
	Remotes.Event("SellAllWeapons").OnServerEvent:Connect(function(player)
		WeaponService.SellAll(player)
	end)
	Remotes.Event("EnchantWeapon").OnServerEvent:Connect(function(player, weaponUid)
		WeaponService.Enchant(player, weaponUid)
	end)
	Remotes.Event("BanDrop").OnServerEvent:Connect(function(player, kind, id, banned)
		WeaponService.Ban(player, kind, id, banned)
	end)
	-- Inventory MMB: merge 5×L1→L2 or 3×L2→L3 (same weapon id)
	Remotes.Event("MergeWeapon").OnServerEvent:Connect(function(player, weaponUid)
		WeaponService.Merge(player, weaponUid)
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

local function weaponLevel(w: any): number
	return math.clamp(math.floor(w.level or 1), 1, WeaponConfig.MAX_WEAPON_LEVEL or 3)
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
		if not ProgressConfig.IsOffhandUnlocked(profile) then
			Remotes.Event("Notify"):FireClient(player, {
				text = "Offhand (2nd sword) is a paid unlock",
				color = "red",
			})
			return
		end
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
	local price = if def then WeaponConfig.GetSellPrice(def, weaponLevel(w)) else 5
	profile.coins += price
	table.remove(profile.weapons, idx)
	ProfileService.Push(player)
end

--- Sell every unequipped weapon; keep main/offhand and at least one sword.
function WeaponService.SellAll(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local kept: { any } = {}
	local gained = 0
	local sold = 0
	for _, w in ipairs(profile.weapons or {}) do
		local equipped = profile.equippedMain == w.uid or profile.equippedOffhand == w.uid
		if equipped then
			table.insert(kept, w)
		else
			local def = WeaponConfig.Get(w.id)
			gained += (def and def.sellPrice) or 5
			sold += 1
		end
	end
	-- never empty inventory
	if #kept == 0 and #(profile.weapons or {}) > 0 then
		-- keep first weapon if nothing equipped (safety)
		local first = profile.weapons[1]
		table.insert(kept, first)
		local def = WeaponConfig.Get(first.id)
		gained = math.max(0, gained - ((def and def.sellPrice) or 5))
		sold = math.max(0, sold - 1)
		if not profile.equippedMain then
			profile.equippedMain = first.uid
		end
	end
	if sold <= 0 then
		Remotes.Event("Notify"):FireClient(player, {
			text = "No unequipped swords to sell",
			color = "yellow",
		})
		return
	end
	profile.weapons = kept
	profile.coins = (profile.coins or 0) + gained
	ProfileService.Push(player)
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Sold %d swords for %d coins", sold, gained),
		color = "gold",
	})
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
	if not w.enchants then
		w.enchants = {}
	end
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

--[[
	Merge same weapons in inventory (MMB on a sword):
	  5 × same id at level 1 → that stack becomes level 2 (4 consumed)
	  3 × same id at level 2 → becomes level 3
]]
function WeaponService.Merge(player: Player, weaponUid: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local target, _ = findWeapon(profile, weaponUid)
	if not target then
		return
	end

	local lv = weaponLevel(target)
	local need = WeaponConfig.GetMergeNeed(lv)
	if not need then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Already max level (L3)",
			color = "red",
		})
		return
	end

	-- collect matching uid indices (same id + level), target first
	local matches: { { w: any, i: number } } = {}
	for i, w in profile.weapons do
		if w.id == target.id and weaponLevel(w) == lv then
			table.insert(matches, { w = w, i = i })
		end
	end

	if #matches < need then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format(
				"Need %d × same sword at L%d (have %d) — MMB to merge",
				need,
				lv,
				#matches
			),
			color = "red",
		})
		return
	end

	-- Keep target uid; remove (need-1) other copies (highest index first)
	local toRemove: { number } = {}
	local removed = 0
	for _, m in matches do
		if m.w.uid ~= weaponUid and removed < (need - 1) then
			table.insert(toRemove, m.i)
			removed += 1
		end
	end
	table.sort(toRemove, function(a, b)
		return a > b
	end)
	for _, idx in toRemove do
		local gone = profile.weapons[idx]
		if gone then
			if profile.equippedMain == gone.uid then
				profile.equippedMain = weaponUid
			end
			if profile.equippedOffhand == gone.uid then
				profile.equippedOffhand = nil
			end
			table.remove(profile.weapons, idx)
		end
	end

	target.level = lv + 1
	-- optional: clear enchants on upgrade (keep for now — player investment)

	local def = WeaponConfig.Get(target.id)
	local name = def and def.name or target.id
	local eff = if def then WeaponConfig.GetEffectivePower(def, target.level) else 0
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("%s → L%d  (strength %.0f)", name, target.level, eff),
		color = "gold",
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
