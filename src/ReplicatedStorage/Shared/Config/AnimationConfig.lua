--!strict
--[[
	Combat + locomotion animation IDs.

	Attack = official Roblox tool slash (both AttackMain / AttackAlt).
	BannedIds: Place assets we cannot load (permission) — never use.
]]

local SLASH = "rbxassetid://522635514"

local AnimationConfig = {
	-- === ATTACK (character swing; covers dual-wield visual on grips) ===
	AttackMain = SLASH,
	AttackAlt = SLASH,

	PreferPublishedAttack = true, -- never trust Place Swing AnimationId
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	AttackMainFallback = SLASH,
	AttackAltFallback = SLASH,
	ToolHold = "rbxassetid://522696694",

	AlternateDual = false,

	-- Safe public R15 locomotion (replace Place bad ids)
	Locomotion = {
		Idle = "rbxassetid://507766666",
		Walk = "rbxassetid://507777826",
		Run = "rbxassetid://507767714",
	},

	-- Never LoadAnimation these (permission / broken)
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
