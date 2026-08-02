--[[
	Studio Command Bar script.
	Removes all MobSpawns markers for a chosen location (1-7).

	Usage:
	1. Set LOCATION_ID below.
	2. Paste into Command Bar and run.
]]

local LOCATION_ID = 1 -- change to 2..7 as needed; set to "all" to wipe every location

local Workspace = game:GetService("Workspace")

local function clearLocation(locationId: number)
	local name = string.format("Loc%02d", locationId)
	local world = Workspace:FindFirstChild("World")
	local locFolder = world and world:FindFirstChild("Locations") and world.Locations:FindFirstChild(name)
	if not locFolder then
		locFolder = Workspace:FindFirstChild(name)
	end
	if not locFolder then
		warn("Loc" .. tostring(locationId) .. " folder not found")
		return
	end
	local spawnFolder = locFolder:FindFirstChild("MobSpawns")
	if spawnFolder then
		spawnFolder:ClearAllChildren()
		print("[Markers] Cleared MobSpawns for Loc" .. tostring(locationId))
	else
		print("[Markers] No MobSpawns folder for Loc" .. tostring(locationId))
	end
end

if LOCATION_ID == "all" then
	for i = 1, 7 do
		clearLocation(i)
	end
else
	clearLocation(LOCATION_ID)
end
