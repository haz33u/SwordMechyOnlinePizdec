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
local WeaponModels = require(script.Parent.WeaponModels)

local WeaponVisual = {}

local player = Players.LocalPlayer
local folder: Folder? = nil
local mainModel: Model? = nil
local offModel: Model? = nil
local tracks: { [string]: AnimationTrack } = {}
local lastPlay = 0
local lastPlayedId: string? = nil
local comboBusy = false -- true while right→left combo is running (spam LMB ignored)
local autoAttackOn = false
local autoAttackToken = 0
local getProfileFn: (() -> any?)? = nil

-- Minecraft-style procedural swing state
local mcShoulder: Motor6D? = nil
local mcLeftShoulder: Motor6D? = nil
local mcWaist: Motor6D? = nil
local mcSwinging = false
local mcT = 0
local offSwinging = false
local offT = 0
local mcBound: RBXScriptConnection? = nil
local mcSlash: Sound? = nil

-- Minecraft third-person arm raise: hand in front of torso, fist "holds" the blade.
-- (Not hanging at hip — that made free swords stick out of the elbows.)
local READY = CFrame.Angles(math.rad(-85), math.rad(-10), math.rad(-25))
local READY_LEFT = CFrame.Angles(math.rad(-85), math.rad(10), math.rad(25))

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

--- Fallback placeholder when Place has no model for this weapon id.
local function makePlaceholderSword(name: string, def: any?, parent: Folder): Model
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

local function attachPlaceholderToGrip(model: Model, grip: Attachment)
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

local function findGripAttachment(char: Model, side: string): Attachment?
	if side == "left" then
		local hand = char:FindFirstChild("LeftHand")
		return hand and hand:FindFirstChild("LeftGripAttachment") :: Attachment?
	end
	local hand = char:FindFirstChild("RightHand")
	return hand and hand:FindFirstChild("RightGripAttachment") :: Attachment?
end

local function equipSide(char: Model, parent: Folder, side: string, name: string, weaponId: string?, def: any?): Model?
	-- Place mesh models (optional). Any error → placeholder so inventory equip never looks "dead".
	if weaponId then
		local ok, modelOrErr, grip = pcall(function()
			if not WeaponModels.HasVisual(weaponId) then
				return nil, CFrame.new()
			end
			return WeaponModels.PrepareClone(weaponId)
		end)
		if ok and modelOrErr and typeof(modelOrErr) == "Instance" and modelOrErr:IsA("Model") then
			local model = modelOrErr :: Model
			model.Name = name
			model.Parent = parent
			local gripCf = if typeof(grip) == "CFrame" then grip else CFrame.new()
			local attOk = pcall(function()
				WeaponModels.AttachToHand(model, char, side, gripCf)
			end)
			if attOk then
				return model
			end
			model:Destroy()
		elseif not ok then
			warn("[WeaponVisual] PrepareClone failed for", weaponId, modelOrErr)
		end
	end

	local gripAtt = findGripAttachment(char, side)
	if not gripAtt then
		return nil
	end
	local placeholder = makePlaceholderSword(name, def or { rarity = "Common" }, parent)
	attachPlaceholderToGrip(placeholder, gripAtt)
	return placeholder
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

	local mainId: string? = nil
	if profile.equippedMain and profile.weapons then
		for _, w in profile.weapons do
			if w.uid == profile.equippedMain then
				mainId = w.id
				break
			end
		end
	end
	local offId: string? = nil
	if profile.equippedOffhand and profile.weapons then
		for _, w in profile.weapons do
			if w.uid == profile.equippedOffhand then
				offId = w.id
				break
			end
		end
	end

	-- Always show main (starter / equipped); offhand only when equipped
	mainModel = equipSide(char, folder, "right", "MainSword", mainId or (mainDef and mainDef.id), mainDef or { rarity = "Common" })
	if offDef and offId then
		offModel = equipSide(char, folder, "left", "OffSword", offId, offDef)
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

