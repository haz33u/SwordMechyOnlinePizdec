--!strict
--[[
	Equipped pets float in a fan behind the local player (pro sim style).
	Server owns equip/stats; this is client cosmetic only.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
local PetModelConfig = require(Shared.Config.PetModelConfig)
local AuraModelConfig = require(Shared.Config.AuraModelConfig)
local AuraConfig = require(Shared.Config.AuraConfig)

local Settings = require(script.Parent.Settings)

local PetVisual = {}

local player = Players.LocalPlayer
local active: { [string]: Model } = {} -- uid → model
local lastSig = ""
local lastProfile: any = nil
local renderConn: RBXScriptConnection? = nil
local charConn: RBXScriptConnection? = nil
local camConn: RBXScriptConnection? = nil
local petsEnabled = true
local camCulling = true
local maxCamDistance = 80

Settings.OnChange("visualPets", function(enabled: boolean)
	petsEnabled = enabled
	if not enabled then
		PetVisual.ClearWorldPets()
	elseif lastProfile then
		PetVisual.Refresh(lastProfile)
	end
end)

local function getFolders(): { Folder }
	local folders = {}
	local f = ReplicatedStorage:FindFirstChild(PetModelConfig.FolderName or "PetModels")
	if f and f:IsA("Folder") then
		table.insert(folders, f)
	end
	local inc = ReplicatedStorage:FindFirstChild("INCREMENTAL ASSETS")
	if inc then
		local f2 = inc:FindFirstChild("MinionModels")
		if f2 and f2:IsA("Folder") then
			table.insert(folders, f2)
		end
	end
	return folders
end

local function sanitizeParts(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.Anchored = true
			d.CastShadow = true
		elseif d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ForceField") or d:IsA("Camera") then
			d:Destroy()
		elseif d:IsA("Motor6D") or d:IsA("Humanoid") or d:IsA("Animator") or d:IsA("AnimationController") then
			-- Pet models are anchored cosmetics: rig motors/humanoid only interfere with
			-- character rig lookups (e.g. WeaponVisual) and add no value here.
			d:Destroy()
		elseif d.Name == "HumanoidRootPart" and d:IsA("BasePart") then
			-- Remove the rig root so it cannot be mistaken for a character joint.
			d:Destroy()
		end
	end
end

local function rarityColor(rarity: string): Color3
	local t = PetModelConfig.RarityColor
	return (t and t[rarity]) or Color3.fromRGB(160, 160, 170)
end

local function auraNameForRarity(rarity: string): string
	local map = {
		Common = "A_Ice",
		Uncommon = "A_Leaf",
		Rare = "A_Dragon",
		Epic = "A_Blaze",
		Legendary = "A_Fire",
		Mythic = "A_Cosmic",
		Secret = "A_Blackhole",
		Limited = "A_Heavenly",
	}
	return map[rarity] or "A_Light"
end

local function clearPetAura(model: Model)
	local existing = model:FindFirstChild("PetAuraVfx")
	if existing then
		existing:Destroy()
	end
end

local function applyPetAura(model: Model, petId: string)
	clearPetAura(model)
	local def = PetConfig.Get(petId)
	if not def then
		return
	end
	local auraId = auraNameForRarity(def.rarity or "Common")
	local auraTemplateName = AuraModelConfig.GetModelName(auraId)
	if not auraTemplateName then
		return
	end
	local auraVfx = ReplicatedStorage:FindFirstChild("AuraVfx")
	if not auraVfx then
		return
	end
	local template = auraVfx:FindFirstChild(auraTemplateName)
	if not template or not template:IsA("Model") then
		return
	end
	local clone = template:Clone()
	clone.Name = "PetAuraVfx"
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

	local primary = clone.PrimaryPart or clone:FindFirstChild("RootPart") or clone:FindFirstChild("Circle")
	local petPrimary = model.PrimaryPart
	if primary and primary:IsA("BasePart") and petPrimary and petPrimary:IsA("BasePart") then
		primary.Size = primary.Size * 0.5
		clone.PrimaryPart = primary
		local weld = Instance.new("Weld")
		weld.Part0 = petPrimary
		weld.Part1 = primary
		weld.C0 = CFrame.new(0, 0, 0)
		weld.Parent = primary
		clone.Parent = model
	else
		clone:Destroy()
	end
end

local function makePlaceholder(petId: string, def: any?): Model
	local m = Instance.new("Model")
	m.Name = "PetPlaceholder_" .. petId
	local rar = (def and def.rarity) or "Common"
	local col = rarityColor(rar)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(1.1, 1.1, 1.1)
	body.Color = col
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Massless = true
	body.Parent = m
	m.PrimaryPart = body

	-- small "ear" accents
	local ear = Instance.new("Part")
	ear.Name = "Accent"
	ear.Size = Vector3.new(0.35, 0.55, 0.35)
	ear.Color = col:Lerp(Color3.new(1, 1, 1), 0.25)
	ear.Material = Enum.Material.SmoothPlastic
	ear.Anchored = true
	ear.CanCollide = false
	ear.Massless = true
	ear.CFrame = body.CFrame * CFrame.new(0, 0.7, 0)
	ear.Parent = m
	local w = Instance.new("WeldConstraint")
	w.Part0 = body
	w.Part1 = ear
	w.Parent = ear

	local bb = Instance.new("BillboardGui")
	bb.Name = "PetName"
	bb.Size = UDim2.fromOffset(100, 24)
	bb.StudsOffset = Vector3.new(0, 1.2, 0)
	bb.AlwaysOnTop = false
	bb.Parent = body
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.fromScale(1, 1)
	lab.Font = Enum.Font.Arcade
	lab.TextSize = 12
	lab.TextColor3 = Color3.new(1, 1, 1)
	lab.TextStrokeTransparency = 0.5
	lab.Text = (def and def.name) or petId
	lab.Parent = bb

	return m
end

local function clonePetModel(petId: string): Model?
	local def = PetConfig.Get(petId)
	local modelName = PetModelConfig.GetModelName(petId)
	local folders = getFolders()
	if #folders > 0 and modelName then
		local template: Instance? = nil
		for _, folder in ipairs(folders) do
			local found = folder:FindFirstChild(modelName)
			if found and found:IsA("Model") then
				template = found
				break
			end
		end
		if template and template:IsA("Model") then
			local clone = template:Clone()
			clone.Name = "Pet_" .. petId
			-- Pets are cosmetic follow-ons: never simulate physics or cast shadows from far away.
			pcall(function()
				clone:SetAttribute("PetFollowModel", true)
				if (clone :: any).ModelStreamingMode then
					(clone :: any).ModelStreamingMode = Enum.ModelStreamingMode.NonStreaming
				end
				if (clone :: any).LevelOfDetail then
					(clone :: any).LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
				end
			end)
			sanitizeParts(clone)
			local handle = clone.PrimaryPart
			if not handle then
				for _, d in clone:GetDescendants() do
					if d:IsA("BasePart") then
						handle = d
						break
					end
				end
			end
			if handle then
				clone.PrimaryPart = handle
			end
			local pre = PetModelConfig.DefaultScale or 1
			if type(pre) == "number" and pre > 0 and pre ~= 1 then
				pcall(function()
					(clone :: any):ScaleTo(pre)
				end)
			end
			-- Uniform size: force max bbox ≈ TargetExtent (all pets like slime scale)
			local target = PetModelConfig.TargetExtent or 2.0
			if type(target) == "number" and target > 0.1 then
				local okBb, _cf, size = pcall(function()
					return clone:GetBoundingBox()
				end)
				if okBb and typeof(size) == "Vector3" then
					local maxDim = math.max(size.X, size.Y, size.Z, 0.05)
					local factor = target / maxDim
					local fMin = PetModelConfig.TargetExtentMinFactor or 0.04
					local fMax = PetModelConfig.TargetExtentMaxFactor or 25
					factor = math.clamp(factor, fMin, fMax)
					if math.abs(factor - 1) > 0.02 then
						pcall(function()
							local cur = 1
							pcall(function()
								cur = (clone :: any):GetScale()
							end)
							if type(cur) ~= "number" or cur <= 0 then
								cur = 1
							end
							(clone :: any):ScaleTo(cur * factor)
						end)
					end
				end
			end
			sanitizeParts(clone)
			return clone
		end
	end
	return makePlaceholder(petId, def)
end

local function clearAll()
	for uid, m in active do
		if m then
			clearPetAura(m)
			m:Destroy()
		end
		active[uid] = nil
	end
	lastSig = ""
end

local function teamSignature(profile: any): string
	if not profile then
		return ""
	end
	local parts = {}
	for _, uid in profile.petTeam or {} do
		local id = "?"
		for _, p in profile.pets or {} do
			if p.uid == uid then
				id = p.id or "?"
				break
			end
		end
		table.insert(parts, tostring(uid) .. ":" .. tostring(id))
	end
	return table.concat(parts, "|")
end

local function ensureFolderOnChar(char: Model): Folder
	local f = char:FindFirstChild("SM_PetVisuals")
	if f and f:IsA("Folder") then
		return f
	end
	local nf = Instance.new("Folder")
	nf.Name = "SM_PetVisuals"
	-- Parent under character so pets move with the player but never sit in Workspace root.
	nf.Parent = char
	return nf
end

local function getCamera(): Camera?
	local camera = Workspace.CurrentCamera
	if camera and camera:IsA("Camera") then
		return camera
	end
	return nil
end

local function isVisibleToCamera(): boolean
	if not camCulling then
		return true
	end
	local camera = getCamera()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not camera or not hrp or not hrp:IsA("BasePart") then
		return true
	end
	local dist = (camera.CFrame.Position - hrp.Position).Magnitude
	return dist <= maxCamDistance
end

local function setPetsVisible(visible: boolean)
	for _, m in active do
		if m.Parent then
			for _, part in m:GetDescendants() do
				if part:IsA("BasePart") then
					pcall(function()
						part.LocalTransparencyModifier = visible and 0 or 1
					end)
				end
			end
		end
	end
end

local function rebuild(profile: any)
	local char = player.Character
	if not char then
		clearAll()
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		clearAll()
		return
	end

	local sig = teamSignature(profile)
	-- Drop destroyed models (respawn / character wipe)
	for uid, m in active do
		if not m.Parent then
			active[uid] = nil
		end
	end

	local want: { [string]: string } = {} -- uid → petId
	for _, uid in profile.petTeam or {} do
		for _, p in profile.pets or {} do
			if p.uid == uid then
				want[uid] = p.id
				break
			end
		end
	end

	local needRebuild = sig ~= lastSig
	if not needRebuild then
		for uid in want do
			if not active[uid] then
				needRebuild = true
				break
			end
		end
	end
	if not needRebuild and next(active) ~= nil then
		return
	end
	lastSig = sig

	for uid, m in active do
		if not want[uid] then
			m:Destroy()
			active[uid] = nil
		end
	end

	local folder = ensureFolderOnChar(char)
	for uid, petId in want do
		local existing = active[uid]
		if existing and existing.Parent then
			-- Pets must always live under the character's SM_PetVisuals folder.
			-- If something has pulled them out (Studio edits, parenting bugs), put them back.
			if existing.Parent ~= folder then
				if existing.Parent == Workspace or existing.Parent:IsDescendantOf(Workspace) and not existing.Parent:IsDescendantOf(char) then
					pcall(function()
						existing:Destroy()
					end)
					active[uid] = nil
				else
					existing.Parent = folder
				end
			end
		else
			if existing then
				pcall(function()
					existing:Destroy()
				end)
			end
			local model = clonePetModel(petId)
			if model then
				model:SetAttribute("PetUid", uid)
				model:SetAttribute("PetId", petId)
				model.Parent = folder
				pcall(function()
					-- Roblox CFrame: +Z is behind LookVector (behind the character)
					model:PivotTo(hrp.CFrame * CFrame.new(0, 2, 3.5))
				end)
				applyPetAura(model, petId)
				active[uid] = model
			end
		end
	end
end

local function slotOffset(index: number, total: number): Vector3
	-- Roblox object space: LookVector = -Z, so +Z is BEHIND the character.
	local back = PetModelConfig.FollowBack or 4.2
	local height = PetModelConfig.FollowHeight or 2.35
	local spread = PetModelConfig.FollowSpread or 1.65
	local mid = (total + 1) / 2
	local x = (index - mid) * spread
	return Vector3.new(x, height, back)
end

function stepFollow(dt: number)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then
		return
	end

	local cameraVisible = isVisibleToCamera()

	-- stable order from attributes + name
	local list: { { uid: string, model: Model } } = {}
	for uid, m in active do
		if m.Parent then
			-- Cull pet models when the camera is far from the character. They are purely
			-- cosmetic follow-ons, so skipping updates and hiding them saves frames.
			local folder = char:FindFirstChild("SM_PetVisuals")
			if folder and m.Parent ~= folder then
				pcall(function()
					m.Parent = folder
				end)
			end
			for _, part in m:GetDescendants() do
				if part:IsA("BasePart") then
					pcall(function()
						part.LocalTransparencyModifier = cameraVisible and 0 or 1
					end)
				end
			end
			if cameraVisible then
				table.insert(list, { uid = uid, model = m })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.uid < b.uid
	end)

	local n = #list
	if n == 0 then
		return
	end

	local frameDt = if typeof(dt) == "number" and dt > 0 then dt else 0.016
	local alpha = math.clamp(frameDt * 12, 0.05, 0.95)
	local bobA = PetModelConfig.BobAmp or 0.14
	local bobS = PetModelConfig.BobSpeed or 2.2
	local t = os.clock()

	for i, entry in ipairs(list) do
		local model = entry.model
		local off = slotOffset(i, n)
		local bob = math.sin(t * bobS + i * 1.3) * bobA
		local goal = hrp.CFrame * CFrame.new(off.X, off.Y + bob, off.Z)
		-- face same as player (pets look forward with you)
		local look = goal.Position + hrp.CFrame.LookVector
		goal = CFrame.lookAt(goal.Position, look)

		local ok, cur = pcall(function()
			return model:GetPivot()
		end)
		if ok and typeof(cur) == "CFrame" then
			local nextCf = cur:Lerp(goal, alpha)
			pcall(function()
				model:PivotTo(nextCf)
			end)
		else
			pcall(function()
				model:PivotTo(goal)
			end)
		end
	end
end

function PetVisual.ClearWorldPets()
	clearAll()
end

function PetVisual.Refresh(profile: any?)
	if not profile then
		lastProfile = nil
		clearAll()
		return
	end
	lastProfile = profile
	if not petsEnabled then
		clearAll()
		return
	end
	local ok, err = pcall(function()
		rebuild(profile)
	end)
	if not ok then
		warn("[PetVisual] rebuild failed", err)
	end
end

function PetVisual.Init()
	if renderConn then
		return
	end
	renderConn = RunService.RenderStepped:Connect(stepFollow)

	-- Reveal pets immediately when the camera snaps back to the character.
	camConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		setPetsVisible(true)
	end)

	local function onChar(_char: Model)
		task.defer(function()
			lastSig = ""
			for uid, m in active do
				if m then
					pcall(function()
						m:Destroy()
					end)
				end
				active[uid] = nil
			end
			if lastProfile then
				PetVisual.Refresh(lastProfile)
			end
		end)
	end

	if player.Character then
		onChar(player.Character)
	end
	charConn = player.CharacterAdded:Connect(onChar)
end

function PetVisual.Destroy()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	if charConn then
		charConn:Disconnect()
		charConn = nil
	end
	if camConn then
		camConn:Disconnect()
		camConn = nil
	end
	clearAll()
end

--- Inventory slot: 3D preview of pet mesh (same PetModels as world). Returns true if shown.
function PetVisual.TryFillInventoryIcon(parent: GuiObject, petId: string, zIndex: number?): boolean
	local ok, result = pcall(function()
		local existing = parent:FindFirstChild("PetViewport")
		if existing then
			existing:Destroy()
		end
		local clone = clonePetModel(petId)
		if not clone then
			return false
		end
		-- strip billboard for clean icon
		for _, d in clone:GetDescendants() do
			if d:IsA("BillboardGui") then
				d:Destroy()
			end
		end

		local vf = Instance.new("ViewportFrame")
		vf.Name = "PetViewport"
		vf.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
		vf.BackgroundTransparency = 0.2
		vf.BorderSizePixel = 0
		vf.Size = UDim2.fromScale(0.78, 0.68)
		vf.Position = UDim2.fromScale(0.5, 0.4)
		vf.AnchorPoint = Vector2.new(0.5, 0.5)
		vf.ZIndex = zIndex or 40
		vf.Active = false
		vf.Ambient = Color3.fromRGB(200, 200, 210)
		vf.LightColor = Color3.fromRGB(255, 255, 255)
		vf.LightDirection = Vector3.new(-1, -1, -0.5)
		vf.Parent = parent

		local world = Instance.new("WorldModel")
		world.Parent = vf
		clone.Parent = world
		pcall(function()
			clone:PivotTo(CFrame.new())
		end)
		local okBox, bbCf, bbSize = pcall(function()
			return clone:GetBoundingBox()
		end)
		local extent = 1.2
		if okBox and typeof(bbCf) == "CFrame" and typeof(bbSize) == "Vector3" then
			pcall(function()
				clone:TranslateBy(-(bbCf :: CFrame).Position)
			end)
			extent = math.max(bbSize.X, bbSize.Y, bbSize.Z, 0.4)
		end
		pcall(function()
			clone:PivotTo(CFrame.Angles(0, math.rad(-30), 0) * clone:GetPivot())
		end)
		local cam = Instance.new("Camera")
		cam.Parent = vf
		vf.CurrentCamera = cam
		local dist = math.clamp(extent * 1.9, 1.2, 12)
		cam.FieldOfView = 30
		cam.CFrame = CFrame.new(Vector3.new(dist * 0.45, dist * 0.35, dist * 0.85), Vector3.zero)
		return true
	end)
	return ok and result == true
end

return PetVisual
