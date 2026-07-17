--!strict
--[[
	Placeholder mob models in Workspace (no fancy art).
	- Default "Нуб"-style blocks / simple humanoids
	- ClickDetector to attack without custom UI
	- Billboard: name + HP
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)

local MobVisualService = {}
MobVisualService._folder = nil :: Folder?
MobVisualService._models = {} :: { [string]: Model } -- uid -> model
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

local function makeBillboard(parent: BasePart, title: string): (BillboardGui, TextLabel, TextLabel)
	local bb = Instance.new("BillboardGui")
	bb.Name = "MobHud"
	bb.Size = UDim2.fromOffset(160, 48)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Parent = parent

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "Name"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 14
	nameLbl.TextColor3 = Color3.new(1, 1, 1)
	nameLbl.TextStrokeTransparency = 0.4
	nameLbl.Text = title
	nameLbl.Parent = bb

	local hpLbl = Instance.new("TextLabel")
	hpLbl.Name = "HP"
	hpLbl.BackgroundTransparency = 1
	hpLbl.Position = UDim2.new(0, 0, 0.5, 0)
	hpLbl.Size = UDim2.new(1, 0, 0.5, 0)
	hpLbl.Font = Enum.Font.Gotham
	hpLbl.TextSize = 12
	hpLbl.TextColor3 = Color3.fromRGB(120, 255, 140)
	hpLbl.TextStrokeTransparency = 0.4
	hpLbl.Text = "HP"
	hpLbl.Parent = bb

	return bb, nameLbl, hpLbl
end

--- Simple placeholder body: torso + head (n00b style)
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
		-- humanoid / r6 / default "нуб"
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
		-- face label "нуб"
		local decal = Instance.new("BillboardGui")
		decal.Size = UDim2.fromOffset(40, 20)
		decal.StudsOffset = Vector3.new(0, 0, -0.7)
		decal.Parent = head
		local face = Instance.new("TextLabel")
		face.Size = UDim2.fromScale(1, 1)
		face.BackgroundTransparency = 1
		face.Text = "нуб"
		face.TextScaled = true
		face.Font = Enum.Font.GothamBold
		face.TextColor3 = Color3.new(0, 0, 0)
		face.Parent = decal
	end

	root.Color = color
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.CFrame = CFrame.new(position + Vector3.new(0, root.Size.Y / 2, 0))
	root.Parent = model
	model.PrimaryPart = root

	-- Click to attack (works without friend UI)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 48
	click.Parent = root

	makeBillboard(root, def.name)

	model:SetAttribute("MobId", def.id)
	model:SetAttribute("Tier", def.tier)
	model:SetAttribute("IsDebug", def.isDebug == true)
	model:SetAttribute("IsBoss", def.isBoss == true)

	return model
end

function MobVisualService.Init(onClick: (Player, string) -> ())
	MobVisualService._onClick = onClick
	ensureFolder()
	print("[MobVisual] placeholder spawner ready (Workspace.Mobs)")
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
	local root = model.PrimaryPart
	if not root then
		return
	end
	local bb = root:FindFirstChild("MobHud")
	if not bb then
		return
	end
	local hpLbl = bb:FindFirstChild("HP")
	if hpLbl and hpLbl:IsA("TextLabel") then
		local pct = 0
		if entry.maxHp > 0 then
			pct = math.clamp(entry.hp / entry.maxHp, 0, 1)
		end
		hpLbl.Text = string.format("%s / %s (%.0f%%)", formatHp(entry.hp), formatHp(entry.maxHp), pct * 100)
		if pct > 0.5 then
			hpLbl.TextColor3 = Color3.fromRGB(120, 255, 140)
		elseif pct > 0.25 then
			hpLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
		else
			hpLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
		end
	end
	local nameLbl = bb:FindFirstChild("Name")
	if nameLbl and nameLbl:IsA("TextLabel") then
		local prefix = entry.isDebug and "[DEBUG] " or (entry.isBoss and "[BOSS] " or "")
		nameLbl.Text = prefix .. (entry.name or entry.mobId)
	end
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
		-- death flash: hide, keep model for respawn
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
	end
end

function MobVisualService.Despawn(uid: string)
	local model = MobVisualService._models[uid]
	if model then
		model:Destroy()
		MobVisualService._models[uid] = nil
	end
end

function MobVisualService.ClearLocation(locationId: number, mobsTable: { [string]: any })
	for uid, entry in mobsTable do
		if entry.locationId == locationId then
			MobVisualService.Despawn(uid)
		end
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
