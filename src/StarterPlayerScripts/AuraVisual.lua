--!strict
--[[
	Equipped aura visual on local character (ring / particles / wings).
	Server owns equip; this is client cosmetic only.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AuraConfig = require(Shared.Config.AuraConfig)
local AuraModelConfig = require(Shared.Config.AuraModelConfig)

local AuraVisual = {}

local player = Players.LocalPlayer
local activeModel: Model? = nil
local activeUid: string? = nil
local lastProfile: any = nil
local spinConn: RBXScriptConnection? = nil
local charConn: RBXScriptConnection? = nil

local function getFolder(): Folder?
	local f = ReplicatedStorage:FindFirstChild(AuraModelConfig.FolderName or "AuraVfx")
	if f and f:IsA("Folder") then
		return f
	end
	return nil
end

local BODY_NAME = {
	HumanoidRootPart = true,
	Head = true,
	Torso = true,
	UpperTorso = true,
	LowerTorso = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	LeftArm = true,
	RightArm = true,
	LeftLeg = true,
	RightLeg = true,
	LeftHand = true,
	RightHand = true,
	LeftFoot = true,
	RightFoot = true,
	LeftUpperArm = true,
	RightUpperArm = true,
	LeftLowerArm = true,
	RightLowerArm = true,
	LeftUpperLeg = true,
	RightUpperLeg = true,
	LeftLowerLeg = true,
	RightLowerLeg = true,
}

local function isBodyPartName(name: string): boolean
	if BODY_NAME[name] then
		return true
	end
	local lower = string.lower(name)
	if string.find(lower, "dummy", 1, true) then
		return true
	end
	if string.find(lower, "humanoid", 1, true) then
		return true
	end
	-- R15 / classic limb patterns
	if string.find(lower, "upperarm", 1, true)
		or string.find(lower, "lowerarm", 1, true)
		or string.find(lower, "upperleg", 1, true)
		or string.find(lower, "lowerleg", 1, true)
		or string.find(lower, "lefthand", 1, true)
		or string.find(lower, "righthand", 1, true)
		or string.find(lower, "leftfoot", 1, true)
		or string.find(lower, "rightfoot", 1, true)
		or string.find(lower, "left arm", 1, true)
		or string.find(lower, "right arm", 1, true)
		or string.find(lower, "left leg", 1, true)
		or string.find(lower, "right leg", 1, true)
	then
		return true
	end
	return false
end

local function hasVfx(inst: Instance): boolean
	if inst:IsA("ParticleEmitter")
		or inst:IsA("Beam")
		or inst:IsA("Trail")
		or inst:IsA("Fire")
		or inst:IsA("Smoke")
		or inst:IsA("Sparkles")
	then
		return true
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("ParticleEmitter")
			or d:IsA("Beam")
			or d:IsA("Trail")
			or d:IsA("Fire")
			or d:IsA("Smoke")
			or d:IsA("Sparkles")
		then
			return true
		end
	end
	return false
end

--- Pack auras often ship with a full Dummy/R15 — move VFX off limbs, then strip body.
local function stripCharacterJunk(root: Model)
	-- Ensure invisible Root to host reparented VFX
	local host = root.PrimaryPart
	if not host or isBodyPartName(host.Name) then
		local r = Instance.new("Part")
		r.Name = "Root"
		r.Size = Vector3.new(0.4, 0.4, 0.4)
		r.Transparency = 1
		r.CanCollide = false
		r.Massless = true
		r.Anchored = false
		r.Parent = root
		root.PrimaryPart = r
		host = r
	end

	-- Reparent VFX off body parts onto Root attachments (preserve some Y bias)
	local vfxList: { Instance } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("ParticleEmitter")
			or d:IsA("Beam")
			or d:IsA("Trail")
			or d:IsA("Fire")
			or d:IsA("Smoke")
			or d:IsA("Sparkles")
		then
			table.insert(vfxList, d)
		end
	end
	for i, d in ipairs(vfxList) do
		local parent = d.Parent
		local onBody = false
		local yBias = 0
		if parent and parent:IsA("BasePart") and isBodyPartName(parent.Name) then
			onBody = true
			local l = string.lower(parent.Name)
			if string.find(l, "head", 1, true) then
				yBias = 1.1
			elseif string.find(l, "leg", 1, true) or string.find(l, "foot", 1, true) then
				yBias = -1.4
			elseif string.find(l, "arm", 1, true) or string.find(l, "hand", 1, true) then
				yBias = 0.35
			end
		elseif parent and parent:IsA("Attachment") then
			local bp = parent.Parent
			if bp and bp:IsA("BasePart") and isBodyPartName(bp.Name) then
				onBody = true
			end
		end
		if onBody then
			local att = Instance.new("Attachment")
			att.Name = "FX_" .. tostring(i)
			att.Position = Vector3.new(0, yBias, 0)
			att.Parent = host
			d.Parent = att
			if d:IsA("Beam") then
				local a0 = Instance.new("Attachment")
				a0.Position = Vector3.new(0, 0, 0)
				a0.Parent = host
				local a1 = Instance.new("Attachment")
				a1.Position = Vector3.new(0, 1.5, 0)
				a1.Parent = host
				;(d :: Beam).Attachment0 = a0
				;(d :: Beam).Attachment1 = a1
			end
		end
	end

	local kill: { Instance } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("Humanoid")
			or d:IsA("Shirt")
			or d:IsA("Pants")
			or d:IsA("ShirtGraphic")
			or d:IsA("BodyColors")
			or d:IsA("CharacterMesh")
			or d:IsA("Accessory")
			or d:IsA("Hat")
			or d:IsA("Clothing")
			or d:IsA("Animator")
			or d:IsA("AnimationController")
			or d:IsA("Motor6D")
		then
			table.insert(kill, d)
		elseif d:IsA("BasePart") and isBodyPartName(d.Name) and d ~= host then
			table.insert(kill, d)
		elseif d:IsA("Model") and d ~= root then
			local n = string.lower(d.Name)
			if string.find(n, "dummy", 1, true) or d:FindFirstChildOfClass("Humanoid") then
				table.insert(kill, d)
			end
		end
	end
	for _, d in kill do
		pcall(function()
			d:Destroy()
		end)
	end
end

local function sanitize(root: Instance)
	stripCharacterJunk(root)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.Anchored = false
			d.CastShadow = false
			-- Hide leftover solid junk that isn't neon/effect mesh
			if not hasVfx(d) and d.Material ~= Enum.Material.Neon and d.Transparency < 0.9 then
				-- semi-hide non-vfx bricks that packs leave as holders
				if d.Name ~= "Root" and d.Name ~= "Ring" and d.Name ~= "Wing" then
					d.Transparency = math.max(d.Transparency, 0.85)
				end
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
			pcall(function()
				(d :: any).Enabled = true
			end)
		elseif d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ForceField") or d:IsA("Camera") then
			d:Destroy()
		end
	end
end

local function rarityColor(rarity: string): Color3
	local t = AuraModelConfig.RarityColor
	return (t and t[rarity]) or Color3.fromRGB(180, 180, 200)
end

local function normalizeExtent(clone: Model, target: number)
	if target <= 0.1 then
		return
	end
	local okBb, _cf, size = pcall(function()
		return clone:GetBoundingBox()
	end)
	if not okBb or typeof(size) ~= "Vector3" then
		return
	end
	local maxDim = math.max(size.X, size.Y, size.Z, 0.05)
	local factor = target / maxDim
	local fMin = AuraModelConfig.TargetExtentMinFactor or 0.04
	local fMax = AuraModelConfig.TargetExtentMaxFactor or 20
	factor = math.clamp(factor, fMin, fMax)
	if math.abs(factor - 1) > 0.02 then
		pcall(function()
			local cur = 1
			pcall(function()
				cur = (clone :: any):GetScale()
			end)
			if type(cur) ~= "number" or cur <= 0 then
				cur = 1
			end
			(clone :: any):ScaleTo(cur * factor)
		end)
	end
end

local function getAuraTheme(auraId: string, def: any?): { mainColor: Color3, secColor: Color3, texture: string, speed: number }
	local name = (def and def.name) or auraId
	local lower = string.lower(name .. "_" .. auraId)
	local rar = (def and def.rarity) or "Common"
	local main = rarityColor(rar)
	local sec = main:Lerp(Color3.new(1, 1, 1), 0.3)
	local tex = "rbxasset://textures/particles/sparkles_main.dds"
	local spd = 1.2

	if string.find(lower, "ice", 1, true) or string.find(lower, "frost", 1, true) then
		main = Color3.fromRGB(100, 220, 255)
		sec = Color3.fromRGB(220, 245, 255)
		spd = 1.0
	elseif string.find(lower, "fire", 1, true) or string.find(lower, "flame", 1, true) then
		main = Color3.fromRGB(255, 90, 40)
		sec = Color3.fromRGB(255, 200, 50)
		spd = 2.2
	elseif string.find(lower, "dark", 1, true) or string.find(lower, "shadow", 1, true) then
		main = Color3.fromRGB(130, 40, 210)
		sec = Color3.fromRGB(40, 20, 70)
		spd = 0.9
	elseif string.find(lower, "light", 1, true) or string.find(lower, "spark", 1, true) then
		main = Color3.fromRGB(255, 225, 90)
		sec = Color3.fromRGB(255, 255, 200)
		spd = 1.8
	elseif string.find(lower, "leaf", 1, true) or string.find(lower, "foliage", 1, true) then
		main = Color3.fromRGB(80, 220, 110)
		sec = Color3.fromRGB(180, 255, 120)
		spd = 1.1
	end

	return { mainColor = main, secColor = sec, texture = tex, speed = spd }
end

local function makeProcedural(auraId: string, def: any?): Model
	local m = Instance.new("Model")
	m.Name = "AuraProc_" .. auraId
	local theme = getAuraTheme(auraId, def)
	local mode = AuraModelConfig.GetAttachMode(auraId)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored = false
	root.CanCollide = false
	root.Massless = true
	root.Transparency = 1
	root.Size = Vector3.new(0.4, 0.4, 0.4)
	root.Parent = m
	m.PrimaryPart = root

	-- Layer 1: Ground Seal / Rotating Neon Rings
	if mode == "feet" or mode == "hrp" then
		local ring = Instance.new("Part")
		ring.Name = "Ring"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.18, 3.4, 3.4)
		ring.CFrame = CFrame.Angles(0, 0, math.rad(90))
		ring.Color = theme.mainColor
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.35
		ring.CanCollide = false
		ring.Massless = true
		ring.Anchored = false
		ring.Parent = m

		local innerRing = Instance.new("Part")
		innerRing.Name = "InnerRing"
		innerRing.Shape = Enum.PartType.Cylinder
		innerRing.Size = Vector3.new(0.22, 2.2, 2.2)
		innerRing.CFrame = CFrame.Angles(0, 0, math.rad(90))
		innerRing.Color = theme.secColor
		innerRing.Material = Enum.Material.Neon
		innerRing.Transparency = 0.45
		innerRing.CanCollide = false
		innerRing.Massless = true
		innerRing.Anchored = false
		innerRing.Parent = m

		local w1 = Instance.new("WeldConstraint")
		w1.Part0 = root
		w1.Part1 = ring
		w1.Parent = ring

		local w2 = Instance.new("WeldConstraint")
		w2.Part0 = root
		w2.Part1 = innerRing
		w2.Parent = innerRing
	end

	-- Layer 2: Wings for Back Mode
	if mode == "back" then
		for _, side in { -1, 1 } do
			local wing = Instance.new("Part")
			wing.Name = "Wing"
			wing.Size = Vector3.new(0.25, 2.4, 1.5)
			wing.Color = theme.mainColor
			wing.Material = Enum.Material.Neon
			wing.Transparency = 0.22
			wing.CanCollide = false
			wing.Massless = true
			wing.CFrame = CFrame.new(side * 0.95, 0.55, 0.55) * CFrame.Angles(0, side * 0.4, side * 0.3)
			wing.Parent = m

			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = wing
			w.Parent = wing
		end
	end

	-- Layer 3: Upward Rising Energy Column (ParticleEmitter)
	local att = Instance.new("Attachment")
	att.Name = "AuraEmit"
	att.Parent = root

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "ColumnParticles"
	pe.Texture = theme.texture
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.mainColor),
		ColorSequenceKeypoint.new(1, theme.secColor),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.5, 0.65),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	pe.Lifetime = NumberRange.new(0.7, 1.4)
	pe.Rate = if mode == "back" then 16 else 32
	pe.Speed = NumberRange.new(0.6 * theme.speed, 2.0 * theme.speed)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.LightEmission = 0.75
	pe.Parent = att

	-- Layer 4: Orbital Swirling Embers
	local peOrbit = Instance.new("ParticleEmitter")
	peOrbit.Name = "OrbitalEmbers"
	peOrbit.Texture = theme.texture
	peOrbit.Color = ColorSequence.new(theme.secColor)
	peOrbit.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	peOrbit.Lifetime = NumberRange.new(1.0, 1.8)
	peOrbit.Rate = 14
	peOrbit.Speed = NumberRange.new(1.5, 3.0)
	peOrbit.SpreadAngle = Vector2.new(180, 180)
	peOrbit.LightEmission = 0.9
	peOrbit.Parent = att

	return m
