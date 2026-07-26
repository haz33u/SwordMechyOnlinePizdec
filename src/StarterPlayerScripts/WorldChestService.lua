--!strict
--[[
	Client service for 3D Map Chests Touch pads.
	Listens to character step/touch on:
	  1) Group / Community Reward Chest -> ClaimGroupChest remote
	  2) 500 Coins Case Chest -> Case Preview (loc1_500)
	  3) 50k Coins Case Chest -> Case Preview (loc1_50k)
	  4) 49 Robux Premium Chest -> Aura Case / Gamepass Preview
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local WorldChestService = {}

local lastTouchTime: { [string]: number } = {}
local TOUCH_COOLDOWN = 1.8 -- seconds between opening modals on step

local function handleTouch(pad: BasePart, chestType: string, store: any)
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
		store:OpenModal("case", { kind = "aura", poolId = "aura_premium" })
	end
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
				handleTouch(part, chestType, store)
			end
		end)
	end

	-- Scan Workspace for chest pads
	task.defer(function()
		-- 1) Group Chest: Workspace.Spawn.Button.Touch
		local spawnFolder = Workspace:FindFirstChild("Spawn")
		if spawnFolder then
			local btn = spawnFolder:FindFirstChild("Button", true)
			local touch = btn and btn:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "group")
			end
		end

		-- 2) 500 Coins Chest: Workspace.Model."1 chest 500"
		local m1 = Workspace:FindFirstChild("1 chest 500", true)
		if m1 then
			local touch = m1:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "500")
			end
		end

		-- 3) 50k Coins Chest: Workspace.Model."3rd chest 50k"
		local m2 = Workspace:FindFirstChild("3rd chest 50k", true)
		if m2 then
			local touch = m2:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "50k")
			end
		end

		-- 4) 49 Robux Chest: Workspace.Model."49robux chest"
		local m3 = Workspace:FindFirstChild("49robux chest", true)
		if m3 then
			local touch = m3:FindFirstChild("Touch", true)
			if touch and touch:IsA("BasePart") then
				bindPad(touch, "robux")
			end
		end
	end)
end

return WorldChestService
