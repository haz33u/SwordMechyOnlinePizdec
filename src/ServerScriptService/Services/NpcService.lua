--!strict
--[[
	NpcService — Handles physical Hub Cases and World NPCs (Quest Master, Smith, etc.).
	- Enforces STRICT SINGLETON rule per location: EXACTLY 1 Quest Master and 1 Smith!
	- Removes floating BillboardGui titles from NPCs (only native [E] ProximityPrompts remain).
	- Keeps small, fixed-size 3D Billboard titles ONLY for Case Chests (130x28px, MaxDistance = 35).
	- Includes all 4 Hub Cases: Pet Case (500), Pet Case (50K), Pet Case (49 R$), and Aura Case.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local NpcService = {}
NpcService._boundObjects = {} :: { [Instance]: boolean }
NpcService._questMasterBound = false
NpcService._smithBound = false

local function ensureFolder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then
		return f
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end

--- Clear all BillboardGuis from an instance (used for NPCs so no floating billboard shows)
local function removeAllBillboards(target: Instance)
	for _, desc in target:GetDescendants() do
		if desc:IsA("BillboardGui") then
			desc:Destroy()
		end
	end
	for _, child in target:GetChildren() do
		if child:IsA("BillboardGui") then
			child:Destroy()
		end
	end
end

--- Create SMALL, FIXED-SIZE BillboardGui ONLY for Case Chests
local function addSmallCaseBillboard(parent: BasePart, titleText: string, color: Color3)
	removeAllBillboards(parent)

	local bill = Instance.new("BillboardGui")
	bill.Name = "CaseBillboard"
	bill.Size = UDim2.fromOffset(130, 28)
	bill.StudsOffset = Vector3.new(0, 2.5, 0)
	bill.AlwaysOnTop = false -- Local 3D space
	bill.MaxDistance = 35 -- Compact fixed distance
	bill.Parent = parent

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 0.2
	frame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	frame.Parent = bill
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.TextColor3 = color
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.Text = titleText
	title.Parent = frame
end

--- Extract clean display name for chests
local function getCleanCaseName(rawName: string): string
	local name = rawName
	name = string.gsub(name, "_Box$", "")
	name = string.gsub(name, "_Lid$", "")
	name = string.gsub(name, "^PetCase_500$", "Pet Case (500)")
	name = string.gsub(name, "^PetCase_50k$", "Pet Case (50K)")
	name = string.gsub(name, "^PetCase_49r$", "Pet Case (49 R$)")
	name = string.gsub(name, "^AuraCase$", "Aura Case")
	return name
end

--- Bind ProximityPrompt & ClickDetector to any Case chest part
function NpcService.BindCase(object: Instance, caseName: string, kind: string, poolId: string?)
	local topTarget = if object:IsA("BasePart") and object.Parent and (object.Parent:IsA("Model") or string.find(string.lower(object.Parent.Name), "case")) then object.Parent else object
	if NpcService._boundObjects[topTarget] or NpcService._boundObjects[object] then
		return
	end

	local part: BasePart? = if object:IsA("BasePart") then object else object:FindFirstChildWhichIsA("BasePart", true)
	if not part then return end

	NpcService._boundObjects[topTarget] = true
	NpcService._boundObjects[object] = true

	local cleanName = getCleanCaseName(caseName)
	addSmallCaseBillboard(part, cleanName, Color3.fromRGB(255, 200, 50))

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = cleanName
		prompt.ActionText = "Open Case [E]"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end

	prompt.Triggered:Connect(function(player)
		Remotes.Event("OpenCasePreview"):FireClient(player, { kind = kind, poolId = poolId, count = 1 })
	end)

	local cd = part:FindFirstChildOfClass("ClickDetector")
	if not cd then
		cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = part
	end
	cd.MouseClick:Connect(function(player)
		Remotes.Event("OpenCasePreview"):FireClient(player, { kind = kind, poolId = poolId, count = 1 })
	end)
end

--- Bind ProximityPrompt & ClickDetector to Quest Master NPC (SINGLETON: EXACTLY 1 PER LOCATION)
function NpcService.BindQuestMaster(object: Instance)
	if NpcService._questMasterBound then
		-- Destroy extra duplicate Quest Master models in Workspace!
		if object and object.Parent and object.Parent.Name ~= "NPCs" then
			object:Destroy()
		end
		return
	end

	local topTarget = if object:IsA("BasePart") and object.Parent and object.Parent:IsA("Model") then object.Parent else object
	if NpcService._boundObjects[topTarget] or NpcService._boundObjects[object] then
		return
	end

	local part: BasePart? = if object:IsA("Model")
		then (object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChildWhichIsA("BasePart"))
		else (if object:IsA("BasePart") then object else nil)

	if not part then
		return
	end

	NpcService._questMasterBound = true
	NpcService._boundObjects[topTarget] = true
	NpcService._boundObjects[object] = true

	-- REMOVE ALL BillboardGuis from Quest Master NPC
	removeAllBillboards(topTarget)
	removeAllBillboards(part)

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Quest Master"
		prompt.ActionText = "Talk / Quests [E]"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end

	prompt.Triggered:Connect(function(player)
		Remotes.Event("OpenPanel"):FireClient(player, "quests")
		Remotes.Event("Notify"):FireClient(player, { text = "Quest Master: View active quests!", color = "cyan" })
	end)

	local cd = part:FindFirstChildOfClass("ClickDetector")
	if not cd then
		cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = part
	end
	cd.MouseClick:Connect(function(player)
		Remotes.Event("OpenPanel"):FireClient(player, "quests")
		Remotes.Event("Notify"):FireClient(player, { text = "Quest Master: View active quests!", color = "cyan" })
	end)
end

--- Bind ProximityPrompt & ClickDetector to Smith NPC (SINGLETON: EXACTLY 1 PER LOCATION)
function NpcService.BindSmith(object: Instance)
	if NpcService._smithBound then
		-- Destroy extra duplicate Smith models in Workspace!
		if object and object.Parent and object.Parent.Name ~= "NPCs" then
			object:Destroy()
		end
		return
	end

	local topTarget = if object:IsA("BasePart") and object.Parent and object.Parent:IsA("Model") then object.Parent else object
	if NpcService._boundObjects[topTarget] or NpcService._boundObjects[object] then
		return
	end

	local part: BasePart? = if object:IsA("Model")
		then (object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChildWhichIsA("BasePart"))
		else (if object:IsA("BasePart") then object else nil)

	if not part then
		return
	end

	NpcService._smithBound = true
	NpcService._boundObjects[topTarget] = true
	NpcService._boundObjects[object] = true

	-- REMOVE ALL BillboardGuis from Smith NPC
	removeAllBillboards(topTarget)
	removeAllBillboards(part)

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Smith"
		prompt.ActionText = "Forge / Enchant [E]"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end

	prompt.Triggered:Connect(function(player)
		Remotes.Event("OpenPanel"):FireClient(player, "weapons")
		Remotes.Event("Notify"):FireClient(player, { text = "Smith: Upgrade & enchant swords here!", color = "orange" })
	end)

	local cd = part:FindFirstChildOfClass("ClickDetector")
	if not cd then
		cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = part
	end
	cd.MouseClick:Connect(function(player)
		Remotes.Event("OpenPanel"):FireClient(player, "weapons")
		Remotes.Event("Notify"):FireClient(player, { text = "Smith: Upgrade & enchant swords here!", color = "orange" })
	end)
end

--- Inspect instance and bind if it matches a known NPC or Case
function NpcService.InspectAndBind(inst: Instance)
	if inst:IsA("Folder") then
		return
	end

	local topTarget = if inst:IsA("BasePart") and inst.Parent and inst.Parent:IsA("Model") then inst.Parent else inst
	if NpcService._boundObjects[topTarget] or NpcService._boundObjects[inst] then
		return
	end

	local name = inst.Name
	local lowerName = string.lower(name)

	-- Skip Lid parts
	if string.find(lowerName, "_lid") or string.find(lowerName, "lid") then
		return
	end

	if string.find(lowerName, "quest") or string.find(lowerName, "quester") or string.find(lowerName, "sam") then
		NpcService.BindQuestMaster(topTarget)
	elseif string.find(lowerName, "smith") or string.find(lowerName, "blacksmith") or string.find(lowerName, "forge") or string.find(lowerName, "enchant") then
		NpcService.BindSmith(topTarget)
	end
end

--- Remove all BillboardGuis from NPCs & Ferryman, and remove giant sky labels
function NpcService.PurgeNpcBillboardsAndSkyLabels()
	for _, desc in Workspace:GetDescendants() do
		if desc:IsA("BillboardGui") then
			local p = desc.Parent
			local pName = if p then string.lower(p.Name) else ""
			local pParentName = if p and p.Parent then string.lower(p.Parent.Name) else ""

			-- Remove billboards from Quest Master, Smith, NPCs (no Ferryman)
			if string.find(pName, "quest") or string.find(pName, "smith") or string.find(pParentName, "quest") or string.find(pParentName, "smith") then
				desc:Destroy()
			else
				local titleLab = desc:FindFirstChildWhichIsA("TextLabel", true)
				if titleLab then
					local txt = string.upper(titleLab.Text)
					if string.find(txt, "CENTRAL") or string.find(txt, "BOSS") or string.find(txt, "CAMP") or string.find(txt, "HUB") or string.find(txt, "ARENA") then
						desc:Destroy()
					end
				end
			end
		end
	end
end

--- Clean up any duplicate HubCases created on the platform
function NpcService.CleanDuplicateHubCases()
	for _, desc in Workspace:GetDescendants() do
		if desc:IsA("Folder") and desc.Name == "HubCases" then
			desc:Destroy()
		end
	end
end

--- Spawn physical 3D Hub Cases & NPCs DIRECTLY ON THE CENTRAL HUB PLATFORM
function NpcService.EnsureHubInteractives()
	NpcService.CleanDuplicateHubCases()

	-- Quest Master & Smith NPCs only
	local npcsFolder = ensureFolder(Workspace, "NPCs")

	-- 5. Quest Master NPC (Singleton, NO BillboardGui)
	if not npcsFolder:FindFirstChild("QuestMaster") then
		local model = Instance.new("Model")
		model.Name = "QuestMaster"
		local body = makePart(model, "HumanoidRootPart", Vector3.new(2, 5, 2), CFrame.new(16, 2.8, 22), Color3.fromRGB(40, 140, 200), Enum.Material.SmoothPlastic)
		local head = makePart(model, "Head", Vector3.new(1.6, 1.6, 1.6), CFrame.new(16, 6.0, 22), Color3.fromRGB(255, 220, 180), Enum.Material.SmoothPlastic)
		model.PrimaryPart = body
		model.Parent = npcsFolder
		NpcService.BindQuestMaster(model)
	end

	-- 6. Smith NPC (Singleton, NO BillboardGui)
	if not npcsFolder:FindFirstChild("Smith") then
		local model = Instance.new("Model")
		model.Name = "Smith"
		local body = makePart(model, "HumanoidRootPart", Vector3.new(2.4, 5, 2.2), CFrame.new(21, 2.8, 22), Color3.fromRGB(180, 70, 40), Enum.Material.SmoothPlastic)
		local head = makePart(model, "Head", Vector3.new(1.7, 1.7, 1.7), CFrame.new(21, 6.0, 22), Color3.fromRGB(255, 210, 170), Enum.Material.SmoothPlastic)
		model.PrimaryPart = body
		model.Parent = npcsFolder
		NpcService.BindSmith(model)
	end
end

function NpcService.Init()
	task.defer(function()
		task.wait(1.5)
		NpcService.EnsureHubInteractives()

		-- Scan Workspace for existing models/parts
		for _, descendant in Workspace:GetDescendants() do
			NpcService.InspectAndBind(descendant)
		end

		NpcService.PurgeNpcBillboardsAndSkyLabels()

		Workspace.DescendantAdded:Connect(function(descendant)
			task.wait(0.1)
			NpcService.InspectAndBind(descendant)
			NpcService.PurgeNpcBillboardsAndSkyLabels()
		end)

		print("[NpcService] 4 Hub Cases & Singleton NPCs online — small fixed case billboards only!")
	end)
end

return NpcService
