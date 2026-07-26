--!strict
--[[
	Client service for 3D Map Chests Touch pads.
	Clean 3D labels + exact chest pool bindings:
	  1) Group / Community Reward Chest -> ClaimGroupChest remote
	  2) 500 Coins Case Chest -> loc1_500 (500 Coins)
	  3) 50k Coins Case Chest -> loc1_50k (50,000 Coins)
	  4) 49 Robux Premium Chest -> loc1_key49 (49 Keys)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local WorldChestService = {}

local lastTouchTime: { [string]: number } = {}
local TOUCH_COOLDOWN = 1.8 -- seconds between opening modals on step

local function handleTouch(chestType: string, store: any)
	local now = os.time()
	local last = lastTouchTime[chestType] or 0
	if (now - last) < TOUCH_COOLDOWN then
		return
	end
	lastTouchTime[chestType] = now

	if chestType == "group" then
		Remotes.Event("ClaimGroupChest"):FireServer()
	elseif chestType == "500" then
		store:OpenModal("case", { kind = "pet", poolId = "loc1_500" })
	elseif chestType == "50k" then
		store:OpenModal("case", { kind = "pet", poolId = "loc1_50k" })
	elseif chestType == "robux" then
		store:OpenModal("case", { kind = "pet", poolId = "loc1_key49" })
	end
end

--- Destroy ugly yellow developer debug tags / old BillboardGuis / SelectionBoxes inside chest models
local function cleanAndTagChest(model: Instance?, title: string, subtitle: string, mainColor: Color3)
	if not model then
		return
	end

	-- Clean old debug tags / prompts
	for _, desc in model:GetDescendants() do
		if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("ProximityPrompt") or desc:IsA("SelectionBox") then
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
		return
	end

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

function WorldChestService.Init(store: any)
	local player = Players.LocalPlayer

	local function bindPad(part: BasePart, chestType: string)
		part.Touched:Connect(function(hit)
			if not hit or not hit.Parent then
				return
			end
			local char = player.Character
			if char and hit:IsDescendantOf(char) then
				handleTouch(chestType, store)
			end
		end)
	end

	task.defer(function()
		task.wait(1.5)

		-- 1) Group Chest: Workspace.Spawn.GroupChest
		local groupModel = Workspace:FindFirstChild("GroupChest", true) or Workspace:FindFirstChild("Spawn")
		cleanAndTagChest(groupModel, "COMMUNITY CHEST", "Roblox Group Reward", Color3.fromRGB(80, 220, 255))
		
		local spawnFolder = Workspace:FindFirstChild("Spawn")
		if spawnFolder then
			local btn = spawnFolder:FindFirstChild("Button", true)
			local touch = btn and btn:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "group")
			end
		end

		-- 2) 500 Coins Chest: Workspace."1 chest 500"
		local m1 = Workspace:FindFirstChild("1 chest 500", true)
		cleanAndTagChest(m1, "500 COINS CHEST", "Cost: 500 Coins · Step to open", Color3.fromRGB(255, 215, 80))
		if m1 then
			local touch = m1:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "500")
			end
		end

		-- 3) 50k Coins Chest: Workspace."3rd chest 50k"
		local m2 = Workspace:FindFirstChild("3rd chest 50k", true)
		cleanAndTagChest(m2, "50K COINS CHEST", "Cost: 50,000 Coins · Step to open", Color3.fromRGB(255, 170, 40))
		if m2 then
			local touch = m2:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "50k")
			end
		end

		-- 4) 49 Robux Chest: Workspace."49robux chest"
		local m3 = Workspace:FindFirstChild("49robux chest", true)
		cleanAndTagChest(m3, "49 KEYS CHEST", "Cost: 49 Keys · Step to open", Color3.fromRGB(210, 110, 255))
		if m3 then
			local touch = m3:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "robux")
			end
		end
	end)
end

return WorldChestService
