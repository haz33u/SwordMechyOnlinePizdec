--!strict
--[[
	NpcService — Handles physical Hub Cases and World NPCs (Quest Master, Smith, etc.).
	Provides both auto-spawned 3D Hub interactives and dynamic Workspace scanning
	for Studio-built NPC models and Case chests.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local NpcService = {}
NpcService._boundObjects = {} :: { [Instance]: boolean }

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

local function addBillboard(parent: Instance, titleText: string, subtitleText: string?, color: Color3)
	local bill = parent:FindFirstChildOfClass("BillboardGui")
	if not bill then
		bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromOffset(180, 48)
		bill.StudsOffset = Vector3.new(0, 3.8, 0)
		bill.AlwaysOnTop = true
		bill.Parent = parent

		local frame = Instance.new("Frame")
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
		title.Size = UDim2.new(1, 0, subtitleText and 0.55 or 1, 0)
		title.BackgroundTransparency = 1
		title.TextColor3 = color
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.Text = titleText
		title.Parent = frame

		if subtitleText then
			local sub = Instance.new("TextLabel")
			sub.Size = UDim2.new(1, 0, 0.45, 0)
			sub.Position = UDim2.new(0, 0, 0.55, 0)
			sub.BackgroundTransparency = 1
			sub.TextColor3 = Color3.fromRGB(200, 200, 210)
			sub.Font = Enum.Font.Gotham
			sub.TextSize = 11
			sub.Text = subtitleText
			sub.Parent = frame
		end
	end
end

--- Bind ProximityPrompt & ClickDetector to any Case object
function NpcService.BindCase(object: Instance, caseName: string, kind: string, poolId: string?)
	if NpcService._boundObjects[object] then
		return
	end
	NpcService._boundObjects[object] = true

	local part = if object:IsA("Model") then (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) else object
	if not part or not part:IsA("BasePart") then
		return
	end

	addBillboard(part, caseName, "Click or Press [E]", Color3.fromRGB(255, 200, 50))

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = caseName
		prompt.ActionText = "Open Case [E]"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end

	prompt.Triggered:Connect(function(player)
		Remotes.Event("OpenCasePreview"):FireClient(player, { kind = kind, poolId = poolId, count = 1 })
		Remotes.Event("Notify"):FireClient(player, { text = "Opening " .. caseName .. "...", color = "gold" })
	end)

	local cd = part:FindFirstChildOfClass("ClickDetector")
	if not cd then
		cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = part
	end
	cd.MouseClick:Connect(function(player)
		Remotes.Event("OpenCasePreview"):FireClient(player, { kind = kind, poolId = poolId, count = 1 })
		Remotes.Event("Notify"):FireClient(player, { text = "Opening " .. caseName .. "...", color = "gold" })
	end)
end

--- Bind ProximityPrompt & ClickDetector to Quest Master NPC
function NpcService.BindQuestMaster(object: Instance)
	if NpcService._boundObjects[object] then
		return
	end
	NpcService._boundObjects[object] = true

	local part = if object:IsA("Model") then (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) else object
	if not part or not part:IsA("BasePart") then
		return
	end

	addBillboard(part, "Quest Master", "Quests & Rewards", Color3.fromRGB(80, 220, 255))

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
	if NpcService._boundObjects[object] then
		return
	end
	NpcService._boundObjects[object] = true

	local part = if object:IsA("Model") then (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) else object
	if not part or not part:IsA("BasePart") then
		return
	end

	addBillboard(part, "Smith", "Swords & Enchants", Color3.fromRGB(255, 140, 40))

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
	local name = inst.Name
	local lowerName = string.lower(name)

	if string.find(lowerName, "quest") or string.find(lowerName, "quester") or string.find(lowerName, "sam") then
		NpcService.BindQuestMaster(inst)
	elseif string.find(lowerName, "smith") or string.find(lowerName, "blacksmith") or string.find(lowerName, "forge") or string.find(lowerName, "enchant") then
		NpcService.BindSmith(inst)
	elseif string.find(lowerName, "pet case") or string.find(lowerName, "petcase") or string.find(lowerName, "pet chest") then
		local poolId = if string.find(lowerName, "50k") then "loc1_50k" else "loc1_500"
		NpcService.BindCase(inst, name, "pet", poolId)
	elseif string.find(lowerName, "aura case") or string.find(lowerName, "auracase") or string.find(lowerName, "aura chest") then
		NpcService.BindCase(inst, name, "aura", nil)
	elseif string.find(lowerName, "case") or string.find(lowerName, "chest") then
		NpcService.BindCase(inst, name, "pet", "loc1_500")
	end
end

--- Spawn physical 3D Hub Cases & NPCs near Loc1 spawn if missing
function NpcService.EnsureHubInteractives()
	local npcsFolder = ensureFolder(Workspace, "NPCs")

	-- 1. Pet Case (500)
	if not npcsFolder:FindFirstChild("PetCase_500") and not Workspace:FindFirstChild("PetCase_500", true) then
		local box = makePart(npcsFolder, "PetCase_500", Vector3.new(3.5, 3, 2.5), CFrame.new(-12, 1.5, 75), Color3.fromRGB(0, 160, 120), Enum.Material.Metal)
		local lid = makePart(npcsFolder, "PetCase_500_Lid", Vector3.new(3.7, 0.8, 2.7), CFrame.new(-12, 3.2, 75), Color3.fromRGB(240, 200, 80), Enum.Material.SmoothPlastic)
		NpcService.BindCase(box, "Pet Case (500)", "pet", "loc1_500")
	end

	-- 2. Pet Case (50K)
	if not npcsFolder:FindFirstChild("PetCase_50k") and not Workspace:FindFirstChild("PetCase_50k", true) then
		local box = makePart(npcsFolder, "PetCase_50k", Vector3.new(3.5, 3, 2.5), CFrame.new(-5, 1.5, 75), Color3.fromRGB(0, 120, 180), Enum.Material.Metal)
		local lid = makePart(npcsFolder, "PetCase_50k_Lid", Vector3.new(3.7, 0.8, 2.7), CFrame.new(-5, 3.2, 75), Color3.fromRGB(240, 200, 80), Enum.Material.SmoothPlastic)
		NpcService.BindCase(box, "Pet Case (50K)", "pet", "loc1_50k")
	end

	-- 3. Aura Case
	if not npcsFolder:FindFirstChild("AuraCase") and not Workspace:FindFirstChild("AuraCase", true) then
		local box = makePart(npcsFolder, "AuraCase", Vector3.new(3.5, 3, 2.5), CFrame.new(2, 1.5, 75), Color3.fromRGB(150, 60, 220), Enum.Material.Metal)
		local lid = makePart(npcsFolder, "AuraCase_Lid", Vector3.new(3.7, 0.8, 2.7), CFrame.new(2, 3.2, 75), Color3.fromRGB(240, 200, 80), Enum.Material.SmoothPlastic)
		NpcService.BindCase(box, "Aura Case", "aura", nil)
	end

	-- 4. Quest Master NPC
	if not npcsFolder:FindFirstChild("QuestMaster") and not Workspace:FindFirstChild("QuestMaster", true) then
		local model = Instance.new("Model")
		model.Name = "QuestMaster"
		local body = makePart(model, "HumanoidRootPart", Vector3.new(2, 5, 2), CFrame.new(12, 2.5, 75), Color3.fromRGB(40, 140, 200), Enum.Material.SmoothPlastic)
		local head = makePart(model, "Head", Vector3.new(1.6, 1.6, 1.6), CFrame.new(12, 5.7, 75), Color3.fromRGB(255, 220, 180), Enum.Material.SmoothPlastic)
		model.PrimaryPart = body
		model.Parent = npcsFolder
		NpcService.BindQuestMaster(model)
	end

	-- 5. Smith NPC
	if not npcsFolder:FindFirstChild("Smith") and not Workspace:FindFirstChild("Smith", true) then
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
		-- Ensure hub 3D interactives
		NpcService.EnsureHubInteractives()

		-- Scan Workspace for existing models/parts
		for _, descendant in Workspace:GetDescendants() do
			NpcService.InspectAndBind(descendant)
		end

		-- Dynamic listener for streaming / Studio sync
		Workspace.DescendantAdded:Connect(function(descendant)
			task.wait(0.1)
			NpcService.InspectAndBind(descendant)
		end)

		print("[NpcService] Hub Cases, Quest Master, and Smith NPCs online with ProximityPrompts & ClickDetectors!")
	end)
end

return NpcService
