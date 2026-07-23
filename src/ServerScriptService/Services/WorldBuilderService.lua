--!strict
--[[
	WorldBuilderService — Builds procedural 3D map scaffold & props for Location 1: "Dark Goblin Forest".
	Generates 4 themed Goblin Camps (A, B, C, D) + Boss Arena with wood huts, bonfires, gates, & MobSpawns markers.
]]

local Workspace = game:GetService("Workspace")

local WorldBuilderService = {}

local function ensureFolder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if not f or not f:IsA("Folder") then
		local newF = Instance.new("Folder")
		newF.Name = name
		newF.Parent = parent
		return newF
	end
	return f
end

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, anchored: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Wood
	p.Anchored = if anchored ~= nil then anchored else true
	p.CanCollide = true
	p.CastShadow = true
	p.Parent = parent
	return p
end

local function makeTorch(parent: Instance, cf: CFrame)
	local post = makePart(parent, "TorchPost", Vector3.new(0.6, 6, 0.6), cf * CFrame.new(0, 3, 0), Color3.fromRGB(80, 50, 30), Enum.Material.Wood)
	local head = makePart(parent, "TorchHead", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 6.2, 0), Color3.fromRGB(255, 140, 20), Enum.Material.Neon)
	head.CanCollide = false
	
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 40)
	light.Range = 18
	light.Brightness = 2.5
	light.Parent = head
end

local function makeBonfire(parent: Instance, pos: Vector3)
	local base = makePart(parent, "BonfireBase", Vector3.new(4, 0.8, 4), CFrame.new(pos + Vector3.new(0, 0.4, 0)), Color3.fromRGB(70, 70, 75), Enum.Material.Cobblestone)
	local fire = makePart(parent, "FireCore", Vector3.new(2, 2, 2), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(255, 100, 0), Enum.Material.Neon)
	fire.CanCollide = false
	
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 20)
	light.Range = 30
	light.Brightness = 4
	light.Parent = fire
end

local function makeHut(parent: Instance, name: string, pos: Vector3, size: Vector3)
	local cf = CFrame.new(pos)
	-- Wooden floor
	makePart(parent, name .. "_Floor", Vector3.new(size.X, 0.6, size.Z), cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(90, 60, 40), Enum.Material.WoodPlanks)
	-- Pillars
	local h = size.Y
	makePart(parent, name .. "_P1", Vector3.new(1, h, 1), cf * CFrame.new(-size.X/2 + 0.5, h/2, -size.Z/2 + 0.5), Color3.fromRGB(70, 45, 25), Enum.Material.Wood)
	makePart(parent, name .. "_P2", Vector3.new(1, h, 1), cf * CFrame.new(size.X/2 - 0.5, h/2, -size.Z/2 + 0.5), Color3.fromRGB(70, 45, 25), Enum.Material.Wood)
	makePart(parent, name .. "_P3", Vector3.new(1, h, 1), cf * CFrame.new(-size.X/2 + 0.5, h/2, size.Z/2 - 0.5), Color3.fromRGB(70, 45, 25), Enum.Material.Wood)
	makePart(parent, name .. "_P4", Vector3.new(1, h, 1), cf * CFrame.new(size.X/2 - 0.5, h/2, size.Z/2 - 0.5), Color3.fromRGB(70, 45, 25), Enum.Material.Wood)
	-- Thatch roof
	makePart(parent, name .. "_Roof", Vector3.new(size.X + 2, 1.5, size.Z + 2), cf * CFrame.new(0, h + 0.75, 0), Color3.fromRGB(60, 80, 40), Enum.Material.Grass)
end

local function makeMarker(parent: Instance, name: string, mobId: string, zone: string, pos: Vector3)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(3, 1, 3)
	p.CFrame = CFrame.new(pos)
	p.Transparency = 0.8
	p.Color = Color3.fromRGB(0, 255, 120)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.SetAttribute(p, "MobId", mobId)
	p.SetAttribute(p, "Zone", zone)
	p.Parent = parent
end

