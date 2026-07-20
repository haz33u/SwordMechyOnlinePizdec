--!strict
--[[
	Place weapon models + systematic hilt attach.

	Contract:
	  Attachment "SM_Hilt" on PrimaryPart = palm on HANDLE (not mid-blade).
	  Axis of SM_Hilt: WorldAxis that points toward blade TIP.
	  Hand: RightGripAttachment / LeftGripAttachment
	  Link: RigidConstraint

	If SM_Hilt missing → EnsureHiltAttachment() bakes it (longest axis + Tool.Grip heuristic).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponModelConfig = require(Shared.Config.WeaponModelConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)

local WeaponModels = {}

local HILT_NAME = WeaponModelConfig.HiltAttachmentName or "SM_Hilt"
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

local function findHandlePart(root: Instance): BasePart?
	local named = root:FindFirstChild("Handle", true)
	if named and named:IsA("BasePart") then
		return named
	end
	local best: BasePart? = nil
	local bestVol = -1
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			local s = d.Size
			local vol = s.X * s.Y * s.Z
			if vol > bestVol then
				bestVol = vol
				best = d
			end
		end
	end
	return best
end

local function weldLooseParts(handle: BasePart, root: Instance)
	for _, d in root:GetDescendants() do
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
end

--- Longest local axis of a part as unit Vector3 in part space.
local function longestLocalAxis(part: BasePart): (Vector3, number)
	local s = part.Size
	if s.Y >= s.X and s.Y >= s.Z then
		return Vector3.yAxis, s.Y
	elseif s.X >= s.Y and s.X >= s.Z then
		return Vector3.xAxis, s.X
	end
	return Vector3.zAxis, s.Z
end

local function orientHiltAttachment(att: Attachment, hiltLocal: Vector3, tipDir: Vector3)
	local tip = tipDir.Unit
	local arb = if math.abs(tip:Dot(Vector3.xAxis)) < 0.9 then Vector3.xAxis else Vector3.zAxis
	local right = tip:Cross(arb)
	if right.Magnitude < 1e-4 then
		right = tip:Cross(Vector3.zAxis)
	end
	right = right.Unit
	local back = right:Cross(tip).Unit
	att.CFrame = CFrame.fromMatrix(hiltLocal, right, tip, back)
end

--[[
	Bake / ensure SM_Hilt on PrimaryPart. Always recomputes CFrame.
	Palm = handle end; attachment +Y = tip.
]]
function WeaponModels.EnsureHiltAttachment(model: Model, toolGrip: CFrame?, modelName: string?): Attachment?
	local handle = model.PrimaryPart or findHandlePart(model)
	if not handle then
		return nil
	end
	model.PrimaryPart = handle

	local att: Attachment? = nil
	local existing = handle:FindFirstChild(HILT_NAME)
	if existing and existing:IsA("Attachment") then
		att = existing
	else
		for _, d in model:GetDescendants() do
			if d:IsA("Attachment") and d.Name == HILT_NAME then
				att = d
				break
			end
		end
	end
	if not att then
		att = Instance.new("Attachment")
		att.Name = HILT_NAME
		att.Parent = handle
	end

	local ov = WeaponModelConfig.ResolveOverride(modelName or model.Name)
	-- length is POST-ScaleTo (call EnsureHilt only after scale)
	local axis, length = longestLocalAxis(handle)
	local half = length * 0.5

	local bias = WeaponModelConfig.HiltEndBias or 0.96
	if ov and type(ov.hiltBias) == "number" then
		bias = math.clamp(ov.hiltBias, 0.55, 0.995)
	end
	local along = half * bias

	local hiltLocal: Vector3
	local tipDir: Vector3

	if ov and typeof(ov.hiltPosition) == "Vector3" then
		-- Rare absolute (must already be in post-scale local space)
		hiltLocal = ov.hiltPosition
		tipDir = if ov.tipDirection and typeof(ov.tipDirection) == "Vector3" and ov.tipDirection.Magnitude > 0.01
			then ov.tipDirection.Unit
			else (-hiltLocal).Unit
	else
		-- hiltEnd: which geometric end is the HANDLE (+1 / -1 along long axis)
		local hiltEnd = 1
		if ov and type(ov.hiltEnd) == "number" and ov.hiltEnd ~= 0 then
			hiltEnd = if ov.hiltEnd > 0 then 1 else -1
		elseif ov and type(ov.tipSign) == "number" and ov.tipSign ~= 0 then
			-- tipSign = tip dir; handle is opposite
			hiltEnd = if ov.tipSign > 0 then -1 else 1
		elseif toolGrip and toolGrip.Position.Magnitude > 0.01 then
			local proj = toolGrip.Position:Dot(axis)
			hiltEnd = if proj >= 0 then 1 else -1
		end
		if ov and ov.flipTip then
			hiltEnd = -hiltEnd
		end

		hiltLocal = axis * (along * hiltEnd)
		tipDir = -axis * hiltEnd
	end

	orientHiltAttachment(att, hiltLocal, tipDir)

	model:SetAttribute("SM_HiltBaked", true)
	print(string.format(
		"[WeaponModels] grip v3 %s hiltLocal=%s tip=%s len=%.2f",
		modelName or model.Name,
		tostring(hiltLocal),
		tostring(tipDir),
		length
	))
	return att
end

--- Clone free Tool/Model into a clean weld-ready Model. Returns model + original Tool.Grip (scaled).
function WeaponModels.PrepareClone(weaponId: string): (Model?, CFrame)
	local template = WeaponModels.GetTemplate(weaponId)
	if not template then
		return nil, CFrame.new()
	end

	local modelName = template.Name
	local clone = template:Clone()
	clone.Name = "Weapon_" .. WeaponConfig.ResolveId(weaponId)

	local grip = CFrame.new()

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

	for _, ch in clone:GetChildren() do
		if ch:IsA("Folder") and #ch:GetChildren() == 0 then
			ch:Destroy()
		end
	end

	local handle = findHandlePart(clone)
	if not handle then
		clone:Destroy()
		return nil, grip
	end
	if handle.Name ~= "Handle" then
		handle.Name = "Handle"
	end
	clone.PrimaryPart = handle
	weldLooseParts(handle, clone)

	local scale = WeaponModelConfig.DefaultScale
	if type(scale) == "number" and scale > 0 and scale ~= 1 then
		local okScale = pcall(function()
			(clone :: any):ScaleTo(scale)
		end)
		if okScale then
			local p = grip.Position * scale
			grip = CFrame.new(p) * (grip - grip.Position)
		end
	end

	-- Bake hilt on this clone (uses scaled mesh + scaled grip)
	WeaponModels.EnsureHiltAttachment(clone, grip, modelName)

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

--- Attach prepared model: palm GripAttachment ↔ SM_Hilt (RigidConstraint).
function WeaponModels.AttachToHand(model: Model, char: Model, side: string, grip: CFrame)
	local handle = model.PrimaryPart or findHandlePart(model)
	if not handle then
		return
	end
	local hand = findHand(char, side)
	if not hand then
		return
	end

	-- Clean old links
	for _, c in handle:GetChildren() do
		if c.Name == "SM_WeaponWeld" or c.Name == "SM_WeaponRigid" then
			c:Destroy()
		end
	end

	local hilt = WeaponModels.EnsureHiltAttachment(model, grip, model.Name)
	if not hilt then
		warn("[WeaponModels] no SM_Hilt for", model.Name)
		return
	end

	local gripAtt = findHandGripAttachment(hand, side)
	if not gripAtt then
		gripAtt = Instance.new("Attachment")
		gripAtt.Name = if side == "left" then "LeftGripAttachment" else "RightGripAttachment"
		gripAtt.Position = Vector3.new(0, -0.1, 0)
		gripAtt.Parent = hand
	end

	-- Clean previous attach helpers
	for _, c in hand:GetChildren() do
		if c:IsA("Attachment") and c.Name == "SM_PalmOffset" then
			c:Destroy()
		end
	end
	for _, c in handle:GetChildren() do
		if c:IsA("Attachment") and c.Name == "SM_HiltRoll" then
			c:Destroy()
		end
	end

	local isLeft = side == "left"
	local off = if isLeft then WeaponModelConfig.PalmOffsetLeft else WeaponModelConfig.PalmOffsetRight
	if typeof(off) ~= "Vector3" then
		off = Vector3.zero
	end
	local tilt = if isLeft then WeaponModelConfig.PalmTiltLeft else WeaponModelConfig.PalmTiltRight
	if typeof(tilt) ~= "Vector3" then
		tilt = Vector3.zero
	end
	local bladeRoll = if isLeft then WeaponModelConfig.BladeRollLeft else WeaponModelConfig.BladeRollRight
	if type(bladeRoll) ~= "number" then
		bladeRoll = 0
	end

	-- 1) Palm: position (+ optional tiny tilt). NOT for spinning the blade flat/edge.
	local palmAtt = Instance.new("Attachment")
	palmAtt.Name = "SM_PalmOffset"
	palmAtt.CFrame = gripAtt.CFrame
		* CFrame.new(off)
		* CFrame.Angles(math.rad(tilt.X), math.rad(tilt.Y), math.rad(tilt.Z))
	palmAtt.Parent = hand

	-- 2) Blade roll around SWORD axis: SM_Hilt +Y = tip → rotate around local Y only.
	--    Studio “Rotate” around the blade = this slider (BladeRollRight / Left).
	local hiltRoll = Instance.new("Attachment")
	hiltRoll.Name = "SM_HiltRoll"
	hiltRoll.CFrame = hilt.CFrame * CFrame.Angles(0, math.rad(bladeRoll), 0)
	hiltRoll.Parent = handle

	local rigid = Instance.new("RigidConstraint")
	rigid.Name = "SM_WeaponRigid"
	rigid.Attachment0 = palmAtt
	rigid.Attachment1 = hiltRoll
	rigid.Parent = handle
