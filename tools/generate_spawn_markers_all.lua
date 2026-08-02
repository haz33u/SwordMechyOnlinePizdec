--[[
	Universal Studio Command Bar script.
	Creates MobSpawns markers for any location (1-7) under
	Workspace.World.Locations.LocXX.MobSpawns.

	Usage:
	1. Open SwordMasters_Loc1-7.rbxlx in Studio (or synced place).
	2. Paste this entire file into Command Bar.
	3. Set LOCATION_ID below to the location you want to generate.
	4. Set CLEAR_EXISTING = true to remove old markers first.
	5. Run.
	6. Drag markers onto your Art and save.

	Each marker has attributes:
	  MobId       = e.g. "L5_CinderWolf"
	  Zone        = A/B/C/D/Boss
	  Model       = preferred model name (same as MobId by default; edit to assign custom model)
	  DisplayName = readable name
	  IsSpawnMarker = true
]]

local LOCATION_ID = 1 -- change to 2..7 as needed
local CLEAR_EXISTING = false -- set true to wipe old markers before generating

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MobConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.MobConfig)
local LocationConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LocationConfig)
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.WorldConfig)

local ZONE_COLOR = {
	A = Color3.fromRGB(100, 200, 100),
	B = Color3.fromRGB(100, 160, 255),
	C = Color3.fromRGB(200, 120, 255),
	D = Color3.fromRGB(180, 80, 220),
	Boss = Color3.fromRGB(230, 60, 60),
}

local function ensureLocationsFolder(): Folder
	local world = Workspace:FindFirstChild("World")
	if not world then
		world = Instance.new("Folder")
		world.Name = "World"
		world.Parent = Workspace
	end
	local locations = world:FindFirstChild("Locations")
	if not locations then
		locations = Instance.new("Folder")
		locations.Name = "Locations"
		locations.Parent = world
	end
	return locations :: Folder
end

local function getLocFolder(locations: Folder, locationId: number): Folder
	local name = string.format("Loc%02d", locationId)
	local folder = locations:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = locations
	end
	return folder :: Folder
end

local function makeMarker(mobId: string, zone: string, index: number, total: number, folder: Folder)
	local def = MobConfig.Get(mobId)
	if not def then
		warn("Unknown mob: " .. tostring(mobId))
		return
	end

	local locationId = def.location
	local c = WorldConfig.GetIslandCenter(locationId)
	local angle = (index / math.max(total, 1)) * math.pi * 2
	local rMin, rMax = WorldConfig.GetZoneRadii(zone)
	if zone == "Boss" then
		rMin, rMax = 0, WorldConfig.GetHalfSize() * WorldConfig.BOSS_FRACTION
	end
	local r = (rMin + rMax) / 2
	local pos = Vector3.new(
		c.X + math.cos(angle) * r,
		WorldConfig.FLOOR_Y + 4,
		c.Z + math.sin(angle) * r
	)

	local p = Instance.new("Part")
	p.Name = string.format("%s_%02d", mobId, index)
	p.Size = Vector3.new(3, 0.4, 3)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = ZONE_COLOR[zone] or Color3.fromRGB(200, 200, 200)
	p.Transparency = 0.35
	p.CFrame = CFrame.new(pos)
	p:SetAttribute("MobId", mobId)
	p:SetAttribute("Zone", zone)
	p:SetAttribute("Model", mobId)
	p:SetAttribute("DisplayName", def.name)
	p:SetAttribute("IsSpawnMarker", true)
	p.Parent = folder
	return p
end

local function generateLocation(locationId: number)
	local locDef = LocationConfig.Get(locationId)
	if not locDef then
		warn("No LocationConfig for Loc" .. tostring(locationId))
		return
	end

	local locations = ensureLocationsFolder()
	local locFolder = getLocFolder(locations, locationId)
	local spawnFolder = locFolder:FindFirstChild("MobSpawns")
	if spawnFolder then
		if CLEAR_EXISTING then
			spawnFolder:ClearAllChildren()
		elseif #spawnFolder:GetChildren() > 0 then
			print(string.format("[Markers] Loc%d already has %d markers -- skipped (set CLEAR_EXISTING=true to overwrite)", locationId, #spawnFolder:GetChildren()))
			return
		end
	else
		spawnFolder = Instance.new("Folder")
		spawnFolder.Name = "MobSpawns"
		spawnFolder.Parent = locFolder
	end

	for _, spawn in ipairs(locDef.mobs) do
		for i = 1, spawn.count do
			makeMarker(spawn.mobId, spawn.zone, i, spawn.count, spawnFolder)
		end
	end

	if locDef.bossId then
		makeMarker(locDef.bossId, "Boss", 1, 1, spawnFolder)
	end

	print(string.format("[Markers] Loc%d created %d markers", locationId, #spawnFolder:GetChildren()))
end

generateLocation(LOCATION_ID)
print("[Markers] Done. Drag markers onto your Art and save.")
