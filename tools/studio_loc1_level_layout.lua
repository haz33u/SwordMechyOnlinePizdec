--[[
	Loc1 Goblin City — 4 large camps + boss on FULL Art scale.

	Source of truth: Loc01.Art world AABB (not origin + 32 stud toy ring).
	Rebuilds only: MobSpawns, ZoneGuides, PathHints.
	Never touches: Loc01.Art

	Run via Studio MCP execute_luau, or paste FULL file into Command Bar
	(not the filename — that causes "Incomplete statement").
]]

local Workspace = game:GetService("Workspace")

-- Camp plan as fractions of Art BB (eastward city walk from west spawn)
-- xFrac/zFrac in 0..1 of Art min→max; footprint = marker disk radius (studs)
local CAMPS = {
	{
		key = "A",
		xFrac = 0.18,
		zFrac = 0.52,
		count = 12,
		mobId = "L1_Goblin",
		zone = "A",
		name = "Goblin",
		color = Color3.fromRGB(88, 214, 141),
		footprint = 55,
	},
	{
		key = "B",
		xFrac = 0.38,
		zFrac = 0.42,
		count = 8,
		mobId = "L1_DarkGoblin",
		zone = "B",
		name = "Dark Goblin",
		color = Color3.fromRGB(93, 173, 226),
		footprint = 55,
	},
	{
		key = "C",
		xFrac = 0.58,
		zFrac = 0.58,
		count = 5,
		mobId = "L1_GoblinWarrior",
		zone = "C",
		name = "Goblin Warrior",
		color = Color3.fromRGB(142, 68, 173),
		footprint = 50,
	},
	{
		key = "D",
		xFrac = 0.78,
		zFrac = 0.38,
		count = 4,
		mobId = "L1_GoblinScout",
		zone = "D",
		name = "Goblin Scout",
		color = Color3.fromRGB(146, 43, 33),
		footprint = 48,
	},
}

local BOSS = {
	xFrac = 0.93,
	zFrac = 0.72,
	mobId = "L1_Boss",
	zone = "Boss",
	name = "Forest Guardian",
	color = Color3.fromRGB(39, 174, 96),
	footprint = 45,
}

local MIN_CAMP_DIST = 180
local MARKER_Y = 2.0
local GUIDE_Y = 1.0
local PATH_Y = 1.2

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then
		return f
	end
	if f then
		f:Destroy()
	end
	local n = Instance.new("Folder")
	n.Name = name
	n.Parent = parent
	return n
end

local function clearFolder(f)
	for _, ch in f:GetChildren() do
		ch:Destroy()
	end
end

local function artBounds(art)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	local n = 0
	for _, d in art:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
			local cf, size = d.CFrame, d.Size
			local half = size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = cf:PointToWorldSpace(Vector3.new(sx * half.X, sy * half.Y, sz * half.Z))
						minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
						maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
					end
				end
			end
		end
	end
	if n == 0 then
		-- Island fallback: Loc1 center 0, size 1200
		local half = 600
		minV = Vector3.new(-half, 0, -half)
		maxV = Vector3.new(half, 40, half)
		warn("[layout] Loc01.Art has no BaseParts — using island fallback ±600")
	end
	return minV, maxV
end

local function lerp1(a, b, t)
	return a + (b - a) * t
end

local function xzFromFrac(minV, maxV, xFrac, zFrac)
	local padX = (maxV.X - minV.X) * 0.02
	local padZ = (maxV.Z - minV.Z) * 0.02
	local x = lerp1(minV.X + padX, maxV.X - padX, xFrac)
	local z = lerp1(minV.Z + padZ, maxV.Z - padZ, zFrac)
	return Vector3.new(x, MARKER_Y, z)
end

local function plate(name, pos, size, color, parent, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.ForceField
	p.Color = color
	p.Transparency = transparency or 0.78
	p.Position = Vector3.new(pos.X, GUIDE_Y, pos.Z)
	p.Parent = parent
	return p
end

local function pathSegment(from, to, i, parent)
	local mid = (from + to) * 0.5
	local dir = to - from
	local len = dir.Magnitude
	local p = Instance.new("Part")
	p.Name = string.format("Path_%02d", i)
	p.Size = Vector3.new(8, 0.25, math.max(len, 4))
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(200, 200, 180)
	p.Transparency = 0.7
	p.CFrame = CFrame.new(mid.X, PATH_Y, mid.Z) * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0)
	p.Parent = parent
