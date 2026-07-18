--!strict
--[[
	Local player: sword visuals on grips + attack animation on Swing.

	Animation resolve order:
	  1) ReplicatedStorage.CombatAnimations.Swing1 / Swing2 (KeyframeSequence)
	  2) ReplicatedStorage.Animations.Swing (Animation instance or KFS child)
	  3) AnimationConfig.AttackMain / AttackAlt (published rbxassetid)
	  4) Official R15 toolslash / toollunge fallbacks

	Grips: RightHand.RightGripAttachment, LeftHand.LeftGripAttachment
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

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
local registeredIds: { [string]: string } = {}
local swingToggle = false
local lastPlay = 0
local warnedOnce: { [string]: boolean } = {}

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

local function warnOnce(key: string, msg: string)
	if warnedOnce[key] then
		return
	end
	warnedOnce[key] = true
	warn("[WeaponVisual]", msg)
end

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

	if rarity == "Legendary" or rarity == "Mythic" or rarity == "Secret" or rarity == "Limited" then
		local light = Instance.new("PointLight")
		light.Brightness = 0.8
		light.Range = 6
		light.Color = color
		light.Parent = handle
	end

	local att = Instance.new("Attachment")
	att.Name = "Grip"
	att.Position = Vector3.new(0, -AnimationConfig.SwordLength * 0.35, 0)
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

	-- Always show main sword if equipped; if no equip data, still show default Common blade
	if rightGrip then
		mainModel = makeSword("MainSword", mainDef or { rarity = "Common" }, folder)
		attachToGrip(mainModel, rightGrip)
	end
	if offDef and leftGrip then
		offModel = makeSword("OffSword", offDef, folder)
		attachToGrip(offModel, leftGrip)
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

local function registerKfs(seq: KeyframeSequence, cacheKey: string): string?
	if registeredIds[cacheKey] then
		return registeredIds[cacheKey]
	end
	local ok, contentId = pcall(function()
		return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
	end)
	if ok and type(contentId) == "string" and contentId ~= "" then
		registeredIds[cacheKey] = contentId
		return contentId
	end
	warnOnce("kfs_" .. cacheKey, "RegisterKeyframeSequence failed for " .. cacheKey)
	return nil
end

local function findKfsIn(folder: Instance?, names: { string }): (KeyframeSequence?, string?)
	if not folder then
		return nil, nil
	end
	for _, name in names do
		local inst = folder:FindFirstChild(name, true)
		if inst and inst:IsA("KeyframeSequence") then
			return inst, name
		end
		-- Animation container with KFS child (e.g. Run.KeyframeSequence)
		local holder = folder:FindFirstChild(name)
		if holder then
			local kfs = holder:FindFirstChildWhichIsA("KeyframeSequence", true)
			if kfs then
				return kfs, name
			end
		end
	end
	return nil, nil
end

local function findAnimationInstance(folder: Instance?, names: { string }): string?
	if not folder then
		return nil
	end
	for _, name in names do
		local inst = folder:FindFirstChild(name, true)
		if inst and inst:IsA("Animation") then
			local id = inst.AnimationId
			if type(id) == "string" and id ~= "" and id ~= "rbxassetid://0" then
				return id
			end
		end
	end
	return nil
end

--- Build ordered list of content ids to try for this swing
local function collectAnimCandidates(preferAlt: boolean): { string }
	local list: { string } = {}
	local seen: { [string]: boolean } = {}

	local function add(id: string?)
		if type(id) ~= "string" or id == "" or seen[id] then
			return
		end
		seen[id] = true
		table.insert(list, id)
	end

	local combatFolder = ReplicatedStorage:FindFirstChild(AnimationConfig.CombatAnimsFolder)
	local animsFolder = ReplicatedStorage:FindFirstChild(AnimationConfig.ExtraAnimsFolder or "Animations")

	-- 1) CombatAnimations Swing1 / Swing2 (from Combat Dummy)
	local combatNames = if preferAlt
		then { AnimationConfig.Swing2Name, "swing2", "Swing2", AnimationConfig.Swing1Name, "Swing" }
		else { AnimationConfig.Swing1Name, "swing1", "Swing1", "Swing", AnimationConfig.Swing2Name }
	local kfs, key = findKfsIn(combatFolder, combatNames)
	if kfs and key then
		add(registerKfs(kfs, "combat_" .. key))
	end

	-- 2) ReplicatedStorage.Animations.Swing (highest priority after combat KFS)
	local swingNames = if preferAlt
		then { "Swing2", "Swing", "Attack2", "slash", "Attack" }
		else { "Swing", "Swing1", "Attack", "slash", "Attack1" }
	-- Prefer explicit AnimationId on folder (e.g. Swing = 522635514)
	add(findAnimationInstance(animsFolder, swingNames))
	local kfs2, key2 = findKfsIn(animsFolder, swingNames)
	if kfs2 and key2 then
		add(registerKfs(kfs2, "anims_" .. key2))
	end

	-- 3) Published store id (optional)
	if AnimationConfig.PreferPublishedAttack then
		add(AnimationConfig.GetAttackId(preferAlt))
	else
		-- still try as mid-priority if set
		local pub = AnimationConfig.GetAttackId(preferAlt)
		if pub and pub ~= AnimationConfig.AttackMainFallback then
			add(pub)
		end
	end

	-- 4) Hard fallbacks (always last)
	add(if preferAlt then AnimationConfig.AttackAltFallback else AnimationConfig.AttackMainFallback)
	add(AnimationConfig.AttackMainFallback)
	add("rbxassetid://522635514")
	add("rbxassetid://522638767")

	return list
