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

-- Lift mobs a hair off the floor so feet never z-fight with terrain.
local GROUND_SKIN = 0.05

-- Defined further down (needs the marker-folder helper); declared here so buildBody can use it.
local snapModelToGround: (Model, Vector3) -> ()

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
	-- Stud-based 3D proportion: 4.5 studs wide, 1.1 studs tall in world space
	bb.Size = UDim2.new(4.5, 0, 1.1, 0)
	bb.StudsOffset = Vector3.new(0, 3.0, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 38 -- Hide clean when out of combat range
	bb.DistanceLowerLimit = 8
	bb.DistanceUpperLimit = 35
	bb.Parent = parent

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	barBg.BackgroundTransparency = 0.15
	barBg.BorderSizePixel = 0
	barBg.Size = UDim2.new(1, 0, 1, 0)
	barBg.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = barBg

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.8
	stroke.Color = tierColor
	stroke.Transparency = 0.15
	stroke.Parent = barBg

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "Name"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, -8, 0.45, 0)
	nameLbl.Position = UDim2.new(0, 4, 0, 2)
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextScaled = true
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextStrokeTransparency = 0.4
	nameLbl.TextXAlignment = Enum.TextXAlignment.Center
	nameLbl.Text = title
	nameLbl.Parent = barBg

	local fillTrack = Instance.new("Frame")
	fillTrack.Name = "FillTrack"
	fillTrack.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
	fillTrack.BorderSizePixel = 0
	fillTrack.Size = UDim2.new(1, -12, 0.4, 0)
	fillTrack.Position = UDim2.new(0, 6, 0.52, 0)
	fillTrack.Parent = barBg
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 5)
	trackCorner.Parent = fillTrack

	local fill = Instance.new("Frame")
	fill.Name = "BarFill"
	fill.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Parent = fillTrack
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = fill

	local hpLbl = Instance.new("TextLabel")
	hpLbl.Name = "HP"
	hpLbl.BackgroundTransparency = 1
	hpLbl.Size = UDim2.new(1, 0, 1, 0)
	hpLbl.Font = Enum.Font.FredokaOne
	hpLbl.TextScaled = true
	hpLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpLbl.TextStrokeTransparency = 0.4
	hpLbl.ZIndex = 2
	hpLbl.Text = "100 / 100"
	hpLbl.Parent = fillTrack
end

