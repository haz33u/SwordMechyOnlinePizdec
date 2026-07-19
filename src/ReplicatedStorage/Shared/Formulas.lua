--!strict
--[[
	All combat / power math in one place.
]]

local GameConfig = require(script.Parent.Config.GameConfig)
local RebirthConfig = require(script.Parent.Config.RebirthConfig)
local UpgradeConfig = require(script.Parent.Config.UpgradeConfig)
local WeaponConfig = require(script.Parent.Config.WeaponConfig)
local PetConfig = require(script.Parent.Config.PetConfig)
local AuraConfig = require(script.Parent.Config.AuraConfig)
local RelicConfig = require(script.Parent.Config.RelicConfig)
local EnchantConfig = require(script.Parent.Config.EnchantConfig)
local ClickConfig = require(script.Parent.Config.ClickConfig)
local ProgressConfig = require(script.Parent.Config.ProgressConfig)

local Formulas = {}

local function sumEnchantStat(enchants: { any }, stat: string): number
	local total = 0
	for _, e in enchants do
		local def
		for _, d in EnchantConfig.Enchants do
			if d.id == e.id then
				def = d
				break
			end
		end
		if def and def.stat == stat then
			total += e.value
		end
	end
	return total
end

local function findWeapon(profile: any, uid: string?): any?
	if not uid then
		return nil
	end
	for _, w in profile.weapons do
		if w.uid == uid then
			return w
		end
	end
	return nil
end

function Formulas.GetUpgradeLevel(profile: any, id: string): number
	return profile.upgradeLevels[id] or 0
end

function Formulas.GetWeaponPowerMult(profile: any): number
	local main = findWeapon(profile, profile.equippedMain)
	local mult = 1
	if main then
		local def = WeaponConfig.Get(main.id)
		if def then
			mult = WeaponConfig.GetEffectivePower(def, main.level or 1)
		end
	end
	-- offhand only if paid unlock
	if ProgressConfig.IsOffhandUnlocked(profile) then
		local off = findWeapon(profile, profile.equippedOffhand)
		if off then
			local def = WeaponConfig.Get(off.id)
			if def then
				mult += WeaponConfig.GetEffectivePower(def, off.level or 1) * 0.5
			end
		end
	end
	return mult
end

function Formulas.GetEnchantPools(profile: any): { [string]: number }
	local pools = {
		power = 0,
		damage = 0,
		attackSpeed = 0,
		crit = 0,
		coins = 0,
		luck = 0,
	}
	local function addFrom(uid: string?)
		local w = findWeapon(profile, uid)
		if not w then
			return
		end
		for stat, _ in pools do
			pools[stat] += sumEnchantStat(w.enchants, stat)
		end
	end
	addFrom(profile.equippedMain)
	if ProgressConfig.IsOffhandUnlocked(profile) then
		addFrom(profile.equippedOffhand)
	end
	return pools
end

--[[
	Pets: dump "Мощь xN" = pure mult.
	Team stacks additive on excess: factor = 1 + Σ(N-1)×level (same as old % math, no % stored).
]]
function Formulas.GetPetPowerMult(profile: any): number
	local mult = 1
	for _, uid in profile.petTeam do
		for _, pet in profile.pets do
			if pet.uid == uid then
				local def = PetConfig.Get(pet.id)
				if def then
					local base = PetConfig.GetPowerMult(def)
					local levelFactor = 1 + PetConfig.LEVEL_POWER_PER * math.max(0, pet.level - 1)
					local ench = sumEnchantStat(pet.enchants, "power") -- enchant still % points
					mult += (base * levelFactor - 1) + ench / 100
				end
				break
			end
		end
	end
	return math.max(1, mult)
end

--- Display/compat only (not combat source of truth)
function Formulas.GetPetPowerPct(profile: any): number
	return (Formulas.GetPetPowerMult(profile) - 1) * 100
end

function Formulas.GetPetCoinPct(profile: any): number
	local total = 0
	for _, uid in profile.petTeam do
		for _, pet in profile.pets do
			if pet.uid == uid then
				local def = PetConfig.Get(pet.id)
				if def then
					-- coinMult pure → convert excess to soft % for coin formula
					local cm = def.coinMult or 1
					total += (cm - 1) * 100
				end
				break
			end
		end
	end
	return total
end

