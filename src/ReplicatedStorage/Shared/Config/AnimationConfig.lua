--!strict
--[[
	Combat attack animation — ONE source of truth.

	Your published / store animation:
	  https://create.roblox.com/store/asset/133642421878218
	  rbxassetid://133642421878218

	Also set on Place: ReplicatedStorage.Animations.Swing.AnimationId (same id).
	WeaponVisual plays ONLY this (and AttackAlt if different).
]]

local AnimationConfig = {
	-- === ATTACK (right hand / click) — change THESE only ===
	AttackMain = "rbxassetid://133642421878218",
	AttackAlt = "rbxassetid://133642421878218", -- set another id when you have Swing2 published

	-- true = always use AttackMain/AttackAlt above (recommended)
	PreferPublishedAttack = true,

	-- Do NOT auto-use Combat Dummy KeyframeSequences (they look "wrong"/random)
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	-- Only if AttackMain fails to load
	AttackMainFallback = "rbxassetid://522635514",
	AttackAltFallback = "rbxassetid://522638767",
	ToolHold = "rbxassetid://522696694",

	AlternateDual = false, -- one attack anim until you set a real AttackAlt

	SwordLength = 2.4,
	SwordWidth = 0.22,
	SwordDepth = 0.08,
}

function AnimationConfig.GetAttackId(isAlt: boolean?): string
	if isAlt then
		local a = AnimationConfig.AttackAlt
		if type(a) == "string" and a ~= "" then
			return a
		end
		return AnimationConfig.AttackAltFallback
	end
	local m = AnimationConfig.AttackMain
	if type(m) == "string" and m ~= "" then
		return m
	end
	return AnimationConfig.AttackMainFallback
end

return AnimationConfig
