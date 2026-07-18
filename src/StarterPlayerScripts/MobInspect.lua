--!strict
--[[
	Shift + Right Click on a mob → Cristalix-style drop table panel.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Rarity = require(script.Parent.Rarity)
local Theme = require(script.Parent.Theme)

local MobInspect = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local gui: ScreenGui? = nil
local panel: Frame? = nil
local open = false

local function ensureGui(): ScreenGui
	if gui and gui.Parent then
		return gui
	end
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "MobInspectGui"
	g.ResetOnSpawn = false
	g.DisplayOrder = 60
	g.IgnoreGuiInset = true
	g.Parent = pg
	gui = g
	return g
end

local function close()
	open = false
	if panel then
		panel.Visible = false
	end
end

local function clearChildren(f: Instance)
	for _, c in f:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") and not c:IsA("UICorner") and not c:IsA("UIStroke") then
			c:Destroy()
		end
	end
end

local function makeLabel(parent: Instance, text: string, size: number, color: Color3?, bold: boolean?): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, size + 6)
	t.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	t.TextSize = size
	t.TextColor3 = color or Theme.Text
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text
	t.Parent = parent
	return t
end

local function show(data: any)
	local g = ensureGui()
	if not panel then
		local p = Instance.new("Frame")
		p.Name = "Panel"
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.fromScale(0.5, 0.48)
		p.Size = UDim2.fromOffset(420, 480)
		p.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
		p.BackgroundTransparency = 0.08
		p.BorderSizePixel = 0
		p.Parent = g
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 14)
		c.Parent = p
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(90, 100, 140)
		s.Thickness = 1.5
		s.Transparency = 0.3
		s.Parent = p
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 14)
		pad.PaddingBottom = UDim.new(0, 14)
		pad.PaddingLeft = UDim.new(0, 16)
		pad.PaddingRight = UDim.new(0, 16)
		pad.Parent = p

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "Close"
		closeBtn.Size = UDim2.fromOffset(32, 32)
		closeBtn.Position = UDim2.new(1, -36, 0, 4)
		closeBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 60)
		closeBtn.Text = "X"
		closeBtn.TextColor3 = Color3.new(1, 1, 1)
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.TextSize = 16
		closeBtn.Parent = p
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 8)
		cc.Parent = closeBtn
		closeBtn.MouseButton1Click:Connect(close)

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Body"
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.Size = UDim2.new(1, 0, 1, -8)
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 4
		scroll.Parent = p
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 8)
		list.Parent = scroll

		panel = p
	end

	assert(panel)
	panel.Visible = true
	open = true
	local body = panel:FindFirstChild("Body") :: ScrollingFrame
	clearChildren(body)

	makeLabel(body, data.name or "Mob", 22, Theme.Text, true)
	makeLabel(
		body,
		string.format(
			"%s  ·  HP %s  ·  +%s coins  ·  +%s power",
			data.tierLabel or data.tier or "?",
			tostring(data.hp),
			tostring(data.coinReward),
			tostring(data.powerReward)
		),
		14,
		Theme.TextSoft or Theme.TextMuted,
		false
	)
	if data.description then
		makeLabel(body, data.description, 13, Theme.TextMuted, false)
	end

	makeLabel(body, "Possible loot:", 16, Theme.Gold or Color3.fromRGB(240, 200, 90), true)

	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.Parent = body
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = UDim2.fromOffset(88, 110)
	gl.CellPadding = UDim2.fromOffset(10, 10)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = grid

	for i, row in ipairs(data.drops or {}) do
		local cell = Instance.new("Frame")
		cell.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
		cell.BorderSizePixel = 0
		cell.LayoutOrder = i
		cell.Parent = grid
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = cell
		local stroke = Instance.new("UIStroke")
		stroke.Color = Rarity.Of(row.rarity)
		stroke.Thickness = 2
		stroke.Transparency = 0.15
		stroke.Parent = cell

		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(56, 56)
		img.Position = UDim2.new(0.5, -28, 0, 8)
		img.Image = row.icon or ""
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = cell

		local pct = Instance.new("TextLabel")
		pct.BackgroundTransparency = 1
		pct.Size = UDim2.new(1, -6, 0, 18)
		pct.Position = UDim2.new(0, 3, 1, -40)
		pct.Font = Enum.Font.GothamBold
		pct.TextSize = 13
		pct.TextColor3 = Rarity.Of(row.rarity)
		pct.Text = string.format("%.3f%%", row.chancePercent or 0)
		pct.Parent = cell

		local nm = Instance.new("TextLabel")
		nm.BackgroundTransparency = 1
		nm.Size = UDim2.new(1, -6, 0, 16)
		nm.Position = UDim2.new(0, 3, 1, -20)
		nm.Font = Enum.Font.Gotham
		nm.TextSize = 11
		nm.TextColor3 = Theme.TextSoft or Theme.Text
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.Text = row.rarity or ""
		nm.Parent = cell
	end

	if data.enchantDust then
		local d = data.enchantDust
		makeLabel(
			body,
			string.format(
				"✦ %s  %d–%d  (%.0f%%) — %s",
				d.name,
				d.min,
				d.max,
				d.chancePercent or 100,
				d.note or ""
			),
			14,
			Color3.fromRGB(190, 120, 255),
			true
		)
	end

	makeLabel(body, "Shift+RMB — inspect  ·  click — attack", 12, Theme.TextMuted, false)
end

local function findMobFromTarget(inst: Instance?): (string?, string?)
	local cur = inst
	while cur and cur ~= Workspace do
		if cur:IsA("Model") and cur:GetAttribute("MobUid") then
			return cur:GetAttribute("MobUid") :: string, cur:GetAttribute("MobId") :: string?
		end
		if cur:IsA("Model") and cur.Parent and cur.Parent.Name == "Mobs" then
			local uid = cur:GetAttribute("MobUid")
			if uid then
				return uid :: string, cur:GetAttribute("MobId") :: string?
			end
		end
		cur = cur.Parent
	end
	return nil, nil
end

function MobInspect.Init()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton2 then
			return
		end
		if not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and not UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
			return
		end

		local target = mouse.Target
		local uid, mobId = findMobFromTarget(target)
		if not uid and not mobId then
			-- ray fallback
			local cam = Workspace.CurrentCamera
			if cam then
				local unit = mouse.UnitRay
				local ray = Workspace:Raycast(unit.Origin, unit.Direction * 80)
				if ray then
					uid, mobId = findMobFromTarget(ray.Instance)
				end
			end
		end

		local key = mobId or uid
		if not key then
			return
		end

		local ok, data = pcall(function()
			return Remotes.Function("GetMobDropInfo"):InvokeServer(uid or key)
		end)
		if ok and data then
			show(data)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.Escape and open then
			close()
		end
	end)

	print("[MobInspect] Shift+RMB on mob — drop table")
end

return MobInspect
