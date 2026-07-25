--!strict
--[[
	MasteryService.lua
	Handles player mastery progression for weapon swings and mob kills.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MasteryConfig = require(Shared.Config.MasteryConfig)
local ProfileService = require(script.Parent.ProfileService)
local Remotes = require(Shared.Remotes)

local MasteryService = {}

function MasteryService.AddXp(player: Player, masteryId: string, amount: number)
	local profile = ProfileService.Get(player)
	if not profile then return end

	local def = MasteryConfig.Get(masteryId)
	if not def then return end

	profile.masteries = profile.masteries or {}
	local oldXp = profile.masteries[masteryId] or 0
	local oldLevel = MasteryConfig.GetLevel(oldXp, def)

	local newXp = oldXp + amount
	profile.masteries[masteryId] = newXp

	local newLevel = MasteryConfig.GetLevel(newXp, def)
	if newLevel > oldLevel then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Mastery Level Up! %s -> Lv.%d", def.name, newLevel),
			color = "gold",
		})
	end
end

function MasteryService.OnSwing(player: Player)
	MasteryService.AddXp(player, "weapon_sword", 1)
end

function MasteryService.OnMobKill(player: Player, mobDef: any)
	if not mobDef then return end
	if mobDef.isBoss then
		MasteryService.AddXp(player, "mob_boss", 1)
	else
		MasteryService.AddXp(player, "mob_simple", 1)
	end
end

function MasteryService.GetBonusMultiplier(profile: any): (number, number)
	if not profile or not profile.masteries then
		return 1.0, 0.0
	end

	local totalPowerMult = 1.0
	local totalCritAdd = 0.0

	for id, xp in profile.masteries do
		local def = MasteryConfig.Get(id)
		if def then
			local lvl = MasteryConfig.GetLevel(xp, def)
			if lvl > 0 then
				totalPowerMult += (lvl * def.bonusPowerPctPerLevel) / 100
				totalCritAdd += (lvl * def.bonusCritPctPerLevel) / 100
			end
		end
	end

	return totalPowerMult, totalCritAdd
end

return MasteryService
