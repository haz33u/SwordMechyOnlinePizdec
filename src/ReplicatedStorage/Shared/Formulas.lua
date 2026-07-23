--!strict
--[[
	All combat / power math in one place.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local AnomalyConfig = require(script.Parent.Config.AnomalyConfig)

local Formulas = {}

export type AnomalyRuntime = {
	id: string,
	name: string,
	endsAt: number,
	mods: any,
	hud: { [string]: number }?,
}

--- Active global anomaly from ReplicatedStorage.WorldState (server writes, all read).
function Formulas.GetActiveAnomaly(): AnomalyRuntime?
	local folder = ReplicatedStorage:FindFirstChild(AnomalyConfig.WORLD_FOLDER)
	if not folder then
		return nil
	end
	local id = folder:GetAttribute(AnomalyConfig.ATTR_ID)
	if type(id) ~= "string" or id == "" then
		return nil
	end
	local endsAt = folder:GetAttribute(AnomalyConfig.ATTR_ENDS)
	local now = workspace:GetServerTimeNow()
	if type(endsAt) ~= "number" or endsAt <= now then
		return nil
	end
	local def = AnomalyConfig.Get(id)
	if not def then
		return nil
	end
	return {
		id = def.id,
		name = def.name,
		endsAt = endsAt,
		mods = def.mods or {},
		hud = def.hud,
	}
end

function Formulas.GetAnomalyMods(): any
	local a = Formulas.GetActiveAnomaly()
	return if a then a.mods else {}
end

local function sumEnchantStat(enchants: { any }?, stat: string): number
	if not enchants then
		return 0
	end
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
	if not uid or not profile or not profile.weapons then
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
	if not profile or not profile.upgradeLevels then
		return 0
	end
	return profile.upgradeLevels[id] or 0
end

function Formulas.GetWeaponPowerMult(profile: any): number
	if not profile then
		return 1
	end
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
	if not profile then
		return pools
	end
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

local function getPetMap(profile: any): { [string]: any }
	local map = {}
	if profile and profile.pets then
		for _, pet in profile.pets do
			map[pet.uid] = pet
		end
	end
	return map
end

--[[
	Pets: dump "Мощь xN" = pure mult.
	Team stacks additive on excess: factor = 1 + Σ(N-1)×level (same as old % math, no % stored).
]]
function Formulas.GetPetPowerMult(profile: any): number
	local mult = 1
	local petMap = getPetMap(profile)
	for _, uid in profile.petTeam or {} do
		local pet = petMap[uid]
		if pet then
			local def = PetConfig.Get(pet.id)
			if def then
				local base = PetConfig.GetPowerMult(def)
				local levelFactor = 1 + PetConfig.LEVEL_POWER_PER * math.max(0, pet.level - 1)
				local ench = sumEnchantStat(pet.enchants, "power") -- enchant still % points
				mult += (base * levelFactor - 1) + ench / 100
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
	local petMap = getPetMap(profile)
	for _, uid in profile.petTeam or {} do
		local pet = petMap[uid]
		if pet then
			local def = PetConfig.Get(pet.id)
			if def then
				-- coinMult pure → convert excess to soft % for coin formula
				local cm = def.coinMult or 1
				total += (cm - 1) * 100
			end
		end
	end
	return total
end

--- Max equipped relic slots: free 2, +1 if paid relicSlot gamepass.
function Formulas.GetMaxRelicSlots(profile: any): number
	local n = GameConfig.START_RELIC_SLOTS or 2
	local unlocks = profile and profile.unlocks
	if unlocks and unlocks.relicSlot then
		n += (GameConfig.PAID_RELIC_SLOTS or 1)
	end
	local cap = GameConfig.MAX_RELIC_SLOTS or 3
	return math.min(n, cap)
end

function Formulas.GetAuraPct(profile: any): (number, number, number)
	local p, d, c, _, _ = Formulas.GetAuraBonuses(profile)
	return p, d, c
end

--- power%, damage%, coin%, crit points, multicrit points (level-scaled dump stats)
function Formulas.GetAuraBonuses(profile: any): (number, number, number, number, number)
	if not profile or not profile.equippedAura then
		return 0, 0, 0, 0, 0
	end
	for _, a in profile.auras or {} do
		if a.uid == profile.equippedAura then
			local rawId = a.id
			local id = AuraConfig.ResolveId and AuraConfig.ResolveId(rawId) or rawId
			local def = AuraConfig.Get(id) or AuraConfig.Get(rawId)
			if def then
				local eff = AuraConfig.GetEffective(def, a.level or 1)
				return eff.powerPct, eff.damagePct, eff.coinPct, eff.critPct, eff.multiCritPct
			end
		end
	end
	return 0, 0, 0, 0, 0
end

function Formulas.GetRelicPct(profile: any): (number, number)
	local power, damage = 0, 0
	local maxSlots = Formulas.GetMaxRelicSlots(profile)
	local n = 0
	for _, uid in profile.equippedRelics or {} do
		if n >= maxSlots then
			break
		end
		for _, r in profile.relics or {} do
			if r.uid == uid then
				local rawId = r.id
				local id = RelicConfig.ResolveId and RelicConfig.ResolveId(rawId) or rawId
				local def = RelicConfig.Get(id) or RelicConfig.Get(rawId)
				if def then
					local p, d = RelicConfig.EffectiveStats(def, r.stars or 0)
					power += p
					damage += d
					n += 1
				end
				break
			end
		end
	end
	return power, damage
end

function Formulas.GetBoostPct(profile: any, statKey: string): number
	if not profile or type(profile.boosts) ~= "table" then
		return 0
	end
	local b = profile.boosts[statKey]
	if type(b) == "table" and type(b.expiresAt) == "number" and b.expiresAt > os.time() then
		return (b.pct or 0) * 100
	end
	return 0
end

function Formulas.GetFriendMult(player: Player?): number
	if not player then return 1 end
	local count = (player:GetAttribute("friends_in_game") or 0) :: number
	return math.min(1.5, 1 + count * 0.10)
end

function Formulas.GetPremiumMult(player: Player?): number
	if not player then return 1 end
	if player.MembershipType == Enum.MembershipType.Premium then
		return 1.20
	end
	return 1.0
end

--[[
	TotalPower = Player Strength (HUD Power, click gain, lifetime strength).
	Power% boosts this stat directly.
	Damage% is applied separately during combat hits (GetHitDamage).
]]
function Formulas.GetTotalPower(profile: any, player: Player?): number
	local base = GameConfig.BASE_POWER + (profile.lifetimePower or 0)
	local rebirthMult = RebirthConfig.GetMultAfter(profile.rebirthLevel or 0)

	local weaponMult = Formulas.GetWeaponPowerMult(profile) -- pure dump Сила
	local petMult = Formulas.GetPetPowerMult(profile) -- pure dump Мощь product/stack
	local ench = Formulas.GetEnchantPools(profile)
	local auraP = Formulas.GetAuraPct(profile)
	local relicP = Formulas.GetRelicPct(profile)

	local upgradePowerLvl = Formulas.GetUpgradeLevel(profile, "Power")
	local upgradePowerPct = upgradePowerLvl * (UpgradeConfig.Defs.Power.effectPerLevel * 100)
	local questPowerPct = profile.questPowerPct or 0
	local boostPowerPct = Formulas.GetBoostPct(profile, "power")

	local friendMult = Formulas.GetFriendMult(player)
	local premiumMult = Formulas.GetPremiumMult(player)

	local anom = Formulas.GetAnomalyMods()
	local powerPct = ench.power + auraP + relicP + upgradePowerPct + questPowerPct + boostPowerPct

	local total = base
		* rebirthMult
		* weaponMult
		* petMult
		* friendMult
		* premiumMult
		* (1 + powerPct / 100)
		* (anom.powerMult or 1)

	return math.max(1, total)
end

-- Base Power gain earned per click (linear & smooth progression)
function Formulas.GetClickPowerGain(profile: any, player: Player?): number
	local baseGain = GameConfig.BASE_POWER_PER_CLICK or 1
	local rebirthMult = RebirthConfig.GetMultAfter(profile.rebirthLevel or 0)
	local weaponMult = Formulas.GetWeaponPowerMult(profile)
	local petMult = Formulas.GetPetPowerMult(profile)
	local ench = Formulas.GetEnchantPools(profile)
	local auraP = Formulas.GetAuraPct(profile)
	local relicP = Formulas.GetRelicPct(profile)

	local upgradePowerLvl = Formulas.GetUpgradeLevel(profile, "Power")
	local upgradePowerPct = upgradePowerLvl * (UpgradeConfig.Defs.Power.effectPerLevel * 100)
	local questPowerPct = profile.questPowerPct or 0
	local boostPowerPct = Formulas.GetBoostPct(profile, "power")

	local friendMult = Formulas.GetFriendMult(player)
	local premiumMult = Formulas.GetPremiumMult(player)

	local anom = Formulas.GetAnomalyMods()
	local powerPct = ench.power + auraP + relicP + upgradePowerPct + questPowerPct + boostPowerPct

	local gain = baseGain
		* rebirthMult
		* weaponMult
		* petMult
		* friendMult
		* premiumMult
		* (1 + powerPct / 100)
		* (anom.powerMult or 1)

	return math.max(1, math.floor(gain + 0.5))
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
	local _, _, _, auraCrit = Formulas.GetAuraBonuses(profile)
	return math.clamp(lvl * per + ench.crit / 100 + (auraCrit or 0) / 100, 0, 0.85)
end

function Formulas.GetMultiCritChance(profile: any): number
	local lvl = Formulas.GetUpgradeLevel(profile, "MultiCrit")
	local per = (UpgradeConfig.Defs.MultiCrit and UpgradeConfig.Defs.MultiCrit.effectPerLevel) or 0.01
	local _, _, _, _, auraMulti = Formulas.GetAuraBonuses(profile)
	return math.clamp(lvl * per + (auraMulti or 0) / 100, 0, 0.5)
end

--- Returns damage multiplier factor (1 + damagePct / 100)
function Formulas.GetDamageMultiplier(profile: any): number
	local ench = Formulas.GetEnchantPools(profile)
	local _, auraD = Formulas.GetAuraPct(profile)
	local _, relicD = Formulas.GetRelicPct(profile)
	local anom = Formulas.GetAnomalyMods()
	local damagePct = ench.damage + auraD + relicD + (anom.damagePct or 0)
	return 1 + damagePct / 100
end

function Formulas.GetDPS(profile: any, player: Player?): number
	local power = Formulas.GetTotalPower(profile, player)
	local dmgMult = Formulas.GetDamageMultiplier(profile)
	return power * dmgMult * Formulas.GetCPS(profile)
end

--- Returns damage, isCrit, isMultiCrit
function Formulas.GetHitDamage(profile: any, player: Player?): (number, boolean, boolean)
	local power = Formulas.GetTotalPower(profile, player)
	local dmgMult = Formulas.GetDamageMultiplier(profile)
	local baseDamage = power * dmgMult

	local crit = Formulas.GetCritChance(profile)
	local isCrit = math.random() < crit
	local isMulti = false
	local dmg = baseDamage

	if isCrit then
		dmg *= 2
		-- multi-crit: upgrade crit hit to ×3
		if math.random() < Formulas.GetMultiCritChance(profile) then
			dmg = baseDamage * 3
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
	local dmgMult = Formulas.GetDamageMultiplier(profile)
	local baseDamage = power * dmgMult
	local crit = Formulas.GetCritChance(profile)
	local multi = Formulas.GetMultiCritChance(profile)
	-- expected: normal + crit×2 + multi-crit portion (crit→×3)
	local avgDmg = baseDamage * ((1 - crit) + crit * ((1 - multi) * 2 + multi * 3))
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
	local relicCoins = 0
	local maxSlots = Formulas.GetMaxRelicSlots(profile)
	local n = 0
	for _, uid in profile.equippedRelics or {} do
		if n >= maxSlots then
			break
		end
		for _, r in profile.relics or {} do
			if r.uid == uid then
				local id = RelicConfig.ResolveId(r.id)
				local def = RelicConfig.Get(id) or RelicConfig.Get(r.id)
				if def then
					local _, _, c = RelicConfig.EffectiveStats(def, r.stars or 0)
					relicCoins += c
					n += 1
				end
				break
			end
		end
	end
	local boostCoins = Formulas.GetBoostPct(profile, "money")
	local base = 1 + (ench.coins + petCoins + auraCoins + relicCoins + boostCoins) / 100
	local anom = Formulas.GetAnomalyMods()
	return base * (anom.coinMult or 1)
end

function Formulas.GetLuck(profile: any): number
	local ench = Formulas.GetEnchantPools(profile)
	local lvl = Formulas.GetUpgradeLevel(profile, "Luck")
	local anom = Formulas.GetAnomalyMods()
	local questLuck = (profile and profile.questLuckPct or 0) / 100
	return lvl * 0.02 + ench.luck / 100 + (anom.luckAdd or 0) + questLuck
end

--- Multiplier on mob respawn delay (<1 = faster).
function Formulas.GetAnomalySpawnMult(): number
	local anom = Formulas.GetAnomalyMods()
	local m = anom.spawnMult or 1
	return math.clamp(m, 0.25, 3)
end

function Formulas.GetAnomalyDropMult(): number
	local anom = Formulas.GetAnomalyMods()
	return math.max(0.1, anom.dropMult or 1)
end

function Formulas.GetAnomalyDustMult(): number
	local anom = Formulas.GetAnomalyMods()
	return math.max(0.1, anom.dustMult or 1)
end

function Formulas.GetAnomalyKeyChanceMult(): number
	local anom = Formulas.GetAnomalyMods()
	return math.max(0.1, anom.keyChanceMult or 1)
end

function Formulas.GetAnomalyMobHpMult(): number
	local anom = Formulas.GetAnomalyMods()
	return math.max(0.5, anom.mobHpMult or 1)
end

function Formulas.GetWalkSpeed(profile: any): number
	local lvl = Formulas.GetUpgradeLevel(profile, "RunSpeed")
	return 16 + lvl * UpgradeConfig.Defs.RunSpeed.effectPerLevel
end

--[[
	Ideal-time to next rebirth with CURRENT gear (always clicking).
	Uses expected DPS (crit averaged). Returns seconds (0 if ready, math.huge if stuck).
]]
function Formulas.EstimateRebirthEta(profile: any, player: Player?): (number, number, number, number)
	local nextLv = (profile.rebirthLevel or 0) + 1
	local powerCost, coinCost = RebirthConfig.GetCosts(nextLv)
	local currentPower = Formulas.GetTotalPower(profile, player)
	local coins = profile.coins or 0
	local remPower = math.max(0, powerCost - currentPower)
	local remCoins = math.max(0, coinCost - coins)

	if remPower <= 0 and remCoins <= 0 then
		return 0, 0, 0, 0
	end

	local dps = Formulas.GetDPS(profile, player)
	if dps < 0.01 then
		return math.huge, remPower, remCoins, dps
	end

	local tPower = remPower / dps
	local tCoin = 0
	if remCoins > 0 then
		-- rough farm: damage dealt → coins (Loc1-ish ratio × coin mult)
		local coinsPerSec = dps * (RebirthConfig.ETA_COINS_PER_DAMAGE or 0.12) * Formulas.GetCoinMult(profile)
		tCoin = if coinsPerSec > 0.01 then remCoins / coinsPerSec else math.huge
	end

	return math.max(tPower, tCoin), remPower, remCoins, dps
end

function Formulas.Snapshot(profile: any, player: Player?): { [string]: any }
	local power = Formulas.GetTotalPower(profile, player)
	local cps = Formulas.GetCPS(profile)
	local nextLv = (profile.rebirthLevel or 0) + 1
	local etaSec, remPower, remCoins, dpsIdeal = Formulas.EstimateRebirthEta(profile, player)
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
		nextRebirthCost = RebirthConfig.GetPowerCost(nextLv),
		nextRebirthCoinCost = RebirthConfig.GetCoinCost(nextLv),
		rebirthProgress = RebirthConfig.GetProgress(
			power,
			profile.coins or 0,
			nextLv
		),
		rebirthEtaSeconds = etaSec,
		rebirthRemainingDamage = remPower,
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
