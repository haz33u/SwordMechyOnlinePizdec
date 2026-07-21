--[[
	Grey-box Loc1 layout: path Spawn → A → B → C → D → Boss.
	Run via Studio MCP / Command Bar (paste full file). Preserves Loc01.Art.
]]

local Workspace = game:GetService("Workspace")

local PATH = {
	-- along +XZ diagonal toward boss arena
	A = { dist = 32, count = 12, mobId = "L1_Goblin", zone = "A", name = "Goblin", color = Color3.fromRGB(88, 214, 141), spread = 14 },
	B = { dist = 58, count = 8, mobId = "L1_DarkGoblin", zone = "B", name = "Dark Goblin", color = Color3.fromRGB(93, 173, 226), spread = 16 },
	C = { dist = 88, count = 5, mobId = "L1_GoblinWarrior", zone = "C", name = "Goblin Warrior", color = Color3.fromRGB(142, 68, 173), spread = 12 },
	D = { dist = 118, count = 4, mobId = "L1_GoblinScout", zone = "D", name = "Goblin Scout", color = Color3.fromRGB(146, 43, 33), spread = 10 },
}
local BOSS = {
	pos = Vector3.new(148, 2, 148),
	mobId = "L1_Boss",
	zone = "Boss",
	name = "Forest Guardian",
	color = Color3.fromRGB(39, 174, 96),
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

local function clearFolder(f)
	for _, ch in f:GetChildren() do
		ch:Destroy()
	end
end

local world = folder(Workspace, "World")
local locations = folder(world, "Locations")
local loc01 = folder(locations, "Loc01")
loc01:SetAttribute("LocationId", 1)
loc01:SetAttribute("LocationName", "Starter Village")

-- Never touch Art/
local spawns = folder(loc01, "MobSpawns")
clearFolder(spawns)
local guides = folder(loc01, "ZoneGuides")
clearFolder(guides)
local pathHints = folder(loc01, "PathHints")
clearFolder(pathHints)

-- Player spawn
local ps = loc01:FindFirstChild("PlayerSpawn")
if not ps then
	ps = Instance.new("Part")
	ps.Name = "PlayerSpawn"
	ps.Parent = loc01
end
ps.Size = Vector3.new(12, 1, 12)
ps.Anchored = true
ps.CanCollide = false
ps.Material = Enum.Material.Neon
ps.Color = Color3.fromRGB(80, 255, 120)
ps.Transparency = 0.2
ps.Position = Vector3.new(0, 2, 0)

local function plate(name, pos, size, color, parent, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.ForceField
	p.Color = color
	p.Transparency = transparency or 0.75
	p.Position = pos
	p.Parent = parent
	return p
end

local function pathSegment(from, to, i)
	local mid = (from + to) * 0.5
	local dir = to - from
	local len = dir.Magnitude
	local p = Instance.new("Part")
	p.Name = string.format("Path_%02d", i)
	p.Size = Vector3.new(6, 0.25, math.max(len, 4))
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(200, 200, 180)
	p.Transparency = 0.65
	p.CFrame = CFrame.lookAt(mid, to) * CFrame.Angles(0, 0, 0)
	-- lookAt points -Z; flatten to ground
	p.CFrame = CFrame.new(mid.X, 1.2, mid.Z) * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0)
	p.Parent = pathHints
end

local function marker(mobId, displayName, zone, pos, color, index, isBoss)
	local p = Instance.new("Part")
	p.Name = string.format("%s_%02d", mobId, index or 1)
	p.Size = if isBoss then Vector3.new(8, 0.6, 8) else Vector3.new(4, 0.5, 4)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.25
	p.Position = pos
	p:SetAttribute("MobId", mobId)
	p:SetAttribute("Zone", zone)
	p:SetAttribute("IsSpawnMarker", true)
	p:SetAttribute("DisplayName", displayName)
	p.Parent = spawns

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(170, 42)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.new(0, 0, 0)
	t.BackgroundTransparency = 0.35
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 13
	t.TextWrapped = true
	if isBoss then
		t.Text = "BOSS · Forest Guardian\n(end of Loc1)"
	else
		t.Text = string.format("%s\nZone %s", displayName, zone)
	end
	t.Parent = bb
	return p
end

-- Cluster centers along diagonal path toward boss
local function centerAt(dist)
	local s = dist / math.sqrt(2)
	return Vector3.new(s, 2, s)
end

local order = { "A", "B", "C", "D" }
local prev = Vector3.new(0, 2, 0)
local pathI = 1
pathSegment(prev, centerAt(PATH.A.dist), pathI)
pathI = pathI + 1

for _, key in ipairs(order) do
	local cfg = PATH[key]
	local c = centerAt(cfg.dist)
	pathSegment(prev, c, pathI)
	pathI = pathI + 1
	prev = c

	-- zone floor plate
	plate(string.format("Zone%s_Plate", key), Vector3.new(c.X, 1.0, c.Z), Vector3.new(cfg.spread * 2.4, 0.4, cfg.spread * 2.4), cfg.color, guides, 0.82)

	for i = 1, cfg.count do
		local angle = (i / cfg.count) * math.pi * 2
		local r = cfg.spread * (0.45 + 0.55 * ((i % 3) / 3))
		local pos = c + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		marker(cfg.mobId, cfg.name, cfg.zone, pos, cfg.color, i, false)
	end
end

pathSegment(prev, BOSS.pos, pathI)
plate("BossArena_Plate", Vector3.new(BOSS.pos.X, 1.0, BOSS.pos.Z), Vector3.new(28, 0.5, 28), BOSS.color, guides, 0.8)
marker(BOSS.mobId, BOSS.name, BOSS.zone, BOSS.pos, BOSS.color, 1, true)

local n = #spawns:GetChildren()
print(string.format("[OK] Loc01 grey-box: %d spawn markers + zone plates + path (Art preserved)", n))
print("Labels: Goblin / Dark Goblin / Goblin Warrior / Goblin Scout / BOSS Forest Guardian")
print("Save place (Ctrl+S), then Play to test.")
