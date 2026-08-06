--!strict
--[[
	High-Detail 3D Weapon Generator for Location 2 (Pirate Shore / Maritime Theme).
	Run this script in Roblox Studio Command Bar (or via tools/mcp_exec.js) to generate
	all Location 2 weapons into ReplicatedStorage.WeaponModels!

	Design Standard:
	  - Smooth cylindrical handles with leather/cloth wrapping rings & brass pommels.
	  - Multipart curved guards, basket hilts, skull/gem sockets, and trident prongs.
	  - Multi-layered blades with fullers, beveled edges, and glowing sea-blue/gold accents.
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
	darkWood = color(50, 32, 18),
	richWood = color(85, 55, 30),
	brass = color(210, 160, 50),
	gold = color(245, 195, 40),
	darkIron = color(45, 50, 58),
	steel = color(160, 175, 190),
	brightSteel = color(220, 230, 240),
	coralRed = color(220, 60, 50),
	seaBlue = color(40, 160, 220),
	krakenPurple = color(140, 40, 210),
	glowCyan = color(60, 240, 255),
	glowSea = color(30, 220, 160),
	bone = color(225, 215, 190),
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
	print("Generated Loc2 Weapon:", model.Name)
end

--------------------------------------------------------------------------------
-- LOC 2 WEAPON BUILDERS
--------------------------------------------------------------------------------

-- 1. Pirate Hook (PirateHook)
local function buildPirateHook(): Model
	local m = Instance.new("Model")
	m.Name = "PirateHook"

	local handle = makeCyl(m, "HandleCore", 1.2, 0.22, CFrame.new(0, 0.6, 0), PAL.darkWood, Enum.Material.Wood)
	makeCyl(m, "GripWrap1", 0.3, 0.24, CFrame.new(0, 0.45, 0), PAL.coralRed, Enum.Material.Fabric)
	makeCyl(m, "GripWrap2", 0.3, 0.24, CFrame.new(0, 0.75, 0), PAL.coralRed, Enum.Material.Fabric)
	makeCyl(m, "Pommel", 0.18, 0.28, CFrame.new(0, 0.08, 0), PAL.brass, Enum.Material.Metal)

	-- Brass Cup Guard
	local cup = makeCyl(m, "GuardCup", 0.25, 0.55, CFrame.new(0, 1.2, 0), PAL.brass, Enum.Material.Metal)
	makeCyl(m, "GuardRim", 0.1, 0.6, CFrame.new(0, 1.3, 0), PAL.gold, Enum.Material.Metal)

	-- Curved Hook Shank & Barbs
	local baseShank = makeCyl(m, "ShankBase", 0.8, 0.18, CFrame.new(0, 1.6, 0), PAL.steel, Enum.Material.Metal)
	local hookMid = makeWedge(m, "HookMid", Vector3.new(0.2, 1.1, 0.6), CFrame.new(0, 2.2, 0.25) * CFrame.Angles(math.rad(25), 0, 0), PAL.brightSteel, Enum.Material.Metal)
	local hookTip = makeWedge(m, "HookTip", Vector3.new(0.18, 0.8, 0.5), CFrame.new(0, 2.8, 0.6) * CFrame.Angles(math.rad(130), 0, 0), PAL.brightSteel, Enum.Material.Metal)
	makePart(m, "Barb", Vector3.new(0.1, 0.3, 0.15), CFrame.new(0, 2.5, 0.75) * CFrame.Angles(math.rad(45), 0, 0), PAL.coralRed, Enum.Material.SmoothPlastic)

	finishWeapon(m, handle, 0.15)
	return m
end

-- 2. Pirate Hammer / Anchor Hammer (PirateHammer)
local function buildPirateHammer(): Model
	local m = Instance.new("Model")
	m.Name = "PirateHammer"

	local handle = makeCyl(m, "Shaft", 3.8, 0.18, CFrame.new(0, 1.9, 0), PAL.richWood, Enum.Material.Wood)
	makeCyl(m, "GripBand1", 0.4, 0.2, CFrame.new(0, 0.6, 0), PAL.coralRed, Enum.Material.Fabric)
	makeCyl(m, "GripBand2", 0.4, 0.2, CFrame.new(0, 1.2, 0), PAL.coralRed, Enum.Material.Fabric)
	makeCyl(m, "PommelCap", 0.2, 0.26, CFrame.new(0, 0.1, 0), PAL.brass, Enum.Material.Metal)

	-- Heavy Iron Anchor Head
	local headBlock = makePart(m, "HeadBlock", Vector3.new(0.6, 0.9, 0.6), CFrame.new(0, 3.4, 0), PAL.darkIron, Enum.Material.Metal)
	local anchorRing = makeCyl(m, "AnchorRing", 0.15, 0.45, CFrame.new(0, 3.95, 0), PAL.brass, Enum.Material.Metal)

	-- Flukes (Anchor Arms)
	local leftArm = makeWedge(m, "LeftFluke", Vector3.new(0.35, 1.2, 0.8), CFrame.new(-0.6, 3.2, 0) * CFrame.Angles(0, 0, math.rad(55)), PAL.steel, Enum.Material.Metal)
	local rightArm = makeWedge(m, "RightFluke", Vector3.new(0.35, 1.2, 0.8), CFrame.new(0.6, 3.2, 0) * CFrame.Angles(0, 0, math.rad(-55)), PAL.steel, Enum.Material.Metal)

	-- Barnacle / Gem Highlight
	makePart(m, "GemCore", Vector3.new(0.25, 0.25, 0.65), CFrame.new(0, 3.4, 0), PAL.glowCyan, Enum.Material.Neon)

	finishWeapon(m, handle, 0.2)
	return m
end

-- 3. Pirate Cutlass (Cutlass)
local function buildCutlass(): Model
	local m = Instance.new("Model")
	m.Name = "Cutlass"

	local handle = makeCyl(m, "HandleCore", 1.1, 0.16, CFrame.new(0, 0.55, 0), PAL.darkWood, Enum.Material.Wood)
	makeCyl(m, "Pommel", 0.2, 0.25, CFrame.new(0, 0.08, 0), PAL.brass, Enum.Material.Metal)

	-- Curved Guard D-Ring
	local guardPlate = makeCyl(m, "GuardPlate", 0.12, 0.55, CFrame.new(0, 1.1, 0), PAL.brass, Enum.Material.Metal)
	local dRing = makePart(m, "DRing", Vector3.new(0.12, 1.1, 0.45), CFrame.new(0, 0.55, 0.25), PAL.brass, Enum.Material.Metal)

	-- Broad Curved Cutlass Blade
	local bladeBase = makePart(m, "BladeBase", Vector3.new(0.12, 2.2, 0.45), CFrame.new(0, 2.2, 0), PAL.steel, Enum.Material.Metal, 0.2)
	local bladeCurve = makeWedge(m, "BladeCurve", Vector3.new(0.12, 1.2, 0.6), CFrame.new(0, 3.4, 0.08) * CFrame.Angles(math.rad(8), 0, 0), PAL.brightSteel, Enum.Material.Metal, 0.3)
	local tipWedge = makeWedge(m, "BladeTip", Vector3.new(0.1, 0.8, 0.5), CFrame.new(0, 4.0, 0.25) * CFrame.Angles(math.rad(-15), 0, 0), PAL.brightSteel, Enum.Material.Metal, 0.3)

	-- Fuller Grooves
	makePart(m, "Fuller", Vector3.new(0.14, 2.0, 0.1), CFrame.new(0, 2.3, -0.05), PAL.darkIron, Enum.Material.Metal)

	finishWeapon(m, handle, 0.15)
	return m
end

-- 4. Corsair Sabre (CorsairSabre)
local function buildCorsairSabre(): Model
	local m = Instance.new("Model")
	m.Name = "CorsairSabre"

	local handle = makeCyl(m, "HandleCore", 1.2, 0.15, CFrame.new(0, 0.6, 0), PAL.richWood, Enum.Material.Wood)
	makeCyl(m, "GripRing1", 0.1, 0.17, CFrame.new(0, 0.4, 0), PAL.gold, Enum.Material.Metal)
	makeCyl(m, "GripRing2", 0.1, 0.17, CFrame.new(0, 0.8, 0), PAL.gold, Enum.Material.Metal)
	makeCyl(m, "PommelGem", 0.22, 0.24, CFrame.new(0, 0.08, 0), PAL.coralRed, Enum.Material.Neon)

	-- Ornate Shell Guard
	local guardCross = makePart(m, "GuardCross", Vector3.new(0.7, 0.12, 0.7), CFrame.new(0, 1.2, 0), PAL.gold, Enum.Material.Metal)
	local shellBow = makeWedge(m, "ShellBow", Vector3.new(0.5, 0.9, 0.4), CFrame.new(0, 0.75, 0.2) * CFrame.Angles(math.rad(180), 0, 0), PAL.brass, Enum.Material.Metal)

	-- Slender Curved Sabre Blade
	local bladeLower = makePart(m, "BladeLower", Vector3.new(0.1, 2.4, 0.35), CFrame.new(0, 2.4, 0), PAL.brightSteel, Enum.Material.Metal, 0.3)
	local bladeUpper = makeWedge(m, "BladeUpper", Vector3.new(0.08, 1.6, 0.45), CFrame.new(0, 4.0, 0.08) * CFrame.Angles(math.rad(10), 0, 0), PAL.brightSteel, Enum.Material.Metal, 0.4)
	makePart(m, "SabreGlow", Vector3.new(0.12, 2.0, 0.06), CFrame.new(0, 2.5, 0.05), PAL.glowSea, Enum.Material.Neon)

	finishWeapon(m, handle, 0.15)
	return m
end

-- 5. Sea Trident (SeaTrident)
local function buildSeaTrident(): Model
	local m = Instance.new("Model")
	m.Name = "SeaTrident"

	local shaft = makeCyl(m, "LongShaft", 4.2, 0.16, CFrame.new(0, 2.1, 0), PAL.darkIron, Enum.Material.Metal)
	makeCyl(m, "ShaftGrip1", 0.5, 0.18, CFrame.new(0, 1.0, 0), PAL.seaBlue, Enum.Material.Fabric)
	makeCyl(m, "ShaftGrip2", 0.5, 0.18, CFrame.new(0, 2.0, 0), PAL.seaBlue, Enum.Material.Fabric)
	makeCyl(m, "BottomSpear", 0.5, 0.2, CFrame.new(0, 0.1, 0), PAL.brass, Enum.Material.Metal)

	-- Trident Crown Base
	local crownBase = makePart(m, "CrownBase", Vector3.new(0.9, 0.4, 0.3), CFrame.new(0, 4.2, 0), PAL.brass, Enum.Material.Metal)
	local gemCenter = makePart(m, "TridentGem", Vector3.new(0.3, 0.3, 0.35), CFrame.new(0, 4.2, 0), PAL.glowCyan, Enum.Material.Neon)

	-- 3 Prongs (Center long, Left & Right curved)
	local centerProng = makePart(m, "CenterProng", Vector3.new(0.12, 1.8, 0.22), CFrame.new(0, 5.1, 0), PAL.brightSteel, Enum.Material.Metal, 0.4)
	local centerTip = makeWedge(m, "CenterTip", Vector3.new(0.1, 0.6, 0.2), CFrame.new(0, 6.1, 0), PAL.glowCyan, Enum.Material.Neon)

	local leftProng = makeWedge(m, "LeftProng", Vector3.new(0.1, 1.4, 0.3), CFrame.new(-0.45, 4.9, 0) * CFrame.Angles(0, 0, math.rad(-12)), PAL.brightSteel, Enum.Material.Metal, 0.3)
	local rightProng = makeWedge(m, "RightProng", Vector3.new(0.1, 1.4, 0.3), CFrame.new(0.45, 4.9, 0) * CFrame.Angles(0, 0, math.rad(12)), PAL.brightSteel, Enum.Material.Metal, 0.3)

	finishWeapon(m, shaft, 0.2)
	return m
end

-- 6. Cannon Blade (Cannonblade)
local function buildCannonblade(): Model
	local m = Instance.new("Model")
	m.Name = "Cannonblade"

	local handle = makeCyl(m, "HandleCore", 1.3, 0.18, CFrame.new(0, 0.65, 0), PAL.darkWood, Enum.Material.Wood)
	makeCyl(m, "Pommel", 0.22, 0.28, CFrame.new(0, 0.1, 0), PAL.darkIron, Enum.Material.Metal)

	-- Cannon Barrel Hilt Assembly
	local cannonBarrel = makeCyl(m, "CannonBarrel", 1.8, 0.35, CFrame.new(0, 2.0, 0), PAL.darkIron, Enum.Material.Metal)
	local muzzleRing = makeCyl(m, "MuzzleRing", 0.15, 0.4, CFrame.new(0, 2.85, 0), PAL.brass, Enum.Material.Metal)
	makePart(m, "FusableGlow", Vector3.new(0.12, 0.12, 0.4), CFrame.new(0, 1.4, -0.3), PAL.coralRed, Enum.Material.Neon)

	-- Blade Mounted on Top of Barrel
	local bladeSpine = makePart(m, "BladeSpine", Vector3.new(0.14, 2.6, 0.5), CFrame.new(0, 3.4, 0.1), PAL.steel, Enum.Material.Metal, 0.2)
	local bladeTip = makeWedge(m, "BladeTip", Vector3.new(0.12, 1.0, 0.5), CFrame.new(0, 4.8, 0.1), PAL.brightSteel, Enum.Material.Metal, 0.3)

	finishWeapon(m, handle, 0.2)
	return m
end

-- 7. Kraken Blade (KrakenBlade)
local function buildKrakenBlade(): Model
	local m = Instance.new("Model")
	m.Name = "KrakenBlade"

	local handle = makeCyl(m, "HandleCore", 1.3, 0.18, CFrame.new(0, 0.65, 0), PAL.darkIron, Enum.Material.Metal)
	makeCyl(m, "KrakenEyePommel", 0.28, 0.28, CFrame.new(0, 0.1, 0), PAL.glowCyan, Enum.Material.Neon)

	-- Tentacle Curved Guard
	local tentacle1 = makeWedge(m, "Tentacle1", Vector3.new(0.25, 1.0, 0.6), CFrame.new(-0.35, 1.3, 0) * CFrame.Angles(0, 0, math.rad(-35)), PAL.krakenPurple, Enum.Material.SmoothPlastic)
	local tentacle2 = makeWedge(m, "Tentacle2", Vector3.new(0.25, 1.0, 0.6), CFrame.new(0.35, 1.3, 0) * CFrame.Angles(0, 0, math.rad(35)), PAL.krakenPurple, Enum.Material.SmoothPlastic)

	-- Organic Jagged Kraken Blade
	local bladeCore = makePart(m, "BladeCore", Vector3.new(0.16, 2.8, 0.55), CFrame.new(0, 2.7, 0), PAL.darkIron, Enum.Material.Metal)
	local biolumVein = makePart(m, "BiolumVein", Vector3.new(0.18, 2.4, 0.15), CFrame.new(0, 2.7, 0), PAL.glowCyan, Enum.Material.Neon)

	local edgeTooth1 = makeWedge(m, "Tooth1", Vector3.new(0.1, 0.6, 0.3), CFrame.new(0, 2.2, 0.35) * CFrame.Angles(math.rad(20), 0, 0), PAL.brightSteel, Enum.Material.Metal)
	local edgeTooth2 = makeWedge(m, "Tooth2", Vector3.new(0.1, 0.6, 0.3), CFrame.new(0, 3.0, 0.35) * CFrame.Angles(math.rad(20), 0, 0), PAL.brightSteel, Enum.Material.Metal)
	local tipWedge = makeWedge(m, "KrakenTip", Vector3.new(0.12, 1.1, 0.55), CFrame.new(0, 4.4, 0.05), PAL.brightSteel, Enum.Material.Metal, 0.4)

	finishWeapon(m, handle, 0.2)
	return m
end

-- 8. Pirate Captain Rapier (PirateCaptainRapier)
local function buildPirateCaptainRapier(): Model
	local m = Instance.new("Model")
	m.Name = "PirateCaptainRapier"

	local handle = makeCyl(m, "HandleCore", 1.2, 0.14, CFrame.new(0, 0.6, 0), PAL.richWood, Enum.Material.Wood)
	makeCyl(m, "CrownPommel", 0.25, 0.26, CFrame.new(0, 0.08, 0), PAL.gold, Enum.Material.Metal)

	-- Full Gold Swept-Hilt Basket Guard
	local basketCore = makeCyl(m, "BasketCore", 0.2, 0.7, CFrame.new(0, 1.2, 0), PAL.gold, Enum.Material.Metal)
	local basketSide1 = makePart(m, "BasketSide1", Vector3.new(0.65, 0.8, 0.45), CFrame.new(0, 0.8, 0.15), PAL.brass, Enum.Material.Metal)
	local rubygem = makePart(m, "CaptainRuby", Vector3.new(0.2, 0.2, 0.25), CFrame.new(0, 1.25, 0.36), PAL.coralRed, Enum.Material.Neon)

	-- Needle-Sharp Rapier Blade
	local bladeBase = makeCyl(m, "RapierBlade", 3.4, 0.08, CFrame.new(0, 2.9, 0), PAL.brightSteel, Enum.Material.Metal)
	local needleTip = makeWedge(m, "NeedleTip", Vector3.new(0.08, 0.8, 0.08), CFrame.new(0, 4.8, 0), PAL.brightSteel, Enum.Material.Metal, 0.5)

	finishWeapon(m, handle, 0.15)
	return m
end

--------------------------------------------------------------------------------
-- RUN ALL BUILDERS
--------------------------------------------------------------------------------
print("========== BUILDING LOCATION 2 PIRATE WEAPONS ==========")
buildPirateHook()
buildPirateHammer()
buildCutlass()
buildCorsairSabre()
buildSeaTrident()
buildCannonblade()
buildKrakenBlade()
buildPirateCaptainRapier()
print("========== LOCATION 2 WEAPONS BUILT SUCCESSFULLY ==========")
