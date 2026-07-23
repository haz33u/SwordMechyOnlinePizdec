--!strict
--[[
	Combat + logical mobs + placeholder visuals.
	Killable via ClickDetector (no friend UI required) or Swing remote.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local ClickConfig = require(Shared.Config.ClickConfig)
local LocationConfig = require(Shared.Config.LocationConfig)
local WorldConfig = require(Shared.Config.WorldConfig)
local ProfileService = require(script.Parent.ProfileService)
local QuestService = require(script.Parent.QuestService)
local LootService = require(script.Parent.LootService)
local MobVisualService = require(script.Parent.MobVisualService)
local MobSpawnMarkerService = require(script.Parent.MobSpawnMarkerService)

local CombatService = {}
CombatService._mobs = {} :: { [string]: any }
CombatService._lastSwing = {} :: { [number]: number }
CombatService._autoLock = {} :: { [number]: string }

local function mobUid(): string
	return ProfileService.NewUid()
end

function CombatService.Init()
	MobVisualService.Init(function(player, uid)
		CombatService.Swing(player, uid, "manual")
	end)

	Remotes.Event("Swing").OnServerEvent:Connect(function(player, targetMobUid, source)
		CombatService.Swing(player, targetMobUid, source)
	end)

	Remotes.Event("ToggleAutoClicker").OnServerEvent:Connect(function(player)
		CombatService.ToggleAuto(player)
	end)

	Remotes.Event("DebugSpawnDummy").OnServerEvent:Connect(function(player)
		CombatService.DebugSpawnDummy(player)
	end)

	-- Server-side auto-click loop (works without client UI)
	task.spawn(function()
		while true do
			task.wait(0.05)
			for _, player in Players:GetPlayers() do
				local profile = ProfileService.Get(player)
				if profile and profile.autoClicker and Formulas.IsAutoClickerUnlocked(profile) then
					CombatService.Swing(player, nil, "auto")
				end
			end
		end
	end)
end

function CombatService.ToggleAuto(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	if not Formulas.IsAutoClickerUnlocked(profile) then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Auto-clicker not purchased (manual CPS cap: Loc1=4, max=20)",
			color = "red",
		})
		return
	end
	profile.autoClicker = not profile.autoClicker
	-- No toast for auto on/off (user request — status is on AUTO chip)
	ProfileService.Push(player)
end

function CombatService.SpawnMob(mobId: string, position: Vector3?, extras: any?): string?
	local def = MobConfig.Get(mobId)
	if not def then
		return nil
	end
	local resolvedId = def.id -- canonical (LegacyIdMap applied inside Get)
	local id = mobUid()
	local entry = {
		uid = id,
		mobId = resolvedId,
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
	MobVisualService.Spawn(entry)
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

local function hitRange(isAuto: boolean?): number
	local base = if isAuto then (GameConfig.AUTO_HIT_RANGE or GameConfig.HIT_RANGE or 12) else (GameConfig.HIT_RANGE or 10)
	return base + (GameConfig.HIT_RANGE_EPSILON or 0)
end

--- true if mob is roughly in front of the character (flat look cone).
local function inFrontCone(hrp: BasePart, mobPos: Vector3, coneCos: number): boolean
	local origin = hrp.Position
	local toMob = mobPos - origin
	local flat = Vector3.new(toMob.X, 0, toMob.Z)
	if flat.Magnitude < 0.05 then
		return true -- on top of player
	end
	local look = hrp.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.05 then
		return true
	end
	return flat.Unit:Dot(flatLook.Unit) >= coneCos
end

local function getMobPos(mob: any): Vector3
	if not mob then
		return Vector3.zero
	end
	local model = MobVisualService.GetModel(mob.uid)
	if model and model.PrimaryPart then
		return model.PrimaryPart.Position
	end
	return mob.position or Vector3.zero
end

local function pickTarget(player: Player, targetMobUid: string?, locId: number, isAuto: boolean?): any?
	local maxRange = hitRange(isAuto)
	local coneCos = GameConfig.HIT_CONE_COS
	if type(coneCos) ~= "number" then
		coneCos = 0.35
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end
	local origin = hrp.Position

	-- explicit target (manual click on mob ClickDetector)
	local mob = targetMobUid and CombatService._mobs[targetMobUid] or nil
	if mob and mob.alive then
		local pos = getMobPos(mob)
		if (pos - origin).Magnitude <= maxRange * 1.5 then
			return mob
		end
	end

	-- AUTO-CLICKER Single-Target Lock: focus 100% DPS on current locked target until dead or out of range
	if isAuto then
		local lockedUid = CombatService._autoLock[player.UserId]
		if lockedUid then
			local lockedMob = CombatService._mobs[lockedUid]
			if lockedMob and lockedMob.alive then
				local pos = getMobPos(lockedMob)
				if (pos - origin).Magnitude <= maxRange then
					return lockedMob
				end
			end
		end
	end

	local best = nil
	local bestDist = math.huge

	-- AUTO-CLICKER / Free-aim: 360° radius search around player (nearest mob within maxRange in world space)
	for _, m in CombatService._mobs do
		if m.alive then
			local pos = getMobPos(m)
			local d = (pos - origin).Magnitude
			local inCone = isAuto or inFrontCone(hrp, pos, coneCos)
			if d <= maxRange and inCone then
				if d < bestDist then
					bestDist = d
					best = m
				end
			end
		end
	end

	if isAuto and best then
		CombatService._autoLock[player.UserId] = best.uid
	end

	return best
end

function CombatService.Swing(player: Player, targetMobUid: string?, source: any?)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local isAuto = source == "auto"
	if isAuto then
		if not Formulas.IsAutoClickerUnlocked(profile) then
			return
		end
		-- ensure autoClicker flag is synced to profile
		profile.autoClicker = true
	end

	local now = os.clock()
	local last = CombatService._lastSwing[player.UserId] or 0
	local cd = Formulas.GetSwingCooldown(profile)
	if now - last < cd * 0.90 then
		return
	end

	local locId = profile.currentLocation or 1
	local mob = pickTarget(player, targetMobUid, locId, isAuto)
	if not mob or not mob.alive then
		-- Air Click (clicking empty space or no target in range): still grants Power gain!
		CombatService._lastSwing[player.UserId] = now
		local clickGain = Formulas.GetClickPowerGain(profile, player)
		profile.lifetimePower = (profile.lifetimePower or 0) + clickGain
		profile.totalClicks = (profile.totalClicks or 0) + 1
		QuestService.OnClick(profile)
		if not isAuto or (profile.totalClicks % 2 == 0) then
			ProfileService.Push(player)
		end
		return
	end

	-- Melee range (manual + auto). Cone already applied for free-aim/auto.
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local mobPos = getMobPos(mob)
	local dist = (mobPos - hrp.Position).Magnitude
	if dist > hitRange(isAuto) then
		-- Target too far: treat as Air Click
		CombatService._lastSwing[player.UserId] = now
		local clickGain = Formulas.GetClickPowerGain(profile, player)
		profile.lifetimePower = (profile.lifetimePower or 0) + clickGain
		profile.totalClicks = (profile.totalClicks or 0) + 1
		QuestService.OnClick(profile)
		if not isAuto or (profile.totalClicks % 2 == 0) then
			ProfileService.Push(player)
		end
		return
	end

	-- Only record swing cooldown timestamp once a valid hit target is confirmed in range!
	CombatService._lastSwing[player.UserId] = now

	local damage, isCrit, isMultiCrit = Formulas.GetHitDamage(profile, player)
	if isAuto then
		damage *= (ClickConfig.AUTO_DAMAGE_MULT or 1)
	end

	local def = MobConfig.Get(mob.mobId)
	local armor = (def and def.armorFlat) or 0
	damage = math.max(1, damage - armor)

	mob.hp -= damage
	local hitGain = Formulas.GetClickPowerGain(profile, player)
	profile.lifetimePower = (profile.lifetimePower or 0) + hitGain
	profile.lifetimeDamage += damage
	profile.totalClicks = (profile.totalClicks or 0) + 1
	QuestService.OnClick(profile)

	MobVisualService.UpdateHp(mob)

	Remotes.Event("CombatFx"):FireClient(player, {
		type = "hit",
		mobUid = mob.uid,
		mobId = mob.mobId,
		name = mob.name,
		damage = math.floor(damage),
		crit = isCrit,
		multiCrit = isMultiCrit == true,
		hp = math.max(0, mob.hp),
		maxHp = mob.maxHp,
		isDebug = mob.isDebug,
		source = isAuto and "auto" or "manual",
		totalClicks = profile.totalClicks,
	})

	if mob.hp <= 0 then
		CombatService.OnKill(player, profile, mob)
	end

	if not isAuto or (profile.totalClicks % 2 == 0) then
		ProfileService.Push(player)
	end
end

function CombatService.OnKill(player: Player, profile: any, mob: any)
	local def = MobConfig.Get(mob.mobId)
	if not def then
		return
	end

	mob.alive = false
	local spawnDelay = def.respawnSeconds * Formulas.GetAnomalySpawnMult()
	mob.respawnAt = os.clock() + spawnDelay
	MobVisualService.SetAlive(mob, false)

	if def.isDebug then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Dummy killed (debug) — respawn",
			color = "gold",
		})
		task.delay(spawnDelay, function()
			if CombatService._mobs[mob.uid] then
				local hpM = Formulas.GetAnomalyMobHpMult()
				mob.hp = def.hp * hpM
				mob.maxHp = def.hp * hpM
				mob.alive = true
				MobVisualService.SetAlive(mob, true)
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
	LootService.TryBossDust(player, profile, def)
	LootService.TryCaseKeys(player, profile, def)

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("%s ✕  +%d power  +%d coins", def.name, def.powerReward, coins),
		color = "green",
	})

	task.delay(spawnDelay, function()
		if CombatService._mobs[mob.uid] then
			local hpM = Formulas.GetAnomalyMobHpMult()
			mob.hp = def.hp * hpM
			mob.maxHp = def.hp * hpM
			mob.alive = true
			MobVisualService.SetAlive(mob, true)
		end
	end)

	ProfileService.Push(player)
