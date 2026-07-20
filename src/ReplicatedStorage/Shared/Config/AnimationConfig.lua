--!strict
--[[
	Attack presentation:
	  UseMinecraftSwing = true  → procedural Minecraft-like Motor6D swing (no asset)
	  UseMinecraftSwing = false → rbxassetid AttackMain (published anim)

	Default: published user attack anim (MC swing optional).
]]

-- Right / left hand attacks (user assets, 2026-07-20)
local ATTACK_RIGHT = "rbxassetid://131793860537357"
local ATTACK_RIGHT_BRUTAL = "rbxassetid://86113662553657" -- spare right-hand set (future)
local ATTACK_LEFT = "rbxassetid://97155624777350"

local AnimationConfig = {
	-- false = published AttackMain (right) + AttackOffhand (left when dual-wield)
	UseMinecraftSwing = false,

	MinecraftSwing = {
		SwingTime = 0.28,
		RaisePower = 1.15,
		RollPower = 0.45,
		SwingDir = -1, -- flip to 1 if swings backward
		SoundId = "rbxasset://sounds/swordslash.wav",
		SoundVolume = 0.6,
	},

	--[[
		Presets (switch AttackMain later without losing ids):
		  default  = ATTACK_RIGHT
		  brutal   = ATTACK_RIGHT_BRUTAL  (saved for future)
	]]
	AttackPresets = {
		defaultRight = ATTACK_RIGHT,
		brutalRight = ATTACK_RIGHT_BRUTAL,
		defaultLeft = ATTACK_LEFT,
	},

	-- Active set (use brutal: AttackMain = AnimationConfig.AttackPresets.brutalRight)
	AttackMain = ATTACK_RIGHT,
	AttackOffhand = ATTACK_LEFT,
	AttackAlt = ATTACK_RIGHT_BRUTAL, -- alt / future brutal right
	AttackCandidates = { ATTACK_RIGHT, ATTACK_RIGHT_BRUTAL },

	PreferPublishedAttack = true,
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	AttackMainFallback = ATTACK_RIGHT,
	AttackAltFallback = ATTACK_RIGHT_BRUTAL,
	ToolHold = ATTACK_RIGHT,

	AlternateDual = false,

	Locomotion = {
		Idle = "rbxassetid://507766666",
		Walk = "rbxassetid://507777826",
		Run = "rbxassetid://507767714",
	},

	BannedAssetIds = {
		["12741376562"] = true,
		["rbxassetid://12741376562"] = true,
	},

	SwordLength = 2.4,
	SwordWidth = 0.22,
	SwordDepth = 0.08,
}

function AnimationConfig.IsBannedId(id: string?): boolean
	if type(id) ~= "string" or id == "" or id == "rbxassetid://0" then
		return true
	end
	if AnimationConfig.BannedAssetIds[id] then
		return true
	end
	local num = string.match(id, "(%d+)")
	if num and AnimationConfig.BannedAssetIds[num] then
		return true
	end
	return false
end

function AnimationConfig.GetAttackId(_isAlt: boolean?): string
	return AnimationConfig.AttackMain
end

--- Left-hand / offhand attack AnimationId (empty → procedural fallback)
function AnimationConfig.GetAttackOffhandId(): string
	local id = AnimationConfig.AttackOffhand
	if type(id) == "string" and id ~= "" and not AnimationConfig.IsBannedId(id) then
		return id
	end
	return ""
end

function AnimationConfig.GetAttackCandidateList(_preferAlt: boolean?): { string }
	return { AnimationConfig.AttackMain }
end

function AnimationConfig.GetLocomotionId(name: string): string
	local loc = AnimationConfig.Locomotion
	if name == "Idle" then
		return loc.Idle
	elseif name == "Walk" then
		return loc.Walk
	elseif name == "Run" then
		return loc.Run
	end
	return loc.Idle
end

return AnimationConfig
