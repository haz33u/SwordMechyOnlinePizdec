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
	local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local Formulas = require(Shared.Formulas)
	local cap = Formulas.GetWeaponBagCap(profile)
	if #(profile.weapons or {}) >= cap then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Weapon bag full (%d) — sell or upgrade Backpack", cap),
			color = "red",
		})
		return
	end
	local wuid = ProfileService.NewUid()
	table.insert(profile.weapons, {
		uid = wuid,
		id = def.id,
		level = 1,
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

	-- No toast on every weapon drop (clutters UI). Inventory updates via ProfileUpdate.
	-- Bag-full / dust / keys still Notify.
end

local function rollExactDropTable(dropTable: { [string]: number }, profile: any): any?
	local total = 0
	local entries = {}
	for id, w in dropTable do
		if w > 0 and not (profile.bannedWeaponIds and profile.bannedWeaponIds[id]) then
			local def = WeaponConfig.Get(id)
			if def then
				total += w
				table.insert(entries, { def = def, w = w })
			end
		end
	end
	if total <= 0 or #entries == 0 then
		return nil
	end
	local r = math.random() * total
	local acc = 0
	for _, e in entries do
		acc += e.w
		if r <= acc then
			return e.def
		end
	end
	return entries[#entries].def
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

	-- Loc2 dump: exact weapon % table on the mob
	if mobDef.dropTable then
		local def = rollExactDropTable(mobDef.dropTable, profile)
		if def then
			LootService.GrantWeapon(player, profile, def)
		end
		return
	end

	local tier = mobDef.tier or "medium"
	local luck = Formulas.GetLuck(profile)
	local baseChance = WeaponConfig.GetBaseDropChance(tier, locationId)
	local scale = mobDef.weaponDropScale or 1
	local anomDrop = Formulas.GetAnomalyDropMult()
	local chance = math.clamp(baseChance * scale * (1 + luck * 0.05) * anomDrop, 0, 1)

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
	amount = math.max(1, math.floor(amount * Formulas.GetAnomalyDustMult() + 0.5))
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
	local keyM = Formulas.GetAnomalyKeyChanceMult()

	local petChance = (CaseConfig.PetKeyChance[tier] or 0) * keyM
	if petChance > 0 and math.random() < petChance then
		local amount = CaseConfig.RollAmount(CaseConfig.PetKeyAmount, tier)
		profile.petKeys = (profile.petKeys or 0) + amount
		granted = true
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Pet key +%d (total %d)", amount, profile.petKeys),
			color = "pink",
		})
	end

	local auraChance = (CaseConfig.AuraKeyChance[tier] or 0) * keyM
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
	local preview = if mobDef.dropTable
		then WeaponConfig.BuildDropPreviewFromTable(mobDef.dropTable)
		else WeaponConfig.BuildDropPreview(tier, locationId)
	local rows = {}
	for _, entry in preview do
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

	-- Kill ETA from equipped gear (Cristalix-style "kill time")
	local hits, seconds, dmgAvg, yourPower, cps = 0, 0, 0, 0, 0
	if profile then
		hits, seconds, dmgAvg, yourPower, cps =
			Formulas.EstimateKill(profile, mobDef.hp, mobDef.armorFlat)
	end

	local mainName = nil
	local mainStrength = nil
	if profile and profile.equippedMain then
		for _, w in profile.weapons or {} do
			if w.uid == profile.equippedMain then
				local def = WeaponConfig.Get(w.id)
				if def then
					mainName = string.format("%s L%d", def.name, w.level or 1)
					mainStrength = WeaponConfig.GetEffectivePower(def, w.level or 1)
				end
				break
			end
		end
	end

	return {
		mobId = mobDef.id,
		name = mobDef.name,
		tier = tier,
		tierLabel = if tier == "simple"
			then "Tier 1"
			elseif tier == "medium"
			then "Tier 2"
			elseif tier == "hard"
			then "Tier 3"
			elseif tier == "elite"
			then "Tier 4"
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
		-- combat preview (depends on YOUR sword / CPS)
		combat = {
			yourPower = yourPower,
			cps = cps,
			dmgPerHit = dmgAvg,
			hitsToKill = hits,
			secondsToKill = seconds,
			mainWeapon = mainName,
			mainStrength = mainStrength,
		},
	}
end

return LootService
