--!strict
--[[
	Pet Model Studio Snapshot Generator
	
	ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ:
	1. Откройте ваш проект в Roblox Studio.
	2. Откройте Command Bar (Command Bar внизу экрана или через меню View -> Command Bar).
	3. Вставьте весь этот код в Command Bar и нажмите Enter.
	
	ЧТО СДЕЛАЕТ СКРИПТ:
	- Создаст на вашем экране сетку со ВСЕМИ 3D-моделями петов из ReplicatedStorage.PetModels.
	- Настроит идеальный студийный свет, правильную камеру (FOV 25) и чистый темно-фиолетовый/прозрачный фон.
	- Каждый пет будет отрендерен ровно в его 1-в-1 игровом виде!
]]

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
if not petModelsFolder then
	warn("[SnapshotGenerator] Папка ReplicatedStorage.PetModels не найдена!")
	return
end

-- Удаляем старое окно если было
local oldGui = CoreGui:FindFirstChild("PetSnapshotGui")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetSnapshotGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
mainFrame.Parent = screenGui

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(1, 0.9)
scroll.Position = UDim2.fromScale(0, 0.05)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = mainFrame

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(160, 160)
grid.CellPadding = UDim2.fromOffset(16, 16)
grid.SortOrder = Enum.SortOrder.Name
grid.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 20)
padding.PaddingLeft = UDim.new(0, 20)
padding.PaddingRight = UDim.new(0, 20)
padding.Parent = scroll

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "📷 PET 3D MODELS STUDIO RENDER SNAPSHOTS"
title.TextColor3 = Color3.fromRGB(56, 189, 248)
title.TextSize = 20
title.Font = Enum.Font.FredokaOne
title.Parent = mainFrame

for _, item in petModelsFolder:GetChildren() do
	if item:IsA("Model") or item:IsA("BasePart") then
		local card = Instance.new("Frame")
		card.Name = item.Name
		card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
		card.BorderSizePixel = 0

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(56, 189, 248)
		stroke.Thickness = 1.5
		stroke.Parent = card

		local viewport = Instance.new("ViewportFrame")
		viewport.Size = UDim2.new(1, 0, 1, -26)
		viewport.BackgroundTransparency = 1
		viewport.Ambient = Color3.fromRGB(180, 190, 210)
		viewport.LightColor = Color3.fromRGB(255, 245, 230)
		viewport.LightDirection = Vector3.new(-1, -1.5, -1).Unit
		viewport.Parent = card

		local modelClone = item:Clone()
		modelClone.Parent = viewport

		local cam = Instance.new("Camera")
		cam.FieldOfView = 25
		viewport.CurrentCamera = cam
		cam.Parent = viewport

		-- Centering camera around model bounding box
		local cf, size
		if modelClone:IsA("Model") then
			cf, size = modelClone:GetBoundingBox()
		else
			cf = modelClone.CFrame
			size = modelClone.Size
		end

		local maxExtent = math.max(size.X, size.Y, size.Z)
		if maxExtent < 0.1 then maxExtent = 1 end
		local dist = maxExtent * 2.2

		cam.CFrame = CFrame.lookAt(
			cf.Position + Vector3.new(dist * 0.4, dist * 0.3, dist),
			cf.Position
		)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 24)
		label.Position = UDim2.new(0, 0, 1, -24)
		label.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
		label.Text = "Model: " .. item.Name
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 12
		label.Font = Enum.Font.SourceSansBold
		label.Parent = card

		card.Parent = scroll
	end
end

screenGui.Parent = CoreGui
print("✅ [SnapshotGenerator] Сетка рендеров петов успешно создана на экране в Roblox Studio!")
