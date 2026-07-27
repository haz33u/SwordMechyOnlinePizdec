--!strict
--[[
	LocationDoorService — Handles zone transition doors & barrier walls between locations.
	Features:
	  - Auto-calculates SurfaceGui CanvasSize based on physical door part size (anchor.Size).
	  - Uses TextScaled = true so text perfectly fills any size door (10 studs to 200 studs wide).
	  - Displays exact user-requested text:
	      🔒 AREA CLOSED
	      ⚡ Get Rebirth 3 to Unlock
	      🏆 Required Title: "Oathbreaker" (glowing in exact Title Index color!)
	  - Renders on ALL 4 faces (Front, Back, Left, Right) so rotation in Studio never hides text.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LocationConfig = require(Shared.Config.LocationConfig)
local RebirthConfig = require(Shared.Config.RebirthConfig)

local LocationDoorService = {}

local boundDoors: { [Instance]: boolean } = {}
local doorObjects: { { model: Instance, primary: BasePart, reqRebirth: number, reqTitle: string, targetLocId: number, tag: BillboardGui?, surfaces: { SurfaceGui } } } = {}

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

	-- Auto-calculate CanvasSize based on physical part size in studs
	local pSize = anchor.Size
	local w = math.max(pSize.X, pSize.Z, 12)
	local h = math.max(pSize.Y, 8)
	local canvasW = math.clamp(math.floor(w * 40), 1000, 4000)
	local canvasH = math.clamp(math.floor(h * 40), 600, 2400)

	local sg = Instance.new("SurfaceGui")
	sg.Name = name
	sg.Face = face
	sg.CanvasSize = Vector2.new(canvasW, canvasH)
	sg.AlwaysOnTop = true
	sg.MaxDistance = 180
	sg.LightInfluence = 0
	sg.Adornee = anchor
	sg.Parent = anchor

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.04, 0)
	layout.Parent = container

	-- Line 1: Area Closed
	local lockHeader = Instance.new("TextLabel")
	lockHeader.Size = UDim2.new(0.9, 0, 0.26, 0)
	lockHeader.BackgroundTransparency = 1
	lockHeader.Font = Enum.Font.Arcade
	lockHeader.TextScaled = true
	lockHeader.TextColor3 = Color3.fromRGB(255, 70, 80)
	lockHeader.Text = "🔒 AREA CLOSED"
	lockHeader.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lockHeader.TextStrokeTransparency = 0
	lockHeader.Parent = container

	-- Line 2: Get Rebirth X to Unlock
	local rebLine = Instance.new("TextLabel")
	rebLine.Size = UDim2.new(0.9, 0, 0.22, 0)
	rebLine.BackgroundTransparency = 1
	rebLine.Font = Enum.Font.Arcade
	rebLine.TextScaled = true
	rebLine.TextColor3 = Color3.fromRGB(255, 215, 80)
	rebLine.Text = string.format("Get Rebirth %d to Unlock", reqRebirth)
	rebLine.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rebLine.TextStrokeTransparency = 0
	rebLine.Parent = container

	-- Line 3: Required Title
	local titleLine = Instance.new("TextLabel")
	titleLine.Size = UDim2.new(0.9, 0, 0.22, 0)
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

		-- Search deep for any folder named "Doors" or "LocationDoors" anywhere in Workspace
		local doorsFolders: { Instance } = {}
		for _, desc in Workspace:GetDescendants() do
			if desc:IsA("Folder") or desc:IsA("Model") then
				local lName = string.lower(desc.Name)
				if lName == "doors" or lName == "locationdoors" then
					table.insert(doorsFolders, desc)
				end
			end
		end

		for _, folder in doorsFolders do
			for _, child in folder:GetChildren() do
				if (child:IsA("Model") or child:IsA("BasePart")) and not boundDoors[child] then
					table.insert(list, child)
				end
			end
		end

		-- Match parts with explicit UnlockRebirth attribute
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

		-- Read rebirth requirement from attribute OR item name
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

		-- Attach SurfaceGui to ALL 4 FACES (Front, Back, Left, Right)
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
			surfaces = surfaces,
		})

		print(string.format("[LocationDoorService] Bound door '%s' (ReqRebirth: %d, Title: '%s')", inst:GetFullName(), reqNum, titleName))
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
					data.model.Material = Enum.Material.SmoothPlastic
					data.model.Color = Color3.fromRGB(220, 50, 60)
				end
			else
				for _, part in data.model:GetDescendants() do
					if part:IsA("BasePart") then
						part.CanCollide = not isUnlocked
						part.Transparency = isUnlocked and 1 or 0.35
						if not isUnlocked then
							part.Material = Enum.Material.SmoothPlastic
							part.Color = Color3.fromRGB(220, 50, 60)
						end
					end
				end
			end

			-- Update UI Tags
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