end

local function cloneAuraModel(auraId: string): Model?
	local def = AuraConfig.Get(auraId)
	local modelName = AuraModelConfig.GetModelName(auraId)
	local folder = getFolder()
	if folder and modelName then
		local template = folder:FindFirstChild(modelName)
		if template and template:IsA("Model") then
			local clone = template:Clone()
			clone.Name = "Aura_" .. auraId
			sanitize(clone)
			if not clone.PrimaryPart then
				for _, d in clone:GetDescendants() do
					if d:IsA("BasePart") then
						clone.PrimaryPart = d
						break
					end
				end
			end
			normalizeExtent(clone, AuraModelConfig.TargetExtent or 3.5)
			sanitize(clone)
			-- ensure something to weld
			if not clone.PrimaryPart then
				local inv = Instance.new("Part")
				inv.Name = "Root"
				inv.Transparency = 1
				inv.Size = Vector3.new(0.3, 0.3, 0.3)
				inv.CanCollide = false
				inv.Massless = true
				inv.Parent = clone
				clone.PrimaryPart = inv
			end
			return clone
		end
	end
	return makeProcedural(auraId, def)
end

local function applyAuraHighlight(char: Model, rarity: string?)
	local hl = char:FindFirstChild("SM_AuraHighlight") :: Highlight?
	if not rarity then
		if hl then
			hl:Destroy()
		end
		return
	end
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "SM_AuraHighlight"
		hl.Parent = char
	end
	local col = rarityColor(rarity)
	hl.FillColor = col
	hl.OutlineColor = col
	hl.FillTransparency = 0.85
	hl.OutlineTransparency = 0.25
	hl.Enabled = true
