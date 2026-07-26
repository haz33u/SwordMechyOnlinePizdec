--!strict
--[[
	UpgradeTreeUI.lua
	Complete Skill & Upgrade Tree UI — reads node config directly from
	the original UIUpgradeTree module, renders all nodes from code,
	draws connection lines, shows hover tooltips with boost values,
	and sends purchases via Net.UnlockTalentNode.
]]

local Players       = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared           = ReplicatedStorage:WaitForChild("Shared")
local UIUpgradeTree    = require(Shared.Modules.UIUpgradeTree)
local NumbersLibs      = require(Shared.Librairies.NumbersLibs)
local T                = require(script.Parent.Theme)
local UIKit            = require(script.Parent.UIKit)
local Net              = require(script.Parent.Net)

local UpgradeTreeUI = {}
local currentGui: ScreenGui? = nil
local frame: Frame? = nil
local storeRef: any = nil

-- ═══════════════════════════════════════════════════════════
-- AUTOMATIC TREE LAYOUT ENGINE
-- Generates 2D positions for every node using BFS from roots.
-- ═══════════════════════════════════════════════════════════

local NODE_W = 120  -- card width
local NODE_H = 64   -- card height
local GAP_X  = 40   -- horizontal gap between nodes
local GAP_Y  = 90   -- vertical gap between rows

local function buildPositionMap(): { [string]: Vector2 }
	local nodes = UIUpgradeTree.Nodes
	if not nodes then return {} end

	-- Find root nodes (nodes with no parents / requirements)
	local roots: { string } = {}
	for nodeId, _ in pairs(nodes) do
		local reqs = UIUpgradeTree.GetRequirements(nodeId)
		if #reqs == 0 then
			table.insert(roots, nodeId)
		end
	end

	-- BFS to assign (column, row) to each node
	local positions: { [string]: Vector2 } = {}
	local rowSlot: { [number]: number } = {} -- tracks how many nodes placed in each row

	local queue: { { id: string, depth: number, parentX: number? } } = {}

	-- Start with roots at row 0
	for _, rootId in ipairs(roots) do
		table.insert(queue, { id = rootId, depth = 0, parentX = nil })
	end

	local visited: { [string]: boolean } = {}

	while #queue > 0 do
		local item = table.remove(queue, 1)
		local nodeId = item.id
		local depth = item.depth

		if visited[nodeId] then continue end
		visited[nodeId] = true

		-- Assign column slot in this row
		if not rowSlot[depth] then
			rowSlot[depth] = 0
		end
		local col = rowSlot[depth]
		rowSlot[depth] = col + 1

		-- x,y position: center the tree later
		local x = col * (NODE_W + GAP_X)
		local y = depth * (NODE_H + GAP_Y)
		positions[nodeId] = Vector2.new(x, y)

		-- Enqueue children
		local nodeData = nodes[nodeId]
		if nodeData and nodeData.unlocks then
			for _, childId in ipairs(nodeData.unlocks) do
				if not visited[childId] then
					table.insert(queue, { id = childId, depth = depth + 1, parentX = x })
				end
			end
		end
	end

	-- Center the whole tree: find bounds then offset
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	for _, pos in pairs(positions) do
		minX = math.min(minX, pos.X)
		maxX = math.max(maxX, pos.X + NODE_W)
		minY = math.min(minY, pos.Y)
		maxY = math.max(maxY, pos.Y + NODE_H)
	end
	local offsetX = -minX + 40  -- 40px padding
	local offsetY = -minY + 40

	local centered: { [string]: Vector2 } = {}
	for nodeId, pos in pairs(positions) do
		centered[nodeId] = Vector2.new(pos.X + offsetX, pos.Y + offsetY)
	end

	return centered, maxX - minX + 80, maxY - minY + 80
end

-- ═══════════════════════════════════════════════════════════
-- GRADIENT COLORS (from original Com_UITree gradients)
-- ═══════════════════════════════════════════════════════════

