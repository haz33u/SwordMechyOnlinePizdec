--[[
	Edit-mode: build Loc1 Dark Forest DF_* weapon models with materials.
	Parents under ReplicatedStorage.WeaponModels. Safe to re-run (replaces DF_*).
	Then Save Place.
]]

local RS = game:GetService("ReplicatedStorage")

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if f then
		return f
	end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local wm = folder(RS, "WeaponModels")

local function C(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local PAL = {
	bark = C(55, 38, 28),
	barkLight = C(90, 65, 48),
	moss = C(40, 75, 38),
	rust = C(95, 58, 42),
	steel = C(120, 128, 135),
	steelDark = C(55, 60, 68),
	bone = C(200, 185, 150),
	cord = C(110, 85, 55),
	leaf = C(70, 100, 55),
	amber = C(220, 130, 40),
	shadow = C(25, 18, 40),
	violet = C(100, 65, 160),
	glowSpirit = C(90, 230, 140),
	glowAmber = C(255, 160, 50),
	glowShadow = C(140, 90, 255),
}

local function part(parent, name, size, cf, color, mat, shiny)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shiny then
		p.Reflectance = shiny
	end
	p.Parent = parent
	return p
end

local function cyl(parent, name, height, radius, cf, color, mat)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	-- Cylinder default long axis is X; we build along Y for blade
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Anchored = true
	p.CanCollide = false
	p.Massless = true
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function weldAll(model, handle)
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

local function finish(model, handleName)
	local handle = model:FindFirstChild(handleName) or model:FindFirstChildWhichIsA("BasePart")
	handle.Name = "Handle"
	model.PrimaryPart = handle
	-- SM_Hilt near pommel (−Y relative to grip origin at 0)
	local att = Instance.new("Attachment")
	att.Name = "SM_Hilt"
	att.Position = Vector3.new(0, -0.05, 0)
	att.Parent = handle
	weldAll(model, handle)
	model:SetAttribute("SM_HiltBaked", true)
	model:SetAttribute("DF_MaterialSet", true)
	return model
end

local function clearOld(name)
	local old = wm:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local function model(name)
	clearOld(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = wm
	return m
end

-- Grip origin ~ y=0, tip +Y. Authored ~4 studs, code scales 0.52.
local function build_StarterStick()
	local m = model("DF_StarterStick")
	local h = cyl(m, "Handle", 1.1, 0.085, CFrame.new(0, -0.2, 0), PAL.bark, Enum.Material.Wood)
	cyl(m, "Shaft", 2.4, 0.075, CFrame.new(0, 1.4, 0), PAL.barkLight, Enum.Material.Wood)
	part(m, "BladeFlat", Vector3.new(0.22, 1.8, 0.09), CFrame.new(0, 2.0, 0), PAL.barkLight, Enum.Material.Wood)
	for i, y in ipairs({ -0.35, -0.15, 0.05 }) do
		cyl(m, "Cord" .. i, 0.08, 0.1, CFrame.new(0, y, 0), PAL.cord, Enum.Material.Fabric)
	end
	part(m, "Moss", Vector3.new(0.12, 0.2, 0.06), CFrame.new(0.08, 1.5, 0.05), PAL.moss, Enum.Material.Grass)
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.16, 0.35, 0.1)
	tip.CFrame = CFrame.new(0, 3.05, 0)
	tip.Color = PAL.barkLight
	tip.Material = Enum.Material.Wood
	tip.Anchored = true
	tip.CanCollide = false
	tip.Massless = true
	tip.Parent = m
	return finish(m, "Handle")
end

local function build_MossRust()
	local m = model("DF_MossRust")
	cyl(m, "Handle", 1.0, 0.07, CFrame.new(0, -0.35, 0), PAL.bark, Enum.Material.Wood)
	part(m, "Guard", Vector3.new(0.55, 0.12, 0.1), CFrame.new(0, 0.25, 0), PAL.rust, Enum.Material.CorrodedMetal)
	part(m, "MossL", Vector3.new(0.14, 0.1, 0.1), CFrame.new(-0.25, 0.28, 0.04), PAL.moss, Enum.Material.Grass)
	part(m, "MossR", Vector3.new(0.12, 0.08, 0.09), CFrame.new(0.24, 0.28, -0.03), PAL.moss, Enum.Material.Grass)
	part(m, "Blade", Vector3.new(0.2, 2.4, 0.07), CFrame.new(0, 1.55, 0), PAL.steelDark, Enum.Material.Metal, 0.08)
	part(m, "Pommel", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, -0.9, 0), PAL.rust, Enum.Material.CorrodedMetal)
	return finish(m, "Handle")
