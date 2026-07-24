--!strict
--[[
	TALENT TREE UI — Modern Category-Branch Skill Network
	
	Renders a structured talent tree with category tabs, progress indicators,
	branch cards, quest gating badges, and cost unlock buttons.
]]

local Players = game:GetService("Players")
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
	card.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
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
	titleLab.Size = UDim2.new(0.35, 0, 1, 0)
	titleLab.Position = UDim2.fromOffset(20, 0)
	titleLab.BackgroundTransparency = 1
	titleLab.Font = Enum.Font.GothamBold
	titleLab.TextSize = 18
	titleLab.TextColor3 = Color3.fromRGB(0, 230, 255)
	titleLab.Text = "TALENT TREE  ·  SKILL NETWORK"
	titleLab.TextXAlignment = Enum.TextXAlignment.Left
	titleLab.ZIndex = 53
	titleLab.Parent = header

	local statsLab = Instance.new("TextLabel")
	statsLab.Name = "Stats"
	statsLab.Size = UDim2.new(0.55, -60, 1, 0)
	statsLab.Position = UDim2.new(0.38, 0, 0, 0)
	statsLab.BackgroundTransparency = 1
	statsLab.Font = Enum.Font.GothamBold
	statsLab.TextSize = 13
	statsLab.TextColor3 = Color3.fromRGB(240, 200, 80)
	statsLab.Text = "Coins: 0  |  Talent Points: 0  |  Total: 0/114"
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

	-- Branch Category Tabs Bar
	local tabsRow = Instance.new("Frame")
	tabsRow.Name = "TabsRow"
	tabsRow.Size = UDim2.new(1, -24, 0, 44)
	tabsRow.Position = UDim2.fromOffset(12, 60)
	tabsRow.BackgroundTransparency = 1
	tabsRow.ZIndex = 52
	tabsRow.Parent = card

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabList.Padding = UDim.new(0, 8)
	tabList.Parent = tabsRow

	local CATEGORIES = {
		{ id = "combat", name = "⚔ COMBAT", color = Color3.fromRGB(220, 70, 50) },
		{ id = "luck", name = "🍀 LUCK & RNG", color = Color3.fromRGB(40, 190, 110) },
		{ id = "speed", name = "⚡ SPEED", color = Color3.fromRGB(240, 180, 40) },
		{ id = "utility", name = "💰 UTILITY", color = Color3.fromRGB(160, 80, 220) },
		{ id = "prestige", name = "🔱 PRESTIGE", color = Color3.fromRGB(0, 200, 255) },
	}

	local activeCategory = "combat"
	local tabBtns: { [string]: TextButton } = {}

	-- Branch Progress Subheader
	local subheader = Instance.new("Frame")
	subheader.Name = "Subheader"
	subheader.Size = UDim2.new(1, -24, 0, 36)
	subheader.Position = UDim2.fromOffset(12, 110)
	subheader.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	subheader.ZIndex = 52
	subheader.Parent = card
	UIKit.Corner(subheader, 8)

	local branchProgLab = Instance.new("TextLabel")
	branchProgLab.Name = "BranchProgLab"
	branchProgLab.Size = UDim2.new(0.5, 0, 1, 0)
	branchProgLab.Position = UDim2.fromOffset(12, 0)
	branchProgLab.BackgroundTransparency = 1
	branchProgLab.Font = Enum.Font.GothamBold
	branchProgLab.TextSize = 13
	branchProgLab.TextColor3 = Color3.fromRGB(0, 220, 255)
	branchProgLab.Text = "Branch Progress: 0/0"
	branchProgLab.TextXAlignment = Enum.TextXAlignment.Left
	branchProgLab.ZIndex = 53
	branchProgLab.Parent = subheader

	local branchEffectLab = Instance.new("TextLabel")
	branchEffectLab.Name = "BranchEffectLab"
	branchEffectLab.Size = UDim2.new(0.5, -12, 1, 0)
	branchEffectLab.Position = UDim2.new(0.5, 0, 0, 0)
	branchEffectLab.BackgroundTransparency = 1
	branchEffectLab.Font = Enum.Font.Gotham
	branchEffectLab.TextSize = 12
	branchEffectLab.TextColor3 = Color3.fromRGB(180, 190, 210)
	branchEffectLab.Text = "Active Branch Boosts: None"
	branchEffectLab.TextXAlignment = Enum.TextXAlignment.Right
	branchEffectLab.ZIndex = 53
	branchEffectLab.Parent = subheader

	-- Scrollable Cards Grid Container
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -24, 1, -160)
	scroll.Position = UDim2.fromOffset(12, 152)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 240)
	scroll.ZIndex = 52
	scroll.Parent = card

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(265, 115)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	local function refreshUI()
		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local unlockedMap = (profile and profile.unlockedTalents) or { C_Core = true }
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0
		local talentPts = (profile and profile.talentPoints) or 0

		local totalNodes = 0
		local totalUnlocked = 0
		for id, node in TalentTreeConfig.Nodes do
			totalNodes += 1
			if unlockedMap[id] == true then
				totalUnlocked += 1
			end
		end

		statsLab.Text = string.format(
			"Coins: %s  |  Talent Points: %s  |  Total Unlocked: %d/%d",
			Format.Num(coins),
			Format.Num(talentPts),
			totalUnlocked,
			totalNodes
		)

		-- Update Category Tabs
		for _, cat in ipairs(CATEGORIES) do
			local btn = tabBtns[cat.id]
			if btn then
				if cat.id == activeCategory then
					btn.BackgroundColor3 = cat.color
					btn.TextColor3 = Color3.new(1, 1, 1)
				else
					btn.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
					btn.TextColor3 = Color3.fromRGB(150, 160, 180)
				end
			end
		end

		-- Clear Grid Cards
		for _, child in scroll:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		-- Collect nodes for active category
		local catNodes = {}
		local branchUnlocked = 0
		local branchTotal = 0

		for id, node in TalentTreeConfig.Nodes do
			if node.branch == activeCategory or (activeCategory == "combat" and id == "C_Core") then
				branchTotal += 1
				if unlockedMap[id] == true then
					branchUnlocked += 1
				end
				table.insert(catNodes, node)
			end
		end

		branchProgLab.Text = string.format("Branch Progress: %d / %d Unlocked (%d%%)", branchUnlocked, branchTotal, math.floor((branchUnlocked / math.max(1, branchTotal)) * 100))

		-- Render Cards
		for order, node in ipairs(catNodes) do
			local isUnlocked = unlockedMap[node.id] == true
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

			local samOk = not node.reqSamTier or ((profile and profile.samClickTier or 0) >= node.reqSamTier)
			local frostOk = not node.reqFrostTier or ((profile and profile.frostTier or 0) >= node.reqFrostTier)
			local grimOk = not node.reqGrimTier or ((profile and profile.grimTier or 0) >= node.reqGrimTier)
			local locOk = not node.reqLocation or ((profile and profile.currentLocation or 1) >= node.reqLocation)
			local questsOk = samOk and frostOk and grimOk and locOk

			local nodeCard = Instance.new("Frame")
			nodeCard.Name = "Card_" .. node.id
			nodeCard.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
			nodeCard.LayoutOrder = order
			nodeCard.ZIndex = 53
			nodeCard.Parent = scroll
			UIKit.Corner(nodeCard, 10)

			local strokeColor = Color3.fromRGB(40, 50, 70)
			if isUnlocked then
				strokeColor = Color3.fromRGB(0, 200, 120)
			elseif isAvailable and questsOk then
				strokeColor = Color3.fromRGB(0, 200, 240)
			elseif isAvailable and not questsOk then
				strokeColor = Color3.fromRGB(220, 120, 30)
			end
			UIKit.Stroke(nodeCard, strokeColor, 1.5, 0.2)

			local iconLab = Instance.new("TextLabel")
			iconLab.Size = UDim2.fromOffset(36, 36)
			iconLab.Position = UDim2.fromOffset(10, 10)
			iconLab.BackgroundTransparency = 1
			iconLab.Font = Enum.Font.GothamBold
			iconLab.TextSize = 22
			iconLab.TextColor3 = if isUnlocked then Color3.fromRGB(240, 200, 80) else Color3.fromRGB(200, 210, 230)
			iconLab.Text = node.icon or "⚔"
			iconLab.ZIndex = 54
			iconLab.Parent = nodeCard

			local titleLabCard = Instance.new("TextLabel")
			titleLabCard.Size = UDim2.new(1, -56, 0, 20)
			titleLabCard.Position = UDim2.fromOffset(50, 8)
			titleLabCard.BackgroundTransparency = 1
			titleLabCard.Font = Enum.Font.GothamBold
			titleLabCard.TextSize = 13
			titleLabCard.TextColor3 = if isUnlocked then Color3.fromRGB(0, 230, 255) else Color3.fromRGB(230, 235, 245)
			titleLabCard.Text = node.name
			titleLabCard.TextXAlignment = Enum.TextXAlignment.Left
			titleLabCard.ZIndex = 54
			titleLabCard.Parent = nodeCard

			local descLab = Instance.new("TextLabel")
			descLab.Size = UDim2.new(1, -20, 0, 36)
			descLab.Position = UDim2.fromOffset(10, 42)
			descLab.BackgroundTransparency = 1
			descLab.Font = Enum.Font.Gotham
			descLab.TextSize = 11
			descLab.TextColor3 = Color3.fromRGB(160, 175, 195)
			descLab.TextWrapped = true
			descLab.Text = node.desc
			descLab.TextXAlignment = Enum.TextXAlignment.Left
			descLab.ZIndex = 54
			descLab.Parent = nodeCard

			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(1, -20, 0, 26)
			buyBtn.Position = UDim2.fromOffset(10, 80)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 11
			buyBtn.ZIndex = 55
			buyBtn.Parent = nodeCard
			UIKit.Corner(buyBtn, 6)

			if isUnlocked then
				buyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 90)
				buyBtn.TextColor3 = Color3.new(1, 1, 1)
				buyBtn.Text = "UNLOCKED ✓"
			elseif isAvailable then
				if not questsOk then
					buyBtn.BackgroundColor3 = Color3.fromRGB(180, 90, 20)
					buyBtn.TextColor3 = Color3.new(1, 1, 1)
					if not samOk then
						buyBtn.Text = "🔒 Click Step " .. tostring(node.reqSamTier)
					elseif not frostOk then
						buyBtn.Text = "🔒 Case Step " .. tostring(node.reqFrostTier)
					elseif not grimOk then
						buyBtn.Text = "🔒 Power Step " .. tostring(node.reqGrimTier)
					else
						buyBtn.Text = "🔒 Loc " .. tostring(node.reqLocation)
					end
				else
					local canAfford = if node.costType == "talentPoints" then talentPts >= node.cost else coins >= node.cost
					if canAfford then
						buyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
						buyBtn.TextColor3 = Color3.new(1, 1, 1)
						buyBtn.Text = "UNLOCK (" .. Format.Num(node.cost) .. ")"
					else
						buyBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
						buyBtn.TextColor3 = Color3.fromRGB(180, 185, 200)
						buyBtn.Text = "NEED " .. Format.Num(node.cost)
					end
					buyBtn.MouseButton1Click:Connect(function()
						Net.UnlockTalentNode(node.id)
						task.delay(0.3, refreshUI)
					end)
				end
			else
				buyBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
				buyBtn.TextColor3 = Color3.fromRGB(100, 110, 130)
				buyBtn.Text = "LOCKED 🔒"
			end
		end

		scroll.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 20)
	end

	-- Create Category Tabs
	for _, cat in ipairs(CATEGORIES) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. cat.id
		tabBtn.Size = UDim2.fromOffset(130, 38)
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.TextSize = 12
		tabBtn.Text = cat.name
		tabBtn.ZIndex = 53
		tabBtn.Parent = tabsRow
		UIKit.Corner(tabBtn, 8)
		tabBtns[cat.id] = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			activeCategory = cat.id
			refreshUI()
		end)
	end

	local api = {}

	function api.Show()
		layer.Visible = true
		refreshUI()
	end

	function api.Hide()
		layer.Visible = false
	end

	function api.Toggle()
		layer.Visible = not layer.Visible
		if layer.Visible then
			refreshUI()
		end
	end

	function api.Refresh()
		if layer.Visible then
			refreshUI()
		end
	end

	return api
end

return TalentTreeUI
