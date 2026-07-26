--!strict
--[[
	Titles Index UI modal — view ALL available titles, preview live shimmers, equip active title.
	Responsive scale + crisp readable styling.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TitleConfig = require(Shared.Config.TitleConfig)
local Remotes = require(Shared.Remotes)

local UIKit = require(script.Parent.UIKit)

local TitleIndexUI = {}

local activeGui: ScreenGui? = nil
local activeModal: Frame? = nil

function TitleIndexUI.Open(store: any)
	if activeModal then
		TitleIndexUI.Close()
		return
	end

	local player = Players.LocalPlayer
	local pGui = player:WaitForChild("PlayerGui")

	local sg = pGui:FindFirstChild("TitleIndexGui")
	if not sg then
		sg = Instance.new("ScreenGui")
		sg.Name = "TitleIndexGui"
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 99999
		sg.Parent = pGui
	else
		(sg :: ScreenGui).DisplayOrder = 99999
	end
	activeGui = sg :: ScreenGui

	local modal = Instance.new("Frame")
	modal.Name = "TitleIndexModal"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.Size = UDim2.new(0.65, 0, 0.78, 0)
	modal.BackgroundColor3 = Color3.fromRGB(34, 40, 54)
	modal.BackgroundTransparency = 0
	modal.ZIndex = 100
	modal.Parent = sg

	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(480, 400)
	constraint.MaxSize = Vector2.new(840, 700)
	constraint.Parent = modal

	UIKit.Corner(modal, 16)
	UIKit.Stroke(modal, Color3.fromRGB(255, 215, 90), 2.5, 0.1)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.ZIndex = 101
	header.Parent = modal

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.fromOffset(20, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.TextSize = 26
	titleLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "TITLES INDEX"
	titleLabel.ZIndex = 102
	titleLabel.Parent = header

	UIKit.ApplyShimmer(titleLabel, "gold", 0.5, 45)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(38, 38)
	closeBtn.Position = UDim2.new(1, -48, 0.5, -19)
	closeBtn.BackgroundColor3 = Color3.fromRGB(230, 50, 60)
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.TextSize = 22
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "X"
	closeBtn.ZIndex = 103
	closeBtn.Parent = header
	UIKit.Corner(closeBtn, 10)
	UIKit.Stroke(closeBtn, Color3.new(1, 1, 1), 1.5, 0.3)

	closeBtn.MouseButton1Click:Connect(function()
		TitleIndexUI.Close()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -36, 1, -74)
	scroll.Position = UDim2.fromOffset(18, 60)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 90)
	scroll.ZIndex = 101
	scroll.Parent = modal

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.485, -6, 0, 114)
	grid.CellPadding = UDim2.new(0.03, 0, 0, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	local profile = store and store:PeekProfile()
	local activeTitle = (profile and profile.title) or ""

	for idx, def in ipairs(TitleConfig.Titles) do
		local card = Instance.new("Frame")
		card.Name = "Title_" .. def.id
		card.BackgroundColor3 = Color3.fromRGB(48, 56, 76)
		card.LayoutOrder = idx
		card.ZIndex = 102
		card.Parent = scroll

		UIKit.Corner(card, 12)
		UIKit.Stroke(card, Color3.fromRGB(90, 105, 140), 1.5, 0.2)

		local isUnlocked = TitleConfig.IsUnlocked(profile, def.id)
		local isEquipped = (activeTitle == def.name or activeTitle == def.id)

		local nameLab = Instance.new("TextLabel")
		nameLab.Size = UDim2.new(1, -16, 0, 32)
		nameLab.Position = UDim2.fromOffset(8, 8)
		nameLab.BackgroundTransparency = 1
		nameLab.Font = Enum.Font.Arcade
		nameLab.TextSize = 19
		nameLab.TextColor3 = Color3.new(1, 1, 1)
		nameLab.TextXAlignment = Enum.TextXAlignment.Center
		nameLab.Text = def.name
		nameLab.ZIndex = 103
		nameLab.Parent = card

		if isUnlocked then
			if def.shimmer == "rainbow" then
				UIKit.ApplyRainbow(nameLab, 0.4, 0.35, 90)
			else
				UIKit.ApplyShimmer(nameLab, def.shimmer, 0.6, 60)
			end
		else
			nameLab.TextColor3 = Color3.fromRGB(150, 155, 170)
		end

		local reqLab = Instance.new("TextLabel")
		reqLab.Size = UDim2.new(1, -16, 0, 22)
		reqLab.Position = UDim2.fromOffset(8, 42)
		reqLab.BackgroundTransparency = 1
		reqLab.Font = Enum.Font.Arcade
		reqLab.TextSize = 13
		reqLab.TextColor3 = if isUnlocked then Color3.fromRGB(130, 240, 150) else Color3.fromRGB(240, 130, 130)
		reqLab.TextXAlignment = Enum.TextXAlignment.Center
		reqLab.Text = if isUnlocked then string.format("★ UNLOCKED (+%.0f%% Power)", def.powerPct * 100) else string.format("🔒 Rebirth %d required", def.minRebirth)
		reqLab.ZIndex = 103
		reqLab.Parent = card

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -24, 0, 34)
		btn.Position = UDim2.new(0, 12, 1, -42)
		btn.Font = Enum.Font.Arcade
		btn.TextSize = 15
		btn.ZIndex = 104
		btn.Parent = card
		UIKit.Corner(btn, 8)

		if isEquipped then
			btn.BackgroundColor3 = Color3.fromRGB(40, 200, 100)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Text = "EQUIPPED"
			UIKit.Stroke(btn, Color3.new(1, 1, 1), 1.2, 0.2)
		elseif isUnlocked then
			btn.BackgroundColor3 = Color3.fromRGB(255, 185, 40)
			btn.TextColor3 = Color3.fromRGB(20, 20, 20)
			btn.Text = "EQUIP"
			UIKit.Stroke(btn, Color3.new(1, 1, 1), 1.2, 0.2)
			btn.MouseButton1Click:Connect(function()
				Remotes.Event("SelectTitle"):FireServer(def.id)
				task.wait(0.2)
				TitleIndexUI.Close()
			end)
		else
			btn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
			btn.TextColor3 = Color3.fromRGB(130, 135, 150)
			btn.Text = "LOCKED"
		end
	end

	activeModal = modal
end

function TitleIndexUI.Close()
	if activeGui then
		activeGui:Destroy()
		activeGui = nil
		activeModal = nil
	end
end

return TitleIndexUI
