--!strict
--[[
	UpgradeTreeUI.lua
	Exact 1-to-1 visual reconstruction of the Noob Incremental Skill & Upgrade Tree UI.
	Renders hexagonal node cards at the exact UDim2 coordinates extracted from the .rbxlx place file.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIUpgradeTree = require(Shared.Modules.UIUpgradeTree)
local UITreeLayoutData = require(Shared.Config.UITreeLayoutData)
local NumbersLibs = require(Shared.Librairies.NumbersLibs)
local Icons = require(Shared.Modules.Icons)
local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)

local UpgradeTreeUI = {}
local currentGui: ScreenGui? = nil
local frame: Frame? = nil
local mapCanvas: Frame? = nil
local hoverFrame: Frame? = nil
local storeRef: any = nil

-- Default Gem Icon used in Noob Incremental
local GEM_ICON_ID = "rbxassetid://74012557494815"

-- Gradient themes matching original Noob Incremental node types
local THEME_GRADIENTS = {
	Prism = {
		c1 = Color3.fromRGB(0, 195, 255),
		c2 = Color3.fromRGB(0, 110, 220),
		stroke = Color3.fromRGB(120, 220, 255),
	},
	Oof = {
		c1 = Color3.fromRGB(190, 60, 255),
		c2 = Color3.fromRGB(110, 30, 180),
		stroke = Color3.fromRGB(220, 140, 255),
	},
	Rune = {
		c1 = Color3.fromRGB(240, 60, 70),
		c2 = Color3.fromRGB(140, 20, 30),
		stroke = Color3.fromRGB(255, 130, 140),
	},
	Cash = {
		c1 = Color3.fromRGB(50, 205, 90),
		c2 = Color3.fromRGB(20, 120, 50),
		stroke = Color3.fromRGB(130, 255, 160),
	},
	Fire = {
		c1 = Color3.fromRGB(255, 140, 40),
		c2 = Color3.fromRGB(180, 60, 10),
		stroke = Color3.fromRGB(255, 190, 100),
	},
	Tier = {
		c1 = Color3.fromRGB(230, 190, 40),
		c2 = Color3.fromRGB(160, 120, 10),
		stroke = Color3.fromRGB(255, 220, 120),
	},
	Default = {
		c1 = Color3.fromRGB(0, 180, 240),
		c2 = Color3.fromRGB(0, 90, 180),
		stroke = Color3.fromRGB(100, 210, 255),
	},
}

local function getTheme(nodeData: any)
	local gt = nodeData and nodeData.gradientType or "Prism"
	for key, theme in pairs(THEME_GRADIENTS) do
		if string.find(gt, key, 1, true) then
			return theme
		end
	end
	return THEME_GRADIENTS.Default
end

local function drawLine(parent: Frame, p1: Vector2, p2: Vector2, isUnlocked: boolean)
	local dist = (p2 - p1).Magnitude
	local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)

	local line = Instance.new("Frame")
	line.Name = "ConnectionLine"
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.fromOffset(p1.X, p1.Y)
	line.Size = UDim2.fromOffset(dist, isUnlocked and 3 or 2)
	line.Rotation = math.deg(angle)
	line.BackgroundColor3 = isUnlocked and Color3.fromRGB(80, 210, 255) or Color3.fromRGB(50, 55, 68)
	line.BackgroundTransparency = isUnlocked and 0 or 0.4
	line.BorderSizePixel = 0
	line.ZIndex = 5
	line.Parent = parent
end

