--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local UpgradeConfig = require(Shared.Config.UpgradeConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local UpgradeService = {}

function UpgradeService.Init()
	Remotes.Event("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeId)
		UpgradeService.Buy(player, upgradeId)
	end)
end

function UpgradeService.Buy(player: Player, upgradeId: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local def = UpgradeConfig.Defs[upgradeId]
	if not def then
		return
	end

	local unlocked, lockReason = UpgradeConfig.IsUnlocked(profile, upgradeId)
	if not unlocked then
		Remotes.Event("Notify"):FireClient(player, {
			text = lockReason or "Upgrade locked",
			color = "red",
		})
		return
	end

	if not profile.upgradeLevels then
		profile.upgradeLevels = {}
	end
	local cur = profile.upgradeLevels[upgradeId] or 0
	if cur >= def.maxLevel then
		Remotes.Event("Notify"):FireClient(player, { text = "Max level", color = "red" })
		return
	end

	local cost = UpgradeConfig.GetCost(upgradeId, cur + 1)
	if profile.coins < cost then
		Remotes.Event("Notify"):FireClient(player, { text = "Not enough coins (" .. cost .. ")", color = "red" })
		return
	end

	profile.coins -= cost
	profile.upgradeLevels[upgradeId] = cur + 1
	ProfileService.ApplyWalkSpeed(player)
	ProfileService.Push(player)
	local extra = ""
	if upgradeId == "Power" then
		local pct = (cur + 1) * (def.effectPerLevel * 100)
		extra = string.format(" (+%g%% Power total)", pct)
	elseif upgradeId == "Backpack" then
		local cap = UpgradeConfig.GetBagCap(profile)
		extra = string.format(" (bags %d slots each)", cap)
	elseif upgradeId == "ClickSpeed" then
		extra = string.format(" (+%d%% speed)", (cur + 1) * 1)
	end
	Remotes.Event("Notify"):FireClient(player, {
		text = def.name .. " → " .. (cur + 1) .. extra,
		color = "green",
	})
end

return UpgradeService
