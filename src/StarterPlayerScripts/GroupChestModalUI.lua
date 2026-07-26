--!strict
--[[
	GroupChestModalUI — Top-Tier Roblox Group Join & Daily Rewards Popup.
	Displays:
	  - Header & Group ID (928205129)
	  - Daily Reward preview (+10,000 Coins, +3 Pet Keys, +1 Aura Key)
	  - Re-check Membership / Claim button
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)

local GroupChestModalUI = {}

local S = 1.42
local function px(n: number): number
	return math.floor(n * S + 0.5)
end

function GroupChestModalUI.Mount(gui: ScreenGui, store: any, toastApi: any?)
	local layer = Instance.new("Folder")
	layer.Name = "GroupChestModalUI"
	layer.Parent = gui

	-- Dark glass hit catcher
	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.55
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Visible = false
	dim.ZIndex = 140
	dim.Parent = layer

	-- Main Window Card
	local card = UIKit.Glass({
		Name = "GroupModalCard",
		Parent = layer,
		Size = UDim2.fromScale(0.44, 0.58),
		Position = UDim2.fromScale(0.5, 0.5),
		Anchor = Vector2.new(0.5, 0.5),
		Radius = T.R.md,
		Z = 141,
		Deep = true,
		AccentBar = true,
	})
	card.Visible = false

	local rsc = Instance.new("UISizeConstraint")
	rsc.MinSize = Vector2.new(440, 380)
	rsc.MaxSize = Vector2.new(620, 500)
	rsc.Parent = card
	UIKit.Stroke(card, Color3.fromRGB(80, 200, 255), 1.8, 0.25)
	UIKit.Pad(card, px(16))

	-- Top Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, px(42))
	header.ZIndex = 142
	header.Parent = card

	UIKit.Label({
		Parent = header,
		Text = "👥 COMMUNITY REWARD CHEST",
		Size = UDim2.new(0.85, 0, 1, 0),
		SizePx = px(20),
		Font = T.Font.Title,
		Color = Color3.fromRGB(90, 220, 255),
		X = Enum.TextXAlignment.Left,
		Z = 143,
	})

	local closeBtn = UIKit.Button({
		Name = "Close",
		Parent = card,
		Text = "✕",
		Size = UDim2.fromOffset(px(36), px(36)),
		Position = UDim2.new(1, 0, 0, 0),
		Anchor = Vector2.new(1, 0),
		Color = T.Danger,
		Color2 = T.Colors and T.Colors.DangerDeep or Color3.fromRGB(160, 40, 50),
		SizePx = px(16),
		Compact = true,
		Radius = T.R.sm,
		Z = 145,
	})

	-- Body Subtitle
	local bodyLab = UIKit.Label({
		Parent = card,
		Text = "Join our official Roblox Group to unlock Daily Rewards every 24 hours!",
		Size = UDim2.new(1, 0, 0, px(32)),
		Position = UDim2.fromOffset(0, px(46)),
		SizePx = px(13),
		Font = T.Font.Body,
		Color = Color3.fromRGB(220, 230, 245),
		Wrap = true,
		X = Enum.TextXAlignment.Left,
		Z = 142,
	})

	-- Group ID Badge
	local idBadge = Instance.new("Frame")
	idBadge.Name = "GroupBadge"
	idBadge.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
	idBadge.BorderSizePixel = 0
	idBadge.Size = UDim2.new(1, 0, 0, px(36))
	idBadge.Position = UDim2.fromOffset(0, px(84))
	idBadge.ZIndex = 142
	idBadge.Parent = card
	UIKit.Corner(idBadge, T.R.sm)
	UIKit.Stroke(idBadge, Color3.fromRGB(60, 160, 240), 1.2, 0.3)

	local groupIdLab = UIKit.Label({
		Parent = idBadge,
		Text = "👥 Group ID: 928205129",
		Size = UDim2.fromScale(1, 1),
		SizePx = px(14),
		Font = T.Font.Title,
		Color = Color3.fromRGB(255, 215, 80),
		X = Enum.TextXAlignment.Center,
		Z = 143,
	})

	-- Rewards Preview Container
	local rewardsFrame = Instance.new("Frame")
	rewardsFrame.Name = "RewardsContainer"
	rewardsFrame.BackgroundTransparency = 1
	rewardsFrame.Size = UDim2.new(1, 0, 0, px(95))
	rewardsFrame.Position = UDim2.fromOffset(0, px(132))
	rewardsFrame.ZIndex = 142
	rewardsFrame.Parent = card

	local rList = Instance.new("UIListLayout")
	rList.FillDirection = Enum.FillDirection.Horizontal
	rList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rList.Padding = UDim.new(0, px(10))
	rList.Parent = rewardsFrame

	local rewardsData = {
		{ icon = "🪙", val = "+10,000", label = "Coins", color = Color3.fromRGB(255, 215, 80) },
		{ icon = "🔑", val = "+3", label = "Pet Keys", color = Color3.fromRGB(100, 220, 255) },
		{ icon = "✨", val = "+1", label = "Aura Key", color = Color3.fromRGB(210, 100, 255) },
	}

	for i, r in ipairs(rewardsData) do
		local rCard = Instance.new("Frame")
		rCard.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
		rCard.BorderSizePixel = 0
		rCard.Size = UDim2.fromOffset(px(115), px(90))
		rCard.LayoutOrder = i
		rCard.ZIndex = 143
		rCard.Parent = rewardsFrame
		UIKit.Corner(rCard, T.R.sm)
		UIKit.Stroke(rCard, r.color, 1.4, 0.3)
		UIKit.Pad(rCard, px(6))

		UIKit.Label({
			Parent = rCard,
			Text = r.icon,
			Size = UDim2.new(1, 0, 0, px(28)),
			SizePx = px(22),
			X = Enum.TextXAlignment.Center,
			Z = 144,
		})
		UIKit.Label({
			Parent = rCard,
			Text = r.val,
			Size = UDim2.new(1, 0, 0, px(22)),
			Position = UDim2.fromOffset(0, px(30)),
			SizePx = px(14),
			Font = T.Font.Title,
			Color = r.color,
			X = Enum.TextXAlignment.Center,
			Z = 144,
		})
		UIKit.Label({
			Parent = rCard,
			Text = r.label,
			Size = UDim2.new(1, 0, 0, px(18)),
			Position = UDim2.fromOffset(0, px(54)),
			SizePx = px(11),
			Color = T.TextSoft,
			X = Enum.TextXAlignment.Center,
			Z = 144,
		})
	end

	-- CTA Action Buttons
	local ctaRow = Instance.new("Frame")
	ctaRow.Name = "CtaRow"
	ctaRow.BackgroundTransparency = 1
	ctaRow.Size = UDim2.new(1, 0, 0, px(44))
	ctaRow.Position = UDim2.new(0, 0, 1, -px(44))
	ctaRow.ZIndex = 142
	ctaRow.Parent = card

	local claimBtn = UIKit.Button({
		Name = "ClaimBtn",
		Parent = ctaRow,
		Text = "🎁 Claim Group Reward",
		Size = UDim2.new(1, 0, 1, 0),
		Color = T.Success,
		Color2 = T.Colors and T.Colors.SuccessDeep or Color3.fromRGB(28, 140, 80),
		Primary = true,
		SizePx = px(16),
		Radius = T.R.sm,
		Z = 144,
	})

	local function hideAll()
		dim.Visible = false
		card.Visible = false
	end

	closeBtn.MouseButton1Click:Connect(hideAll)
	dim.MouseButton1Click:Connect(hideAll)

	claimBtn.MouseButton1Click:Connect(function()
		hideAll()
		Net.Event("ClaimGroupChest"):FireServer()
	end)

	local api = {}

	function api.Show(payload: any?)
		dim.Visible = true
		card.Visible = true

		local gid = (payload and payload.groupId) or 928205129
		groupIdLab.Text = string.format("👥 Group ID: %d", gid)
	end

	function api.Hide()
		hideAll()
	end

	return api
end

return GroupChestModalUI