function WorldBuilderService.Init()
	local world = ensureFolder(Workspace, "World")
	local locations = ensureFolder(world, "Locations")
	local loc01 = ensureFolder(locations, "Loc01")
	
	local art = loc01:FindFirstChild("Art")
	if art then
		-- Already constructed or customized in Studio
		print("[WorldBuilder] Loc01.Art exists — skipping procedural scaffold")
		return
	end
	
	art = ensureFolder(loc01, "Art")
	local spawnsFolder = ensureFolder(loc01, "MobSpawns")
	
	print("[WorldBuilder] Constructing procedural Dark Goblin Forest map layout...")
	
	-- Ground Island: Dark Forest Soil
	makePart(art, "ForestGround", Vector3.new(280, 6, 360), CFrame.new(0, -3, -60), Color3.fromRGB(40, 55, 35), Enum.Material.Grass)
	
	-- Player Spawn Pad (Entrance Camp A)
	local spawnPad = makePart(art, "PlayerSpawn", Vector3.new(12, 1, 12), CFrame.new(0, 0.5, 90), Color3.fromRGB(220, 180, 50), Enum.Material.SmoothPlastic)
	local spawnDecal = Instance.new("SpawnLocation")
	spawnDecal.Size = Vector3.new(12, 1, 12)
	spawnDecal.CFrame = spawnPad.CFrame
	spawnDecal.Transparency = 1
	spawnDecal.CanCollide = false
	spawnDecal.Parent = spawnPad

	-- Torches at entrance
	makeTorch(art, CFrame.new(-10, 0, 80))
	makeTorch(art, CFrame.new(10, 0, 80))

	--------------------------------------------------------------------------
	-- CAMP A: Goblin Outpost (Entrance)
	--------------------------------------------------------------------------
	makeHut(art, "OutpostHut1", Vector3.new(-25, 0, 50), Vector3.new(12, 8, 12))
	makeHut(art, "OutpostHut2", Vector3.new(25, 0, 50), Vector3.new(12, 8, 12))
	makeBonfire(art, Vector3.new(0, 0, 50))
	
	-- Mob Spawns Camp A (L1_Goblin)
	makeMarker(spawnsFolder, "Spawn_A1", "L1_Goblin", "A", Vector3.new(-12, 1, 45))
	makeMarker(spawnsFolder, "Spawn_A2", "L1_Goblin", "A", Vector3.new(12, 1, 45))
	makeMarker(spawnsFolder, "Spawn_A3", "L1_Goblin", "A", Vector3.new(-18, 1, 60))
	makeMarker(spawnsFolder, "Spawn_A4", "L1_Goblin", "A", Vector3.new(18, 1, 60))

	--------------------------------------------------------------------------
	-- CAMP B: Dark Goblin Village (Mid Field)
	--------------------------------------------------------------------------
	makeHut(art, "VillageHut1", Vector3.new(-45, 0, -10), Vector3.new(16, 10, 16))
	makeHut(art, "VillageHut2", Vector3.new(45, 0, -10), Vector3.new(16, 10, 16))
	makeBonfire(art, Vector3.new(0, 0, -10))
	makeTorch(art, CFrame.new(-25, 0, -10))
	makeTorch(art, CFrame.new(25, 0, -10))

	-- Mob Spawns Camp B (L1_DarkGoblin)
	makeMarker(spawnsFolder, "Spawn_B1", "L1_DarkGoblin", "B", Vector3.new(-20, 1, -15))
	makeMarker(spawnsFolder, "Spawn_B2", "L1_DarkGoblin", "B", Vector3.new(20, 1, -15))
	makeMarker(spawnsFolder, "Spawn_B3", "L1_DarkGoblin", "B", Vector3.new(-30, 1, 0))
	makeMarker(spawnsFolder, "Spawn_B4", "L1_DarkGoblin", "B", Vector3.new(30, 1, 0))

	--------------------------------------------------------------------------
	-- CAMP C: Goblin Forge & Armory (Hard Zone)
	--------------------------------------------------------------------------
	makeHut(art, "ForgeHut", Vector3.new(0, 0, -80), Vector3.new(20, 12, 20))
	makeBonfire(art, Vector3.new(-30, 0, -80))
	makeBonfire(art, Vector3.new(30, 0, -80))

	-- Mob Spawns Camp C (L1_GoblinWarrior)
	makeMarker(spawnsFolder, "Spawn_C1", "L1_GoblinWarrior", "C", Vector3.new(-25, 1, -75))
	makeMarker(spawnsFolder, "Spawn_C2", "L1_GoblinWarrior", "C", Vector3.new(25, 1, -75))
	makeMarker(spawnsFolder, "Spawn_C3", "L1_GoblinWarrior", "C", Vector3.new(0, 1, -95))

	--------------------------------------------------------------------------
	-- CAMP D: Gate & Totems (Elite Zone)
	--------------------------------------------------------------------------
	-- Skull gate posts
	makePart(art, "GatePillarLeft", Vector3.new(3, 16, 3), CFrame.new(-18, 8, -140), Color3.fromRGB(60, 40, 25), Enum.Material.Wood)
	makePart(art, "GatePillarRight", Vector3.new(3, 16, 3), CFrame.new(18, 8, -140), Color3.fromRGB(60, 40, 25), Enum.Material.Wood)
	makePart(art, "GateArch", Vector3.new(40, 3, 3), CFrame.new(0, 16, -140), Color3.fromRGB(70, 45, 25), Enum.Material.Wood)
	makeTorch(art, CFrame.new(-18, 16, -140))
	makeTorch(art, CFrame.new(18, 16, -140))

	-- Mob Spawns Camp D (L1_GoblinScout)
	makeMarker(spawnsFolder, "Spawn_D1", "L1_GoblinScout", "D", Vector3.new(-12, 1, -130))
	makeMarker(spawnsFolder, "Spawn_D2", "L1_GoblinScout", "D", Vector3.new(12, 1, -130))

	--------------------------------------------------------------------------
	-- DUNGEON PORTAL: Dark Portal to Subterranean Arena
	--------------------------------------------------------------------------
	local dungeonPortalFrame = makePart(art, "DungeonPortalFrame", Vector3.new(12, 16, 2), CFrame.new(35, 8, -140), Color3.fromRGB(40, 20, 60), Enum.Material.Slate)
	local dungeonPortalCore = makePart(art, "DungeonPortalCore", Vector3.new(8, 12, 0.4), CFrame.new(35, 7, -140), Color3.fromRGB(140, 30, 220), Enum.Material.Neon)
	dungeonPortalCore.Transparency = 0.25

	local dungeonPrompt = Instance.new("ProximityPrompt")
	dungeonPrompt.ObjectText = "Dark Dungeon Portal"
	dungeonPrompt.ActionText = "Enter Dungeon [E]"
	dungeonPrompt.HoldDuration = 0.5
	dungeonPrompt.MaxActivationDistance = 14
	dungeonPrompt.Parent = dungeonPortalCore

	dungeonPrompt.Triggered:Connect(function(player)
		Remotes.Event("OpenPanel"):FireClient(player, "dungeons")
	end)

	--------------------------------------------------------------------------
	-- BOSS ARENA: Goblin King's Throne
	--------------------------------------------------------------------------
	local throneBase = makePart(art, "ThroneAltar", Vector3.new(36, 3, 36), CFrame.new(0, 1.5, -190), Color3.fromRGB(70, 70, 75), Enum.Material.Cobblestone)
	local throneChair = makePart(art, "GoblinThrone", Vector3.new(8, 10, 6), CFrame.new(0, 8, -202), Color3.fromRGB(90, 30, 20), Enum.Material.WoodPlanks)
	
	makeTorch(art, CFrame.new(-15, 3, -175))
	makeTorch(art, CFrame.new(15, 3, -175))
	makeTorch(art, CFrame.new(-15, 3, -205))
	makeTorch(art, CFrame.new(15, 3, -205))

	-- Boss Spawn Marker (L1_GoblinKing)
	makeMarker(spawnsFolder, "Spawn_Boss", "L1_GoblinKing", "Boss", Vector3.new(0, 3, -190))

	print("[WorldBuilder] Dark Goblin Forest procedural scaffold successfully built!")
