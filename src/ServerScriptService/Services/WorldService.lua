--!strict
--[[
	BACKEND ONLY — no parts, no scaffold, no UI.

	- Resolve spawn from YOUR map (PlayerSpawn parts)
	- Teleport when location changes
	- Never creates Workspace geometry
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local WorldConfig = require(Shared.Config.WorldConfig)

local WorldService = {}

function WorldService.Init()
	print(string.format(
		"[WorldService] backend-only | %d locs | no build",
		#WorldConfig.Locations
	))
end

function WorldService.FindSpawnPart(locationId: number): BasePart?
	local name = string.format("Loc%02d", locationId)

	local function searchUnder(root: Instance?): BasePart?
		if not root then
			return nil
		end
		local locations = root:FindFirstChild("Locations")
		local locFolder: Instance? = nil
		if locations then
			locFolder = locations:FindFirstChild(name)
		end
		if not locFolder then
			locFolder = root:FindFirstChild(name)
		end
		if not locFolder then
			return nil
		end
		local spawn = locFolder:FindFirstChild("PlayerSpawn", true)
		if spawn and spawn:IsA("BasePart") then
			return spawn
		end
		return nil
	end

	local world = Workspace:FindFirstChild("World")
	local found = searchUnder(world)
	if found then
		return found
	end
	return searchUnder(Workspace)
end

function WorldService.GetSpawnCFrame(locationId: number): CFrame?
	local part = WorldService.FindSpawnPart(locationId)
	if part then
		return part.CFrame + Vector3.new(0, 3, 0)
	end
	return nil
end

function WorldService.TeleportToLocation(player: Player, locationId: number): boolean
	local cf = WorldService.GetSpawnCFrame(locationId)
	if not cf then
		return false
	end
	local char = player.Character
	if not char then
		return false
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	hrp.CFrame = cf
	return true
end

function WorldService.TeleportToCFrame(player: Player, cf: CFrame): boolean
	local char = player.Character
	if not char then
		return false
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	hrp.CFrame = cf
	return true
end

function WorldService.GetConfigCenter(locationId: number): Vector3
	return WorldConfig.GetIslandCenter(locationId)
end

return WorldService