end

local function clear()
	if spinConn then
		spinConn:Disconnect()
		spinConn = nil
	end
	if activeModel then
		activeModel:Destroy()
		activeModel = nil
	end
	activeUid = nil
	local char = player.Character
	if char then
		applyAuraHighlight(char, nil)
	end
end

local function ensureFolder(char: Model): Folder
	local f = char:FindFirstChild("SM_AuraVisuals")
	if f and f:IsA("Folder") then
		return f
	end
	local nf = Instance.new("Folder")
	nf.Name = "SM_AuraVisuals"
	nf.Parent = char
	return nf
end

local function attachToCharacter(char: Model, model: Model, auraId: string)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		model:Destroy()
		return
	end
	local folder = ensureFolder(char)
	model.Parent = folder
	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		return
	end

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
		end
	end

	local off = AuraModelConfig.GetOffset(auraId)
	local mode = AuraModelConfig.GetAttachMode(auraId)
	-- Weld primary to HRP with offset
	root.CFrame = hrp.CFrame * CFrame.new(off)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "AuraWeld"
	weld.Part0 = hrp
	weld.Part1 = root
	weld.Parent = root

	-- Keep offset via AlignOrientation-less trick: re-apply Motor6D-like CFrame every frame for feet/back spin
	if mode == "feet" or mode == "hrp" then
		spinConn = RunService.RenderStepped:Connect(function()
			if not model.Parent or not hrp.Parent then
				return
			end
			local bob = math.sin(os.clock() * 1.8) * 0.05
			local yaw = os.clock() * 0.7
			pcall(function()
				-- Move whole model by setting PrimaryPart CFrame relative; weld may fight —
				-- destroy weld and use Pivot follow instead for spin
			end)
		end)
		-- Prefer rigid offset without fighting weld: use Weld with Attachment offsets
		weld:Destroy()
		local a0 = Instance.new("Attachment")
		a0.Name = "AuraA0"
		a0.Position = off
		a0.Parent = hrp
		local a1 = Instance.new("Attachment")
		a1.Name = "AuraA1"
		a1.Parent = root
		local rigid = Instance.new("RigidConstraint")
		rigid.Attachment0 = a0
		rigid.Attachment1 = a1
		rigid.Parent = root
		model:SetAttribute("AuraAttach", a0:GetFullName())
	elseif mode == "back" then
		weld:Destroy()
		local a0 = Instance.new("Attachment")
		a0.Name = "AuraA0"
		a0.Position = off
		a0.Parent = hrp
		local a1 = Instance.new("Attachment")
		a1.Name = "AuraA1"
		a1.Parent = root
		local rigid = Instance.new("RigidConstraint")
		rigid.Attachment0 = a0
		rigid.Attachment1 = a1
		rigid.Parent = root
	end

	-- Slow spin for rings via rotating attachment offset
	if mode == "feet" or mode == "hrp" then
		if spinConn then
			spinConn:Disconnect()
		end
		local a0 = hrp:FindFirstChild("AuraA0")
		spinConn = RunService.RenderStepped:Connect(function()
			if not a0 or not a0.Parent then
				return
			end
			local t = os.clock()
			local base = AuraModelConfig.GetOffset(auraId)
			;(a0 :: Attachment).Position = base + Vector3.new(0, math.sin(t * 2) * 0.06, 0)
			;(a0 :: Attachment).Orientation = Vector3.new(0, (t * 40) % 360, 0)
		end)
	end
