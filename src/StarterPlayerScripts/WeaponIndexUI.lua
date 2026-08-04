--!strict
--[[
	Weapon Index UI modal showing collected weapons by location.
	Mirrors MobIndexUI pattern for quick inspection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(Shared.Config.WeaponConfig)
local Rarity = require(script.Parent.Rarity)
local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local WeaponIndexUI = {}
local currentGui: ScreenGui? = nil
local frame: Frame? = nil
local activeLocation = 1

local player = Players.LocalPlayer

local RARITY_ORDER: { [string]: number } = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Secret = 7,
	Limited = 8,
}

function WeaponIndexUI.Mount(parentGui: ScreenGui, store: any)
	currentGui = parentGui

	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "WeaponIndexFrame"
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

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -40, 0, 36)
	header.Position = UDim2.new(0, 16, 0, 12)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.Arcade
	header.TextSize = 22
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "WEAPON INDEX"
	header.Parent = modalFrame

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

	local countLab = Instance.new("TextLabel")
	countLab.Name = "Count"
	countLab.Size = UDim2.new(0, 200, 0, 20)
	countLab.Position = UDim2.new(0, 16, 0, 42)
	countLab.BackgroundTransparency = 1
	countLab.Font = Enum.Font.Arcade
	countLab.TextSize = 12
	countLab.TextColor3 = Color3.fromRGB(180, 180, 200)
	countLab.TextXAlignment = Enum.TextXAlignment.Left
	countLab.Text = ""
	countLab.Parent = modalFrame

	local tabHolder = Instance.new("ScrollingFrame")
	tabHolder.Name = "TabHolder"
	tabHolder.Size = UDim2.new(1, -32, 0, 34)
	tabHolder.Position = UDim2.new(0, 16, 0, 66)
	tabHolder.BackgroundTransparency = 1
	tabHolder.BorderSizePixel = 0
	tabHolder.ScrollBarThickness = 4
	tabHolder.CanvasSize = UDim2.new(0, 10 * 105, 0, 0)
	tabHolder.Parent = modalFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabHolder

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "WeaponScroll"
	scroll.Size = UDim2.new(1, -32, 1, -112)
	scroll.Position = UDim2.new(0, 16, 0, 106)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness = 6
	scroll.Parent = modalFrame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(250, 70)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.Parent = scroll

	local function renderWeaponList(locId: number)
		for _, child in scroll:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local profile = store:PeekProfile()
		local indexData = (profile and profile.weaponIndex) or {}
		local weapons = {}
		for _, def in WeaponConfig.Weapons do
			if (def.location or 1) == locId and not def.dropDisabled then
				table.insert(weapons, def)
			end
		end
		table.sort(weapons, function(a, b)
			local ra = RARITY_ORDER[a.rarity] or 99
			local rb = RARITY_ORDER[b.rarity] or 99
			if ra ~= rb then
				return ra < rb
			end
			return a.name < b.name
		end)

		local found = 0
		for _, w in ipairs(weapons) do
			if indexData[w.id] then
				found += 1
			end
		end
		countLab.Text = string.format("Found %d / %d", found, #weapons)

		for _, w in ipairs(weapons) do
			local discovered = indexData[w.id] == true
			local card = Instance.new("Frame")
			card.Name = "WeaponCard_" .. w.id
			card.BackgroundColor3 = discovered and Color3.fromRGB(34, 38, 48) or Color3.fromRGB(28, 28, 32)
			card.BorderSizePixel = 0
			card.Parent = scroll

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 8)
			cardCorner.Parent = card

			local edge = Rarity.Of(w.rarity)
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Color = edge
			stroke.Transparency = discovered and 0.3 or 0.8
			stroke.Parent = card

			local weaponName = Instance.new("TextLabel")
			weaponName.Size = UDim2.new(1, -12, 0, 22)
			weaponName.Position = UDim2.new(0, 8, 0, 6)
			weaponName.BackgroundTransparency = 1
			weaponName.Font = Enum.Font.Arcade
			weaponName.TextSize = 14
			weaponName.TextColor3 = discovered and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 130)
			weaponName.TextXAlignment = Enum.TextXAlignment.Left
			weaponName.Text = discovered and w.name or "???"
			weaponName.Parent = card

			local stats = Instance.new("TextLabel")
			stats.Size = UDim2.new(1, -12, 0, 18)
			stats.Position = UDim2.new(0, 8, 0, 28)
			stats.BackgroundTransparency = 1
			stats.Font = Enum.Font.Arcade
			stats.TextSize = 12
			stats.TextColor3 = Color3.fromRGB(180, 220, 255)
			stats.TextXAlignment = Enum.TextXAlignment.Left
			stats.Text = discovered and string.format("Power x%.2f · %s", w.powerMult or 1, w.rarity) or "Not discovered"
			stats.Parent = card

			local sell = Instance.new("TextLabel")
			sell.Size = UDim2.new(1, -12, 0, 16)
			sell.Position = UDim2.new(0, 8, 0, 46)
			sell.BackgroundTransparency = 1
			sell.Font = Enum.Font.Arcade
			sell.TextSize = 11
			sell.TextColor3 = Color3.fromRGB(150, 150, 170)
			sell.TextXAlignment = Enum.TextXAlignment.Left
			sell.Text = discovered and string.format("Sell %d coins", w.sellPrice or 0) or ""
			sell.Parent = card
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#weapons / 2) * 80)
	end

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
			renderWeaponList(locId)
		end)
	end

	renderWeaponList(1)
	frame = modalFrame

	return {
		Toggle = function()
			if frame then
				frame.Visible = not frame.Visible
				if frame.Visible then
					renderWeaponList(activeLocation)
				end
			end
		end,
		Show = function()
			if frame then
				renderWeaponList(activeLocation)
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

return WeaponIndexUI
