--!strict
--[[
	Sword Masters — gameplay backend + placeholder mobs.
	Friend owns full UI. We spawn simple "нуб" placeholders in Workspace.Mobs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Formulas)

local Services = script.Parent:WaitForChild("Services")
local ProfileService = require(Services.ProfileService)
local CombatService = require(Services.CombatService)
local RebirthService = require(Services.RebirthService)
local UpgradeService = require(Services.UpgradeService)
local WeaponService = require(Services.WeaponService)
local PetService = require(Services.PetService)
local AuraService = require(Services.AuraService)
local RelicService = require(Services.RelicService)
local QuestService = require(Services.QuestService)
local DungeonService = require(Services.DungeonService)
local LocationService = require(Services.LocationService)
local WorldService = require(Services.WorldService)
local UnlockService = require(Services.UnlockService)
local FerrymanService = require(Services.FerrymanService)
local DebugService = require(Services.DebugService)

print("[SwordMasters]", GameConfig.VERSION, "backend boot...")

Remotes.InitAll()
WorldService.Init()
ProfileService.Init()
CombatService.Init()
RebirthService.Init()
UpgradeService.Init()
WeaponService.Init()
PetService.Init()
AuraService.Init()
RelicService.Init()
QuestService.Init()
DungeonService.Init()
LocationService.Init()
UnlockService.Init()
FerrymanService.Init()
DebugService.Init()

-- Loc1 mobs + DEBUG dummy as killable placeholders
CombatService.BootstrapLocation1()

Remotes.Function("GetProfile").OnServerInvoke = function(player)
	local profile = ProfileService.Get(player)
	if not profile then
		return nil
	end
	local locId = profile.currentLocation or 1
	return {
		profile = profile,
		stats = Formulas.Snapshot(profile),
		mobs = CombatService.GetMobsForClient(locId),
	}
end

--- Public stats for inventory Profile search (@username). Online players only.
Remotes.Function("GetPublicProfile").OnServerInvoke = function(_player, usernameRaw)
	if type(usernameRaw) ~= "string" then
		return { ok = false, error = "Enter a username" }
	end
	local name = string.gsub(usernameRaw, "^%s*@?", "")
	name = string.gsub(name, "%s+$", "")
	if name == "" or #name > 40 then
		return { ok = false, error = "Enter a username" }
	end
	local target: Player? = nil
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == string.lower(name) or string.lower(p.DisplayName) == string.lower(name) then
			target = p
			break
		end
	end
	if not target then
		-- resolve id then match online session
		local okId, userId = pcall(function()
			return Players:GetUserIdFromNameAsync(name)
		end)
		if okId and type(userId) == "number" then
			target = Players:GetPlayerByUserId(userId)
		end
	end
	if not target then
		return { ok = false, error = "Player not in this server" }
	end
	local profile = ProfileService.Get(target)
	if not profile then
		return { ok = false, error = "Profile not loaded" }
	end
	return {
		ok = true,
		userId = target.UserId,
		name = target.Name,
		displayName = target.DisplayName,
		stats = Formulas.Snapshot(profile),
		currentLocation = profile.currentLocation or 1,
	}
end

Remotes.Function("GetMobCatalog").OnServerInvoke = function(_player)
	local MobConfig = require(Shared.Config.MobConfig)
	return MobConfig.GetPublicCatalog()
end

Remotes.Function("GetMobDropInfo").OnServerInvoke = function(player, mobIdOrUid)
	local MobConfig = require(Shared.Config.MobConfig)
	local LootService = require(Services.LootService)
	local CombatService = require(Services.CombatService)
	local ProfileService = require(Services.ProfileService)

	local mobId = mobIdOrUid
	if type(mobIdOrUid) == "string" then
		-- allow live uid from Workspace.Mobs attribute
		local live = CombatService._mobs and CombatService._mobs[mobIdOrUid]
		if live then
			mobId = live.mobId
		end
	end
	local def = MobConfig.Get(mobId)
	if not def then
		return nil
	end
	return LootService.BuildMobInspect(def, ProfileService.Get(player))
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		ProfileService.ApplyWalkSpeed(player)
		ProfileService.Push(player)
	end)
end)

print("[SwordMasters] ready | click mobs in Workspace.Mobs | auto if profile.autoClicker")
