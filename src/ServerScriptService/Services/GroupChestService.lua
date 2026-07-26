--!strict
--[[
	Server service for Community Group Chest claims.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local GameConfig = require(Shared.Config.GameConfig)
local ProfileService = require(script.Parent.ProfileService)

local GroupChestService = {}

function GroupChestService.Init()
	Remotes.Event("ClaimGroupChest").OnServerEvent:Connect(function(player)
		GroupChestService.Claim(player)
	end)

	-- Purge old toolbox scripts from Workspace
	local Workspace = game:GetService("Workspace")
	for _, desc in Workspace:GetDescendants() do
		if desc.Name == "ChestClient" or desc.Name == "ChestServer" or desc.Name == "ChestRemotes" then
			desc:Destroy()
		end
	end
end

function GroupChestService.Claim(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local groupId = GameConfig.ROBLOX_GROUP_ID or 0
	if groupId > 0 then
		local isMember = false
		local ok, err = pcall(function()
			isMember = player:IsInGroup(groupId)
		end)
		if not ok or not isMember then
			print(string.format("[GroupChest] Player %s is NOT in Roblox Group %d", player.Name, groupId))
			Remotes.Event("OpenGroupModal"):FireClient(player, { groupId = groupId })
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("👥 Join our Roblox Group to unlock Daily Chest Rewards! (Group ID: %d)", groupId),
				color = "yellow",
			})
			return
		else
			print(string.format("[GroupChest] Player %s verified member of Roblox Group %d", player.Name, groupId))
		end
	else
		print("[GroupChest] ROBLOX_GROUP_ID is 0 (Test mode) — skipping group membership check")
	end

	local now = os.time()
	local lastClaim = profile.lastGroupChestTime or 0
	local COOLDOWN = 86400 -- 24 hours

	if (now - lastClaim) < COOLDOWN then
		local remSec = COOLDOWN - (now - lastClaim)
		local hours = math.floor(remSec / 3600)
		local mins = math.floor((remSec % 3600) / 60)
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Chest on cooldown! Ready in %dh %dm", hours, mins),
			color = "red",
		})
		return
	end

	profile.lastGroupChestTime = now
	profile.coins = (profile.coins or 0) + 10_000
	profile.petKeys = (profile.petKeys or 0) + 3
	profile.auraKeys = (profile.auraKeys or 0) + 1

	Remotes.Event("Notify"):FireClient(player, {
		text = "🎁 Group Chest Claimed! +10,000 Coins, +3 Pet Keys, +1 Aura Key!",
		color = "gold",
	})

	ProfileService.Push(player)
end

return GroupChestService
