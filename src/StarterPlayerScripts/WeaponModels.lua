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

	-- Grip → same hiltEnd as hands (icon tip-up must match hold, not "higher world end")
	local tool = template:FindFirstChildWhichIsA("Tool", true)
	local gripHiltEnd: number? = nil
	if tool and tool:IsA("Tool") then
		local gp = tool.Grip.Position
		if gp.Magnitude > 0.01 then
			local axis0 = longestLocalAxis(handle)
			local proj = gp:Dot(axis0)
			if math.abs(proj) > 0.01 then
				gripHiltEnd = if proj >= 0 then 1 else -1
			end
		end
	end
	-- Also read from already-cloned Tool before flatten (if still present)
	if gripHiltEnd == nil then
		local cloneTool = clone:FindFirstChildWhichIsA("Tool", true)
		if cloneTool and cloneTool:IsA("Tool") then
			local gp = cloneTool.Grip.Position
			if gp.Magnitude > 0.01 then
				local axis0 = longestLocalAxis(handle)
				local proj = gp:Dot(axis0)
				if math.abs(proj) > 0.01 then
					gripHiltEnd = if proj >= 0 then 1 else -1
				end
			end
		end
	end

	clone:SetAttribute("IconTemplateName", template.Name)
	if gripHiltEnd then
		clone:SetAttribute("IconHiltEnd", gripHiltEnd)
	end
	return clone
end

--- Align PrimaryPart longest axis to world +Y (tip up).
--- Prefer override.hiltEnd, then IconHiltEnd from Tool.Grip (same as hand).
--- Fallback "higher end = tip" is WRONG for many toolbox meshes (e.g. IronSword hangs tip-down).
local function orientTipUp(clone: Model)
	local handle = clone.PrimaryPart
	if not handle then
		return
	end
	local axis, _len = longestLocalAxis(handle)
	local worldAxis = handle.CFrame:VectorToWorldSpace(axis).Unit

	local templateName = clone:GetAttribute("IconTemplateName")
	local ov = if type(templateName) == "string" then WeaponModelConfig.ResolveOverride(templateName) else nil

	local hiltEnd: number? = nil
	if ov and type(ov.hiltEnd) == "number" and ov.hiltEnd ~= 0 then
		hiltEnd = if ov.hiltEnd > 0 then 1 else -1
	else
		local attr = clone:GetAttribute("IconHiltEnd")
		if type(attr) == "number" and attr ~= 0 then
			hiltEnd = if attr > 0 then 1 else -1
		end
	end

	local tipWorld: Vector3
	if hiltEnd then
		-- tip is opposite handle end (same convention as EnsureHiltAttachment)
		local handleLocal = axis * hiltEnd
		tipWorld = handle.CFrame:VectorToWorldSpace(-handleLocal).Unit
	else
		-- Last resort: whichever long-axis end is currently higher
		tipWorld = worldAxis
		if worldAxis:Dot(Vector3.yAxis) < 0 then
			tipWorld = -worldAxis
		end
	end

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

local function resolveIconOverride(clone: Model): any
	local templateName = clone:GetAttribute("IconTemplateName")
	if type(templateName) ~= "string" then
		return nil
	end
	return WeaponModelConfig.ResolveOverride(templateName)
end

local function measureIconBb(clone: Model): (number, number, number)
	-- height Y, lateral max(X,Z), half-diagonal of AABB
	local ok, _, size = pcall(function()
		return clone:GetBoundingBox()
	end)
	if ok and typeof(size) == "Vector3" then
		local h = math.max(size.Y, 0.15)
		local lat = math.max(size.X, size.Z, 0.02)
		local halfDiag = size.Magnitude * 0.5
		return h, lat, halfDiag
	end
	return 1.5, 0.4, 1.0
end

local function getStoredIconFit(clone: Model): (number, number, number)
	local h = clone:GetAttribute("IconFitH")
	local lat = clone:GetAttribute("IconFitW")
	local diag = clone:GetAttribute("IconFitDiag")
	if type(h) == "number" and type(lat) == "number" and h > 0 and lat > 0 then
		local d = if type(diag) == "number" and diag > 0 then diag else math.max(h, lat)
		return h, lat, d
	end
	return measureIconBb(clone)
end

