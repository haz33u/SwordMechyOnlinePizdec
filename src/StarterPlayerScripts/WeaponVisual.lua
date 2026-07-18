--!strict
--[[
	Local player: weld simple sword visuals to hand grips + play attack anim on Swing/CombatFx.

	Attachments used (default R15):
	  RightHand.RightGripAttachment  → main
	  LeftHand.LeftGripAttachment    → offhand
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationConfig = require(Shared.Config.AnimationConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local Rarity = require(script.Parent.Rarity)

local WeaponVisual = {}

local player = Players.LocalPlayer
local folder: Folder? = nil
local mainModel: Model? = nil
local offModel: Model? = nil
local tracks: { [string]: AnimationTrack } = {}
local swingToggle = false
local lastPlay = 0

local RARITY_COLOR = {
	Common = Color3.fromRGB(170, 175, 185),
	Uncommon = Color3.fromRGB(72, 180, 100),
	Rare = Color3.fromRGB(70, 130, 230),
	Epic = Color3.fromRGB(160, 80, 220),
	Legendary = Color3.fromRGB(230, 160, 50),
	Mythic = Color3.fromRGB(230, 70, 110),
	Secret = Color3.fromRGB(255, 230, 120),
	Limited = Color3.fromRGB(255, 80, 200),
}

local function ensureFolder(char: Model): Folder
	local f = char:FindFirstChild("SM_WeaponVisuals")
	if f and f:IsA("Folder") then
		return f
	end
	local nf = Instance.new("Folder")
	nf.Name = "SM_WeaponVisuals"
	nf.Parent = char
	return nf
end

local function clearSword(model: Model?)
	if model then
		model:Destroy()
	end
end

local function makeSword(name: string, def: any?, parent: Folder): Model
	local m = Instance.new("Model")
	m.Name = name

	local rarity = (def and def.rarity) or "Common"
	local color = RARITY_COLOR[rarity] or Rarity.Of(rarity)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(
		AnimationConfig.SwordWidth,
		AnimationConfig.SwordLength,
		AnimationConfig.SwordDepth
	)
	handle.Color = color
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.CastShadow = true
	handle.Parent = m

	-- simple guard
	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.7, 0.12, 0.25)
	guard.Color = Color3.fromRGB(40, 40, 48)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.CanQuery = false
	guard.Massless = true
	guard.Parent = m
	local gw = Instance.new("WeldConstraint")
	gw.Part0 = handle
	gw.Part1 = guard
	gw.Parent = guard
	guard.CFrame = handle.CFrame * CFrame.new(0, -AnimationConfig.SwordLength * 0.28, 0)

	-- tip glow for high rarity
	if rarity == "Legendary" or rarity == "Mythic" or rarity == "Secret" or rarity == "Limited" then
		local light = Instance.new("PointLight")
		light.Brightness = 0.8
		light.Range = 6
		light.Color = color
		light.Parent = handle
	end

	local att = Instance.new("Attachment")
	att.Name = "Grip"
	-- blade up from grip
	att.Position = Vector3.new(0, -AnimationConfig.SwordLength * 0.35, 0)
	att.Orientation = Vector3.new(0, 0, 0)
	att.Parent = handle

	m.PrimaryPart = handle
	m.Parent = parent
	return m
end

local function attachToGrip(model: Model, grip: Attachment)
	local handle = model.PrimaryPart
	if not handle then
		return
	end
	local modelGrip = handle:FindFirstChild("Grip") :: Attachment?
	if not modelGrip then
		return
	end
	-- clear old constraints
	for _, c in handle:GetChildren() do
		if c:IsA("RigidConstraint") then
			c:Destroy()
		end
	end
	local rigid = Instance.new("RigidConstraint")
	rigid.Attachment0 = grip
	rigid.Attachment1 = modelGrip
	rigid.Parent = handle
end

local function findGrip(char: Model, side: string): Attachment?
	if side == "left" then
		local hand = char:FindFirstChild("LeftHand")
		return hand and hand:FindFirstChild("LeftGripAttachment") :: Attachment?
	end
	local hand = char:FindFirstChild("RightHand")
	return hand and hand:FindFirstChild("RightGripAttachment") :: Attachment?
end

local function resolveWeaponDef(profile: any, uid: string?): any?
	if not uid or not profile or not profile.weapons then
		return nil
	end
	for _, w in profile.weapons do
		if w.uid == uid then
			return WeaponConfig.Get(w.id)
		end
	end
	return nil
end

function WeaponVisual.Refresh(profile: any?)
	local char = player.Character
	if not char then
		return
	end
	folder = ensureFolder(char)

	clearSword(mainModel)
	clearSword(offModel)
	mainModel = nil
	offModel = nil

	if not profile then
		return
	end

	local mainDef = resolveWeaponDef(profile, profile.equippedMain)
	local offDef = resolveWeaponDef(profile, profile.equippedOffhand)

	local rightGrip = findGrip(char, "right")
	local leftGrip = findGrip(char, "left")

	if mainDef and rightGrip then
		mainModel = makeSword("MainSword", mainDef, folder)
		attachToGrip(mainModel, rightGrip)
	end
	if offDef and leftGrip then
		offModel = makeSword("OffSword", offDef, folder)
		attachToGrip(offModel, leftGrip)
	elseif not mainDef and rightGrip then
		-- always show at least starter visual if somehow empty: skip
	end
end

local function getAnimator(char: Model): Animator?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	return animator
end

local function loadTrack(animator: Animator, id: string): AnimationTrack?
	if tracks[id] and tracks[id].Parent then
		return tracks[id]
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		tracks[id] = track
		return track
	end
	return nil
end

function WeaponVisual.PlayAttack(forceAlt: boolean?)
	local now = os.clock()
	if now - lastPlay < 0.12 then
		return
	end
	lastPlay = now

	local char = player.Character
	if not char then
		return
	end
	local animator = getAnimator(char)
	if not animator then
		return
	end

	local useAlt = forceAlt
	if useAlt == nil and AnimationConfig.AlternateDual then
		swingToggle = not swingToggle
		useAlt = swingToggle and offModel ~= nil
	end

	local id = AnimationConfig.GetAttackId(useAlt == true)
	local track = loadTrack(animator, id)
	if track then
		track:Play(0.05, 1, 1.15)
	end
end

function WeaponVisual.Init(getProfile: () -> any?)
	local function onChar(char: Model)
		tracks = {}
		task.defer(function()
			task.wait(0.2)
			WeaponVisual.Refresh(getProfile())
		end)
		char.Destroying:Connect(function()
			mainModel = nil
			offModel = nil
			folder = nil
			tracks = {}
		end)
	end

	if player.Character then
		onChar(player.Character)
	end
	player.CharacterAdded:Connect(onChar)
end

return WeaponVisual
