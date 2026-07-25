--!strict
--[[
	LootVFX.lua
	Client-side physical 3D drop animations:
	Spawns 3D coins, dust gems, or item placeholders at mob death locations,
	pops them outward with random velocity, and smoothly curves them into the HUD.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local LootVFX = {}
local localPlayer = Players.LocalPlayer

local ACTIVE_ITEMS_FOLDER_NAME = "SM_LootVFXFolder"

local function getVFXFolder(): Folder
	local folder = workspace:FindFirstChild(ACTIVE_ITEMS_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = ACTIVE_ITEMS_FOLDER_NAME
		folder.Parent = workspace
	end
	return folder :: Folder
end

local function playDropSound()
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://131886134" -- pop sound
		sound.Volume = 0.35
		sound.PlaybackSpeed = math.random(95, 110) / 100
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

local function playCollectSound()
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://461237526" -- chime collect
		sound.Volume = 0.4
		sound.PlaybackSpeed = math.random(100, 120) / 100
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

-- Quad bezier formula
local function bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local l1 = p0:Lerp(p1, t)
	local l2 = p1:Lerp(p2, t)
	return l1:Lerp(l2, t)
end

function LootVFX.SpawnDrop(startPos: Vector3, lootType: string?, amount: number?)
	local char = localPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local kind = lootType or "Coin"
	local count = math.clamp(amount or 1, 1, 6)

	playDropSound()

	for i = 1, count do
		task.delay((i - 1) * 0.06, function()
			if not hrp or not hrp.Parent then return end

			local part = Instance.new("Part")
			part.Name = "LootDrop_" .. kind
			part.Size = Vector3.new(0.7, 0.7, 0.7)
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			part.Anchored = true
			part.Material = Enum.Material.Neon

			if kind == "Coin" then
				part.Shape = Enum.PartType.Cylinder
				part.Size = Vector3.new(0.2, 0.8, 0.8)
				part.Color = Color3.fromRGB(255, 205, 40)
			elseif kind == "Dust" or kind == "EnchantDust" then
				part.Shape = Enum.PartType.Ball
				part.Size = Vector3.new(0.6, 0.6, 0.6)
				part.Color = Color3.fromRGB(80, 210, 255)
			else
				part.Shape = Enum.PartType.Block
				part.Size = Vector3.new(0.6, 0.8, 0.6)
				part.Color = Color3.fromRGB(190, 80, 255)
			end

			local spreadX = math.random(-35, 35) / 10
			local spreadZ = math.random(-35, 35) / 10
			local popHeight = math.random(30, 55) / 10
			local popPos = startPos + Vector3.new(spreadX, popHeight, spreadZ)

			part.CFrame = CFrame.new(startPos) * CFrame.Angles(math.rad(90), 0, math.rad(math.random(0, 360)))
			part.Parent = getVFXFolder()

			-- Step 1: Pop up
			local popTween = TweenService:Create(
				part,
				TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = CFrame.new(popPos) * CFrame.Angles(math.rad(90), 0, math.rad(math.random(0, 360))) }
			)
			popTween:Play()

			popTween.Completed:Connect(function()
				-- Step 2: Fly to character HRP with Bezier Curve
				local startTime = os.clock()
				local duration = 0.45
				local p0 = part.Position

				local conn: RBXScriptConnection? = nil
				conn = RunService.RenderStepped:Connect(function()
					if not hrp or not hrp.Parent or not part.Parent then
						if conn then conn:Disconnect() end
						part:Destroy()
						return
					end

					local elapsed = os.clock() - startTime
					local t = math.clamp(elapsed / duration, 0, 1)

					local targetPos = hrp.Position + Vector3.new(0, 0.5, 0)
					local midPos = (p0 + targetPos) / 2 + Vector3.new(0, 3, 0)

					local currentPos = bezier(p0, midPos, targetPos, t)
					part.CFrame = CFrame.new(currentPos) * CFrame.Angles(t * 12, t * 8, 0)

					if t >= 1 then
						if conn then conn:Disconnect() end
						part:Destroy()
						playCollectSound()
					end
				end)
			end)
		end)
	end
end

function LootVFX.Init()
	pcall(function()
		Remotes.Event("Notify").OnClientEvent:Connect(function(data)
			if typeof(data) == "table" and data.text then
				local str = tostring(data.text)
				local char = localPlayer.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local pos = (char.HumanoidRootPart :: BasePart).Position + (char.HumanoidRootPart :: BasePart).CFrame.LookVector * 4
					if string.find(str, "coins") or string.find(str, "Coins") then
						LootVFX.SpawnDrop(pos, "Coin", 3)
					elseif string.find(str, "dust") or string.find(str, "Dust") then
						LootVFX.SpawnDrop(pos, "Dust", 2)
					end
				end
			end
		end)
	end)
end

return LootVFX
