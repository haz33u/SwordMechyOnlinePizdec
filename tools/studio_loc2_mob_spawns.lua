--[[
	STUDIO COMMAND BAR (Edit Mode) — paste & run once per location, then Save place.
	Creates/replaces neon spawn markers for Loc2 under Workspace.World.Locations.Loc02.MobSpawns
	using fallback ring math (or you can add your own custom positions).
	After running: Save Place → test in Play by traveling to Loc2.
]]

print("[studio_loc2_mob_spawns] Running... this will create markers for Loc2")

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)
local WorldConfig = require(Shared.Config.WorldConfig)
local LocationConfig = require(Shared.Config.LocationConfig)

local locId = 2
local locFolder = WorldConfig.GetLocationsFolder() or Workspace:FindFirstChild("World"):WaitForChild("Locations"):WaitForChild(string.format("Loc%02d", locId))

local spawnsFolder = locFolder:FindFirstChild("MobSpawns") or Instance.new("Folder")
spawnsFolder.Name = "MobSpawns"
spawnsFolder.Parent = locFolder

print("[Loc2] Markers folder ready: " .. spawnsFolder:GetFullName())

local locDef = LocationConfig.Get(locId)
if not locDef then
	print("[Loc2] ERROR: No LocationConfig for Loc2!")
	return
end

local function makeMarker(mobId: string, zone: string, index: number, total: number)
	local pos = WorldConfig.GetZonePoint(locId, zone, index, total)
	local p = Instance.new("Part")
	p.Name = string.format("%s_%02d", mobId, index)
	p.Size = Vector3.new(4, 0.5, 4)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(0, 255, 120)
	p.Transparency = 0.4
	p.CFrame = CFrame.new(pos)
	p:SetAttribute("MobId", mobId)
	p:SetAttribute("Zone", zone)
	p:SetAttribute("IsSpawnMarker", true)
	p.Parent = spawnsFolder
	print(string.format("[Loc2] Created marker: %s (MobId=%s, Zone=%s, Pos=%.0f,%.0f,%.0f)", p.Name, mobId, zone, pos.X, pos.Y, pos.Z))
	return p
end

local function spawnEntry(spawn: any)
	for i = 1, spawn.count do
		makeMarker(spawn.mobId, spawn.zone, i, spawn.count)
	end
end

-- Spawn from LocationConfig (fallback rings)
for _, spawn in locDef.mobs do
	spawnEntry(spawn)
end

if locDef.bossId then
	makeMarker(locDef.bossId, "Boss", 1, 1)
end

print(string.format("[Loc2] Done! %d markers created. Save Place now.", #spawnsFolder:GetChildren()))
print("Test in Play: set location 2 and check if mobs spawn (use MobVisualService or just click them).")
