--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RebirthConfig = require(Shared.Config.RebirthConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local QuestService = require(script.Parent.QuestService)

local RebirthService = {}

function RebirthService.Init()
	Remotes.Event("RequestRebirth").OnServerEvent:Connect(function(player)
		RebirthService.Try(player)
	end)
end

function RebirthService.Try(player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end

	local nextLevel = (profile.rebirthLevel or 0) + 1
	if nextLevel > RebirthConfig.MAX_LEVEL then
		Remotes.Event("Notify"):FireClient(player, { text = "Макс. перерождение", color = "red" })
		return false
	end

	local cost = RebirthConfig.GetCost(nextLevel)
	if (profile.lifetimeDamage or 0) < cost then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Нужно %.0f урона (есть %.0f)", cost, profile.lifetimeDamage or 0),
			color = "red",
		})
		return false
	end

	profile.rebirthLevel = nextLevel
	local bonus = RebirthConfig.GetBonus(nextLevel)
	profile.rebirthMult = (profile.rebirthMult or 1) * (1 + bonus)

	-- soft: do NOT wipe weapons/pets/locations
	QuestService.OnRebirth(profile)

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Перерождение %d! Mult x%.2f (+%.0f%%)", nextLevel, profile.rebirthMult, bonus * 100),
		color = "purple",
	})
	ProfileService.Push(player)
	return true
end

return RebirthService