end

local function loadTrack(animator: Animator, id: string): AnimationTrack?
	local existing = tracks[id]
	if existing then
		-- re-use if still valid
		local okParent = pcall(function()
			return existing.Parent ~= nil or existing.Length >= 0
		end)
		if okParent then
			return existing
		end
		tracks[id] = nil
	end

	local anim = Instance.new("Animation")
	anim.Name = "SM_Attack"
	anim.AnimationId = id
	local ok, trackOrErr = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()
	if not ok or typeof(trackOrErr) ~= "Instance" then
		warnOnce("load_" .. id, "LoadAnimation failed for " .. id .. " → " .. tostring(trackOrErr))
		return nil
	end
	local track = trackOrErr :: AnimationTrack
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	tracks[id] = track
	return track
end

function WeaponVisual.PlayAttack(forceAlt: boolean?)
	local now = os.clock()
	if now - lastPlay < 0.08 then
		return
	end
	lastPlay = now

	local char = player.Character
	if not char then
		warnOnce("nochar", "PlayAttack: no character")
		return
	end
	local animator = getAnimator(char)
	if not animator then
		warnOnce("noanim", "PlayAttack: no Animator on Humanoid")
		return
	end

	local useAlt = forceAlt
	if useAlt == nil and AnimationConfig.AlternateDual then
		swingToggle = not swingToggle
		useAlt = swingToggle
	end

	-- Direct load from Animations.Swing Animation instance (most reliable for place setup)
	local animsFolder = ReplicatedStorage:FindFirstChild(AnimationConfig.ExtraAnimsFolder or "Animations")
	if animsFolder then
		local swingInst = animsFolder:FindFirstChild("Swing")
		if swingInst and swingInst:IsA("Animation") and swingInst.AnimationId ~= "" then
			local track = loadTrack(animator, swingInst.AnimationId)
			if track then
				pcall(function()
					for _, t in tracks do
						if t ~= track and t.IsPlaying and t.Priority == Enum.AnimationPriority.Action4 then
							t:Stop(0.05)
						end
					end
				end)
				track:Play(0.05, 1, 1.25)
				return
			end
		end
	end

	local candidates = collectAnimCandidates(useAlt == true)
	for _, id in candidates do
		local track = loadTrack(animator, id)
		if track then
			pcall(function()
				for _, t in tracks do
					if t ~= track and t.IsPlaying and t.Priority == Enum.AnimationPriority.Action4 then
						t:Stop(0.05)
					end
				end
			end)
			track:Play(0.05, 1, 1.25)
			return
		end
	end
	warnOnce("allfail", "PlayAttack: all animation candidates failed. Check F9 Client log.")
end

function WeaponVisual.Init(getProfile: () -> any?)
	task.defer(function()
		-- warm register
		pcall(function()
			collectAnimCandidates(false)
			collectAnimCandidates(true)
		end)
		print("[WeaponVisual] ready | CombatAnims=",
			ReplicatedStorage:FindFirstChild("CombatAnimations") ~= nil,
			"Animations=",
			ReplicatedStorage:FindFirstChild("Animations") ~= nil
		)
	end)

	local function onChar(char: Model)
		tracks = {}
		registeredIds = {}
		warnedOnce = {}
		task.defer(function()
			task.wait(0.25)
			pcall(function()
				collectAnimCandidates(false)
				collectAnimCandidates(true)
			end)
			WeaponVisual.Refresh(getProfile())
		end)
		char.Destroying:Connect(function()
			mainModel = nil
			offModel = nil
			folder = nil
			tracks = {}
			registeredIds = {}
		end)
	end

	if player.Character then
		onChar(player.Character)
	end
	player.CharacterAdded:Connect(onChar)
end

return WeaponVisual
