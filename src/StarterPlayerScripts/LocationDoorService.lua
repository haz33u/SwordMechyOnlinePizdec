--!strict
--[[
	LocationDoorService — Handles zone transition doors & gates between locations.
	Features:
	  - Finds door parts/models in Workspace (e.g. "Door", "Loc2Door", "Gate", "Door1", etc.)
	  - Attaches 3D overhead lock labels ("🔒 REQUIRES REBIRTH 1")
	  - Dynamically opens doors (CanCollide = false, Transparency = 1) when player reaches required Rebirth.
	  - Notifies player if trying to pass a locked door.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LocationConfig = require(Shared.Config.LocationConfig)

local LocationDoorService = {}

local boundDoors: { [Instance]: boolean } = {}
local doorObjects: { { model: Instance, primary: BasePart, reqRebirth: number, targetLocId: number, tag: BillboardGui? } } = {}

local function createDoorTag(anchor: BasePart, reqRebirth: number, locName: string): BillboardGui
	local old = anchor:FindFirstChild("DoorLockTag")
	if old then
		old:Destroy()
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "DoorLockTag"
	bb.Size = UDim2.fromOffset(280, 70)
	bb.StudsOffset = Vector3.new(0, 5.0, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	bb.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 34)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextSize = 22
	title.TextColor3 = Color3.fromRGB(255, 80, 80)
	title.Text = string.format("🔒 REQUIRES REBIRTH %d", reqRebirth)
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.15
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Size = UDim2.new(1, 0, 0, 24)
	sub.Position = UDim2.fromOffset(0, 34)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Arcade
	sub.TextSize = 14
	sub.TextColor3 = Color3.fromRGB(255, 215, 80)
	sub.Text = string.format("Unlock %s", locName)
	sub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	sub.TextStrokeTransparency = 0.25
	sub.Parent = bb

	return bb
end

function LocationDoorService.Init(store: any, toastApi: any?)
	local player = Players.LocalPlayer

	local function findDoorInstances(): { Instance }
		local list: { Instance } = {}
		local names = { "Door", "Loc2Door", "Loc02Door", "Gate", "Door1", "LocationDoor", "ZoneDoor", "Loc2_Gate", "Door_Loc2" }
		for _, name in names do
			for _, item in Workspace:GetDescendants() do
				if item.Name == name and (item:IsA("Model") or item:IsA("BasePart")) then
					if not boundDoors[item] then
						table.insert(list, item)
					end
				end
			end
		end
		return list
	end

	local function setupDoor(inst: Instance)
		boundDoors[inst] = true

		local anchor: BasePart? = nil
		if inst:IsA("Model") then
			anchor = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		elseif inst:IsA("BasePart") then
			anchor = inst
		end

		if not anchor then
			return
		end

		-- Read rebirth requirement attribute, or default to Location 2 rebirth requirement (Rebirth 1)
		local reqRebirth = inst:GetAttribute("UnlockRebirth")
		if typeof(reqRebirth) ~= "number" then
			local loc2 = LocationConfig.Get(2)
			reqRebirth = (loc2 and loc2.unlockRebirth) or 1
		end

		local loc2Meta = LocationConfig.Get(2)
		local locName = (loc2Meta and loc2Meta.name) or "Location 2"

		local tag = createDoorTag(anchor, reqRebirth :: number, locName)

		table.insert(doorObjects, {
			model = inst,
			primary = anchor,
			reqRebirth = reqRebirth :: number,
			targetLocId = 2,
			tag = tag,
		})

		-- Touch lock notification when player walks into locked door
		local function onTouch(hit: Instance)
			if not hit or not hit.Parent then
				return
			end
			local char = player.Character
			if char and (hit:IsDescendantOf(char) or hit.Parent:FindFirstChildOfClass("Humanoid") ~= nil) then
				local stats = store:PeekStats() or {}
				local rebirth = stats.rebirthLevel or 0
				if rebirth < (reqRebirth :: number) and toastApi then
					toastApi.Show(string.format("🔒 Requires Rebirth %d to open %s!", reqRebirth, locName), "yellow")
				end
			end
		end

		if inst:IsA("BasePart") then
			inst.Touched:Connect(onTouch)
		else
			for _, part in inst:GetDescendants() do
				if part:IsA("BasePart") then
					part.Touched:Connect(onTouch)
				end
			end
		end
	end

	local function refreshDoorStates()
		local stats = store:PeekStats() or {}
		local playerRebirth = stats.rebirthLevel or 0

		for _, data in doorObjects do
			local isUnlocked = playerRebirth >= data.reqRebirth

			-- Update visibility and collision of door parts
			if data.model:IsA("BasePart") then
				data.model.CanCollide = not isUnlocked
				data.model.Transparency = isUnlocked and 0.85 or 0
			else
				for _, part in data.model:GetDescendants() do
					if part:IsA("BasePart") then
						part.CanCollide = not isUnlocked
						part.Transparency = isUnlocked and 0.85 or 0
					end
				end
			end

			-- Update 3D Overhead Lock Tag
			if data.tag then
				data.tag.Enabled = not isUnlocked
			end
		end
	end

	-- Initial scanner loop
	task.spawn(function()
		for _ = 1, 5 do
			for _, door in findDoorInstances() do
				setupDoor(door)
			end
			refreshDoorStates()
			task.wait(1)
		end
	end)

	-- Monitor player stats changes to dynamically open/close doors
	pcall(function()
		scope:Observer(store.stats):onChange(function()
			refreshDoorStates()
		end)
	end)

	print("[LocationDoorService] Initialized — monitoring zone doors for Rebirth unlocks")
end

return LocationDoorService
