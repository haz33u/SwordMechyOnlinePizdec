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

		addBtn("🧹 STARTER WEAPON ONLY", Color3.fromRGB(180, 50, 60), function()
			fire("clearWeapons")
		end)
		addBtn("⚠️ RESET DATA & REBIRTHS", Color3.fromRGB(160, 40, 50), function()
			fire("resetData")
		end)
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
		addBtn("Give Loc1 pets (500 pool)", Color3.fromRGB(100, 60, 120), function()
			fire("giveLoc1Pets")
		end)
		addBtn("Give Stiko pet", Color3.fromRGB(90, 50, 110), function()
			fire("givePet", "P1_L1")
		end)
		addBtn("Give all auras", Color3.fromRGB(120, 60, 140), function()
			fire("giveAllAuras")
		end)
		addBtn("Give Flame aura", Color3.fromRGB(160, 70, 40), function()
			fire("giveAura", "A_E1")
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
		for devLoc = 1, 7 do
			addBtn("Teleport Loc" .. tostring(devLoc), Color3.fromRGB(45, 45, 55), function()
				fire("setLocation", devLoc)
			end)
		end

		addBtn("Set Rebirth 25", Color3.fromRGB(120, 40, 120), function()
			fire("setRebirth", 25)
		end)
		addBtn("Reset Lifetime", Color3.fromRGB(80, 80, 90), function()
			fire("resetLifetime")
		end)

		addBtn("📷 3D PETS INSPECTOR", Color3.fromRGB(0, 160, 220), function()
			local Players = game:GetService("Players")
			local localPlayer = Players.LocalPlayer
			if not localPlayer then return end

			local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
			if not playerGui then return end

			local old = playerGui:FindFirstChild("DevPetSnapshotGui")
			if old then
				old:Destroy()
				return
			end

			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "DevPetSnapshotGui"
			screenGui.ResetOnSpawn = false
			screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

			local mainFrame = Instance.new("Frame")
			mainFrame.Size = UDim2.fromScale(1, 1)
			mainFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
			mainFrame.BackgroundTransparency = 0.05
			mainFrame.Parent = screenGui

			local topBar = Instance.new("Frame")
			topBar.Size = UDim2.new(1, 0, 0, 50)
			topBar.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
			topBar.BorderSizePixel = 0
			topBar.Parent = mainFrame

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -60, 1, 0)
			title.Position = UDim2.new(0, 20, 0, 0)
			title.BackgroundTransparency = 1
			title.Text = "✨ 3D PET MODELS INSPECTOR"
			title.TextColor3 = Color3.fromRGB(56, 189, 248)
			title.TextSize = 20
			title.Font = Enum.Font.FredokaOne
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = topBar

			local closeBtn = Instance.new("TextButton")
			closeBtn.Size = UDim2.fromOffset(36, 36)
			closeBtn.Position = UDim2.new(1, -46, 0.5, -18)
			closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
			closeBtn.Text = "✕"
			closeBtn.TextColor3 = Color3.new(1, 1, 1)
			closeBtn.Font = Enum.Font.FredokaOne
			closeBtn.TextSize = 18
			closeBtn.Parent = topBar
			UIKit.Corner(closeBtn, 8)
			closeBtn.MouseButton1Click:Connect(function()
				screenGui:Destroy()
			end)

			local scroll = Instance.new("ScrollingFrame")
			scroll.Size = UDim2.new(1, 0, 1, -50)
			scroll.Position = UDim2.new(0, 0, 0, 50)
			scroll.BackgroundTransparency = 1
			scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			scroll.Parent = mainFrame

			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.fromOffset(240, 240)
			grid.CellPadding = UDim2.fromOffset(16, 16)
			grid.Parent = scroll

			local padding = Instance.new("UIPadding")
			padding.PaddingTop = UDim.new(0, 20)
			padding.PaddingLeft = UDim.new(0, 20)
			padding.PaddingRight = UDim.new(0, 20)
			padding.Parent = scroll

			local foldersToScan = {
				{ Name = "🐾 PETS", Folder = ReplicatedStorage:FindFirstChild("PetModels") },
			}

			local inc = ReplicatedStorage:FindFirstChild("INCREMENTAL ASSETS")
			if inc then
				local m = inc:FindFirstChild("MinionModels")
				if m then table.insert(foldersToScan, { Name = "🧟 MINIONS", Folder = m }) end
			end

			local axes = ReplicatedStorage:FindFirstChild("AxesFolder")
			if axes then table.insert(foldersToScan, { Name = "⚔️ WEAPONS", Folder = axes }) end

			for _, entry in foldersToScan do
				local folder = entry.Folder
				if folder then
					for _, item in folder:GetChildren() do
						if item:IsA("Model") or item:IsA("BasePart") then
							local card = Instance.new("Frame")
							card.Name = item.Name
							card.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
							card.BorderSizePixel = 0
							UIKit.Corner(card, 14)
							UIKit.Stroke(card, Color3.fromRGB(56, 189, 248), 1.5, 0.2)

							local viewport = Instance.new("ViewportFrame")
							viewport.Size = UDim2.new(1, -16, 1, -40)
							viewport.Position = UDim2.new(0, 8, 0, 8)
							viewport.BackgroundTransparency = 1
							viewport.Ambient = Color3.fromRGB(210, 220, 240)
							viewport.LightColor = Color3.fromRGB(255, 255, 255)
							viewport.LightDirection = Vector3.new(-1, -1.2, -1).Unit
							viewport.Parent = card

							local modelClone = item:Clone()
							modelClone.Parent = viewport

							for _, d in modelClone:GetDescendants() do
								if d:IsA("BaseScript") or d:IsA("Sound") then d:Destroy() end
							end

							local cam = Instance.new("Camera")
							cam.FieldOfView = 22
							viewport.CurrentCamera = cam
							cam.Parent = viewport

							local cf: CFrame, size: Vector3
							if modelClone:IsA("Model") then
								cf, size = modelClone:GetBoundingBox()
							elseif modelClone:IsA("BasePart") then
								cf = modelClone.CFrame
								size = modelClone.Size
							else
								cf = CFrame.new()
								size = Vector3.new(2, 2, 2)
							end

							local maxExtent = math.max(size.X, size.Y, size.Z)
							if maxExtent < 0.1 then maxExtent = 1 end
							local dist = maxExtent * 1.65

							cam.CFrame = CFrame.lookAt(
								cf.Position + Vector3.new(dist * 0.5, dist * 0.35, dist * 0.9),
								cf.Position
							)

							local label = Instance.new("TextLabel")
							label.Size = UDim2.new(1, 0, 0, 28)
							label.Position = UDim2.new(0, 0, 1, -28)
							label.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
							label.Text = entry.Name .. ": " .. item.Name
							label.TextColor3 = Color3.fromRGB(255, 255, 255)
							label.TextSize = 12
							label.Font = Enum.Font.FredokaOne
							label.Parent = card

							card.Parent = scroll
						end
					end
				end
			end

			screenGui.Parent = playerGui
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