local GRADIENT_COLORS = {
	Oof     = { bg = Color3.fromRGB(50, 35, 70),  border = Color3.fromRGB(130, 80, 200) },
	Prism   = { bg = Color3.fromRGB(25, 45, 70),  border = Color3.fromRGB(60, 140, 220) },
	Rune    = { bg = Color3.fromRGB(50, 25, 30),  border = Color3.fromRGB(200, 80, 80)  },
	Cash    = { bg = Color3.fromRGB(45, 55, 25),  border = Color3.fromRGB(140, 200, 60) },
	Fire    = { bg = Color3.fromRGB(60, 30, 15),  border = Color3.fromRGB(220, 120, 40) },
	Tier    = { bg = Color3.fromRGB(40, 40, 55),  border = Color3.fromRGB(120, 120, 180)},
	Rebirth = { bg = Color3.fromRGB(55, 20, 55),  border = Color3.fromRGB(200, 60, 200) },
	Coin    = { bg = Color3.fromRGB(55, 50, 20),  border = Color3.fromRGB(220, 200, 60) },
	R3      = { bg = Color3.fromRGB(25, 50, 45),  border = Color3.fromRGB(60, 200, 170) },
	Default = { bg = Color3.fromRGB(28, 30, 38),  border = Color3.fromRGB(60, 65, 80)   },
}

local function getGradient(nodeData)
	local gt = nodeData.gradientType or "Default"
	-- Try exact match first, then prefix match
	if GRADIENT_COLORS[gt] then return GRADIENT_COLORS[gt] end
	for key, val in pairs(GRADIENT_COLORS) do
		if string.find(gt, key, 1, true) then return val end
	end
	return GRADIENT_COLORS.Default
end

-- ═══════════════════════════════════════════════════════════
-- DRAWING HELPERS
-- ═══════════════════════════════════════════════════════════

local function drawLine(parent: Frame, p1: Vector2, p2: Vector2, unlocked: boolean)
	local dist = (p2 - p1).Magnitude
	local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.fromOffset(p1.X, p1.Y)
	line.Size = UDim2.fromOffset(dist, unlocked and 3 or 2)
	line.Rotation = math.deg(angle)
	line.BackgroundColor3 = unlocked and Color3.fromRGB(80, 200, 255) or Color3.fromRGB(50, 55, 65)
	line.BackgroundTransparency = unlocked and 0 or 0.4
	line.BorderSizePixel = 0
	line.ZIndex = 2
	line.Parent = parent
end

-- ═══════════════════════════════════════════════════════════
-- MOUNT
-- ═══════════════════════════════════════════════════════════

