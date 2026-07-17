--!strict
--[[
	Weapon drops: location-matched catalog + tier weights + progression squeeze.

	Flow:
	  1) chance = TierDropChance[tier] * Location.dropChanceMult * (1+luck) [* mob scale]
	  2) roll rarity from TierRarityWeights (Epic+ * highRarityMult on later locs)
	  3) pick random weapon of that rarity on mob.location (not banned, not dropDisabled)
	  4) optional mob.weaponPool = allowlist filter (special bosses)

	Limited never rolls here.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local LootService = {}

local function pickFrom(list: { any }): any?
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
		local banned = profile.bannedWeaponIds[def.id]
		local blocked = allow ~= nil and not allow[def.id]
		if not banned and not blocked then
			table.insert(out, def)
		end
	end
	return out
end

function LootService.TryWeaponDrop(player: Player, profile: any, mobDef: any)
	if not mobDef or mobDef.isDebug then
		return
	end
	-- explicit zero = no weapon loot (dummy / special)
	if mobDef.weaponDropChance == 0 then
		return
	end

	local locationId = mobDef.location or profile.currentLocation or 1
	if locationId < 1 then
		return
	end

	local tier = mobDef.tier or "normal"
	local luck = Formulas.GetLuck(profile)
	local baseChance = WeaponConfig.GetBaseDropChance(tier, locationId)
	-- Optional per-mob scale (1.0 default). Legacy weaponDropChance can boost/cut slightly
	-- if author set it as a relative hint — we treat values > 0 as scale when far from template.
	local scale = mobDef.weaponDropScale or 1
	local chance = baseChance * scale * (1 + luck)
	-- Cap so luck never guarantees every kill on trash
	chance = math.clamp(chance, 0, 0.92)

	if math.random() > chance then
		return
	end

	local rarity = WeaponConfig.RollRarity(tier, locationId)
	if not rarity then
		return
	end

	local pool = filterCandidates(locationId, rarity, profile, mobDef.weaponPool)
	-- Soft fallback: if high rarity empty (banned all), step down one rarity
	if #pool == 0 then
		local idx = WeaponConfig.RarityIndex(rarity)
		for i = idx - 1, 1, -1 do
			local r2 = WeaponConfig.RarityOrder[i]
			if r2 and r2 ~= "Limited" then
				pool = filterCandidates(locationId, r2, profile, mobDef.weaponPool)
				if #pool > 0 then
					rarity = r2
					break
				end
			end
		end
	end

	local def = pickFrom(pool)
	if not def then
		return
	end

	local wuid = ProfileService.NewUid()
	table.insert(profile.weapons, {
		uid = wuid,
		id = def.id,
		enchants = {},
	})

	-- auto equip if strictly better powerMult
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
		text = "Дроп: " .. def.name .. " (" .. def.rarity .. ")",
		color = if def.rarity == "Secret" or def.rarity == "Limited"
			then "gold"
			elseif def.rarity == "Mythic" or def.rarity == "Legendary"
			then "orange"
			else "gold",
	})
end

function LootService.TryPetKey(_player: Player, _profile: any)
	-- skeleton: reserved for key drops
end

return LootService