end

local function marker(
	mobId,
	displayName,
	zone,
	pos,
	color,
	index,
	isBoss,
	parent
)
	local p = Instance.new("Part")
	p.Name = string.format("%s_%02d", mobId, index)
	p.Size = if isBoss then Vector3.new(10, 0.6, 10) else Vector3.new(4.5, 0.5, 4.5)
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
	p.Parent = parent

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(180, 44)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 400
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
		t.Text = "BOSS - Forest Guardian\n(end of Loc1)"
	else
		t.Text = string.format("%s\nZone %s", displayName, zone)
	end
	t.Parent = bb
	return p
end

local function scatterInDisk(center, count, radius, i)
	-- Deterministic ring + slight radial jitter (no math.random for stable layout)
	local angle = (i / math.max(count, 1)) * math.pi * 2 + (i * 0.37)
	local ring = 0.35 + 0.55 * ((i % 4) / 4)
	local r = radius * ring
	return center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
end

-- ─── hierarchy ─────────────────────────────────────────────
local world = folder(Workspace, "World")
local locations = folder(world, "Locations")
local loc01 = folder(locations, "Loc01")
loc01:SetAttribute("LocationId", 1)
loc01:SetAttribute("LocationName", "Goblin City")

local art = loc01:FindFirstChild("Art")
local minV
local maxV
if art then
	minV, maxV = artBounds(art)
else
	warn("[layout] No Loc01.Art — island fallback")
	minV = Vector3.new(-600, 0, -600)
	maxV = Vector3.new(600, 40, 600)
end

local artSize = maxV - minV
print(string.format(
	"[layout] Art BB size XZ=%.0f x %.0f  min=(%.0f,%.0f) max=(%.0f,%.0f)",
	artSize.X,
	artSize.Z,
	minV.X,
	minV.Z,
	maxV.X,
	maxV.Z
))

-- Rebuild combat scaffolding only
local spawns = folder(loc01, "MobSpawns")
clearFolder(spawns)
local guides = folder(loc01, "ZoneGuides")
clearFolder(guides)
local pathHints = folder(loc01, "PathHints")
clearFolder(pathHints)

-- PlayerSpawn: keep existing if present; else west-edge entrance
local ps = loc01:FindFirstChild("PlayerSpawn")
if not ps then
	ps = Instance.new("Part")
	ps.Name = "PlayerSpawn"
	ps.Parent = loc01
end
if ps:IsA("BasePart") then
	ps.Size = Vector3.new(12, 1, 12)
	ps.Anchored = true
	ps.CanCollide = false
	ps.Material = Enum.Material.Neon
	ps.Color = Color3.fromRGB(80, 255, 120)
	ps.Transparency = 0.2
	-- Entrance: near Art west, slightly inside
	local spawnPos = xzFromFrac(minV, maxV, 0.04, 0.50)
	-- Prefer existing if already near Art; else set entrance
	local cur = ps.Position
	local insideX = cur.X >= minV.X - 50 and cur.X <= maxV.X + 50
	local insideZ = cur.Z >= minV.Z - 50 and cur.Z <= maxV.Z + 50
	if not (insideX and insideZ) or (cur.X == 0 and cur.Z == 0 and artSize.X > 400) then
		-- Keep (0,2,0) if it is already a valid west entrance for this map
		if cur.X >= minV.X - 20 and cur.X <= minV.X + 80 and insideZ then
			ps.Position = Vector3.new(cur.X, MARKER_Y, cur.Z)
		else
			ps.Position = spawnPos
		end
	end
end

local spawnPos = if ps:IsA("BasePart") then ps.Position else xzFromFrac(minV, maxV, 0.04, 0.50)
plate("Spawn_Plate", spawnPos, Vector3.new(24, 0.4, 24), Color3.fromRGB(80, 200, 120), guides, 0.85)

-- Place camps
local centers = {}
local pathI = 1
local prev = Vector3.new(spawnPos.X, MARKER_Y, spawnPos.Z)

