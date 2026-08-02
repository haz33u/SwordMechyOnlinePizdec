--!strict
--[[
	Client-side mob aura visuals. Applies lightweight aura VFX to live mobs by tier.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AuraModelConfig = require(Shared.Config.AuraModelConfig)
local Settings = require(script.Parent.Settings)

local activeAuras: { [Model]: Model } = {}
--- Live mobs we know about, whether or not they currently wear an aura. Needed so
--- flipping the "Show Auras" toggle can affect mobs that already spawned.
local trackedMobs: { [Model]: boolean } = {}

local TIER_AURA = {
	simple = "A_Leaf",
	medium = "A_Dragon",
	hard = "A_Blaze",
	elite = "A_Fire",
	boss = "A_Cosmic",
	debug = "A_Light",
	trash = "A_Leaf",
	normal = "A_Dragon",
}

local function getRootPart(model: Model): BasePart?
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	return model:FindFirstChildWhichIsA("BasePart")
end

local function removeAura(mob: Model)
	local aura = activeAuras[mob]
	if aura then
		activeAuras[mob] = nil
		pcall(function()
			aura:Destroy()
		end)
	end
end

local function applyAura(mob: Model)
	removeAura(mob)
	local tier: string = mob:GetAttribute("Tier") or "simple"
	local isBoss = mob:GetAttribute("IsBoss") == true
	local auraId = isBoss and "A_UltimateEvil" or (TIER_AURA[tier] or "A_Light")
	local modelName = AuraModelConfig.GetModelName(auraId)
	if not modelName then
		return
	end
	local auraVfx = ReplicatedStorage:FindFirstChild("AuraVfx")
	if not auraVfx then
		return
	end
	local template = auraVfx:FindFirstChild(modelName)
	if not template or not template:IsA("Model") then
		return
	end
	local root = getRootPart(mob)
	if not root then
		return
	end
	local clone: Model = template:Clone() :: Model
	clone.Name = "MobAuraVfx"
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		elseif d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ForceField") or d:IsA("Camera") then
			d:Destroy()
		end
	end
	local auraRoot = clone.PrimaryPart or clone:FindFirstChild("RootPart") or clone:FindFirstChild("Circle") or clone:FindFirstChildWhichIsA("BasePart")
	if auraRoot and auraRoot:IsA("BasePart") then
		local scale = isBoss and 1.2 or 0.8
		auraRoot.Size = auraRoot.Size * scale
		clone.PrimaryPart = auraRoot
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = auraRoot
		weld.C0 = CFrame.new(0, 0, 0)
		weld.Parent = auraRoot
		clone.Parent = mob
		activeAuras[mob] = clone
	else
		clone:Destroy()
	end
end

local function onMobAdded(mob: Instance)
	if not mob:IsA("Model") then
		return
	end
	if mob:GetAttribute("IsLiveCombatMob") ~= true then
		return
	end
	trackedMobs[mob] = true
	if Settings.ShouldShowVisual("auras") then
		applyAura(mob)
	end
	mob.Destroying:Once(function()
		trackedMobs[mob] = nil
		removeAura(mob)
	end)
end

local function init()
	local mobsFolder = Workspace:WaitForChild("Mobs", 10)
	if not mobsFolder then
		return
	end
	for _, child in ipairs(mobsFolder:GetChildren()) do
		onMobAdded(child)
	end
	mobsFolder.ChildAdded:Connect(onMobAdded)

	-- "Show Auras" toggle applies to mobs already on screen, not just future spawns.
	Settings.OnChange("visualAuras", function(enabled: boolean)
		for mob in pairs(trackedMobs) do
			if mob.Parent then
				if enabled then
					applyAura(mob)
				else
					removeAura(mob)
				end
			else
				trackedMobs[mob] = nil
			end
		end
	end)
end

init()
