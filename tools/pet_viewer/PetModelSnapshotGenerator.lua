--!strict
--[[
	High-Quality Pet Studio Snapshot Generator (v2 - Big Cards + Studio Lighting + All Folders)
]]

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oldGui = CoreGui:FindFirstChild("PetSnapshotGui")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetSnapshotGui"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
mainFrame.Parent = screenGui

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(1, 0.92)
scroll.Position = UDim2.fromScale(0, 0.08)
scroll.BackgroundTransparency = 1
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = mainFrame

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(260, 260) -- Крупные карточки!
grid.CellPadding = UDim2.fromOffset(20, 20)
grid.SortOrder = Enum.SortOrder.Name
grid.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 24)
padding.PaddingLeft = UDim.new(0, 24)
padding.PaddingRight = UDim.new(0, 24)
padding.Parent = scroll

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 48)
title.BackgroundTransparency = 1
title.Text = "✨ STUDIO HIGH-QUALITY PET RENDERS ENGINE"
title.TextColor3 = Color3.fromRGB(56, 189, 248)
title.TextSize = 22
title.Font = Enum.Font.FredokaOne
title.Parent = mainFrame

-- Поиск всех папок с моделями
local foldersToScan = {}
local petModels = ReplicatedStorage:FindFirstChild("PetModels")
if petModels then table.insert(foldersToScan, petModels) end

local inc = ReplicatedStorage:FindFirstChild("INCREMENTAL ASSETS")
if inc then
	for _, child in inc:GetChildren() do
		if child:IsA("Folder") then table.insert(foldersToScan, child) end
	end
end

local totalCount = 0

for _, folder in foldersToScan do
	for _, item in folder:GetChildren() do
		if item:IsA("Model") or item:IsA("BasePart") then
			totalCount += 1
			local card = Instance.new("Frame")
			card.Name = item.Name
			card.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
			card.BorderSizePixel = 0
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(56, 189, 248)
			stroke.Thickness = 2
			stroke.Parent = card

			-- Светлая подложка для контрастности
			local bgGradient = Instance.new("UIGradient")
			bgGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 45, 70)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 20, 32))
			})
			bgGradient.Rotation = 45
			bgGradient.Parent = card

			local viewport = Instance.new("ViewportFrame")
			viewport.Size = UDim2.new(1, -16, 1, -44)
			viewport.Position = UDim2.new(0, 8, 0, 8)
			viewport.BackgroundTransparency = 1
			
			-- Студийное яркое освещение
			viewport.Ambient = Color3.fromRGB(210, 220, 240)
			viewport.LightColor = Color3.fromRGB(255, 255, 255)
			viewport.LightDirection = Vector3.new(-1, -1.2, -1).Unit
			viewport.Parent = card

			local modelClone = item:Clone()
			modelClone.Parent = viewport

			-- Очистка от скриптов/лишнего
			for _, d in modelClone:GetDescendants() do
				if d:IsA("BaseScript") or d:IsA("Sound") then d:Destroy() end
			end

			local cam = Instance.new("Camera")
			cam.FieldOfView = 22 -- Узкий сочный FOV
			viewport.CurrentCamera = cam
			cam.Parent = viewport

			local cf: CFrame, size: Vector3
			if modelClone:IsA("Model") then
				cf, size = modelClone:GetBoundingBox()
			else
				cf = modelClone.CFrame
				size = modelClone.Size
			end

			local maxExtent = math.max(size.X, size.Y, size.Z)
			if maxExtent < 0.1 then maxExtent = 1 end
			local dist = maxExtent * 1.65

			-- Изометрический студийный угол
			cam.CFrame = CFrame.lookAt(
				cf.Position + Vector3.new(dist * 0.5, dist * 0.35, dist * 0.9),
				cf.Position
			)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, 30)
			label.Position = UDim2.new(0, 0, 1, -30)
			label.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
			label.Text = "[" .. folder.Name .. "] " .. item.Name
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextSize = 13
			label.Font = Enum.Font.FredokaOne
			label.Parent = card

			card.Parent = scroll
		end
	end
end

title.Text = "✨ STUDIO 3D RENDERS ENGINE (" .. totalCount .. " MODELS FOUND IN GAME)"
screenGui.Parent = CoreGui
print("✅ [SnapshotGenerator v2] Найдено моделей: " .. totalCount .. "! Рендеры обновлены!")
