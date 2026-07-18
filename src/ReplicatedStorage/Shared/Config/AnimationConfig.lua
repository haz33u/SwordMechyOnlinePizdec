--!strict
--[[
	Combat / equip animations.

	Default IDs = Roblox R15 built-in Tool animations (same as default Animate script):
	  toolslash  522635514
	  toollunge  522638767
	  toolnone   522696694

	These work without uploading. Replace with your published Animation IDs
	when you have custom sword swings (R15/Rthro recommended).
]]

local AnimationConfig = {
	-- Primary attack (right hand / main)
	AttackMain = "rbxassetid://522635514", -- R15 toolslash
	-- Secondary / dual variety (left hand cue)
	AttackAlt = "rbxassetid://522638767", -- R15 toollunge
	-- Idle hold while weapons equipped (optional soft layer)
	ToolHold = "rbxassetid://522696694", -- R15 toolnone

	-- If true, alternate slash/lunge each swing when dual wielding
	AlternateDual = true,

	-- Visual sword parts (placeholder until mesh catalog)
	SwordLength = 2.4,
	SwordWidth = 0.22,
	SwordDepth = 0.08,
}

function AnimationConfig.GetAttackId(isAlt: boolean?): string
	if isAlt then
		return AnimationConfig.AttackAlt
	end
	return AnimationConfig.AttackMain
end

return AnimationConfig
