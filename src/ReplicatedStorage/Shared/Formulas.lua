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
	local off = findWeapon(profile, profile.equippedOffhand)
	local mult = 1
	if main then
		local def = WeaponConfig.Get(main.id)
		if def then
			mult = def.powerMult
		end
	end
	if off then
		local def = WeaponConfig.Get(off.id)
		if def then
			mult += def.powerMult * 0.5 -- offhand 50%
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
	addFrom(profile.equippedOffhand)
	return pools
end

function Formulas.GetPetPowerPct(profile: any): number
	local total = 0
	for _, uid in profile.petTeam do
		for _, pet in profile.pets do
			if pet.uid == uid then
				local def = PetConfig.Get(pet.id)
				if def then
					local levelFactor = 1 + PetConfig.LEVEL_POWER_PER * math.max(0, pet.level - 1)
					total += def.powerPct * levelFactor
					total += sumEnchantStat(pet.enchants, "power")
				end
				break
			end
		end
	end
	return total
end

function Formulas.GetPetCoinPct(profile: any): number
	local total = 0
	for _, uid in profile.petTeam do
		for _, pet in profile.pets do
			if pet.uid == uid then
				local def = PetConfig.Get(pet.id)
				if def then
					total += def.coinPct
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

	local rebirthMult = profile.rebirthMult or 1
	if (profile.rebirthLevel or 0) > 0 and rebirthMult <= 1 then
		rebirthMult = RebirthConfig.GetMultAfter(profile.rebirthLevel)
	end

	local weaponMult = Formulas.GetWeaponPowerMult(profile)
	local ench = Formulas.GetEnchantPools(profile)
	local petPct = Formulas.GetPetPowerPct(profile)
	local auraP, auraD = Formulas.GetAuraPct(profile)
	local relicP, relicD = Formulas.GetRelicPct(profile)

	local upgradePowerLvl = Formulas.GetUpgradeLevel(profile, "Power")
	local upgradePowerPct = upgradePowerLvl * (UpgradeConfig.Defs.Power.effectPerLevel * 100)

	-- percent pools stack additively then apply as mult
	local powerPct = ench.power + petPct + auraP + relicP + upgradePowerPct
	local damagePct = ench.damage + auraD + relicD

	local total = base
		* rebirthMult
		* weaponMult
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
					speedPct += def.speedPct
				end
			end
		end
	end
	return speedPct
end

function Formulas.GetSwingCooldown(profile: any): number
	local speedPct = Formulas.GetAttackSpeedPercent(profile)
	local cd: number
	if speedPct >= 0 then
		cd = GameConfig.BASE_SWING_COOLDOWN / (1 + speedPct / 100)
	else
		cd = GameConfig.BASE_SWING_COOLDOWN * (1 + math.abs(speedPct) / 100)
	end
	-- clamp by CPS caps
	local minCd = 1 / ClickConfig.MAX_CPS
	local maxCd = 1 / ClickConfig.MIN_CPS
	return math.clamp(cd, minCd, maxCd)
end

--[[
	CPS = clicks per second = core farming rate.
	Max theoretical attacks/sec the server will accept.
]]
function Formulas.GetCPS(profile: any): number
	local cd = Formulas.GetSwingCooldown(profile)
	local cps = 1 / cd
	return math.clamp(cps, ClickConfig.MIN_CPS, ClickConfig.MAX_CPS)
end

function Formulas.GetDPS(profile: any): number
	return Formulas.GetTotalPower(profile) * Formulas.GetCPS(profile)
end

function Formulas.IsAutoClickerUnlocked(profile: any): boolean
	if ClickConfig.AUTO_UNLOCKED_BY_DEFAULT then
		return true
	end
	if (profile.rebirthLevel or 0) >= (ClickConfig.AUTO_UNLOCK_REBIRTH or 0) then
		return true
	end
	return profile.autoClickerUnlocked == true
end

function Formulas.GetCritChance(profile: any): number
	local ench = Formulas.GetEnchantPools(profile)
	local lvl = Formulas.GetUpgradeLevel(profile, "CritChance")
	return math.clamp(lvl * 0.01 + ench.crit / 100, 0, 0.85)
end

function Formulas.GetHitDamage(profile: any): (number, boolean)
	local power = Formulas.GetTotalPower(profile)
	local crit = Formulas.GetCritChance(profile)
	local isCrit = math.random() < crit
	local dmg = power
	if isCrit then
		dmg *= 2
	end
	return dmg, isCrit
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

function Formulas.Snapshot(profile: any): { [string]: any }
	local power = Formulas.GetTotalPower(profile)
	local cps = Formulas.GetCPS(profile)
	return {
		totalPower = power,
		cps = cps,
		dps = power * cps,
		damagePerClick = power,
		swingCd = Formulas.GetSwingCooldown(profile),
		attackSpeedPct = Formulas.GetAttackSpeedPercent(profile),
		crit = Formulas.GetCritChance(profile),
		coinMult = Formulas.GetCoinMult(profile),
		luck = Formulas.GetLuck(profile),
		walkSpeed = Formulas.GetWalkSpeed(profile),
		rebirthLevel = profile.rebirthLevel,
		rebirthMult = profile.rebirthMult,
		nextRebirthCost = RebirthConfig.GetCost((profile.rebirthLevel or 0) + 1),
		lifetimeDamage = profile.lifetimeDamage,
		totalClicks = profile.totalClicks or 0,
		coins = profile.coins,
		petSlots = profile.petSlots,
		location = profile.currentLocation,
		autoClicker = profile.autoClicker == true,
		autoClickerUnlocked = Formulas.IsAutoClickerUnlocked(profile),
	}
end

return Formulas