end

local function resolveEquipped(profile: any): (string?, string?)
	if not profile then
		return nil, nil
	end
	local uid = profile.equippedAura
	if type(uid) ~= "string" then
		return nil, nil
	end
	for _, a in profile.auras or {} do
		if a.uid == uid then
			return uid, a.id
		end
	end
	return nil, nil
end

function AuraVisual.Refresh(profile: any?)
	lastProfile = profile
	local char = player.Character
	if not profile or not char then
		clear()
		return
	end
	local uid, auraId = resolveEquipped(profile)
	if not uid or not auraId then
		clear()
		return
	end
	if activeUid == uid and activeModel and activeModel.Parent then
		return
	end
	clear()
	local model = cloneAuraModel(auraId)
	if not model then
		return
	end
	activeModel = model
	activeUid = uid
	local def = AuraConfig.Get(auraId)
	local ok, err = pcall(function()
		attachToCharacter(char, model, auraId)
	end)
	if not ok then
		warn("[AuraVisual] attach failed", err)
		clear()
	else
		applyAuraHighlight(char, def and def.rarity)
	end
end

function AuraVisual.Init()
	if charConn then
		return
	end
	charConn = player.CharacterAdded:Connect(function()
		task.defer(function()
			clear()
			if lastProfile then
				AuraVisual.Refresh(lastProfile)
			end
		end)
	end)
	if player.Character and lastProfile then
		AuraVisual.Refresh(lastProfile)
	end
