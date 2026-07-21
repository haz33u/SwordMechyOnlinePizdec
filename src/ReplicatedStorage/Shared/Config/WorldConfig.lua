--!strict
--[[
	WORLD — Phase 1: 4 LARGE territories (not 18 mini-islands).

	Each location ≈ full themed map for atmosphere building.
	Travel between them = teleport.

	Scale notes (studs):
	  WalkSpeed 16 → cross 1200 studs ≈ 75 sec
	  Good for forests / villages / multi-POI

	Art ownership:
	  Workspace.World.Locations.Loc0N.Art  → NEVER modified by code
	  Workspace.World.Locations.Loc0N.Scaffold → optional grey guides
]]

export type WorldLocationMeta = {
	id: number,
	name: string,
	theme: string,
	unlockPower: number, -- soft recommend (0 = ignore)
	unlockRebirth: number?, -- min rebirthLevel to unlock (Loc2 = 2)
	travelCostCoins: number?, -- one-time buy (Cristalix Loc2 = 500K)
	coinMult: number,
	powerMult: number,
	status: string, -- stub | wip | ready
	blurb: string,
}

local WorldConfig = {
	-- ═══════════════════════════════════════
	-- PHASE: only these locations exist in world
	-- Later: add Loc05… without shrinking these
	-- ═══════════════════════════════════════
	PHASE = 1,
	LOCATION_COUNT = 4,

	-- ONE territory size (square playable floor)
	-- Was 280 (too small). Now room for atmosphere.
	ISLAND_SIZE = 1200,
	ISLAND_HEIGHT = 8,

	-- Gap between territory edges
	ISLAND_GAP = 400,

	-- Center-to-center
	ISLAND_PITCH = 1600, -- 1200 + 400

	-- 2×2 grid for 4 territories
	GRID_COLUMNS = 2,
	GRID_ROWS = 2,

	GRID_ORIGIN = Vector3.new(0, 0, 0),

	-- Shared lobby (menus, AFK, shop later)
	LOBBY_CENTER = Vector3.new(0, 40, -2000),
	LOBBY_SIZE = 200,

	FLOOR_Y = 0,
	SPAWN_Y_OFFSET = 8,
	VOID_KILL_Y = -200,
	BOUND_PADDING = 16,

	--[[
		Fallback zone rings as FRACTIONS of half-island (half = 600 at size 1200).
		City-scale walk between camps (not playtest postage stamps).
		Used ONLY when LocXX.MobSpawns has no markers.
		Loc1 primary layout = Studio markers on Art BB (see studio_loc1_level_layout.lua).

		Approx radii at half=600:
		  A  72–132, B 168–240, C 288–360, D 408–480, Boss ~480
	]]
	ZONE_FRACTIONS = {
		Spawn = { 0.00, 0.08 },
		A = { 0.12, 0.22 }, -- Camp A — entrance goblins
		B = { 0.28, 0.40 }, -- Camp B — mid city
		C = { 0.48, 0.60 }, -- Camp C — hard lager
		D = { 0.68, 0.80 }, -- Camp D — elite gate
	} :: { [string]: { number } },
	BOSS_FRACTION = 0.80, -- far edge for math fallback

	ZONE_COLORS = {
		Spawn = Color3.fromRGB(80, 200, 120),
		A = Color3.fromRGB(100, 160, 255),
		B = Color3.fromRGB(255, 200, 80),
		C = Color3.fromRGB(255, 120, 60),
		D = Color3.fromRGB(180, 80, 220),
		Boss = Color3.fromRGB(220, 60, 60),
	} :: { [string]: Color3 },

	-- Backend does NOT build anything. These names are for YOUR Studio map convention:
	-- Workspace.World.Locations.Loc01.PlayerSpawn (BasePart)
	ROOT_FOLDER = "World",
	LOCATIONS_FOLDER = "Locations",
	ART_FOLDER = "Art", -- optional; you own it

	--[[
		4 territories for Phase 1.
		Expand later to 8 / 12 / 18 without rescaling these four.
	]]
	Locations = {
		{
			id = 1,
			name = "Goblin City", -- Loc1 art: goblin camps + boss
			theme = "dark_forest",
			unlockPower = 0,
			travelCostCoins = 0, -- free teleport
			coinMult = 1,
			powerMult = 1,
			status = "wip",
			blurb = "Four goblin camps by tier, boss at the far end. Free travel.",
		},
		{
			id = 2,
			name = "Pirate Ship", -- dump: «Пиратский корабль»
			theme = "pirate",
			unlockPower = 0,
			unlockRebirth = 2, -- opens after 2nd rebirth
			travelCostCoins = 500_000, -- dump: «Купить за 500K»
			coinMult = 3,
			powerMult = 4,
			status = "stub",
			blurb = "Needs R2 + 500K once. Cannons, rum, maps.",
		},
		{
			id = 3,
			name = "Shinobi Lands",
			theme = "shinobi",
			unlockPower = 0,
			unlockRebirth = 4, -- placeholder
			travelCostCoins = 5_000_000,
			coinMult = 8,
			powerMult = 12,
			status = "stub",
			blurb = "Village, bridges, training yards, temple.",
		},
		{
			id = 4,
			name = "Polar Tundra",
			theme = "tundra",
			unlockPower = 0,
			unlockRebirth = 6,
			travelCostCoins = 50_000_000,
			coinMult = 18,
			powerMult = 30,
			status = "stub",
			blurb = "Snow, ravines, camp, ice boss.",
		},
	} :: { WorldLocationMeta },
}

