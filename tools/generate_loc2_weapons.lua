--!strict
--[[
	Low-Poly 3D Weapon Generator for Location 2 (Pirate Shore).
	Run this script in Roblox Studio Command Bar to generate all Location 2 weapons
	and place them directly into ReplicatedStorage.WeaponModels!

	Each generated model adheres strictly to docs/WEAPON_HOLD.md:
	  - PrimaryPart named "Handle"
	  - SM_Hilt Attachment baked on handle pommel
	  - Low-poly cartoon aesthetic (smooth colors, neon accents, clean geometry)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponModelsFolder = ReplicatedStorage:FindFirstChild("WeaponModels")
if not WeaponModelsFolder then
	WeaponModelsFolder = Instance.new("Folder")
	WeaponModelsFolder.Name = "WeaponModels"
	WeaponModelsFolder.Parent = ReplicatedStorage
end

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material, cframe: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CFrame = cframe
	p.Parent = parent
	return p
end

local function makeWedge(name: string, size: Vector3, color: Color3, material: Enum.Material, cframe: CFrame, parent: Instance): WedgePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CFrame = cframe
	p.Parent = parent
	return p
end

local function makeWeld(part0: BasePart, part1: BasePart): WeldConstraint
	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = part0
	return w
end

local function bakeHilt(model: Model, handle: BasePart, hiltOffsetFromBottom: number)
	model.PrimaryPart = handle
	local hilt = handle:FindFirstChild("SM_Hilt") or Instance.new("Attachment")
	hilt.Name = "SM_Hilt"
	hilt.CFrame = CFrame.new(0, -handle.Size.Y / 2 + hiltOffsetFromBottom, 0) * CFrame.Angles(0, 0, 0)
	hilt.Parent = handle
end

--------------------------------------------------------------------------------
-- WEAPON BUILDERS
--------------------------------------------------------------------------------

-- 1. Pirate Hook (pirate_hook)
local function buildPirateHook(): Model
	local m = Instance.new("Model")
	m.Name = "PirateHook"

	local handle = makePart("Handle", Vector3.new(0.4, 1.2, 0.4), Color3.fromRGB(80, 45, 20), Enum.Material.Wood, CFrame.new(0, 0.6, 0), m)
	local guard = makePart("Guard", Vector3.new(0.85, 0.22, 0.85), Color3.fromRGB(180, 140, 60), Enum.Material.Metal, CFrame.new(0, 1.2, 0), m)
	makeWeld(handle, guard)

	-- Hook shank + curved tip (wedge parts)
	local shank = makePart("Shank", Vector3.new(0.22, 1.2, 0.35), Color3.fromRGB(200, 210, 220), Enum.Material.Metal, CFrame.new(0, 1.85, 0), m)
	makeWeld(handle, shank)

	local hookCurve = makeWedge("HookCurve", Vector3.new(0.22, 1.0, 0.7), Color3.fromRGB(210, 220, 230), Enum.Material.Metal, CFrame.new(0, 2.35, 0.35) * CFrame.Angles(math.rad(20), 0, 0), m)
	makeWeld(handle, hookCurve)

	local tip = makePart("HookTip", Vector3.new(0.18, 0.35, 0.18), Color3.fromRGB(230, 240, 250), Enum.Material.Metal, CFrame.new(0, 2.85, 0.65), m)
	makeWeld(handle, tip)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 2. Pirate Hammer (pirate_hammer)
local function buildPirateHammer(): Model
	local m = Instance.new("Model")
	m.Name = "PirateHammer"

	local shaft = makePart("Handle", Vector3.new(0.35, 3.8, 0.35), Color3.fromRGB(70, 40, 20), Enum.Material.Wood, CFrame.new(0, 1.9, 0), m)

	-- Center block + two striking faces so it doesn't look like a single flat box
	local core = makePart("HammerCore", Vector3.new(1.1, 0.9, 1.1), Color3.fromRGB(110, 115, 120), Enum.Material.Metal, CFrame.new(0, 3.4, 0), m)
	makeWeld(shaft, core)

	local faceF = makePart("FaceFront", Vector3.new(0.95, 0.7, 0.35), Color3.fromRGB(90, 95, 100), Enum.Material.Metal, CFrame.new(0, 3.4, 0.72), m)
	makeWeld(shaft, faceF)
	local faceB = makePart("FaceBack", Vector3.new(0.95, 0.7, 0.35), Color3.fromRGB(90, 95, 100), Enum.Material.Metal, CFrame.new(0, 3.4, -0.72), m)
	makeWeld(shaft, faceB)
	local faceL = makePart("FaceLeft", Vector3.new(0.35, 0.7, 0.95), Color3.fromRGB(90, 95, 100), Enum.Material.Metal, CFrame.new(0.72, 3.4, 0), m)
	makeWeld(shaft, faceL)
	local faceR = makePart("FaceRight", Vector3.new(0.35, 0.7, 0.95), Color3.fromRGB(90, 95, 100), Enum.Material.Metal, CFrame.new(-0.72, 3.4, 0), m)
	makeWeld(shaft, faceR)

	local goldBand = makePart("GoldBand", Vector3.new(1.25, 0.18, 1.25), Color3.fromRGB(230, 180, 40), Enum.Material.Metal, CFrame.new(0, 3.75, 0), m)
	makeWeld(shaft, goldBand)

	bakeHilt(m, shaft, 0.3)
	return m
end

-- 3. Pirate Saber (pirate_saber)
local function buildPirateSaber(): Model
	local m = Instance.new("Model")
	m.Name = "PirateSaber"

	local handle = makePart("Handle", Vector3.new(0.32, 1.2, 0.32), Color3.fromRGB(40, 30, 25), Enum.Material.Leather, CFrame.new(0, 0.6, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.5, 0.25, 0.5), Color3.fromRGB(210, 170, 50), Enum.Material.Metal, CFrame.new(0, 0.12, 0), m)
	makeWeld(handle, pommel)

	-- D-guard + basket bars
	local basket = makePart("BasketGuard", Vector3.new(1.0, 0.3, 1.0), Color3.fromRGB(210, 170, 50), Enum.Material.Metal, CFrame.new(0, 1.2, 0), m)
	makeWeld(handle, basket)
	for _, ang in ipairs({0, 45, 90, 135}) do
		local bar = makePart("BasketBar", Vector3.new(0.08, 0.08, 1.05), Color3.fromRGB(210, 170, 50), Enum.Material.Metal, CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.rad(ang), 0), m)
		makeWeld(handle, bar)
	end

	-- Curved blade: base + tapered wedge tip
	local blade = makePart("Blade", Vector3.new(0.2, 2.4, 0.45), Color3.fromRGB(210, 220, 230), Enum.Material.Metal, CFrame.new(0, 2.5, 0.05), m)
	makeWeld(handle, blade)
	local tip = makeWedge("BladeTip", Vector3.new(0.18, 1.0, 0.38), Color3.fromRGB(220, 230, 240), Enum.Material.Metal, CFrame.new(0, 4.0, 0.05) * CFrame.Angles(0, 0, math.rad(5)), m)
	makeWeld(handle, tip)
	local fuller = makePart("Fuller", Vector3.new(0.08, 1.8, 0.05), Color3.fromRGB(180, 190, 200), Enum.Material.Metal, CFrame.new(0, 2.9, 0.24), m)
	makeWeld(handle, fuller)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 4. Golden Plated Sword (golden_plated_sword)
local function buildGoldenPlatedSword(): Model
	local m = Instance.new("Model")
	m.Name = "GoldenPlatedSword"

	local handle = makePart("Handle", Vector3.new(0.32, 1.2, 0.32), Color3.fromRGB(20, 20, 25), Enum.Material.Leather, CFrame.new(0, 0.6, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.55, 0.25, 0.55), Color3.fromRGB(245, 195, 40), Enum.Material.Metal, CFrame.new(0, 0.12, 0), m)
	makeWeld(handle, pommel)

	local crossguard = makePart("Crossguard", Vector3.new(1.5, 0.28, 0.45), Color3.fromRGB(245, 195, 40), Enum.Material.Metal, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, crossguard)
	local crossTipL = makePart("CrossTipL", Vector3.new(0.2, 0.2, 0.45), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, CFrame.new(0.85, 1.25, 0), m)
	makeWeld(handle, crossTipL)
	local crossTipR = makePart("CrossTipR", Vector3.new(0.2, 0.2, 0.45), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, CFrame.new(-0.85, 1.25, 0), m)
	makeWeld(handle, crossTipR)

	local gem = makePart("Gem", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(239, 68, 68), Enum.Material.Neon, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, gem)

	local blade = makePart("Blade", Vector3.new(0.22, 2.8, 0.45), Color3.fromRGB(255, 215, 70), Enum.Material.Metal, CFrame.new(0, 2.85, 0), m)
	makeWeld(handle, blade)
	local tip = makeWedge("BladeTip", Vector3.new(0.2, 0.9, 0.4), Color3.fromRGB(255, 230, 90), Enum.Material.Metal, CFrame.new(0, 4.1, 0), m)
	makeWeld(handle, tip)
	local fuller = makePart("Fuller", Vector3.new(0.08, 2.0, 0.06), Color3.fromRGB(230, 180, 40), Enum.Material.Neon, CFrame.new(0, 3.0, 0.23), m)
	makeWeld(handle, fuller)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 5. Captain Axe (captain_axe)
local function buildCaptainAxe(): Model
	local m = Instance.new("Model")
	m.Name = "CaptainAxe"

	local shaft = makePart("Handle", Vector3.new(0.35, 4.2, 0.35), Color3.fromRGB(60, 35, 15), Enum.Material.Wood, CFrame.new(0, 2.1, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.55, 0.2, 0.55), Color3.fromRGB(180, 140, 60), Enum.Material.Metal, CFrame.new(0, 0.1, 0), m)
	makeWeld(shaft, pommel)

	-- Axe head built from multiple parts for a solid silhouette
	local headCore = makePart("AxeHeadCore", Vector3.new(0.4, 1.4, 1.6), Color3.fromRGB(130, 135, 140), Enum.Material.Metal, CFrame.new(0, 3.6, 0), m)
	makeWeld(shaft, headCore)
	local bladeL = makeWedge("AxeBladeL", Vector3.new(0.15, 1.5, 1.0), Color3.fromRGB(180, 190, 200), Enum.Material.Metal, CFrame.new(0, 3.6, 0.85) * CFrame.Angles(0, math.rad(90), 0), m)
	makeWeld(shaft, bladeL)
	local bladeR = makeWedge("AxeBladeR", Vector3.new(0.15, 1.5, 1.0), Color3.fromRGB(180, 190, 200), Enum.Material.Metal, CFrame.new(0, 3.6, -0.85) * CFrame.Angles(0, -math.rad(90), 0), m)
	makeWeld(shaft, bladeR)

	-- Skull emblem with eye sockets
	local skull = makePart("SkullEmblem", Vector3.new(0.6, 0.55, 0.55), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, CFrame.new(0, 3.6, 0), m)
	makeWeld(shaft, skull)
	local eyeL = makePart("EyeL", Vector3.new(0.12, 0.12, 0.08), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic, CFrame.new(0.12, 3.65, 0.25), m)
	makeWeld(shaft, eyeL)
	local eyeR = makePart("EyeR", Vector3.new(0.12, 0.12, 0.08), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic, CFrame.new(-0.12, 3.65, 0.25), m)
	makeWeld(shaft, eyeR)

	bakeHilt(m, shaft, 0.3)
	return m
end

-- 6. Element Blade (element_blade)
local function buildElementBlade(): Model
	local m = Instance.new("Model")
	m.Name = "ElementBlade"

	local handle = makePart("Handle", Vector3.new(0.32, 1.2, 0.32), Color3.fromRGB(20, 30, 40), Enum.Material.SmoothPlastic, CFrame.new(0, 0.6, 0), m)
	local guard = makePart("Guard", Vector3.new(1.35, 0.32, 0.45), Color3.fromRGB(16, 185, 129), Enum.Material.Neon, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guard)
	local guardGem = makePart("GuardGem", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(52, 211, 153), Enum.Material.Neon, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guardGem)

	-- Layered elemental blade
	local core = makePart("BladeCore", Vector3.new(0.18, 2.8, 0.35), Color3.fromRGB(20, 40, 60), Enum.Material.SmoothPlastic, CFrame.new(0, 2.8, 0), m)
	makeWeld(handle, core)
	local blade = makePart("Blade", Vector3.new(0.22, 2.9, 0.42), Color3.fromRGB(56, 189, 248), Enum.Material.Neon, CFrame.new(0, 2.85, 0), m)
	makeWeld(handle, blade)
	local tip = makeWedge("BladeTip", Vector3.new(0.2, 0.9, 0.35), Color3.fromRGB(120, 220, 255), Enum.Material.Neon, CFrame.new(0, 4.05, 0), m)
	makeWeld(handle, tip)
	local edge = makePart("Edge", Vector3.new(0.06, 2.4, 0.08), Color3.fromRGB(220, 250, 255), Enum.Material.Neon, CFrame.new(0, 2.95, 0.22), m)
	makeWeld(handle, edge)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 7. Emerald Blade (emerald_blade)
local function buildEmeraldBlade(): Model
	local m = Instance.new("Model")
	m.Name = "EmeraldBlade"

	local handle = makePart("Handle", Vector3.new(0.32, 1.2, 0.32), Color3.fromRGB(15, 25, 20), Enum.Material.Leather, CFrame.new(0, 0.6, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.5, 0.22, 0.5), Color3.fromRGB(16, 185, 129), Enum.Material.Metal, CFrame.new(0, 0.11, 0), m)
	makeWeld(handle, pommel)

	local guard = makePart("Guard", Vector3.new(1.45, 0.3, 0.48), Color3.fromRGB(16, 185, 129), Enum.Material.Metal, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guard)
	local guardGem = makePart("GuardGem", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(52, 211, 153), Enum.Material.Neon, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guardGem)

	local blade = makePart("Blade", Vector3.new(0.24, 2.9, 0.48), Color3.fromRGB(52, 211, 153), Enum.Material.Glass, CFrame.new(0, 2.9, 0), m)
	makeWeld(handle, blade)
	local tip = makeWedge("BladeTip", Vector3.new(0.22, 0.95, 0.42), Color3.fromRGB(110, 245, 190), Enum.Material.Glass, CFrame.new(0, 4.1, 0), m)
	makeWeld(handle, tip)
	local facetL = makePart("FacetL", Vector3.new(0.12, 2.0, 0.08), Color3.fromRGB(30, 160, 110), Enum.Material.Glass, CFrame.new(0.1, 3.0, 0.22) * CFrame.Angles(0, math.rad(15), 0), m)
	makeWeld(handle, facetL)
	local facetR = makePart("FacetR", Vector3.new(0.12, 2.0, 0.08), Color3.fromRGB(30, 160, 110), Enum.Material.Glass, CFrame.new(-0.1, 3.0, 0.22) * CFrame.Angles(0, -math.rad(15), 0), m)
	makeWeld(handle, facetR)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 8. Sea Dagger (sea_dagger)
local function buildSeaDagger(): Model
	local m = Instance.new("Model")
	m.Name = "SeaDagger"

	local handle = makePart("Handle", Vector3.new(0.28, 0.9, 0.28), Color3.fromRGB(240, 230, 220), Enum.Material.SmoothPlastic, CFrame.new(0, 0.45, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.4, 0.18, 0.4), Color3.fromRGB(244, 114, 182), Enum.Material.SmoothPlastic, CFrame.new(0, 0.09, 0), m)
	makeWeld(handle, pommel)

	local guard = makePart("Guard", Vector3.new(0.9, 0.22, 0.35), Color3.fromRGB(244, 114, 182), Enum.Material.SmoothPlastic, CFrame.new(0, 0.95, 0), m)
	makeWeld(handle, guard)

	local blade = makePart("Blade", Vector3.new(0.18, 1.7, 0.38), Color3.fromRGB(14, 165, 233), Enum.Material.Neon, CFrame.new(0, 1.85, 0), m)
	makeWeld(handle, blade)
	local tip = makeWedge("BladeTip", Vector3.new(0.16, 0.6, 0.32), Color3.fromRGB(120, 220, 255), Enum.Material.Neon, CFrame.new(0, 2.75, 0), m)
	makeWeld(handle, tip)
	local ridge = makePart("Ridge", Vector3.new(0.06, 1.2, 0.06), Color3.fromRGB(220, 250, 255), Enum.Material.Neon, CFrame.new(0, 2.0, 0.19), m)
	makeWeld(handle, ridge)

	bakeHilt(m, handle, 0.15)
	return m
end

--------------------------------------------------------------------------------
-- EXECUTE GENERATION
--------------------------------------------------------------------------------
local builders = {
	buildPirateHook,
	buildPirateHammer,
	buildPirateSaber,
	buildGoldenPlatedSword,
	buildCaptainAxe,
	buildElementBlade,
	buildEmeraldBlade,
	buildSeaDagger,
}

print("[WeaponGenerator] Generating Location 2 Low-Poly 3D Weapons...")
for _, b in ipairs(builders) do
	local model = b()
	local existing = WeaponModelsFolder:FindFirstChild(model.Name)
	if existing then
		existing:Destroy()
	end
	model.Parent = WeaponModelsFolder
	print(" -> Created 3D Weapon Model: " .. model.Name)
end
print("[WeaponGenerator] Location 2 Weapons successfully built into ReplicatedStorage.WeaponModels!")