--- Must be defined BEFORE playOffhandSwing / PlayAttack (Luau local scope).
local function loadTrack(animator: Animator, id: string): AnimationTrack?
	if tracks[id] then
		local cached = tracks[id]
		-- Length can resolve after first load; keep using same track
		return cached
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
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	tracks[id] = track
	print("[WeaponVisual] Loaded attack track:", id, "len=", track.Length)
	return track
end

--- Wait until track.Length > 0 or timeout (async asset fetch).
local function waitTrackLength(track: AnimationTrack, timeoutSec: number?): number
	local timeout = timeoutSec or 2
	local t0 = os.clock()
	while track.Length <= 0 and (os.clock() - t0) < timeout do
		task.wait(0.05)
	end
	return track.Length
end

local function preloadAttackTracks(char: Model)
	local animator = getAnimator(char)
	if not animator then
		return
	end
	local ids = {
		AnimationConfig.GetAttackId(false),
		AnimationConfig.GetAttackOffhandId(),
		AnimationConfig.GetAttackDualId(),
	}
	for _, id in ids do
		if type(id) == "string" and id ~= "" then
			local tr = loadTrack(animator, id)
			if tr then
				waitTrackLength(tr, 2)
				print("[WeaponVisual] preload", id, "len=", tr.Length)
			end
		end
	end
end

--- Offhand purchased (gamepass/unlock) — required to use dual attack clip.
local function isOffhandPurchased(): boolean
	local fn = getProfileFn
	if not fn then
		return false
	end
	local profile = fn()
	if type(profile) ~= "table" then
		return false
	end
	local u = (profile :: any).unlocks
	return type(u) == "table" and u.offhand == true
end

--- Dual clip only after Offhand purchase AND a second sword equipped.
local function canUseDualAttackAnim(): boolean
	if not isOffhandPurchased() then
		return false
	end
	if not offModel or not offModel.Parent then
		return false
	end
	local dualId = AnimationConfig.GetAttackDualId()
	return dualId ~= ""
end

local mcWarnedNoShoulder = false

--- R15 shoulder motors (Right / Left). R6: "Right Shoulder" under Torso.
local function findShoulder(char: Model, side: string): Motor6D?
	local isLeft = side == "left"
	local paths = if isLeft
		then {
			{ "LeftUpperArm", "LeftShoulder" },
			{ "UpperTorso", "LeftShoulder" },
			{ "Torso", "Left Shoulder" },
			{ "Torso", "LeftShoulder" },
		}
		else {
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
	local want = if isLeft then "leftshoulder" else "rightshoulder"
	local wantSp = if isLeft then "left shoulder" else "right shoulder"
	local arm = if isLeft then "LeftUpperArm" else "RightUpperArm"
	local arm6 = if isLeft then "Left Arm" else "Right Arm"
	for _, d in char:GetDescendants() do
		if d:IsA("Motor6D") then
			local n = string.lower(d.Name)
			if n == want or n == wantSp then
				return d
			end
			local p1 = d.Part1
			local p0 = d.Part0
			if p1 and p0 then
				local n1, n0 = p1.Name, p0.Name
				if (n1 == arm or n1 == arm6) and (n0 == "UpperTorso" or n0 == "Torso") then
					return d
				end
			end
		end
	end
	return nil
end

local function findRightShoulder(char: Model): Motor6D?
	return findShoulder(char, "right")
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
	-- joints may appear after character stream; retry without spam-warn
	if not mcShoulder or not mcShoulder.Parent then
		mcShoulder = findRightShoulder(char)
	end
	if not mcLeftShoulder or not mcLeftShoulder.Parent then
		mcLeftShoulder = findShoulder(char, "left")
	end
	if not mcWaist or not mcWaist.Parent then
		mcWaist = findWaist(char)
	end
	if mcShoulder then
		mcWarnedNoShoulder = false
		return true
	end
	return false
end

local function warnNoShoulder(char: Model)
	if mcWarnedNoShoulder then
		return
	end
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
		"[WeaponVisual] no RightShoulder after wait. RigType=",
		rig,
		"| motors:",
		if #motors > 0 then table.concat(motors, "; ") else "(none)"
	)
end

