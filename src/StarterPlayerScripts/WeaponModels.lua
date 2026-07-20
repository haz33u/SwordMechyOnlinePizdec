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

--[[
	Bake / ensure SM_Hilt on PrimaryPart.
	Hilt = end of long axis nearest Tool.Grip (if any), else opposite of "up" bias.
	Attachment CFrame: origin at hilt, LookVector / axes so +Y of attachment ≈ tip direction.
]]
function WeaponModels.EnsureHiltAttachment(model: Model, toolGrip: CFrame?, modelName: string?): Attachment?
	local handle = model.PrimaryPart or findHandlePart(model)
	if not handle then
		return nil
	end
	model.PrimaryPart = handle

	local existing = handle:FindFirstChild(HILT_NAME)
	if existing and existing:IsA("Attachment") then
		return existing
	end
	-- Also search descendants (baked under nested part)
	for _, d in model:GetDescendants() do
		if d:IsA("Attachment") and d.Name == HILT_NAME then
			return d
		end
	end

	local axis, length = longestLocalAxis(handle)
	local half = length * 0.5
	local bias = WeaponModelConfig.HiltEndBias or 0.92
	local along = half * bias

	-- Tip direction along ±axis. Prefer Tool.Grip: grip is near hand → hilt is that end.
	local tipSign = 1
	if toolGrip and toolGrip.Position.Magnitude > 0.01 then
		-- Grip position in tool space is roughly on handle; project onto long axis of part
		-- Tool.Grip.Position is relative to handle when Tool was equipped; after unwrap still useful sign of Y/X/Z
		local g = toolGrip.Position
		local proj = g:Dot(axis)
		-- Hilt is toward grip from center → tip is opposite grip
		if proj > 0 then
			tipSign = -1 -- grip on +axis side → tip on -axis
		else
			tipSign = 1
		end
	else
		-- Default: tip toward +axis (many free swords blade on +Y)
		tipSign = 1
	end

	local overrideName = modelName or model.Name
	-- Strip Weapon_ prefix from clones
	overrideName = string.gsub(overrideName, "^Weapon_", "")
	local ov = WeaponModelConfig.GetOverride(overrideName)
	if ov and ov.flipTip then
		tipSign = -tipSign
	end

	local tipAxis = axis * tipSign
	-- Hilt is opposite tip end
	local hiltLocal = -tipAxis * along

	local att = Instance.new("Attachment")
	att.Name = HILT_NAME
	-- Orient so Attachment.WorldCFrame.UpVector ≈ tip (use Y as blade axis on attachment)
	-- CFrame.lookAt builds -Z forward; we want +Y = tip
	local tip = tipAxis.Unit
	local arb = if math.abs(tip:Dot(Vector3.xAxis)) < 0.9 then Vector3.xAxis else Vector3.zAxis
	local right = tip:Cross(arb)
	if right.Magnitude < 1e-4 then
		right = tip:Cross(Vector3.zAxis)
	end
	right = right.Unit
	local back = right:Cross(tip).Unit
	-- fromMatrix(pos, vX, vY, vZ) columns
	att.CFrame = CFrame.fromMatrix(hiltLocal, right, tip, back)
	att.Parent = handle

	model:SetAttribute("SM_HiltBaked", true)
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

--[[
	Inventory / UI icon: 3D ViewportFrame of WeaponModels mesh.
	Safe for slots: Active=false, full pcall, never throws to parent UI.
	Returns ViewportFrame or nil (caller falls back to IconConfig Decal).
]]
function WeaponModels.FillViewport(parent: GuiObject, weaponId: string, zIndex: number?): ViewportFrame?
	local ok, result = pcall(function()
		local existing = parent:FindFirstChild("WeaponViewport")
		if existing then
			existing:Destroy()
		end

		if not WeaponModels.HasVisual(weaponId) then
			return nil
		end

		local clone, _grip = WeaponModels.PrepareClone(weaponId)
		if not clone then
			return nil
		end

		-- Icon-only: strip any leftover constraints / sounds
		for _, d in clone:GetDescendants() do
			if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("RigidConstraint") or d:IsA("Weld") then
				if d.Name == "SM_WeaponRigid" or d:IsA("BaseScript") or d:IsA("Sound") then
					d:Destroy()
				end
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.CastShadow = false
			end
		end

		local vf = Instance.new("ViewportFrame")
		vf.Name = "WeaponViewport"
		vf.BackgroundTransparency = 1
		vf.BorderSizePixel = 0
		vf.Size = UDim2.fromScale(0.88, 0.88)
		vf.Position = UDim2.fromScale(0.5, 0.5)
		vf.AnchorPoint = Vector2.new(0.5, 0.5)
		vf.ZIndex = zIndex or 36
		vf.Active = false -- clicks pass through to inventory slot button
		vf.Selectable = false
		vf.Ambient = Color3.fromRGB(180, 185, 200)
		vf.LightColor = Color3.fromRGB(255, 250, 240)
		vf.LightDirection = Vector3.new(-0.6, -1, -0.5)
		vf.Parent = parent

		local world = Instance.new("WorldModel")
		world.Parent = vf
		clone.Parent = world

		local okBox, bbCf, bbSize = pcall(function()
			return clone:GetBoundingBox()
		end)
		if not okBox or typeof(bbCf) ~= "CFrame" or typeof(bbSize) ~= "Vector3" then
			clone:Destroy()
			vf:Destroy()
			return nil
		end

		-- Center model at origin, then 3/4 hero angle (icon-friendly)
		local center = (bbCf :: CFrame).Position
		local pivot = clone:GetPivot()
		clone:PivotTo(pivot * CFrame.new(pivot:PointToObjectSpace(center)).Inverse())
		clone:PivotTo(
			CFrame.Angles(0, math.rad(-40), 0)
				* CFrame.Angles(math.rad(18), 0, 0)
				* CFrame.Angles(0, 0, math.rad(-8))
		)

		local ok2, _cf2, size2 = pcall(function()
			return clone:GetBoundingBox()
		end)
		local extent = 1
		if ok2 and typeof(size2) == "Vector3" then
			extent = math.max(size2.X, size2.Y, size2.Z, 0.4)
		end

		local cam = Instance.new("Camera")
		cam.Parent = vf
		vf.CurrentCamera = cam
		local dist = extent * 1.55
		cam.FieldOfView = 28
		cam.CFrame = CFrame.new(Vector3.new(dist * 0.55, dist * 0.28, dist * 0.72), Vector3.zero)

		return vf
	end)

	if ok and result and typeof(result) == "Instance" and result:IsA("ViewportFrame") then
		return result
	end
	return nil
end

--- Inventory helper: 3D mesh icon if available, else false (use IconConfig Image).
function WeaponModels.TryFillInventoryIcon(parent: GuiObject, weaponId: string, zIndex: number?): boolean
	local vf = WeaponModels.FillViewport(parent, weaponId, zIndex)
	return vf ~= nil
end

return WeaponModels
