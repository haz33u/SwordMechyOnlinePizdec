--!strict
--[[
	Collection Index / Bestiary / Catalog bonuses.

	Discovering each unique weapon, mob, or pet grants small permanent global bonuses.
	100% completion of a location gives a larger bonus.
]]

local WeaponConfig = require(script.Parent.WeaponConfig)
local MobConfig = require(script.Parent.MobConfig)
local PetConfig = require(script.Parent.PetConfig)

local IndexConfig = {
	BONUSES = {
		weapon = {
			perEntry = { damagePct = 0.5 },
			perLocationCompletion = { damagePct = 5 },
		},
		mob = {
			perEntry = { coinPct = 0.2 },
			perLocationCompletion = { coinPct = 3 },
		},
		pet = {
			perEntry = { luckPct = 0.3 },
			perLocationCompletion = { luckPct = 4 },
		},
	},
}

function IndexConfig.GetWeaponIndexBonuses(indexData: { [string]: boolean }?): (number, number)
	if not indexData then
		return 0, 0
	end
	local entries = 0
	local locationsCompleted = 0
	local byLocation: { [number]: { total: number, found: number } } = {}

	for id, found in indexData do
		if found then
			entries += 1
			local def = WeaponConfig.Get(id)
			if def then
				local loc = def.location
				byLocation[loc] = byLocation[loc] or { total = 0, found = 0 }
				byLocation[loc].found += 1
			end
		end
	end

	for _, def in WeaponConfig.Weapons do
		if not def.dropDisabled then
			local loc = def.location
			byLocation[loc] = byLocation[loc] or { total = 0, found = 0 }
			byLocation[loc].total += 1
		end
	end

	for _, counts in byLocation do
		if counts.found >= counts.total and counts.total > 0 then
			locationsCompleted += 1
		end
	end

	local perEntry = IndexConfig.BONUSES.weapon.perEntry.damagePct or 0
	local perLoc = IndexConfig.BONUSES.weapon.perLocationCompletion.damagePct or 0
	return entries * perEntry, locationsCompleted * perLoc
end

function IndexConfig.GetMobIndexBonuses(indexData: { [string]: boolean }?): (number, number)
	if not indexData then
		return 0, 0
	end
	local entries = 0
	local locationsCompleted = 0
	local byLocation: { [number]: { total: number, found: number } } = {}

	for id, found in indexData do
		if found then
			entries += 1
			local def = MobConfig.Get(id)
			if def and def.location > 0 then
				local loc = def.location
				byLocation[loc] = byLocation[loc] or { total = 0, found = 0 }
				byLocation[loc].found += 1
			end
		end
	end

	for _, def in MobConfig.Mobs do
		if def.location > 0 and not def.isDebug then
			local loc = def.location
			byLocation[loc] = byLocation[loc] or { total = 0, found = 0 }
			byLocation[loc].total += 1
		end
	end

	for _, counts in byLocation do
		if counts.found >= counts.total and counts.total > 0 then
			locationsCompleted += 1
		end
	end

	local perEntry = IndexConfig.BONUSES.mob.perEntry.coinPct or 0
	local perLoc = IndexConfig.BONUSES.mob.perLocationCompletion.coinPct or 0
	return entries * perEntry, locationsCompleted * perLoc
end

function IndexConfig.GetPetIndexBonuses(indexData: { [string]: boolean }?): (number, number)
	if not indexData then
		return 0, 0
	end
	local entries = 0
	local locationsCompleted = 0
	local byLocation: { [number]: { total: number, found: number } } = {}

	for id, found in indexData do
		if found then
			entries += 1
			local def = PetConfig.Get(id)
			if def then
				local loc = def.location or 1
				byLocation[loc] = byLocation[loc] or { total = 0, found = 0 }
				byLocation[loc].found += 1
			end
		end
	end

	for _, def in PetConfig.Pets do
		if not def.limited then
			local loc = def.location or 1
			byLocation[loc] = byLocation[loc] or { total = 0, found = 0 }
			byLocation[loc].total += 1
		end
	end

	for _, counts in byLocation do
		if counts.found >= counts.total and counts.total > 0 then
			locationsCompleted += 1
		end
	end

	local perEntry = IndexConfig.BONUSES.pet.perEntry.luckPct or 0
	local perLoc = IndexConfig.BONUSES.pet.perLocationCompletion.luckPct or 0
	return entries * perEntry, locationsCompleted * perLoc
end

return IndexConfig