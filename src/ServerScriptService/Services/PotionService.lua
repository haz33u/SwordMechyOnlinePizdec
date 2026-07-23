--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local PotionService = {}

local POTION_CONFIG = {
	SmallCoin = { stat = "money", pct = 0.25, duration = 600, name = "Small Coin Potion (+25% Coins)" },
	MidCoin = { stat = "money", pct = 0.50, duration = 1200, name = "Medium Coin Potion (+50% Coins)" },
	BigCoin = { stat = "money", pct = 1.00, duration = 1800, name = "Big Coin Potion (+100% Coins)" },
	
	SmallPower = { stat = "power", pct = 0.25, duration = 600, name = "Small Power Potion (+25% Power)" },
	MidPower = { stat = "power", pct = 0.50, duration = 1200, name = "Medium Power Potion (+50% Power)" },
	BigPower = { stat = "power", pct = 1.00, duration = 1800, name = "Big Power Potion (+100% Power)" },

	SmallDamage = { stat = "damage", pct = 0.25, duration = 600, name = "Small Damage Potion (+25% Damage)" },
	MidDamage = { stat = "damage", pct = 0.50, duration = 1200, name = "Medium Damage Potion (+50% Damage)" },
	BigDamage = { stat = "damage", pct = 1.00, duration = 1800, name = "Big Damage Potion (+100% Damage)" },

	SmallLuck = { stat = "luck", pct = 0.25, duration = 600, name = "Small Luck Potion (+25% Luck)" },
	MidLuck = { stat = "luck", pct = 0.50, duration = 1200, name = "Medium Luck Potion (+50% Luck)" },
	BigLuck = { stat = "luck", pct = 1.00, duration = 1800, name = "Big Luck Potion (+100% Luck)" },
}

function PotionService.Init()
	Remotes.Event("UsePotion").OnServerEvent:Connect(function(player, potionId)
		PotionService.UsePotion(player, potionId)
	end)
end

function PotionService.UsePotion(player: Player, potionId: string)
	local profile = ProfileService.Get(player)
	local def = POTION_CONFIG[potionId]
	if not profile or not def then
		return
	end

	if not profile.boosts then
		profile.boosts = {}
	end

	local now = os.time()
	local existing = profile.boosts[def.stat]
	local remaining = if existing and existing.expiresAt and existing.expiresAt > now then existing.expiresAt - now else 0

	profile.boosts[def.stat] = {
		pct = def.pct,
		scope = "local",
		duration = def.duration,
		expiresAt = now + remaining + def.duration,
	}

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Activated %s! (%dm)", def.name, math.floor(def.duration / 60)),
		color = "cyan",
	})
	ProfileService.Push(player)
end

return PotionService
