--[[
	Studio Command Bar script — diagnose unprompted character sliding.

	Isolates whether the drift comes from aura/weapon visuals welded into the
	character's physics assembly, or from something outside src/ (spawn geometry,
	Workspace.Gravity, an imported model carrying a BodyMover).

	Usage:
	1. Play Solo (F5) — the character must exist and be yours.
	2. Paste into the Command Bar and run.
	3. STOP TOUCHING THE KEYBOARD for the whole 20s. Watch the output.

	Reading the result:
	  - "CLEAN after strip" -> visuals were the cause; the aura/weapon fix is correct.
	  - "STILL DRIFTING after strip" -> NOT the visuals. Read the dumped
	    constraint/gravity/slope report and look outside src/.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SAMPLE_SECONDS = 6
local DRIFT_THRESHOLD = 1.5 -- studs of horizontal travel with zero input = drift

local player = Players.LocalPlayer
local char = player and player.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChildOfClass("Humanoid")

if not (hrp and hrp:IsA("BasePart") and hum) then
	warn("[SlideDiag] No character / HumanoidRootPart. Press F5 first.")
	return
end

--- Measures horizontal travel while the player holds still.
local function measure(label: string): number
	print(string.format("[SlideDiag] %s — hold still for %ds...", label, SAMPLE_SECONDS))
	local start = hrp.Position
	local maxInputSeen = 0
	local t0 = os.clock()
	while os.clock() - t0 < SAMPLE_SECONDS do
		maxInputSeen = math.max(maxInputSeen, hum.MoveDirection.Magnitude)
		RunService.Heartbeat:Wait()
	end
	local d = hrp.Position - start
	local horiz = Vector3.new(d.X, 0, d.Z).Magnitude
	if maxInputSeen > 0.05 then
		warn(string.format("[SlideDiag] %s: INPUT DETECTED (%.2f) — result invalid, rerun without touching keys.", label, maxInputSeen))
	end
	print(string.format(
		"[SlideDiag] %s: moved %.3f studs horizontally | vel=%s",
		label, horiz, tostring(hrp.AssemblyLinearVelocity)
	))
	return horiz
end

--- Reports anything in the character that could push the assembly.
local function dumpForces()
	print("[SlideDiag] --- force sources inside character ---")
	local found = 0
	for _, d in char:GetDescendants() do
		if d:IsA("BodyMover") or d:IsA("Constraint") then
			-- WeldConstraint/RigidConstraint are the aura/weapon attach path
			print(string.format("   %s  <%s>  parent=%s", d:GetFullName(), d.ClassName, d.Parent and d.Parent.Name or "?"))
			found += 1
		elseif d:IsA("BasePart") and not d.Anchored and d:FindFirstChildOfClass("BodyVelocity") then
			print("   unanchored part with BodyVelocity: " .. d:GetFullName())
			found += 1
		end
	end
	if found == 0 then
		print("   (none)")
	end
	print(string.format("[SlideDiag] Workspace.Gravity = %.2f", Workspace.Gravity))
	local floorMat = hum.FloorMaterial
	print("[SlideDiag] FloorMaterial = " .. tostring(floorMat) .. " | Sit=" .. tostring(hum.Sit) .. " | PlatformStand=" .. tostring(hum.PlatformStand))
	-- slope of whatever we're standing on
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
	if hit then
		local tilt = math.deg(math.acos(math.clamp(hit.Normal:Dot(Vector3.yAxis), -1, 1)))
		print(string.format("[SlideDiag] ground: %s | slope %.2f deg | normal %s", hit.Instance:GetFullName(), tilt, tostring(hit.Normal)))
		if tilt > 2 then
			warn("[SlideDiag] ^ ground is NOT level — a sloped floor alone can cause sliding.")
		end
	else
		warn("[SlideDiag] no ground under character within 12 studs (falling?)")
	end
end

print("=========== SLIDE DIAGNOSIS ===========")
dumpForces()

local before = measure("BASELINE (aura + weapon attached)")

-- Strip visuals: remove the folders AuraVisual/WeaponVisual/PetVisual build into
-- the character, which is what welds unanchored parts into its assembly.
print("[SlideDiag] stripping SM_AuraVisuals / SM_WeaponVisuals / SM_PetVisuals ...")
local stripped = {}
for _, name in { "SM_AuraVisuals", "SM_WeaponVisuals", "SM_PetVisuals", "SM_AuraHighlight" } do
	local f = char:FindFirstChild(name)
	if f then
		table.insert(stripped, name)
		f:Destroy()
	end
end
-- also kill the HRP-parented aura attachment + its RigidConstraint (AuraVisual.lua:565-589)
for _, d in hrp:GetChildren() do
	if d.Name == "AuraA0" or d:IsA("RigidConstraint") or d:IsA("WeldConstraint") then
		table.insert(stripped, d.Name .. "<" .. d.ClassName .. ">")
		d:Destroy()
	end
end
print("[SlideDiag] stripped: " .. (#stripped > 0 and table.concat(stripped, ", ") or "NOTHING FOUND"))

hrp.AssemblyLinearVelocity = Vector3.zero
hrp.AssemblyAngularVelocity = Vector3.zero
task.wait(0.5)

local after = measure("AFTER STRIP (no aura/weapon/pet)")

print("=========== VERDICT ===========")
print(string.format("baseline drift = %.3f studs | after strip = %.3f studs", before, after))
if after < DRIFT_THRESHOLD and before >= DRIFT_THRESHOLD then
	print("CLEAN after strip -> the VISUALS were the cause. AuraVisual/WeaponVisual fix is correct.")
elseif after >= DRIFT_THRESHOLD then
	warn("STILL DRIFTING after strip -> NOT the visuals. Cause is outside src/ — check the")
	warn("   ground/slope/gravity lines dumped above, and any imported model's baked constraints.")
	dumpForces()
else
	print("No drift in either sample. Could not reproduce — try equipping an aura first,")
	print("   or moving to the spot where you saw the sliding, then rerun.")
end
print("===============================")
