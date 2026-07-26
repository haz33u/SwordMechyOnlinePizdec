--!strict
--[[
	Titles Index UI modal — view all available titles, preview live shimmers, equip active title.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TitleConfig = require(Shared.Config.TitleConfig)
local Remotes = require(Shared.Remotes)

local T = require(script.Parent.Theme)
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
		sg.DisplayOrder = 90
		sg.Parent = pGui
	end
	activeGui = sg :: ScreenGui

	local modal = Instance.new("Frame")
	modal.Name = "TitleIndexModal"
	modal.AnchorPoint = Vector3.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.Size = UDim2.fromOffset(560, 480)
	modal.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	modal.BackgroundTransparency = 0.05
	modal.Parent = sg

	UIKit.Corner(modal, 16)
	UIKit.Stroke(modal, Color3.fromRGB(255, 200, 80), 2, 0.2)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundTransparency = 1
	header.Parent = modal

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.fromOffset(16, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "TITLES INDEX"
	titleLabel.Parent = header

	UIKit.ApplyShimmer(titleLabel, "gold", 0.5, 45)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "X"
	closeBtn.Parent = header
	UIKit.Corner(closeBtn, 8)

	closeBtn.MouseButton1Click:Connect(function()
		TitleIndexUI.Close()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -32, 1, -70)
	scroll.Position = UDim2.fromOffset(16, 56)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 80)
	scroll.Parent = modal

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(256, 120)
	grid.CellPadding = UDim2.fromOffset(12, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	local profile = store and store:PeekProfile()
	local activeTitle = (profile and profile.title) or ""

	for idx, def in ipairs(TitleConfig.Titles) do
		local card = Instance.new("Frame")
		card.Name = "Title_" .. def.id
		card.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
		card.LayoutOrder = idx
		card.Parent = scroll

		UIKit.Corner(card, 12)
		UIKit.Stroke(card, Color3.fromRGB(60, 70, 95), 1.5, 0.4)

		local isUnlocked = TitleConfig.IsUnlocked(profile, def.id)
		local isEquipped = (activeTitle == def.name or activeTitle == def.id)

		local nameLab = Instance.new("TextLabel")
		nameLab.Size = UDim2.new(1, -16, 0, 32)
		nameLab.Position = UDim2.fromOffset(8, 8)
		nameLab.BackgroundTransparency = 1
		nameLab.Font = Enum.Font.Arcade
		nameLab.TextSize = 18
		nameLab.TextColor3 = Color3.new(1, 1, 1)
		nameLab.TextXAlignment = Enum.TextXAlignment.Center
		nameLab.Text = def.name
		nameLab.Parent = card

		if isUnlocked then
			if def.shimmer == "rainbow" then
				UIKit.ApplyRainbow(nameLab, 0.4, 0.35, 90)
			else
				UIKit.ApplyShimmer(nameLab, def.shimmer, 0.6, 60)
			end
		else
			nameLab.TextColor3 = Color3.fromRGB(130, 135, 150)
		end

		local reqLab = Instance.new("TextLabel")
		reqLab.Size = UDim2.new(1, -16, 0, 20)
		reqLab.Position = UDim2.fromOffset(8, 42)
		reqLab.BackgroundTransparency = 1
		reqLab.Font = Enum.Font.Arcade
		reqLab.TextSize = 13
		reqLab.TextColor3 = if isUnlocked then Color3.fromRGB(120, 230, 140) else Color3.fromRGB(220, 120, 120)
		reqLab.TextXAlignment = Enum.TextXAlignment.Center
		reqLab.Text = if isUnlocked then string.format("★ UNLOCKED (+%.0f%% Power)", def.powerPct * 100) else string.format("🔒 Rebirth %d required", def.minRebirth)
		reqLab.Parent = card

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -24, 0, 32)
		btn.Position = UDim2.new(0, 12, 1, -40)
		btn.Font = Enum.Font.Arcade
		btn.TextSize = 15
		btn.Parent = card
		UIKit.Corner(btn, 8)

		if isEquipped then
			btn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Text = "EQUIPPED"
		elseif isUnlocked then
			btn.BackgroundColor3 = Color3.fromRGB(240, 170, 40)
			btn.TextColor3 = Color3.fromRGB(20, 20, 20)
			btn.Text = "EQUIP"
			btn.MouseButton1Click:Connect(function()
				Remotes.Event("SelectTitle"):FireServer(def.id)
				task.wait(0.2)
				TitleIndexUI.Close()
			end)
		else
			btn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
			btn.TextColor3 = Color3.fromRGB(100, 105, 120)
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