function Formulas.GetAuraPct(profile: any): (number, number, number)
	if not profile.equippedAura then
		return 0, 0, 0
	end
	for _, a in profile.auras do
		if a.uid == profile.equippedAura then
			local def = AuraConfig.Get(a.id)
			if def then
				return def.powerPct, def.damagePct, def.coinPct
			end
		end
	end
	return 0, 0, 0
end

function Formulas.GetRelicPct(profile: any): (number, number)
	local power, damage = 0, 0
	for _, uid in profile.equippedRelics do
		for _, r in profile.relics do
			if r.uid == uid then
				local def = RelicConfig.Get(r.id)
				if def then
					local starMult = 1 + RelicConfig.STAR_BONUS * (r.stars or 0)
					power += def.powerPct * starMult
					damage += def.damagePct * starMult
				end
				break
			end
		end
	end
	return power, damage
end

function Formulas.GetTotalPower(profile: any): number
	local base = GameConfig.BASE_POWER + (profile.lifetimePower or 0)

	local rebirthMult = RebirthConfig.GetMultAfter(profile.rebirthLevel or 0)
	if (profile.rebirthMult or 0) > 0 and profile.rebirthLevel and profile.rebirthLevel > 0 then
		-- prefer stored if it matches rank table; else force table
		local tableMult = RebirthConfig.GetMultAfter(profile.rebirthLevel)
		rebirthMult = tableMult
	end

	local weaponMult = Formulas.GetWeaponPowerMult(profile) -- pure dump Сила
	local petMult = Formulas.GetPetPowerMult(profile) -- pure dump Мощь product/stack
	local ench = Formulas.GetEnchantPools(profile)
	local auraP, auraD = Formulas.GetAuraPct(profile)
	local relicP, relicD = Formulas.GetRelicPct(profile)

	local upgradePowerLvl = Formulas.GetUpgradeLevel(profile, "Power")
	local upgradePowerPct = upgradePowerLvl * (UpgradeConfig.Defs.Power.effectPerLevel * 100)
	local questPowerPct = profile.questPowerPct or 0

	-- Non-dump systems still use % pools (enchants / aura / relic / upgrades / quests)
	local powerPct = ench.power + auraP + relicP + upgradePowerPct + questPowerPct
	local damagePct = ench.damage + auraD + relicD

	local total = base
		* rebirthMult
		* weaponMult
		* petMult
		* (1 + powerPct / 100)
		* (1 + damagePct / 100)

	return math.max(1, total)
end

function Formulas.GetAttackSpeedPercent(profile: any): number
	local ench = Formulas.GetEnchantPools(profile)
	local clickLvl = Formulas.GetUpgradeLevel(profile, "ClickSpeed")
	local clickPct = clickLvl * (UpgradeConfig.Defs.ClickSpeed.effectPerLevel * 100)
	local speedPct = ench.attackSpeed + clickPct

	for _, uid in profile.petTeam do
		for _, pet in profile.pets do
			if pet.uid == uid then
				local def = PetConfig.Get(pet.id)
				if def then
					-- speedMult pure; excess → % points for attack-speed pool
					local sm = def.speedMult or 1
					speedPct += (sm - 1) * 100
				end
			end
		end
	end
	return speedPct
end

function Formulas.GetMaxCPS(profile: any): number
	return ClickConfig.GetMaxCPS(profile)
end

function Formulas.GetSwingCooldown(profile: any): number
	local speedPct = Formulas.GetAttackSpeedPercent(profile)
	local cd: number
	if speedPct >= 0 then
		cd = GameConfig.BASE_SWING_COOLDOWN / (1 + speedPct / 100)
	else
		cd = GameConfig.BASE_SWING_COOLDOWN * (1 + math.abs(speedPct) / 100)
	end
	-- clamp by location / purchase CPS cap
	local maxCps = Formulas.GetMaxCPS(profile)
	local minCd = 1 / maxCps
	local maxCd = 1 / ClickConfig.MIN_CPS
	return math.clamp(cd, minCd, maxCd)
end

--[[
	CPS = clicks per second = core farming rate.
	Without purchased auto: Loc1 ≤ 4, global ≤ 20 (see ClickConfig).
]]
function Formulas.GetCPS(profile: any): number
	local cd = Formulas.GetSwingCooldown(profile)
	local cps = 1 / cd
	local maxCps = Formulas.GetMaxCPS(profile)
	return math.clamp(cps, ClickConfig.MIN_CPS, maxCps)
end

function Formulas.GetDPS(profile: any): number
	return Formulas.GetTotalPower(profile) * Formulas.GetCPS(profile)
