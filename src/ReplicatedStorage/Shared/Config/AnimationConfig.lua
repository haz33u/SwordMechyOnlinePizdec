--!strict
--[[
	Official Roblox public animation IDs only (no private / duplicated assets).

	Do NOT "Duplicate" animations in Creator Dashboard — that creates a NEW
	asset you own that can be empty/private. Just paste rbxassetid://NUMBER.

	All IDs below are Roblox default R15 Animate-script assets (load for everyone).
]]

-- Primary attack candidates (first that loads wins). Alternate clicks can rotate.
local TOOL_SLASH = "rbxassetid://522635514" -- default R15 tool slash
local TOOL_LUNGE = "rbxassetid://522638767" -- default R15 tool lunge
local TOOL_NONE = "rbxassetid://507768375" -- default R15 tool hold (weak fallback)
-- Same assets, alternate URL form (some Studio builds resolve one better)
local TOOL_SLASH_HTTP = "http://www.roblox.com/asset/?id=522635514"
local TOOL_LUNGE_HTTP = "http://www.roblox.com/asset/?id=522638767"

local AnimationConfig = {
	-- Prefer lunge first if slash flaked after "duplicate" experiments
	AttackMain = TOOL_LUNGE,
	AttackAlt = TOOL_SLASH,

	-- Ordered list tried by WeaponVisual until LoadAnimation succeeds
	AttackCandidates = {
		TOOL_LUNGE,
		TOOL_SLASH,
		TOOL_LUNGE_HTTP,
		TOOL_SLASH_HTTP,
		TOOL_NONE,
	},

	PreferPublishedAttack = true,
	UseCombatKeyframeSequences = false,

	CombatAnimsFolder = "CombatAnimations",
	ExtraAnimsFolder = "Animations",
	Swing1Name = "Swing1",
	Swing2Name = "Swing2",

	AttackMainFallback = TOOL_SLASH,
	AttackAltFallback = TOOL_LUNGE,
	ToolHold = "rbxassetid://522696694",

	AlternateDual = true, -- lunge ↔ slash each click

	Locomotion = {
		Idle = "rbxassetid://507766666",
		Walk = "rbxassetid://507777826",
		Run = "rbxassetid://507767714",
	},

	BannedAssetIds = {
		["12741376562"] = true,
		["rbxassetid://12741376562"] = true,
		-- user's published Attack2 if it flakes without permission (keep playable)
		-- ["134636926386401"] = true, -- uncomment if still errors
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

function AnimationConfig.GetAttackId(isAlt: boolean?): string
	if isAlt then
		return AnimationConfig.AttackAlt
	end
	return AnimationConfig.AttackMain
end

function AnimationConfig.GetAttackCandidateList(preferAlt: boolean?): { string }
	local primary = AnimationConfig.GetAttackId(preferAlt == true)
	local list = { primary }
	for _, id in AnimationConfig.AttackCandidates do
		local dup = false
		for _, e in list do
			if e == id then
				dup = true
				break
			end
		end
		if not dup and not AnimationConfig.IsBannedId(id) then
			table.insert(list, id)
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
