--!strict
--[[
	Readable combat placeholders: silhouette by tier/shape + HP billboard.
	Studio AI / artists can replace models named preferredModelName later.
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MobConfig = require(Shared.Config.MobConfig)
local NumberFormat = require(Shared.NumberFormat)

local MobVisualService = {}
MobVisualService._folder = nil :: Folder?
MobVisualService._models = {} :: { [string]: Model }
MobVisualService._onClick = nil :: ((Player, string) -> ())?

local TIER_COLOR = {
	simple = Color3.fromRGB(110, 190, 120),
	medium = Color3.fromRGB(100, 155, 230),
	hard = Color3.fromRGB(180, 110, 255),
	boss = Color3.fromRGB(230, 70, 70),
	debug = Color3.fromRGB(255, 185, 50),
	-- legacy aliases
	trash = Color3.fromRGB(110, 190, 120),
	normal = Color3.fromRGB(100, 155, 230),
	elite = Color3.fromRGB(180, 110, 255),
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
	return NumberFormat.Num(math.max(0, n))
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

local function part(
	name: string,
	size: Vector3,
	color: Color3,
	cf: CFrame,
	parent: Instance,
	opts: { shape: Enum.PartType?, material: Enum.Material?, collide: boolean? }?
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = (opts and opts.material) or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = opts and opts.collide == true or false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts and opts.shape then
		p.Shape = opts.shape
	end
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function weldVisual(model: Model, root: BasePart)
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = d
			w.Parent = root
			d.Anchored = true
		end
	end
end

local function makeHpHud(parent: BasePart, title: string, tierColor: Color3)
	local bb = Instance.new("BillboardGui")
	bb.Name = "MobHud"
	bb.Size = UDim2.fromOffset(160, 48)
	bb.StudsOffset = Vector3.new(0, 3.8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	bb.Parent = parent

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "Name"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, 0, 0, 16)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 13
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextStrokeTransparency = 0.25
	nameLbl.Text = title
	nameLbl.Parent = bb

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	barBg.BorderSizePixel = 0
	barBg.Size = UDim2.new(1, 0, 0, 14)
	barBg.Position = UDim2.new(0, 0, 0, 18)
	barBg.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = barBg
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = tierColor
	stroke.Transparency = 0.25
	stroke.Parent = barBg

	local fill = Instance.new("Frame")
	fill.Name = "BarFill"
	fill.BackgroundColor3 = Color3.fromRGB(90, 230, 120)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Parent = barBg
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local hpLbl = Instance.new("TextLabel")
	hpLbl.Name = "HP"
	hpLbl.BackgroundTransparency = 1
	hpLbl.Size = UDim2.new(1, 0, 1, 0)
	hpLbl.Font = Enum.Font.GothamBold
	hpLbl.TextSize = 11
	hpLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpLbl.TextStrokeTransparency = 0.3
	hpLbl.ZIndex = 2
	hpLbl.Text = "0/0"
	hpLbl.Parent = barBg
end

local function tryStudioModel(def: any): Model?
	local name = def.visual and def.visual.preferredModelName
	if not name then
		return nil
	end
	local templates = Workspace:FindFirstChild("MobTemplates")
		or game:GetService("ReplicatedStorage"):FindFirstChild("MobTemplates")
	if not templates then
		return nil
	end
	local src = templates:FindFirstChild(name)
	if src and src:IsA("Model") then
		local clone = src:Clone()
		clone.Name = def.id
		return clone
	end
	return nil
end

local function buildBody(def: any, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = def.id

	local scale = (def.visual and def.visual.scale) or 1
	local color = hexToColor(def.visual and def.visual.color)
		or TIER_COLOR[def.tier]
		or Color3.fromRGB(180, 180, 180)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	local light = color:Lerp(Color3.new(1, 1, 1), 0.2)
	local shape = (def.visual and def.visual.shape) or "humanoid"
	local isBoss = def.isBoss == true
	local isDebug = def.isDebug == true

	local root: BasePart

	if shape == "ball" then
		-- slime: body + eyes + highlight
		root = part("Root", Vector3.new(2.6, 2.2, 2.6) * scale, color, CFrame.new(position + Vector3.new(0, 1.2 * scale, 0)), model, {
			shape = Enum.PartType.Ball,
			material = Enum.Material.Neon,
			collide = true,
		})
		root.Material = Enum.Material.SmoothPlastic
		part("Shine", Vector3.new(1.1, 0.9, 1.1) * scale, light, root.CFrame * CFrame.new(0.35 * scale, 0.45 * scale, -0.55 * scale), model, {
			shape = Enum.PartType.Ball,
		}).Transparency = 0.35
		local eyeL = part("EyeL", Vector3.new(0.35, 0.45, 0.2) * scale, Color3.new(1, 1, 1), root.CFrame * CFrame.new(-0.4 * scale, 0.25 * scale, -1.0 * scale), model)
		local eyeR = part("EyeR", Vector3.new(0.35, 0.45, 0.2) * scale, Color3.new(1, 1, 1), root.CFrame * CFrame.new(0.4 * scale, 0.25 * scale, -1.0 * scale), model)
		part("PupilL", Vector3.new(0.16, 0.2, 0.12) * scale, Color3.new(0, 0, 0), eyeL.CFrame * CFrame.new(0, 0, -0.08), model)
		part("PupilR", Vector3.new(0.16, 0.2, 0.12) * scale, Color3.new(0, 0, 0), eyeR.CFrame * CFrame.new(0, 0, -0.08), model)
	elseif shape == "quad" then
		-- wolf-like: body + head + legs + tail
		root = part("Root", Vector3.new(3.4, 1.5, 4.2) * scale, color, CFrame.new(position + Vector3.new(0, 1.1 * scale, 0)), model, {
			collide = true,
			material = Enum.Material.SmoothPlastic,
		})
		part("Head", Vector3.new(1.5, 1.3, 1.6) * scale, light, root.CFrame * CFrame.new(0, 0.35 * scale, -2.0 * scale), model)
		part("Snout", Vector3.new(0.9, 0.7, 1.0) * scale, dark, root.CFrame * CFrame.new(0, 0.15 * scale, -2.85 * scale), model)
		part("EarL", Vector3.new(0.35, 0.7, 0.25) * scale, dark, root.CFrame * CFrame.new(-0.45 * scale, 1.0 * scale, -1.9 * scale), model)
		part("EarR", Vector3.new(0.35, 0.7, 0.25) * scale, dark, root.CFrame * CFrame.new(0.45 * scale, 1.0 * scale, -1.9 * scale), model)
		part("Tail", Vector3.new(0.45, 0.45, 1.6) * scale, dark, root.CFrame * CFrame.new(0, 0.2 * scale, 2.4 * scale), model)
		for i, off in ipairs({
			Vector3.new(-0.9, -0.85, -1.1),
			Vector3.new(0.9, -0.85, -1.1),
			Vector3.new(-0.9, -0.85, 1.1),
			Vector3.new(0.9, -0.85, 1.1),
		}) do
			part("Leg" .. i, Vector3.new(0.55, 1.1, 0.55) * scale, dark, root.CFrame * CFrame.new(off * scale), model)
		end
	else
		-- humanoid / goblin / skeleton / dummy
		local torsoH = 2.1 * scale
		root = part("Root", Vector3.new(2.0, torsoH, 1.15) * scale, color, CFrame.new(position + Vector3.new(0, 1.55 * scale, 0)), model, {
			collide = true,
			material = Enum.Material.SmoothPlastic,
		})
		local headColor = isDebug and Color3.fromRGB(255, 210, 140) or light
		if def.tier == "normal" and string.find(string.lower(def.name), "skeleton") then
			headColor = Color3.fromRGB(230, 230, 220)
			root.Color = Color3.fromRGB(210, 210, 200)
		end
		local head = part("Head", Vector3.new(1.35, 1.25, 1.25) * scale, headColor, root.CFrame * CFrame.new(0, torsoH * 0.72, 0), model)
		part("ArmL", Vector3.new(0.7, 1.7, 0.7) * scale, dark, root.CFrame * CFrame.new(-1.35 * scale, 0.1 * scale, 0), model)
		part("ArmR", Vector3.new(0.7, 1.7, 0.7) * scale, dark, root.CFrame * CFrame.new(1.35 * scale, 0.1 * scale, 0), model)
		part("LegL", Vector3.new(0.75, 1.6, 0.75) * scale, dark, root.CFrame * CFrame.new(-0.45 * scale, -torsoH * 0.85, 0), model)
		part("LegR", Vector3.new(0.75, 1.6, 0.75) * scale, dark, root.CFrame * CFrame.new(0.45 * scale, -torsoH * 0.85, 0), model)
		-- eyes
		part("EyeL", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.new(1, 1, 1), head.CFrame * CFrame.new(-0.28 * scale, 0.1 * scale, -0.62 * scale), model)
		part("EyeR", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.new(1, 1, 1), head.CFrame * CFrame.new(0.28 * scale, 0.1 * scale, -0.62 * scale), model)
		if isBoss then
			part("Crown", Vector3.new(1.5, 0.35, 1.5) * scale, Color3.fromRGB(255, 210, 70), head.CFrame * CFrame.new(0, 0.85 * scale, 0), model, {
				material = Enum.Material.Neon,
			})
		end
	end

	model.PrimaryPart = root
	weldVisual(model, root)

	-- tier outline feel
	local hl = Instance.new("Highlight")
	hl.Name = "TierGlow"
	hl.FillTransparency = isBoss and 0.75 or 0.88
	hl.OutlineTransparency = 0.25
	hl.FillColor = color
	hl.OutlineColor = isBoss and Color3.fromRGB(255, 80, 80) or (isDebug and Color3.fromRGB(255, 200, 60) or color)
	hl.Parent = model

	if isBoss or isDebug then
		local light = Instance.new("PointLight")
		light.Brightness = isBoss and 1.4 or 0.8
		light.Range = isBoss and 14 or 10
		light.Color = color
		light.Parent = root
	end

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 72
	click.Parent = root

	local tierColor = TIER_COLOR[def.tier] or color
	makeHpHud(root, def.name, tierColor)

	model:SetAttribute("MobId", def.id)
	model:SetAttribute("Tier", def.tier)
	model:SetAttribute("IsDebug", isDebug)
	model:SetAttribute("IsBoss", isBoss)
	model:SetAttribute("CurrentHp", def.hp)
	model:SetAttribute("MaxHp", def.hp)

	return model
end

local function buildPlaceholder(def: any, position: Vector3): Model
	local studio = tryStudioModel(def)
	if studio then
		local root = studio.PrimaryPart or studio:FindFirstChildWhichIsA("BasePart", true)
		if root and root:IsA("BasePart") then
			studio.PrimaryPart = root
			studio:PivotTo(CFrame.new(position + Vector3.new(0, root.Size.Y / 2, 0)))
			if not root:FindFirstChildOfClass("ClickDetector") then
				local click = Instance.new("ClickDetector")
				click.MaxActivationDistance = 72
				click.Parent = root
			end
			if not root:FindFirstChild("MobHud") then
				local tierColor = TIER_COLOR[def.tier] or Color3.fromRGB(180, 180, 180)
				makeHpHud(root, def.name, tierColor)
			end
			studio:SetAttribute("MobId", def.id)
			studio:SetAttribute("Tier", def.tier)
			studio:SetAttribute("IsDebug", def.isDebug == true)
			studio:SetAttribute("IsBoss", def.isBoss == true)
			return studio
		end
		studio:Destroy()
	end
	return buildBody(def, position)
end

function MobVisualService.Init(onClick: (Player, string) -> ())
	MobVisualService._onClick = onClick
	ensureFolder()
	print("[MobVisual] silhouettes + HP ready (templates: Workspace/ReplicatedStorage.MobTemplates)")
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
				fill.BackgroundColor3 = Color3.fromRGB(90, 230, 120)
			elseif pct > 0.25 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 205, 70)
			else
				fill.BackgroundColor3 = Color3.fromRGB(240, 80, 80)
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
			elseif d:IsA("Highlight") then
				d.Enabled = true
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
			elseif d:IsA("Highlight") then
				d.Enabled = false
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