function WorldConfig.GetMeta(id: number): WorldLocationMeta?
	return WorldConfig.Locations[id]
end

function WorldConfig.GetHalfSize(): number
	return WorldConfig.ISLAND_SIZE / 2
end

function WorldConfig.GetZoneRadii(zone: string): (number, number)
	local half = WorldConfig.GetHalfSize()
	local frac: { number }? = WorldConfig.ZONE_FRACTIONS[zone]
	if not frac or #frac < 2 then
		return 0, half * 0.2
	end
	return half * frac[1], half * frac[2]
end

function WorldConfig.GetIslandCenter(locationId: number): Vector3
	local idx = locationId - 1
	local col = idx % WorldConfig.GRID_COLUMNS
	local row = math.floor(idx / WorldConfig.GRID_COLUMNS)
	local pitch = WorldConfig.ISLAND_PITCH
	local origin = WorldConfig.GRID_ORIGIN
	return Vector3.new(origin.X + col * pitch, WorldConfig.FLOOR_Y, origin.Z + row * pitch)
end

function WorldConfig.GetIslandBounds(locationId: number): (Vector3, Vector3)
	local c = WorldConfig.GetIslandCenter(locationId)
	local half = WorldConfig.GetHalfSize() - WorldConfig.BOUND_PADDING
	local min = Vector3.new(c.X - half, WorldConfig.VOID_KILL_Y, c.Z - half)
	local max = Vector3.new(c.X + half, c.Y + 400, c.Z + half)
	return min, max
end

function WorldConfig.GetSpawnCFrame(locationId: number): CFrame
	local c = WorldConfig.GetIslandCenter(locationId)
	return CFrame.new(c.X, c.Y + WorldConfig.SPAWN_Y_OFFSET, c.Z)
end

function WorldConfig.GetBossCFrame(locationId: number): CFrame
	local c = WorldConfig.GetIslandCenter(locationId)
	local d = WorldConfig.GetHalfSize() * WorldConfig.BOSS_FRACTION
	return CFrame.new(c.X + d, WorldConfig.FLOOR_Y + WorldConfig.SPAWN_Y_OFFSET, c.Z + d)
end

function WorldConfig.GetZonePoint(locationId: number, zone: string, index: number, total: number): Vector3
	if zone == "Boss" then
		local b = WorldConfig.GetBossCFrame(locationId).Position
		return Vector3.new(b.X, WorldConfig.FLOOR_Y + 4, b.Z)
	end
	-- Debug dummy: right next to spawn
	if zone == "Debug" then
		local c = WorldConfig.GetIslandCenter(locationId)
		local offset = 10 + (index - 1) * 5
		return Vector3.new(c.X + offset, WorldConfig.FLOOR_Y + 4, c.Z + 6)
	end
	local c = WorldConfig.GetIslandCenter(locationId)
	local rMin, rMax = WorldConfig.GetZoneRadii(zone)
	if zone == "Spawn" then
		rMin, rMax = 0, WorldConfig.GetHalfSize() * 0.12
	end
	local r = (rMin + rMax) / 2
	local angle = (index / math.max(total, 1)) * math.pi * 2
	return Vector3.new(c.X + math.cos(angle) * r, WorldConfig.FLOOR_Y + 4, c.Z + math.sin(angle) * r)
end

function WorldConfig.IsInsideLocation(locationId: number, position: Vector3): boolean
	local min, max = WorldConfig.GetIslandBounds(locationId)
	return position.X >= min.X
		and position.X <= max.X
		and position.Z >= min.Z
		and position.Z <= max.Z
		and position.Y >= min.Y
end

function WorldConfig.GetWorldFootprint(): (number, number)
	return WorldConfig.GRID_COLUMNS * WorldConfig.ISLAND_PITCH, WorldConfig.GRID_ROWS * WorldConfig.ISLAND_PITCH
end

return WorldConfig
