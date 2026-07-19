--!strict
--[[
	World ferryman NPC near each location spawn.
	Click / ProximityPrompt → client opens travel UI (locations panel).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local WorldService = require(script.Parent.WorldService)

local FerrymanService = {}
FerrymanService._npcs = {} :: { [number]: Model }

local function ensureFolder(): Folder
	local f = Workspace:FindFirstChild("NPCs")
	if f and f:IsA("Folder") then
		return f
	end
	local folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = Workspace
	return folder
end

local function makeFerryman(locationId: number): Model?
	local spawnCf = WorldService.GetSpawnCFrame(locationId)
	if not spawnCf then
		-- fallback math spawn
		local WorldConfig = require(Shared.Config.WorldConfig)
		spawnCf = WorldConfig.GetSpawnCFrame(locationId)
	end
	if not spawnCf then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = "Ferryman_Loc" .. tostring(locationId)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 5, 2)
	root.Anchored = true
	root.CanCollide = false
	root.Color = Color3.fromRGB(40, 90, 140)
	root.Material = Enum.Material.SmoothPlastic
	root.CFrame = spawnCf * CFrame.new(8, 2.5, 0)
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Anchored = true
	head.CanCollide = false
	head.Shape = Enum.PartType.Ball
	head.Color = Color3.fromRGB(255, 220, 180)
	head.CFrame = root.CFrame * CFrame.new(0, 3.2, 0)
	head.Parent = model

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(160, 40)
	bill.StudsOffset = Vector3.new(0, 4.2, 0)
	bill.AlwaysOnTop = true
	bill.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	label.TextColor3 = Color3.fromRGB(180, 220, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = "Ferryman · Worlds"
	label.Parent = bill
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Travel"
	prompt.ObjectText = "Ferryman"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	prompt.Triggered:Connect(function(player)
		Remotes.Event("OpenTravel"):FireClient(player)
		Remotes.Event("Notify"):FireClient(player, {
			text = "Ferryman: Loc2 needs R2 + 500K once",
			color = "cyan",
		})
	end)

	-- also ClickDetector for mouse users without proximity UI
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 16
	cd.Parent = root
	cd.MouseClick:Connect(function(player)
		Remotes.Event("OpenTravel"):FireClient(player)
	end)

	model.PrimaryPart = root
	model.Parent = ensureFolder()
	return model
end

function FerrymanService.Init()
	Remotes.Event("OpenTravel") -- ensure exists
	task.defer(function()
		task.wait(1)
		for locId = 1, 4 do
			local m = makeFerryman(locId)
			if m then
				FerrymanService._npcs[locId] = m
			end
		end
		print("[FerrymanService] NPCs spawned near spawns (Travel prompt)")
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			-- prompts already global
		end)
	end)
end

return FerrymanService
