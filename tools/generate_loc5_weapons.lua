--!strict
--[[
	Low-Poly 3D Weapon Generator for Location 5 (Ash Canyons).
	Run this script in Roblox Studio Command Bar to generate all Location 5 weapons
	and place them directly into ReplicatedStorage.WeaponModels!

	Each generated model adheres strictly to docs/WEAPON_HOLD.md:
	  - PrimaryPart named "Handle"
	  - SM_Hilt Attachment baked on handle pommel
	  - Low-poly volcanic aesthetic (obsidian, magma, ash, phoenix embers)
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

-- 1. Ash Shiv (ash_shiv)
local function buildAshShiv(): Model
	local m = Instance.new("Model")
	m.Name = "AshShiv"

	local handle = makePart("Handle", Vector3.new(0.25, 0.85, 0.25), Color3.fromRGB(50, 40, 40), Enum.Material.Wood, CFrame.new(0, 0.42, 0), m)
	local wrap = makePart("Wrap", Vector3.new(0.32, 0.4, 0.32), Color3.fromRGB(120, 80, 50), Enum.Material.Leather, CFrame.new(0, 0.55, 0), m)
	makeWeld(handle, wrap)

	local blade = makePart("Blade", Vector3.new(0.2, 1.6, 0.35), Color3.fromRGB(80, 80, 80), Enum.Material.Metal, CFrame.new(0, 1.5, 0), m)
	makeWeld(handle, blade)
	local tip = makeWedge("BladeTip", Vector3.new(0.18, 0.55, 0.3), Color3.fromRGB(120, 120, 120), Enum.Material.Metal, CFrame.new(0, 2.25, 0), m)
	makeWeld(handle, tip)
	local ashEdge = makePart("AshEdge", Vector3.new(0.06, 1.2, 0.06), Color3.fromRGB(200, 200, 200), Enum.Material.SmoothPlastic, CFrame.new(0, 1.6, 0.18), m)
	makeWeld(handle, ashEdge)

	bakeHilt(m, handle, 0.15)
	return m
end

-- 2. Magma Maul (magma_maul)
local function buildMagmaMaul(): Model
	local m = Instance.new("Model")
	m.Name = "MagmaMaul"

	local shaft = makePart("Handle", Vector3.new(0.38, 3.6, 0.38), Color3.fromRGB(30, 25, 25), Enum.Material.Rock, CFrame.new(0, 1.8, 0), m)

	local core = makePart("HeadCore", Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(40, 35, 35), Enum.Material.Rock, CFrame.new(0, 3.6, 0), m)
	makeWeld(shaft, core)

	local magma1 = makePart("Magma1", Vector3.new(1.0, 0.8, 1.0), Color3.fromRGB(255, 100, 20), Enum.Material.Neon, CFrame.new(0, 3.6, 0), m)
	makeWeld(shaft, magma1)
	local magma2 = makePart("Magma2", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(255, 160, 40), Enum.Material.Neon, CFrame.new(0.25, 3.8, 0.25), m)
	makeWeld(shaft, magma2)
	local magma3 = makePart("Magma3", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(255, 160, 40), Enum.Material.Neon, CFrame.new(-0.25, 3.4, -0.25), m)
	makeWeld(shaft, magma3)

	local spike1 = makePart("Spike1", Vector3.new(0.25, 0.9, 0.25), Color3.fromRGB(50, 45, 45), Enum.Material.Rock, CFrame.new(0, 4.1, 0) * CFrame.Angles(math.rad(10), 0, 0), m)
	makeWeld(shaft, spike1)
	local spike2 = makePart("Spike2", Vector3.new(0.25, 0.9, 0.25), Color3.fromRGB(50, 45, 45), Enum.Material.Rock, CFrame.new(0.5, 3.7, 0) * CFrame.Angles(0, 0, math.rad(10)), m)
	makeWeld(shaft, spike2)
	local spike3 = makePart("Spike3", Vector3.new(0.25, 0.9, 0.25), Color3.fromRGB(50, 45, 45), Enum.Material.Rock, CFrame.new(-0.5, 3.7, 0) * CFrame.Angles(0, 0, -math.rad(10)), m)
	makeWeld(shaft, spike3)

	bakeHilt(m, shaft, 0.3)
	return m
end

-- 3. Obsidian Glaive (obsidian_glaive)
local function buildObsidianGlaive(): Model
	local m = Instance.new("Model")
	m.Name = "ObsidianGlaive"

	local handle = makePart("Handle", Vector3.new(0.32, 3.0, 0.32), Color3.fromRGB(25, 20, 25), Enum.Material.Rock, CFrame.new(0, 1.5, 0), m)
	local wrap = makePart("Wrap", Vector3.new(0.4, 0.9, 0.4), Color3.fromRGB(60, 45, 45), Enum.Material.Leather, CFrame.new(0, 0.8, 0), m)
	makeWeld(handle, wrap)

	-- Long curved obsidian blade
	local blade = makeWedge("Blade", Vector3.new(0.28, 3.2, 1.0), Color3.fromRGB(15, 10, 20), Enum.Material.Glass, CFrame.new(0, 3.6, 0.4) * CFrame.Angles(math.rad(15), 0, 0), m)
	makeWeld(handle, blade)
	local edge = makeWedge("Edge", Vector3.new(0.12, 3.0, 0.85), Color3.fromRGB(60, 50, 90), Enum.Material.Neon, CFrame.new(0, 3.6, 0.45) * CFrame.Angles(math.rad(15), 0, 0), m)
	makeWeld(handle, edge)
	local guard = makePart("Guard", Vector3.new(0.8, 0.18, 0.8), Color3.fromRGB(80, 60, 80), Enum.Material.Metal, CFrame.new(0, 3.0, 0), m)
	makeWeld(handle, guard)

	bakeHilt(m, handle, 0.25)
	return m
end

-- 4. Inferno Blade (inferno_blade)
local function buildInfernoBlade(): Model
	local m = Instance.new("Model")
	m.Name = "InfernoBlade"

	local handle = makePart("Handle", Vector3.new(0.34, 1.2, 0.34), Color3.fromRGB(25, 15, 15), Enum.Material.Leather, CFrame.new(0, 0.6, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.5, 0.22, 0.5), Color3.fromRGB(120, 40, 20), Enum.Material.Metal, CFrame.new(0, 0.11, 0), m)
	makeWeld(handle, pommel)

	local guard = makePart("Guard", Vector3.new(1.4, 0.28, 0.45), Color3.fromRGB(180, 50, 20), Enum.Material.Metal, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guard)
	local guardGem = makePart("GuardGem", Vector3.new(0.38, 0.38, 0.38), Color3.fromRGB(255, 80, 20), Enum.Material.Neon, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guardGem)

	local blade = makePart("Blade", Vector3.new(0.24, 3.0, 0.48), Color3.fromRGB(40, 15, 15), Enum.Material.Metal, CFrame.new(0, 2.95, 0), m)
	makeWeld(handle, blade)
	local flame = makePart("Flame", Vector3.new(0.2, 2.8, 0.4), Color3.fromRGB(255, 90, 20), Enum.Material.Neon, CFrame.new(0, 2.95, 0), m)
	makeWeld(handle, flame)
	local tip = makeWedge("BladeTip", Vector3.new(0.22, 1.0, 0.42), Color3.fromRGB(255, 160, 50), Enum.Material.Neon, CFrame.new(0, 4.15, 0), m)
	makeWeld(handle, tip)
	local edge = makePart("Edge", Vector3.new(0.08, 2.4, 0.08), Color3.fromRGB(255, 200, 80), Enum.Material.Neon, CFrame.new(0, 3.0, 0.24), m)
	makeWeld(handle, edge)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 5. Volcano God Sword (volcano_god_sword)
local function buildVolcanoGodSword(): Model
	local m = Instance.new("Model")
	m.Name = "VolcanoGodSword"

	local handle = makePart("Handle", Vector3.new(0.36, 1.3, 0.36), Color3.fromRGB(20, 15, 15), Enum.Material.Rock, CFrame.new(0, 0.65, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.55, 0.25, 0.55), Color3.fromRGB(255, 90, 20), Enum.Material.Neon, CFrame.new(0, 0.12, 0), m)
	makeWeld(handle, pommel)

	local guard = makePart("Guard", Vector3.new(1.6, 0.35, 0.55), Color3.fromRGB(60, 40, 40), Enum.Material.Rock, CFrame.new(0, 1.3, 0), m)
	makeWeld(handle, guard)
	local guardCore = makePart("GuardCore", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 100, 20), Enum.Material.Neon, CFrame.new(0, 1.3, 0), m)
	makeWeld(handle, guardCore)
	local guardWingL = makePart("GuardWingL", Vector3.new(0.4, 0.18, 0.9), Color3.fromRGB(180, 60, 20), Enum.Material.Neon, CFrame.new(0.5, 1.3, 0) * CFrame.Angles(0, math.rad(25), 0), m)
	makeWeld(handle, guardWingL)
	local guardWingR = makePart("GuardWingR", Vector3.new(0.4, 0.18, 0.9), Color3.fromRGB(180, 60, 20), Enum.Material.Neon, CFrame.new(-0.5, 1.3, 0) * CFrame.Angles(0, -math.rad(25), 0), m)
	makeWeld(handle, guardWingR)

	local blade = makePart("Blade", Vector3.new(0.28, 3.4, 0.55), Color3.fromRGB(35, 25, 25), Enum.Material.Rock, CFrame.new(0, 3.15, 0), m)
	makeWeld(handle, blade)
	local lava = makePart("Lava", Vector3.new(0.18, 3.0, 0.42), Color3.fromRGB(255, 80, 20), Enum.Material.Neon, CFrame.new(0, 3.15, 0), m)
	makeWeld(handle, lava)
	local tip = makeWedge("BladeTip", Vector3.new(0.25, 1.1, 0.48), Color3.fromRGB(255, 180, 60), Enum.Material.Neon, CFrame.new(0, 4.55, 0), m)
	makeWeld(handle, tip)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 6. Phoenix Ash Blade (phoenix_ash_blade)
local function buildPhoenixAshBlade(): Model
	local m = Instance.new("Model")
	m.Name = "PhoenixAshBlade"

	local handle = makePart("Handle", Vector3.new(0.34, 1.2, 0.34), Color3.fromRGB(20, 15, 15), Enum.Material.Leather, CFrame.new(0, 0.6, 0), m)
	local pommel = makePart("Pommel", Vector3.new(0.5, 0.22, 0.5), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, CFrame.new(0, 0.11, 0), m)
	makeWeld(handle, pommel)

	local guard = makePart("Guard", Vector3.new(1.45, 0.3, 0.48), Color3.fromRGB(200, 80, 30), Enum.Material.Metal, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guard)
	local featherL = makePart("FeatherL", Vector3.new(0.35, 0.08, 0.8), Color3.fromRGB(255, 120, 50), Enum.Material.Neon, CFrame.new(0.55, 1.3, 0) * CFrame.Angles(0, math.rad(35), 0), m)
	makeWeld(handle, featherL)
	local featherR = makePart("FeatherR", Vector3.new(0.35, 0.08, 0.8), Color3.fromRGB(255, 120, 50), Enum.Material.Neon, CFrame.new(-0.55, 1.3, 0) * CFrame.Angles(0, -math.rad(35), 0), m)
	makeWeld(handle, featherR)

	local blade = makePart("Blade", Vector3.new(0.24, 3.2, 0.48), Color3.fromRGB(40, 20, 20), Enum.Material.Metal, CFrame.new(0, 3.0, 0), m)
	makeWeld(handle, blade)
	local ashFire = makePart("AshFire", Vector3.new(0.18, 3.0, 0.4), Color3.fromRGB(255, 100, 40), Enum.Material.Neon, CFrame.new(0, 3.0, 0), m)
	makeWeld(handle, ashFire)
	local tip = makeWedge("BladeTip", Vector3.new(0.22, 1.0, 0.42), Color3.fromRGB(255, 220, 100), Enum.Material.Neon, CFrame.new(0, 4.3, 0), m)
	makeWeld(handle, tip)
	local crest = makePart("Crest", Vector3.new(0.3, 0.08, 0.5), Color3.fromRGB(255, 200, 80), Enum.Material.Neon, CFrame.new(0, 3.8, 0.22), m)
	makeWeld(handle, crest)

	bakeHilt(m, handle, 0.2)
	return m
end

--------------------------------------------------------------------------------
-- EXECUTE GENERATION
--------------------------------------------------------------------------------
local builders = {
	buildAshShiv,
	buildMagmaMaul,
	buildObsidianGlaive,
	buildInfernoBlade,
	buildVolcanoGodSword,
	buildPhoenixAshBlade,
}

print("[WeaponGenerator] Generating Location 5 Volcanic 3D Weapons...")
for _, b in ipairs(builders) do
	local model = b()
	local existing = WeaponModelsFolder:FindFirstChild(model.Name)
	if existing then
		existing:Destroy()
	end
	model.Parent = WeaponModelsFolder
	print(" -> Created 3D Weapon Model: " .. model.Name)
end
print("[WeaponGenerator] Location 5 Weapons successfully built into ReplicatedStorage.WeaponModels!")
