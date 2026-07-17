--!strict
--[[
	Combat + logical mob instances.
	Visual models are Studio's job; backend only tracks uid/hp/position/mobId.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local ClickConfig = require(Shared.Config.ClickConfig)
local LocationConfig = require(Shared.Config.LocationConfig)
local WorldConfig = require(Shared.Config.WorldConfig)
local ProfileService = require(script.Parent.ProfileService)
local QuestService = require(script.Parent.QuestService)
local LootService = require(script.Parent.LootService)

local CombatService = {}
CombatService._mobs = {} :: { [string]: any }
CombatService._lastSwing = {} :: { [number]: number }

local function mobUid(): string
	return ProfileService.NewUid()
end

function CombatService.Init()
	Remotes.Event("Swing").OnServerEvent:Connect(function(player, targetMobUid, source)
		CombatService.Swing(player, targetMobUid, source)
	end)

	Remotes.Event("ToggleAutoClicker").OnServerEvent:Connect(function(player)
		CombatService.ToggleAuto(player)
	end)

	-- Debug: respawn dummy for current location
	Remotes.Event("DebugSpawnDummy").OnServerEvent:Connect(function(player)
		CombatService.DebugSpawnDummy(player)
	end)
end

function CombatService.ToggleAuto(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	if not Formulas.IsAutoClickerUnlocked(profile) then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Автокликер ещё не открыт",
			color = "red",
		})
		return
	end
	profile.autoClicker = not profile.autoClicker
	Remotes.Event("Notify"):FireClient(player, {
		text = profile.autoClicker and "Автокликер: ВКЛ" or "Автокликер: ВЫКЛ",
		color = profile.autoClicker and "green" or "red",
	})
	ProfileService.Push(player)
end

function CombatService.SpawnMob(mobId: string, position: Vector3?, extras: any?): string?
	local def = MobConfig.Get(mobId)
	if not def then
		return nil
	end
	local id = mobUid()
	local entry = {
		uid = id,
		mobId = mobId,
		name = def.name,
		tier = def.tier,
		hp = def.hp,
		maxHp = def.hp,
		position = position or Vector3.new(0, 5, 0),
		alive = true,
		respawnAt = 0,
		isBoss = def.isBoss == true,
		isDebug = def.isDebug == true,
		locationId = extras and extras.locationId or def.location,
		zone = extras and extras.zone or def.defaultZone,
		visual = def.visual,
	}
	CombatService._mobs[id] = entry
	return id
end

function CombatService.GetMobsForClient(locationId: number?): { any }
	local list = {}
	for _, m in CombatService._mobs do
		if m.alive then
			if locationId == nil or m.locationId == locationId or m.isDebug then
				table.insert(list, {
					uid = m.uid,
					mobId = m.mobId,
					name = m.name,
					tier = m.tier,
					hp = m.hp,
					maxHp = m.maxHp,
					isBoss = m.isBoss,
					isDebug = m.isDebug,
					locationId = m.locationId,
					zone = m.zone,
					position = { m.position.X, m.position.Y, m.position.Z },
					visual = m.visual,
				})
			end
		end
	end
	return list
end

function CombatService.Swing(player: Player, targetMobUid: string?, source: any?)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local isAuto = source == "auto"
	if isAuto then
		if not profile.autoClicker or not Formulas.IsAutoClickerUnlocked(profile) then
			return
		end
	end

	local now = os.clock()
	local last = CombatService._lastSwing[player.UserId] or 0
	local cd = Formulas.GetSwingCooldown(profile)
	if now - last < cd * 0.90 then
		return
	end
	CombatService._lastSwing[player.UserId] = now

	local locId = profile.currentLocation or 1
	local mob = targetMobUid and CombatService._mobs[targetMobUid] or nil
	if not mob or not mob.alive then
		-- prefer dummy if targeting free-fire, else first alive on location
		local fallback = nil
		local dummy = nil
		for _, m in CombatService._mobs do
			if m.alive then
				if m.isDebug and (m.locationId == locId or m.locationId == 0) then
					dummy = m
				elseif m.locationId == locId and not fallback then
					fallback = m
				end
			end
		end
		mob = fallback or dummy
	end
	if not mob or not mob.alive then
		return
	end

	local damage, isCrit = Formulas.GetHitDamage(profile)
	if isAuto then
		damage *= (ClickConfig.AUTO_DAMAGE_MULT or 1)
	end

	local def = MobConfig.Get(mob.mobId)
	local armor = (def and def.armorFlat) or 0
	damage = math.max(1, damage - armor)

	mob.hp -= damage
	profile.lifetimeDamage += damage
	profile.totalClicks = (profile.totalClicks or 0) + 1

	Remotes.Event("CombatFx"):FireClient(player, {
		type = "hit",
		mobUid = mob.uid,
		mobId = mob.mobId,
		name = mob.name,
		damage = math.floor(damage),
		crit = isCrit,
		hp = math.max(0, mob.hp),
		maxHp = mob.maxHp,
		isDebug = mob.isDebug,
		source = isAuto and "auto" or "manual",
		totalClicks = profile.totalClicks,
	})

	if mob.hp <= 0 then
		CombatService.OnKill(player, profile, mob)
	end

	if not isAuto or (profile.totalClicks % 5 == 0) then
		ProfileService.Push(player)
	end
end

function CombatService.OnKill(player: Player, profile: any, mob: any)
	local def = MobConfig.Get(mob.mobId)
	if not def then
		return
	end

	mob.alive = false
	mob.respawnAt = os.clock() + def.respawnSeconds

	-- Debug dummy: no power/coins/quests/loot
	if def.isDebug then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Dummy down (debug) — respawn soon",
			color = "gold",
		})
		task.delay(def.respawnSeconds, function()
			if CombatService._mobs[mob.uid] then
				mob.hp = def.hp
				mob.maxHp = def.hp
				mob.alive = true
			end
		end)
		ProfileService.Push(player)
		return
	end

	local coinMult = Formulas.GetCoinMult(profile)
	local coins = math.floor(def.coinReward * coinMult)
	profile.coins += coins
	profile.lifetimePower += def.powerReward

	QuestService.OnKill(player, profile, mob.mobId, def.isBoss == true)
	LootService.TryWeaponDrop(player, profile, def)
	LootService.TryPetKey(player, profile)

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("%s | +%d power, +%d coins", def.name, def.powerReward, coins),
		color = "green",
	})

	task.delay(def.respawnSeconds, function()
		if CombatService._mobs[mob.uid] then
			mob.hp = def.hp
			mob.maxHp = def.hp
			mob.alive = true
		end
	end)