end

function Formulas.IsAutoClickerUnlocked(profile: any): boolean
	-- Free manual clicking always works; "unlocked auto" = purchased product
	if type(ClickConfig.IsAutoPurchased) == "function" then
		return ClickConfig.IsAutoPurchased(profile)
	end
	if ClickConfig.AUTO_UNLOCKED_BY_DEFAULT then
		return true
	end
	if (profile.rebirthLevel or 0) >= (ClickConfig.AUTO_UNLOCK_REBIRTH or 0) then
		return true
	end
	if profile.autoClickerUnlocked == true then
		return true
	end
	local unlocks = profile.unlocks or {}
	return unlocks.autoClicker == true
end

function Formulas.GetCritChance(profile: any): number
	local ench = Formulas.GetEnchantPools(profile)
	local lvl = Formulas.GetUpgradeLevel(profile, "CritChance")
	local per = (UpgradeConfig.Defs.CritChance and UpgradeConfig.Defs.CritChance.effectPerLevel) or 0.01
	return math.clamp(lvl * per + ench.crit / 100, 0, 0.85)
end

function Formulas.GetMultiCritChance(profile: any): number
	local lvl = Formulas.GetUpgradeLevel(profile, "MultiCrit")
	local per = (UpgradeConfig.Defs.MultiCrit and UpgradeConfig.Defs.MultiCrit.effectPerLevel) or 0.01
	return math.clamp(lvl * per, 0, 0.5)
end

--- Returns damage, isCrit, isMultiCrit
function Formulas.GetHitDamage(profile: any): (number, boolean, boolean)
	local power = Formulas.GetTotalPower(profile)
	local crit = Formulas.GetCritChance(profile)
	local isCrit = math.random() < crit
	local isMulti = false
	local dmg = power
	if isCrit then
		dmg *= 2
		-- multi-crit: upgrade crit hit to ×3
		if math.random() < Formulas.GetMultiCritChance(profile) then
			dmg = power * 3
			isMulti = true
		end
	end
	return dmg, isCrit, isMulti
end

function Formulas.GetWeaponBagCap(profile: any): number
	return UpgradeConfig.GetBagCap(profile, "weapons")
end

function Formulas.GetPetBagCap(profile: any): number
	return UpgradeConfig.GetBagCap(profile, "pets")
end

function Formulas.GetItemBagCap(profile: any): number
	return UpgradeConfig.GetBagCap(profile, "items")
end

--[[
	Expected damage per click (crit averaged). Armor applied like CombatService.
	Returns: hitsToKill, secondsToKill, dmgPerHitAvg, yourPower, cps
]]
function Formulas.EstimateKill(
	profile: any,
	mobHp: number,
	armorFlat: number?
): (number, number, number, number, number)
	local power = Formulas.GetTotalPower(profile)
	local crit = Formulas.GetCritChance(profile)
	local multi = Formulas.GetMultiCritChance(profile)
	-- expected: normal + crit×2 + multi-crit portion (crit→×3)
	local avgDmg = power * ((1 - crit) + crit * ((1 - multi) * 2 + multi * 3))
	local armor = armorFlat or 0
	local effective = math.max(1, avgDmg - armor)
	local hp = math.max(1, mobHp)
	local hits = math.max(1, math.ceil(hp / effective))
	local cps = Formulas.GetCPS(profile)
	local seconds = hits / math.max(0.01, cps)
	return hits, seconds, effective, power, cps
end

function Formulas.GetCoinMult(profile: any): number
	local ench = Formulas.GetEnchantPools(profile)
	local petCoins = Formulas.GetPetCoinPct(profile)
	local _, _, auraCoins = Formulas.GetAuraPct(profile)
	return 1 + (ench.coins + petCoins + auraCoins) / 100
end

function Formulas.GetLuck(profile: any): number
	local ench = Formulas.GetEnchantPools(profile)
	local lvl = Formulas.GetUpgradeLevel(profile, "Luck")
	return lvl * 0.02 + ench.luck / 100
end

function Formulas.GetWalkSpeed(profile: any): number
	local lvl = Formulas.GetUpgradeLevel(profile, "RunSpeed")
	return 16 + lvl * UpgradeConfig.Defs.RunSpeed.effectPerLevel
end

