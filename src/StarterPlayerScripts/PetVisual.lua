--!strict
--[[
	Equipped pets float in a fan behind the local player (pro sim style).
	Server owns equip/stats; this is client cosmetic only.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
local PetModelConfig = require(Shared.Config.PetModelConfig)

local PetVisual = {}

local player = Players.LocalPlayer
local active: { [string]: Model } = {} -- uid → model
local lastSig = ""
local renderConn: RBXScriptConnection? = nil
local charConn: RBXScriptConnection? = nil

local function getFolder(): Folder?
	local f = ReplicatedStorage:FindFirstChild(PetModelConfig.FolderName or "PetModels")
	if f and f:IsA("Folder") then
		return f
	end
	return nil
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
		elseif d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ForceField") then
			d:Destroy()
		end
	end
end

local function rarityColor(rarity: string): Color3
	local t = PetModelConfig.RarityColor
	return (t and t[rarity]) or Color3.fromRGB(160, 160, 170)
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
	local folder = getFolder()
	if folder and modelName then
		local template = folder:FindFirstChild(modelName)
		if template and template:IsA("Model") then
			local clone = template:Clone()
			clone.Name = "Pet_" .. petId
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
			local scale = PetModelConfig.DefaultScale or 0.55
			if type(scale) == "number" and scale > 0 and scale ~= 1 then
				pcall(function()
					(clone :: any):ScaleTo(scale)
				end)
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
	nf.Parent = char
	return nf
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
			if existing.Parent ~= folder then
				existing.Parent = folder
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
					model:PivotTo(hrp.CFrame * CFrame.new(0, 2, -3))
				end)
				active[uid] = model
			end
		end
	end
end

local function slotOffset(index: number, total: number): Vector3
	local back = PetModelConfig.FollowBack or 4.2
	local height = PetModelConfig.FollowHeight or 2.35
	local spread = PetModelConfig.FollowSpread or 1.65
	local mid = (total + 1) / 2
	local x = (index - mid) * spread
	return Vector3.new(x, height, -back)
end

local function stepFollow(_dt: number)
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

	-- stable order from attributes + name
	local list: { { uid: string, model: Model } } = {}
	for uid, m in active do
		if m.Parent then
			table.insert(list, { uid = uid, model = m })
		end
	end
	table.sort(list, function(a, b)
		return a.uid < b.uid
	end)

	local n = #list
	if n == 0 then
		return
	end

	local alpha = PetModelConfig.LerpAlpha or 0.16
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

function PetVisual.Refresh(profile: any?)
	if not profile then
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
			-- App.ProfileUpdate / refreshAll will call Refresh; if not, wait one frame
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
	clearAll()
end

return PetVisual
