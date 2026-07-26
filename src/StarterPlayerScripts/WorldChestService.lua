--!strict
--[[
	Client service for 3D Map Chests Touch pads.
	Includes strict TouchExit / Radius protection:
	  - Stepping on chest opens modal EXACTLY ONCE.
	  - Standing inside radius prevents reopening or window spam.
	  - Stepping out (> 9 studs away) unlocks the chest for next trigger.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local WorldChestService = {}

local isStandingOnChest: { [string]: boolean } = {}
local chestPrimaryParts: { [string]: BasePart } = {}

local function handleTouch(chestType: string, store: any)
	-- If player is already standing in chest zone or modal is open, DO NOT open new window
	if isStandingOnChest[chestType] then
		return
	end
	local currentModal = store:PeekModal()
	if currentModal and (currentModal.kind == "casePreview" or currentModal.kind == "caseOpen") then
		return
	end

	isStandingOnChest[chestType] = true

	if chestType == "group" then
		Remotes.Event("ClaimGroupChest"):FireServer()
	elseif chestType == "500" then
		store:OpenModal("casePreview", { kind = "pet", poolId = "loc1_500" })
	elseif chestType == "50k" then
		store:OpenModal("casePreview", { kind = "pet", poolId = "loc1_50k" })
	elseif chestType == "robux" then
		store:OpenModal("casePreview", { kind = "pet", poolId = "loc1_key49" })
	end
end

--- Completely purge old free-model scripts, remotes, and floating BillboardGuis
local function purgeOldChestScripts()
	local folder = Workspace:FindFirstChild("Folder")
	if folder then
		for _, name in { "ChestClient", "ChestServer", "ChestRemotes", "AuraChest" } do
			local old = folder:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end
	end

	for _, desc in Workspace:GetDescendants() do
		if desc.Name == "ChestClient" or desc.Name == "ChestServer" or desc.Name == "ChestRemotes" then
			desc:Destroy()
		end
	end
end

--- Destroy ugly yellow developer debug tags / old BillboardGuis / SelectionBoxes inside chest models
local function cleanAndTagChest(model: Instance?, title: string, subtitle: string, mainColor: Color3): BasePart?
	if not model then
		return nil
	end

	-- Clean old debug tags / prompts / GUIs
	for _, desc in model:GetDescendants() do
		if desc.Name ~= "CleanChestTag" and (desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("ProximityPrompt") or desc:IsA("SelectionBox") or desc:IsA("ClickDetector")) then
			desc:Destroy()
		end
	end

	-- Find primary part to anchor clean overhead label
	local anchorPart: BasePart? = nil
	if model:IsA("Model") then
		anchorPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	elseif model:IsA("BasePart") then
		anchorPart = model
	end

	if not anchorPart then
		return nil
	end

	if not anchorPart:FindFirstChild("CleanChestTag") then
		local bb = Instance.new("BillboardGui")
		bb.Name = "CleanChestTag"
		bb.Size = UDim2.fromOffset(260, 60)
		bb.StudsOffset = Vector3.new(0, 3.8, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 70
		bb.Parent = anchorPart

		local titleLab = Instance.new("TextLabel")
		titleLab.Size = UDim2.new(1, 0, 0, 30)
		titleLab.BackgroundTransparency = 1
		titleLab.Font = Enum.Font.Arcade
		titleLab.TextSize = 22
		titleLab.TextColor3 = mainColor
		titleLab.Text = title
		titleLab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		titleLab.TextStrokeTransparency = 0.15
		titleLab.Parent = bb

		local subLab = Instance.new("TextLabel")
		subLab.Size = UDim2.new(1, 0, 0, 22)
		subLab.Position = UDim2.fromOffset(0, 30)
		subLab.BackgroundTransparency = 1
		subLab.Font = Enum.Font.Arcade
		subLab.TextSize = 14
		subLab.TextColor3 = Color3.fromRGB(240, 240, 240)
		subLab.Text = subtitle
		subLab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		subLab.TextStrokeTransparency = 0.25
		subLab.Parent = bb
	end

	return anchorPart
end

function WorldChestService.Init(store: any)
	local player = Players.LocalPlayer

	-- Purge old toolbox scripts immediately
	purgeOldChestScripts()

	local boundPads: { [Instance]: boolean } = {}

	local function bindModelPads(root: Instance?, chestType: string)
		if not root then
			return
		end

		for _, desc in root:GetDescendants() do
			if desc:IsA("BasePart") and not boundPads[desc] then
				boundPads[desc] = true
				desc.CanTouch = true
				desc.Touched:Connect(function(hit)
					if not hit or not hit.Parent then
						return
					end
					local char = player.Character
					if char and (hit:IsDescendantOf(char) or hit.Parent:FindFirstChildOfClass("Humanoid") ~= nil) then
						handleTouch(chestType, store)
					end
				end)
			end
		end
	end

	local function refreshAllChests()
		purgeOldChestScripts()

		-- 1) Group Chest
		local groupModel = Workspace:FindFirstChild("GroupChest", true) or Workspace:FindFirstChild("Spawn")
		local p1 = cleanAndTagChest(groupModel, "COMMUNITY CHEST", "Roblox Group Reward", Color3.fromRGB(80, 220, 255))
		if p1 then chestPrimaryParts["group"] = p1 end
		bindModelPads(groupModel, "group")

		-- 2) 500 Coins Chest
		local m1 = Workspace:FindFirstChild("1 chest 500", true)
		local p2 = cleanAndTagChest(m1, "500 COINS CHEST", "Cost: 500 Coins · Step to open", Color3.fromRGB(255, 215, 80))
		if p2 then chestPrimaryParts["500"] = p2 end
		bindModelPads(m1, "500")

		-- 3) 50k Coins Chest
		local m3 = Workspace:FindFirstChild("3rd chest 50k", true)
		local p3 = cleanAndTagChest(m3, "50K COINS CHEST", "Cost: 50,000 Coins · Step to open", Color3.fromRGB(255, 170, 40))
		if p3 then chestPrimaryParts["50k"] = p3 end
		bindModelPads(m3, "50k")

		-- 4) 49 Robux Chest
		local m4 = Workspace:FindFirstChild("49robux chest", true)
		local p4 = cleanAndTagChest(m4, "49 KEYS CHEST", "Cost: 49 Keys · Step to open", Color3.fromRGB(210, 110, 255))
		if p4 then chestPrimaryParts["robux"] = p4 end
		bindModelPads(m4, "robux")
	end

	-- Distance tracker to reset touch lock only when player walks away (> 9 studs)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				for cType, part in pairs(chestPrimaryParts) do
					if isStandingOnChest[cType] then
						local dist = (hrp.Position - part.Position).Magnitude
						if dist > 9.0 then
							isStandingOnChest[cType] = false
						end
					end
				end
			end
		end
	end)

	task.defer(function()
		refreshAllChests()

		-- Repeated cleanup pass for streaming/delayed loads
		for _ = 1, 4 do
			task.wait(1)
			refreshAllChests()
		end
	end)
end

return WorldChestService
