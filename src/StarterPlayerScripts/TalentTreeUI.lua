--!strict
--[[
	TALENT TREE UI — RNG-Style Hexagonal Skill Network (Pan & Zoom Canvas)
	
	Renders an interactive 2D node graph with connecting glowing lines,
	hexagonal node chips, tooltips, and pan/zoom canvas controls.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TalentTreeConfig = require(Shared.Config.TalentTreeConfig)

local TalentTreeUI = {}

function TalentTreeUI.Mount(parent: Instance, store: any)
	local layer = Instance.new("Frame")
	layer.Name = "TalentTreeWindow"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.Visible = false
	layer.ZIndex = 50
	layer.Parent = parent

	-- Main Modal Backdrop Container
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(0.88, 0.88)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	card.BorderSizePixel = 0
	card.ZIndex = 51
	card.Parent = layer
	UIKit.Corner(card, 16)
	UIKit.Stroke(card, Color3.fromRGB(0, 200, 240), 1.8, 0.3)

	-- Header Bar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
	header.BorderSizePixel = 0
	header.ZIndex = 52
	header.Parent = card
	UIKit.Corner(header, 16)

	local titleLab = Instance.new("TextLabel")
	titleLab.Name = "Title"
	titleLab.Size = UDim2.new(0.4, 0, 1, 0)
	titleLab.Position = UDim2.fromOffset(20, 0)
	titleLab.BackgroundTransparency = 1
	titleLab.Font = Enum.Font.GothamBold
	titleLab.TextSize = 20
	titleLab.TextColor3 = Color3.fromRGB(0, 230, 255)
	titleLab.Text = "TALENT TREE  ·  SKILL NETWORK"
	titleLab.TextXAlignment = Enum.TextXAlignment.Left
	titleLab.ZIndex = 53
	titleLab.Parent = header

	local statsLab = Instance.new("TextLabel")
	statsLab.Name = "Stats"
	statsLab.Size = UDim2.new(0.5, -60, 1, 0)
	statsLab.Position = UDim2.new(0.45, 0, 0, 0)
	statsLab.BackgroundTransparency = 1
	statsLab.Font = Enum.Font.GothamBold
	statsLab.TextSize = 14
	statsLab.TextColor3 = Color3.fromRGB(240, 200, 80)
	statsLab.Text = "Coins: 0  |  Talent Points: 0  |  Nodes: 0/0"
	statsLab.TextXAlignment = Enum.TextXAlignment.Right
	statsLab.ZIndex = 53
	statsLab.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "✕"
	closeBtn.ZIndex = 54
	closeBtn.Parent = header
	UIKit.Corner(closeBtn, 18)
	closeBtn.MouseButton1Click:Connect(function()
		layer.Visible = false
	end)

	-- Viewport View (ClipDescendants for pan/zoom canvas)
	local viewport = Instance.new("Frame")
	viewport.Name = "Viewport"
	viewport.Size = UDim2.new(1, -24, 1, -140)
	viewport.Position = UDim2.fromOffset(12, 60)
	viewport.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	viewport.ClipsDescendants = true
	viewport.BorderSizePixel = 0
	viewport.ZIndex = 52
	viewport.Parent = card
	UIKit.Corner(viewport, 12)

	-- Grid Background Pattern
	local gridBg = Instance.new("ImageLabel")
	gridBg.Name = "GridBg"
	gridBg.Size = UDim2.fromScale(1, 1)
	gridBg.BackgroundTransparency = 1
	gridBg.Image = "rbxassetid://6071575915" -- Soft hex/grid texture
	gridBg.ImageColor3 = Color3.fromRGB(30, 40, 60)
	gridBg.ImageTransparency = 0.85
	gridBg.ScaleType = Enum.ScaleType.Tile
	gridBg.TileSize = UDim2.fromOffset(64, 64)
	gridBg.ZIndex = 53
	gridBg.Parent = viewport

	-- Draggable Canvas Host
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromOffset(4000, 4000)
	canvas.Position = UDim2.new(0.5, -2000, 0.5, -2000) -- Center origin C_Core
	canvas.BackgroundTransparency = 1
	canvas.ZIndex = 54
	canvas.Parent = viewport

	local canvasScale = Instance.new("UIScale")
	canvasScale.Scale = 1.0
	canvasScale.Parent = canvas

	-- Container for Connection Lines
	local linesFolder = Instance.new("Folder")
	linesFolder.Name = "Lines"
	linesFolder.Parent = canvas

	-- Container for Node Buttons
	local nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "Nodes"
	nodesFolder.Parent = canvas

	-- Tooltip Card (Bottom Bar)
	local tooltipCard = Instance.new("Frame")
	tooltipCard.Name = "TooltipCard"
	tooltipCard.Size = UDim2.new(1, -24, 0, 68)
	tooltipCard.Position = UDim2.new(0, 12, 1, -76)
	tooltipCard.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
	tooltipCard.ZIndex = 60
	tooltipCard.Parent = card
	UIKit.Corner(tooltipCard, 12)
	UIKit.Stroke(tooltipCard, Color3.fromRGB(60, 80, 120), 1.2, 0.4)

	local nodeTitle = Instance.new("TextLabel")
	nodeTitle.Name = "NodeTitle"
	nodeTitle.Size = UDim2.new(0.4, 0, 0, 24)
	nodeTitle.Position = UDim2.fromOffset(16, 10)
	nodeTitle.BackgroundTransparency = 1
	nodeTitle.Font = Enum.Font.GothamBold
	nodeTitle.TextSize = 16
	nodeTitle.TextColor3 = Color3.fromRGB(240, 200, 80)
	nodeTitle.Text = "Select a node"
	nodeTitle.TextXAlignment = Enum.TextXAlignment.Left
	nodeTitle.ZIndex = 61
	nodeTitle.Parent = tooltipCard

	local nodeDesc = Instance.new("TextLabel")
	nodeDesc.Name = "NodeDesc"
	nodeDesc.Size = UDim2.new(0.55, 0, 0, 24)
	nodeDesc.Position = UDim2.fromOffset(16, 34)
	nodeDesc.BackgroundTransparency = 1
	nodeDesc.Font = Enum.Font.Gotham
	nodeDesc.TextSize = 13
	nodeDesc.TextColor3 = Color3.fromRGB(180, 190, 210)
	nodeDesc.Text = "Click any node on the tree to inspect effects and unlock."
	nodeDesc.TextXAlignment = Enum.TextXAlignment.Left
	nodeDesc.ZIndex = 61
	nodeDesc.Parent = tooltipCard

	local unlockBtn = Instance.new("TextButton")
	unlockBtn.Name = "UnlockBtn"
	unlockBtn.Size = UDim2.fromOffset(160, 44)
	unlockBtn.Position = UDim2.new(1, -172, 0.5, -22)
	unlockBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
	unlockBtn.Font = Enum.Font.GothamBold
	unlockBtn.TextSize = 14
	unlockBtn.TextColor3 = Color3.new(1, 1, 1)
	unlockBtn.Text = "Unlock Node"
	unlockBtn.Visible = false
	unlockBtn.ZIndex = 62
	unlockBtn.Parent = tooltipCard
	UIKit.Corner(unlockBtn, 10)

	-- Pan / Drag Controls State
	local isDragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()
	local selectedNodeId: string? = nil

	viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			dragStart = input.Position
			startPos = canvas.Position
		end
	end)

	viewport.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			canvas.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	local function endDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end
	viewport.InputEnded:Connect(endDrag)

	-- Mouse Wheel Zoom
	viewport.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local delta = input.Position.Z
			local curScale = canvasScale.Scale
			local nextScale = math.clamp(curScale + (delta * 0.1), 0.6, 1.8)
			canvasScale.Scale = nextScale
		end
	end)

	-- Center Viewport Button
	local centerBtn = Instance.new("TextButton")
	centerBtn.Name = "CenterBtn"
	centerBtn.Size = UDim2.fromOffset(36, 36)
	centerBtn.Position = UDim2.new(1, -48, 1, -48)
	centerBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
	centerBtn.Font = Enum.Font.GothamBold
	centerBtn.TextSize = 18
	centerBtn.TextColor3 = Color3.fromRGB(0, 230, 255)
	centerBtn.Text = "🎯"
	centerBtn.ZIndex = 65
	centerBtn.Parent = viewport
	UIKit.Corner(centerBtn, 18)
	centerBtn.MouseButton1Click:Connect(function()
		canvas.Position = UDim2.new(0.5, -2000, 0.5, -2000)
		canvasScale.Scale = 1.0
	end)

	-- Render Connecting Lines Between Nodes
	local function renderLines(unlockedMap: { [string]: boolean })
		for _, child in linesFolder:GetChildren() do
			child:Destroy()
		end

		local centerOrigin = Vector2.new(2000, 2000)

		for id, node in TalentTreeConfig.Nodes do
			local p1 = centerOrigin + node.gridPos
			for _, parentId in ipairs(node.parents) do
				local parentNode = TalentTreeConfig.Nodes[parentId]
				if parentNode then
					local p2 = centerOrigin + parentNode.gridPos

					local dist = (p1 - p2).Magnitude
					local angle = math.atan2(p1.Y - p2.Y, p1.X - p2.X)
					local mid = (p1 + p2) * 0.5

					local line = Instance.new("Frame")
					line.Name = "Line_" .. parentId .. "_" .. id
					line.Size = UDim2.fromOffset(dist, 4)
					line.Position = UDim2.fromOffset(mid.X, mid.Y)
					line.AnchorPoint = Vector2.new(0.5, 0.5)
					line.Rotation = math.deg(angle)
					line.BorderSizePixel = 0
					line.ZIndex = 54
					line.Parent = linesFolder

					local parentUnlocked = unlockedMap[parentId] == true
					local selfUnlocked = unlockedMap[id] == true

					if selfUnlocked and parentUnlocked then
						line.BackgroundColor3 = Color3.fromRGB(240, 190, 40) -- Unlocked path = Gold
					elseif parentUnlocked then
						line.BackgroundColor3 = Color3.fromRGB(0, 200, 255) -- Available path = Cyan
					else
						line.BackgroundColor3 = Color3.fromRGB(40, 45, 60) -- Locked path = Dark Grey
					end
					UIKit.Corner(line, 2)
				end
			end
		end
	end

	-- Refresh Node Buttons and State
	local function refreshNodes()
		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local unlockedMap = (profile and profile.unlockedTalents) or { C_Core = true }
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0
		local talentPts = (profile and profile.talentPoints) or 0

		renderLines(unlockedMap)

		local totalNodes = 0
		local unlockedCount = 0
		for _ in TalentTreeConfig.Nodes do
			totalNodes += 1
		end
		for id, val in unlockedMap do
			if val == true and TalentTreeConfig.Nodes[id] then
				unlockedCount += 1
			end
		end

		statsLab.Text = string.format(
			"Coins: %s  |  Talent Points: %s  |  Nodes: %d/%d",
			Format.Num(coins),
			Format.Num(talentPts),
			unlockedCount,
			totalNodes
		)

		for _, child in nodesFolder:GetChildren() do
			child:Destroy()
		end

		local centerOrigin = Vector2.new(2000, 2000)

		for id, node in TalentTreeConfig.Nodes do
			local isUnlocked = unlockedMap[id] == true

			local isAvailable = false
			if not isUnlocked then
				if #node.parents == 0 then
					isAvailable = true
				else
					for _, pId in ipairs(node.parents) do
						if unlockedMap[pId] == true then
							isAvailable = true
							break
						end
					end
				end
			end

			local sizePx = 46
			if node.nodeType == "major" then
				sizePx = 58
			elseif node.nodeType == "keystone" then
				sizePx = 72
			end

			local btn = Instance.new("TextButton")
			btn.Name = "Node_" .. id
			btn.Size = UDim2.fromOffset(sizePx, sizePx)
			btn.Position = UDim2.fromOffset(centerOrigin.X + node.gridPos.X, centerOrigin.Y + node.gridPos.Y)
			btn.AnchorPoint = Vector2.new(0.5, 0.5)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = if sizePx > 50 then 22 else 16
			btn.Text = node.icon or "⚔"
			btn.ZIndex = 55
			btn.Parent = nodesFolder

			UIKit.Corner(btn, if node.nodeType == "keystone" then 36 else 12)

			if isUnlocked then
				btn.BackgroundColor3 = Color3.fromRGB(0, 170, 110)
				btn.TextColor3 = Color3.new(1, 1, 1)
				UIKit.Stroke(btn, Color3.fromRGB(240, 200, 80), 2.2, 0.1)
			elseif isAvailable then
				btn.BackgroundColor3 = Color3.fromRGB(30, 45, 70)
				btn.TextColor3 = Color3.fromRGB(0, 230, 255)
				UIKit.Stroke(btn, Color3.fromRGB(0, 200, 255), 2.0, 0.2)
			else
				btn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
				btn.TextColor3 = Color3.fromRGB(80, 90, 110)
				UIKit.Stroke(btn, Color3.fromRGB(40, 45, 60), 1.0, 0.5)
			end

			btn.MouseButton1Click:Connect(function()
				selectedNodeId = id
				nodeTitle.Text = node.name .. (if isUnlocked then "  [UNLOCKED ✓]" else "")
				nodeDesc.Text = string.format("%s  ·  Cost: %s %s", node.desc, Format.Num(node.cost), if node.costType == "talentPoints" then "Talent Points" else "Coins")

				local samOk = not node.reqSamTier or ((profile and profile.samClickTier or 0) >= node.reqSamTier)
				local frostOk = not node.reqFrostTier or ((profile and profile.frostTier or 0) >= node.reqFrostTier)
				local grimOk = not node.reqGrimTier or ((profile and profile.grimTier or 0) >= node.reqGrimTier)
				local locOk = not node.reqLocation or ((profile and profile.currentLocation or 1) >= node.reqLocation)
				local questsOk = samOk and frostOk and grimOk and locOk

				if isUnlocked then
					unlockBtn.Visible = false
				elseif isAvailable then
					unlockBtn.Visible = true
					local canAfford = if node.costType == "talentPoints" then talentPts >= node.cost else coins >= node.cost
					if not questsOk then
						unlockBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 30)
						if not samOk then
							unlockBtn.Text = "🔒 Need Click Step " .. tostring(node.reqSamTier)
						elseif not frostOk then
							unlockBtn.Text = "🔒 Need Case Step " .. tostring(node.reqFrostTier)
						elseif not grimOk then
							unlockBtn.Text = "🔒 Need Power Step " .. tostring(node.reqGrimTier)
						else
							unlockBtn.Text = "🔒 Need Loc " .. tostring(node.reqLocation)
						end
					elseif canAfford then
						unlockBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
						unlockBtn.Text = "Unlock (" .. Format.Num(node.cost) .. ")"
					else
						unlockBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
						unlockBtn.Text = "Need " .. Format.Num(node.cost)
					end
				else
					unlockBtn.Visible = false
				end
			end)
		end
	end

	unlockBtn.MouseButton1Click:Connect(function()
		if selectedNodeId then
			Net.UnlockTalentNode(selectedNodeId)
			task.delay(0.3, refreshNodes)
		end
	end)

	local api = {}

	function api.Show()
		layer.Visible = true
		refreshNodes()
	end

	function api.Hide()
		layer.Visible = false
	end

	function api.Toggle()
		layer.Visible = not layer.Visible
		if layer.Visible then
			refreshNodes()
		end
	end

	function api.Refresh()
		if layer.Visible then
			refreshNodes()
		end
	end

	return api
end

return TalentTreeUI
