--!strict
--[[
	Sword Masters — server bootstrap (skeleton)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local GameConfig = require(Shared.Config.GameConfig)

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

print("[SwordMasters]", GameConfig.VERSION, "booting...")

Remotes.InitAll()

-- World first (islands 1–18 placeholders)
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

CombatService.BootstrapLocation1()

Remotes.Function("GetProfile").OnServerInvoke = function(player)
	local profile = ProfileService.Get(player)
	if not profile then
		return nil
	end
	local Formulas = require(Shared.Formulas)
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

print("[SwordMasters] ready. World 18 islands + Loc1 mobs. See docs/WORLD_SETUP.md")