local function tryStudioModel(def: any, modelName: string?): Model?
	local prefName = modelName or (def.visual and def.visual.preferredModelName)
	local searchNames = {
		prefName,
		def.visual and def.visual.preferredModelName,
		def.id,
		def.name,
		string.gsub(def.id, "^L%d+_", ""),
	}

	-- 1. Search primary asset containers FIRST (ReplicatedStorage, INCREMENTAL ASSETS, MinionModels)
	local inc = game:GetService("ReplicatedStorage"):FindFirstChild("INCREMENTAL ASSETS")
	local incMobs = inc and inc:FindFirstChild("MobsFolder")
	local incMinions = inc and inc:FindFirstChild("MinionModels")
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local repMinions = replicatedStorage:FindFirstChild("MinionModels")
	local repMobTemplates = replicatedStorage:FindFirstChild("MobTemplates")
	local containers = {
		repMinions,
		incMinions,
		incMobs,
		repMobTemplates,
		Workspace:FindFirstChild("MobTemplates"),
	}

	for _, container in containers do
		if container then
			for _, n in searchNames do
				if typeof(n) == "string" and n ~= "" then
					local src = container:FindFirstChild(n)
					if src and src:IsA("Model") then
						local clone = src:Clone()
						clone.Name = def.id
						return clone
					end
				end
			end
		end
	end

	-- 2. Fallback: Search Workspace descendants for custom placed models
	for _, desc in Workspace:GetDescendants() do
		if desc:IsA("Model") and not desc:GetAttribute("IsLiveCombatMob") and desc.Parent and desc.Parent.Name ~= "Mobs" then
			for _, n in searchNames do
				if typeof(n) == "string" and n ~= "" then
					if string.lower(desc.Name) == string.lower(n) then
						local clone = desc:Clone()
						clone.Name = def.id
						return clone
					end
				end
			end
		end
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
		root = part("Root", Vector3.new(2.6, 2.2, 2.6) * scale, color, CFrame.new(position + Vector3.new(0, 2.2 * scale, 0)), model, {
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
		root = part("Root", Vector3.new(3.4, 1.5, 4.2) * scale, color, CFrame.new(position + Vector3.new(0, 2.4 * scale, 0)), model, {
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
		local isGoblin = shape == "goblin" or string.find(string.lower(def.id), "goblin") ~= nil
		local torsoH = 2.1 * scale
		local bodyColor = color
		local skinColor = light

		if isGoblin then
			if def.id == "L1_DarkGoblin" then
				bodyColor = Color3.fromRGB(35, 42, 58)
				skinColor = Color3.fromRGB(45, 90, 80)
			elseif def.id == "L1_GoblinWarrior" then
				bodyColor = Color3.fromRGB(50, 60, 45)
				skinColor = Color3.fromRGB(30, 130, 60)
			elseif def.id == "L1_GoblinScout" then
				bodyColor = Color3.fromRGB(80, 55, 35)
				skinColor = Color3.fromRGB(45, 200, 100)
			else
				skinColor = Color3.fromRGB(82, 190, 128)
			end
		end

		root = part("Root", Vector3.new(2.0, torsoH, 1.15) * scale, bodyColor, CFrame.new(position + Vector3.new(0, 3.2 * scale, 0)), model, {
			collide = true,
			material = Enum.Material.SmoothPlastic,
		})

		local head = part("Head", Vector3.new(1.35, 1.25, 1.25) * scale, skinColor, root.CFrame * CFrame.new(0, torsoH * 0.72, 0), model)
		part("ArmL", Vector3.new(0.7, 1.7, 0.7) * scale, skinColor, root.CFrame * CFrame.new(-1.35 * scale, 0.1 * scale, 0), model)
		part("ArmR", Vector3.new(0.7, 1.7, 0.7) * scale, skinColor, root.CFrame * CFrame.new(1.35 * scale, 0.1 * scale, 0), model)
		part("LegL", Vector3.new(0.75, 1.6, 0.75) * scale, dark, root.CFrame * CFrame.new(-0.45 * scale, -torsoH * 0.85, 0), model)
		part("LegR", Vector3.new(0.75, 1.6, 0.75) * scale, dark, root.CFrame * CFrame.new(0.45 * scale, -torsoH * 0.85, 0), model)

		-- Long Goblin Ears & Accessories
		if isGoblin then
			part("EarL", Vector3.new(0.95, 0.28, 0.28) * scale, skinColor, head.CFrame * CFrame.new(-0.95 * scale, 0.1 * scale, 0.1 * scale) * CFrame.Angles(0, 0, math.rad(22)), model)
			part("EarR", Vector3.new(0.95, 0.28, 0.28) * scale, skinColor, head.CFrame * CFrame.new(0.95 * scale, 0.1 * scale, 0.1 * scale) * CFrame.Angles(0, 0, math.rad(-22)), model)

			if def.id == "L1_DarkGoblin" then
				part("DarkHelm", Vector3.new(1.42, 0.7, 1.32) * scale, Color3.fromRGB(20, 25, 35), head.CFrame * CFrame.new(0, 0.35 * scale, 0), model)
				part("EyeL", Vector3.new(0.25, 0.25, 0.12) * scale, Color3.fromRGB(180, 100, 255), head.CFrame * CFrame.new(-0.28 * scale, 0.1 * scale, -0.62 * scale), model, { material = Enum.Material.Neon })
				part("EyeR", Vector3.new(0.25, 0.25, 0.12) * scale, Color3.fromRGB(180, 100, 255), head.CFrame * CFrame.new(0.28 * scale, 0.1 * scale, -0.62 * scale), model, { material = Enum.Material.Neon })
			elseif def.id == "L1_GoblinWarrior" then
				part("PauldronsL", Vector3.new(0.95, 0.6, 0.95) * scale, Color3.fromRGB(40, 50, 40), root.CFrame * CFrame.new(-1.35 * scale, 0.8 * scale, 0), model)
				part("PauldronsR", Vector3.new(0.95, 0.6, 0.95) * scale, Color3.fromRGB(40, 50, 40), root.CFrame * CFrame.new(1.35 * scale, 0.8 * scale, 0), model)
				part("HornL", Vector3.new(0.25, 0.75, 0.25) * scale, Color3.fromRGB(200, 190, 170), head.CFrame * CFrame.new(-0.6 * scale, 0.7 * scale, -0.2 * scale) * CFrame.Angles(0, 0, math.rad(-25)), model)
				part("HornR", Vector3.new(0.25, 0.75, 0.25) * scale, Color3.fromRGB(200, 190, 170), head.CFrame * CFrame.new(0.6 * scale, 0.7 * scale, -0.2 * scale) * CFrame.Angles(0, 0, math.rad(25)), model)
				part("EyeL", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.fromRGB(255, 80, 80), head.CFrame * CFrame.new(-0.28 * scale, 0.1 * scale, -0.62 * scale), model, { material = Enum.Material.Neon })
				part("EyeR", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.fromRGB(255, 80, 80), head.CFrame * CFrame.new(0.28 * scale, 0.1 * scale, -0.62 * scale), model, { material = Enum.Material.Neon })
			else
				part("EyeL", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.new(1, 1, 1), head.CFrame * CFrame.new(-0.28 * scale, 0.1 * scale, -0.62 * scale), model)
				part("EyeR", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.new(1, 1, 1), head.CFrame * CFrame.new(0.28 * scale, 0.1 * scale, -0.62 * scale), model)
			end
		else
			part("EyeL", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.new(1, 1, 1), head.CFrame * CFrame.new(-0.28 * scale, 0.1 * scale, -0.62 * scale), model)
			part("EyeR", Vector3.new(0.22, 0.22, 0.12) * scale, Color3.new(1, 1, 1), head.CFrame * CFrame.new(0.28 * scale, 0.1 * scale, -0.62 * scale), model)
		end
	end

	model.PrimaryPart = root
	weldVisual(model, root)

	-- Same grounding path as Studio models: excludes markers, probes deep, keeps feet on the floor.
	snapModelToGround(model, position)

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

	if isBoss then
		local ring = Instance.new("Part")
		ring.Name = "BossTelegraphRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.2, 14 * scale, 14 * scale)
		ring.Color = Color3.fromRGB(255, 40, 40)
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.65
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanTouch = false
		ring.CanQuery = false
		ring.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = ring
		w.Parent = root
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
	model:SetAttribute("IsLiveCombatMob", true)
	model:SetAttribute("CurrentHp", def.hp)
	model:SetAttribute("MaxHp", def.hp)

	return model
end

--- Spawn markers are real geometry — a mob must never raycast onto its own marker.
local function collectMarkerFolders(): { Instance }
	local folders = {}
	local world = Workspace:FindFirstChild("World")
	local locations = world and world:FindFirstChild("Locations")
	if locations then
		for _, loc in locations:GetChildren() do
			local f = loc:FindFirstChild("MobSpawns") or loc:FindFirstChild("Mobspawns")
			if f then
				table.insert(folders, f)
			end
		end
	end
	for _, child in Workspace:GetChildren() do
		if string.find(string.lower(child.Name), "mobspawn") then
			table.insert(folders, child)
		end
	end
	return folders
end

--[[
	Studio templates (MobTemplates) are R6 rigs: unanchored parts + a live Humanoid.
	Left as-is they are physics-simulated — they settle into the floor, get shoved by
	players and drift off their marker. Mobs here are static click targets, so freeze them.
]]
local function freezeStudioModel(model: Model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.EvaluateStateMachine = false
		end)
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.AutoRotate = false
		hum.BreakJointsOnDeath = false
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.Massless = true
		end
	end
end

--- Cache authored transparency + collision so respawn restores the pose exactly.
local function rememberPartState(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("BaseTransparency") == nil then
				d:SetAttribute("BaseTransparency", d.Transparency)
			end
			if d:GetAttribute("BaseCanCollide") == nil then
				d:SetAttribute("BaseCanCollide", d.CanCollide)
			end
		end
	end
end

function snapModelToGround(model: Model, targetPos: Vector3)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root then return end
	model.PrimaryPart = root

	local bboxCF, bboxSize = model:GetBoundingBox()
	local _, ry, _ = bboxCF:ToOrientation()

	-- Raycast down to find ground level, excluding model, mobs, trees, and props
	local rayParam = RaycastParams.new()
	rayParam.FilterType = Enum.RaycastFilterType.Exclude

	local excludeList = { model, Workspace:FindFirstChild("Mobs"), Workspace:FindFirstChild("Characters") }
	-- Markers are solid parts sitting AT the spawn point: hitting one returns the marker's
	-- own top face as "ground", so every mob sank by its full foot offset.
	for _, f in collectMarkerFolders() do
		table.insert(excludeList, f)
	end
	for _, child in Workspace:GetChildren() do
		local lower = string.lower(child.Name)
		if string.find(lower, "tree") or string.find(lower, "decor") or string.find(lower, "fence") or string.find(lower, "prop") then
			table.insert(excludeList, child)
		end
	end
	rayParam.FilterDescendantsInstances = excludeList

	-- Start well above and probe deep: markers may sit high over the actual floor.
	local rayResult = Workspace:Raycast(targetPos + Vector3.new(0, 30, 0), Vector3.new(0, -200, 0), rayParam)
	-- If nothing was hit, trust the marker's own height rather than dropping the mob.
	local groundY = rayResult and rayResult.Position.Y or targetPos.Y

	-- Calculate distance from PrimaryPart to actual body feet (ignoring held spears/weapons)
	local lowestBodyY = math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			-- Combat mobs are stationary. Unanchored templates fall through the floor
			-- while SetAlive disables collision during the respawn delay.
			p.Anchored = true

			local lowerName = string.lower(p.Name)
			-- Skip held weapons/spears when finding feet position
			if not (string.find(lowerName, "spear") or string.find(lowerName, "sword") or string.find(lowerName, "weapon") or string.find(lowerName, "tool") or string.find(lowerName, "handle")) then
				local bottomY = p.Position.Y - (p.Size.Y / 2)
				if bottomY < lowestBodyY then
					lowestBodyY = bottomY
				end
			end
		end
	end

	-- Distance from the pivot (what PivotTo positions) down to the feet.
	local pivotY = model:GetPivot().Position.Y
	local footOffset = bboxSize.Y / 2
	if lowestBodyY < math.huge and pivotY > lowestBodyY then
		footOffset = pivotY - lowestBodyY
	end

	local uprightCF = CFrame.new(targetPos.X, groundY + footOffset + GROUND_SKIN, targetPos.Z) * CFrame.Angles(0, ry, 0)
	model:PivotTo(uprightCF)
	-- Remember the resolved pose so respawn restores it instead of re-sinking to the raw marker.
	model:SetAttribute("GroundedY", uprightCF.Position.Y)
end

local function buildPlaceholder(def: any, position: Vector3, modelName: string?): Model
	local studio = tryStudioModel(def, modelName)
	if studio then
		-- Freeze BEFORE snapping: an unanchored rig would fall out of the pose we just set.
		freezeStudioModel(studio)
		if not studio.PrimaryPart then
			studio.PrimaryPart = studio:FindFirstChild("HumanoidRootPart") :: BasePart?
				or studio:FindFirstChildWhichIsA("BasePart", true)
		end
		snapModelToGround(studio, position)
		rememberPartState(studio)
		local root = studio.PrimaryPart
		if root then
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
			studio:SetAttribute("IsLiveCombatMob", true)
			return studio
		end
		studio:Destroy()
	end
	local body = buildBody(def, position)
	rememberPartState(body)
	return body
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

	local model = buildPlaceholder(def, entry.position, entry.modelName)
	model:SetAttribute("MobUid", entry.uid)
	model:SetAttribute("MobId", entry.mobId)
	model:SetAttribute("LocationId", entry.locationId)
	model:SetAttribute("Zone", entry.zone)
	model:SetAttribute("MarkerName", entry.markerName)
	model:SetAttribute("IsLiveCombatMob", true)
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

	local fill = bb:FindFirstChild("BarFill", true)
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.new(pct, 0, 1, 0)
		if pct > 0.5 then
			fill.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
		elseif pct > 0.25 then
			fill.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		else
			fill.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		end
	end

	local hpLbl = bb:FindFirstChild("HP", true)
	if hpLbl and hpLbl:IsA("TextLabel") then
		hpLbl.Text = string.format("%s / %s", formatHp(hp), formatHp(maxHp))
	end

	local nameLbl = bb:FindFirstChild("Name", true)
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
		-- Restore the authoritative spawn pose before revealing the model, repairing any
		-- template that moved or fell while hidden during the respawn delay. Prefer the
		-- height resolved at spawn: re-snapping is fine, but PivotTo(entry.position) alone
		-- would drop the mob onto the raw marker and re-sink it by its foot offset.
		if model.PrimaryPart then
			local groundedY = model:GetAttribute("GroundedY")
			if typeof(groundedY) == "number" then
				local _, ry, _ = model:GetPivot():ToOrientation()
				model:PivotTo(CFrame.new(entry.position.X, groundedY, entry.position.Z) * CFrame.Angles(0, ry, 0))
			else
				snapModelToGround(model, entry.position)
			end
		else
			snapModelToGround(model, entry.position)
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				local base = d:GetAttribute("BaseTransparency")
				d.Transparency = if typeof(base) == "number" then base else 0
				local coll = d:GetAttribute("BaseCanCollide")
				d.CanCollide = if typeof(coll) == "boolean" then coll else (d.Name == "Root")
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

function MobVisualService.GetModel(uid: string): Model?
	return MobVisualService._models[uid]
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
