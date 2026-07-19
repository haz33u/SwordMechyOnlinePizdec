--!strict
--[[
	CombatController (client LocalScript)
	1) Idle / Walk / Run — safe public R15 ids (never load banned Place assets)
	2) Sprint on SHIFT (1.6x WalkSpeed)
	3) Disables default Animate to avoid fights with custom locomotion

	Attack swings: WeaponVisual.PlayAttack (App / Hud / CombatFx)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationConfig = require(Shared.Config.AnimationConfig)

local player = Players.LocalPlayer

local animFolder = ReplicatedStorage:FindFirstChild("Animations")
if not animFolder then
	warn("[CombatController] ReplicatedStorage.Animations missing — using code-only locomotion ids")
end

local function sanitizePlaceAnimations()
	if not animFolder then
		return
	end
	for _, child in animFolder:GetChildren() do
		if child:IsA("Animation") then
			local id = child.AnimationId
			if AnimationConfig.IsBannedId(id) then
				local safe = AnimationConfig.GetLocomotionId(child.Name)
				if child.Name == "Swing" or child.Name == "Attack" then
					safe = AnimationConfig.AttackMain
				end
				child.AnimationId = safe
				print("[CombatController] replaced banned AnimationId on", child.Name, "→", safe)
			end
		end
	end
end

local function makeAnim(name: string, id: string): Animation
	local a = Instance.new("Animation")
	a.Name = name
	a.AnimationId = id
	return a
end

local function resolveAnimation(name: string): Animation?
	-- Prefer code-safe ids always for Idle/Walk/Run (avoids Place permission errors)
	if name == "Idle" or name == "Walk" or name == "Run" then
		return makeAnim(name, AnimationConfig.GetLocomotionId(name))
	end

	if not animFolder then
		return nil
	end
	local animInstance = animFolder:FindFirstChild(name)
	if not animInstance then
		return nil
	end

	if animInstance:IsA("Animation") then
		local id = animInstance.AnimationId
		if AnimationConfig.IsBannedId(id) then
			return makeAnim(name, AnimationConfig.GetLocomotionId(name))
		end
		if id == "" or id == "rbxassetid://0" then
			local ks = animInstance:FindFirstChildOfClass("KeyframeSequence")
			if ks then
				local ok, regId = pcall(function()
					return KeyframeSequenceProvider:RegisterKeyframeSequence(ks)
				end)
				if ok and type(regId) == "string" and regId ~= "" and not AnimationConfig.IsBannedId(regId) then
					return makeAnim(name, regId)
				end
			end
			return makeAnim(name, AnimationConfig.GetLocomotionId(name))
		end
		return animInstance
	end

	if animInstance:IsA("KeyframeSequence") then
		local ok, regId = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(animInstance)
		end)
		if ok and type(regId) == "string" and regId ~= "" and not AnimationConfig.IsBannedId(regId) then
			return makeAnim(name, regId)
		end
	end

	return makeAnim(name, AnimationConfig.GetLocomotionId(name))
end

local tracks: { [string]: AnimationTrack? } = {
	idle = nil,
	walk = nil,
	run = nil,
}

local humanoid: Humanoid? = nil
local animator: Animator? = nil
local currentMovementTrack: AnimationTrack? = nil
local renderConn: RBXScriptConnection? = nil

local PRIORITY_MAP = {
	idle = Enum.AnimationPriority.Idle,
	walk = Enum.AnimationPriority.Movement,
	run = Enum.AnimationPriority.Movement,
}

local isSprinting = false
local baseWalkSpeed = 16
local SPRINT_MULT = 1.6

local function updateSprint()
	if not humanoid then
		return
	end
	if isSprinting then
		humanoid.WalkSpeed = baseWalkSpeed * SPRINT_MULT
	else
		humanoid.WalkSpeed = baseWalkSpeed
	end
end

local function setupAnimator(char: Model)
	humanoid = char:WaitForChild("Humanoid") :: Humanoid

	local animateScript = char:FindFirstChild("Animate")
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Disabled = true
	elseif animateScript and animateScript:IsA("Script") then
		(animateScript :: any).Disabled = true
	end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	sanitizePlaceAnimations()

	tracks = { idle = nil, walk = nil, run = nil }
	currentMovementTrack = nil

	local animDefs = {
		idle = resolveAnimation("Idle"),
		walk = resolveAnimation("Walk"),
		run = resolveAnimation("Run"),
	}

	for name, animInst in animDefs do
		if animInst and animator then
			local ok, track = pcall(function()
				return animator:LoadAnimation(animInst)
			end)
			if ok and track then
				local prio = PRIORITY_MAP[name]
				if prio then
					track.Priority = prio
				end
				track.Looped = true
				tracks[name] = track
				print(string.format("[CombatController] Loaded '%s' → %s", name, animInst.AnimationId))
			else
				warn("[CombatController] Load failed", name, track)
			end
		else
			warn("[CombatController] missing animation asset:", name)
		end
	end
end

local function updateMovementAnimation()
	if not humanoid or not animator then
		return
	end
	if humanoid.Health <= 0 then
		if currentMovementTrack and currentMovementTrack.IsPlaying then
			currentMovementTrack:Stop(0.3)
		end
		return
	end

	local speed = humanoid.MoveDirection.Magnitude
	local want: AnimationTrack? = nil
	if speed < 0.05 then
		want = tracks.idle
	elseif isSprinting then
		want = tracks.run or tracks.walk
	else
		want = tracks.walk or tracks.run
	end

	if want and want ~= currentMovementTrack then
		if currentMovementTrack and currentMovementTrack.IsPlaying then
			currentMovementTrack:Stop(0.2)
		end
		want:Play(0.2)
		currentMovementTrack = want
	elseif want and not want.IsPlaying then
		want:Play(0.2)
		currentMovementTrack = want
	end
end

local function onCharacter(char: Model)
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	setupAnimator(char)
	renderConn = RunService.RenderStepped:Connect(updateMovementAnimation)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isSprinting = true
		updateSprint()
	end
end)

UserInputService.InputEnded:Connect(function(input, _gp)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isSprinting = false
		updateSprint()
	end
end)

if player.Character then
	onCharacter(player.Character)
end
player.CharacterAdded:Connect(onCharacter)

print("[CombatController] initialized (safe locomotion; banned 12741376562)")
