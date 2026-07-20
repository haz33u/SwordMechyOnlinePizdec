--[[
	Studio Command Bar / Edit-mode script: bake SM_Hilt on every ReplicatedStorage.WeaponModels child.

	Usage:
	  1. Stop Play (Edit mode)
	  2. Paste into Command Bar OR require this Module if synced
	  3. Save Place

	Creates Attachment "SM_Hilt" on each sword PrimaryPart at the HANDLE end.
	Runtime (WeaponModels.lua) uses the same algorithm if attachment is missing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HILT_NAME = "SM_Hilt"
local FOLDER = "WeaponModels"
local HILT_END_BIAS = 0.92

local function findHandle(root: Instance): BasePart?
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

local function longestAxis(part: BasePart): (Vector3, number)
	local s = part.Size
	if s.Y >= s.X and s.Y >= s.Z then
		return Vector3.yAxis, s.Y
	elseif s.X >= s.Y and s.X >= s.Z then
		return Vector3.xAxis, s.X
	end
	return Vector3.zAxis, s.Z
end

local function bakeOne(model: Model): string
	-- Prefer live Tool.Grip before any unwrap
	local tool = model:FindFirstChildWhichIsA("Tool", true)
	local grip = if tool and tool:IsA("Tool") then tool.Grip else CFrame.new()

	local handle = findHandle(model)
	if not handle then
		return model.Name .. " FAIL no BasePart"
	end

	-- Remove old hilts
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
		tipSign = if proj > 0 then -1 else 1
	end
	local tipAxis = axis * tipSign
	local hiltLocal = -tipAxis * along

	local tip = tipAxis.Unit
	local arb = if math.abs(tip:Dot(Vector3.xAxis)) < 0.9 then Vector3.xAxis else Vector3.zAxis
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
		grip.Y
	)
end

local folder = ReplicatedStorage:FindFirstChild(FOLDER)
if not folder then
	warn("[bake_weapon_hilts] missing ReplicatedStorage." .. FOLDER)
	return
end

print("=== bake_weapon_hilts ===")
for _, ch in folder:GetChildren() do
	if ch:IsA("Model") then
		print(bakeOne(ch))
	end
end
print("=== done — Save Place ===")
