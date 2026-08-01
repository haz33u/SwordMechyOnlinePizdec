--!strict
--[[
	Low-Poly 3D Weapon Generator for Location 2 (Pirate Shore).
	Run this script in Roblox Studio Command Bar to generate all Location 2 weapons
	and place them directly into ReplicatedStorage.WeaponModels!

	Each generated model adheres strictly to docs/WEAPON_HOLD.md:
	  - PrimaryPart named "Handle" or "Blade"
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
	local guard = makePart("Guard", Vector3.new(0.8, 0.2, 0.8), Color3.fromRGB(180, 140, 60), Enum.Material.Metal, CFrame.new(0, 1.2, 0), m)
	makeWeld(handle, guard)

	-- Hook blade arc (wedge parts)
	local bladeBase = makePart("BladeBase", Vector3.new(0.2, 1.4, 0.4), Color3.fromRGB(200, 210, 220), Enum.Material.Metal, CFrame.new(0, 2.0, 0), m)
	makeWeld(handle, bladeBase)

	local hookTip = makePart("HookTip", Vector3.new(0.2, 0.8, 0.8), Color3.fromRGB(220, 230, 240), Enum.Material.Metal, CFrame.new(0, 2.7, 0.3) * CFrame.Angles(math.rad(45), 0, 0), m)
	makeWeld(handle, hookTip)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 2. Pirate Hammer (pirate_hammer)
local function buildPirateHammer(): Model
	local m = Instance.new("Model")
	m.Name = "PirateHammer"

	local shaft = makePart("Handle", Vector3.new(0.35, 3.8, 0.35), Color3.fromRGB(70, 40, 20), Enum.Material.Wood, CFrame.new(0, 1.9, 0), m)
	
	local head = makePart("HammerHead", Vector3.new(1.2, 1.0, 1.8), Color3.fromRGB(110, 115, 120), Enum.Material.Metal, CFrame.new(0, 3.4, 0), m)
	makeWeld(shaft, head)

	local ring1 = makePart("GoldRing1", Vector3.new(1.25, 0.15, 1.85), Color3.fromRGB(230, 180, 40), Enum.Material.Metal, CFrame.new(0, 3.7, 0), m)
	makeWeld(shaft, ring1)

	bakeHilt(m, shaft, 0.3)
	return m
end

-- 3. Pirate Saber (pirate_saber)
local function buildPirateSaber(): Model
	local m = Instance.new("Model")
	m.Name = "PirateSaber"

	local handle = makePart("Handle", Vector3.new(0.3, 1.2, 0.3), Color3.fromRGB(40, 30, 25), Enum.Material.SmoothPlastic, CFrame.new(0, 0.6, 0), m)
	
	local basketGuard = makePart("BasketGuard", Vector3.new(0.9, 0.4, 0.9), Color3.fromRGB(210, 170, 50), Enum.Material.Metal, CFrame.new(0, 1.2, 0), m)
	makeWeld(handle, basketGuard)

	local blade = makePart("Blade", Vector3.new(0.15, 3.0, 0.5), Color3.fromRGB(210, 220, 230), Enum.Material.Metal, CFrame.new(0, 2.8, 0.1) * CFrame.Angles(math.rad(5), 0, 0), m)
	makeWeld(handle, blade)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 4. Golden Plated Sword (golden_plated_sword)
local function buildGoldenPlatedSword(): Model
	local m = Instance.new("Model")
	m.Name = "GoldenPlatedSword"

	local handle = makePart("Handle", Vector3.new(0.3, 1.2, 0.3), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, CFrame.new(0, 0.6, 0), m)
	
	local crossguard = makePart("Crossguard", Vector3.new(1.4, 0.25, 0.4), Color3.fromRGB(245, 195, 40), Enum.Material.Metal, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, crossguard)

	local gem = makePart("Gem", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(239, 68, 68), Enum.Material.Neon, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, gem)

	local blade = makePart("Blade", Vector3.new(0.2, 3.2, 0.45), Color3.fromRGB(255, 215, 70), Enum.Material.Metal, CFrame.new(0, 2.95, 0), m)
	makeWeld(handle, blade)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 5. Captain Axe (captain_axe)
local function buildCaptainAxe(): Model
	local m = Instance.new("Model")
	m.Name = "CaptainAxe"

	local shaft = makePart("Handle", Vector3.new(0.35, 4.2, 0.35), Color3.fromRGB(60, 35, 15), Enum.Material.Wood, CFrame.new(0, 2.1, 0), m)

	local axeBlade1 = makePart("AxeBladeL", Vector3.new(0.15, 1.8, 1.2), Color3.fromRGB(180, 190, 200), Enum.Material.Metal, CFrame.new(0, 3.5, 0.6), m)
	makeWeld(shaft, axeBlade1)

	local axeBlade2 = makePart("AxeBladeR", Vector3.new(0.15, 1.8, 1.2), Color3.fromRGB(180, 190, 200), Enum.Material.Metal, CFrame.new(0, 3.5, -0.6), m)
	makeWeld(shaft, axeBlade2)

	local skullCenter = makePart("SkullEmblem", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, CFrame.new(0, 3.5, 0), m)
	makeWeld(shaft, skullCenter)

	bakeHilt(m, shaft, 0.3)
	return m
end

-- 6. Element Blade (element_blade)
local function buildElementBlade(): Model
	local m = Instance.new("Model")
	m.Name = "ElementBlade"

	local handle = makePart("Handle", Vector3.new(0.3, 1.2, 0.3), Color3.fromRGB(20, 30, 40), Enum.Material.SmoothPlastic, CFrame.new(0, 0.6, 0), m)

	local guard = makePart("Guard", Vector3.new(1.3, 0.3, 0.4), Color3.fromRGB(16, 185, 129), Enum.Material.Neon, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guard)

	local blade = makePart("Blade", Vector3.new(0.2, 3.4, 0.5), Color3.fromRGB(56, 189, 248), Enum.Material.Neon, CFrame.new(0, 3.05, 0), m)
	makeWeld(handle, blade)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 7. Emerald Blade (emerald_blade)
local function buildEmeraldBlade(): Model
	local m = Instance.new("Model")
	m.Name = "EmeraldBlade"

	local handle = makePart("Handle", Vector3.new(0.3, 1.2, 0.3), Color3.fromRGB(15, 25, 20), Enum.Material.SmoothPlastic, CFrame.new(0, 0.6, 0), m)

	local guard = makePart("Guard", Vector3.new(1.4, 0.3, 0.45), Color3.fromRGB(16, 185, 129), Enum.Material.Metal, CFrame.new(0, 1.25, 0), m)
	makeWeld(handle, guard)

	local blade = makePart("Blade", Vector3.new(0.22, 3.5, 0.5), Color3.fromRGB(52, 211, 153), Enum.Material.Glass, CFrame.new(0, 3.1, 0), m)
	makeWeld(handle, blade)

	bakeHilt(m, handle, 0.2)
	return m
end

-- 8. Sea Dagger (sea_dagger)
local function buildSeaDagger(): Model
	local m = Instance.new("Model")
	m.Name = "SeaDagger"

	local handle = makePart("Handle", Vector3.new(0.25, 0.9, 0.25), Color3.fromRGB(240, 230, 220), Enum.Material.SmoothPlastic, CFrame.new(0, 0.45, 0), m)

	local guard = makePart("Guard", Vector3.new(0.8, 0.2, 0.3), Color3.fromRGB(244, 114, 182), Enum.Material.SmoothPlastic, CFrame.new(0, 0.95, 0), m)
	makeWeld(handle, guard)

	local blade = makePart("Blade", Vector3.new(0.15, 2.0, 0.35), Color3.fromRGB(14, 165, 233), Enum.Material.Neon, CFrame.new(0, 2.0, 0), m)
	makeWeld(handle, blade)

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
