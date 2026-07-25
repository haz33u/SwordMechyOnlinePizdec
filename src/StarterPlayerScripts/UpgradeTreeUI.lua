--!strict
--[[
	UpgradeTreeUI.lua
	Complete visual upgrade tree layout inspired by Noob Incremental (Com_UITree).
	Displays interactive tree nodes, connection lines, unlock conditions, and level-ups.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TalentTreeConfig = require(Shared.Config.TalentTreeConfig)
local NumberFormat = require(Shared.NumberFormat)
local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)

local UpgradeTreeUI = {}
local currentGui: ScreenGui? = nil
local frame: Frame? = nil
local mapCanvas: Frame? = nil
local player = Players.LocalPlayer

-- Node positions on canvas
local NODE_POSITIONS = {
	root = Vector2.new(350, 50),
	power_1 = Vector2.new(200, 150),
	speed_1 = Vector2.new(500, 150),
	crit_1 = Vector2.new(100, 270),
	bag_1 = Vector2.new(300, 270),
	coin_1 = Vector2.new(450, 270),
	power_2 = Vector2.new(600, 270),
	mastery_boost = Vector2.new(350, 390),
}

local function drawLine(parent: Frame, p1: Vector2, p2: Vector2, isUnlocked: boolean): Frame
	local dist = (p2 - p1).Magnitude
	local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)

	local line = Instance.new("Frame")
	line.Name = "ConnectionLine"
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.fromOffset(p1.X, p1.Y)
	line.Size = UDim2.fromOffset(dist, isUnlocked and 3 or 2)
	line.Rotation = math.deg(angle)
	line.BackgroundColor3 = isUnlocked and Color3.fromRGB(80, 200, 255) or Color3.fromRGB(60, 65, 80)
	line.BorderSizePixel = 0
	line.ZIndex = 52
	line.Parent = parent
	return line
end

function UpgradeTreeUI.Mount(parentGui: ScreenGui, store: any)
	currentGui = parentGui

	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "UpgradeTreeFrame"
	modalFrame.Size = UDim2.fromOffset(720, 520)
	modalFrame.Position = UDim2.fromScale(0.5, 0.5)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	modalFrame.BorderSizePixel = 0
	modalFrame.Visible = false
	modalFrame.ZIndex = 60
	modalFrame.Parent = parentGui

	UIKit.Corner(modalFrame, T.R.md)
	UIKit.Stroke(modalFrame, Color3.fromRGB(90, 160, 250), 2, 0.2)

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -40, 0, 36)
	header.Position = UDim2.new(0, 20, 0, 14)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.Arcade
	header.TextSize = 22
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "SKILL & UPGRADE TREE"
	header.Parent = modalFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromOffset(32, 32)
	closeBtn.Position = UDim2.new(1, -44, 0, 14)
	closeBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 60)
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "X"
	closeBtn.Parent = modalFrame
	UIKit.Corner(closeBtn, 6)

	closeBtn.MouseButton1Click:Connect(function()
		modalFrame.Visible = false
	end)

	-- Scrollable Map Canvas
	local scrollMap = Instance.new("ScrollingFrame")
	scrollMap.Name = "ScrollMap"
	scrollMap.Size = UDim2.new(1, -40, 1, -70)
	scrollMap.Position = UDim2.new(0, 20, 0, 56)
	scrollMap.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
	scrollMap.BorderSizePixel = 0
	scrollMap.CanvasSize = UDim2.fromOffset(700, 500)
	scrollMap.ScrollBarThickness = 6
	scrollMap.Parent = modalFrame
	UIKit.Corner(scrollMap, T.R.sm)

	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.Parent = scrollMap
	mapCanvas = canvas

	local function renderTree()
		if not mapCanvas then return end
		mapCanvas:ClearAllChildren()

		local profile = store:PeekProfile()
		local unlocked = (profile and profile.unlockedTalents) or {}

		-- Render connection lines
		for nodeId, nodeDef in TalentTreeConfig.Nodes do
			local p1 = NODE_POSITIONS[nodeId]
			if not p1 then continue end
			for _, childId in nodeDef.children or {} do
				local p2 = NODE_POSITIONS[childId]
				if p2 then
					local isConnActive = unlocked[nodeId] == true and unlocked[childId] == true
					drawLine(mapCanvas, p1, p2, isConnActive)
				end
			end
		end

		-- Render node cards
		for nodeId, nodeDef in TalentTreeConfig.Nodes do
			local pos = NODE_POSITIONS[nodeId] or Vector2.new(350, 250)
			local isUnlocked = unlocked[nodeId] == true

			local nodeCard = Instance.new("TextButton")
			nodeCard.Name = "Node_" .. nodeId
			nodeCard.Size = UDim2.fromOffset(110, 64)
			nodeCard.Position = UDim2.fromOffset(pos.X - 55, pos.Y - 32)
			nodeCard.BackgroundColor3 = isUnlocked and Color3.fromRGB(40, 120, 210) or Color3.fromRGB(32, 35, 45)
			nodeCard.BorderSizePixel = 0
			nodeCard.AutoButtonColor = true
			nodeCard.Text = ""
			nodeCard.ZIndex = 60
			nodeCard.Parent = mapCanvas
			UIKit.Corner(nodeCard, 8)
			UIKit.Stroke(nodeCard, isUnlocked and Color3.fromRGB(90, 200, 255) or Color3.fromRGB(70, 75, 90), 1.5, 0.2)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Size = UDim2.new(1, -8, 0, 22)
			titleLbl.Position = UDim2.new(0, 4, 0, 4)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.Arcade
			titleLbl.TextSize = 11
			titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			titleLbl.TextWrapped = true
			titleLbl.Text = nodeDef.name or nodeId
			titleLbl.ZIndex = 61
			titleLbl.Parent = nodeCard

			local statLbl = Instance.new("TextLabel")
			statLbl.Size = UDim2.new(1, -8, 0, 18)
			statLbl.Position = UDim2.new(0, 4, 0, 26)
			statLbl.BackgroundTransparency = 1
			statLbl.Font = Enum.Font.Arcade
			statLbl.TextSize = 10
			statLbl.TextColor3 = isUnlocked and Color3.fromRGB(180, 240, 255) or Color3.fromRGB(160, 160, 180)
			statLbl.Text = isUnlocked and "[UNLOCKED]" or ("Cost: " .. NumberFormat.Num(nodeDef.costCoins or 0))
			statLbl.ZIndex = 61
			statLbl.Parent = nodeCard

			nodeCard.MouseButton1Click:Connect(function()
				if not isUnlocked then
					Net.BuyTalentNode(nodeId)
					task.delay(0.2, renderTree)
				end
			end)
		end
	end

	renderTree()
	frame = modalFrame

	return {
		Toggle = function()
			if frame then
				frame.Visible = not frame.Visible
				if frame.Visible then renderTree() end
			end
		end,
		Show = function()
			if frame then
				frame.Visible = true
				renderTree()
			end
		end,
		Hide = function()
			if frame then
				frame.Visible = false
			end
		end,
	}
end

return UpgradeTreeUI