local function bindMcRender()
	if mcBound then
		return
	end
	mcBound = RunService.RenderStepped:Connect(function(dt)
		local cfg = AnimationConfig.MinecraftSwing or {}
		local swingTime = cfg.SwingTime or 0.3
		local raisePower = cfg.RaisePower or 1.2
		local rollPower = cfg.RollPower or 0.4
		local swingDir = cfg.SwingDir or -1
		local useMc = AnimationConfig.UseMinecraftSwing == true

		-- Right arm: only drive Motor6D when MC procedural mode is on.
		-- Published AttackMain owns the right arm when UseMinecraftSwing = false.
		if useMc and mcShoulder and mcShoulder.Parent then
			if mcSwinging then
				mcT += dt / swingTime
				if mcT >= 1 then
					mcSwinging = false
					mcT = 0
					mcShoulder.Transform = if mainModel and mainModel.Parent then READY else CFrame.new()
					if mcWaist and mcWaist.Parent then
						mcWaist.Transform = CFrame.new()
					end
				else
					local raise, roll, body = mcCurve(mcT)
					mcShoulder.Transform = READY
						* CFrame.Angles(swingDir * raise * raisePower, body * 2, -roll * rollPower)
					if mcWaist and mcWaist.Parent then
						mcWaist.Transform = CFrame.Angles(0, body, 0)
					end
				end
			elseif mainModel and mainModel.Parent then
				mcShoulder.Transform = READY
			end
		end

		-- Left arm: procedural READY/slash only when no published offhand anim
		local offAnimId = AnimationConfig.GetAttackOffhandId()
		local useProcLeft = useMc or offAnimId == ""
		if useProcLeft and mcLeftShoulder and mcLeftShoulder.Parent then
			if offSwinging then
				offT += dt / swingTime
				if offT >= 1 then
					offSwinging = false
					offT = 0
					mcLeftShoulder.Transform = if offModel and offModel.Parent then READY_LEFT else CFrame.new()
				else
					local raise, roll, body = mcCurve(offT)
					mcLeftShoulder.Transform = READY_LEFT
						* CFrame.Angles(swingDir * raise * raisePower, -body * 2, roll * rollPower)
				end
			elseif offModel and offModel.Parent then
				mcLeftShoulder.Transform = READY_LEFT
			else
				mcLeftShoulder.Transform = CFrame.new()
			end
		end
	end)
end

--- Offhand slash: published AttackOffhand anim, else procedural left shoulder.
local function playOffhandSwing(): number
	-- returns approximate duration of left attack (for combo lock)
	if not offModel or not offModel.Parent then
		return 0
	end
	local char = player.Character
	if not char then
		return 0
	end

	local offId = AnimationConfig.GetAttackOffhandId()
	if offId ~= "" then
		local animator = getAnimator(char)
		if animator then
			local track = loadTrack(animator, offId)
			if track then
				waitTrackLength(track, 1.5)
				-- Stop right track so left anim is visible (sequential combo)
				local rightId = AnimationConfig.GetAttackId(false)
				local rightT = tracks[rightId]
				if rightT and rightT.IsPlaying then
					pcall(function()
						rightT:Stop(0.08)
					end)
				end
				track:Play(0.05, 1, 1.0)
				local len = track.Length
				local dur = if len > 0 then len / 1.0 else 0.4
				print("[WeaponVisual] PlayAttack LEFT →", offId, "len=", len)
				return dur
			end
		end
		warn("[WeaponVisual] offhand anim failed, procedural fallback:", offId)
	end

	if offSwinging then
		return 0.28
	end
	if not mcLeftShoulder or not mcLeftShoulder.Parent then
		mcLeftShoulder = findShoulder(char, "left")
	end
	if not mcLeftShoulder then
		return 0
	end
	bindMcRender()
	offSwinging = true
	offT = 0
	local cfg = AnimationConfig.MinecraftSwing or {}
	return cfg.SwingTime or 0.28
end