end

--- Lightweight clone for UI icons (no hilt bake). Resets world pose so RS pivot is not at -200,0,0.
local function prepareIconClone(weaponId: string): Model?
	local template = WeaponModels.GetTemplate(weaponId)
	if not template then
		return nil
	end
	local clone = template:Clone()
	clone.Name = "Icon_" .. weaponId

	-- Flatten Tool wrappers
	local tools = {}
	for _, d in clone:GetDescendants() do
		if d:IsA("Tool") then
			table.insert(tools, d)
		end
	end
	for _, tool in tools do
		for _, ch in tool:GetChildren() do
			ch.Parent = clone
		end
		tool:Destroy()
	end

	-- Flatten one level of nested Models (e.g. SupeSport → blue rose)
	local nested = {}
	for _, ch in clone:GetChildren() do
		if ch:IsA("Model") then
			table.insert(nested, ch)
		end
	end
	for _, nest in nested do
		for _, ch in nest:GetChildren() do
			ch.Parent = clone
		end
		nest:Destroy()
	end

	for _, d in clone:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
			d:Destroy()
		end
	end

	local handle = findHandlePart(clone)
	if not handle then
		clone:Destroy()
		return nil
	end
	clone.PrimaryPart = handle
	weldLooseParts(handle, clone)

	-- Unanchor briefly so we can re-pivot from RS world coords, then re-anchor
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.CastShadow = false
		end
	end

	-- CRITICAL: Place models often sit at huge WorldPivots; put pivot at origin first
	pcall(function()
		clone:PivotTo(CFrame.new())
	end)

	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end

	clone:SetAttribute("IconTemplateName", template.Name)
	return clone
