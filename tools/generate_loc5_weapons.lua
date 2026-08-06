--!strict
--[[
	High-Detail 3D Weapon Generator for Location 5 (Ash Canyons / Volcanic & Magma Theme).
	Run this script in Roblox Studio Command Bar (or via tools/mcp_exec.js) to generate
	all Location 5 weapons into ReplicatedStorage.WeaponModels!

	Design Standard:
	  - Volcanic stone, obsidian glass, and basalt rock textures with neon lava veins.
	  - Multi-layered serrated blades, glowing magma cores, and phoenix ember wing guards.
	  - PrimaryPart named "Handle" with baked "SM_Hilt" attachment.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponModelsFolder = ReplicatedStorage:FindFirstChild("WeaponModels")
if not WeaponModelsFolder then
	WeaponModelsFolder = Instance.new("Folder")
	WeaponModelsFolder.Name = "WeaponModels"
	WeaponModelsFolder.Parent = ReplicatedStorage
end

local function color(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local PAL = {
	ashGrey = color(60, 60, 65),
	darkObsidian = color(22, 22, 26),
	basalt = color(40, 38, 42),
	moltenOrange = color(255, 110, 10),
	magmaRed = color(230, 40, 20),
	brightLava = color(255, 170, 30),
	amberGlow = color(255, 200, 50),
	phoenixGold = color(245, 195, 40),
	phoenixCrimson = color(220, 30, 60),
	steelDark = color(80, 85, 95),
}

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?, shiny: number?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Color = col
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shiny then
		p.Reflectance = shiny
	end
	p.Parent = parent
	return p
end

local function makeCyl(parent: Instance, name: string, height: number, radius: number, cf: CFrame, col: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Color = col
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeWedge(parent: Instance, name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?): WedgePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Color = col
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weldAll(model: Model, handle: BasePart)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= handle then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = d
			w.Parent = d
			d.Anchored = false
		end
	end
	handle.Anchored = false
end

local function finishWeapon(model: Model, handle: BasePart, hiltYOffset: number)
	handle.Name = "Handle"
	model.PrimaryPart = handle

	local existing = WeaponModelsFolder:FindFirstChild(model.Name)
	if existing then
		existing:Destroy()
	end

	weldAll(model, handle)

	local hilt = Instance.new("Attachment")
	hilt.Name = "SM_Hilt"
	hilt.CFrame = CFrame.new(0, -handle.Size.Y / 2 + hiltYOffset, 0)
	hilt.Parent = handle

	model.Parent = WeaponModelsFolder
	print("Generated Loc5 Weapon:", model.Name)
end

--------------------------------------------------------------------------------
-- LOC 5 WEAPON BUILDERS
--------------------------------------------------------------------------------

-- 1. Ash Shiv (AshShiv)
local function buildAshShiv(): Model
	local m = Instance.new("Model")
	m.Name = "AshShiv"

	local handle = makeCyl(m, "HandleCore", 0.95, 0.14, CFrame.new(0, 0.48, 0), PAL.basalt, Enum.Material.Slate)
	makeCyl(m, "GripWrap", 0.45, 0.16, CFrame.new(0, 0.5, 0), PAL.ashGrey, Enum.Material.Fabric)
	makeCyl(m, "Pommel", 0.16, 0.2, CFrame.new(0, 0.08, 0), PAL.darkObsidian, Enum.Material.Glass)

	-- Serrated Ash Dagger Blade
	local guard = makePart(m, "Guard", Vector3.new(0.45, 0.12, 0.3), CFrame.new(0, 1.0, 0), PAL.basalt, Enum.Material.Slate)
	local bladeBody = makePart(m, "BladeBody", Vector3.new(0.12, 1.6, 0.38), CFrame.new(0, 1.8, 0), PAL.darkObsidian, Enum.Material.Glass, 0.3)
	local emberLine = makePart(m, "EmberLine", Vector3.new(0.14, 1.4, 0.08), CFrame.new(0, 1.8, 0.05), PAL.moltenOrange, Enum.Material.Neon)
	local tipWedge = makeWedge(m, "ShivTip", Vector3.new(0.1, 0.6, 0.35), CFrame.new(0, 2.7, 0), PAL.darkObsidian, Enum.Material.Glass, 0.4)

	finishWeapon(m, handle, 0.12)
	return m
end

-- 2. Magma Maul (MagmaMaul)
local function buildMagmaMaul(): Model
	local m = Instance.new("Model")
	m.Name = "MagmaMaul"

	local shaft = makeCyl(m, "Shaft", 3.8, 0.18, CFrame.new(0, 1.9, 0), PAL.basalt, Enum.Material.Slate)
	makeCyl(m, "ShaftRing1", 0.3, 0.22, CFrame.new(0, 0.8, 0), PAL.magmaRed, Enum.Material.Neon)
	makeCyl(m, "ShaftRing2", 0.3, 0.22, CFrame.new(0, 1.8, 0), PAL.magmaRed, Enum.Material.Neon)
	makeCyl(m, "PommelSpike", 0.3, 0.24, CFrame.new(0, 0.1, 0), PAL.darkObsidian, Enum.Material.Glass)

	-- Massive Volcanic Spiked Head with Glowing Magma Core
	local headCore = makePart(m, "HeadCore", Vector3.new(0.9, 1.1, 0.9), CFrame.new(0, 3.5, 0), PAL.darkObsidian, Enum.Material.Glass)
	makePart(m, "MagmaHeart", Vector3.new(1.02, 0.9, 1.02), CFrame.new(0, 3.5, 0), PAL.moltenOrange, Enum.Material.Neon)

	-- 4 Spiked Basalt Plates
	makeWedge(m, "SpikeFront", Vector3.new(0.4, 0.8, 0.6), CFrame.new(0, 3.5, 0.75) * CFrame.Angles(math.rad(90), 0, 0), PAL.basalt, Enum.Material.Slate)
	makeWedge(m, "SpikeBack", Vector3.new(0.4, 0.8, 0.6), CFrame.new(0, 3.5, -0.75) * CFrame.Angles(math.rad(-90), 0, 0), PAL.basalt, Enum.Material.Slate)
	makeWedge(m, "SpikeLeft", Vector3.new(0.6, 0.8, 0.4), CFrame.new(-0.75, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), PAL.basalt, Enum.Material.Slate)
	makeWedge(m, "SpikeRight", Vector3.new(0.6, 0.8, 0.4), CFrame.new(0.75, 3.5, 0) * CFrame.Angles(0, 0, math.rad(-90)), PAL.basalt, Enum.Material.Slate)

	finishWeapon(m, shaft, 0.2)
	return m
end

-- 3. Obsidian Glaive (ObsidianGlaive)
local function buildObsidianGlaive(): Model
	local m = Instance.new("Model")
	m.Name = "ObsidianGlaive"

	local shaft = makeCyl(m, "GlaiveShaft", 4.4, 0.16, CFrame.new(0, 2.2, 0), PAL.darkObsidian, Enum.Material.Glass)
	makeCyl(m, "MidGrip", 0.8, 0.18, CFrame.new(0, 1.8, 0), PAL.ashGrey, Enum.Material.Fabric)
	makeCyl(m, "CounterWeight", 0.4, 0.22, CFrame.new(0, 0.2, 0), PAL.basalt, Enum.Material.Slate)
	makePart(m, "BottomGlow", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.05, 0), PAL.moltenOrange, Enum.Material.Neon)

	-- Curved Naginata-Style Obsidian Blade with Lava Channel
	local socket = makePart(m, "BladeSocket", Vector3.new(0.35, 0.6, 0.35), CFrame.new(0, 4.4, 0), PAL.basalt, Enum.Material.Slate)
	local bladeSpine = makePart(m, "BladeSpine", Vector3.new(0.14, 2.8, 0.45), CFrame.new(0, 5.7, 0.08), PAL.darkObsidian, Enum.Material.Glass, 0.4)
	local lavaVein = makePart(m, "LavaVein", Vector3.new(0.16, 2.4, 0.1), CFrame.new(0, 5.6, 0.05), PAL.brightLava, Enum.Material.Neon)

	local curvedTip = makeWedge(m, "CurvedTip", Vector3.new(0.12, 1.4, 0.6), CFrame.new(0, 7.2, 0.2) * CFrame.Angles(math.rad(15), 0, 0), PAL.darkObsidian, Enum.Material.Glass, 0.5)

	finishWeapon(m, shaft, 0.2)
	return m
end

-- 4. Inferno Blade (InfernoBlade)
local function buildInfernoBlade(): Model
	local m = Instance.new("Model")
	m.Name = "InfernoBlade"

	local handle = makeCyl(m, "HandleCore", 1.2, 0.16, CFrame.new(0, 0.6, 0), PAL.basalt, Enum.Material.Slate)
	makeCyl(m, "PommelGem", 0.24, 0.26, CFrame.new(0, 0.08, 0), PAL.magmaRed, Enum.Material.Neon)

	-- Winged Lava Guard
	local guardCenter = makePart(m, "GuardCenter", Vector3.new(0.4, 0.2, 0.4), CFrame.new(0, 1.2, 0), PAL.darkObsidian, Enum.Material.Glass)
	local leftWing = makeWedge(m, "LeftWing", Vector3.new(0.2, 0.9, 0.5), CFrame.new(-0.4, 1.3, 0) * CFrame.Angles(0, 0, math.rad(-40)), PAL.moltenOrange, Enum.Material.Neon)
	local rightWing = makeWedge(m, "RightWing", Vector3.new(0.2, 0.9, 0.5), CFrame.new(0.4, 1.3, 0) * CFrame.Angles(0, 0, math.rad(40)), PAL.moltenOrange, Enum.Material.Neon)

	-- Double-Edged Flaming Blade Body
	local bladeBase = makePart(m, "BladeBase", Vector3.new(0.14, 2.6, 0.55), CFrame.new(0, 2.6, 0), PAL.darkObsidian, Enum.Material.Glass, 0.3)
	local coreFire = makePart(m, "CoreFire", Vector3.new(0.16, 2.3, 0.2), CFrame.new(0, 2.6, 0), PAL.brightLava, Enum.Material.Neon)
	local bladeTip = makeWedge(m, "BladeTip", Vector3.new(0.12, 1.0, 0.55), CFrame.new(0, 4.3, 0), PAL.darkObsidian, Enum.Material.Glass, 0.4)

	finishWeapon(m, handle, 0.15)
	return m
end

-- 5. Volcano God Sword (VolcanoGodSword)
local function buildVolcanoGodSword(): Model
	local m = Instance.new("Model")
	m.Name = "VolcanoGodSword"

	local handle = makeCyl(m, "HandleCore", 1.5, 0.2, CFrame.new(0, 0.75, 0), PAL.basalt, Enum.Material.Slate)
	makeCyl(m, "GripGlow1", 0.3, 0.22, CFrame.new(0, 0.5, 0), PAL.magmaRed, Enum.Material.Neon)
	makeCyl(m, "GripGlow2", 0.3, 0.22, CFrame.new(0, 1.0, 0), PAL.magmaRed, Enum.Material.Neon)
	makeCyl(m, "GodPommel", 0.35, 0.32, CFrame.new(0, 0.1, 0), PAL.darkObsidian, Enum.Material.Glass)

	-- Massive Volcanic Crossguard
	local guardMain = makePart(m, "GuardMain", Vector3.new(1.4, 0.3, 0.5), CFrame.new(0, 1.5, 0), PAL.basalt, Enum.Material.Slate)
	local eyeCore = makePart(m, "VolcanoEye", Vector3.new(0.35, 0.35, 0.52), CFrame.new(0, 1.5, 0), PAL.amberGlow, Enum.Material.Neon)

	-- Colossal Greatsword Blade with Cracked Basalt Armor Plates
	local bladeCore = makePart(m, "BladeCore", Vector3.new(0.18, 3.4, 0.8), CFrame.new(0, 3.3, 0), PAL.brightLava, Enum.Material.Neon)
	local armorLeft = makePart(m, "ArmorLeft", Vector3.new(0.08, 3.0, 0.3), CFrame.new(-0.25, 3.3, 0), PAL.darkObsidian, Enum.Material.Glass)
	local armorRight = makePart(m, "ArmorRight", Vector3.new(0.08, 3.0, 0.3), CFrame.new(0.25, 3.3, 0), PAL.darkObsidian, Enum.Material.Glass)

	local godTip = makeWedge(m, "GodTip", Vector3.new(0.16, 1.2, 0.8), CFrame.new(0, 5.4, 0), PAL.darkObsidian, Enum.Material.Glass, 0.4)

	finishWeapon(m, handle, 0.2)
	return m
end

-- 6. Phoenix Ash Blade (PhoenixAshBlade)
local function buildPhoenixAshBlade(): Model
	local m = Instance.new("Model")
	m.Name = "PhoenixAshBlade"

	local handle = makeCyl(m, "HandleCore", 1.3, 0.16, CFrame.new(0, 0.65, 0), PAL.phoenixGold, Enum.Material.Metal)
	makeCyl(m, "GripWrap", 0.6, 0.18, CFrame.new(0, 0.65, 0), PAL.ashGrey, Enum.Material.Fabric)
	makeCyl(m, "PhoenixEggPommel", 0.26, 0.28, CFrame.new(0, 0.1, 0), PAL.amberGlow, Enum.Material.Neon)

	-- Majestic Phoenix Wing Guard
	local guardCore = makePart(m, "GuardCore", Vector3.new(0.4, 0.2, 0.4), CFrame.new(0, 1.3, 0), PAL.phoenixGold, Enum.Material.Metal)
	local wingL = makeWedge(m, "PhoenixWingL", Vector3.new(0.22, 1.2, 0.65), CFrame.new(-0.45, 1.4, 0) * CFrame.Angles(0, 0, math.rad(-45)), PAL.phoenixCrimson, Enum.Material.Neon)
	local wingR = makeWedge(m, "PhoenixWingR", Vector3.new(0.22, 1.2, 0.65), CFrame.new(0.45, 1.4, 0) * CFrame.Angles(0, 0, math.rad(45)), PAL.phoenixCrimson, Enum.Material.Neon)

	-- Radiant Phoenix Feather Blade
	local bladeCore = makePart(m, "BladeCore", Vector3.new(0.14, 3.0, 0.6), CFrame.new(0, 2.9, 0), PAL.phoenixGold, Enum.Material.Metal, 0.4)
	local featherGlow = makePart(m, "FeatherGlow", Vector3.new(0.16, 2.6, 0.25), CFrame.new(0, 2.9, 0), PAL.amberGlow, Enum.Material.Neon)

	local featherTip = makeWedge(m, "PhoenixTip", Vector3.new(0.12, 1.2, 0.6), CFrame.new(0, 4.8, 0), PAL.phoenixGold, Enum.Material.Metal, 0.5)

	finishWeapon(m, handle, 0.18)
	return m
end

--------------------------------------------------------------------------------
-- RUN ALL BUILDERS
--------------------------------------------------------------------------------
print("========== BUILDING LOCATION 5 VOLCANIC WEAPONS ==========")
buildAshShiv()
buildMagmaMaul()
buildObsidianGlaive()
buildInfernoBlade()
buildVolcanoGodSword()
buildPhoenixAshBlade()
print("========== LOCATION 5 WEAPONS BUILT SUCCESSFULLY ==========")
