--!strict
--[[
	Attack animation = published asset 95040065182870 (user).

	Character: default Roblox Player.Character (R15 from Avatar).
	Not a custom model in git — Place/Avatar settings.
	Swing: WeaponVisual loads AnimationId onto character Humanoid.Animator.
]]

local USER_ATTACK = "rbxassetid://95040065182870"

-- Public R15 fallbacks if user asset fails permission/load
local TOOL_LUNGE = "rbxassetid://522638767"
local TOOL_SLASH = "rbxassetid://522635514"

local AnimationConfig = {
	AttackMain = USER_ATTACK,
	AttackAlt = USER_ATTACK,

	AttackCandidates = {
		USER_ATTACK,
		"http://www.roblox.com/asset/?id=95040065182870",
		TOOL_LUNGE,
		TOOL_SLASH,
	},

	PreferPublishedAttack = true,
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	AttackMainFallback = TOOL_LUNGE,
	AttackAltFallback = TOOL_SLASH,
	ToolHold = "rbxassetid://522696694",

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
	local list = {}
	for _, id in AnimationConfig.AttackCandidates do
		if not AnimationConfig.IsBannedId(id) then
			local dup = false
			for _, e in list do
				if e == id then
					dup = true
					break
				end
			end
			if not dup then
				table.insert(list, id)
			end
		end
	end
	return list
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
