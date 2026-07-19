--!strict
--[[
	ONE attack animation only — user asset 95040065182870.
	No slash/lunge/tool fallbacks for combat swings.
]]

local ATTACK = "rbxassetid://95040065182870"

local AnimationConfig = {
	AttackMain = ATTACK,
	AttackAlt = ATTACK,

	-- Single entry — WeaponVisual must not try anything else
	AttackCandidates = { ATTACK },

	PreferPublishedAttack = true,
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	-- Same id only (no other attack anims)
	AttackMainFallback = ATTACK,
	AttackAltFallback = ATTACK,
	ToolHold = ATTACK,

	AlternateDual = false,

	-- Walk/idle only (not attacks)
	Locomotion = {
		Idle = "rbxassetid://507766666",
		Walk = "rbxassetid://507777826",
		Run = "rbxassetid://507767714",
	},

	BannedAssetIds = {
		["12741376562"] = true,
		["rbxassetid://12741376562"] = true,
		-- old public tool swings — do not use for attack
		["522635514"] = true,
		["rbxassetid://522635514"] = true,
		["522638767"] = true,
		["rbxassetid://522638767"] = true,
		["507768375"] = true,
		["rbxassetid://507768375"] = true,
		["522696694"] = true,
		["rbxassetid://522696694"] = true,
		["134636926386401"] = true,
		["rbxassetid://134636926386401"] = true,
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
	return ATTACK
end

function AnimationConfig.GetAttackCandidateList(_preferAlt: boolean?): { string }
	return { ATTACK }
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
