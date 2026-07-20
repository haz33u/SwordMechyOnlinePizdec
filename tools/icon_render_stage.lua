--[[
	Paste into Studio Command Bar (Edit mode) after Rojo sync.

	What it does:
	  - Creates Workspace.IconRenderStage with lights + camera
	  - Lists Loc1 weapon model names under ReplicatedStorage.WeaponModels
	  - Prints how to screenshot each for pro ImageLabel icons

	Full guide: docs/WEAPON_ICONS.md
]]

local RS = game:GetService("ReplicatedStorage")
local folder = RS:FindFirstChild("WeaponModels")
if not folder then
	warn("[IconRenderStage] No ReplicatedStorage.WeaponModels")
	return
end

local stage = workspace:FindFirstChild("IconRenderStage")
if stage then
	stage:Destroy()
end
stage = Instance.new("Folder")
stage.Name = "IconRenderStage"
stage.Parent = workspace

local anchor = Instance.new("Part")
anchor.Name = "Anchor"
anchor.Anchored = true
anchor.CanCollide = false
anchor.Transparency = 1
anchor.Size = Vector3.new(0.2, 0.2, 0.2)
anchor.Position = Vector3.new(0, 5, 0)
anchor.Parent = stage

local key = Instance.new("PointLight")
key.Name = "KeyLight"
key.Brightness = 2
key.Range = 20
key.Parent = anchor

local camPart = Instance.new("Part")
camPart.Name = "CameraHint"
camPart.Anchored = true
camPart.CanCollide = false
camPart.Transparency = 0.7
camPart.Color = Color3.fromRGB(80, 160, 255)
camPart.Size = Vector3.new(0.4, 0.4, 0.4)
camPart.CFrame = CFrame.new(Vector3.new(3.2, 5.8, 4.2), Vector3.new(0, 5.5, 0))
camPart.Parent = stage

print("[IconRenderStage] Ready at Workspace.IconRenderStage")
print("Models available:")
for _, ch in folder:GetChildren() do
	if ch:IsA("Model") then
		print("  -", ch.Name)
	end
end
print([[
Workflow:
  1. Clone a model from WeaponModels into IconRenderStage near Anchor
  2. Pose tip-up (same as inventory), fill frame ~80%
  3. View from CameraHint direction / set CurrentCamera
  4. Screenshot → remove background → upload Image
  5. IconConfig.WeaponAssetIds.<weapon_id> = "rbxassetid://..."
See docs/WEAPON_ICONS.md
]])
