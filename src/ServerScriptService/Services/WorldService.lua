--!strict
--[[
	World bootstrap for 4 large territories.

	CRITICAL FOR ART COLLAB:
	- Code NEVER deletes or edits LocXX.Art
	- Scaffold only created if missing (guides)
	- If you build floor in Art, you can delete Scaffold yourself
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local WorldConfig = require(Shared.Config.WorldConfig)

local WorldService = {}
WorldService._root = nil :: Folder?

local function ensureFolder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then
		return f
	end
	if f then
		f:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(90, 90, 100)
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new()
	p.Name = props.Name or "Part"
	p.Transparency = props.Transparency or 0
	p.Parent = props.Parent
	if props.Locked then
		p.Locked = true
	end
	return p
end

local function hasArt(locFolder: Folder): boolean
	local art = locFolder:FindFirstChild(WorldConfig.ART_FOLDER)
	if not art then
		return false
	end
	return #art:GetChildren() > 0
end

function WorldService.Init()
	local root = ensureFolder(Workspace, WorldConfig.ROOT_FOLDER)
	WorldService._root = root
	root:SetAttribute("Phase", WorldConfig.PHASE)
	root:SetAttribute("IslandSize", WorldConfig.ISLAND_SIZE)

	local lobby = ensureFolder(root, WorldConfig.LOBBY_FOLDER)
	local locations = ensureFolder(root, WorldConfig.LOCATIONS_FOLDER)
	ensureFolder(root, WorldConfig.DUNGEONS_FOLDER)

	-- README for humans in Studio Explorer
	if not root:FindFirstChild("_README") then
		local readme = Instance.new("StringValue")
		readme.Name = "_README"
		readme.Value =
			"Art goes into each Loc0N.Art — code never touches it. Scaffold = temporary guides only. See docs/COLLAB.md"
		readme.Parent = root
	end

	if WorldConfig.AUTO_BUILD_SCAFFOLD then
		WorldService.BuildLobby(lobby)
		for id = 1, #WorldConfig.Locations do
			WorldService.EnsureLocation(locations, id)
		end
	else
		-- still create empty Loc folders for organization
		for id = 1, #WorldConfig.Locations do
			WorldService.EnsureLocationFolders(locations, id)
		end
	end

	local w, h = WorldConfig.GetWorldFootprint()
	print(string.format(
		"[World] Phase %d | %d territories | each %dx%d studs | footprint ~%dx%d",
		WorldConfig.PHASE,
		#WorldConfig.Locations,
		WorldConfig.ISLAND_SIZE,
		WorldConfig.ISLAND_SIZE,
		w,
		h
	))
end

function WorldService.BuildLobby(parent: Folder)
	local art = ensureFolder(parent, WorldConfig.ART_FOLDER)
	if art:FindFirstChild("LobbyFloor") or parent:FindFirstChild("LobbyFloor") then
		return
	end
	local scaffold = ensureFolder(parent, WorldConfig.SCAFFOLD_FOLDER)
	if scaffold:FindFirstChild("LobbyFloor") then
		return
	end
	local c = WorldConfig.LOBBY_CENTER
	part({
		Name = "LobbyFloor",
		Parent = scaffold,
		Size = Vector3.new(WorldConfig.LOBBY_SIZE, 2, WorldConfig.LOBBY_SIZE),
		CFrame = CFrame.new(c.X, c.Y - 1, c.Z),
		Color = Color3.fromRGB(50, 55, 80),
	})
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(c.X, c.Y, c.Z)
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = scaffold
end

function WorldService.EnsureLocationFolders(parent: Folder, locationId: number): Folder
	local meta = WorldConfig.GetMeta(locationId)
	local name = string.format("Loc%02d", locationId)
	local folder = ensureFolder(parent, name)
	folder:SetAttribute("LocationId", locationId)
	if meta then
		folder:SetAttribute("LocationName", meta.name)
		folder:SetAttribute("Theme", meta.theme)
		folder:SetAttribute("Status", meta.status)
		folder:SetAttribute("Blurb", meta.blurb)
	end
	ensureFolder(folder, WorldConfig.ART_FOLDER) -- empty Art for friends to fill
	return folder
end

function WorldService.EnsureLocation(parent: Folder, locationId: number)
	local folder = WorldService.EnsureLocationFolders(parent, locationId)
	local meta = WorldConfig.GetMeta(locationId)
	if not meta then
		return
	end

	-- If artists already built something — only ensure folders/attrs, no scaffold overwrite
	if hasArt(folder) and not WorldConfig.REBUILD_SCAFFOLD then
		print("[World] Loc" .. locationId .. " has Art — scaffold skipped")
		WorldService.EnsureSpawnReference(folder, locationId)
		return
	end

	local scaffold = folder:FindFirstChild(WorldConfig.SCAFFOLD_FOLDER)
	if scaffold and not WorldConfig.REBUILD_SCAFFOLD then
		-- already has scaffold from previous play
		WorldService.EnsureSpawnReference(folder, locationId)
		return
	end

	if scaffold and WorldConfig.REBUILD_SCAFFOLD then
		scaffold:Destroy()
	end

	WorldService.BuildScaffold(folder, locationId, meta)
	WorldService.EnsureSpawnReference(folder, locationId)
end

function WorldService.EnsureSpawnReference(folder: Folder, locationId: number)
	-- Prefer Art.PlayerSpawn, then Scaffold.PlayerSpawn, then create Scaffold one
	if folder:FindFirstChild("PlayerSpawn", true) then
		return
	end
	local scaffold = ensureFolder(folder, WorldConfig.SCAFFOLD_FOLDER)
	local cf = WorldConfig.GetSpawnCFrame(locationId)
	local sp = part({
		Name = "PlayerSpawn",
		Parent = scaffold,
		Size = Vector3.new(14, 1, 14),
		CFrame = cf * CFrame.new(0, -WorldConfig.SPAWN_Y_OFFSET + 0.5, 0),
		Color = Color3.fromRGB(80, 220, 120),
		CanCollide = false,
	})
	sp:SetAttribute("IsSpawn", true)
end

function WorldService.BuildScaffold(folder: Folder, locationId: number, meta: any)
	local scaffold = ensureFolder(folder, WorldConfig.SCAFFOLD_FOLDER)
	local center = WorldConfig.GetIslandCenter(locationId)
	local size = WorldConfig.ISLAND_SIZE

	-- Floor guide (artists replace with terrain under Art/)
	part({
		Name = "FloorGuide",
		Parent = scaffold,
		Size = Vector3.new(size, WorldConfig.ISLAND_HEIGHT, size),
		CFrame = CFrame.new(center.X, WorldConfig.FLOOR_Y - WorldConfig.ISLAND_HEIGHT / 2, center.Z),
		Color = locationId == 1 and Color3.fromRGB(40, 85, 45) or Color3.fromRGB(75, 78, 85),
		Material = Enum.Material.Slate,
	})

	-- Bounds
	local bounds = ensureFolder(scaffold, "Bounds")
	local half = size / 2
	local wallH = 60
	local wallT = 6
	local walls = {
		{ "WallN", Vector3.new(size, wallH, wallT), Vector3.new(center.X, wallH / 2, center.Z + half) },
		{ "WallS", Vector3.new(size, wallH, wallT), Vector3.new(center.X, wallH / 2, center.Z - half) },
		{ "WallE", Vector3.new(wallT, wallH, size), Vector3.new(center.X + half, wallH / 2, center.Z) },
		{ "WallW", Vector3.new(wallT, wallH, size), Vector3.new(center.X - half, wallH / 2, center.Z) },
	}
	for _, w in walls do
		part({
			Name = w[1],
			Parent = bounds,
			Size = w[2],
			CFrame = CFrame.new(w[3]),
			Transparency = 1,
			CanCollide = true,
		})
	end

	-- Zone disks (guides — hide later)
	local zones = ensureFolder(scaffold, "ZoneGuides")
	for zoneName, _ in WorldConfig.ZONE_FRACTIONS do
		local rMin, rMax = WorldConfig.GetZoneRadii(zoneName)
		local r = (rMin + rMax) / 2
		part({
			Name = "Zone_" .. zoneName,
			Parent = zones,
			Size = Vector3.new(r * 2, 0.5, r * 2),
			CFrame = CFrame.new(center.X, WorldConfig.FLOOR_Y + 0.4, center.Z),
			Color = WorldConfig.ZONE_COLORS[zoneName] or Color3.new(1, 1, 1),
			Transparency = 0.82,
			CanCollide = false,
			Material = Enum.Material.Neon,
		})
	end

	local bossPos = WorldConfig.GetBossCFrame(locationId).Position
	part({
		Name = "BossArenaGuide",
		Parent = zones,
		Size = Vector3.new(80, 1, 80),
		CFrame = CFrame.new(bossPos.X, WorldConfig.FLOOR_Y + 0.6, bossPos.Z),
		Color = WorldConfig.ZONE_COLORS.Boss,
		Transparency = 0.5,
		CanCollide = false,
	})

	-- Spawn
	local sp = part({
		Name = "PlayerSpawn",
		Parent = scaffold,
		Size = Vector3.new(16, 1, 16),
		CFrame = WorldConfig.GetSpawnCFrame(locationId) * CFrame.new(0, -WorldConfig.SPAWN_Y_OFFSET + 0.5, 0),
		Color = Color3.fromRGB(80, 220, 120),
		CanCollide = false,
	})
	sp:SetAttribute("IsSpawn", true)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(280, 50)
	bb.StudsOffset = Vector3.new(0, 20, 0)
	bb.AlwaysOnTop = true
	bb.Parent = sp
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = string.format("%d. %s  [%s]", locationId, meta.name, meta.status)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bb

	-- NPC stubs under Scaffold only
	local npcs = ensureFolder(scaffold, "NPCGuides")
	part({
		Name = "UpgradeNPC_Guide",
		Parent = npcs,
		Size = Vector3.new(5, 8, 5),
		CFrame = CFrame.new(center.X + 40, WorldConfig.FLOOR_Y + 4, center.Z + 25),
		Color = Color3.fromRGB(100, 100, 220),
	})
	part({
		Name = "QuestNPC_Guide",
		Parent = npcs,
		Size = Vector3.new(5, 8, 5),
		CFrame = CFrame.new(center.X - 40, WorldConfig.FLOOR_Y + 4, center.Z + 25),
		Color = Color3.fromRGB(220, 180, 80),
	})

	-- Corner poles so scale is obvious in Studio
	local corner = size / 2 - 10
	for _, off in {
		Vector3.new(corner, 0, corner),
		Vector3.new(-corner, 0, corner),
		Vector3.new(corner, 0, -corner),
		Vector3.new(-corner, 0, -corner),
	} do
		part({
			Name = "CornerPole",
			Parent = scaffold,
			Size = Vector3.new(4, 40, 4),
			CFrame = CFrame.new(center + off + Vector3.new(0, 20, 0)),
			Color = Color3.fromRGB(255, 255, 0),
			Transparency = 0.3,
			CanCollide = false,
		})
	end
end

function WorldService.GetLocationFolder(locationId: number): Folder?
	local root = WorldService._root or Workspace:FindFirstChild(WorldConfig.ROOT_FOLDER)
	if not root then
		return nil
	end
	local locations = root:FindFirstChild(WorldConfig.LOCATIONS_FOLDER)
	if not locations then
		return nil
	end
	return locations:FindFirstChild(string.format("Loc%02d", locationId)) :: Folder?
end

function WorldService.GetSpawnCFrame(locationId: number): CFrame
	local folder = WorldService.GetLocationFolder(locationId)
	if folder then
		local spawnPart = folder:FindFirstChild("PlayerSpawn", true)
		if spawnPart and spawnPart:IsA("BasePart") then
			return spawnPart.CFrame + Vector3.new(0, 4, 0)
		end
	end
	return WorldConfig.GetSpawnCFrame(locationId)
end

function WorldService.TeleportToLocation(player: Player, locationId: number)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	hrp.CFrame = WorldService.GetSpawnCFrame(locationId)
end

function WorldService.TeleportToLobby(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local c = WorldConfig.LOBBY_CENTER
	hrp.CFrame = CFrame.new(c.X, c.Y + 5, c.Z)
end

return WorldService