end

--- Align PrimaryPart longest axis to world +Y (tip up), using hiltEnd/tip from override when set.
local function orientTipUp(clone: Model)
	local handle = clone.PrimaryPart
	if not handle then
		return
	end
	local axis, _len = longestLocalAxis(handle)
	-- World direction of local long axis
	local worldAxis = handle.CFrame:VectorToWorldSpace(axis).Unit
	-- Prefer tip opposite handle end from override
	local templateName = clone:GetAttribute("IconTemplateName")
	local ov = if type(templateName) == "string" then WeaponModelConfig.ResolveOverride(templateName) else nil
	local tipWorld = worldAxis
	if ov and type(ov.hiltEnd) == "number" and ov.hiltEnd ~= 0 then
		-- handle along +axis * hiltEnd in local → tip is opposite in world
		local handleLocal = axis * (if ov.hiltEnd > 0 then 1 else -1)
		tipWorld = handle.CFrame:VectorToWorldSpace(-handleLocal).Unit
	elseif worldAxis:Dot(Vector3.yAxis) < 0 then
		tipWorld = -worldAxis
	end
	-- Rotation that maps tipWorld → +Y
	local from = tipWorld
	local to = Vector3.yAxis
	local dot = math.clamp(from:Dot(to), -1, 1)
	if dot > 0.999 then
		return
	end
	local rot: CFrame
	if dot < -0.999 then
		local orth = if math.abs(from.X) < 0.9 then Vector3.xAxis else Vector3.zAxis
		rot = CFrame.fromAxisAngle(from:Cross(orth).Unit, math.pi)
	else
		rot = CFrame.fromAxisAngle(from:Cross(to).Unit, math.acos(dot))
	end
	clone:PivotTo(rot * clone:GetPivot())
