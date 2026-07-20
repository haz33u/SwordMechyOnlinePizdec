--!strict
--[[
	Client helpers: resolve Place models, strip Tool junk, attach to hand, inventory viewport.
	Source of truth for names: Shared.Config.WeaponModelConfig
	Assets live in ReplicatedStorage.WeaponModels (Studio / Team Create only).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponModelConfig = require(Shared.Config.WeaponModelConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)

local WeaponModels = {}

local folderCache: Folder? = nil

local function getFolder(): Folder?
	if folderCache and folderCache.Parent then
		return folderCache
	end
	local f = ReplicatedStorage:FindFirstChild(WeaponModelConfig.FolderName)
	if f and f:IsA("Folder") then
		folderCache = f
		return f
	end
	return nil
end

function WeaponModels.GetTemplate(weaponId: string): Model?
	local modelName = WeaponModelConfig.GetModelName(weaponId)
	if not modelName then
		return nil
	end
	local folder = getFolder()
	if not folder then
		return nil
	end
	local m = folder:FindFirstChild(modelName)
	if m and m:IsA("Model") then
		return m
	end
	return nil
end

function WeaponModels.HasVisual(weaponId: string): boolean
	return WeaponModels.GetTemplate(weaponId) ~= nil
end

--- Clone free Tool/Model into a clean weld-ready Model. Returns model + Tool.Grip (or identity).
function WeaponModels.PrepareClone(weaponId: string): (Model?, CFrame)
	local template = WeaponModels.GetTemplate(weaponId)
	if not template then
		return nil, CFrame.new()
	end

	local clone = template:Clone()
	clone.Name = "Weapon_" .. WeaponConfig.ResolveId(weaponId)

	local grip = CFrame.new()

	-- Free swords are usually Model → Tool → Handle/Unions
	local tool = clone:FindFirstChildWhichIsA("Tool", true)
	if tool and tool:IsA("Tool") then
		grip = tool.Grip
		for _, ch in tool:GetChildren() do
			if ch:IsA("BaseScript") or ch:IsA("RemoteEvent") or ch:IsA("RemoteFunction") or ch:IsA("Sound") then
				ch:Destroy()
			else
				ch.Parent = clone
			end
		end
		tool:Destroy()
	end

	for _, d in clone:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.Anchored = false
			d.CastShadow = true
		end
	end

	-- Drop empty leftover folders / Accoutrements
	for _, ch in clone:GetChildren() do
		if ch:IsA("Folder") and #ch:GetChildren() == 0 then
			ch:Destroy()
		end
	end

	local handle: BasePart? = nil
	local named = clone:FindFirstChild("Handle", true)
	if named and named:IsA("BasePart") then
		handle = named
	else
		for _, d in clone:GetDescendants() do
			if d:IsA("BasePart") then
				handle = d
				break
			end
		end
	end

	if not handle then
		clone:Destroy()
		return nil, grip
	end

	if handle.Name ~= "Handle" then
		handle.Name = "Handle"
	end
	clone.PrimaryPart = handle

	-- Ensure non-handle parts stay glued (some free assets only use loose unions under Tool)
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") and d ~= handle then
			local welded = false
			for _, c in d:GetChildren() do
				if c:IsA("WeldConstraint") or c:IsA("Weld") or c:IsA("Motor6D") or c:IsA("RigidConstraint") then
					welded = true
					break
				end
			end
			if not welded then
				for _, c in handle:GetChildren() do
					if (c:IsA("WeldConstraint") or c:IsA("Weld")) and ((c :: any).Part1 == d or (c :: any).Part0 == d) then
						welded = true
						break
					end
				end
			end
			if not welded then
				local w = Instance.new("WeldConstraint")
				w.Part0 = handle
				w.Part1 = d
				w.Parent = d
			end
		end
	end

	local scale = WeaponModelConfig.DefaultScale
	if type(scale) == "number" and scale > 0 and scale ~= 1 then
		local okScale = pcall(function()
			(clone :: any):ScaleTo(scale)
		end)
		if okScale then
			-- Tool.Grip was authored pre-scale — shrink translation with the mesh
			local p = grip.Position * scale
			grip = CFrame.new(p) * (grip - grip.Position)
		end
	end

	-- Stash scaled grip for attach
	clone:SetAttribute("SM_GripPX", grip.X)
	clone:SetAttribute("SM_GripPY", grip.Y)
	clone:SetAttribute("SM_GripPZ", grip.Z)

	return clone, grip
end

local function findHand(char: Model, side: string): BasePart?
	if side == "left" then
		local h = char:FindFirstChild("LeftHand")
		if h and h:IsA("BasePart") then
			return h
		end
		local a = char:FindFirstChild("Left Arm")
		if a and a:IsA("BasePart") then
			return a
		end
		return nil
	end
	local h = char:FindFirstChild("RightHand")
	if h and h:IsA("BasePart") then
		return h
	end
	local a = char:FindFirstChild("Right Arm")
	if a and a:IsA("BasePart") then
		return a
	end
	return nil
end

local function findHandGripAttachment(hand: BasePart, side: string): Attachment?
	local name = if side == "left" then "LeftGripAttachment" else "RightGripAttachment"
	local a = hand:FindFirstChild(name)
	if a and a:IsA("Attachment") then
		return a
	end
	return nil
end

local function degAngles(v: Vector3): CFrame
	return CFrame.Angles(math.rad(v.X), math.rad(v.Y), math.rad(v.Z))
end

--- Rotation that maps vector `from` → `to` (both directions).
local function mapVector(from: Vector3, to: Vector3): CFrame
	from = from.Unit
	to = to.Unit
	local dot = from:Dot(to)
	if dot > 0.9999 then
		return CFrame.new()
	end
	if dot < -0.9999 then
		local orth = if math.abs(from.X) < 0.9 then Vector3.xAxis else Vector3.yAxis
		local axis = from:Cross(orth)
		if axis.Magnitude < 1e-4 then
			axis = from:Cross(Vector3.zAxis)
		end
		return CFrame.fromAxisAngle(axis.Unit, math.pi)
	end
	return CFrame.fromAxisAngle(from:Cross(to).Unit, math.acos(math.clamp(dot, -1, 1)))
end

--- Classic sim: blade forward/up when arms hang.
local function forwardHoldC1(handle: BasePart, side: string): CFrame
	local size = handle.Size
	local long = math.max(size.X, size.Y, size.Z)
	local hiltFactor = WeaponModelConfig.ForwardHiltFactor or 0.32
	local hilt = long * hiltFactor
	local deg = if side == "left"
		then (WeaponModelConfig.ForwardLeftAngles or Vector3.new(-90, -90, 0))
		else (WeaponModelConfig.ForwardRightAngles or Vector3.new(-90, 90, 0))
	return CFrame.new(0, hilt, 0) * degAngles(deg)
end

--[[
	Minecraft third-person item hold:
	  Arm raised (READY). Point free-sword long axis (+Y) along BladeDir in grip space
	  so the tip goes UP/OUT — not into the chest (see screenshot 193836).
]]
local function minecraftHoldC1(handle: BasePart, side: string): CFrame
	local size = handle.Size
	local long = math.max(size.X, size.Y, size.Z)
	local hiltFactor = WeaponModelConfig.MinecraftHiltFactor or 0.12
	local hilt = long * hiltFactor
	local isLeft = side == "left"

	local dir = if isLeft
		then (WeaponModelConfig.MinecraftBladeDirLeft or Vector3.new(-0.25, 1, -0.55))
		else (WeaponModelConfig.MinecraftBladeDirRight or Vector3.new(0.25, 1, -0.55))
	if dir.Magnitude < 1e-3 then
		dir = Vector3.new(0, 1, -0.4)
	end
	dir = dir.Unit

	local off = if isLeft
		then (WeaponModelConfig.MinecraftLeftOffset or Vector3.zero)
		else (WeaponModelConfig.MinecraftRightOffset or Vector3.zero)

	-- Free meshes: tip usually +Y; FlipBlade* reverses (tip was backward on right hand)
	local flip = if isLeft then WeaponModelConfig.MinecraftFlipBladeLeft else WeaponModelConfig.MinecraftFlipBladeRight
	local meshTip = if flip then -Vector3.yAxis else Vector3.yAxis

	-- C1:Inverse() maps meshTip → dir  ⇒  C1 maps dir → meshTip
	local rot = mapVector(dir, meshTip)
	-- Hilt offset along mesh tip axis (into the handle)
	local hiltOffset = meshTip * hilt
	return CFrame.new(off) * CFrame.new(hiltOffset) * rot
end

--[[
	Weld like Roblox Tools on R15:
	  Part0 = Hand, C0 = Right/LeftGripAttachment.CFrame
	  Part1 = Handle, C1 = hold pose
]]
function WeaponModels.AttachToHand(model: Model, char: Model, side: string, grip: CFrame)
	local handle = model.PrimaryPart
	if not handle then
		return
	end
	local hand = findHand(char, side)
	if not hand then
		return
	end

	for _, c in handle:GetChildren() do
		if c.Name == "SM_WeaponWeld" then
			c:Destroy()
		elseif c:IsA("Weld") and (c :: Weld).Part0 == hand then
			c:Destroy()
		end
	end

	local gripAtt = findHandGripAttachment(hand, side)
	local isLeft = side == "left"
	local tune = if isLeft then WeaponModelConfig.HoldTuneLeft else WeaponModelConfig.HoldTuneRight
	if typeof(tune) ~= "CFrame" then
		tune = CFrame.new()
	end

	local weld = Instance.new("Weld")
	weld.Name = "SM_WeaponWeld"
	weld.Part0 = hand
	weld.Part1 = handle

	if gripAtt then
		weld.C0 = gripAtt.CFrame
	else
		weld.C0 = CFrame.new(0, -0.15, 0)
	end

	local mode = WeaponModelConfig.HoldMode or "minecraft"
	local c1: CFrame
	local hasToolGrip = typeof(grip) == "CFrame" and grip.Position.Magnitude > 0.05
	if mode == "tool" and hasToolGrip then
		c1 = grip
	elseif mode == "forward" then
		c1 = forwardHoldC1(handle, side)
	else
		-- default minecraft
		c1 = minecraftHoldC1(handle, side)
	end
	weld.C1 = c1 * tune
	weld.Parent = handle
end

--- Fill a parent GuiObject with a ViewportFrame preview of the weapon model.
function WeaponModels.FillViewport(parent: GuiObject, weaponId: string, zIndex: number?): ViewportFrame?
	local existing = parent:FindFirstChild("WeaponViewport")
	if existing then
		existing:Destroy()
	end

	local clone, _grip = WeaponModels.PrepareClone(weaponId)
	if not clone then
		return nil
	end

	local vf = Instance.new("ViewportFrame")
	vf.Name = "WeaponViewport"
	vf.BackgroundTransparency = 1
	vf.BorderSizePixel = 0
	vf.Size = UDim2.fromScale(0.86, 0.86)
	vf.Position = UDim2.fromScale(0.5, 0.48)
	vf.AnchorPoint = Vector2.new(0.5, 0.5)
	vf.ZIndex = zIndex or 36
	vf.Ambient = Color3.fromRGB(200, 200, 210)
	vf.LightColor = Color3.fromRGB(255, 255, 255)
	vf.LightDirection = Vector3.new(-0.5, -1, -0.4)
	vf.Parent = parent

	local world = Instance.new("WorldModel")
	world.Parent = vf
	clone.Parent = world

	-- Center model at origin, camera on a soft 3/4 angle
	local okBox, bbCf, bbSize = pcall(function()
		return clone:GetBoundingBox()
	end)
	if not okBox or typeof(bbCf) ~= "CFrame" or typeof(bbSize) ~= "Vector3" then
		clone:Destroy()
		vf:Destroy()
		return nil
	end

	local center = (bbCf :: CFrame).Position
	clone:PivotTo(clone:GetPivot() * CFrame.new(clone:GetPivot():PointToObjectSpace(center)).Inverse())
	clone:PivotTo(CFrame.Angles(0, math.rad(-35), 0) * CFrame.Angles(math.rad(12), 0, 0))

	local _, size2 = clone:GetBoundingBox()
	local extent = math.max(size2.X, size2.Y, size2.Z, 0.5)
	local cam = Instance.new("Camera")
	cam.Parent = vf
	vf.CurrentCamera = cam
	local dist = extent * 1.45
	cam.CFrame = CFrame.new(Vector3.new(dist * 0.55, dist * 0.2, dist * 0.7), Vector3.zero)
	cam.FieldOfView = 32

	return vf
end

return WeaponModels
