--!strict
--[[
	Placeholder mobs + primitive worldspace HP bar.
	ClickDetector attack. No full game UI.
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)

local MobVisualService = {}
MobVisualService._folder = nil :: Folder?
MobVisualService._models = {} :: { [string]: Model }
MobVisualService._onClick = nil :: ((Player, string) -> ())?

local TIER_COLOR = {
	trash = Color3.fromRGB(120, 200, 120),
	normal = Color3.fromRGB(100, 160, 255),
	elite = Color3.fromRGB(180, 100, 255),
	boss = Color3.fromRGB(220, 60, 60),
	debug = Color3.fromRGB(255, 180, 40),
}

local function hexToColor(hex: string?): Color3?
	if not hex or #hex < 7 then
		return nil
	end
	local r = tonumber(hex:sub(2, 3), 16)
	local g = tonumber(hex:sub(4, 5), 16)
	local b = tonumber(hex:sub(6, 7), 16)
	if r and g and b then
		return Color3.fromRGB(r, g, b)
	end
	return nil
end

local function formatHp(n: number): string
	n = math.floor(math.max(0, n))
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local function ensureFolder(): Folder
	if MobVisualService._folder and MobVisualService._folder.Parent then
		return MobVisualService._folder
	end
	local existing = Workspace:FindFirstChild("Mobs")
	if existing and existing:IsA("Folder") then
		MobVisualService._folder = existing
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = "Mobs"
	f.Parent = Workspace
	MobVisualService._folder = f
	return f
end

--- Primitive HP bar: name + bar fill + numbers
local function makeHpHud(parent: BasePart, title: string)
	local bb = Instance.new("BillboardGui")
	bb.Name = "MobHud"
	bb.Size = UDim2.fromOffset(140, 40)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	bb.Parent = parent

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "Name"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, 0, 0, 14)
	nameLbl.Position = UDim2.new(0, 0, 0, 0)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 12
	nameLbl.TextColor3 = Color3.new(1, 1, 1)
	nameLbl.TextStrokeTransparency = 0.35
	nameLbl.Text = title
	nameLbl.Parent = bb

	-- bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	barBg.BorderSizePixel = 0
	barBg.Size = UDim2.new(1, 0, 0, 12)
	barBg.Position = UDim2.new(0, 0, 0, 16)
	barBg.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = barBg
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.3
	stroke.Parent = barBg

	-- fill
	local fill = Instance.new("Frame")
	fill.Name = "BarFill"
	fill.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Parent = barBg
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = fill

	-- hp text over bar
	local hpLbl = Instance.new("TextLabel")
	hpLbl.Name = "HP"
	hpLbl.BackgroundTransparency = 1
	hpLbl.Size = UDim2.new(1, 0, 1, 0)
	hpLbl.Font = Enum.Font.GothamBold
	hpLbl.TextSize = 10
	hpLbl.TextColor3 = Color3.new(1, 1, 1)
	hpLbl.TextStrokeTransparency = 0.4
	hpLbl.ZIndex = 2
	hpLbl.Text = "0/0"
	hpLbl.Parent = barBg
end

local function buildPlaceholder(def: any, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = def.id

	local scale = (def.visual and def.visual.scale) or 1
	local color = hexToColor(def.visual and def.visual.color)
		or TIER_COLOR[def.tier]
		or Color3.fromRGB(180, 180, 180)

	local shape = (def.visual and def.visual.shape) or "humanoid"
	local root: BasePart

	if shape == "ball" then
		root = Instance.new("Part")
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(2.4, 2.4, 2.4) * scale
		root.Name = "Root"
	elseif shape == "quad" then
		root = Instance.new("Part")
		root.Size = Vector3.new(3.2, 1.6, 4) * scale
		root.Name = "Root"
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.4, 1.2, 1.4) * scale
		head.Color = color
		head.Material = Enum.Material.SmoothPlastic
		head.Anchored = true
		head.CanCollide = false
		head.CFrame = CFrame.new(position + Vector3.new(0, 1.4 * scale, 1.2 * scale))
		head.Parent = model
	else
		root = Instance.new("Part")
		root.Size = Vector3.new(2, 2, 1) * scale
		root.Name = "Root"
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.2, 1.2, 1.2) * scale
		head.Color = Color3.fromRGB(255, 220, 180)
		head.Material = Enum.Material.SmoothPlastic
		head.Anchored = true
		head.CanCollide = false
		head.CFrame = CFrame.new(position + Vector3.new(0, 1.8 * scale, 0))
		head.Parent = model
		local faceBb = Instance.new("BillboardGui")
		faceBb.Size = UDim2.fromOffset(40, 20)
		faceBb.StudsOffset = Vector3.new(0, 0, -0.7)
		faceBb.Parent = head
		local face = Instance.new("TextLabel")
		face.Size = UDim2.fromScale(1, 1)
		face.BackgroundTransparency = 1
		face.Text = "нуб"
		face.TextScaled = true
		face.Font = Enum.Font.GothamBold
		face.TextColor3 = Color3.new(0, 0, 0)
		face.Parent = faceBb
	end

	root.Color = color
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.CFrame = CFrame.new(position + Vector3.new(0, root.Size.Y / 2, 0))
	root.Parent = model
	model.PrimaryPart = root

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 64
	click.Parent = root

	makeHpHud(root, def.name)

	model:SetAttribute("MobId", def.id)
	model:SetAttribute("Tier", def.tier)
	model:SetAttribute("IsDebug", def.isDebug == true)
	model:SetAttribute("IsBoss", def.isBoss == true)
	model:SetAttribute("CurrentHp", def.hp)
	model:SetAttribute("MaxHp", def.hp)

	return model