end

local function frameModelInViewport(clone: Model, cam: Camera)
	-- 1) Center at origin
	local okBox, bbCf, bbSize = pcall(function()
		return clone:GetBoundingBox()
	end)
	local extent = 1.5
	if okBox and typeof(bbCf) == "CFrame" and typeof(bbSize) == "Vector3" then
		pcall(function()
			clone:TranslateBy(-(bbCf :: CFrame).Position)
		end)
		extent = math.max(bbSize.X, bbSize.Y, bbSize.Z, 0.35)
	elseif clone.PrimaryPart then
		pcall(function()
			clone:TranslateBy(-clone.PrimaryPart.Position)
		end)
		local s = clone.PrimaryPart.Size
		extent = math.max(s.X, s.Y, s.Z, 0.35)
	end

	-- 2) Auto tip-up (align long axis with +Y)
	pcall(function()
		orientTipUp(clone)
	end)

	-- 3) iconInvert / iconEuler AFTER tip-up (hand grip does not use these)
	local templateName = clone:GetAttribute("IconTemplateName")
	local ov = if type(templateName) == "string" then WeaponModelConfig.ResolveOverride(templateName) else nil
	if ov then
		if ov.iconInvert then
			-- 180° around X → flips upside-down inventory previews
			pcall(function()
				clone:PivotTo(CFrame.Angles(math.rad(180), 0, 0) * clone:GetPivot())
			end)
		end
		if typeof(ov.iconEuler) == "Vector3" then
			local e = ov.iconEuler
			pcall(function()
				clone:PivotTo(CFrame.Angles(math.rad(e.X), math.rad(e.Y), math.rad(e.Z)) * clone:GetPivot())
			end)
		end
	end

	-- 4) Showcase yaw only
	pcall(function()
		clone:PivotTo(CFrame.Angles(0, math.rad(-35), 0) * clone:GetPivot())
	end)

	-- 5) Re-center + uniform fill scale (small swords get bigger)
	local ok2, bb2, size2 = pcall(function()
		return clone:GetBoundingBox()
	end)
	if ok2 and typeof(bb2) == "CFrame" then
		pcall(function()
			clone:TranslateBy(-(bb2 :: CFrame).Position)
		end)
	end
	if ok2 and typeof(size2) == "Vector3" then
		extent = math.max(size2.X, size2.Y, size2.Z, 0.35)
	end

	local target = WeaponModelConfig.IconTargetExtent or 2.4
	if extent > 0.01 and math.abs(extent - target) > 0.05 then
		local factor = target / extent
		factor = math.clamp(factor, 0.25, 4)
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
		local ok3, bb3, size3 = pcall(function()
			return clone:GetBoundingBox()
		end)
		if ok3 and typeof(bb3) == "CFrame" then
			pcall(function()
				clone:TranslateBy(-(bb3 :: CFrame).Position)
			end)
		end
		if ok3 and typeof(size3) == "Vector3" then
			extent = math.max(size3.X, size3.Y, size3.Z, 0.35)
		end
	end

	-- 6) Camera
	local dist = math.clamp(extent * 1.85, 1.8, 12)
	cam.FieldOfView = 30
	cam.CFrame = CFrame.new(Vector3.new(dist * 0.5, dist * 0.3, dist * 0.85), Vector3.zero)
