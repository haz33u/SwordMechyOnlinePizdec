--!strict
--[[
	TALENT TREE UI — Hexagonal Honeycomb Skill Lattice (Chemical Table Layout)
	
	Renders a tightly-packed 2D hex grid where hexes touch edge-to-edge
	in an axial honeycomb pattern (q, r).
	
	Supports multi-level node upgrading (Lv 1 to 100+), Pan & Zoom canvas,
	and quest-gating requirement indicators.
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

--- Converts axial hex coordinates (q, r) to 2D pixel offset
local function hexToPixel(q: number, r: number, size: number): Vector2
	local x = size * 1.732 * (q + r * 0.5)
	local y = size * 1.5 * r
	return Vector2.new(x, y)
end

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
	card.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
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
	titleLab.TextSize = 18
	titleLab.TextColor3 = Color3.fromRGB(0, 230, 255)
	titleLab.Text = "TALENT TREE  ·  HONEYCOMB NETWORK"
	titleLab.TextXAlignment = Enum.TextXAlignment.Left
	titleLab.ZIndex = 53
	titleLab.Parent = header

	local statsLab = Instance.new("TextLabel")
	statsLab.Name = "Stats"
	statsLab.Size = UDim2.new(0.5, -60, 1, 0)
	statsLab.Position = UDim2.new(0.45, 0, 0, 0)
	statsLab.BackgroundTransparency = 1
	statsLab.Font = Enum.Font.GothamBold
	statsLab.TextSize = 13
	statsLab.TextColor3 = Color3.fromRGB(240, 200, 80)
	statsLab.Text = "Coins: 0  |  Talent Points: 0  |  Nodes: 0/47"
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

	-- Viewport (ClipDescendants for pan & zoom canvas)
	local viewport = Instance.new("Frame")
	viewport.Name = "Viewport"
	viewport.Size = UDim2.new(1, -24, 1, -140)
	viewport.Position = UDim2.fromOffset(12, 60)
	viewport.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
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
	gridBg.Image = "rbxassetid://6071575915"
	gridBg.ImageColor3 = Color3.fromRGB(30, 40, 60)
	gridBg.ImageTransparency = 0.88
	gridBg.ScaleType = Enum.ScaleType.Tile
	gridBg.TileSize = UDim2.fromOffset(64, 64)
	gridBg.ZIndex = 53
	gridBg.Parent = viewport

	-- Draggable Honeycomb Canvas Host
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromOffset(3000, 3000)
	canvas.Position = UDim2.new(0.5, -1500, 0.5, -1500)
	canvas.BackgroundTransparency = 1
	canvas.ZIndex = 54
	canvas.Parent = viewport

	local canvasScale = Instance.new("UIScale")
	canvasScale.Scale = 1.0
	canvasScale.Parent = canvas

	local nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "Nodes"
	nodesFolder.Parent = canvas

	-- Tooltip & Upgrade Inspector (Bottom Bar)
	local inspector = Instance.new("Frame")
	inspector.Name = "Inspector"
	inspector.Size = UDim2.new(1, -24, 0, 68)
	inspector.Position = UDim2.new(0, 12, 1, -76)
	inspector.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	inspector.ZIndex = 60
	inspector.Parent = card
	UIKit.Corner(inspector, 12)
	UIKit.Stroke(inspector, Color3.fromRGB(50, 70, 110), 1.2, 0.4)

	local nodeTitle = Instance.new("TextLabel")
	nodeTitle.Name = "NodeTitle"
	nodeTitle.Size = UDim2.new(0.4, 0, 0, 24)
	nodeTitle.Position = UDim2.fromOffset(16, 10)
	nodeTitle.BackgroundTransparency = 1
	nodeTitle.Font = Enum.Font.GothamBold
	nodeTitle.TextSize = 16
	nodeTitle.TextColor3 = Color3.fromRGB(240, 200, 80)
	nodeTitle.Text = "Select a hex node"
	nodeTitle.TextXAlignment = Enum.TextXAlignment.Left
	nodeTitle.ZIndex = 61
	nodeTitle.Parent = inspector

	local nodeDesc = Instance.new("TextLabel")
	nodeDesc.Name = "NodeDesc"
	nodeDesc.Size = UDim2.new(0.55, 0, 0, 24)
	nodeDesc.Position = UDim2.fromOffset(16, 34)
	nodeDesc.BackgroundTransparency = 1
	nodeDesc.Font = Enum.Font.Gotham
	nodeDesc.TextSize = 12
	nodeDesc.TextColor3 = Color3.fromRGB(180, 190, 210)
	nodeDesc.Text = "Click any node on the honeycomb table to inspect and upgrade."
	nodeDesc.TextXAlignment = Enum.TextXAlignment.Left
	nodeDesc.ZIndex = 61
	nodeDesc.Parent = inspector

	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Name = "UpgradeBtn"
	upgradeBtn.Size = UDim2.fromOffset(170, 44)
	upgradeBtn.Position = UDim2.new(1, -182, 0.5, -22)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.TextSize = 13
	upgradeBtn.TextColor3 = Color3.new(1, 1, 1)
	upgradeBtn.Text = "Upgrade"
	upgradeBtn.Visible = false
	upgradeBtn.ZIndex = 62
	upgradeBtn.Parent = inspector
	UIKit.Corner(upgradeBtn, 10)

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

	viewport.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)

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
		canvas.Position = UDim2.new(0.5, -1500, 0.5, -1500)
		canvasScale.Scale = 1.0
	end)

	-- Refresh Honeycomb Lattice
	local function refreshLattice()
		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local unlockedMap = (profile and profile.unlockedTalents) or { C_Core = 1 }
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0
		local talentPts = (profile and profile.talentPoints) or 0

		local totalNodes = 0
		local activeNodes = 0
		for id, node in TalentTreeConfig.Nodes do
			totalNodes += 1
			local val = unlockedMap[id]
			local lvl = if type(val) == "number" then val else (if val == true then 1 else 0)
			if lvl > 0 then
				activeNodes += 1
			end
		end

		statsLab.Text = string.format(
			"Coins: %s  |  Talent Points: %s  |  Nodes Active: %d/%d",
			Format.Num(coins),
			Format.Num(talentPts),
			activeNodes,
			totalNodes
		)

		for _, child in nodesFolder:GetChildren() do
			child:Destroy()
		end

		local centerOrigin = Vector2.new(1500, 1500)
		local HEX_SIZE = 38 -- Hex Radius for tight edge-to-edge packing

		for id, node in TalentTreeConfig.Nodes do
			local val = unlockedMap[id]
			local curLvl = if type(val) == "number" then val else (if val == true then 1 else 0)
			local isUnlocked = curLvl > 0

			local isAvailable = false
			if not isUnlocked then
				if #node.parents == 0 then
					isAvailable = true
				else
					for _, pId in ipairs(node.parents) do
						local pVal = unlockedMap[pId]
						local pLvl = if type(pVal) == "number" then pVal else (if pVal == true then 1 else 0)
						if pLvl > 0 then
							isAvailable = true
							break
						end
					end
				end
			end

			local samOk = not node.reqSamTier or ((profile and profile.samClickTier or 0) >= node.reqSamTier)
			local frostOk = not node.reqFrostTier or ((profile and profile.frostTier or 0) >= node.reqFrostTier)
			local grimOk = not node.reqGrimTier or ((profile and profile.grimTier or 0) >= node.reqGrimTier)
			local locOk = not node.reqLocation or ((profile and profile.currentLocation or 1) >= node.reqLocation)
			local questsOk = samOk and frostOk and grimOk and locOk

			local pix = centerOrigin + hexToPixel(node.hexPos.X, node.hexPos.Y, HEX_SIZE)

			-- Hexagon Container
			local hexBtn = Instance.new("TextButton")
			hexBtn.Name = "Hex_" .. id
			hexBtn.Size = UDim2.fromOffset(HEX_SIZE * 1.65, HEX_SIZE * 1.65)
			hexBtn.Position = UDim2.fromOffset(pix.X, pix.Y)
			hexBtn.AnchorPoint = Vector2.new(0.5, 0.5)
			hexBtn.Font = Enum.Font.GothamBold
			hexBtn.TextSize = 18
			hexBtn.Text = ""
			hexBtn.ZIndex = 55
			hexBtn.Parent = nodesFolder
			UIKit.Corner(hexBtn, 14) -- Hexagonal-like rounded chip

			local strokeColor = Color3.fromRGB(40, 50, 70)
			if isUnlocked then
				hexBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 180)
				strokeColor = Color3.fromRGB(0, 230, 255)
			elseif isAvailable and questsOk then
				hexBtn.BackgroundColor3 = Color3.fromRGB(24, 34, 52)
				strokeColor = Color3.fromRGB(0, 200, 240)
			elseif isAvailable and not questsOk then
				hexBtn.BackgroundColor3 = Color3.fromRGB(34, 24, 20)
				strokeColor = Color3.fromRGB(220, 110, 30)
			else
				hexBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
				strokeColor = Color3.fromRGB(35, 42, 58)
			end
			UIKit.Stroke(hexBtn, strokeColor, if node.nodeType == "keystone" then 2.5 else 1.8, 0.15)

			local iconLab = Instance.new("TextLabel")
			iconLab.Size = UDim2.fromScale(1, 0.55)
			iconLab.Position = UDim2.fromScale(0, 0.05)
			iconLab.BackgroundTransparency = 1
			iconLab.Font = Enum.Font.GothamBold
			iconLab.TextSize = if node.nodeType == "keystone" then 22 else 18
			iconLab.TextColor3 = if isUnlocked then Color3.fromRGB(255, 230, 100) else Color3.fromRGB(200, 210, 230)
			iconLab.Text = node.icon or "⚔"
			iconLab.ZIndex = 56
			iconLab.Parent = hexBtn

			local lvlLab = Instance.new("TextLabel")
			lvlLab.Size = UDim2.fromScale(1, 0.35)
			lvlLab.Position = UDim2.fromScale(0, 0.6)
			lvlLab.BackgroundTransparency = 1
			lvlLab.Font = Enum.Font.GothamBold
			lvlLab.TextSize = 10
			lvlLab.TextColor3 = if isUnlocked then Color3.fromRGB(220, 245, 255) else Color3.fromRGB(140, 155, 175)
			lvlLab.Text = if node.maxLevel == 1 then (if isUnlocked then "MAX" else "1/1") else string.format("Lv.%d/%d", curLvl, node.maxLevel)
			lvlLab.ZIndex = 56
			lvlLab.Parent = hexBtn

			hexBtn.MouseButton1Click:Connect(function()
				selectedNodeId = id
				local cost = TalentTreeConfig.GetUpgradeCost(node, curLvl)

				nodeTitle.Text = string.format("%s  [Lv.%d/%d]", node.name, curLvl, node.maxLevel)
				nodeDesc.Text = string.format("%s  ·  Next Upgrade: %s %s", node.desc, Format.Num(cost), if node.costType == "talentPoints" then "Talent Points" else "Coins")

				if curLvl >= node.maxLevel then
					upgradeBtn.Visible = true
					upgradeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
					upgradeBtn.Text = "MAX LEVEL ✓"
				elseif isAvailable or isUnlocked then
					upgradeBtn.Visible = true
					local canAfford = if node.costType == "talentPoints" then talentPts >= cost else coins >= cost

					if not questsOk then
						upgradeBtn.BackgroundColor3 = Color3.fromRGB(180, 90, 20)
						if not samOk then
							upgradeBtn.Text = "🔒 Click Step " .. tostring(node.reqSamTier)
						elseif not frostOk then
							upgradeBtn.Text = "🔒 Case Step " .. tostring(node.reqFrostTier)
						elseif not grimOk then
							upgradeBtn.Text = "🔒 Power Step " .. tostring(node.reqGrimTier)
						else
							upgradeBtn.Text = "🔒 Loc " .. tostring(node.reqLocation)
						end
					elseif canAfford then
						upgradeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
						upgradeBtn.Text = string.format("UPGRADE (%s)", Format.Num(cost))
					else
						upgradeBtn.BackgroundColor3 = Color3.fromRGB(65, 70, 85)
						upgradeBtn.Text = string.format("NEED %s", Format.Num(cost))
					end
				else
					upgradeBtn.Visible = false
				end
			end)
		end
	end

	upgradeBtn.MouseButton1Click:Connect(function()
		if selectedNodeId then
			Net.UnlockTalentNode(selectedNodeId)
			task.delay(0.3, refreshLattice)
		end
	end)

	local api = {}

	function api.Show()
		layer.Visible = true
		refreshLattice()
	end

	function api.Hide()
		layer.Visible = false
	end

	function api.Toggle()
		layer.Visible = not layer.Visible
		if layer.Visible then
			refreshLattice()
		end
	end

	function api.Refresh()
		if layer.Visible then
			refreshLattice()
		end
	end

	return api
end

return TalentTreeUI
