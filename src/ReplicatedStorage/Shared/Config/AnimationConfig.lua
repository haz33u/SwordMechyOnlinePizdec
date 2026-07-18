--!strict
--[[
	Combat animations.

	Published attack (user):
	  https://create.roblox.com/store/asset/133642421878218

	Optional KeyframeSequences in ReplicatedStorage.CombatAnimations (Swing1/Swing2)
	used only if PreferPublishedAttack = false or published id empty.
]]

local AnimationConfig = {
	-- Published sword attack (right hand / main swings)
	-- Store: https://create.roblox.com/store/asset/133642421878218
	AttackMain = "rbxassetid://133642421878218",
	-- Second hit variety — same pack for now; replace if you publish Swing2
	AttackAlt = "rbxassetid://133642421878218",

	PreferPublishedAttack = true,

	-- Optional Place folder with KeyframeSequences (fallback / legacy)
	CombatAnimsFolder = "CombatAnimations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	-- Ultimate fallback: official R15 tool anims
	AttackMainFallback = "rbxassetid://522635514",
	AttackAltFallback = "rbxassetid://522638767",
	ToolHold = "rbxassetid://522696694",

	AlternateDual = true,

	SwordLength = 2.4,
	SwordWidth = 0.22,
	SwordDepth = 0.08,
}

function AnimationConfig.GetAttackId(isAlt: boolean?): string
	if AnimationConfig.PreferPublishedAttack then
		if isAlt then
			local a = AnimationConfig.AttackAlt
			if type(a) == "string" and a ~= "" then
				return a
			end
		else
			local m = AnimationConfig.AttackMain
			if type(m) == "string" and m ~= "" then
				return m
			end
		end
	end
	if isAlt then
		return AnimationConfig.AttackAltFallback
	end
	return AnimationConfig.AttackMainFallback
end

return AnimationConfig
