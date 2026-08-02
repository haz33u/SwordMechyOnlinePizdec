--!strict
--[[
	Side TAB menu — TikTok-style player list + streak flame.
	Shows online players, rebirth rank, location, and daily streak.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer
local SideTabMenu = {}

local OPEN_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local WIDTH = 340

local gui: ScreenGui?
local frame: Frame?
local list: ScrollingFrame?
local open = false
local lastStats: any?

local function flameText(streak: number): string
	if streak <= 0 then
		return ""
	end
	if streak >= 30 then
		return "🔥🔥🔥"
	elseif streak >= 14 then
		return "🔥🔥"
	elseif streak >= 3 then
		return "🔥"
	end
	return "🕯️"
end

local function streakColor(streak: number): Color3
	if streak >= 30 then
		return Color3.fromRGB(255, 80, 80)
	elseif streak >= 14 then
		return Color3.fromRGB(255, 140, 60)
	elseif streak >= 3 then
		return Color3.fromRGB(255, 200, 80)
	end
	return Color3.fromRGB(180, 180, 180)
end

local function makeRow(target: Player, stats: any?): Frame
	local row = Instance.new("Frame")
	row.Name = "Row_" .. target.Name
	row.Size = UDim2.new(1, 0, 0, 54)
	row.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 70)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.5
	stroke.Parent = row

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.fromOffset(40, 40)
	avatar.Position = UDim2.fromOffset(7, 7)
	avatar.BackgroundTransparency = 1
	avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", target.UserId)
	avatar.Parent = row

	local cornerAv = Instance.new("UICorner")
	cornerAv.CornerRadius = UDim.new(0, 8)
	cornerAv.Parent = avatar

	local nameLab = Instance.new("TextLabel")
	nameLab.Name = "Name"
	nameLab.Size = UDim2.new(1, -130, 0, 22)
	nameLab.Position = UDim2.fromOffset(54, 4)
	nameLab.BackgroundTransparency = 1
	nameLab.Text = target.DisplayName
	nameLab.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLab.Font = Enum.Font.GothamBold
	nameLab.TextSize = 15
	nameLab.TextXAlignment = Enum.TextXAlignment.Left
	nameLab.TextTruncate = Enum.TextTruncate.AtEnd
	nameLab.Parent = row

	local subLab = Instance.new("TextLabel")
	subLab.Name = "Sub"
	subLab.Size = UDim2.new(1, -130, 0, 18)
	subLab.Position = UDim2.fromOffset(54, 26)
	subLab.BackgroundTransparency = 1
	subLab.TextColor3 = Color3.fromRGB(180, 180, 190)
	subLab.Font = Enum.Font.Gotham
	subLab.TextSize = 12
	subLab.TextXAlignment = Enum.TextXAlignment.Left
	subLab.TextTruncate = Enum.TextTruncate.AtEnd
	subLab.Parent = row

	local streak = stats and stats.dailyStreak or 0
	local flameLab = Instance.new("TextLabel")
	flameLab.Name = "Streak"
	flameLab.Size = UDim2.fromOffset(70, 54)
	flameLab.Position = UDim2.new(1, -76, 0, 0)
	flameLab.BackgroundTransparency = 1
	flameLab.Text = string.format("%s %d", flameText(streak), streak)
	flameLab.TextColor3 = streakColor(streak)
	flameLab.Font = Enum.Font.GothamBold
	flameLab.TextSize = 14
	flameLab.TextXAlignment = Enum.TextXAlignment.Right
	flameLab.Parent = row

	if stats then
		local loc = stats.location or 1
		local rb = stats.rebirthLevel or 0
		local rank = stats.rebirthRankName or ""
		subLab.Text = string.format("Loc %d  •  R%d %s", loc, rb, rank)
	end

	return row
end

local function refreshList()
	if not list then
		return
	end
	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.Name
	layout.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = list

	local sorted = Players:GetPlayers()
	table.sort(sorted, function(a, b)
		return a.Name < b.Name
	end)

	for _, p in ipairs(sorted) do
		local stats = nil
		if p == player then
			stats = lastStats
		end
		local row = makeRow(p, stats)
		row.Parent = list
	end
end

local function setOpen(want: boolean)
	open = want
	if not frame then
		return
	end
	local goal: UDim2 = want and UDim2.new(0, WIDTH, 0, 0) or UDim2.new(0, 0, 0, 0)
	local tw = TweenService:Create(frame, want and OPEN_TWEEN or CLOSE_TWEEN, { Size = goal })
	tw:Play()
	frame.Visible = true
	if not want then
		tw.Completed:Connect(function()
			frame.Visible = false
		end)
	else
		refreshList()
	end
end

function SideTabMenu.Init()
	if gui then
		return
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "SideTabMenu"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 0.5
	bg.Visible = false
	bg.ZIndex = 100
	bg.Parent = gui
	bg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setOpen(false)
		end
	end)

	frame = Instance.new("Frame")
	frame.Name = "Menu"
	frame.Size = UDim2.new(0, 0, 1, 0)
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Visible = false
	frame.ZIndex = 101
	frame.Parent = gui

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	header.BorderSizePixel = 0
	header.ZIndex = 102
	header.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 1, 0)
	title.Position = UDim2.fromOffset(14, 0)
	title.BackgroundTransparency = 1
	title.Text = "PLAYERS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 103
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.fromOffset(40, 40)
	closeBtn.Position = UDim2.new(1, -46, 0, 8)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 28
	closeBtn.ZIndex = 103
	closeBtn.Parent = header
	closeBtn.MouseButton1Click:Connect(function()
		setOpen(false)
	end)

	list = Instance.new("ScrollingFrame")
	list.Name = "PlayerList"
	list.Size = UDim2.new(1, 0, 1, -56)
	list.Position = UDim2.fromOffset(0, 56)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 130)
	list.ZIndex = 102
	list.Parent = frame

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if input.KeyCode == Enum.KeyCode.Tab then
			setOpen(not open)
		end
	end)

	Players.PlayerAdded:Connect(function()
		if open then
			refreshList()
		end
	end)
	Players.PlayerRemoving:Connect(function(removed)
		if not open then
			return
		end
		if list then
			local row = list:FindFirstChild("Row_" .. removed.Name)
			if row then
				row:Destroy()
			end
		end
	end)

	Remotes.Event("ProfileUpdate").OnClientEvent:Connect(function(data)
		lastStats = data and data.stats
		if open then
			refreshList()
		end
	end)
end

return SideTabMenu