end

function CombatService.BootstrapLocation1()
	CombatService.SpawnLocationMobs(1)
end

function CombatService.SpawnLocationMobs(locationId: number)
	local loc = LocationConfig.Get(locationId)
	if not loc then
		return
	end

	-- despawn old live combat models
	for uid, m in CombatService._mobs do
		if m.locationId == locationId then
			MobVisualService.Despawn(uid)
			CombatService._mobs[uid] = nil
		end
	end

	-- Prefer EDIT-MODE markers you placed under LocXX.MobSpawns
	local markers = MobSpawnMarkerService.Collect(locationId)
	if #markers > 0 then
		for _, pt in markers do
			CombatService.SpawnMob(pt.mobId, pt.position, {
				locationId = locationId,
				zone = pt.zone,
			})
		end
		print(string.format(
			"[Combat] Loc%d: %d mobs from Studio markers (MobSpawns)",
			locationId,
			#markers
		))
		return
	end

	-- Fallback: math rings from LocationConfig (no markers in Place yet)
	warn(string.format(
		"[Combat] Loc%d: no MobSpawns markers — using config fallback. Place markers in Edit for control.",
		locationId
	))

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
	print(string.format("[Combat] Loc%d: %d mobs (fallback math)", locationId, count))
end

function CombatService.DebugSpawnDummy(player: Player)
	local profile = ProfileService.Get(player)
	local locId = (profile and profile.currentLocation) or 1

	for uid, m in CombatService._mobs do
		if m.isDebug and m.locationId == locId then
			MobVisualService.Despawn(uid)
			CombatService._mobs[uid] = nil
		end
	end

	local pos = WorldConfig.GetZonePoint(locId, "Debug", 1, 1)
	-- if player has character, spawn dummy in front of them
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		pos = hrp.Position + hrp.CFrame.LookVector * 10 + Vector3.new(0, 0, 0)
		pos = Vector3.new(pos.X, WorldConfig.FLOOR_Y + 4, pos.Z)
	end

	local id = CombatService.SpawnMob("DEBUG_Dummy", pos, {
		locationId = locId,
		zone = "Debug",
	})

	Remotes.Event("Notify"):FireClient(player, {
		text = "DEBUG Dummy: " .. tostring(id),
		color = "gold",
	})
	ProfileService.Push(player)
	Remotes.Event("MobsUpdate"):FireClient(player, CombatService.GetMobsForClient(locId))
end

return CombatService