end

local function build_BoneThorn()
	local m = model("DF_BoneThorn")
	cyl(m, "Handle", 0.9, 0.06, CFrame.new(0, -0.25, 0), PAL.cord, Enum.Material.Fabric)
	cyl(m, "Wrap", 0.35, 0.075, CFrame.new(0, -0.05, 0), PAL.bark, Enum.Material.Wood)
	part(m, "Blade", Vector3.new(0.14, 1.7, 0.06), CFrame.new(0.02, 1.05, 0), PAL.bone, Enum.Material.SmoothPlastic)
	part(m, "Tip", Vector3.new(0.08, 0.35, 0.05), CFrame.new(0.05, 2.0, 0), PAL.bone, Enum.Material.SmoothPlastic)
	return finish(m, "Handle")
end

local function build_RootMace()
	local m = model("DF_RootMace")
	cyl(m, "Handle", 1.4, 0.09, CFrame.new(0, 0.1, 0), PAL.bark, Enum.Material.Wood)
	part(m, "Head", Vector3.new(0.75, 0.7, 0.75), CFrame.new(0, 2.0, 0), PAL.barkLight, Enum.Material.Wood)
	part(m, "Spike1", Vector3.new(0.15, 0.45, 0.15), CFrame.new(0.35, 2.25, 0), PAL.bark, Enum.Material.Wood)
	part(m, "Spike2", Vector3.new(0.15, 0.4, 0.15), CFrame.new(-0.3, 2.2, 0.2), PAL.bark, Enum.Material.Wood)
	part(m, "Spike3", Vector3.new(0.12, 0.38, 0.12), CFrame.new(0.1, 2.35, -0.3), PAL.moss, Enum.Material.Grass)
	part(m, "RootWrap", Vector3.new(0.22, 0.5, 0.22), CFrame.new(0.12, 0.6, 0), PAL.cord, Enum.Material.Wood)
	return finish(m, "Handle")
end

local function build_Twinleaf()
	local m = model("DF_Twinleaf")
	cyl(m, "Handle", 1.0, 0.07, CFrame.new(0, -0.3, 0), PAL.bark, Enum.Material.Wood)
	part(m, "Guard", Vector3.new(0.7, 0.1, 0.12), CFrame.new(0, 0.3, 0), PAL.leaf, Enum.Material.LeafyGrass)
	part(m, "BladeL", Vector3.new(0.18, 2.5, 0.07), CFrame.new(-0.12, 1.6, 0) * CFrame.Angles(0, 0, 0.08), PAL.steel, Enum.Material.Metal, 0.12)
	part(m, "BladeR", Vector3.new(0.18, 2.5, 0.07), CFrame.new(0.12, 1.6, 0) * CFrame.Angles(0, 0, -0.08), PAL.steel, Enum.Material.Metal, 0.12)
	part(m, "Pommel", Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, -0.85, 0), PAL.leaf, Enum.Material.Grass)
	return finish(m, "Handle")
end

