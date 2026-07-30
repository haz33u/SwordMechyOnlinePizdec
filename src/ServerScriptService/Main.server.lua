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

-- Kill free-model / toolbox scripts in Workspace ChestServer, PoseTexture, Robux kits...
-- They often run *before* Main; still disable+destroy so they don't re-fire on respawn/stream.
pcall(function()
	local Workspace = game:GetService("Workspace")
	local BAD_NAMES = {
		ChestServer = true,
		ChestClient = true,
		ChestRemotes = true,
		PoseTexture = true,
		TextureConfiguration = true,
		LightConfig = true,
		AuraChest = true,
	}
	local function isBadScript(inst: Instance): boolean
		if not inst:IsA("LuaSourceContainer") then
			return false
		end
		if BAD_NAMES[inst.Name] then
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
	local function kill(inst: Instance)
		if not isBadScript(inst) then
			return
		end
		if inst:IsA("BaseScript") then
			(inst :: BaseScript).Disabled = true
		end
		inst:Destroy()
	end
	for _, desc in Workspace:GetDescendants() do
		kill(desc)
	end
	Workspace.DescendantAdded:Connect(function(desc)
		task.defer(kill, desc)
	end)
end)

local Services = script.Parent:FindFirstChild("Services") or (script.Parent.Parent and script.Parent.Parent:FindFirstChild("Services")) or game:GetService("ServerScriptService"):WaitForChild("Services")
local ProfileService = require(Services:WaitForChild("ProfileService"))
local CombatService = require(Services.CombatService)
local RebirthService = require(Services.RebirthService)
local UpgradeService = require(Services.UpgradeService)
local WeaponService = require(Services.WeaponService)
local PetService = require(Services.PetService)
local AuraService = require(Services.AuraService)
local RelicService = require(Services.RelicService)
local AnomalyService = require(Services.AnomalyService)
local QuestService = require(Services.QuestService)
local DungeonService = require(Services.DungeonService)
local LocationService = require(Services.LocationService)
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
local DebugService = require(Services.DebugService)

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
PetService.Init()
AuraService.Init()
RelicService.Init()
AnomalyService.Init()
QuestService.Init()
-- DungeonService.Init() -- disabled per user request
BattlePassService.Init()
LocationService.Init()
PotionService.Init()
UnlockService.Init()
FerrymanService.Init()
NpcService.Init()
TitleService.Init()
GroupChestService.Init()
DebugService.Init()

-- Spawn mobs for all locations after game starts (Loc1 uses your placed markers; others use fallback or markers if placed)
CombatService.BootstrapAllLocations()

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
