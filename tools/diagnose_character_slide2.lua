--[[
	SLIDE DIAGNOSIS, PASS 2 — isolate WHICH visuals folder drives the drift.

	Pass 1 (diagnose_character_slide.lua) proved the drift is caused by something in
	the visuals folders: 7.845 studs baseline -> 0.000 after stripping
	SM_WeaponVisuals + SM_PetVisuals together on level ground (slope 0.00 deg).
	It could not say WHICH, because it stripped both at once, and SM_AuraVisuals
	was not even attached during that run.

	This pass strips ONE folder at a time, re-measuring after each, so the drift
	drops to zero on exactly the guilty step.

	Run in Studio: press F5, stand still, paste into the Command Bar (client context),
	and DO NOT touch movement keys while it samples (~24s total).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SAMPLE_SECONDS = 6
local DRIFT_THRESHOLD = 1.5

local player = Players.LocalPlayer
local char = player and player.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChildOfClass("Humanoid")

if not (hrp and hrp:IsA("BasePart") and hum) then
	warn("[SlideDiag2] No character / HumanoidRootPart. Press F5 first.")
	return
end

local function measure(label: string): number
	print(string.format("[SlideDiag2] %s — hold still for %ds...", label, SAMPLE_SECONDS))
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
		warn(string.format("[SlideDiag2] %s: INPUT DETECTED (%.2f) — result invalid, rerun without touching keys.", label, maxInputSeen))
	end
	print(string.format("[SlideDiag2] %s: moved %.3f studs horizontally", label, horiz))
	return horiz
end

--- Zero out residual momentum so each sample starts clean.
local function settle()
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.5)
end

--- Report what's actually inside a folder that could push the assembly:
--- unanchored parts (they join the physics assembly) and surviving scripts.
local function describe(folderName: string)
	local f = char:FindFirstChild(folderName)
	if not f then
		print(string.format("   %s: NOT PRESENT", folderName))
		return
	end
	local unanchored, anchored, joints, scripts, modules = 0, 0, 0, 0, {}
	for _, d in f:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Anchored then
				anchored += 1
			else
				unanchored += 1
			end
		elseif d:IsA("Constraint") or d:IsA("JointInstance") then
			joints += 1
		elseif d:IsA("ModuleScript") then
			table.insert(modules, d.Name)
		elseif d:IsA("LuaSourceContainer") then
			scripts += 1
		end
	end
	print(string.format(
		"   %s: %d unanchored / %d anchored parts | %d joints | %d scripts | %d ModuleScripts%s",
		folderName, unanchored, anchored, joints, scripts, #modules,
		if #modules > 0 then " -> " .. table.concat(modules, ", ") else ""
	))
	if unanchored > 0 and joints > 0 then
		warn(string.format("   ^ %s has unanchored parts AND joints — this can drag a ball-socket rig.", folderName))
	end
	if #modules > 0 then
		warn(string.format("   ^ %s still contains ModuleScript(s): a BaseScript-only sanitize does not remove these.", folderName))
	end
end

--- Strip one folder, re-measure, and report the delta against the running drift.
local function stripAndMeasure(folderName: string, prev: number): (number, boolean)
	local f = char:FindFirstChild(folderName)
	if not f then
		print(string.format("[SlideDiag2] %s not present — skipping.", folderName))
		return prev, false
	end
	print(string.format("[SlideDiag2] >>> destroying %s ...", folderName))
	f:Destroy()
	settle()
	local now = measure("after removing " .. folderName)
	local fixed = prev >= DRIFT_THRESHOLD and now < DRIFT_THRESHOLD
	if fixed then
		print(string.format("[SlideDiag2] *** DRIFT STOPPED when %s was removed (%.3f -> %.3f). ***", folderName, prev, now))
	end
	return now, fixed
end

print("=========== SLIDE DIAGNOSIS — PASS 2 ===========")

-- Rig type first: a BallSocket/AnimationConstraint rig behaves very differently
-- from a Motor6D rig when you rigid-constrain an unanchored part into it.
local motor6d, animConstraint, ballSocket = 0, 0, 0
for _, d in char:GetDescendants() do
	if d:IsA("Motor6D") then
		motor6d += 1
	elseif d:IsA("AnimationConstraint") then
		animConstraint += 1
	elseif d:IsA("BallSocketConstraint") then
		ballSocket += 1
	end
end
print(string.format(
	"[SlideDiag2] rig: %d Motor6D | %d AnimationConstraint | %d BallSocketConstraint | RigType=%s",
	motor6d, animConstraint, ballSocket, tostring(hum.RigType)
))
if ballSocket > 0 then
	warn("[SlideDiag2] ^ constraint-based rig: limbs are separate physics bodies joined by SOFT ball sockets.")
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { char }
local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
if hit then
	local tilt = math.deg(math.acos(math.clamp(hit.Normal:Dot(Vector3.yAxis), -1, 1)))
	print(string.format("[SlideDiag2] ground: %s | slope %.2f deg", hit.Instance:GetFullName(), tilt))
end

print("[SlideDiag2] --- contents of each visuals folder ---")
for _, name in { "SM_WeaponVisuals", "SM_PetVisuals", "SM_AuraVisuals", "SM_AuraHighlight" } do
	describe(name)
end

settle()
local drift = measure("BASELINE (everything attached)")
if drift < DRIFT_THRESHOLD then
	warn("[SlideDiag2] No drift in the baseline — cannot isolate. Equip the loadout you saw sliding with, then rerun.")
	return
end

-- Order matters: weapons first, since pass 1's dump showed the only unanchored+
-- rigid-constrained parts in the character were the two SM_WeaponRigid links.
local culprits = {}
local fixed
drift, fixed = stripAndMeasure("SM_WeaponVisuals", drift)
if fixed then
	table.insert(culprits, "SM_WeaponVisuals")
end
drift, fixed = stripAndMeasure("SM_PetVisuals", drift)
if fixed then
	table.insert(culprits, "SM_PetVisuals")
end
drift, fixed = stripAndMeasure("SM_AuraVisuals", drift)
if fixed then
	table.insert(culprits, "SM_AuraVisuals")
end

print("=========== VERDICT ===========")
if #culprits > 0 then
	print("CULPRIT(S): " .. table.concat(culprits, " + "))
	print("Fix belongs in the module that builds that folder — nothing else.")
elseif drift >= DRIFT_THRESHOLD then
	warn(string.format("Still drifting %.3f studs with ALL visuals folders removed.", drift))
	warn("   Cause is elsewhere: HRP-parented attachments/constraints, or something")
	warn("   outside src/. Re-run pass 1's force dump and check imported map models.")
else
	print(string.format("Drift ended at %.3f studs but no single strip crossed the threshold —", drift))
	print("   it may be cumulative across folders. Report the per-step numbers above.")
end
print("===============================")
