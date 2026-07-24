--!strict
--[[
	NpcService — Handles physical Hub Cases and World NPCs (Quest Master, Smith, etc.).
	Provides clean, single-billboard Hub interactives on the path (AlwaysOnTop = false, MaxDistance = 50).
	Prevents duplicate overlapping billboards across all Workspace models and Studio scaffolds.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local NpcService = {}
NpcService._boundObjects = {} :: { [Instance]: boolean }
NpcService._boundPositions = {} :: { Vector3 }

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

--- Check if position is near an already bound NPC/Chest of same type
local function isNearBoundPosition(pos: Vector3, threshold: number?): boolean
	local maxDist = threshold or 6
	for _, bPos in ipairs(NpcService._boundPositions) do
		if (pos - bPos).Magnitude < maxDist then
			return true
		end
	end
	return false
end

--- Guarantee EXACTLY ONE BillboardGui across topInstance and all its descendants
local function getOrCreateSingleBillboard(topInstance: Instance, targetPart: BasePart, titleText: string, subtitleText: string?, color: Color3): BillboardGui
	local existingBills: { BillboardGui } = {}
	for _, desc in topInstance:GetDescendants() do
		if desc:IsA("BillboardGui") then
			table.insert(existingBills, desc)
		end
	end

	-- Keep at most 1 billboard, destroy all others
	local mainBill: BillboardGui? = existingBills[1]
	for i = 2, #existingBills do
		existingBills[i]:Destroy()
	end

	if mainBill then
		mainBill.Parent = targetPart
		mainBill.AlwaysOnTop = false
		mainBill.MaxDistance = 50
		mainBill.StudsOffset = Vector3.new(0, 3.6, 0)
		return mainBill
	end

	local bill = Instance.new("BillboardGui")
	bill.Name = "NPCBillboard"
	bill.Size = UDim2.fromOffset(180, 48)
	bill.StudsOffset = Vector3.new(0, 3.6, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 50
	bill.Parent = targetPart

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 0.25
	frame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	frame.Parent = bill
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, subtitleText and 0.55 or 1, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = color
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.Text = titleText
	title.Parent = frame

	if subtitleText then
		local sub = Instance.new("TextLabel")
		sub.Name = "Subtitle"
		sub.Size = UDim2.new(1, 0, 0.45, 0)
		sub.Position = UDim2.new(0, 0, 0.55, 0)
		sub.BackgroundTransparency = 1
		sub.TextColor3 = Color3.fromRGB(200, 200, 210)
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 11
		sub.Text = subtitleText
		sub.Parent = frame
	end

	return bill
end

--- Extract clean display name for chests
local function getCleanCaseName(rawName: string): string
	local name = rawName
	name = string.gsub(name, "_Box$", "")
	name = string.gsub(name, "_Lid$", "")
	name = string.gsub(name, "^PetCase_500$", "Pet Case (500)")
	name = string.gsub(name, "^PetCase_50k$", "Pet Case (50K)")
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

	if isNearBoundPosition(part.Position, 4) then
		return
	end

	NpcService._boundObjects[topTarget] = true
	NpcService._boundObjects[object] = true
	table.insert(NpcService._boundPositions, part.Position)

	local cleanName = getCleanCaseName(caseName)
	getOrCreateSingleBillboard(topTarget, part, cleanName, "Click or Press [E]", Color3.fromRGB(255, 200, 50))

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

--- Bind ProximityPrompt & ClickDetector to Quest Master NPC
function NpcService.BindQuestMaster(object: Instance)
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

	if isNearBoundPosition(part.Position, 5) then
		return
	end

	NpcService._boundObjects[topTarget] = true
	NpcService._boundObjects[object] = true
	table.insert(NpcService._boundPositions, part.Position)

	getOrCreateSingleBillboard(topTarget, part, "Quest Master", "Quests & Rewards", Color3.fromRGB(80, 220, 255))

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

--- Bind ProximityPrompt & ClickDetector to Smith NPC
function NpcService.BindSmith(object: Instance)
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

	if isNearBoundPosition(part.Position, 5) then
		return
	end

	NpcService._boundObjects[topTarget] = true
	NpcService._boundObjects[object] = true
	table.insert(NpcService._boundPositions, part.Position)

	getOrCreateSingleBillboard(topTarget, part, "Smith", "Swords & Enchants", Color3.fromRGB(255, 140, 40))

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
	elseif string.find(lowerName, "pet case") or string.find(lowerName, "petcase") or string.find(lowerName, "pet chest") then
		local poolId = if string.find(lowerName, "50k") then "loc1_50k" else "loc1_500"
		NpcService.BindCase(inst, name, "pet", poolId)
	elseif string.find(lowerName, "aura case") or string.find(lowerName, "auracase") or string.find(lowerName, "aura chest") then
		NpcService.BindCase(inst, name, "aura", nil)
	elseif string.find(lowerName, "case") or string.find(lowerName, "chest") then
		NpcService.BindCase(inst, name, "pet", "loc1_500")
	end
end

--- Purge all duplicate billboards across entire Workspace
function NpcService.PurgeAllDuplicates()
	for _, parent in Workspace:GetDescendants() do
		local bills: { BillboardGui } = {}
		for _, child in parent:GetChildren() do
			if child:IsA("BillboardGui") then
				table.insert(bills, child)
			end
		end
		for i = 2, #bills do
			bills[i]:Destroy()
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

--- Spawn physical 3D Hub Cases & NPCs near Loc1 spawn
function NpcService.EnsureHubInteractives()
	NpcService.CleanDuplicateHubCases()

	local npcsFolder = ensureFolder(Workspace, "NPCs")

	-- 1. Pet Case (500)
	if not npcsFolder:FindFirstChild("PetCase_500") then
		local box = makePart(npcsFolder, "PetCase_500_Box", Vector3.new(3.5, 3, 2.5), CFrame.new(-12, 1.5, 75), Color3.fromRGB(0, 160, 120), Enum.Material.Metal)
		local lid = makePart(npcsFolder, "PetCase_500_Lid", Vector3.new(3.7, 0.8, 2.7), CFrame.new(-12, 3.2, 75), Color3.fromRGB(240, 200, 80), Enum.Material.SmoothPlastic)
		NpcService.BindCase(box, "Pet Case (500)", "pet", "loc1_500")
	end

	-- 2. Pet Case (50K)
	if not npcsFolder:FindFirstChild("PetCase_50k") then
		local box = makePart(npcsFolder, "PetCase_50k_Box", Vector3.new(3.5, 3, 2.5), CFrame.new(-5, 1.5, 75), Color3.fromRGB(0, 120, 180), Enum.Material.Metal)
		local lid = makePart(npcsFolder, "PetCase_50k_Lid", Vector3.new(3.7, 0.8, 2.7), CFrame.new(-5, 3.2, 75), Color3.fromRGB(240, 200, 80), Enum.Material.SmoothPlastic)
		NpcService.BindCase(box, "Pet Case (50K)", "pet", "loc1_50k")
	end

	-- 3. Aura Case
	if not npcsFolder:FindFirstChild("AuraCase") then
		local box = makePart(npcsFolder, "AuraCase_Box", Vector3.new(3.5, 3, 2.5), CFrame.new(2, 1.5, 75), Color3.fromRGB(150, 60, 220), Enum.Material.Metal)
		local lid = makePart(npcsFolder, "AuraCase_Lid", Vector3.new(3.7, 0.8, 2.7), CFrame.new(2, 3.2, 75), Color3.fromRGB(240, 200, 80), Enum.Material.SmoothPlastic)
		NpcService.BindCase(box, "Aura Case", "aura", nil)
	end

	-- 4. Quest Master NPC
	if not npcsFolder:FindFirstChild("QuestMaster") then
		local model = Instance.new("Model")
		model.Name = "QuestMaster"
		local body = makePart(model, "HumanoidRootPart", Vector3.new(2, 5, 2), CFrame.new(12, 2.5, 75), Color3.fromRGB(40, 140, 200), Enum.Material.SmoothPlastic)
		local head = makePart(model, "Head", Vector3.new(1.6, 1.6, 1.6), CFrame.new(12, 5.7, 75), Color3.fromRGB(255, 220, 180), Enum.Material.SmoothPlastic)
		model.PrimaryPart = body
		model.Parent = npcsFolder
		NpcService.BindQuestMaster(model)
	end

	-- 5. Smith NPC
	if not npcsFolder:FindFirstChild("Smith") then
		local model = Instance.new("Model")
		model.Name = "Smith"
		local body = makePart(model, "HumanoidRootPart", Vector3.new(2.4, 5, 2.2), CFrame.new(19, 2.5, 75), Color3.fromRGB(180, 70, 40), Enum.Material.SmoothPlastic)
		local head = makePart(model, "Head", Vector3.new(1.7, 1.7, 1.7), CFrame.new(19, 5.7, 75), Color3.fromRGB(255, 210, 170), Enum.Material.SmoothPlastic)
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

		NpcService.PurgeAllDuplicates()

		Workspace.DescendantAdded:Connect(function(descendant)
			task.wait(0.1)
			NpcService.InspectAndBind(descendant)
			NpcService.PurgeAllDuplicates()
		end)

		print("[NpcService] Clean Hub NPCs online — 1 set of NPCs next to spawn path!")
	end)
end

return NpcService
