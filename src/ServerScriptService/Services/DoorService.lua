--!strict
--[[
	Physical door/portals teleport system.

	Convention:
	  Workspace.World.Locations.LocXX.Doors.<any BasePart>
	    Attribute "DoorLocationId" = number (target location)

	On touch: validate unlock (rebirth + purchased), then teleport.
	No NPCs required — doors are part of the map art.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LocationConfig = require(Shared.Config.LocationConfig)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)
local LocationService = require(script.Parent.LocationService)

local DoorService = {}

local COOLDOWN_SECONDS = 1.5
local _lastTouch = {} :: { [number]: number }
--- Guards against double-wiring: Init() sweeps existing parts and DescendantAdded
--- can fire for the same part again (e.g. re-parented art).
local _wired = {} :: { [BasePart]: boolean }

local function isDoor(part: BasePart): boolean
	local attr = part:GetAttribute("DoorLocationId")
	return typeof(attr) == "number" and attr > 0
end

local function getDoorTarget(part: BasePart): number?
	local attr = part:GetAttribute("DoorLocationId")
	if typeof(attr) == "number" and attr > 0 then
		return attr
	end
	return nil
end

local function onTouch(part: BasePart, other: BasePart)
	local targetId = getDoorTarget(part)
	if not targetId then
		return
	end

	local player = Players:GetPlayerFromCharacter(other.Parent)
	if not player then
		return
	end
	if player.Character ~= other.Parent then
		return
	end
	local hum = other.Parent:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	local now = os.clock()
	local last = _lastTouch[player.UserId] or 0
	if now - last < COOLDOWN_SECONDS then
		return
	end
	_lastTouch[player.UserId] = now

	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local loc = LocationConfig.Get(targetId)
	if not loc then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Unknown location %d", targetId),
			color = "red",
		})
		return
	end

	local unlocked = ProfileService.IsLocationUnlocked(profile, targetId)
	if not unlocked then
		local needRebirth = loc.unlockRebirth or 0
		local rb = profile.rebirthLevel or 0
		if needRebirth > 0 and rb < needRebirth then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("%s locked — need Rebirth %d (you are R%d)", loc.name, needRebirth, rb),
				color = "red",
			})
			return
		end
		local travelCost = loc.travelCostCoins or 0
		if travelCost > 0 and (profile.coins or 0) < travelCost then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("%s locked — need %s coins", loc.name, tostring(travelCost)),
				color = "red",
			})
			return
		end
	end

	-- Reuse LocationService logic (handles coins, unlock flags, mob spawn).
	local ok, err = pcall(LocationService.Set, player, targetId)
	if not ok then
		warn("[DoorService] teleport failed:", err)
		Remotes.Event("Notify"):FireClient(player, {
			text = "Teleport failed. Please try again.",
			color = "red",
		})
	end
end

--[[
	Wire a door part for touch.

	Deliberately does NOT change Transparency/CanCollide: doors are map art and
	an artist-placed visible portal must stay visible. If a specific door should
	be an invisible trigger volume, set that on the part itself in Studio.

	Only CanTouch is forced on, since a part with CanTouch=false never fires.
]]
local function wireDoor(part: BasePart)
	if not isDoor(part) then
		return
	end
	if _wired[part] then
		return
	end
	_wired[part] = true
	part.CanTouch = true
	part.Touched:Connect(function(other)
		onTouch(part, other)
	end)
end

function DoorService.Init()
	for _, desc in Workspace:GetDescendants() do
		if desc:IsA("BasePart") then
			wireDoor(desc)
		end
	end
	Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			wireDoor(desc)
		end
	end)
	print("[DoorService] wired physical doors")
end

return DoorService