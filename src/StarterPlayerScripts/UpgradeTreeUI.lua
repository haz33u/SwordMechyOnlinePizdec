--!strict
--[[
	UpgradeTreeUI.lua
	Complete 1-to-1 Noob Incremental visual Skill & Upgrade Tree.
	Renders explicit node positions for all branches (Damage, Prestige/TP, Luck, Key Finder, Speed)
	with clean line connections, level progression, and backend Net purchases.
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

-- Explicit 2D canvas coordinates for all tree nodes
local TREE_NODE_MAP = {
	-- Start Hub
	TheStart = {
		id = "TheStart",
		configId = "C_Core",
		name = "The Start",
		desc = "The origin of your inner power.",
		icon = "☸",
		pos = Vector2.new(375, 500),
		unlocks = { "SharpBlade_1", "AscendantMight_1", "FourLeafClover_1" },
		maxLvl = 1,
		baseCost = 0,
		costType = "coins",
	},

	-- Damage Branch (Left)
	SharpBlade_1 = {
		id = "SharpBlade_1",
		configId = "C_Dmg_1",
		name = "Sharp Blade I",
		desc = "+10% Sword Damage",
		icon = "⚔️",
		pos = Vector2.new(240, 500),
		unlocks = { "SharpBlade_2" },
		maxLvl = 50,
		baseCost = 150,
		costType = "coins",
	},
	SharpBlade_2 = {
		id = "SharpBlade_2",
		configId = "C_Dmg_2",
		name = "Sharp Blade II",
		desc = "+25% Sword Damage",
		icon = "⚔️",
		pos = Vector2.new(120, 500),
		unlocks = { "SharpBlade_3" },
		maxLvl = 50,
		baseCost = 540,
		costType = "coins",
	},
	SharpBlade_3 = {
		id = "SharpBlade_3",
		configId = "C_Dmg_3",
		name = "Sharp Blade III",
		desc = "+50% Sword Damage",
		icon = "⚔️",
		pos = Vector2.new(40, 410),
		unlocks = {},
		maxLvl = 50,
		baseCost = 2800,
		costType = "coins",
	},

	-- Prestige / TP Branch (Up Center)
	AscendantMight_1 = {
		id = "AscendantMight_1",
		configId = "P_Tp_1",
		name = "Ascendant Might I",
		desc = "+1 Talent Point Boost",
		icon = "✨",
		pos = Vector2.new(375, 380),
		unlocks = { "AscendantMight_2" },
		maxLvl = 10,
		baseCost = 1,
		costType = "talentPoints",
	},
	AscendantMight_2 = {
		id = "AscendantMight_2",
		configId = "P_Tp_2",
		name = "Ascendant Might II",
		desc = "+2 Talent Point Boost",
		icon = "✨",
		pos = Vector2.new(340, 260),
		unlocks = { "AscendantMight_3" },
		maxLvl = 10,
		baseCost = 2,
		costType = "talentPoints",
	},
	AscendantMight_3 = {
		id = "AscendantMight_3",
		configId = "P_Tp_3",
		name = "Ascendant Might III",
		desc = "+3 Talent Point Boost",
		icon = "✨",
		pos = Vector2.new(310, 140),
		unlocks = { "AscendantMight_4" },
		maxLvl = 10,
		baseCost = 3,
		costType = "talentPoints",
	},
	AscendantMight_4 = {
		id = "AscendantMight_4",
		configId = "P_Tp_4",
		name = "Ascendant Might IV",
		desc = "+4 Talent Point Boost",
		icon = "✨",
		pos = Vector2.new(280, 40),
		unlocks = {},
		maxLvl = 10,
		baseCost = 4,
		costType = "talentPoints",
	},

	-- Luck Branch (Right)
	FourLeafClover_1 = {
		id = "FourLeafClover_1",
		configId = "L_Luck_1",
		name = "Four-Leaf Clover 1",
		desc = "+15% Luck Boost",
		icon = "🍀",
		pos = Vector2.new(510, 500),
		unlocks = { "FourLeafClover_2", "KeyFinder_1" },
		maxLvl = 40,
		baseCost = 150,
		costType = "coins",
	},
	FourLeafClover_2 = {
		id = "FourLeafClover_2",
		configId = "L_Luck_2",
		name = "Four-Leaf Clover 2",
		desc = "+35% Luck Boost",
		icon = "🍀",
		pos = Vector2.new(630, 500),
		unlocks = { "FourLeafClover_3" },
		maxLvl = 40,
		baseCost = 600,
		costType = "coins",
	},
	FourLeafClover_3 = {
		id = "FourLeafClover_3",
		configId = "L_Luck_3",
		name = "Four-Leaf Clover 3",
		desc = "+75% Luck Boost",
		icon = "🍀",
		pos = Vector2.new(710, 410),
		unlocks = {},
		maxLvl = 40,
		baseCost = 2400,
		costType = "coins",
	},

	-- Key Finder Branch (Up Right)
	KeyFinder_1 = {
		id = "KeyFinder_1",
		configId = "L_Luck_4",
		name = "Key Finder 1",
		desc = "+10% Key Drop Rate",
		icon = "🔑",
		pos = Vector2.new(580, 350),
		unlocks = { "KeyFinder_2" },
		maxLvl = 20,
		baseCost = 2000,
		costType = "coins",
	},
	KeyFinder_2 = {
		id = "KeyFinder_2",
		configId = "L_Luck_5",
		name = "Key Finder 2",
		desc = "+25% Key Drop Rate",
		icon = "🔑",
		pos = Vector2.new(650, 240),
		unlocks = { "KeyFinder_3" },
		maxLvl = 20,
		baseCost = 12000,
		costType = "coins",
	},
	KeyFinder_3 = {
		id = "KeyFinder_3",
		configId = "L_Luck_6",
		name = "Key Finder 3",
		desc = "+50% Key Drop Rate",
		icon = "🔑",
		pos = Vector2.new(720, 130),
		unlocks = {},
		maxLvl = 20,
		baseCost = 80000,
		costType = "coins",
	},

	-- Speed Branch (Up Left)
	SwiftHaste_1 = {
		id = "SwiftHaste_1",
		configId = "S_Speed_1",
		name = "Swift Haste 1",
		desc = "+10% Attack Speed",
		icon = "⚡",
		pos = Vector2.new(170, 350),
		unlocks = { "SwiftHaste_2" },
		maxLvl = 30,
		baseCost = 1000,
		costType = "coins",
	},
	SwiftHaste_2 = {
		id = "SwiftHaste_2",
		configId = "S_Speed_2",
		name = "Swift Haste 2",
		desc = "+25% Attack Speed",
		icon = "⚡",
		pos = Vector2.new(100, 240),
		unlocks = { "SwiftHaste_3" },
		maxLvl = 30,
		baseCost = 5000,
		costType = "coins",
	},
	SwiftHaste_3 = {
		id = "SwiftHaste_3",
		configId = "S_Speed_3",
		name = "Swift Haste 3",
		desc = "+50% Attack Speed",
		icon = "⚡",
		pos = Vector2.new(40, 130),
		unlocks = {},
		maxLvl = 30,
		baseCost = 35000,
		costType = "coins",
	},
}

local function drawConnection(parent: Frame, p1: Vector2, p2: Vector2, isUnlocked: boolean)
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

	-- Scrollable Map Container
	local scrollMap = Instance.new("ScrollingFrame")
	scrollMap.Name = "ScrollMap"
	scrollMap.Size = UDim2.new(1, -32, 1, -66)
	scrollMap.Position = UDim2.new(0, 16, 0, 54)
	scrollMap.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	scrollMap.BorderSizePixel = 0
	scrollMap.ClipsDescendants = true
	scrollMap.CanvasSize = UDim2.fromOffset(800, 600)
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
		local unlocked = (profile and profile.unlockedTalents) or { C_Core = 1 }

		-- 1. Draw connection lines between center points
		for _, nodeData in pairs(TREE_NODE_MAP) do
			local p1 = nodeData.pos
			for _, childId in ipairs(nodeData.unlocks) do
				local childData = TREE_NODE_MAP[childId]
				if childData then
					local p2 = childData.pos
					local pVal = unlocked[nodeData.configId] or unlocked[nodeData.id]
					local cVal = unlocked[childData.configId] or unlocked[childData.id]
					local isUnlocked = (typeof(pVal) == "number" and pVal > 0) or pVal == true
					drawConnection(mapCanvas, p1, p2, isUnlocked)
				end
			end
		end

		-- 2. Render node cards centered at nodeData.pos
		for _, nodeData in pairs(TREE_NODE_MAP) do
			local pos = nodeData.pos
			local configId = nodeData.configId
			local rawVal = unlocked[configId] or unlocked[nodeData.id]
			local currentLvl = if typeof(rawVal) == "number" then rawVal else (if rawVal == true then 1 else 0)
			local isMax = currentLvl >= nodeData.maxLvl
			local isUnlocked = currentLvl > 0

			local nodeCard = Instance.new("TextButton")
			nodeCard.Name = "Node_" .. nodeData.id
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
			titleLbl.Text = nodeData.icon .. " " .. nodeData.name
			titleLbl.ZIndex = 61
			titleLbl.Parent = nodeCard

			-- Calculate cost for next level
			local costMultiplier = math.pow(1.35, currentLvl)
			local cost = math.floor(nodeData.baseCost * costMultiplier)
			local costText = if isMax then "[MAX]" else (if nodeData.costType == "talentPoints" then (cost .. " TP") else (NumberFormat.Num(cost) .. " Coins"))

			local statLbl = Instance.new("TextLabel")
			statLbl.Size = UDim2.new(1, -6, 0, 18)
			statLbl.Position = UDim2.new(0, 3, 0, 24)
			statLbl.BackgroundTransparency = 1
			statLbl.Font = Enum.Font.Arcade
			statLbl.TextSize = 10
			statLbl.TextColor3 = isMax and Color3.fromRGB(180, 255, 200) or (isUnlocked and Color3.fromRGB(180, 230, 255) or Color3.fromRGB(160, 160, 175))
			statLbl.Text = string.format("Lv.%d/%d • %s", currentLvl, nodeData.maxLvl, costText)
			statLbl.ZIndex = 61
			statLbl.Parent = nodeCard

			nodeCard.MouseButton1Click:Connect(function()
				if not isMax then
					pcall(function()
						Net.UnlockTalentNode(configId)
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
