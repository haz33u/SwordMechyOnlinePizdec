--!strict
--[[
	UpgradeTreeUI.lua
	Complete working implementation of the Noob Incremental Skill & Upgrade Tree UI.
	Uses the original UIUpgradeTree.lua config and Icons.lua module.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIUpgradeTree = require(Shared.Modules.UIUpgradeTree)
local Icons = require(Shared.Modules.Icons)
local NumberFormat = require(Shared.NumberFormat)
local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)

local UpgradeTreeUI = {}
local currentGui: ScreenGui? = nil
local frame: Frame? = nil
local mapCanvas: Frame? = nil
local hoverFrame: Frame? = nil
local storeRef: any = nil
local player = Players.LocalPlayer

-- Manual grid layout positions for Noob Incremental tree nodes (X, Y)
local NODE_CANVAS_POS = {
	TheStart = Vector2.new(400, 520),
	PrismGenerationSpeed = Vector2.new(400, 410),
	MorePrismPlus1 = Vector2.new(340, 310),
	PrismMultiLeft = Vector2.new(240, 310),
	MorePrismPlus2 = Vector2.new(140, 310),
	OofMulti1 = Vector2.new(240, 520),
	OofMulti2 = Vector2.new(140, 520),
	OofMulti3 = Vector2.new(40, 520),
	RuneSpeedMulRight1 = Vector2.new(560, 520),
	RuneSpeedMulRight2 = Vector2.new(660, 520),
	RuneSpeedMulRight3 = Vector2.new(760, 520),
	PrismMulR3_1 = Vector2.new(460, 310),
	PrismMulR3_2 = Vector2.new(560, 310),
	PrismMulR3_3 = Vector2.new(660, 310),
}

local function drawLine(parent: Frame, p1: Vector2, p2: Vector2, isUnlocked: boolean)
	local dist = (p2 - p1).Magnitude
	local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)

	local line = Instance.new("Frame")
	line.Name = "ConnectionLine"
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.fromOffset(p1.X, p1.Y)
	line.Size = UDim2.fromOffset(dist, isUnlocked and 3 or 2)
	line.Rotation = math.deg(angle)
	line.BackgroundColor3 = isUnlocked and Color3.fromRGB(80, 200, 255) or Color3.fromRGB(55, 60, 75)
	line.BorderSizePixel = 0
	line.ZIndex = 51
	line.Parent = parent
end

