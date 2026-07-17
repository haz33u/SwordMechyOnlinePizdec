--[[
	STUDIO COMMAND BAR (Edit Mode) — paste & run once.

	Creates Workspace.World.Locations.Loc01.MobSpawns markers you can MOVE in Edit.
	Play will spawn real killable mobs ON those markers.

	View → Command Bar → paste all → Enter
	Then SAVE the place (Ctrl+S / Publish).
]]

local Workspace = game:GetService("Workspace")

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if f then return f end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local world = folder(Workspace, "World")
local locations = folder(world, "Locations")
local loc01 = folder(locations, "Loc01")
loc01:SetAttribute("LocationId", 1)
loc01:SetAttribute("LocationName", "Тёмный лес")

-- clear old markers (only under MobSpawns)
local old = loc01:FindFirstChild("MobSpawns")
if old then old:Destroy() end
local spawns = folder(loc01, "MobSpawns")

-- Player spawn pad
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

local function marker(mobId, zone, pos, color)
	local p = Instance.new("Part")
	p.Name = mobId
	p.Size = Vector3.new(3.5, 0.5, 3.5)
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
	bb.Size = UDim2.fromOffset(130, 30)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.new(0, 0, 0)
	t.BackgroundTransparency = 0.35
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 11
	t.Text = mobId .. "\n" .. zone
	t.Parent = bb
	return p
end

-- Colors
local CA = Color3.fromRGB(100, 220, 100)
local CB = Color3.fromRGB(100, 160, 255)
local CC = Color3.fromRGB(200, 120, 255)
local CBOS = Color3.fromRGB(230, 60, 60)
local CDBG = Color3.fromRGB(255, 200, 40)

-- Ring helper: center 0,0  radius r, count n
local function ring(mobId, zone, r, n, color, y)
	y = y or 2
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local x = math.cos(a) * r
		local z = math.sin(a) * r
		local p = marker(mobId, zone, Vector3.new(x, y, z), color)
		p.Name = string.format("%s_%02d", mobId, i)
	end
end

-- NEAR SPAWN layout (you can drag any Part after this)
ring("L1_Slime", "A", 18, 6, CA)
ring("L1_GoblinScout", "A", 24, 5, CA)
ring("L1_Skeleton", "B", 36, 4, CB)
ring("L1_Wolf", "B", 42, 3, CB)
ring("L1_GoblinWarrior", "B", 48, 3, CB)
ring("L1_Knight", "C", 58, 2, CC)
marker("L1_Boss", "Boss", Vector3.new(40, 2, 40), CBOS).Name = "L1_Boss_01"
marker("DEBUG_Dummy", "Debug", Vector3.new(10, 2, 6), CDBG).Name = "DEBUG_Dummy_01"

print("[OK] Loc01 MobSpawns created:", #spawns:GetChildren(), "markers. Drag them in Edit, then Save place.")
