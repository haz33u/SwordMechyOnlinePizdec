--!strict
--[[
	Weapon drops — Cristalix-style absolute tables (simple/medium/hard/boss).

	Per kill (non-debug):
	  1) roll drop chance (≈100% for combat tiers)
	  2) roll rarity from weighted table (sum ≈100%, loc high-tier squeeze)
	  3) pick random weapon of that rarity on mob.location
	  4) boss: also grant enchantDust

	Limited never drops. Preview: WeaponConfig.BuildDropPreview + GetMobDropInfo.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local IconConfig = require(Shared.Config.IconConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local LootService = {}

local function pickFromList(list: { any }): any?
	if #list == 0 then
		return nil
	end
	return list[math.random(1, #list)]
end

local function filterCandidates(
	locationId: number,
	rarity: string,
	profile: any,
	allowlist: { string }?
): { any }
	local raw = WeaponConfig.GetDropCandidates(locationId, rarity)
	local out = {}
	local allow: { [string]: boolean }? = nil
	if allowlist and #allowlist > 0 then
		allow = {}
		for _, id in allowlist do
			allow[id] = true
		end
	end
	for _, def in raw do
		local banned = profile.bannedWeaponIds and profile.bannedWeaponIds[def.id]
		local blocked = allow ~= nil and not allow[def.id]
		if not banned and not blocked then
			table.insert(out, def)
		end
	end
	return out
end

function LootService.GrantWeapon(player: Player, profile: any, def: any)
	local wuid = ProfileService.NewUid()
	table.insert(profile.weapons, {
		uid = wuid,
		id = def.id,
		enchants = {},
	})

	local cur = nil
	for _, w in profile.weapons do
		if w.uid == profile.equippedMain then
			cur = w
			break
		end
	end
	local curMult = 1
	if cur then
		local cdef = WeaponConfig.Get(cur.id)
		if cdef then
			curMult = cdef.powerMult
		end
	end
	if def.powerMult > curMult then
		profile.equippedMain = wuid
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = "Drop: " .. def.name .. " (" .. def.rarity .. ")",
		color = if def.rarity == "Secret" or def.rarity == "Limited"
			then "gold"
			elseif def.rarity == "Mythic" or def.rarity == "Legendary"
			then "orange"
			else "gold",
	})
end

function LootService.TryWeaponDrop(player: Player, profile: any, mobDef: any)
	if not mobDef or mobDef.isDebug then
		return
	end
	if mobDef.weaponDropChance == 0 then
		return
	end

	local locationId = mobDef.location or profile.currentLocation or 1
	if locationId < 1 then
		return
	end

	local tier = mobDef.tier or "medium"
	local luck = Formulas.GetLuck(profile)
	local baseChance = WeaponConfig.GetBaseDropChance(tier, locationId)
	local scale = mobDef.weaponDropScale or 1
	-- slight luck boost to success chance only if not already guaranteed
	local chance = math.clamp(baseChance * scale * (1 + luck * 0.05), 0, 1)

	if math.random() > chance then
		return
	end

	local rarity = WeaponConfig.RollRarity(tier, locationId)
	if not rarity then
		return
	end

	local pool = filterCandidates(locationId, rarity, profile, mobDef.weaponPool)
	if #pool == 0 then
		local idx = WeaponConfig.RarityIndex(rarity)
		for i = idx - 1, 1, -1 do
			local r2 = WeaponConfig.RarityOrder[i]
			if r2 and r2 ~= "Limited" then
				pool = filterCandidates(locationId, r2, profile, mobDef.weaponPool)
				if #pool > 0 then
					break
				end
			end
		end
	end

	local def = pickFromList(pool)
	if def then
		LootService.GrantWeapon(player, profile, def)
	end
end

--- Boss material for weapon enchant
function LootService.TryBossDust(player: Player, profile: any, mobDef: any)
	if not mobDef or not mobDef.isBoss then
		return
	end
	if not WeaponConfig.BossDustAlways and math.random() > 0.85 then
		return
	end
	local minD = WeaponConfig.BossDustMin or 2
	local maxD = WeaponConfig.BossDustMax or 5
	local amount = math.random(minD, maxD)
	profile.enchantDust = (profile.enchantDust or 0) + amount
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Enchant dust +%d (total %d)", amount, profile.enchantDust),
		color = "purple",
	})
