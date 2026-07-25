--!strict
--[[
	MobIndexUI.lua
	Bestiary / Mob Index UI modal showing monster statistics, drop rates, and kill counts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local NumberFormat = require(Shared.NumberFormat)
local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local MobIndexUI = {}
local currentGui: ScreenGui? = nil
local frame: Frame? = nil
local activeLocation = 1

local player = Players.LocalPlayer

function MobIndexUI.Mount(parentGui: ScreenGui, store: any)
	currentGui = parentGui

	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "MobIndexFrame"
	modalFrame.Size = UDim2.fromOffset(560, 420)
	modalFrame.Position = UDim2.fromScale(0.5, 0.5)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
	modalFrame.BorderSizePixel = 0
	modalFrame.Visible = false
	modalFrame.ZIndex = 60
	modalFrame.Parent = parentGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = modalFrame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(70, 150, 240)
	stroke.Parent = modalFrame

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -40, 0, 36)
	header.Position = UDim2.new(0, 16, 0, 12)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.Arcade
	header.TextSize = 22
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "BESTIARY & MOB INDEX"
	header.Parent = modalFrame

	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -38, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "X"
	closeBtn.Parent = modalFrame
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		modalFrame.Visible = false
	end)

	-- Location Tabs
	local tabHolder = Instance.new("Frame")
	tabHolder.Name = "TabHolder"
	tabHolder.Size = UDim2.new(1, -32, 0, 32)
	tabHolder.Position = UDim2.new(0, 16, 0, 52)
	tabHolder.BackgroundTransparency = 1
	tabHolder.Parent = modalFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabHolder

	-- Content Scrolling Grid
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "MobScroll"
	scroll.Size = UDim2.new(1, -32, 1, -100)
	scroll.Position = UDim2.new(0, 16, 0, 90)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness = 6
	scroll.Parent = modalFrame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(250, 90)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.Parent = scroll

	local function renderMobList(locId: number)
		for _, child in scroll:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local mobs = MobConfig.GetByLocation(locId)
		for _, mob in ipairs(mobs) do
			if mob.isDebug then continue end

			local card = Instance.new("Frame")
			card.Name = "MobCard_" .. mob.id
			card.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
			card.BorderSizePixel = 0
			card.Parent = scroll

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 8)
			cardCorner.Parent = card

			local mobName = Instance.new("TextLabel")
			mobName.Size = UDim2.new(1, -12, 0, 22)
			mobName.Position = UDim2.new(0, 8, 0, 6)
			mobName.BackgroundTransparency = 1
			mobName.Font = Enum.Font.Arcade
			mobName.TextSize = 14
			mobName.TextColor3 = mob.isBoss and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 255, 255)
			mobName.TextXAlignment = Enum.TextXAlignment.Left
			mobName.Text = (mob.isBoss and "[BOSS] " or "") .. mob.name
			mobName.Parent = card

			local mobHp = Instance.new("TextLabel")
			mobHp.Size = UDim2.new(1, -12, 0, 18)
			mobHp.Position = UDim2.new(0, 8, 0, 28)
			mobHp.BackgroundTransparency = 1
			mobHp.Font = Enum.Font.Arcade
			mobHp.TextSize = 12
			mobHp.TextColor3 = Color3.fromRGB(180, 220, 255)
			mobHp.TextXAlignment = Enum.TextXAlignment.Left
			mobHp.Text = "HP: " .. NumberFormat.Num(mob.hp) .. " | Coins: " .. NumberFormat.Num(mob.coinReward)
			mobHp.Parent = card

			local mobTier = Instance.new("TextLabel")
			mobTier.Size = UDim2.new(1, -12, 0, 18)
			mobTier.Position = UDim2.new(0, 8, 0, 48)
			mobTier.BackgroundTransparency = 1
			mobTier.Font = Enum.Font.Arcade
			mobTier.TextSize = 11
			mobTier.TextColor3 = Color3.fromRGB(150, 150, 170)
			mobTier.TextXAlignment = Enum.TextXAlignment.Left
			mobTier.Text = "Tier: " .. string.upper(mob.tier) .. " | Respawn: " .. tostring(mob.respawnSeconds) .. "s"
			mobTier.Parent = card
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#mobs / 2) * 100)
	end

	-- Location Tabs (Scrollable)
	local tabHolder = Instance.new("ScrollingFrame")
	tabHolder.Name = "TabHolder"
	tabHolder.Size = UDim2.new(1, -32, 0, 34)
	tabHolder.Position = UDim2.new(0, 16, 0, 50)
	tabHolder.BackgroundTransparency = 1
	tabHolder.BorderSizePixel = 0
	tabHolder.ScrollBarThickness = 4
	tabHolder.CanvasSize = UDim2.new(0, 10 * 105, 0, 0)
	tabHolder.Parent = modalFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabHolder

	for locId = 1, 10 do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "TabLoc_" .. locId
		tabBtn.Size = UDim2.fromOffset(98, 28)
		tabBtn.BackgroundColor3 = locId == 1 and Color3.fromRGB(60, 130, 230) or Color3.fromRGB(40, 44, 54)
		tabBtn.Font = Enum.Font.Arcade
		tabBtn.TextSize = 11
		tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tabBtn.Text = "Loc " .. locId
		tabBtn.Parent = tabHolder
		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 6)
		tCorner.Parent = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			activeLocation = locId
			for _, btn in tabHolder:GetChildren() do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = btn.Name == "TabLoc_" .. locId and Color3.fromRGB(60, 130, 230) or Color3.fromRGB(40, 44, 54)
				end
			end
			renderMobList(locId)
		end)
	end

	renderMobList(1)
	frame = modalFrame

	return {
		Toggle = function()
			if frame then
				frame.Visible = not frame.Visible
			end
		end,
		Show = function()
			if frame then
				frame.Visible = true
			end
		end,
		Hide = function()
			if frame then
				frame.Visible = false
			end
		end,
	}
end

return MobIndexUI
