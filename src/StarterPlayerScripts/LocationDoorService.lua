--!strict
--[[
	LocationDoorService — Handles zone transition doors & barrier walls between locations.
	Features:
	  - Displays exact user-requested text:
	      🔒 AREA CLOSED
	      ⚡ Get Rebirth 3 to Unlock
	      🏆 Required Title: "Oathbreaker" (glowing in exact Title Index color!)
	  - Supports Workspace.Doors["1"], Workspace.Doors["2"], etc.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LocationConfig = require(Shared.Config.LocationConfig)
local RebirthConfig = require(Shared.Config.RebirthConfig)

local LocationDoorService = {}

local boundDoors: { [Instance]: boolean } = {}
local doorObjects: { { model: Instance, primary: BasePart, reqRebirth: number, reqTitle: string, targetLocId: number, tag: BillboardGui, surfaces: { SurfaceGui } } } = {}

local function colorToHex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local function createSurfaceLock(anchor: BasePart, face: Enum.NormalId, reqRebirth: number, titleName: string, locName: string): SurfaceGui
	local name = "DoorSurface_" .. face.Name
	local old = anchor:FindFirstChild(name)
	if old then
		old:Destroy()
	end

	local rankStyle = RebirthConfig.GetRankStyle(reqRebirth)
	local titleHex = colorToHex(rankStyle.color or Color3.fromRGB(120, 220, 255))

	local sg = Instance.new("SurfaceGui")
	sg.Name = name
	sg.Face = face
	sg.CanvasSize = Vector2.new(1000, 550)
	sg.AlwaysOnTop = false
	sg.LightInfluence = 0
	sg.Parent = anchor

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = sg

	-- Line 1: Area Closed
	local lockHeader = Instance.new("TextLabel")
	lockHeader.Size = UDim2.new(1, 0, 0, 110)
	lockHeader.Position = UDim2.fromScale(0, 0.06)
	lockHeader.BackgroundTransparency = 1
	lockHeader.Font = Enum.Font.Arcade
	lockHeader.TextScaled = true
	lockHeader.TextColor3 = Color3.fromRGB(255, 65, 75)
	lockHeader.Text = "🔒 AREA CLOSED"
	lockHeader.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lockHeader.TextStrokeTransparency = 0
	lockHeader.Parent = container

	-- Line 2: Get Rebirth X to Unlock
	local rebLine = Instance.new("TextLabel")
	rebLine.Size = UDim2.new(1, 0, 0, 95)
	rebLine.Position = UDim2.fromScale(0, 0.32)
	rebLine.BackgroundTransparency = 1
	rebLine.Font = Enum.Font.Arcade
	rebLine.TextScaled = true
	rebLine.TextColor3 = Color3.fromRGB(255, 215, 80)
	rebLine.Text = string.format("Get Rebirth %d to Unlock", reqRebirth)
	rebLine.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rebLine.TextStrokeTransparency = 0
	rebLine.Parent = container

	-- Line 3: Required Title (glowing with exact index color!)
	local titleLine = Instance.new("TextLabel")
	titleLine.Size = UDim2.new(1, 0, 0, 90)
	titleLine.Position = UDim2.fromScale(0, 0.58)
	titleLine.BackgroundTransparency = 1
	titleLine.Font = Enum.Font.Arcade
	titleLine.RichText = true
	titleLine.TextScaled = true
	titleLine.TextColor3 = Color3.fromRGB(240, 240, 250)
	titleLine.Text = string.format("Required Title: <font color=\"%s\">\"%s\"</font>", titleHex, titleName)
	titleLine.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLine.TextStrokeTransparency = 0
	titleLine.Parent = container

	return sg
end

local function createDoorTag(anchor: BasePart, reqRebirth: number, titleName: string, locName: string): BillboardGui
	local old = anchor:FindFirstChild("DoorLockTag")
	if old then
		old:Destroy()
	end

	local rankStyle = RebirthConfig.GetRankStyle(reqRebirth)
	local titleHex = colorToHex(rankStyle.color or Color3.fromRGB(120, 220, 255))

	local bb = Instance.new("BillboardGui")
	bb.Name = "DoorLockTag"
	bb.Size = UDim2.fromOffset(380, 100)
	bb.StudsOffset = Vector3.new(0, 8.0, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 250
	bb.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 42)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextSize = 26
	title.TextColor3 = Color3.fromRGB(255, 70, 80)
	title.Text = "🔒 AREA CLOSED"
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.1
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Size = UDim2.new(1, 0, 0, 28)
	sub.Position = UDim2.fromOffset(0, 42)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Arcade
	sub.RichText = true
	sub.TextSize = 16
	sub.TextColor3 = Color3.fromRGB(255, 215, 80)
	sub.Text = string.format("Get Rebirth %d to Unlock · Title: <font color=\"%s\">\"%s\"</font>", reqRebirth, titleHex, titleName)
	sub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	sub.TextStrokeTransparency = 0.2
	sub.Parent = bb

	return bb
end

function LocationDoorService.Init(store: any, toastApi: any?)
	local player = Players.LocalPlayer

	local function findDoorInstances(): { Instance }
		local list: { Instance } = {}

		-- Purge any accidental SurfaceGuis or Tags created on generic map walls
		for _, desc in Workspace:GetDescendants() do
			if desc.Name == "DoorLockTag" or string.find(desc.Name, "DoorSurface_") then
				local p = desc.Parent
				local pParent = p and p.Parent
				local parentName = pParent and string.lower(pParent.Name) or ""
				if parentName ~= "doors" and parentName ~= "locationdoors" and p and p:GetAttribute("UnlockRebirth") == nil then
					desc:Destroy()
				end
			end
		end

		-- 1. Match ONLY direct children of Workspace.Doors / Workspace.LocationDoors
		local doorsFolder = Workspace:FindFirstChild("Doors") or Workspace:FindFirstChild("LocationDoors")
		if doorsFolder then
			for _, child in doorsFolder:GetChildren() do
				if (child:IsA("Model") or child:IsA("BasePart")) and not boundDoors[child] then
					table.insert(list, child)
				end
			end
		end

		-- 2. Match parts with explicit UnlockRebirth attribute
		for _, item in Workspace:GetDescendants() do
			if (item:IsA("Model") or item:IsA("BasePart")) and item:GetAttribute("UnlockRebirth") ~= nil then
				if not boundDoors[item] then
					table.insert(list, item)
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

		-- Read rebirth requirement from attribute OR item name (e.g. "1" under Doors -> Location 2 unlockRebirth = 3)
		local reqRebirth = inst:GetAttribute("UnlockRebirth")
		if typeof(reqRebirth) ~= "number" then
			local numInName = tonumber(inst.Name)
			if numInName then
				local targetLoc = LocationConfig.Get(numInName + 1)
				reqRebirth = (targetLoc and targetLoc.unlockRebirth) or (numInName * 3)
			else
				local loc2 = LocationConfig.Get(2)
				reqRebirth = (loc2 and loc2.unlockRebirth) or 3
			end
		end

		local reqNum = reqRebirth :: number
		local titleName = RebirthConfig.GetRankName(reqNum)
		local numInName = tonumber(inst.Name) or 1
		local locTargetMeta = LocationConfig.Get(numInName + 1) or LocationConfig.Get(2)
		local locName = (locTargetMeta and locTargetMeta.name) or string.format("Location %d", numInName + 1)

		local tag = createDoorTag(anchor, reqNum, titleName, locName)

		-- Attach SurfaceGui to ALL 4 VERTICAL FACES (Front, Back, Left, Right)
		local surfaces: { SurfaceGui } = {
			createSurfaceLock(anchor, Enum.NormalId.Front, reqNum, titleName, locName),
			createSurfaceLock(anchor, Enum.NormalId.Back, reqNum, titleName, locName),
			createSurfaceLock(anchor, Enum.NormalId.Left, reqNum, titleName, locName),
			createSurfaceLock(anchor, Enum.NormalId.Right, reqNum, titleName, locName),
		}

		table.insert(doorObjects, {
			model = inst,
			primary = anchor,
			reqRebirth = reqNum,
			reqTitle = titleName,
			targetLocId = numInName + 1,
			tag = tag,
			surfaces = surfaces,
		})

		print(string.format("[LocationDoorService] Bound door '%s' (ReqRebirth: %d, Title: '%s')", inst:GetFullName(), reqNum, titleName))

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
					toastApi.Show(string.format("🔒 Area Closed! Get Rebirth %d to Unlock!", reqNum), "yellow")
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
				data.model.Transparency = isUnlocked and 1 or 0.35
				if not isUnlocked then
					data.model.Material = Enum.Material.ForceField
					data.model.Color = Color3.fromRGB(220, 50, 60)
				end
			else
				for _, part in data.model:GetDescendants() do
					if part:IsA("BasePart") then
						part.CanCollide = not isUnlocked
						part.Transparency = isUnlocked and 1 or 0.35
						if not isUnlocked then
							part.Material = Enum.Material.ForceField
							part.Color = Color3.fromRGB(220, 50, 60)
						end
					end
				end
			end

			-- Update UI Tags (BillboardGui & SurfaceGuis on all 4 faces)
			if data.tag then
				data.tag.Enabled = not isUnlocked
			end
			for _, surf in data.surfaces do
				surf.Enabled = not isUnlocked
			end
		end
	end

	-- Initial scanner loop
	task.spawn(function()
		for _ = 1, 6 do
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