--[[
	Ideal-time to next rebirth with CURRENT gear (always clicking).
	Uses expected DPS (crit averaged). Returns seconds (0 if ready, math.huge if stuck).
]]
function Formulas.EstimateRebirthEta(profile: any): (number, number, number, number)
	local nextLv = (profile.rebirthLevel or 0) + 1
	local dmgCost, coinCost = RebirthConfig.GetCosts(nextLv)
	local dmg = profile.lifetimeDamage or 0
	local coins = profile.coins or 0
	local remDmg = math.max(0, dmgCost - dmg)
	local remCoins = math.max(0, coinCost - coins)

	if remDmg <= 0 and remCoins <= 0 then
		return 0, 0, 0, 0
	end

	local power = Formulas.GetTotalPower(profile)
	local cps = Formulas.GetCPS(profile)
	local crit = Formulas.GetCritChance(profile)
	local dps = power * cps * ((1 - crit) + crit * 2)
	if dps < 0.01 then
		return math.huge, remDmg, remCoins, dps
	end

	local tDmg = remDmg / dps
	local tCoin = 0
	if remCoins > 0 then
		-- rough farm: damage dealt → coins (Loc1-ish ratio × coin mult)
		local coinsPerSec = dps * (RebirthConfig.ETA_COINS_PER_DAMAGE or 0.12) * Formulas.GetCoinMult(profile)
		tCoin = if coinsPerSec > 0.01 then remCoins / coinsPerSec else math.huge
	end

	return math.max(tDmg, tCoin), remDmg, remCoins, dps
end

function Formulas.Snapshot(profile: any): { [string]: any }
	local power = Formulas.GetTotalPower(profile)
	local cps = Formulas.GetCPS(profile)
	local nextLv = (profile.rebirthLevel or 0) + 1
	local etaSec, remDmg, remCoins, dpsIdeal = Formulas.EstimateRebirthEta(profile)
	local rbMult = RebirthConfig.GetMultAfter(profile.rebirthLevel or 0)
	return {
		totalPower = power,
		cps = cps,
		maxCps = Formulas.GetMaxCPS(profile),
		dps = power * cps,
		damagePerClick = power,
		swingCd = Formulas.GetSwingCooldown(profile),
		attackSpeedPct = Formulas.GetAttackSpeedPercent(profile),
		crit = Formulas.GetCritChance(profile),
		coinMult = Formulas.GetCoinMult(profile),
		luck = Formulas.GetLuck(profile),
		walkSpeed = Formulas.GetWalkSpeed(profile),
		rebirthLevel = profile.rebirthLevel,
		rebirthMult = rbMult,
		rebirthRankName = RebirthConfig.GetRankName(profile.rebirthLevel or 0),
		nextRebirthRankName = RebirthConfig.GetRankName(nextLv),
		nextRebirthMult = RebirthConfig.GetMultAfter(nextLv),
		nextRebirthCost = RebirthConfig.GetDamageCost(nextLv),
		nextRebirthCoinCost = RebirthConfig.GetCoinCost(nextLv),
		rebirthProgress = RebirthConfig.GetProgress(
			profile.lifetimeDamage or 0,
			profile.coins or 0,
			nextLv
		),
		rebirthEtaSeconds = etaSec,
		rebirthRemainingDamage = remDmg,
		rebirthRemainingCoins = remCoins,
		rebirthIdealDps = dpsIdeal,
		lifetimeDamage = profile.lifetimeDamage,
		totalClicks = profile.totalClicks or 0,
		coins = profile.coins,
		enchantDust = profile.enchantDust or 0,
		petKeys = profile.petKeys or 0,
		auraKeys = profile.auraKeys or 0,
		questPowerPct = profile.questPowerPct or 0,
		upgradePowerPct = (profile.upgradeLevels and (profile.upgradeLevels.Power or 0) or 0)
			* (UpgradeConfig.Defs.Power.effectPerLevel * 100),
		weaponBagCap = Formulas.GetWeaponBagCap(profile),
		petBagCap = Formulas.GetPetBagCap(profile),
		itemBagCap = Formulas.GetItemBagCap(profile),
		petSlots = profile.petSlots,
		offhandUnlocked = ProgressConfig.IsOffhandUnlocked(profile),
		paidPetSlot = (profile.unlocks and profile.unlocks.paidPetSlot) == true,
		nextPetSlotHint = ProgressConfig.GetNextPetSlotHint(profile),
		location = profile.currentLocation,
		autoClicker = profile.autoClicker == true,
		autoClickerUnlocked = Formulas.IsAutoClickerUnlocked(profile),
	}
end

return Formulas
