--!nocheck
--[[
	STUDIO COMMAND BAR (Edit mode) — paste ALL, run once, then Save place.
	This is NOT a Rojo ModuleScript (lives in /tools only).

	Creates:
	  Workspace.World.Locations.Loc01.MobSpawns  (drag markers freely)
	  Workspace.World.Locations.Loc01.PlayerSpawn

	Loc1 roster (matches LocationConfig / MobConfig):
	  Zone A — L1_Slime          Goblin (T1 green)
	  Zone B — L1_Skeleton       Dark Goblin (T2 blue)
	  Zone C — L1_GoblinWarrior  Goblin Warrior (T3)
	  Zone D — L1_Knight         Goblin Scout (T4 elite)
	  Boss   — L1_Boss           Forest Guardian (move to portal / end)

	Play: CombatService reads Attribute MobId on markers.
]]

local Workspace = game:GetService("Workspace")

local ZONE_CONFIG = {
	{
		mobId = "L1_Slime",
		zone = "A",
		radius = 28,
		count = 12,
		color = Color3.fromRGB(88, 214, 141),
		label = "T1 Goblin",
	},
	{
		mobId = "L1_Skeleton",
		zone = "B",
		radius = 48,
		count = 8,
		color = Color3.fromRGB(93, 173, 226),
		label = "T2 Dark Goblin",
	},
	{
		mobId = "L1_GoblinWarrior",
		zone = "C",
		radius = 72,
		count = 5,
		color = Color3.fromRGB(142, 68, 173),
		label = "T3 Goblin Warrior",
	},
	{
		mobId = "L1_Knight",
		zone = "D",
		radius = 96,
		count = 4,
		color = Color3.fromRGB(146, 43, 33),
		label = "T4 Goblin Scout",
	},
}

local BOSS_CONFIG = {
	mobId = "L1_Boss",
	zone = "Boss",
	position = Vector3.new(110, 2, 110),
	color = Color3.fromRGB(39, 174, 96),
	label = "BOSS Forest Guardian",
}

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if f then
		return f
	end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local world = folder(Workspace, "World")
local locations = folder(world, "Locations")
local loc01 = folder(locations, "Loc01")
loc01:SetAttribute("LocationId", 1)
loc01:SetAttribute("LocationName", "Starter Village")

local oldSpawns = loc01:FindFirstChild("MobSpawns")
if oldSpawns then
	oldSpawns:Destroy()
end
local spawns = folder(loc01, "MobSpawns")

if not loc01:FindFirstChild("PlayerSpawn") then
	local sp = Instance.new("Part")
	sp.Name = "PlayerSpawn"
	sp.Size = Vector3.new(10, 1, 10)
	sp.Anchored = true
	sp.CanCollide = false
	sp.Material = Enum.Material.Neon
	sp.Color = Color3.fromRGB(80, 255, 120)
	sp.Transparency = 0.25
	sp.Position = Vector3.new(0, 2, 0)
	sp.Parent = loc01
end

local function createMarker(mobId, zone, pos, color, index)
	local p = Instance.new("Part")
	p.Name = string.format("%s_%02d", mobId, index or 1)
	p.Size = Vector3.new(4, 0.5, 4)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.3
	p.Position = pos
	p:SetAttribute("MobId", mobId)
	p:SetAttribute("Zone", zone)
	p:SetAttribute("IsSpawnMarker", true)
	p.Parent = spawns

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = p

	local bg = Instance.new("TextLabel")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 0.4
	bg.TextColor3 = Color3.new(1, 1, 1)
	bg.Font = Enum.Font.GothamBold
	bg.TextSize = 12
	bg.Text = string.format("%s\nZone %s", mobId, zone)
	bg.TextWrapped = true
	bg.Parent = bb

	return p
end

local totalMarkers = 0
for _, cfg in ipairs(ZONE_CONFIG) do
	for i = 1, cfg.count do
		local angle = (i / cfg.count) * math.pi * 2
		local x = math.cos(angle) * cfg.radius
		local z = math.sin(angle) * cfg.radius
		createMarker(cfg.mobId, cfg.zone, Vector3.new(x, 2, z), cfg.color, i)
		totalMarkers = totalMarkers + 1
	end
	print(string.format("[ZONE %s] %s x %d r=%d", cfg.zone, cfg.mobId, cfg.count, cfg.radius))
end

createMarker(BOSS_CONFIG.mobId, BOSS_CONFIG.zone, BOSS_CONFIG.position, BOSS_CONFIG.color, 1)
totalMarkers = totalMarkers + 1
print(string.format("[BOSS] %s at %s — drag to portal / end of loc", BOSS_CONFIG.mobId, tostring(BOSS_CONFIG.position)))

print("===================================================")
print(string.format("[OK] Loc01 MobSpawns: %d markers (4 tiers + 1 boss)", totalMarkers))
print("NEXT: drag markers onto map art -> Ctrl+S Save place -> Play")
print("===================================================")
