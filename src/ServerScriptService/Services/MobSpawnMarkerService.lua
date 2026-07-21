--!strict
--[[
	Reads EDIT-MODE spawn markers from the Place.

	Convention (you control these in Studio, visible without Play):
	  Workspace.World.Locations.Loc01.MobSpawns.<any Part>
	    Attributes:
	      MobId  (string) required  e.g. "L1_Goblin", "L1_Boss", "DEBUG_Dummy"
	      (legacy MobIds like L1_Slime resolve via MobConfig.ResolveId)
	      Zone   (string) optional  e.g. "A"

	If no markers found for a location → fallback to WorldConfig math + LocationConfig counts.
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)
local WorldConfig = require(Shared.Config.WorldConfig)

export type SpawnPoint = {
	mobId: string,
	position: Vector3,
	zone: string,
	markerName: string,
	marker: BasePart?,
}

local MobSpawnMarkerService = {}

local function getLocFolder(locationId: number): Instance?
	local name = string.format("Loc%02d", locationId)
	local world = Workspace:FindFirstChild("World")
	if world then
		local locations = world:FindFirstChild("Locations")
		if locations then
			local loc = locations:FindFirstChild(name)
			if loc then
				return loc
			end
		end
		local loc2 = world:FindFirstChild(name)
		if loc2 then
			return loc2
		end
	end
	return Workspace:FindFirstChild(name)
end

function MobSpawnMarkerService.GetMobSpawnsFolder(locationId: number): Folder?
	local loc = getLocFolder(locationId)
	if not loc then
		return nil
	end
	local f = loc:FindFirstChild("MobSpawns")
	if f and f:IsA("Folder") then
		return f
	end
	return nil
end

--- Collect all marker parts under LocXX.MobSpawns
function MobSpawnMarkerService.Collect(locationId: number): { SpawnPoint }
	local points: { SpawnPoint } = {}
	local folder = MobSpawnMarkerService.GetMobSpawnsFolder(locationId)
	if not folder then
		return points
	end

	for _, child in folder:GetDescendants() do
		if child:IsA("BasePart") then
			local mobId = child:GetAttribute("MobId")
			if typeof(mobId) == "string" and mobId ~= "" then
				local def = MobConfig.Get(mobId)
				if def then
					local zone = child:GetAttribute("Zone")
					if typeof(zone) ~= "string" or zone == "" then
						zone = def.defaultZone
					end
					table.insert(points, {
						mobId = mobId,
						position = child.Position,
						zone = zone :: string,
						markerName = child.Name,
						marker = child,
					})
				else
					warn("[MobSpawns] Unknown MobId on marker:", child:GetFullName(), mobId)
				end
			end
		end
	end

	return points
end

function MobSpawnMarkerService.HasMarkers(locationId: number): boolean
	return #MobSpawnMarkerService.Collect(locationId) > 0
end

--[[
	Create default marker layout in EDIT (or first run).
	Does NOT spawn combat mobs — only gold/cyan anchor parts you can drag.
]]
function MobSpawnMarkerService.EnsureDefaultMarkers(locationId: number, spawnTable: { any }, bossId: string?, debugMobs: { any }?)
	local locFolder = getLocFolder(locationId)
	if not locFolder then
		-- create minimal hierarchy so markers exist in place
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
		locFolder = Instance.new("Folder")
		locFolder.Name = string.format("Loc%02d", locationId)
		locFolder.Parent = locations
	end

	local folder = locFolder:FindFirstChild("MobSpawns")
	if folder and folder:IsA("Folder") and #folder:GetChildren() > 0 then
		-- already have markers — never overwrite your placement
		print(string.format("[MobSpawns] Loc%d already has %d markers — skip ensure", locationId, #folder:GetChildren()))
		return folder :: Folder
	end

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "MobSpawns"
		folder.Parent = locFolder
	end

	local function makeMarker(mobId: string, zone: string, index: number, total: number, color: Color3)
		local pos = WorldConfig.GetZonePoint(locationId, zone, index, total)
		local p = Instance.new("Part")
		p.Name = string.format("%s_%02d", mobId, index)
		p.Size = Vector3.new(3, 0.4, 3)
		p.Anchored = true
		p.CanCollide = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = 0.35
		p.CFrame = CFrame.new(pos)
		p:SetAttribute("MobId", mobId)
		p:SetAttribute("Zone", zone)
		p:SetAttribute("IsSpawnMarker", true)
		p.Parent = folder

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(120, 28)
		bb.StudsOffset = Vector3.new(0, 2, 0)
		bb.AlwaysOnTop = true
		bb.Parent = p
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 0.4
		lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.Text = mobId
		lbl.Parent = bb

		return p
	end

	local ZONE_COLOR = {
		A = Color3.fromRGB(100, 200, 100),
		B = Color3.fromRGB(100, 160, 255),
		C = Color3.fromRGB(200, 120, 255),
		Boss = Color3.fromRGB(230, 60, 60),
		Debug = Color3.fromRGB(255, 200, 40),
	}

	for _, spawn in spawnTable do
		for i = 1, spawn.count do
			makeMarker(spawn.mobId, spawn.zone, i, spawn.count, ZONE_COLOR[spawn.zone] or Color3.fromRGB(200, 200, 200))
		end
	end

	if bossId then
		makeMarker(bossId, "Boss", 1, 1, ZONE_COLOR.Boss)
	end

	if debugMobs then
		for _, spawn in debugMobs do
			for i = 1, spawn.count do
				makeMarker(spawn.mobId, spawn.zone or "Debug", i, spawn.count, ZONE_COLOR.Debug)
			end
		end
	end

	-- PlayerSpawn if missing
	if not locFolder:FindFirstChild("PlayerSpawn", true) then
		local c = WorldConfig.GetIslandCenter(locationId)
		local sp = Instance.new("Part")
		sp.Name = "PlayerSpawn"
		sp.Size = Vector3.new(8, 1, 8)
		sp.Anchored = true
		sp.CanCollide = false
		sp.Color = Color3.fromRGB(80, 255, 120)
		sp.Material = Enum.Material.Neon
		sp.Transparency = 0.3
		sp.CFrame = CFrame.new(c.X, WorldConfig.FLOOR_Y + 1, c.Z)
		sp.Parent = locFolder
	end

	print(string.format("[MobSpawns] Loc%d created %d markers under %s", locationId, #folder:GetChildren(), folder:GetFullName()))
	return folder :: Folder
end

return MobSpawnMarkerService
