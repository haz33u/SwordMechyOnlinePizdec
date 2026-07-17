--!strict
--[[
	Sword Masters — BACKEND ONLY
	No UI, no world building. Studio / Studio Agent owns client + map.
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
local QuestService = require(Services.QuestService)
local DungeonService = require(Services.DungeonService)
local LocationService = require(Services.LocationService)
local WorldService = require(Services.WorldService)

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
QuestService.Init()
DungeonService.Init()
LocationService.Init()

-- Logical mobs for location 1 (no 3D models — your map/agent can visualize later)
CombatService.BootstrapLocation1()

Remotes.Function("GetProfile").OnServerInvoke = function(player)
	local profile = ProfileService.Get(player)
	if not profile then
		return nil
	end
	return {
		profile = profile,
		stats = Formulas.Snapshot(profile),
		mobs = CombatService.GetMobsForClient(),
	}
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		ProfileService.ApplyWalkSpeed(player)
		ProfileService.Push(player)
	end)
end)

print("[SwordMasters] backend ready. Remotes under ReplicatedStorage.Remotes")