function UpgradeTreeUI.Mount(parentGui: ScreenGui, store: any)
	currentGui = parentGui
	storeRef = store

	-- Outer Fullscreen Container
	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "UITreeFrame"
	modalFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
	modalFrame.Position = UDim2.fromScale(0.5, 0.5)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	modalFrame.BorderSizePixel = 0
	modalFrame.ClipsDescendants = true
	modalFrame.Visible = false
	modalFrame.ZIndex = 60
	modalFrame.Parent = parentGui

	UIKit.Corner(modalFrame, 12)
	UIKit.Stroke(modalFrame, Color3.fromRGB(60, 140, 220), 2, 0.2)

	-- Header Title
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -60, 0, 40)
	header.Position = UDim2.new(0, 20, 0, 10)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 20
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "NOOB INCREMENTAL — SKILL & UPGRADE TREE"
	header.ZIndex = 65
	header.Parent = modalFrame

	-- Close Button (Red X square)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Exit"
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.Position = UDim2.new(1, -48, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(210, 40, 50)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "X"
	closeBtn.ZIndex = 70
	closeBtn.Parent = modalFrame
	UIKit.Corner(closeBtn, 8)

	closeBtn.MouseButton1Click:Connect(function()
		modalFrame.Visible = false
	end)

	-- Hover Tooltip Window
	local tooltip = Instance.new("Frame")
	tooltip.Name = "Hovering"
	tooltip.Size = UDim2.fromOffset(230, 120)
	tooltip.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
	tooltip.BorderSizePixel = 0
	tooltip.Visible = false
	tooltip.ZIndex = 100
	tooltip.Parent = modalFrame
	UIKit.Corner(tooltip, 10)
	UIKit.Stroke(tooltip, Color3.fromRGB(90, 180, 255), 1.5, 0.15)

	local ttTitle = Instance.new("TextLabel")
	ttTitle.Name = "Title"
	ttTitle.Size = UDim2.new(1, -16, 0, 22)
	ttTitle.Position = UDim2.new(0, 8, 0, 6)
	ttTitle.BackgroundTransparency = 1
	ttTitle.Font = Enum.Font.GothamBold
	ttTitle.TextSize = 13
	ttTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
	ttTitle.TextXAlignment = Enum.TextXAlignment.Left
	ttTitle.Text = ""
	ttTitle.ZIndex = 101
	ttTitle.Parent = tooltip

	local ttDesc = Instance.new("TextLabel")
	ttDesc.Name = "Desc"
	ttDesc.Size = UDim2.new(1, -16, 0, 32)
	ttDesc.Position = UDim2.new(0, 8, 0, 28)
	ttDesc.BackgroundTransparency = 1
	ttDesc.Font = Enum.Font.Gotham
	ttDesc.TextSize = 11
	ttDesc.TextColor3 = Color3.fromRGB(200, 210, 225)
	ttDesc.TextWrapped = true
	ttDesc.TextXAlignment = Enum.TextXAlignment.Left
	ttDesc.Text = ""
	ttDesc.ZIndex = 101
	ttDesc.Parent = tooltip

	local ttBoost = Instance.new("TextLabel")
	ttBoost.Name = "Boost"
	ttBoost.Size = UDim2.new(1, -16, 0, 20)
	ttBoost.Position = UDim2.new(0, 8, 0, 62)
	ttBoost.BackgroundTransparency = 1
	ttBoost.Font = Enum.Font.GothamBold
	ttBoost.TextSize = 11
	ttBoost.TextColor3 = Color3.fromRGB(110, 240, 160)
	ttBoost.TextXAlignment = Enum.TextXAlignment.Left
	ttBoost.Text = ""
	ttBoost.ZIndex = 101
	ttBoost.Parent = tooltip

	local ttCost = Instance.new("TextLabel")
	ttCost.Name = "Cost"
	ttCost.Size = UDim2.new(1, -16, 0, 20)
	ttCost.Position = UDim2.new(0, 8, 0, 84)
	ttCost.BackgroundTransparency = 1
	ttCost.Font = Enum.Font.Gotham
	ttCost.TextSize = 11
	ttCost.TextColor3 = Color3.fromRGB(220, 190, 100)
	ttCost.TextXAlignment = Enum.TextXAlignment.Left
	ttCost.Text = ""
	ttCost.ZIndex = 101
	ttCost.Parent = tooltip
	hoverFrame = tooltip

	-- Scrollable Map Canvas (MapFrame)
	local scrollMap = Instance.new("ScrollingFrame")
	scrollMap.Name = "MapFrame"
	scrollMap.Size = UDim2.new(1, -24, 1, -64)
	scrollMap.Position = UDim2.new(0, 12, 0, 54)
	scrollMap.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
	scrollMap.BorderSizePixel = 0
	scrollMap.ClipsDescendants = true
	scrollMap.CanvasSize = UDim2.fromOffset(2000, 1600)
	scrollMap.ScrollBarThickness = 6
	scrollMap.ScrollBarImageColor3 = Color3.fromRGB(50, 90, 140)
	scrollMap.ZIndex = 61
	scrollMap.Parent = modalFrame
	UIKit.Corner(scrollMap, 8)

	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.ZIndex = 61
	canvas.Parent = scrollMap
	mapCanvas = canvas

	local function getLevel(nodeId: string): number
		local profile = storeRef and storeRef:PeekProfile()
		local unlocked = profile and profile.unlockedTalents or {}
		local raw = unlocked[nodeId]
		if typeof(raw) == "number" then return raw end
		if raw == true then return 1 end
		return 0
	end

	local function renderTree()
		if not mapCanvas or not storeRef then return end
		mapCanvas:ClearAllChildren()

		local nodeDefs = UIUpgradeTree.Nodes or {}
		local layoutData = UITreeLayoutData.Nodes or {}

		local canvasW = scrollMap.CanvasSize.X.Offset
		local canvasH = scrollMap.CanvasSize.Y.Offset

		-- Map node positions in absolute canvas pixels
		local pixelPositions: { [string]: Vector2 } = {}
		for nodeId, layout in pairs(layoutData) do
			local p = layout.position
			local px = p.X.Scale * canvasW + p.X.Offset
			local py = p.Y.Scale * canvasH + p.Y.Offset
			pixelPositions[nodeId] = Vector2.new(px, py)
		end

		-- 1. Draw connection lines between parent/child card centers
		for nodeId, nodeData in pairs(nodeDefs) do
			local p1 = pixelPositions[nodeId]
			if p1 then
				for _, childId in ipairs(nodeData.unlocks or {}) do
					local p2 = pixelPositions[childId]
					if p2 then
						local pLvl = getLevel(nodeId)
						local isUnlocked = pLvl > 0
						drawLine(mapCanvas, p1, p2, isUnlocked)
					end
				end
			end
		end

		-- 2. Render exact Hexagon Cards for each node
		for nodeId, nodeData in pairs(nodeDefs) do
			local p = pixelPositions[nodeId] or Vector2.new(canvasW * 0.5, canvasH * 0.5)
			local currentLvl = getLevel(nodeId)
			local maxLvl = nodeData.maxLevel or 1
			local isMax = currentLvl >= maxLvl

			local isUnlocked = UIUpgradeTree.IsNodeUnlocked(nodeId, function(id) return getLevel(id) end)
			local theme = getTheme(nodeData)

			-- Hexagon Card Button
			local hexCard = Instance.new("ImageButton")
			hexCard.Name = nodeId
			hexCard.Size = UDim2.fromOffset(72, 72)
			hexCard.AnchorPoint = Vector2.new(0.5, 0.5)
			hexCard.Position = UDim2.fromOffset(p.X, p.Y)
			hexCard.BackgroundColor3 = isMax and theme.c1 or (isUnlocked and theme.c2 or Color3.fromRGB(24, 26, 32))
			hexCard.BorderSizePixel = 0
			hexCard.AutoButtonColor = true
			hexCard.ZIndex = 10
			hexCard.Parent = mapCanvas

			-- Hexagon rounded corner shape
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.32, 0)
			corner.Parent = hexCard

			-- Visual Gradient
			local grad = Instance.new("UIGradient")
			grad.Name = "GRADIENT"
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, isMax and Color3.fromRGB(255, 240, 150) or theme.c1),
				ColorSequenceKeypoint.new(1, isMax and theme.c1 or theme.c2),
			})
			grad.Rotation = 45
			grad.Parent = hexCard

			-- Border Stroke (Gold if maxed, Cyan/Theme if unlocked, Dark gray if locked)
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2.5
			stroke.Color = isMax and Color3.fromRGB(255, 220, 80) or (isUnlocked and theme.stroke or Color3.fromRGB(50, 55, 70))
			stroke.Parent = hexCard

			-- Centered Gem Icon
			local iconImg = Instance.new("ImageLabel")
			iconImg.Name = "Icon"
			iconImg.Size = UDim2.fromScale(0.65, 0.65)
			iconImg.Position = UDim2.fromScale(0.5, 0.45)
			iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
			iconImg.BackgroundTransparency = 1
			iconImg.Image = (nodeData.icon and nodeData.icon ~= "") and nodeData.icon or GEM_ICON_ID
			iconImg.ZIndex = 11
			iconImg.Parent = hexCard

			-- Top Level Display ("x/y")
			local titleLbl = Instance.new("TextLabel")
			titleLbl.Name = "Title"
			titleLbl.Size = UDim2.new(1, 0, 0, 16)
			titleLbl.Position = UDim2.new(0, 0, 0, 4)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.TextSize = 11
			titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			titleLbl.Text = string.format("%d/%d", currentLvl, maxLvl)
			titleLbl.ZIndex = 12
			titleLbl.Parent = hexCard

			-- Bottom Price Tag ("999M", "100K", "FREE")
			local costNum = 0
			if nodeData.getCost then
				pcall(function() costNum = nodeData.getCost(currentLvl) end)
			end
			local costStr = isMax and "MAX" or (costNum <= 0 and "FREE" or NumbersLibs.Short(costNum))

			local costLbl = Instance.new("TextLabel")
			costLbl.Name = "Cost"
			costLbl.Size = UDim2.new(1, 4, 0, 16)
			costLbl.Position = UDim2.new(0, -2, 1, -18)
			costLbl.BackgroundTransparency = 1
			costLbl.Font = Enum.Font.GothamBold
			costLbl.TextSize = 10
			costLbl.TextColor3 = isMax and Color3.fromRGB(150, 255, 170) or Color3.fromRGB(255, 230, 130)
			costLbl.Text = costStr
			costLbl.ZIndex = 12
			costLbl.Parent = hexCard

			-- Locked Overlay (Semi-transparent dark overlay with lock icon)
			if not isUnlocked then
				local lock = Instance.new("Frame")
				lock.Name = "Locked"
				lock.Size = UDim2.fromScale(1, 1)
				lock.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				lock.BackgroundTransparency = 0.5
				lock.ZIndex = 15
				lock.Parent = hexCard
				UIKit.Corner(lock, 12)

				local lockTxt = Instance.new("TextLabel")
				lockTxt.Size = UDim2.fromScale(1, 1)
				lockTxt.BackgroundTransparency = 1
				lockTxt.Font = Enum.Font.GothamBold
				lockTxt.TextSize = 18
				lockTxt.TextColor3 = Color3.fromRGB(160, 165, 180)
				lockTxt.Text = "🔒"
				lockTxt.ZIndex = 16
				lockTxt.Parent = lock
			end

			-- Mouse Hover Tooltip
			hexCard.MouseEnter:Connect(function()
				if hoverFrame then
					ttTitle.Text = nodeData.title or nodeId
					ttDesc.Text = nodeData.desc or ""

					local boostText = ""
					if nodeData.boost and nodeData.formatBoost then
						local ok1, curB = pcall(nodeData.boost, currentLvl)
						local ok2, nxtB = pcall(nodeData.boost, currentLvl + 1)
						if ok1 and ok2 then
							local ok3, s1 = pcall(nodeData.formatBoost, curB)
							local ok4, s2 = pcall(nodeData.formatBoost, nxtB)
							if ok3 and ok4 then
								boostText = isMax and tostring(s1) or (tostring(s1) .. " → " .. tostring(s2))
							end
						end
					end
					ttBoost.Text = boostText
					ttCost.Text = isMax and "MAXED" or ("Cost: " .. (costNum <= 0 and "FREE" or NumbersLibs.Short(costNum)))

					hoverFrame.Position = UDim2.fromOffset(hexCard.Position.X.Offset + 45, hexCard.Position.Y.Offset - 20)
					hoverFrame.Visible = true
				end
			end)

			hexCard.MouseLeave:Connect(function()
				if hoverFrame then
					hoverFrame.Visible = false
				end
			end)

			-- Purchase on Click
			hexCard.MouseButton1Click:Connect(function()
				if isMax or not isUnlocked then return end
				pcall(function()
					Net.UnlockTalentNode(nodeId)
				end)
				task.delay(0.25, renderTree)
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
