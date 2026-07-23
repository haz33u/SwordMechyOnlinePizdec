--[[
	Run this script in Roblox Studio Command Bar (or via plugin) to generate permanent 
	MobSpawns markers in Workspace.World.Locations.Loc01.MobSpawns!
	
	Command Bar 1-liner:
	require(game:GetService("ServerScriptService").Services.WorldBuilderService).GenerateStudioMarkers()
]]

local Workspace = game:GetService("Workspace")

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

local function makeMarker(parent: Instance, name: string, mobId: string, zone: string, pos: Vector3)
	local existing = parent:FindFirstChild(name)
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
	p.Parent = parent
	return p
end

local function generate()
	local world = ensureFolder(Workspace, "World")
	local locations = ensureFolder(world, "Locations")
	local loc01 = ensureFolder(locations, "Loc01")
	local spawnsFolder = ensureFolder(loc01, "MobSpawns")

	print("[StudioMarkers] Creating permanent markers in Workspace.World.Locations.Loc01.MobSpawns...")

	-- Camp A (Goblin Entrance)
	makeMarker(spawnsFolder, "Spawn_A1", "L1_Goblin", "A", Vector3.new(-20, 3, 40))
	makeMarker(spawnsFolder, "Spawn_A2", "L1_Goblin", "A", Vector3.new(20, 3, 40))
	makeMarker(spawnsFolder, "Spawn_A3", "L1_Goblin", "A", Vector3.new(-35, 3, 60))
	makeMarker(spawnsFolder, "Spawn_A4", "L1_Goblin", "A", Vector3.new(35, 3, 60))

	-- Camp B (Dark Goblin Mid Field)
	makeMarker(spawnsFolder, "Spawn_B1", "L1_DarkGoblin", "B", Vector3.new(-30, 3, -15))
	makeMarker(spawnsFolder, "Spawn_B2", "L1_DarkGoblin", "B", Vector3.new(30, 3, -15))
	makeMarker(spawnsFolder, "Spawn_B3", "L1_DarkGoblin", "B", Vector3.new(-45, 3, 0))
	makeMarker(spawnsFolder, "Spawn_B4", "L1_DarkGoblin", "B", Vector3.new(45, 3, 0))

	-- Camp C (Goblin Warrior Forge)
	makeMarker(spawnsFolder, "Spawn_C1", "L1_GoblinWarrior", "C", Vector3.new(-35, 3, -75))
	makeMarker(spawnsFolder, "Spawn_C2", "L1_GoblinWarrior", "C", Vector3.new(35, 3, -75))
	makeMarker(spawnsFolder, "Spawn_C3", "L1_GoblinWarrior", "C", Vector3.new(0, 3, -95))

	-- Camp D (Goblin Scout Gate)
	makeMarker(spawnsFolder, "Spawn_D1", "L1_GoblinScout", "D", Vector3.new(-20, 3, -130))
	makeMarker(spawnsFolder, "Spawn_D2", "L1_GoblinScout", "D", Vector3.new(20, 3, -130))

	-- Boss Arena (Goblin King)
	makeMarker(spawnsFolder, "Spawn_Boss", "L1_GoblinKing", "Boss", Vector3.new(0, 5, -190))

	print("[StudioMarkers] Done! 12 permanent markers generated in Workspace. You can now freely move and edit them in Studio Workspace.")
end

return { Generate = generate }