end

function CombatService.BootstrapLocation1()
	CombatService.SpawnLocationMobs(1)
end

function CombatService.SpawnLocationMobs(locationId: number)
	local loc = LocationConfig.Get(locationId)
	if not loc then
		return
	end

	for uid, m in CombatService._mobs do
		if m.locationId == locationId then
			CombatService._mobs[uid] = nil
		end
	end

	local function spawnEntry(spawn: any)
		for i = 1, spawn.count do
			local pos = WorldConfig.GetZonePoint(locationId, spawn.zone, i, spawn.count)
			CombatService.SpawnMob(spawn.mobId, pos, {
				locationId = locationId,
				zone = spawn.zone,
			})
		end
	end

	for _, spawn in loc.mobs do
		spawnEntry(spawn)
	end

	if loc.bossId then
		local pos = WorldConfig.GetZonePoint(locationId, "Boss", 1, 1)
		CombatService.SpawnMob(loc.bossId, pos, {
			locationId = locationId,
			zone = "Boss",
		})
	end

	if loc.debugMobs then
		for _, spawn in loc.debugMobs do
			spawnEntry(spawn)
		end
	end

	local count = 0
	for _, m in CombatService._mobs do
		if m.locationId == locationId then
			count += 1
		end
	end
	print(string.format("[Combat] Loc%d spawned %d logical mobs (+debug)", locationId, count))
end

function CombatService.DebugSpawnDummy(player: Player)
	local profile = ProfileService.Get(player)
	local locId = (profile and profile.currentLocation) or 1

	-- remove old dummies on this loc
	for uid, m in CombatService._mobs do
		if m.isDebug and m.locationId == locId then
			CombatService._mobs[uid] = nil
		end
	end

	local pos = WorldConfig.GetZonePoint(locId, "Debug", 1, 1)
	local id = CombatService.SpawnMob("DEBUG_Dummy", pos, {
		locationId = locId,
		zone = "Debug",
	})

	Remotes.Event("Notify"):FireClient(player, {
		text = "DEBUG Dummy spawned: " .. tostring(id),
		color = "gold",
	})
	ProfileService.Push(player)

	-- also push mob list via profile update side-channel
	Remotes.Event("MobsUpdate"):FireClient(player, CombatService.GetMobsForClient(locId))
end

return CombatService