end

--[[
	Inventory / UI icon: 3D ViewportFrame of WeaponModels mesh.
	Safe for slots: Active=false, full pcall, never throws to parent UI.
]]
function WeaponModels.FillViewport(parent: GuiObject, weaponId: string, zIndex: number?): ViewportFrame?
	local ok, result = pcall(function()
		local existing = parent:FindFirstChild("WeaponViewport")
		if existing then
			existing:Destroy()
		end

		if not WeaponModels.HasVisual(weaponId) then
			return nil :: any
		end

		local clone = prepareIconClone(weaponId)
		if not clone then
			warn("[WeaponModels] icon clone failed for", weaponId)
			return nil
		end

		local vf = Instance.new("ViewportFrame")
		vf.Name = "WeaponViewport"
		vf.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
		vf.BackgroundTransparency = 0.15 -- slight plate so empty vs filled is obvious while tuning
		vf.BorderSizePixel = 0
		vf.Size = UDim2.fromScale(0.92, 0.92)
		vf.Position = UDim2.fromScale(0.5, 0.5)
		vf.AnchorPoint = Vector2.new(0.5, 0.5)
		vf.ZIndex = zIndex or 40
		vf.Active = false
		vf.Selectable = false
		vf.Ambient = Color3.fromRGB(200, 200, 210)
		vf.LightColor = Color3.fromRGB(255, 255, 255)
		vf.LightDirection = Vector3.new(-1, -1, -0.5)
		vf:SetAttribute("WeaponId", weaponId)
		vf.Parent = parent

		local world = Instance.new("WorldModel")
		world.Name = "IconWorld"
		world.Parent = vf
		clone.Parent = world

		local cam = Instance.new("Camera")
		cam.Name = "IconCamera"
		cam.Parent = vf
		vf.CurrentCamera = cam

		frameModelInViewport(clone, cam)

		-- Re-apply camera next frame (fixes rare first-frame empty ViewportFrame)
		task.defer(function()
			if not vf.Parent or not clone.Parent then
				return
			end
			vf.CurrentCamera = cam
			pcall(function()
				frameModelInViewport(clone, cam)
			end)
		end)

		return vf
	end)

	if not ok then
		warn("[WeaponModels] FillViewport error for", weaponId, result)
		return nil
	end
	if result and typeof(result) == "Instance" and (result :: Instance):IsA("ViewportFrame") then
		return result :: ViewportFrame
	end
	return nil
end

--- true = 3D icon shown; false = caller may use static Decal (only if no mesh).
function WeaponModels.TryFillInventoryIcon(parent: GuiObject, weaponId: string, zIndex: number?): boolean
	if not WeaponModels.HasVisual(weaponId) then
		return false
	end
	local vf = WeaponModels.FillViewport(parent, weaponId, zIndex or 40)
	if vf then
		return true
	end
	warn("[WeaponModels] 3D icon failed for", weaponId, "— check WeaponModels folder + model name map")
	return false
end

return WeaponModels
