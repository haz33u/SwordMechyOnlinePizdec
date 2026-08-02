--!strict
--[[
	TALENT TREE UI — Fullscreen Hive-Style Honeycomb Skill Tree
	Bee Swarm / Anime Adventures inspired: transparent dark overlay,
	large hex grid, no zoom, pan by drag, clean top/bottom bars.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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

--- Build a hexagonal frame using six ImageLabels rotated around a center.
local function makeHexFrame(parent: Instance, size: number, color: Color3, transparency: number, z: number): Frame
	local container = Instance.new("Frame")
	container.Name = "HexFrame"
	container.Size = UDim2.fromOffset(size * 2, size * 2)
	container.BackgroundTransparency = 1
	container.ZIndex = z
	container.Parent = parent

	local segSize = UDim2.new(0, math.floor(size * 1.15), 0, math.floor(size * 2))
	for i = 0, 5 do
		local seg = Instance.new("Frame")
		seg.Name = "S" .. i
		seg.Size = segSize
		seg.BorderSizePixel = 0
		seg.BackgroundColor3 = color
		seg.BackgroundTransparency = transparency
		seg.Position = UDim2.new(0.5, 0, 0.5, 0)
		seg.AnchorPoint = Vector2.new(0.5, 0.5)
		seg.Rotation = i * 60
		seg.ZIndex = z
		seg.Parent = container
	end
	return container
end

function TalentTreeUI.Mount(parent: Instance, store: any)
	-- Fullscreen layer with semi-transparent dark backdrop
	local layer = Instance.new("Frame")
	layer.Name = "TalentTreeWindow"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
	layer.BackgroundTransparency = 0.15
	layer.Visible = false
	layer.ZIndex = 100
	layer.Parent = parent

	-- Top bar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.Position = UDim2.fromOffset(0, 0)
	header.BackgroundColor3 = Color3.fromRGB(10, 13, 22)
	header.BackgroundTransparency = 0.25
	header.BorderSizePixel = 0
	header.ZIndex = 110
	header.Parent = layer

	local headerLine = Instance.new("Frame")
	headerLine.Name = "Line"
	headerLine.Size = UDim2.new(1, 0, 0, 2)
	headerLine.Position = UDim2.fromOffset(0, 54)
	headerLine.BackgroundColor3 = Color3.fromRGB(0, 180, 220)
	headerLine.BackgroundTransparency = 0.4
	headerLine.BorderSizePixel = 0
	headerLine.ZIndex = 110
	headerLine.Parent = header

	local titleLab = Instance.new("TextLabel")
	titleLab.Name = "Title"
	titleLab.Size = UDim2.new(1, -160, 1, 0)
	titleLab.Position = UDim2.fromOffset(24, 0)
	titleLab.BackgroundTransparency = 1
	titleLab.Font = Enum.Font.GothamBlack
	titleLab.TextSize = 24
	titleLab.TextColor3 = Color3.fromRGB(0, 230, 255)
	titleLab.Text = "TALENT TREE"
	titleLab.TextXAlignment = Enum.TextXAlignment.Left
	titleLab.TextYAlignment = Enum.TextYAlignment.Center
	titleLab.ZIndex = 111
	titleLab.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromOffset(44, 44)
	closeBtn.Position = UDim2.new(1, -58, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 22
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "✕"
	closeBtn.ZIndex = 111
	closeBtn.Parent = header
	UIKit.Corner(closeBtn, 12)
	closeBtn.MouseButton1Click:Connect(function()
		layer.Visible = false
	end)

	-- Viewport fills the screen between header and bottom bar
	local viewport = Instance.new("Frame")
	viewport.Name = "Viewport"
	viewport.Size = UDim2.new(1, 0, 1, -116)
	viewport.Position = UDim2.fromOffset(0, 56)
	viewport.BackgroundTransparency = 1
	viewport.ClipsDescendants = true
	viewport.ZIndex = 105
	viewport.Parent = layer

	-- Canvas for panning
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromOffset(4000, 4000)
	canvas.Position = UDim2.new(0.5, -2000, 0.5, -2000)
	canvas.BackgroundTransparency = 1
	canvas.ZIndex = 106
	canvas.Parent = viewport

	local nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "Nodes"
	nodesFolder.Parent = canvas

	-- Bottom currency / stats bar
	local bottom = Instance.new("Frame")
	bottom.Name = "BottomBar"
	bottom.Size = UDim2.new(1, 0, 0, 60)
	bottom.Position = UDim2.new(0, 0, 1, -60)
	bottom.BackgroundColor3 = Color3.fromRGB(10, 13, 22)
	bottom.BackgroundTransparency = 0.25
	bottom.BorderSizePixel = 0
	bottom.ZIndex = 110
	bottom.Parent = layer

	local bottomLine = Instance.new("Frame")
	bottomLine.Name = "Line"
	bottomLine.Size = UDim2.new(1, 0, 0, 2)
	bottomLine.BackgroundColor3 = Color3.fromRGB(0, 180, 220)
	bottomLine.BackgroundTransparency = 0.4
	bottomLine.BorderSizePixel = 0
	bottomLine.ZIndex = 110
	bottomLine.Parent = bottom

	local statsLab = Instance.new("TextLabel")
	statsLab.Name = "Stats"
	statsLab.Size = UDim2.new(1, -32, 1, 0)
	statsLab.Position = UDim2.fromOffset(16, 0)
	statsLab.BackgroundTransparency = 1
	statsLab.Font = Enum.Font.GothamBold
	statsLab.TextSize = 16
	statsLab.TextColor3 = Color3.fromRGB(240, 200, 80)
	statsLab.Text = "Coins: 0  |  Talent Points: 0  |  Nodes: 0/0"
	statsLab.TextXAlignment = Enum.TextXAlignment.Center
	statsLab.TextYAlignment = Enum.TextYAlignment.Center
	statsLab.ZIndex = 111
	statsLab.Parent = bottom

	-- Inspector tooltip panel (floating near selected node)
	local inspector = Instance.new("Frame")
	inspector.Name = "Inspector"
	inspector.Size = UDim2.fromOffset(320, 110)
	inspector.Position = UDim2.new(0.5, -160, 1, -180)
	inspector.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
	inspector.BackgroundTransparency = 0.1
	inspector.BorderSizePixel = 0
	inspector.ZIndex = 120
	inspector.Visible = false
	inspector.Parent = layer
	UIKit.Corner(inspector, 14)
	UIKit.Stroke(inspector, Color3.fromRGB(50, 70, 110), 1.5, 0.3)

	local nodeTitle = Instance.new("TextLabel")
	nodeTitle.Name = "NodeTitle"
	nodeTitle.Size = UDim2.new(1, -24, 0, 24)
	nodeTitle.Position = UDim2.fromOffset(12, 10)
	nodeTitle.BackgroundTransparency = 1
	nodeTitle.Font = Enum.Font.GothamBold
	nodeTitle.TextSize = 16
	nodeTitle.TextColor3 = Color3.fromRGB(240, 200, 80)
	nodeTitle.Text = "Select a node"
	nodeTitle.TextXAlignment = Enum.TextXAlignment.Left
	nodeTitle.ZIndex = 121
	nodeTitle.Parent = inspector

	local nodeDesc = Instance.new("TextLabel")
	nodeDesc.Name = "NodeDesc"
	nodeDesc.Size = UDim2.new(1, -24, 0, 34)
	nodeDesc.Position = UDim2.fromOffset(12, 34)
	nodeDesc.BackgroundTransparency = 1
	nodeDesc.Font = Enum.Font.Gotham
	nodeDesc.TextSize = 12
	nodeDesc.TextColor3 = Color3.fromRGB(180, 190, 210)
	nodeDesc.Text = "Click any node to inspect and upgrade."
	nodeDesc.TextWrapped = true
	nodeDesc.TextXAlignment = Enum.TextXAlignment.Left
	nodeDesc.TextYAlignment = Enum.TextYAlignment.Top
	nodeDesc.ZIndex = 121
	nodeDesc.Parent = inspector

	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Name = "UpgradeBtn"
	upgradeBtn.Size = UDim2.new(1, -24, 0, 34)
	upgradeBtn.Position = UDim2.new(0, 12, 0, 70)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.TextSize = 14
	upgradeBtn.TextColor3 = Color3.new(1, 1, 1)
	upgradeBtn.Text = "Upgrade"
	upgradeBtn.ZIndex = 122
	upgradeBtn.Parent = inspector
	UIKit.Corner(upgradeBtn, 10)

	-- Pan state
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
			"Coins: %s  |  Talent Points: %s  |  Nodes: %d/%d",
			Format.Num(coins),
			Format.Num(talentPts),
			activeNodes,
			totalNodes
		)

		for _, child in nodesFolder:GetChildren() do
			child:Destroy()
		end

		local centerOrigin = Vector2.new(2000, 2000)
		local HEX_SIZE = 46

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
			local frostOk = not node.reqFrostTier or ((profile and profile.frostCaseTier or 0) >= node.reqFrostTier)
			local grimOk = not node.reqGrimTier or ((profile and profile.grimKillTier or 0) >= node.reqGrimTier)
			local locOk = not node.reqLocation or ((profile and profile.currentLocation or 1) >= node.reqLocation)
			local questsOk = samOk and frostOk and grimOk and locOk

			local pix = centerOrigin + hexToPixel(node.hexPos.X, node.hexPos.Y, HEX_SIZE)

			local nodeBtn = Instance.new("TextButton")
			nodeBtn.Name = "Hex_" .. id
			nodeBtn.Size = UDim2.fromOffset(HEX_SIZE * 2, HEX_SIZE * 2)
			nodeBtn.Position = UDim2.fromOffset(pix.X, pix.Y)
			nodeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
			nodeBtn.Text = ""
			nodeBtn.AutoButtonColor = false
			nodeBtn.BackgroundTransparency = 1
			nodeBtn.ZIndex = 115
			nodeBtn.Parent = nodesFolder

			local bgColor: Color3
			local strokeColor: Color3
			if isUnlocked then
				bgColor = Color3.fromRGB(0, 140, 170)
				strokeColor = Color3.fromRGB(0, 230, 255)
			elseif isAvailable and questsOk then
				bgColor = Color3.fromRGB(22, 34, 52)
				strokeColor = Color3.fromRGB(0, 200, 240)
			elseif isAvailable and not questsOk then
				bgColor = Color3.fromRGB(45, 28, 18)
				strokeColor = Color3.fromRGB(220, 120, 40)
			else
				bgColor = Color3.fromRGB(16, 20, 30)
				strokeColor = Color3.fromRGB(35, 42, 58)
			end

			local hexFill = makeHexFrame(nodeBtn, HEX_SIZE - 2, bgColor, 0.1, 114)
			hexFill.Position = UDim2.new(0.5, 0, 0.5, 0)
			hexFill.AnchorPoint = Vector2.new(0.5, 0.5)

			local hexStroke = makeHexFrame(nodeBtn, HEX_SIZE, strokeColor, 0.55, 116)
			hexStroke.Position = UDim2.new(0.5, 0, 0.5, 0)
			hexStroke.AnchorPoint = Vector2.new(0.5, 0.5)

			local iconLab = Instance.new("TextLabel")
			iconLab.Size = UDim2.fromScale(1, 0.55)
			iconLab.Position = UDim2.fromScale(0, 0.08)
			iconLab.BackgroundTransparency = 1
			iconLab.Font = Enum.Font.GothamBold
			iconLab.TextSize = if node.nodeType == "keystone" then 24 else 18
			iconLab.TextColor3 = if isUnlocked then Color3.fromRGB(255, 230, 100) else Color3.fromRGB(200, 210, 230)
			iconLab.Text = node.icon or "⚔"
			iconLab.ZIndex = 117
			iconLab.Parent = nodeBtn

			local lvlLab = Instance.new("TextLabel")
			lvlLab.Size = UDim2.fromScale(1, 0.3)
			lvlLab.Position = UDim2.fromScale(0, 0.58)
			lvlLab.BackgroundTransparency = 1
			lvlLab.Font = Enum.Font.GothamBold
			lvlLab.TextSize = 11
			lvlLab.TextColor3 = if isUnlocked then Color3.fromRGB(220, 245, 255) else Color3.fromRGB(140, 155, 175)
			lvlLab.Text = if node.maxLevel == 1 then (if isUnlocked then "MAX" else "1/1") else string.format("Lv.%d/%d", curLvl, node.maxLevel)
			lvlLab.ZIndex = 117
			lvlLab.Parent = nodeBtn

			nodeBtn.MouseButton1Click:Connect(function()
				selectedNodeId = id
				local cost = TalentTreeConfig.GetUpgradeCost(node, curLvl)

				inspector.Visible = true
				nodeTitle.Text = string.format("%s  [Lv.%d/%d]", node.name, curLvl, node.maxLevel)
				nodeDesc.Text = string.format("%s  ·  Next: %s %s", node.desc, Format.Num(cost), if node.costType == "talentPoints" then "TP" else "Coins")

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
					nodeDesc.Text = "Unlock the parent node first."
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