local function rightAttackDuration(rightTrack: AnimationTrack?): number
	local speed = 1.0
	if rightTrack then
		local len = waitTrackLength(rightTrack, 1.5)
		if len > 0 then
			return math.clamp(len / speed * 0.92, 0.15, 1.5)
		end
	end
	if AnimationConfig.UseMinecraftSwing then
		local cfg = AnimationConfig.MinecraftSwing or {}
		return cfg.SwingTime or 0.28
	end
	return 0.35 -- safe default stagger if Length unknown
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

function WeaponVisual.PlayAttack(_forceAlt: boolean?)
	-- Dual combo lock: spam LMB used to cancel the scheduled LEFT swing forever
	if comboBusy then
		return
	end
	local now = os.clock()
	if now - lastPlay < 0.08 then
		return
	end
	lastPlay = now

	local char = player.Character
	if not char then
		return
	end

	local hasOff = offModel ~= nil and offModel.Parent ~= nil
	local offPurchased = isOffhandPurchased()
	local useDual = canUseDualAttackAnim()
	local offId = AnimationConfig.GetAttackOffhandId()
	local dualId = AnimationConfig.GetAttackDualId()

	local function runCombo(playRight: () -> AnimationTrack?)
		comboBusy = true
		task.spawn(function()
			local ok, err = pcall(function()
				local rightTrack = playRight()
				local waitRight = rightAttackDuration(rightTrack)
				task.wait(waitRight)
				if player.Character ~= char then
					return
				end
				if hasOff and offModel and offModel.Parent then
					local leftDur = playOffhandSwing()
					task.wait(math.max(leftDur, 0.12))
				elseif hasOff then
					print("[WeaponVisual] skip LEFT — no offhand equipped")
				end
			end)
			if not ok then
				warn("[WeaponVisual] combo error:", err)
			end
			comboBusy = false
		end)
	end

	local function playSingleTrack(track: AnimationTrack, label: string)
		comboBusy = true
		task.spawn(function()
			local ok, err = pcall(function()
				for _, t in tracks do
					if t.IsPlaying then
						pcall(function()
							t:Stop(0.05)
						end)
					end
				end
				track:Play(0.05, 1, 1.0)
				print("[WeaponVisual] PlayAttack", label, "→", track.Animation and track.Animation.AnimationId or "?", "len=", track.Length)
				task.wait(rightAttackDuration(track))
			end)
			if not ok then
				warn("[WeaponVisual] attack error:", err)
			end
			comboBusy = false
		end)
	end

	-- Minecraft path: right procedural, then left
	if AnimationConfig.UseMinecraftSwing then
		if hasOff then
			runCombo(function()
				playMinecraftSwing()
				return nil
			end)
		else
			playMinecraftSwing()
		end
		return
	end

	if not mcLeftShoulder or not mcLeftShoulder.Parent then
		mcLeftShoulder = findShoulder(char, "left")
	end
	if not mcShoulder or not mcShoulder.Parent then
		mcShoulder = findRightShoulder(char)
	end
	bindMcRender()

	local animator = getAnimator(char)
	if not animator then
		warn("[WeaponVisual] no Animator")
		return
	end

	-- Dual clip: only if Offhand purchased + second sword equipped
	if useDual then
		local dualTrack = loadTrack(animator, dualId)
		if dualTrack then
			waitTrackLength(dualTrack, 1.5)
			playSingleTrack(dualTrack, "DUAL")
			if lastPlayedId ~= dualId then
				lastPlayedId = dualId
			end
			return
		end
		warn("[WeaponVisual] dual anim failed, fallback sequential:", dualId)
	elseif hasOff and not offPurchased then
		print("[WeaponVisual] dual anim locked — buy Offhand (using right-only)")
	end

	local id = AnimationConfig.GetAttackId(false)
	local track = loadTrack(animator, id)
	if not track then
		warn("[WeaponVisual] PlayAttack FAILED — id", id)
		return
	end
	waitTrackLength(track, 1.5)

	for _, t in tracks do
		if t.IsPlaying then
			pcall(function()
				t:Stop(0.05)
			end)
		end
	end

	print(
		"[WeaponVisual] PlayAttack RIGHT →",
		id,
		"len=",
		track.Length,
		"offhandEq=",
		hasOff,
		"offPurchased=",
		offPurchased,
		"dual=",
		useDual
	)

	if not hasOff or not offPurchased then
		-- One-hand (no offhand purchase or no second sword)
		playSingleTrack(track, "RIGHT")
		if lastPlayedId ~= id then
			lastPlayedId = id
		end
		return
	end

	-- Fallback: sequential RIGHT then LEFT (if dual clip unavailable)
	runCombo(function()
		track:Play(0.05, 1, 1.0)
		return track
	end)

	if lastPlayedId ~= id then
		lastPlayedId = id
	end
