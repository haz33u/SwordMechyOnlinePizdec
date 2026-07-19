--!strict
--[[
	Sword visuals on grips + attack:
	  AnimationConfig.UseMinecraftSwing → procedural Motor6D swing (MC curve)
	  else → published AnimationId
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
local lastPlay = 0
local lastPlayedId: string? = nil

-- Minecraft-style procedural swing state
local mcShoulder: Motor6D? = nil
local mcWaist: Motor6D? = nil
local mcSwinging = false
local mcT = 0
local mcBound: RBXScriptConnection? = nil
local mcSlash: Sound? = nil

local READY = CFrame.Angles(math.rad(-90), 0, math.rad(-15))

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
	handle.Size = Vector3.new(AnimationConfig.SwordWidth, AnimationConfig.SwordLength, AnimationConfig.SwordDepth)
	handle.Color = color
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Parent = m

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.7, 0.12, 0.25)
	guard.Color = Color3.fromRGB(40, 40, 48)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.Massless = true
	guard.Parent = m
	local gw = Instance.new("WeldConstraint")
	gw.Part0 = handle
	gw.Part1 = guard
	gw.Parent = guard
	guard.CFrame = handle.CFrame * CFrame.new(0, -AnimationConfig.SwordLength * 0.28, 0)

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

local mcWarnedNoShoulder = false

--- R15: Motor6D "RightShoulder" (often under RightUpperArm). R6: "Right Shoulder" under Torso.
local function findRightShoulder(char: Model): Motor6D?
	-- direct common paths first
	local paths = {
		{ "RightUpperArm", "RightShoulder" },
		{ "UpperTorso", "RightShoulder" },
		{ "Torso", "Right Shoulder" },
		{ "Torso", "RightShoulder" },
	}
	for _, p in paths do
		local a = char:FindFirstChild(p[1])
		if a then
			local m = a:FindFirstChild(p[2])
			if m and m:IsA("Motor6D") then
				return m
			end
		end
	end
	-- scan all motors
	for _, d in char:GetDescendants() do
		if d:IsA("Motor6D") then
			local n = string.lower(d.Name)
			if n == "rightshoulder" or n == "right shoulder" then
				return d
			end
			local p1 = d.Part1
			local p0 = d.Part0
			if p1 and p0 then
				local n1, n0 = p1.Name, p0.Name
				if (n1 == "RightUpperArm" or n1 == "Right Arm") and (n0 == "UpperTorso" or n0 == "Torso") then
					return d
				end
			end
		end
	end
	return nil
end

local function findWaist(char: Model): Motor6D?
	local ut = char:FindFirstChild("UpperTorso")
	if ut then
		local w = ut:FindFirstChild("Waist")
		if w and w:IsA("Motor6D") then
			return w
		end
	end
	for _, d in char:GetDescendants() do
		if d:IsA("Motor6D") and string.lower(d.Name) == "waist" then
			return d
		end
	end
	return nil
end

local function mcCurve(x: number): (number, number, number)
	-- ModelBiped-style cubic ease + sin raise/roll (from user MC script)
	local f = 1 - x
	f = 1 - f * f * f
	local raise = math.sin(f * math.pi)
	local roll = math.sin(x * math.pi)
	local body = -math.sin(math.sqrt(math.max(0, x)) * math.pi * 2) * 0.2
	return raise, roll, body
end

local function ensureMcSound(): Sound?
	if mcSlash and mcSlash.Parent then
		return mcSlash
	end
	local cfg = AnimationConfig.MinecraftSwing or {}
	local s = Instance.new("Sound")
	s.Name = "SM_MCSlash"
	s.SoundId = cfg.SoundId or "rbxasset://sounds/swordslash.wav"
	s.Volume = cfg.SoundVolume or 0.6
	s.Parent = player:FindFirstChild("PlayerGui") or player
	mcSlash = s
	return s
end

local function setupMcJoints(char: Model): boolean
	-- joints may appear after character stream; retry briefly
	if not mcShoulder or not mcShoulder.Parent then
		mcShoulder = findRightShoulder(char)
	end
	if not mcWaist or not mcWaist.Parent then
		mcWaist = findWaist(char)
	end
	if mcShoulder then
		mcWarnedNoShoulder = false
		return true
	end
	if not mcWarnedNoShoulder then
		mcWarnedNoShoulder = true
		local motors = {}
		for _, d in char:GetDescendants() do
			if d:IsA("Motor6D") then
				table.insert(motors, d:GetFullName())
			end
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local rig = if hum then tostring(hum.RigType) else "?"
		warn(
			"[WeaponVisual] MC swing: no RightShoulder. RigType=",
			rig,
			"| motors:",
			if #motors > 0 then table.concat(motors, "; ") else "(none yet)"
		)
	end
	return false
end

local function bindMcRender()
	if mcBound then
		return
	end
	mcBound = RunService.RenderStepped:Connect(function(dt)
		if not mcShoulder or not mcShoulder.Parent then
			return
		end
		local cfg = AnimationConfig.MinecraftSwing or {}
		local swingTime = cfg.SwingTime or 0.3
		local raisePower = cfg.RaisePower or 1.2
		local rollPower = cfg.RollPower or 0.4
		local swingDir = cfg.SwingDir or -1

		if mcSwinging then
			mcT += dt / swingTime
			if mcT >= 1 then
				mcSwinging = false
				mcT = 0
				mcShoulder.Transform = READY
				if mcWaist and mcWaist.Parent then
					mcWaist.Transform = CFrame.new()
				end
				return
			end
			local raise, roll, body = mcCurve(mcT)
			mcShoulder.Transform = READY
				* CFrame.Angles(swingDir * raise * raisePower, body * 2, -roll * rollPower)
			if mcWaist and mcWaist.Parent then
				mcWaist.Transform = CFrame.Angles(0, body, 0)
			end
		else
			-- hold ready pose while equipped swords exist
			if mainModel and mainModel.Parent then
				mcShoulder.Transform = READY
			end
		end
	end)
end

local function playMinecraftSwing()
	local char = player.Character
	if not char then
		return
	end
	if mcSwinging then
		return -- MC-style cooldown: no re-swing mid anim
	end
	if not setupMcJoints(char) then
		-- late joints: try once after a frame (avoids spam; one retry)
		task.defer(function()
			local c = player.Character
			if not c or mcSwinging then
				return
			end
			if setupMcJoints(c) then
				bindMcRender()
				mcSwinging = true
				mcT = 0
				local s = ensureMcSound()
				if s then
					s:Play()
				end
				print("[WeaponVisual] PlayAttack → MinecraftSwing (deferred joints)")
			end
		end)
		return
	end
	bindMcRender()
	mcSwinging = true
	mcT = 0
	local s = ensureMcSound()
	if s then
		s:Play()
	end
	print("[WeaponVisual] PlayAttack → MinecraftSwing")
end

local function loadTrack(animator: Animator, id: string): AnimationTrack?
	if tracks[id] then
		return tracks[id]
	end
	local anim = Instance.new("Animation")
	anim.Name = "SM_Attack"
	anim.AnimationId = id
	local ok, result = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()
	if not ok or typeof(result) ~= "Instance" then
		warn("[WeaponVisual] LoadAnimation FAILED:", id, result)
		return nil
	end
	local track = result :: AnimationTrack
	if track.Length == 0 then
		warn("[WeaponVisual] track length 0 — check publish/access for", id)
	end
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	tracks[id] = track
	print("[WeaponVisual] Loaded attack track:", id, "len=", track.Length)
	return track
end

function WeaponVisual.PlayAttack(_forceAlt: boolean?)
	local now = os.clock()
	if now - lastPlay < 0.08 then
		return
	end
	lastPlay = now

	if AnimationConfig.UseMinecraftSwing then
		playMinecraftSwing()
		return
	end

	local char = player.Character
	if not char then
		return
	end
	local animator = getAnimator(char)
	if not animator then
		warn("[WeaponVisual] no Animator")
		return
	end

	local id = AnimationConfig.GetAttackId(false)
	local track = loadTrack(animator, id)
	if not track then
		warn("[WeaponVisual] PlayAttack FAILED — id", id)
		return
	end
	for _, t in tracks do
		if t ~= track and t.IsPlaying then
			pcall(function()
				t:Stop(0.05)
			end)
		end
	end
	track:Play(0.05, 1, 1.15)
	if lastPlayedId ~= id then
		lastPlayedId = id
		print("[WeaponVisual] PlayAttack →", id)
	end
end

function WeaponVisual.Init(getProfile: () -> any?)
	if AnimationConfig.UseMinecraftSwing then
		print("[WeaponVisual] Attack mode = MinecraftSwing (procedural)")
	else
		print("[WeaponVisual] Attack mode = AnimationId", AnimationConfig.GetAttackId(false))
	end

	local function onChar(char: Model)
		tracks = {}
		lastPlayedId = nil
		mcSwinging = false
		mcT = 0
		mcShoulder = nil
		mcWaist = nil
		mcWarnedNoShoulder = false
		task.spawn(function()
			-- wait for R15 stream (RightUpperArm + motor)
			local deadline = os.clock() + 5
			while os.clock() < deadline and char.Parent do
				if setupMcJoints(char) then
					break
				end
				task.wait(0.15)
			end
			if AnimationConfig.UseMinecraftSwing then
				bindMcRender()
				if mcShoulder then
					print("[WeaponVisual] MC joints ready:", mcShoulder:GetFullName())
				end
			end
			WeaponVisual.Refresh(getProfile())
		end)
		char.Destroying:Connect(function()
			mainModel = nil
			offModel = nil
			folder = nil
			tracks = {}
			mcShoulder = nil
			mcWaist = nil
			mcSwinging = false
		end)
	end

	if player.Character then
		onChar(player.Character)
	end
	player.CharacterAdded:Connect(onChar)
end

return WeaponVisual
