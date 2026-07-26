--!strict
--[[
	WorldBuilderService — Builds procedural 3D map scaffold & props for Location 1: "Dark Goblin Forest".
	Generates 4 themed Goblin Camps (A, B, C, D) + Boss Arena with wood huts, bonfires, gates, & MobSpawns markers.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

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
	p:SetAttribute("MobId", mobId)
	p:SetAttribute("Zone", zone)
	p.Parent = parent
end

function WorldBuilderService.Init()
	-- Procedural generation disabled: player created their own custom map in Studio!
	print("[WorldBuilder] Procedural map generation disabled — using Studio custom map")
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
