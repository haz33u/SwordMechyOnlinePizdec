--!strict
--[[
	Attack presentation:
	  UseMinecraftSwing = true  → procedural Minecraft-like Motor6D swing (no asset)
	  UseMinecraftSwing = false → rbxassetid AttackMain (published anim)

	Default: published user attack anim (MC swing optional).
]]

-- Right-hand attack (user asset, 2026-07-20)
local ATTACK = "rbxassetid://131793860537357"

local AnimationConfig = {
	-- false = play AttackMain AnimationId on right arm; offhand still uses procedural swing
	UseMinecraftSwing = false,

	MinecraftSwing = {
		SwingTime = 0.28,
		RaisePower = 1.15,
		RollPower = 0.45,
		SwingDir = -1, -- flip to 1 if swings backward
		SoundId = "rbxasset://sounds/swordslash.wav",
		SoundVolume = 0.6,
	},

	AttackMain = ATTACK,
	AttackAlt = ATTACK,
	AttackCandidates = { ATTACK },

	PreferPublishedAttack = true,
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	AttackMainFallback = ATTACK,
	AttackAltFallback = ATTACK,
	ToolHold = ATTACK,

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
