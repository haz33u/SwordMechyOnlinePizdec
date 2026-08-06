--!strict
--[[
	AAA Custom Loading Screen & Asset Preloader for Sword Masters.
	- Disables default Roblox loading screen
	- Preloads 3D weapon models, pet models, UI icons & animations via ContentProvider
	- Smooth animated progress bar with glowing candy aesthetics
	- Rotating gameplay tips ticker
	- Smooth 0.5s fade-out transition upon completion
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local RainbowGradient = require(script.Parent.RainbowGradient)

local LoadingScreen = {}

-- Disable default Roblox loading screen as early as possible
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local TIPS = {
	"Tip: Rebirth increases both your Damage and Coins multiplier!",
	"Tip: Equip your best offhand sword to gain extra power!",
	"Tip: Bosses drop valuable Enchant Dust every 10 minutes!",
	"Tip: Unlocking new locations gives access to stronger pets and weapons!",
	"Tip: Check the Skill Tree (U) to upgrade your Speed, Power and Backpack!",
	"Tip: Complete daily quests to earn free rewards and gems!",
}

function LoadingScreen.Mount(gui: ScreenGui): { StepProgress: (number, string) -> (), Finish: () -> () }
	local root = Instance.new("Frame")
	root.Name = "LoadingScreenRoot"
	root.Size = UDim2.fromScale(1, 1)
	root.Position = UDim2.fromOffset(0, 0)
	root.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
	root.BorderSizePixel = 0
	root.ZIndex = 1000
	root.Parent = gui

	-- Dark vignette gradient backdrop
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 32)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 10, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 4, 10)),
	})
	bgGrad.Rotation = 45
	bgGrad.Parent = root

	-- Background subtle particle/glow ring
	local glowRing = Instance.new("Frame")
	glowRing.Name = "GlowRing"
	glowRing.Size = UDim2.fromOffset(450, 450)
	glowRing.Position = UDim2.fromScale(0.5, 0.4)
	glowRing.AnchorPoint = Vector2.new(0.5, 0.5)
	glowRing.BackgroundColor3 = Color3.fromRGB(140, 50, 255)
	glowRing.BackgroundTransparency = 0.85
	glowRing.BorderSizePixel = 0
	glowRing.ZIndex = 1001
	glowRing.Parent = root
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(1, 0)
	ringCorner.Parent = glowRing

	-- Title Container
	local titleContainer = Instance.new("Frame")
	titleContainer.Name = "TitleContainer"
	titleContainer.Size = UDim2.fromOffset(600, 100)
	titleContainer.Position = UDim2.fromScale(0.5, 0.38)
	titleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	titleContainer.BackgroundTransparency = 1
	titleContainer.ZIndex = 1002
	titleContainer.Parent = root

	local gameTitle = Instance.new("TextLabel")
	gameTitle.Name = "Title"
	gameTitle.Size = UDim2.fromScale(1, 0.7)
	gameTitle.Position = UDim2.fromScale(0, 0)
	gameTitle.BackgroundTransparency = 1
	gameTitle.Text = "SWORD MASTERS"
	gameTitle.Font = Enum.Font.LuckiestGuy
	gameTitle.TextSize = 52
	gameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	gameTitle.TextXAlignment = Enum.TextXAlignment.Center
	gameTitle.ZIndex = 1003
	gameTitle.Parent = titleContainer
	UIKit.StyleText(gameTitle, "gold", 3)

	local subTitle = Instance.new("TextLabel")
	subTitle.Name = "SubTitle"
	subTitle.Size = UDim2.new(1, 0, 0.3, 0)
	subTitle.Position = UDim2.fromScale(0, 0.7)
	subTitle.BackgroundTransparency = 1
	subTitle.Text = "PREPARING YOUR ADVENTURE..."
	subTitle.Font = Enum.Font.Arcade
	subTitle.TextSize = 16
	subTitle.TextColor3 = Color3.fromRGB(200, 180, 240)
	subTitle.TextXAlignment = Enum.TextXAlignment.Center
	subTitle.ZIndex = 1003
	subTitle.Parent = titleContainer

	-- Progress Bar Container (bottom center)
	local barTrack = Instance.new("Frame")
	barTrack.Name = "ProgressBarTrack"
	barTrack.Size = UDim2.fromOffset(500, 24)
	barTrack.Position = UDim2.fromScale(0.5, 0.65)
	barTrack.AnchorPoint = Vector2.new(0.5, 0.5)
	barTrack.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
	barTrack.BorderSizePixel = 0
	barTrack.ZIndex = 1002
	barTrack.Parent = root

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 12)
	trackCorner.Parent = barTrack

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Thickness = 2
	trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackStroke.Color = Color3.fromRGB(120, 80, 200)
	trackStroke.Parent = barTrack

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(0, 230, 140)
	barFill.BorderSizePixel = 0
	barFill.ZIndex = 1003
	barFill.Parent = barTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 12)
	fillCorner.Parent = barFill

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 160)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 210, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 60, 255)),
	})
	fillGrad.Parent = barFill

	RainbowGradient.ApplyShimmer(barTrack, "emerald", 0.5, 140)

	-- Status Text (above progress bar)
	local statusLab = Instance.new("TextLabel")
	statusLab.Name = "StatusText"
	statusLab.Size = UDim2.fromOffset(500, 20)
	statusLab.Position = UDim2.fromScale(0.5, 0.61)
	statusLab.AnchorPoint = Vector2.new(0.5, 1)
	statusLab.BackgroundTransparency = 1
	statusLab.Text = "Loading Assets (0%)..."
	statusLab.Font = Enum.Font.Arcade
	statusLab.TextSize = 14
	statusLab.TextColor3 = Color3.fromRGB(240, 240, 255)
	statusLab.TextXAlignment = Enum.TextXAlignment.Center
	statusLab.ZIndex = 1003
	statusLab.Parent = root

	-- Rotating Tip Text (below progress bar)
	local tipLab = Instance.new("TextLabel")
	tipLab.Name = "TipText"
	tipLab.Size = UDim2.fromOffset(650, 30)
	tipLab.Position = UDim2.fromScale(0.5, 0.72)
	tipLab.AnchorPoint = Vector2.new(0.5, 0)
	tipLab.BackgroundTransparency = 1
	tipLab.Text = TIPS[1]
	tipLab.Font = Enum.Font.FredokaOne
	tipLab.TextSize = 14
	tipLab.TextColor3 = Color3.fromRGB(255, 210, 100)
	tipLab.TextXAlignment = Enum.TextXAlignment.Center
	tipLab.ZIndex = 1003
	tipLab.Parent = root

	-- Tip Rotation Thread
	local currentTipIdx = 1
	local tipRunning = true
	task.spawn(function()
		while tipRunning and root.Parent do
			task.wait(2.8)
			if not tipRunning or not root.Parent then
				break
			end
			currentTipIdx = (currentTipIdx % #TIPS) + 1
			-- Smooth text transition
			TweenService:Create(tipLab, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
			task.wait(0.2)
			if not tipRunning or not root.Parent then
				break
			end
			tipLab.Text = TIPS[currentTipIdx]
			TweenService:Create(tipLab, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 0 }):Play()
		end
	end)

	local api = {}

	function api.StepProgress(pct: number, statusMessage: string)
		local clampedPct = math.clamp(pct, 0, 1)
		TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(clampedPct, 1),
		}):Play()
		statusLab.Text = string.format("%s (%d%%)", statusMessage, math.floor(clampedPct * 100))
	end

	function api.Finish()
		tipRunning = false
		api.StepProgress(1.0, "Ready!")
		task.wait(0.2)

		-- Fade out entire root smoothly
		local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, child in root:GetDescendants() do
			if child:IsA("TextLabel") then
				TweenService:Create(child, fadeInfo, { TextTransparency = 1 }):Play()
			elseif child:IsA("Frame") then
				TweenService:Create(child, fadeInfo, { BackgroundTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, fadeInfo, { Transparency = 1 }):Play()
			end
		end
		local bgTw = TweenService:Create(root, fadeInfo, { BackgroundTransparency = 1 })
		bgTw:Play()
		bgTw.Completed:Connect(function()
			root:Destroy()
		end)
	end

	return api
end

-- Preload asset instances via ContentProvider
function LoadingScreen.PreloadAssets(stepCallback: (number, string) -> ())
	local assetsToPreload: { Instance } = {}

	local function addFrom(folderName: string)
		local f = ReplicatedStorage:FindFirstChild(folderName)
		if f then
			for _, child in f:GetChildren() do
				table.insert(assetsToPreload, child)
			end
		end
	end

	addFrom("WeaponModels")
	addFrom("PetModels")
	addFrom("AuraVfx")

	local total = #assetsToPreload
	if total == 0 then
		stepCallback(0.5, "Loading Configurations...")
		task.wait(0.3)
		stepCallback(1.0, "Synchronizing World...")
		return
	end

	local loaded = 0
	local batchSize = 6

	for i = 1, total, batchSize do
		local batch = {}
		for j = i, math.min(i + batchSize - 1, total) do
			table.insert(batch, assetsToPreload[j])
		end
		pcall(function()
			ContentProvider:PreloadAsync(batch)
		end)
		loaded = math.min(i + batchSize - 1, total)
		local progress = loaded / total
		stepCallback(progress * 0.85, string.format("Preloading Assets (%d/%d)...", loaded, total))
		task.wait(0.02)
	end

	stepCallback(0.95, "Synchronizing Player Data...")
	task.wait(0.2)
	stepCallback(1.0, "Ready!")
end

return LoadingScreen
