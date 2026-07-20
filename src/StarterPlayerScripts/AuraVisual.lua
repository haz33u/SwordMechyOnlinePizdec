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

local function sanitize(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.Anchored = false
			d.CastShadow = false
		elseif d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ForceField") then
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

local function makeProcedural(auraId: string, def: any?): Model
	local m = Instance.new("Model")
	m.Name = "AuraProc_" .. auraId
	local rar = (def and def.rarity) or "Common"
	local col = rarityColor(rar)
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

	if mode == "feet" or mode == "hrp" then
		local ring = Instance.new("Part")
		ring.Name = "Ring"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.2, 3.2, 3.2)
		ring.CFrame = CFrame.Angles(0, 0, math.rad(90))
		ring.Color = col
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.45
		ring.CanCollide = false
		ring.Massless = true
		ring.Anchored = false
		ring.Parent = m
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = ring
		w.Parent = ring
	end

	if mode == "back" then
		for _, side in { -1, 1 } do
			local wing = Instance.new("Part")
			wing.Name = "Wing"
			wing.Size = Vector3.new(0.25, 2.2, 1.4)
			wing.Color = col
			wing.Material = Enum.Material.Neon
			wing.Transparency = 0.25
			wing.CanCollide = false
			wing.Massless = true
			wing.CFrame = CFrame.new(side * 0.9, 0.5, 0.5) * CFrame.Angles(0, side * 0.4, side * 0.3)
			wing.Parent = m
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = wing
			w.Parent = wing
		end
	end

	local att = Instance.new("Attachment")
	att.Name = "AuraEmit"
	att.Parent = root
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(col)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Rate = if mode == "back" then 12 else 28
	pe.Speed = NumberRange.new(0.4, 1.5)
	pe.SpreadAngle = Vector2.new(40, 40)
	pe.LightEmission = 0.6
	pe.Parent = att

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
	local ok, err = pcall(function()
		attachToCharacter(char, model, auraId)
	end)
	if not ok then
		warn("[AuraVisual] attach failed", err)
		clear()
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