end

function WorldBuilderService.GenerateStudioMarkers()
	local world = ensureFolder(Workspace, "World")
	local locations = ensureFolder(world, "Locations")
	local loc01 = ensureFolder(locations, "Loc01")
	local spawnsFolder = ensureFolder(loc01, "MobSpawns")

	local function makeMarker(name: string, mobId: string, zone: string, pos: Vector3)
		local existing = spawnsFolder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(4, 1, 4)
		p.CFrame = CFrame.new(pos)
		p.Transparency = 0.5
		p.Color = Color3.fromRGB(0, 255, 120)
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p:SetAttribute("MobId", mobId)
		p:SetAttribute("Zone", zone)
		p.Parent = spawnsFolder
		return p
	end

	makeMarker("Spawn_A1", "L1_Goblin", "A", Vector3.new(-20, 3, 40))
	makeMarker("Spawn_A2", "L1_Goblin", "A", Vector3.new(20, 3, 40))
	makeMarker("Spawn_A3", "L1_Goblin", "A", Vector3.new(-35, 3, 60))
	makeMarker("Spawn_A4", "L1_Goblin", "A", Vector3.new(35, 3, 60))

	makeMarker("Spawn_B1", "L1_DarkGoblin", "B", Vector3.new(-30, 3, -15))
	makeMarker("Spawn_B2", "L1_DarkGoblin", "B", Vector3.new(30, 3, -15))
	makeMarker("Spawn_B3", "L1_DarkGoblin", "B", Vector3.new(-45, 3, 0))
	makeMarker("Spawn_B4", "L1_DarkGoblin", "B", Vector3.new(45, 3, 0))

	makeMarker("Spawn_C1", "L1_GoblinWarrior", "C", Vector3.new(-35, 3, -75))
	makeMarker("Spawn_C2", "L1_GoblinWarrior", "C", Vector3.new(35, 3, -75))
	makeMarker("Spawn_C3", "L1_GoblinWarrior", "C", Vector3.new(0, 3, -95))

	makeMarker("Spawn_D1", "L1_GoblinScout", "D", Vector3.new(-20, 3, -130))
	makeMarker("Spawn_D2", "L1_GoblinScout", "D", Vector3.new(20, 3, -130))

	makeMarker("Spawn_Boss", "L1_GoblinKing", "Boss", Vector3.new(0, 5, -190))

	print("[WorldBuilder] Generated 12 green MobSpawns markers in Workspace.World.Locations.Loc01.MobSpawns!")
end

return WorldBuilderService
