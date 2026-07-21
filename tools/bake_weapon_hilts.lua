--!nocheck
--[[
	STUDIO COMMAND BAR / Edit-mode paste script (NOT a Rojo ModuleScript).

	Bake Attachment "SM_Hilt" on every ReplicatedStorage.WeaponModels child.

	Usage:
	  1. Stop Play (Edit mode)
	  2. View → Command Bar → paste this entire file → Enter
	  3. Save Place

	Runtime WeaponModels.lua can bake hilts if missing; this bakes into the Place.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HILT_NAME = "SM_Hilt"
local FOLDER = "WeaponModels"
local HILT_END_BIAS = 0.92

local function findHandle(root)
	local named = root:FindFirstChild("Handle", true)
	if named and named:IsA("BasePart") then
		return named
	end
	local best = nil
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

local function longestAxis(part)
	local s = part.Size
	if s.Y >= s.X and s.Y >= s.Z then
		return Vector3.yAxis, s.Y
	elseif s.X >= s.Y and s.X >= s.Z then
		return Vector3.xAxis, s.X
	end
	return Vector3.zAxis, s.Z
end

local function bakeOne(model)
	local tool = model:FindFirstChildWhichIsA("Tool", true)
	local grip = CFrame.new()
	if tool and tool:IsA("Tool") then
		grip = tool.Grip
	end

	local handle = findHandle(model)
	if not handle then
		return model.Name .. " FAIL no BasePart"
	end

	for _, d in model:GetDescendants() do
		if d:IsA("Attachment") and d.Name == HILT_NAME then
			d:Destroy()
		end
	end

	local axis, length = longestAxis(handle)
	local along = length * 0.5 * HILT_END_BIAS
	local tipSign = 1
	if grip.Position.Magnitude > 0.01 then
		local proj = grip.Position:Dot(axis)
		if proj > 0 then
			tipSign = -1
		else
			tipSign = 1
		end
	end
	local tipAxis = axis * tipSign
	local hiltLocal = -tipAxis * along

	local tip = tipAxis.Unit
	local arb = Vector3.xAxis
	if math.abs(tip:Dot(Vector3.xAxis)) >= 0.9 then
		arb = Vector3.zAxis
	end
	local right = tip:Cross(arb)
	if right.Magnitude < 1e-4 then
		right = tip:Cross(Vector3.zAxis)
	end
	right = right.Unit
	local back = right:Cross(tip).Unit

	local att = Instance.new("Attachment")
	att.Name = HILT_NAME
	att.CFrame = CFrame.fromMatrix(hiltLocal, right, tip, back)
	att.Parent = handle
	if not model.PrimaryPart then
		model.PrimaryPart = handle
	end
	model:SetAttribute("SM_HiltBaked", true)

	return string.format(
		"%s OK handle=%s long=%.2f tipSign=%d hiltLocal=%s gripY=%.2f",
		model.Name,
		handle.Name,
		length,
		tipSign,
		tostring(hiltLocal),
		grip.Position.Y
	)
end

local folder = ReplicatedStorage:FindFirstChild(FOLDER)
if not folder then
	warn("[bake_weapon_hilts] missing ReplicatedStorage." .. FOLDER)
else
	print("=== bake_weapon_hilts ===")
	for _, ch in folder:GetChildren() do
		if ch:IsA("Model") then
			print(bakeOne(ch))
		end
	end
	print("=== done — Save Place ===")
end
