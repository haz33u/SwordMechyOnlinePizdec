--!strict
--[[
	CombatController (client LocalScript)
	1) Idle / Walk / Run from ReplicatedStorage.Animations (NOT Shared.Animations)
	2) Sprint on SHIFT (1.6x WalkSpeed)
	3) Disables default Animate to avoid fights with custom locomotion

	Attack swings: WeaponVisual.PlayAttack (App / Hud / CombatFx)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local player = Players.LocalPlayer

-- Rojo-safe location (outside Shared)
local animFolder = ReplicatedStorage:WaitForChild("Animations", 30)
if not animFolder then
	warn("[CombatController] ReplicatedStorage.Animations missing — locomotion off")
end

local function resolveAnimation(name: string): Animation?
	if not animFolder then
		return nil
	end
	local animInstance = animFolder:FindFirstChild(name)
	if not animInstance then
		return nil
	end

	if animInstance:IsA("Animation") then
		if animInstance.AnimationId == "" or animInstance.AnimationId == "rbxassetid://0" then
			local ks = animInstance:FindFirstChildOfClass("KeyframeSequence")
			if ks then
				local ok, id = pcall(function()
					return KeyframeSequenceProvider:RegisterKeyframeSequence(ks)
				end)
				if ok and type(id) == "string" and id ~= "" then
					animInstance.AnimationId = id
				else
					warn("[CombatController] could not register KFS for", name)
					return nil
				end
			else
				warn("[CombatController] Animation", name, "has empty AnimationId and no KeyframeSequence")
				return nil
			end
		end
		return animInstance
	end

	if animInstance:IsA("KeyframeSequence") then
		local ok, id = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(animInstance)
		end)
		if ok and type(id) == "string" and id ~= "" then
			local a = Instance.new("Animation")
			a.Name = name
			a.AnimationId = id
			a.Parent = animFolder
			return a
		end
	end

	return nil
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
		-- rare
		(animateScript :: any).Disabled = true
	end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

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
				print(string.format("[CombatController] Loaded '%s'", name))
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

	local moveMag = humanoid.MoveDirection.Magnitude
	local rootPart = humanoid.RootPart
	local velocitySpeed = 0
	if rootPart then
		local vel = rootPart.AssemblyLinearVelocity
		velocitySpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	end
	local isMoving = moveMag > 0.1 or velocitySpeed > 1

	local desired: AnimationTrack? = nil
	if isMoving then
		if isSprinting and tracks.run then
			desired = tracks.run
		elseif tracks.walk then
			desired = tracks.walk
		elseif tracks.run then
			desired = tracks.run
		end
	else
		desired = tracks.idle
	end

	if desired and desired ~= currentMovementTrack then
		if currentMovementTrack and currentMovementTrack.IsPlaying then
			currentMovementTrack:Stop(0.15)
		end
		desired:Play(0.15)
		currentMovementTrack = desired
	elseif desired and not desired.IsPlaying then
		desired:Play(0.15)
		currentMovementTrack = desired
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
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

local function onCharacterAdded(character: Model)
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end

	local hum = character:WaitForChild("Humanoid") :: Humanoid
	task.wait(0.3)
	baseWalkSpeed = hum.WalkSpeed
	setupAnimator(character)

	if tracks.idle then
		tracks.idle:Play(0.3)
		currentMovementTrack = tracks.idle
	end

	renderConn = RunService.RenderStepped:Connect(function()
		updateMovementAnimation()
	end)
end

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

print("[CombatController] initialized (Animations @ ReplicatedStorage.Animations)")