end

--- Case keys from kills (pet + aura). Chance by mob tier.
function LootService.TryCaseKeys(player: Player, profile: any, mobDef: any)
	if not mobDef or mobDef.isDebug then
		return
	end
	local tier = WeaponConfig.NormalizeTier(mobDef.tier or "medium")
	if mobDef.isBoss then
		tier = "boss"
	end

	local granted = false

	local petChance = CaseConfig.PetKeyChance[tier] or 0
	if petChance > 0 and math.random() < petChance then
		local amount = CaseConfig.RollAmount(CaseConfig.PetKeyAmount, tier)
		profile.petKeys = (profile.petKeys or 0) + amount
		granted = true
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Pet key +%d (total %d)", amount, profile.petKeys),
			color = "pink",
		})
	end

	local auraChance = CaseConfig.AuraKeyChance[tier] or 0
	if auraChance > 0 and math.random() < auraChance then
		local amount = CaseConfig.RollAmount(CaseConfig.AuraKeyAmount, tier)
		profile.auraKeys = (profile.auraKeys or 0) + amount
		granted = true
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Aura key +%d (total %d)", amount, profile.auraKeys),
			color = "blue",
		})
	end

	return granted
end

-- back-compat alias (CombatService used to call TryPetKey)
function LootService.TryPetKey(player: Player, profile: any, mobDef: any?)
	if mobDef then
		return LootService.TryCaseKeys(player, profile, mobDef)
	end
	return false
end

--- Inspect payload for Shift+RMB UI
function LootService.BuildMobInspect(mobDef: any, profile: any?): any?
	if not mobDef or mobDef.isDebug then
		return nil
	end
	local locationId = mobDef.location or 1
	local tier = WeaponConfig.NormalizeTier(mobDef.tier or "medium")
	local preview = WeaponConfig.BuildDropPreview(tier, locationId)
	local rows = {}
	for _, entry in preview do
		-- pick representative weapon for icon (first in rarity, or random)
		local rep = entry.weapons[1]
		local icon = if rep then IconConfig.GetWeaponImage(rep.id) else IconConfig.FallbackWeapon
		table.insert(rows, {
			rarity = entry.rarity,
			chancePercent = entry.chancePercent,
			label = if rep then rep.name else entry.rarity,
			weaponId = if rep then rep.id else nil,
			powerMult = if rep then rep.powerMult else nil,
			icon = icon,
			variants = #entry.weapons,
		})
	end

	local dust = nil
	if mobDef.isBoss then
		dust = {
			name = "Enchant Dust",
			min = WeaponConfig.BossDustMin or 2,
			max = WeaponConfig.BossDustMax or 5,
			chancePercent = 100,
			note = "Used to enchant weapons",
		}
	end

	local keyTier = if mobDef.isBoss then "boss" else tier
	local petKeyChance = (CaseConfig.PetKeyChance[keyTier] or 0) * 100
	local auraKeyChance = (CaseConfig.AuraKeyChance[keyTier] or 0) * 100

	return {
		mobId = mobDef.id,
		name = mobDef.name,
		tier = tier,
		tierLabel = if tier == "simple"
			then "Simple"
			elseif tier == "medium"
			then "Medium"
			elseif tier == "hard"
			then "Hard"
			elseif tier == "boss"
			then "Boss"
			else tier,
		location = locationId,
		hp = mobDef.hp,
		coinReward = mobDef.coinReward,
		powerReward = mobDef.powerReward,
		isBoss = mobDef.isBoss == true,
		description = mobDef.description,
		drops = rows,
		enchantDust = dust,
		petKey = {
			chancePercent = petKeyChance,
			note = "Opens Pet Case",
		},
		auraKey = {
			chancePercent = auraKeyChance,
			note = "Opens Aura Case",
		},
		alwaysWeapon = (WeaponConfig.GetBaseDropChance(tier, locationId) >= 0.999),
	}
end

return LootService
