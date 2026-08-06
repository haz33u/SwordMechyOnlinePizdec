--!strict
local Workspace = game:GetService("Workspace")

print("========== MOB GROUNDING AUDIT ==========")
local mobsFolder = Workspace:FindFirstChild("Mobs") or Workspace:FindFirstChild("MobSpawns")
local count = 0
local issues = 0

local function checkMob(inst: Instance)
	if inst:IsA("Model") then
		count += 1
		local gY = inst:GetAttribute("GroundY")
		local gSrc = inst:GetAttribute("GroundSource")
		local gCorr = inst:GetAttribute("GroundCorrection")
		local name = inst.Name
		local cf = inst:GetPivot()
		print(string.format("Mob #%d [%s]: PosY=%.2f, GroundY=%s, Source=%s, Correction=%s",
			count, name, cf.Position.Y, tostring(gY), tostring(gSrc), tostring(gCorr)))
		if type(gCorr) == "number" and math.abs(gCorr) > 6 then
			print(string.format("  WARNING: High correction (%.2f studs)", gCorr))
			issues += 1
		end
	end
end

if mobsFolder then
	for _, child in mobsFolder:GetDescendants() do
		if child:IsA("Model") and (child:FindFirstChildOfClass("Humanoid") or child:GetAttribute("MobId")) then
			checkMob(child)
		end
	end
else
	for _, child in Workspace:GetChildren() do
		if child:IsA("Model") and (child:FindFirstChildOfClass("Humanoid") or child:GetAttribute("MobId")) then
			checkMob(child)
		end
	end
end

print(string.format("========== AUDITED %d MOBS (Issues: %d) ==========", count, issues))