end

function AuraVisual.TryFillInventoryIcon(parent: GuiObject, auraId: string, zIndex: number?): boolean
	local ok, result = pcall(function()
		local existing = parent:FindFirstChild("AuraViewport")
		if existing then
			existing:Destroy()
		end
		local clone = cloneAuraModel(auraId)
		if not clone then
			return false
		end
		for _, d in clone:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		local vf = Instance.new("ViewportFrame")
		vf.Name = "AuraViewport"
		vf.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
		vf.BackgroundTransparency = 0.2
		vf.BorderSizePixel = 0
		vf.Size = UDim2.fromScale(0.78, 0.68)
		vf.Position = UDim2.fromScale(0.5, 0.4)
		vf.AnchorPoint = Vector2.new(0.5, 0.5)
		vf.ZIndex = zIndex or 40
		vf.Active = false
		vf.Ambient = Color3.fromRGB(200, 200, 210)
		vf.LightColor = Color3.fromRGB(255, 255, 255)
		vf.Parent = parent
		local world = Instance.new("WorldModel")
		world.Parent = vf
		clone.Parent = world
		pcall(function()
			clone:PivotTo(CFrame.new())
		end)
		local okBox, bbCf, bbSize = pcall(function()
			return clone:GetBoundingBox()
		end)
		local extent = 1.5
		if okBox and typeof(bbCf) == "CFrame" and typeof(bbSize) == "Vector3" then
			pcall(function()
				clone:TranslateBy(-(bbCf :: CFrame).Position)
			end)
			extent = math.max(bbSize.X, bbSize.Y, bbSize.Z, 0.5)
		end
		local cam = Instance.new("Camera")
		cam.Parent = vf
		vf.CurrentCamera = cam
		local dist = math.clamp(extent * 1.8, 1.5, 14)
		cam.FieldOfView = 32
		cam.CFrame = CFrame.new(Vector3.new(dist * 0.4, dist * 0.5, dist * 0.9), Vector3.zero)
		return true
	end)
	return ok and result == true
end

return AuraVisual