for _, cfg in ipairs(CAMPS) do
	local c = xzFromFrac(minV, maxV, cfg.xFrac, cfg.zFrac)
	table.insert(centers, c)
	pathSegment(prev, c, pathI, pathHints)
	pathI += 1
	prev = c

	local plateSize = cfg.footprint * 2.2
	plate(
		string.format("Camp%s_Plate", cfg.key),
		c,
		Vector3.new(plateSize, 0.45, plateSize),
		cfg.color,
		guides,
		0.8
	)

	-- Camp label pillar
	local pillar = Instance.new("Part")
	pillar.Name = string.format("Camp%s_Label", cfg.key)
	pillar.Size = Vector3.new(6, 0.4, 6)
	pillar.Anchored = true
	pillar.CanCollide = false
	pillar.Material = Enum.Material.Neon
	pillar.Color = cfg.color
	pillar.Transparency = 0.15
	pillar.Position = c + Vector3.new(0, 0.2, 0)
	pillar.Parent = guides
	local pbb = Instance.new("BillboardGui")
	pbb.Size = UDim2.fromOffset(200, 36)
	pbb.StudsOffset = Vector3.new(0, 8, 0)
	pbb.AlwaysOnTop = true
	pbb.MaxDistance = 800
	pbb.Parent = pillar
	local pl = Instance.new("TextLabel")
	pl.Size = UDim2.fromScale(1, 1)
	pl.BackgroundColor3 = Color3.new(0, 0, 0)
	pl.BackgroundTransparency = 0.3
	pl.TextColor3 = Color3.new(1, 1, 1)
	pl.Font = Enum.Font.GothamBold
	pl.TextSize = 14
	pl.Text = string.format("CAMP %s - %s ×%d", cfg.key, cfg.name, cfg.count)
	pl.Parent = pbb

	for i = 1, cfg.count do
		local pos = scatterInDisk(c, cfg.count, cfg.footprint, i)
		marker(cfg.mobId, cfg.name, cfg.zone, pos, cfg.color, i, false, spawns)
	end

	print(string.format(
		"[layout] Camp %s center=(%.0f, %.0f) footprint=%d %s x%d",
		cfg.key,
		c.X,
		c.Z,
		cfg.footprint,
		cfg.name,
		cfg.count
	))
end

local bossPos = xzFromFrac(minV, maxV, BOSS.xFrac, BOSS.zFrac)
pathSegment(prev, bossPos, pathI, pathHints)
plate("BossArena_Plate", bossPos, Vector3.new(BOSS.footprint * 2, 0.5, BOSS.footprint * 2), BOSS.color, guides, 0.78)
marker(BOSS.mobId, BOSS.name, BOSS.zone, bossPos, BOSS.color, 1, true, spawns)
print(string.format("[layout] Boss center=(%.0f, %.0f)", bossPos.X, bossPos.Z))

-- QA distances
local allPts = { spawnPos }
for _, c in centers do
	table.insert(allPts, c)
end
table.insert(allPts, bossPos)
local names = { "Spawn", "A", "B", "C", "D", "Boss" }
local minAdj = math.huge
for i = 2, #allPts do
	local a, b = allPts[i - 1], allPts[i]
	local d = (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
	minAdj = math.min(minAdj, d)
	print(string.format("[layout] dist %s → %s = %.0f studs", names[i - 1], names[i], d))
	if d < MIN_CAMP_DIST and i > 2 then
		warn(string.format("[layout] WARNING: %s→%s only %.0f studs (want ≥ %d)", names[i - 1], names[i], d, MIN_CAMP_DIST))
	end
end

-- Span of markers
local sMin = Vector3.new(math.huge, 0, math.huge)
local sMax = Vector3.new(-math.huge, 0, -math.huge)
for _, ch in spawns:GetChildren() do
	if ch:IsA("BasePart") then
		sMin = Vector3.new(math.min(sMin.X, ch.Position.X), 0, math.min(sMin.Z, ch.Position.Z))
		sMax = Vector3.new(math.max(sMax.X, ch.Position.X), 0, math.max(sMax.Z, ch.Position.Z))
	end
end
local span = sMax - sMin
local n = #spawns:GetChildren()
print(string.format(
	"[OK] Goblin City layout: %d markers | MobSpawns span XZ=%.0f x %.0f | Art XZ=%.0f x %.0f | min adjacent=%.0f",
	n,
	span.X,
	span.Z,
	artSize.X,
	artSize.Z,
	minAdj
))
print("Camps: A Goblin - B Dark Goblin - C Warrior - D Scout - Boss Forest Guardian")
print("Art preserved. Save place (Ctrl+S), then Play.")
