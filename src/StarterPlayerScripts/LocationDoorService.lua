--!strict
--[[
	LocationDoorService — Handles zone transition doors & barrier walls between locations.
	Features:
	  - Finds door/wall parts in Workspace ("Doors -1", "Doors-1", "Door", "Loc2Door", "Gate", etc.)
	  - Attaches SurfaceGuis on BOTH sides of the wall + 3D BillboardGui overhead:
	      🔒 AREA LOCKED
	      ⚡ REQUIRES REBIRTH 1
	      🏆 REQUIRED TITLE: "Tarnished Blade"
	  - Gives barrier a glowing ForceField effect when locked.
	  - Fades away barrier (CanCollide = false, Transparency = 1) when player reaches required Rebirth.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LocationConfig = require(Shared.Config.LocationConfig)
local RebirthConfig = require(Shared.Config.RebirthConfig)

local LocationDoorService = {}

local boundDoors: { [Instance]: boolean } = {}
local doorObjects: { { model: Instance, primary: BasePart, reqRebirth: number, reqTitle: string, targetLocId: number, tag: BillboardGui?, surfaceFront: SurfaceGui?, surfaceBack: SurfaceGui? } } = {}

local function createSurfaceLock(anchor: BasePart, face: Enum.NormalId, reqRebirth: number, titleName: string, locName: string): SurfaceGui
	local name = "DoorSurface_" .. face.Name
	local old = anchor:FindFirstChild(name)
	if old then
		old:Destroy()
	end

	local sg = Instance.new("SurfaceGui")
	sg.Name = name
	sg.Face = face
	sg.CanvasSize = Vector2.new(800, 450)
	sg.AlwaysOnTop = false
	sg.Parent = anchor

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = sg

	-- Top Lock Header
	local lockHeader = Instance.new("TextLabel")
	lockHeader.Size = UDim2.new(1, 0, 0, 90)
	lockHeader.Position = UDim2.fromScale(0, 0.05)
	lockHeader.BackgroundTransparency = 1
	lockHeader.Font = Enum.Font.Arcade
	lockHeader.TextSize = 58
	lockHeader.TextColor3 = Color3.fromRGB(255, 60, 70)
	lockHeader.Text = "🔒 AREA LOCKED"
	lockHeader.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lockHeader.TextStrokeTransparency = 0.1
	lockHeader.Parent = container

	-- Rebirth Requirement Line
	local rebLine = Instance.new("TextLabel")
	rebLine.Size = UDim2.new(1, 0, 0, 75)
	rebLine.Position = UDim2.fromScale(0, 0.30)
	rebLine.BackgroundTransparency = 1
	rebLine.Font = Enum.Font.Arcade
	rebLine.TextSize = 46
	rebLine.TextColor3 = Color3.fromRGB(255, 215, 80)
	rebLine.Text = string.format("⚡ REQUIRES REBIRTH %d", reqRebirth)
	rebLine.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rebLine.TextStrokeTransparency = 0.15
	rebLine.Parent = container

	-- Title Requirement Line
	local titleLine = Instance.new("TextLabel")
	titleLine.Size = UDim2.new(1, 0, 0, 70)
	titleLine.Position = UDim2.fromScale(0, 0.52)
	titleLine.BackgroundTransparency = 1
	titleLine.Font = Enum.Font.Arcade
	titleLine.TextSize = 38
	titleLine.TextColor3 = Color3.fromRGB(100, 220, 255)
	titleLine.Text = string.format("🏆 REQUIRED TITLE: \"%s\"", titleName)
	titleLine.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLine.TextStrokeTransparency = 0.2
	titleLine.Parent = container

	-- Location Subtitle Line
	local subLine = Instance.new("TextLabel")
	subLine.Size = UDim2.new(1, 0, 0, 50)
	subLine.Position = UDim2.fromScale(0, 0.76)
	subLine.BackgroundTransparency = 1
	subLine.Font = Enum.Font.Arcade
	subLine.TextSize = 28
	subLine.TextColor3 = Color3.fromRGB(230, 230, 240)
	subLine.Text = string.format("Reach Rebirth %d to enter %s", reqRebirth, locName)
	subLine.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	subLine.TextStrokeTransparency = 0.25
	subLine.Parent = container

	return sg
end

local function createDoorTag(anchor: BasePart, reqRebirth: number, titleName: string, locName: string): BillboardGui
	local old = anchor:FindFirstChild("DoorLockTag")
	if old then
		old:Destroy()
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "DoorLockTag"
	bb.Size = UDim2.fromOffset(340, 85)
	bb.StudsOffset = Vector3.new(0, 7.0, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 36)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextSize = 22
	title.TextColor3 = Color3.fromRGB(255, 70, 80)
	title.Text = string.format("🔒 REQUIRES REBIRTH %d", reqRebirth)
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.15
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Size = UDim2.new(1, 0, 0, 24)
	sub.Position = UDim2.fromOffset(0, 36)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Arcade
	sub.TextSize = 14
	sub.TextColor3 = Color3.fromRGB(255, 215, 80)
	sub.Text = string.format("🏆 Title: \"%s\" · %s", titleName, locName)
	sub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	sub.TextStrokeTransparency = 0.25
	sub.Parent = bb

	return bb
end

function LocationDoorService.Init(store: any, toastApi: any?)
	local player = Players.LocalPlayer

	local function findDoorInstances(): { Instance }
		local list: { Instance } = {}
		for _, item in Workspace:GetDescendants() do
			if item:IsA("Model") or item:IsA("BasePart") then
				local lowerName = string.lower(item.Name)
				if string.find(lowerName, "door") or string.find(lowerName, "gate") or string.find(lowerName, "wall") or item:GetAttribute("UnlockRebirth") ~= nil then
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

		-- Read rebirth requirement attribute, or default to Location 2 requirement (Rebirth 1)
		local reqRebirth = inst:GetAttribute("UnlockRebirth")
		if typeof(reqRebirth) ~= "number" then
			local loc2 = LocationConfig.Get(2)
			reqRebirth = (loc2 and loc2.unlockRebirth) or 1
		end

		local reqNum = reqRebirth :: number
		local titleName = RebirthConfig.GetRankName(reqNum)
		local loc2Meta = LocationConfig.Get(2)
		local locName = (loc2Meta and loc2Meta.name) or "Location 2"

		local tag = createDoorTag(anchor, reqNum, titleName, locName)
		local sFront = createSurfaceLock(anchor, Enum.NormalId.Front, reqNum, titleName, locName)
		local sBack = createSurfaceLock(anchor, Enum.NormalId.Back, reqNum, titleName, locName)

		table.insert(doorObjects, {
			model = inst,
			primary = anchor,
			reqRebirth = reqNum,
			reqTitle = titleName,
			targetLocId = 2,
			tag = tag,
			surfaceFront = sFront,
			surfaceBack = sBack,
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
				if rebirth < reqNum and toastApi then
					toastApi.Show(string.format("🔒 Requires Rebirth %d (Title: \"%s\") to enter %s!", reqNum, titleName, locName), "yellow")
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

			-- Update visibility, material, and collision of door parts
			if data.model:IsA("BasePart") then
				data.model.CanCollide = not isUnlocked
				data.model.Transparency = isUnlocked and 1 or 0.4
				if not isUnlocked then
					data.model.Material = Enum.Material.ForceField
					data.model.Color = Color3.fromRGB(220, 50, 60)
				end
			else
				for _, part in data.model:GetDescendants() do
					if part:IsA("BasePart") then
						part.CanCollide = not isUnlocked
						part.Transparency = isUnlocked and 1 or 0.4
						if not isUnlocked then
							part.Material = Enum.Material.ForceField
							part.Color = Color3.fromRGB(220, 50, 60)
						end
					end
				end
			end

			-- Update UI Tags
			if data.tag then
				data.tag.Enabled = not isUnlocked
			end
			if data.surfaceFront then
				data.surfaceFront.Enabled = not isUnlocked
			end
			if data.surfaceBack then
				data.surfaceBack.Enabled = not isUnlocked
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

	print("[LocationDoorService] Initialized — monitoring zone doors for Rebirth & Title unlocks")
end

return LocationDoorService
