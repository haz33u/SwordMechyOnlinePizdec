--!strict

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local ClickConfig = require(Shared.Config.ClickConfig)
local ProfileService = require(script.Parent.ProfileService)
local QuestService = require(script.Parent.QuestService)
local LootService = require(script.Parent.LootService)

local CombatService = {}
CombatService._mobs = {} :: { [string]: any } -- mobUid -> state
CombatService._lastSwing = {} :: { [number]: number }

local function mobUid(): string
	return ProfileService.NewUid()
end

function CombatService.Init()
	-- source: "manual" | "auto" (both use same CPS limit)
	Remotes.Event("Swing").OnServerEvent:Connect(function(player, targetMobUid, source)
		CombatService.Swing(player, targetMobUid, source)
	end)

	Remotes.Event("ToggleAutoClicker").OnServerEvent:Connect(function(player)
		CombatService.ToggleAuto(player)
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

function CombatService.SpawnMob(mobId: string, position: Vector3?): string?
	local def = MobConfig.Get(mobId)
	if not def then
		return nil
	end
	local id = mobUid()
	CombatService._mobs[id] = {
		uid = id,
		mobId = mobId,
		hp = def.hp,
		maxHp = def.hp,
		position = position or Vector3.new(0, 5, 0),
		alive = true,
		respawnAt = 0,
	}
	return id
end

function CombatService.GetMobsForClient(): { any }
	local list = {}
	for _, m in CombatService._mobs do
		if m.alive then
			table.insert(list, {
				uid = m.uid,
				mobId = m.mobId,
				hp = m.hp,
				maxHp = m.maxHp,
				position = { m.position.X, m.position.Y, m.position.Z },
			})
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

	-- CORE rate limit = CPS (same for manual & auto — no cheat advantage)
	local now = os.clock()
	local last = CombatService._lastSwing[player.UserId] or 0
	local cd = Formulas.GetSwingCooldown(profile)
	if now - last < cd * 0.90 then
		return
	end
	CombatService._lastSwing[player.UserId] = now

	-- pick target
	local mob = targetMobUid and CombatService._mobs[targetMobUid] or nil
	if not mob or not mob.alive then
		for _, m in CombatService._mobs do
			if m.alive then
				mob = m
				break
			end
		end
	end
	if not mob or not mob.alive then
		return
	end

	local damage, isCrit = Formulas.GetHitDamage(profile)
	if isAuto then
		damage *= (ClickConfig.AUTO_DAMAGE_MULT or 1)
	end

	mob.hp -= damage
	profile.lifetimeDamage += damage
	profile.totalClicks = (profile.totalClicks or 0) + 1 -- CORE: +1 click

	Remotes.Event("CombatFx"):FireClient(player, {
		type = "hit",
		mobUid = mob.uid,
		damage = math.floor(damage),
		crit = isCrit,
		hp = math.max(0, mob.hp),
		maxHp = mob.maxHp,
		source = isAuto and "auto" or "manual",
		totalClicks = profile.totalClicks,
	})

	if mob.hp <= 0 then
		CombatService.OnKill(player, profile, mob)
	end

	-- push less often for auto to reduce net load (every 5 clicks or on kill)
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

	local coinMult = Formulas.GetCoinMult(profile)
	local coins = math.floor(def.coinReward * coinMult)
	profile.coins += coins
	profile.lifetimePower += def.powerReward

	QuestService.OnKill(player, profile, mob.mobId, def.isBoss == true)
	LootService.TryWeaponDrop(player, profile, def)
	LootService.TryPetKey(player, profile) -- small chance free case open token later; skeleton: chance open

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("+%d power, +%d coins", def.powerReward, coins),
		color = "green",
	})

	-- respawn
	task.delay(def.respawnSeconds, function()
		if CombatService._mobs[mob.uid] then
			mob.hp = def.hp
			mob.alive = true
		end
	end)
end

function CombatService.BootstrapLocation1()
	CombatService.SpawnLocationMobs(1)
end

function CombatService.SpawnLocationMobs(locationId: number)
	local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local LocationConfig = require(Shared.Config.LocationConfig)
	local WorldConfig = require(Shared.Config.WorldConfig)

	local loc = LocationConfig.Get(locationId)
	if not loc then
		return
	end

	-- clear previous logic mobs for this location
	for uid, m in CombatService._mobs do
		if m.locationId == locationId then
			CombatService._mobs[uid] = nil
		end
	end

	for _, spawn in loc.mobs do
		for i = 1, spawn.count do
			local pos = WorldConfig.GetZonePoint(locationId, spawn.zone, i, spawn.count)
			local id = CombatService.SpawnMob(spawn.mobId, pos)
			if id and CombatService._mobs[id] then
				CombatService._mobs[id].locationId = locationId
				CombatService._mobs[id].zone = spawn.zone
			end
		end
	end

	if loc.bossId then
		local pos = WorldConfig.GetZonePoint(locationId, "Boss", 1, 1)
		local id = CombatService.SpawnMob(loc.bossId, pos)
		if id and CombatService._mobs[id] then
			CombatService._mobs[id].locationId = locationId
			CombatService._mobs[id].zone = "Boss"
		end
	end
end

return CombatService
