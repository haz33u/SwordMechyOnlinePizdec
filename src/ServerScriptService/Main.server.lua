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

-- Kill free-model / toolbox scripts in Workspace and UI (Constant, cTextureManager, Credits popup, etc.).
-- They often run *before* Main; still disable+destroy so they don't re-fire on respawn/stream.
pcall(function()
	local Workspace = game:GetService("Workspace")
	local StarterGui = game:GetService("StarterGui")
	local StarterPlayer = game:GetService("StarterPlayer")
	local Players = game:GetService("Players")

	local BAD_SCRIPT_NAMES = {
		ChestServer = true,
		ChestClient = true,
		ChestRemotes = true,
		PoseTexture = true,
		TextureConfiguration = true,
		LightConfig = true,
		AuraChest = true,
		Constant = true,
		cTextureManager = true,
		CoreTextureSystem = true,
		HttpEnabled = true,
		AntiIpLogger = true,
		IpLogger = true,
	}
	local BAD_GUI_NAMES = {
		Credits = true,
		Error501 = true,
		Error = true,
	}

	local function isBadScript(inst: Instance): boolean
		if not inst:IsA("LuaSourceContainer") then
			return false
		end
		if BAD_SCRIPT_NAMES[inst.Name] then
			return true
		end
		-- Free-model Robux kits spam MarketplaceService 403
		local p = inst.Parent
		while p and p ~= Workspace do
			local n = string.lower(p.Name)
			if string.find(n, "robux", 1, true) then
				return true
			end
			p = p.Parent
		end
		return false
	end

	local function isBadGui(inst: Instance): boolean
		if not (inst:IsA("ScreenGui") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui")) then
			return false
		end
		return BAD_GUI_NAMES[inst.Name] == true
	end

	local function kill(inst: Instance)
		if isBadScript(inst) then
			if inst:IsA("BaseScript") then
				(inst :: BaseScript).Disabled = true
			end
			inst:Destroy()
		elseif isBadGui(inst) then
			inst:Destroy()
		end
	end

	local function scrub(root: Instance)
		for _, desc in root:GetDescendants() do
			kill(desc)
		end
		root.DescendantAdded:Connect(kill)
	end

	scrub(Workspace)
	scrub(StarterGui)
	scrub(StarterPlayer)

	for _, plr in Players:GetPlayers() do
		if plr:FindFirstChild("PlayerGui") then
			scrub(plr.PlayerGui)
		end
	end
	Players.PlayerAdded:Connect(function(plr)
		local pg = plr:WaitForChild("PlayerGui", 10)
		if pg then
			scrub(pg)
		end
	end)
end)

local Services = script.Parent:FindFirstChild("Services") or (script.Parent.Parent and script.Parent.Parent:FindFirstChild("Services")) or game:GetService("ServerScriptService"):WaitForChild("Services")
local ProfileService = require(Services:WaitForChild("ProfileService"))
local CombatService = require(Services.CombatService)
local MobSpawnMarkerService = require(Services.MobSpawnMarkerService)
local RebirthService = require(Services.RebirthService)
local UpgradeService = require(Services.UpgradeService)
local WeaponService = require(Services.WeaponService)
local EnchantService = require(Services.EnchantService)
local PetService = require(Services.PetService)
local AuraService = require(Services.AuraService)
local RelicService = require(Services.RelicService)
local AnomalyService = require(Services.AnomalyService)
local QuestService = require(Services.QuestService)
local DungeonService = require(Services.DungeonService)
local LocationService = require(Services.LocationService)
local DoorService = require(Services.DoorService)
local OfflineFarmService = require(Services.OfflineFarmService)
local WorldService = require(Services.WorldService)
local WorldBuilderService = require(Services.WorldBuilderService)
local UnlockService = require(Services.UnlockService)
local FerrymanService = require(Services.FerrymanService)
local PotionService = require(Services.PotionService)
local FriendService = require(Services.FriendService)
local TalentTreeService = require(Services.TalentTreeService)
local NpcService = require(Services.NpcService)
local BattlePassService = require(Services.BattlePassService)
local TitleService = require(Services.TitleService)
local GroupChestService = require(Services.GroupChestService)
local AntiCheatService = require(Services.AntiCheatService)
local PrestigeService = require(Services.PrestigeService)
local PurchaseService = require(Services.PurchaseService)
local DailyRewardService = require(Services.DailyRewardService)
local ShutdownService = require(Services.ShutdownService)
local DebugService = require(Services.DebugService)
local StrayPetModelService = require(Services.StrayPetModelService)

print("[SwordMasters]", GameConfig.VERSION, "backend boot...")

Remotes.InitAll()
-- WorldBuilderService.Init() -- disabled: using Studio custom map
WorldService.Init()
ProfileService.Init()
FriendService.Init()
CombatService.Init()
RebirthService.Init()
UpgradeService.Init()
TalentTreeService.Init()
WeaponService.Init()
EnchantService.Init()
PetService.Init()
AuraService.Init()
RelicService.Init()
AnomalyService.Init()
QuestService.Init()
-- DungeonService.Init() -- disabled per user request
BattlePassService.Init()
LocationService.Init()
DoorService.Init()
OfflineFarmService.Init()
PotionService.Init()
UnlockService.Init()
FerrymanService.Init()
NpcService.Init()
TitleService.Init()
GroupChestService.Init()
AntiCheatService.Init()
PrestigeService.Init()
PurchaseService.Init()
DailyRewardService.Init()
ShutdownService.Init()
DebugService.Init()
-- Before mobs spawn: clear leftover generator output from the Workspace root so
-- players never see unowned pet models standing around the map.
StrayPetModelService.Init()

-- Ensure Studio spawn markers exist for all active locations, then spawn mobs.
-- Markers are created only when the folder is empty; existing Art placements are never overwritten.
local LocationConfig = require(Shared.Config.LocationConfig)
for locId = 1, 7 do
	local loc = LocationConfig.Get(locId)
	if loc then
		MobSpawnMarkerService.EnsureDefaultMarkers(locId, loc.mobs, loc.bossId, loc.debugMobs)
	end
	CombatService.SpawnLocationMobs(locId)
end

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