end

--- AUTO: loop the same right→left (or right) combo until SetAutoAttack(false).
function WeaponVisual.SetAutoAttack(enabled: boolean)
	enabled = enabled == true
	if enabled == autoAttackOn then
		return
	end
	autoAttackOn = enabled
	autoAttackToken += 1
	local token = autoAttackToken
	if not enabled then
		print("[WeaponVisual] auto attack OFF")
		return
	end
	print("[WeaponVisual] auto attack ON (loop until disabled)")
	task.spawn(function()
		while autoAttackOn and token == autoAttackToken do
			local char = player.Character
			if char and char.Parent then
				if not comboBusy then
					WeaponVisual.PlayAttack()
				end
				-- Wait for current combo to finish
				while autoAttackOn and token == autoAttackToken and comboBusy do
					task.wait(0.03)
				end
				-- Small gap between combos (same feel as manual cadence)
				if autoAttackOn and token == autoAttackToken then
					task.wait(0.06)
				end
			else
				task.wait(0.2)
			end
		end
	end)
end

function WeaponVisual.IsAutoAttack(): boolean
	return autoAttackOn
end

function WeaponVisual.IsComboBusy(): boolean
	return comboBusy
end

function WeaponVisual.Init(getProfile: () -> any?)
	getProfileFn = getProfile
	if AnimationConfig.UseMinecraftSwing then
		print("[WeaponVisual] Attack mode = MinecraftSwing (procedural)")
	else
		print(
			"[WeaponVisual] Attack mode = R",
			AnimationConfig.GetAttackId(false),
			"L",
			AnimationConfig.GetAttackOffhandId(),
			"DUAL",
			AnimationConfig.GetAttackDualId()
		)
	end

	local function onChar(char: Model)
		tracks = {}
		lastPlayedId = nil
		comboBusy = false
		-- keep autoAttackOn across respawn; loop continues
		mcSwinging = false
		mcT = 0
		offSwinging = false
		offT = 0
		mcShoulder = nil
		mcLeftShoulder = nil
		mcWaist = nil
		mcWarnedNoShoulder = false
		task.spawn(function()
			-- Wait for character stream (Humanoid + Motor6Ds); do not warn on first empty frame
			local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
			if hum then
				pcall(function()
					(hum :: Humanoid):WaitForChild("Animator", 3)
				end)
			end
			char:WaitForChild("RightUpperArm", 5)
			local deadline = os.clock() + 5
			while os.clock() < deadline and char.Parent do
				if setupMcJoints(char) then
					break
				end
				task.wait(0.1)
			end
			if not mcShoulder and char.Parent then
				warnNoShoulder(char)
			end
			-- Bind for offhand swing (and MC right arm only if UseMinecraftSwing)
			bindMcRender()
			if mcShoulder then
				print(
					"[WeaponVisual] joints ready R:",
					mcShoulder:GetFullName(),
					"L:",
					mcLeftShoulder and mcLeftShoulder:GetFullName() or "nil"
				)
			end
			preloadAttackTracks(char)
			WeaponVisual.Refresh(getProfile())
		end)
		char.Destroying:Connect(function()
			mainModel = nil
			offModel = nil
			folder = nil
			tracks = {}
			mcShoulder = nil
			mcLeftShoulder = nil
			mcWaist = nil
			mcSwinging = false
			offSwinging = false
		end)
	end

	if player.Character then
		onChar(player.Character)
	end
	player.CharacterAdded:Connect(onChar)
end

return WeaponVisual
