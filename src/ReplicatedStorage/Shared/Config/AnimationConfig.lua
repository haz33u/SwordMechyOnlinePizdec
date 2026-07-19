--!strict
--[[
	Combat attack animation — ONE source of truth.

	Attack2 only: https://create.roblox.com/store/asset/134636926386401
	rbxassetid://134636926386401
]]

local ATTACK = "rbxassetid://134636926386401"

local AnimationConfig = {
	-- === ATTACK (right hand / click) — only Attack2 ===
	AttackMain = ATTACK,
	AttackAlt = ATTACK,

	PreferPublishedAttack = true,
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	-- Same id — never fall back to default toolslash/lunge
	AttackMainFallback = ATTACK,
	AttackAltFallback = ATTACK,
	ToolHold = "rbxassetid://522696694",

	AlternateDual = false,

	SwordLength = 2.4,
	SwordWidth = 0.22,
	SwordDepth = 0.08,
}

function AnimationConfig.GetAttackId(_isAlt: boolean?): string
	return AnimationConfig.AttackMain
end

return AnimationConfig