function UpgradeTreeUI.Mount(parentGui: ScreenGui, store: any)
	currentGui = parentGui
	storeRef = store

	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "UpgradeTreeFrame"
	modalFrame.Size = UDim2.fromOffset(780, 560)
	modalFrame.Position = UDim2.fromScale(0.5, 0.5)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
	modalFrame.BorderSizePixel = 0
	modalFrame.ClipsDescendants = true
	modalFrame.Visible = false
	modalFrame.ZIndex = 60
	modalFrame.Parent = parentGui

	UIKit.Corner(modalFrame, T.R.md)
	UIKit.Stroke(modalFrame, Color3.fromRGB(90, 160, 250), 2, 0.2)

	-- Header Title
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -50, 0, 36)
	header.Position = UDim2.new(0, 20, 0, 14)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.Arcade
	header.TextSize = 22
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "NOOB INCREMENTAL — SKILL & UPGRADE TREE"
	header.Parent = modalFrame

	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromOffset(32, 32)
	closeBtn.Position = UDim2.new(1, -44, 0, 14)
	closeBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 60)
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "X"
	closeBtn.ZIndex = 65
	closeBtn.Parent = modalFrame
	UIKit.Corner(closeBtn, 6)

	closeBtn.MouseButton1Click:Connect(function()
		modalFrame.Visible = false
	end)

	-- Hover Tooltip Frame
	local tooltip = Instance.new("Frame")
	tooltip.Name = "HoveringFrame"
	tooltip.Size = UDim2.fromOffset(220, 100)
	tooltip.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	tooltip.BorderSizePixel = 0
	tooltip.Visible = false
	tooltip.ZIndex = 100
	tooltip.Parent = modalFrame
	UIKit.Corner(tooltip, 8)
	UIKit.Stroke(tooltip, Color3.fromRGB(100, 180, 255), 1.5, 0.2)

	local ttTitle = Instance.new("TextLabel")
	ttTitle.Size = UDim2.new(1, -12, 0, 22)
	ttTitle.Position = UDim2.new(0, 6, 0, 4)
	ttTitle.BackgroundTransparency = 1
	ttTitle.Font = Enum.Font.Arcade
	ttTitle.TextSize = 13
	ttTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
	ttTitle.TextXAlignment = Enum.TextXAlignment.Left
	ttTitle.Text = ""
	ttTitle.ZIndex = 101
	ttTitle.Parent = tooltip

	local ttDesc = Instance.new("TextLabel")
	ttDesc.Size = UDim2.new(1, -12, 0, 36)
	ttDesc.Position = UDim2.new(0, 6, 0, 26)
	ttDesc.BackgroundTransparency = 1
	ttDesc.Font = Enum.Font.Arcade
	ttDesc.TextSize = 11
	ttDesc.TextColor3 = Color3.fromRGB(200, 210, 225)
	ttDesc.TextWrapped = true
	ttDesc.TextXAlignment = Enum.TextXAlignment.Left
	ttDesc.Text = ""
	ttDesc.ZIndex = 101
	ttDesc.Parent = tooltip

	local ttCost = Instance.new("TextLabel")
	ttCost.Size = UDim2.new(1, -12, 0, 20)
	ttCost.Position = UDim2.new(0, 6, 0, 68)
	ttCost.BackgroundTransparency = 1
	ttCost.Font = Enum.Font.Arcade
	ttCost.TextSize = 11
	ttCost.TextColor3 = Color3.fromRGB(120, 240, 160)
	ttCost.TextXAlignment = Enum.TextXAlignment.Left
	ttCost.Text = ""
	ttCost.ZIndex = 101
	ttCost.Parent = tooltip
	hoverFrame = tooltip

	-- Scrollable Canvas Container
	local scrollMap = Instance.new("ScrollingFrame")
	scrollMap.Name = "ScrollMap"
	scrollMap.Size = UDim2.new(1, -32, 1, -66)
	scrollMap.Position = UDim2.new(0, 16, 0, 54)
	scrollMap.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	scrollMap.BorderSizePixel = 0
	scrollMap.ClipsDescendants = true
	scrollMap.CanvasSize = UDim2.fromOffset(840, 640)
	scrollMap.ScrollBarThickness = 6
	scrollMap.Parent = modalFrame
	UIKit.Corner(scrollMap, T.R.sm)

	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.ClipsDescendants = true
	canvas.Parent = scrollMap
	mapCanvas = canvas

	local function renderTree()
		if not mapCanvas or not storeRef then return end
		mapCanvas:ClearAllChildren()

		local profile = storeRef:PeekProfile()
		local unlocked = (profile and profile.unlockedTalents) or { TheStart = 1, C_Core = 1 }

		local nodeDefs = UIUpgradeTree.Nodes or {}

		-- 1. Draw connection lines between center points
		for nodeId, nodeData in pairs(nodeDefs) do
			local p1 = NODE_CANVAS_POS[nodeId] or Vector2.new(400, 300)
			for _, childId in ipairs(nodeData.unlocks or {}) do
				local childData = nodeDefs[childId]
				local p2 = NODE_CANVAS_POS[childId]
				if childData and p2 then
					local pLvl = unlocked[nodeId] or 0
					local isUnlocked = (typeof(pLvl) == "number" and pLvl > 0) or pLvl == true
					drawLine(mapCanvas, p1, p2, isUnlocked)
				end
			end
		end

		-- 2. Render node cards centered at NODE_CANVAS_POS
		for nodeId, nodeData in pairs(nodeDefs) do
			local pos = NODE_CANVAS_POS[nodeId] or Vector2.new(400, 300)
			local rawVal = unlocked[nodeId]
			local currentLvl = if typeof(rawVal) == "number" then rawVal else (if rawVal == true then 1 else 0)
			local maxLvl = nodeData.maxLevel or 1
			local isMax = currentLvl >= maxLvl
			local isUnlocked = currentLvl > 0

			local nodeCard = Instance.new("TextButton")
			nodeCard.Name = "Node_" .. nodeId
			nodeCard.Size = UDim2.fromOffset(108, 56)
			nodeCard.AnchorPoint = Vector2.new(0.5, 0.5)
			nodeCard.Position = UDim2.fromOffset(pos.X, pos.Y)
			nodeCard.BackgroundColor3 = isMax and Color3.fromRGB(40, 140, 220) or (isUnlocked and Color3.fromRGB(35, 100, 160) or Color3.fromRGB(28, 30, 38))
			nodeCard.BorderSizePixel = 0
			nodeCard.AutoButtonColor = true
			nodeCard.Text = ""
			nodeCard.ZIndex = 60
			nodeCard.Parent = mapCanvas
			UIKit.Corner(nodeCard, 8)
			UIKit.Stroke(nodeCard, isMax and Color3.fromRGB(100, 220, 255) or (isUnlocked and Color3.fromRGB(80, 160, 230) or Color3.fromRGB(60, 65, 80)), 1.5, 0.2)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Size = UDim2.new(1, -6, 0, 20)
			titleLbl.Position = UDim2.new(0, 3, 0, 3)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.Arcade
			titleLbl.TextSize = 11
			titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			titleLbl.TextWrapped = true
			titleLbl.Text = nodeData.title or nodeId
			titleLbl.ZIndex = 61
			titleLbl.Parent = nodeCard

			-- Calculate cost using nodeData.getCost
			local costNum = 0
			if nodeData.getCost then
				costNum = nodeData.getCost(currentLvl)
			end
			local costText = if isMax then "[MAX]" else (costNum <= 0 and "FREE" or NumberFormat.Num(costNum) .. " Coins")

			local statLbl = Instance.new("TextLabel")
			statLbl.Size = UDim2.new(1, -6, 0, 18)
			statLbl.Position = UDim2.new(0, 3, 0, 24)
			statLbl.BackgroundTransparency = 1
			statLbl.Font = Enum.Font.Arcade
			statLbl.TextSize = 10
			statLbl.TextColor3 = isMax and Color3.fromRGB(180, 255, 200) or (isUnlocked and Color3.fromRGB(180, 230, 255) or Color3.fromRGB(160, 160, 175))
			statLbl.Text = string.format("Lv.%d/%d • %s", currentLvl, maxLvl, costText)
			statLbl.ZIndex = 61
			statLbl.Parent = nodeCard

			-- Mouse Hover Tooltip
			nodeCard.MouseEnter:Connect(function()
				if hoverFrame then
					ttTitle.Text = nodeData.title or nodeId
					ttDesc.Text = nodeData.desc or ""
					ttCost.Text = "Cost: " .. costText
					hoverFrame.Position = UDim2.fromOffset(nodeCard.Position.X.Offset + 60, nodeCard.Position.Y.Offset - 20)
					hoverFrame.Visible = true
				end
			end)

			nodeCard.MouseLeave:Connect(function()
				if hoverFrame then
					hoverFrame.Visible = false
				end
			end)

			nodeCard.MouseButton1Click:Connect(function()
				if not isMax then
					pcall(function()
						Net.UnlockTalentNode(nodeId)
					end)
					task.delay(0.25, renderTree)
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