local function build_SpiritBranch()
	local m = model("DF_SpiritBranch")
	cyl(m, "Handle", 1.2, 0.08, CFrame.new(0, -0.1, 0), PAL.bark, Enum.Material.Wood)
	cyl(m, "Shaft", 2.6, 0.07, CFrame.new(0, 1.6, 0), PAL.barkLight, Enum.Material.Wood)
	part(m, "Crystal", Vector3.new(0.35, 0.55, 0.35), CFrame.new(0, 3.15, 0), PAL.glowSpirit, Enum.Material.Neon, 0.2)
	part(m, "Leaf1", Vector3.new(0.35, 0.08, 0.2), CFrame.new(0.25, 2.5, 0), PAL.leaf, Enum.Material.Grass)
	part(m, "Leaf2", Vector3.new(0.3, 0.08, 0.18), CFrame.new(-0.22, 2.7, 0.05), PAL.moss, Enum.Material.Grass)
	return finish(m, "Handle")
end

local function build_Amberheart()
	local m = model("DF_Amberheart")
	cyl(m, "Handle", 1.05, 0.075, CFrame.new(0, -0.3, 0), PAL.bark, Enum.Material.Wood)
	part(m, "Guard", Vector3.new(0.6, 0.14, 0.14), CFrame.new(0, 0.3, 0), PAL.amber, Enum.Material.Neon, 0.15)
	part(m, "Blade", Vector3.new(0.22, 2.6, 0.08), CFrame.new(0, 1.7, 0), PAL.steel, Enum.Material.Metal, 0.2)
	part(m, "Core", Vector3.new(0.1, 1.8, 0.04), CFrame.new(0, 1.7, 0.06), PAL.glowAmber, Enum.Material.Neon, 0.35)
	part(m, "Pommel", Vector3.new(0.18, 0.18, 0.18), CFrame.new(0, -0.9, 0), PAL.amber, Enum.Material.Neon, 0.2)
	return finish(m, "Handle")
end

local function build_CanopyFang()
	local m = model("DF_CanopyFang")
	cyl(m, "Handle", 1.05, 0.08, CFrame.new(0, -0.28, 0), PAL.bark, Enum.Material.Wood)
	part(m, "Guard", Vector3.new(0.65, 0.12, 0.14), CFrame.new(0, 0.32, 0), PAL.leaf, Enum.Material.Grass)
	part(m, "Blade", Vector3.new(0.28, 2.7, 0.09), CFrame.new(0, 1.75, 0), PAL.steel, Enum.Material.Metal, 0.18)
	part(m, "Fang", Vector3.new(0.12, 0.55, 0.1), CFrame.new(0.18, 2.9, 0) * CFrame.Angles(0, 0, -0.4), PAL.leaf, Enum.Material.Grass)
	part(m, "MossEdge", Vector3.new(0.08, 1.2, 0.05), CFrame.new(-0.14, 1.8, 0.05), PAL.moss, Enum.Material.Grass)
	return finish(m, "Handle")
end

local function build_UmbralBough()
	local m = model("DF_UmbralBough")
	cyl(m, "Handle", 1.05, 0.075, CFrame.new(0, -0.3, 0), PAL.shadow, Enum.Material.Wood)
	part(m, "Guard", Vector3.new(0.55, 0.12, 0.12), CFrame.new(0, 0.28, 0), PAL.violet, Enum.Material.Neon, 0.1)
	part(m, "Blade", Vector3.new(0.2, 2.55, 0.07), CFrame.new(0, 1.65, 0), PAL.shadow, Enum.Material.Metal, 0.05)
	part(m, "Glow", Vector3.new(0.08, 2.0, 0.04), CFrame.new(0, 1.65, 0.05), PAL.glowShadow, Enum.Material.Neon, 0.4)
	part(m, "Pommel", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, -0.88, 0), PAL.violet, Enum.Material.Neon, 0.15)
	return finish(m, "Handle")
end

local builders = {
	build_StarterStick,
	build_MossRust,
	build_BoneThorn,
	build_RootMace,
	build_Twinleaf,
	build_SpiritBranch,
	build_Amberheart,
	build_CanopyFang,
	build_UmbralBough,
}

local names = {}
for _, fn in ipairs(builders) do
	local m = fn()
	table.insert(names, m.Name)
end

return "OK DF weapons: " .. table.concat(names, ", ")