function UpgradeTreeUI.Mount(parentGui: ScreenGui, store: any)
	currentGui = parentGui
	storeRef = store

	-- Build position map
	local posMap, canvasW, canvasH = buildPositionMap()

	-- Modal frame
	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "UpgradeTreeFrame"
	modalFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
	modalFrame.Position = UDim2.fromScale(0.5, 0.5)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
	modalFrame.BorderSizePixel = 0
	modalFrame.ClipsDescendants = true
	modalFrame.Visible = false
	modalFrame.ZIndex = 60
	modalFrame.Parent = parentGui
	UIKit.Corner(modalFrame, T.R.md)
	UIKit.Stroke(modalFrame, Color3.fromRGB(70, 130, 220), 2, 0.3)

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -60, 0, 40)
	header.Position = UDim2.new(0, 20, 0, 10)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 20
	header.TextColor3 = Color3.fromRGB(240, 245, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "SKILL & UPGRADE TREE"
	header.ZIndex = 65
	header.Parent = modalFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.Position = UDim2.new(1, -48, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "✕"
	closeBtn.ZIndex = 70
	closeBtn.Parent = modalFrame
	UIKit.Corner(closeBtn, 8)

	closeBtn.MouseButton1Click:Connect(function()
		modalFrame.Visible = false
	end)

	-- Hover tooltip
	local tooltip = Instance.new("Frame")
	tooltip.Name = "Tooltip"
	tooltip.Size = UDim2.fromOffset(240, 130)
	tooltip.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	tooltip.BorderSizePixel = 0
	tooltip.Visible = false
	tooltip.ZIndex = 100
	tooltip.Parent = modalFrame
	UIKit.Corner(tooltip, 8)
	UIKit.Stroke(tooltip, Color3.fromRGB(90, 160, 255), 1.5, 0.15)

	local ttTitle = Instance.new("TextLabel")
	ttTitle.Name = "Title"
	ttTitle.Size = UDim2.new(1, -12, 0, 20)
	ttTitle.Position = UDim2.new(0, 6, 0, 6)
	ttTitle.BackgroundTransparency = 1
	ttTitle.Font = Enum.Font.GothamBold
	ttTitle.TextSize = 14
	ttTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
	ttTitle.TextXAlignment = Enum.TextXAlignment.Left
	ttTitle.Text = ""
	ttTitle.ZIndex = 101
	ttTitle.Parent = tooltip

	local ttDesc = Instance.new("TextLabel")
	ttDesc.Name = "Desc"
	ttDesc.Size = UDim2.new(1, -12, 0, 30)
	ttDesc.Position = UDim2.new(0, 6, 0, 28)
	ttDesc.BackgroundTransparency = 1
	ttDesc.Font = Enum.Font.Gotham
	ttDesc.TextSize = 12
	ttDesc.TextColor3 = Color3.fromRGB(190, 200, 215)
	ttDesc.TextWrapped = true
	ttDesc.TextXAlignment = Enum.TextXAlignment.Left
	ttDesc.Text = ""
	ttDesc.ZIndex = 101
	ttDesc.Parent = tooltip

	local ttBoost = Instance.new("TextLabel")
	ttBoost.Name = "Boost"
	ttBoost.Size = UDim2.new(1, -12, 0, 20)
	ttBoost.Position = UDim2.new(0, 6, 0, 62)
	ttBoost.BackgroundTransparency = 1
	ttBoost.Font = Enum.Font.GothamBold
	ttBoost.TextSize = 12
	ttBoost.TextColor3 = Color3.fromRGB(100, 230, 160)
	ttBoost.TextXAlignment = Enum.TextXAlignment.Left
	ttBoost.Text = ""
	ttBoost.ZIndex = 101
	ttBoost.Parent = tooltip

	local ttCost = Instance.new("TextLabel")
	ttCost.Name = "Cost"
	ttCost.Size = UDim2.new(1, -12, 0, 20)
	ttCost.Position = UDim2.new(0, 6, 0, 84)
	ttCost.BackgroundTransparency = 1
	ttCost.Font = Enum.Font.Gotham
	ttCost.TextSize = 12
	ttCost.TextColor3 = Color3.fromRGB(200, 180, 100)
	ttCost.TextXAlignment = Enum.TextXAlignment.Left
	ttCost.Text = ""
	ttCost.ZIndex = 101
	ttCost.Parent = tooltip

	local ttLevel = Instance.new("TextLabel")
	ttLevel.Name = "Level"
	ttLevel.Size = UDim2.new(1, -12, 0, 20)
	ttLevel.Position = UDim2.new(0, 6, 0, 104)
	ttLevel.BackgroundTransparency = 1
	ttLevel.Font = Enum.Font.Gotham
	ttLevel.TextSize = 11
	ttLevel.TextColor3 = Color3.fromRGB(160, 165, 180)
	ttLevel.TextXAlignment = Enum.TextXAlignment.Left
	ttLevel.Text = ""
	ttLevel.ZIndex = 101
	ttLevel.Parent = tooltip

	-- Scrollable map
	local scrollMap = Instance.new("ScrollingFrame")
	scrollMap.Name = "ScrollMap"
	scrollMap.Size = UDim2.new(1, -24, 1, -62)
	scrollMap.Position = UDim2.new(0, 12, 0, 54)
	scrollMap.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
	scrollMap.BorderSizePixel = 0
	scrollMap.ClipsDescendants = true
	scrollMap.CanvasSize = UDim2.fromOffset(math.max(canvasW or 800, 800), math.max(canvasH or 600, 600))
	scrollMap.ScrollBarThickness = 6
	scrollMap.ScrollBarImageColor3 = Color3.fromRGB(60, 80, 120)
	scrollMap.ZIndex = 61
	scrollMap.Parent = modalFrame
	UIKit.Corner(scrollMap, 6)

	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.ZIndex = 61
	canvas.Parent = scrollMap

	-- ═══════════════════════════════════════════════════════
	-- RENDER TREE
	-- ═══════════════════════════════════════════════════════

	local function getLevel(nodeId: string): number
		local profile = storeRef and storeRef:PeekProfile()
		local unlocked = profile and profile.unlockedTalents or {}
		local raw = unlocked[nodeId]
		if typeof(raw) == "number" then return raw end
		if raw == true then return 1 end
		return 0
	end

	local function isNodeUnlocked(nodeId: string): boolean
		local getLvl = function(id) return getLevel(id) end
		return UIUpgradeTree.IsNodeUnlocked(nodeId, getLvl)
	end

	local function renderTree()
		canvas:ClearAllChildren()

		local nodes = UIUpgradeTree.Nodes
		if not nodes then return end

		-- 1. Draw connection lines (below cards, ZIndex = 2)
		for nodeId, nodeData in pairs(nodes) do
			local p1 = posMap[nodeId]
			if not p1 then continue end
			local center1 = Vector2.new(p1.X + NODE_W / 2, p1.Y + NODE_H / 2)

			for _, childId in ipairs(nodeData.unlocks or {}) do
				local p2 = posMap[childId]
				if not p2 then continue end
				local center2 = Vector2.new(p2.X + NODE_W / 2, p2.Y + NODE_H / 2)
				local parentLvl = getLevel(nodeId)
				drawLine(canvas, center1, center2, parentLvl > 0)
			end
		end

		-- 2. Render node cards
		for nodeId, nodeData in pairs(nodes) do
			local pos = posMap[nodeId]
			if not pos then continue end

			local currentLvl = getLevel(nodeId)
			local maxLvl = nodeData.maxLevel or 1
			local isMax = currentLvl >= maxLvl
			local unlocked = isNodeUnlocked(nodeId)
			local gradient = getGradient(nodeData)

			-- Card background
			local bgColor = if isMax then Color3.fromRGB(
				math.min(255, math.floor(gradient.border.R * 255 * 0.5 + 50)),
				math.min(255, math.floor(gradient.border.G * 255 * 0.5 + 50)),
				math.min(255, math.floor(gradient.border.B * 255 * 0.5 + 50))
			) else (if unlocked then gradient.bg else Color3.fromRGB(22, 24, 30))

			local borderColor = if isMax then gradient.border
				else (if unlocked then gradient.border else Color3.fromRGB(45, 48, 58))

			local card = Instance.new("TextButton")
			card.Name = nodeId
			card.Size = UDim2.fromOffset(NODE_W, NODE_H)
			card.Position = UDim2.fromOffset(pos.X, pos.Y)
			card.BackgroundColor3 = bgColor
			card.BorderSizePixel = 0
			card.AutoButtonColor = true
			card.Text = ""
			card.ZIndex = 10
			card.Parent = canvas
			UIKit.Corner(card, 8)
			UIKit.Stroke(card, borderColor, 1.5, 0.2)

			-- Icon
			if nodeData.icon and nodeData.icon ~= "" then
				local icon = Instance.new("ImageLabel")
				icon.Name = "Icon"
				icon.Size = UDim2.fromOffset(22, 22)
				icon.Position = UDim2.new(0, 6, 0, 6)
				icon.BackgroundTransparency = 1
				icon.Image = nodeData.icon
				icon.ZIndex = 11
				icon.Parent = card
			end

			-- Title
			local titleLbl = Instance.new("TextLabel")
			titleLbl.Name = "Title"
			titleLbl.Size = UDim2.new(1, -32, 0, 18)
			titleLbl.Position = UDim2.new(0, 30, 0, 4)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.TextSize = 10
			titleLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Text = nodeData.title or nodeId
			titleLbl.ZIndex = 11
			titleLbl.Parent = card

			-- Level display
			local lvlLbl = Instance.new("TextLabel")
			lvlLbl.Name = "Level"
			lvlLbl.Size = UDim2.new(1, -8, 0, 14)
			lvlLbl.Position = UDim2.new(0, 4, 0, 24)
			lvlLbl.BackgroundTransparency = 1
			lvlLbl.Font = Enum.Font.GothamBold
			lvlLbl.TextSize = 11
			lvlLbl.TextColor3 = isMax and Color3.fromRGB(160, 255, 180) or (unlocked and Color3.fromRGB(180, 220, 255) or Color3.fromRGB(100, 105, 120))
			lvlLbl.TextXAlignment = Enum.TextXAlignment.Left
			lvlLbl.Text = string.format("%d/%d", currentLvl, maxLvl)
			lvlLbl.ZIndex = 11
			lvlLbl.Parent = card

			-- MAXED badge
			if isMax then
				local maxBadge = Instance.new("TextLabel")
				maxBadge.Name = "MAXED"
				maxBadge.Size = UDim2.fromOffset(36, 14)
				maxBadge.Position = UDim2.new(1, -40, 0, 24)
				maxBadge.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
				maxBadge.Font = Enum.Font.GothamBold
				maxBadge.TextSize = 9
				maxBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
				maxBadge.Text = "MAX"
				maxBadge.ZIndex = 12
				maxBadge.Parent = card
				UIKit.Corner(maxBadge, 4)
			end

			-- Cost label (use original getCost + NumbersLibs.Short)
			if not isMax and unlocked then
				local costNum = 0
				if nodeData.getCost then
					local ok, val = pcall(nodeData.getCost, currentLvl)
					if ok then costNum = val end
				end
				local costStr = costNum <= 0 and "FREE" or NumbersLibs.Short(costNum)

				local costLbl = Instance.new("TextLabel")
				costLbl.Name = "Cost"
				costLbl.Size = UDim2.new(1, -8, 0, 14)
				costLbl.Position = UDim2.new(0, 4, 0, 44)
				costLbl.BackgroundTransparency = 1
				costLbl.Font = Enum.Font.Gotham
				costLbl.TextSize = 10
				costLbl.TextColor3 = Color3.fromRGB(220, 200, 100)
				costLbl.TextXAlignment = Enum.TextXAlignment.Left
				costLbl.Text = "Cost: " .. tostring(costStr)
				costLbl.ZIndex = 11
				costLbl.Parent = card
			end

			-- Locked overlay
			if not unlocked then
				local lock = Instance.new("Frame")
				lock.Name = "Locked"
				lock.Size = UDim2.fromScale(1, 1)
				lock.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				lock.BackgroundTransparency = 0.6
				lock.ZIndex = 15
				lock.Parent = card
				UIKit.Corner(lock, 8)

				local lockIcon = Instance.new("TextLabel")
				lockIcon.Size = UDim2.fromScale(1, 1)
				lockIcon.BackgroundTransparency = 1
				lockIcon.Font = Enum.Font.GothamBold
				lockIcon.TextSize = 20
				lockIcon.TextColor3 = Color3.fromRGB(120, 120, 140)
				lockIcon.Text = "🔒"
				lockIcon.ZIndex = 16
				lockIcon.Parent = lock
			end

			-- Hover tooltip connection
			card.MouseEnter:Connect(function()
				if not tooltip then return end
				ttTitle.Text = nodeData.title or nodeId
				ttDesc.Text = nodeData.desc or ""

				-- Boost display (before → after) using original functions
				local boostText = ""
				if nodeData.boost and nodeData.formatBoost then
					local ok1, curBoost = pcall(nodeData.boost, currentLvl)
					local ok2, nextBoost = pcall(nodeData.boost, currentLvl + 1)
					if ok1 and ok2 then
						local ok3, curStr = pcall(nodeData.formatBoost, curBoost)
						local ok4, nextStr = pcall(nodeData.formatBoost, nextBoost)
						if ok3 and ok4 then
							if isMax then
								boostText = tostring(curStr)
							else
								boostText = tostring(curStr) .. " → " .. tostring(nextStr)
							end
						end
					end
				end
				ttBoost.Text = boostText

				-- Cost
				local costNum = 0
				if nodeData.getCost then
					pcall(function() costNum = nodeData.getCost(currentLvl) end)
				end
				ttCost.Text = isMax and "MAXED" or ("Cost: " .. (costNum <= 0 and "FREE" or tostring(NumbersLibs.Short(costNum))))
				ttLevel.Text = string.format("Level %d / %d", currentLvl, maxLvl)

				-- Position tooltip near card
				tooltip.Position = UDim2.fromOffset(
					math.min(pos.X + NODE_W + 10, (canvasW or 800) - 250),
					pos.Y
				)
				tooltip.Visible = true
			end)

			card.MouseLeave:Connect(function()
				tooltip.Visible = false
			end)

			-- Purchase on click
			card.MouseButton1Click:Connect(function()
				if isMax then return end
				if not unlocked then return end
				pcall(function()
					Net.UnlockTalentNode(nodeId)
				end)
				task.delay(0.3, renderTree)
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