end

function MobVisualService.Init(onClick: (Player, string) -> ())
	MobVisualService._onClick = onClick
	ensureFolder()
	print("[MobVisual] placeholders + HP bar ready")
end

function MobVisualService.Spawn(entry: any)
	local def = MobConfig.Get(entry.mobId)
	if not def then
		return
	end

	MobVisualService.Despawn(entry.uid)

	local model = buildPlaceholder(def, entry.position)
	model:SetAttribute("MobUid", entry.uid)
	model.Parent = ensureFolder()

	local root = model.PrimaryPart
	if root then
		local click = root:FindFirstChildOfClass("ClickDetector")
		if click then
			click.MouseClick:Connect(function(player: Player)
				if MobVisualService._onClick then
					MobVisualService._onClick(player, entry.uid)
				end
			end)
		end
	end

	MobVisualService._models[entry.uid] = model
	MobVisualService.UpdateHp(entry)
end

function MobVisualService.UpdateHp(entry: any)
	local model = MobVisualService._models[entry.uid]
	if not model then
		return
	end

	local hp = math.max(0, entry.hp)
	local maxHp = math.max(1, entry.maxHp)
	local pct = math.clamp(hp / maxHp, 0, 1)

	-- attributes for other systems / debug
	model:SetAttribute("CurrentHp", hp)
	model:SetAttribute("MaxHp", maxHp)
	model:SetAttribute("HpPercent", math.floor(pct * 1000) / 10)

	local root = model.PrimaryPart
	if not root then
		return
	end
	local bb = root:FindFirstChild("MobHud")
	if not bb then
		return
	end

	local barBg = bb:FindFirstChild("BarBg")
	if barBg then
		local fill = barBg:FindFirstChild("BarFill")
		if fill and fill:IsA("Frame") then
			fill.Size = UDim2.new(pct, 0, 1, 0)
			if pct > 0.5 then
				fill.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
			elseif pct > 0.25 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
			else
				fill.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
			end
		end
		local hpLbl = barBg:FindFirstChild("HP")
		if hpLbl and hpLbl:IsA("TextLabel") then
			hpLbl.Text = string.format("%s / %s", formatHp(hp), formatHp(maxHp))
		end
	end

	local nameLbl = bb:FindFirstChild("Name")
	if nameLbl and nameLbl:IsA("TextLabel") then
		local prefix = entry.isDebug and "[DBG] " or (entry.isBoss and "[BOSS] " or "")
		nameLbl.Text = prefix .. (entry.name or entry.mobId)
	end
end

function MobVisualService.SetAlive(entry: any, alive: boolean)
	local model = MobVisualService._models[entry.uid]
	if not model then
		if alive then
			MobVisualService.Spawn(entry)
		end
		return
	end
	if alive then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Transparency = 0
				d.CanCollide = d.Name == "Root"
			end
		end
		local root = model.PrimaryPart
		if root then
			local bb = root:FindFirstChild("MobHud")
			if bb and bb:IsA("BillboardGui") then
				bb.Enabled = true
			end
		end
		MobVisualService.UpdateHp(entry)
	else
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Transparency = 1
				d.CanCollide = false
			end
		end
		local root = model.PrimaryPart
		if root then
			local bb = root:FindFirstChild("MobHud")
			if bb and bb:IsA("BillboardGui") then
				bb.Enabled = false
			end
		end
		model:SetAttribute("CurrentHp", 0)
		model:SetAttribute("HpPercent", 0)
	end
end

function MobVisualService.Despawn(uid: string)
	local model = MobVisualService._models[uid]
	if model then
		model:Destroy()
		MobVisualService._models[uid] = nil
	end
end

function MobVisualService.ClearAll()
	for uid, _ in MobVisualService._models do
		MobVisualService.Despawn(uid)
	end
	local f = ensureFolder()
	f:ClearAllChildren()
end

return MobVisualService