--- Icon-only: enlarge needle meshes so they are readable (does not affect world hand scale).
local function ensureIconLateralThickness(clone: Model)
	local floor = WeaponModelConfig.IconMinLateralStuds or 0.48
	local maxMult = WeaponModelConfig.IconLateralScaleMax or 4.5
	if floor <= 0 then
		return
	end
	local _h, lat, _d = measureIconBb(clone)
	if lat >= floor * 0.98 then
		return
	end
	local factor = math.clamp(floor / math.max(lat, 0.02), 1, maxMult)
	if factor <= 1.02 then
		return
	end
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
	-- Re-center after scale
	local ok, bb = pcall(function()
		local c, _s = clone:GetBoundingBox()
		return c
	end)
	if ok and typeof(bb) == "CFrame" then
		pcall(function()
			clone:TranslateBy(-(bb :: CFrame).Position)
		end)
	end
end

--[[
	ONE icon card camera: fit HEIGHT only.
	Thin blades are thickened via icon-only ScaleTo (not near-clip zoom).
	Near-clip guard prevents black/white face squares (Ardite bug).
]]
local function applyIconCamera(clone: Model, cam: Camera)
	local height, _lat, halfDiag = getStoredIconFit(clone)

	local fov = WeaponModelConfig.IconFov or 28
	local fillH = math.clamp(WeaponModelConfig.IconFillHeight or 0.82, 0.4, 0.95)
	local dMin = WeaponModelConfig.IconDistMin or 1.2
	local dMax = WeaponModelConfig.IconDistMax or 16
	local nearFac = WeaponModelConfig.IconNearClipFactor or 1.2

	local halfTan = math.tan(math.rad(fov * 0.5))
	if halfTan < 1e-4 then
		halfTan = 0.25
	end

	-- height = fillH * (2 * dist * tan)  →  dist = height / (2 * fillH * tan)
	local dist = height / (2 * fillH * halfTan)
	-- Stay outside the mesh (fixes black/white square when camera sat on a face)
	local nearFloor = math.max(dMin, halfDiag * nearFac)
	dist = math.clamp(math.max(dist, nearFloor), dMin, dMax)

	local dir = WeaponModelConfig.IconCamDir
	if typeof(dir) ~= "Vector3" or dir.Magnitude < 0.01 then
		dir = Vector3.new(0.55, 0.22, 0.85)
	end
	dir = dir.Unit

	cam.FieldOfView = fov
	cam.CFrame = CFrame.new(dir * dist, Vector3.zero)
end

local function frameModelInViewport(clone: Model, cam: Camera)
	-- Idempotent: re-entry only rebinds camera (never re-applies invert/yaw)
	if clone:GetAttribute("IconFramed") == true then
		applyIconCamera(clone, cam)
		return
	end

	-- 1) Center at origin
	local okBox, bbCf = pcall(function()
		local c, _s = clone:GetBoundingBox()
		return c
	end)
	if okBox and typeof(bbCf) == "CFrame" then
		pcall(function()
			clone:TranslateBy(-(bbCf :: CFrame).Position)
		end)
	elseif clone.PrimaryPart then
		pcall(function()
			clone:TranslateBy(-clone.PrimaryPart.Position)
		end)
	end

	-- 2) Tip-up (hiltEnd / Tool.Grip)
	pcall(function()
		orientTipUp(clone)
	end)

	-- 3) Rare flip overrides (inventory only — one bit per mesh)
	local ov = resolveIconOverride(clone)
	if ov then
		if ov.iconInvert then
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

	-- 4) Fixed showcase yaw (same for every sword)
	local yaw = WeaponModelConfig.IconYawDeg or -35
	pcall(function()
		clone:PivotTo(CFrame.Angles(0, math.rad(yaw), 0) * clone:GetPivot())
	end)

	-- 5) Re-center
	local ok2, bb2 = pcall(function()
		local c, _s = clone:GetBoundingBox()
		return c
	end)
	if ok2 and typeof(bb2) == "CFrame" then
		pcall(function()
			clone:TranslateBy(-(bb2 :: CFrame).Position)
		end)
	end

	-- 6) Icon-only lateral thicken (needles → readable cards; no camera dive)
	ensureIconLateralThickness(clone)

	-- 7) Store fit dims + camera
	local h, lat, halfDiag = measureIconBb(clone)
	clone:SetAttribute("IconFitH", h)
	clone:SetAttribute("IconFitW", lat)
	clone:SetAttribute("IconFitDiag", halfDiag)
	clone:SetAttribute("IconFramed", true)

	applyIconCamera(clone, cam)
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

		-- Re-bind camera next frame only (do NOT re-frame: invert/yaw would apply twice and cancel)
		task.defer(function()
			if not vf.Parent or not cam.Parent then
				return
			end
			vf.CurrentCamera = cam
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
