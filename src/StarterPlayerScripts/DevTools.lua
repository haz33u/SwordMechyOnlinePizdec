--!strict
--[[
	Right-side DEV panel (only when GameConfig.DEBUG).
	Gives coins/weapons/dust, unlocks, dummy, location.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(script.Parent.Net)
local UIKit = require(script.Parent.UIKit)

local DevTools = {}

local function fire(action: string, payload: any?)
	pcall(function()
		Net.Event("DebugCommand"):FireServer(action, payload)
	end)
end

function DevTools.Mount(gui: ScreenGui)
	if GameConfig.DEBUG ~= true then
		return { Destroy = function() end }
	end

	local root = Instance.new("Frame")
	root.Name = "DevTools"
	root.AnchorPoint = Vector2.new(1, 0.5)
	root.Position = UDim2.new(1, -12, 0.5, 0)
	root.Size = UDim2.fromOffset(52, 52)
	root.BackgroundTransparency = 1
	root.ZIndex = 80
	root.Parent = gui

	local open = false
	local panel: Frame? = nil

	local btn = Instance.new("TextButton")
	btn.Name = "DevToggle"
	btn.Size = UDim2.fromOffset(52, 52)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	btn.BorderSizePixel = 0
	btn.Text = "DEV"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 200, 80)
	btn.AutoButtonColor = true
	btn.ZIndex = 81
	btn.Parent = root
	UIKit.Corner(btn, 12)
	UIKit.Stroke(btn, Color3.fromRGB(255, 180, 40), 1.5, 0.3)

	local function makePanel()
		if panel then
			return panel
		end
		local p = Instance.new("Frame")
		p.Name = "DevPanel"
		p.AnchorPoint = Vector2.new(1, 0.5)
		p.Position = UDim2.new(1, -68, 0.5, 0)
		p.Size = UDim2.fromOffset(220, 360)
		p.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
		p.BorderSizePixel = 0
		p.Visible = false
		p.ZIndex = 82
		p.Parent = root
		UIKit.Corner(p, 12)
		UIKit.Stroke(p, Color3.fromRGB(80, 80, 90), 1, 0.2)
		UIKit.Pad(p, 10)
		UIKit.List(p, 8, false, Enum.HorizontalAlignment.Center)

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, 0, 0, 22)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 15
		title.TextColor3 = Color3.fromRGB(255, 210, 90)
		title.Text = "DEV TOOLS"
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 83
		title.Parent = p

		local function addBtn(label: string, color: Color3, onClick: () -> ())
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 32)
			b.BackgroundColor3 = color
			b.BorderSizePixel = 0
			b.Text = label
			b.Font = Enum.Font.GothamBold
			b.TextSize = 13
			b.TextColor3 = Color3.new(1, 1, 1)
			b.AutoButtonColor = true
			b.ZIndex = 83
			b.Parent = p
			UIKit.Corner(b, 8)
			b.MouseButton1Click:Connect(onClick)
			return b
		end

		addBtn("+100K Coins", Color3.fromRGB(40, 120, 70), function()
			fire("giveCoins", 100_000)
		end)
		addBtn("+1M Coins", Color3.fromRGB(30, 100, 60), function()
			fire("giveCoins", 1_000_000)
		end)
		addBtn("+50 Enchant Dust", Color3.fromRGB(90, 50, 140), function()
			fire("giveDust", 50)
		end)
		addBtn("+10 Pet/Aura Keys", Color3.fromRGB(50, 80, 140), function()
			fire("giveKeys")
		end)
		addBtn("Give all Loc1 weapons", Color3.fromRGB(120, 70, 40), function()
			fire("giveLoc1Weapons")
		end)
		addBtn("Unlock Offhand", Color3.fromRGB(50, 90, 110), function()
			fire("unlockOffhand")
		end)
		addBtn("Unlock AutoClicker", Color3.fromRGB(50, 90, 110), function()
			fire("unlockAuto")
		end)
		addBtn("Spawn Dummy", Color3.fromRGB(70, 70, 90), function()
			fire("spawnDummy")
		end)
		addBtn("Teleport Loc1", Color3.fromRGB(45, 45, 55), function()
			fire("setLocation", 1)
		end)
		addBtn("Teleport Loc2", Color3.fromRGB(45, 45, 55), function()
			fire("setLocation", 2)
		end)

		panel = p
		return p
	end

	btn.MouseButton1Click:Connect(function()
		open = not open
		local p = makePanel()
		p.Visible = open
		btn.Text = if open then "X" else "DEV"
	end)

	print("[DevTools] mounted (GameConfig.DEBUG)")
	return {
		Destroy = function()
			root:Destroy()
		end,
	}
end

return DevTools
