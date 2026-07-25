--!strict
--[[
	UpgradeTreeUI.lua
	Dynamic visual Skill & Talent Tree UI.
	Renders axial hex grid nodes from TalentTreeConfig, drawing connection lines,
	showing current level / max level, costs, and triggering Net.UnlockTalentNode on purchase.
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
local storeRef: any = nil
local player = Players.LocalPlayer

-- Converts axial hex coordinates (q, r) to 2D pixel offsets on the map canvas
local function hexToPixel(q: number, r: number): Vector2
	local centerX = 420
	local centerY = 420
	local hexRadius = 60
	local x = centerX + hexRadius * (math.sqrt(3) * q + (math.sqrt(3) / 2) * r)
	local y = centerY + hexRadius * (1.5 * r)
	return Vector2.new(x, y)
end

local function drawLine(parent: Frame, p1: Vector2, p2: Vector2, isUnlocked: boolean): Frame
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
	line.ZIndex = 52
	line.Parent = parent
	return line
end

function UpgradeTreeUI.Mount(parentGui: ScreenGui, store: any)
	currentGui = parentGui
	storeRef = store

	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "UpgradeTreeFrame"
	modalFrame.Size = UDim2.fromOffset(760, 560)
	modalFrame.Position = UDim2.fromScale(0.5, 0.5)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	modalFrame.BorderSizePixel = 0
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

	-- Scrollable Map Canvas
	local scrollMap = Instance.new("ScrollingFrame")
	scrollMap.Name = "ScrollMap"
	scrollMap.Size = UDim2.new(1, -32, 1, -66)
	scrollMap.Position = UDim2.new(0, 16, 0, 54)
	scrollMap.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	scrollMap.BorderSizePixel = 0
	scrollMap.CanvasSize = UDim2.fromOffset(900, 900)
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
		if not mapCanvas or not storeRef then return end
		mapCanvas:ClearAllChildren()

		local profile = storeRef:PeekProfile()
		local unlocked = (profile and profile.unlockedTalents) or { C_Core = 1 }

		local nodeMap = TalentTreeConfig.Nodes or {}

		-- Render connection lines
		for nodeId, nodeDef in nodeMap do
			local p1 = hexToPixel(nodeDef.hexPos.X, nodeDef.hexPos.Y)
			for _, childId in ipairs(nodeDef.parents or {}) do
				local parentDef = nodeMap[childId]
				if parentDef then
					local p2 = hexToPixel(parentDef.hexPos.X, parentDef.hexPos.Y)
					local pLvl = unlocked[childId] or 0
					local cLvl = unlocked[nodeId] or 0
					local isConnActive = (typeof(pLvl) == "number" and pLvl > 0) or pLvl == true
					drawLine(mapCanvas, p1, p2, isConnActive)
				end
			end
		end

		-- Render node cards
		for nodeId, nodeDef in nodeMap do
			local pos = hexToPixel(nodeDef.hexPos.X, nodeDef.hexPos.Y)
			local rawVal = unlocked[nodeId]
			local currentLvl = if typeof(rawVal) == "number" then rawVal else (if rawVal == true then 1 else 0)
			local isMax = currentLvl >= (nodeDef.maxLevel or 1)
			local isUnlocked = currentLvl > 0

			local nodeCard = Instance.new("TextButton")
			nodeCard.Name = "Node_" .. nodeId
			nodeCard.Size = UDim2.fromOffset(104, 60)
			nodeCard.Position = UDim2.fromOffset(pos.X - 52, pos.Y - 30)
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
			titleLbl.Text = (nodeDef.icon or "") .. " " .. (nodeDef.name or nodeId)
			titleLbl.ZIndex = 61
			titleLbl.Parent = nodeCard

			local cost = TalentTreeConfig.GetUpgradeCost(nodeDef, currentLvl)
			local costText = if isMax then "[MAX]" else (if nodeDef.costType == "talentPoints" then (cost .. " TP") else (NumberFormat.Num(cost) .. " Coins"))

			local statLbl = Instance.new("TextLabel")
			statLbl.Size = UDim2.new(1, -6, 0, 18)
			statLbl.Position = UDim2.new(0, 3, 0, 24)
			statLbl.BackgroundTransparency = 1
			statLbl.Font = Enum.Font.Arcade
			statLbl.TextSize = 10
			statLbl.TextColor3 = isMax and Color3.fromRGB(180, 255, 200) or (isUnlocked and Color3.fromRGB(180, 230, 255) or Color3.fromRGB(160, 160, 175))
			statLbl.Text = string.format("Lv.%d/%d • %s", currentLvl, nodeDef.maxLevel or 1, costText)
			statLbl.ZIndex = 61
			statLbl.Parent = nodeCard

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
