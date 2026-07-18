--!strict
--[[
	Combat animations.

	Preferred: KeyframeSequences in ReplicatedStorage.CombatAnimations
	  (copied from ServerStorage AnimPack_SwordFightingCombat / Combat Dummy / AnimSaves)
	  Swing1, Swing2 — both right-hand sword swings (no publish / no rbxassetid needed)

	Fallback: Roblox default R15 toolslash / toollunge asset ids.
]]

local AnimationConfig = {
	-- Folder under ReplicatedStorage with KeyframeSequence children
	CombatAnimsFolder = "CombatAnimations",
	Swing1Name = "Swing1", -- was AnimSaves.swing1
	Swing2Name = "Swing2", -- was AnimSaves.swing2

	-- Fallback if folder missing (official R15 Tool anims)
	AttackMainFallback = "rbxassetid://522635514",
	AttackAltFallback = "rbxassetid://522638767",
	ToolHold = "rbxassetid://522696694",

	-- Alternate Swing1 / Swing2 every attack (both for right / main hand)
	AlternateDual = true,

	SwordLength = 2.4,
	SwordWidth = 0.22,
	SwordDepth = 0.08,
}

function AnimationConfig.GetAttackId(isAlt: boolean?): string
	if isAlt then
		return AnimationConfig.AttackAltFallback
	end
	return AnimationConfig.AttackMainFallback
end

return AnimationConfig
