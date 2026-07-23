--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProfileService = require(script.Parent.ProfileService)
local QuestService = require(script.Parent.QuestService)

local FriendService = {}

local friendPlayTimeTracker = {} :: { [Player]: number }

function FriendService.Init()
	Players.PlayerAdded:Connect(function(player)
		task.delay(2, function()
			FriendService.UpdateAllFriends()
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		friendPlayTimeTracker[player] = nil
		task.delay(1, function()
			FriendService.UpdateAllFriends()
		end)
	end)

	-- Periodically update friend playtime & friend quest progress (every 10 seconds)
	task.spawn(function()
		while true do
			task.wait(10)
			FriendService.TickFriendPlaytime(10)
		end
	end)
end

function FriendService.UpdateAllFriends()
	local currentPlayers = Players:GetPlayers()
	for _, player in currentPlayers do
		task.spawn(function()
			local friendCount = 0
			local userIds = {}
			
			for _, otherPlayer in currentPlayers do
				if otherPlayer == player then continue end
				
				local isFriend = false
				local ok, res = pcall(function()
					return player:IsFriendsWith(otherPlayer.UserId)
				end)
				if ok and res then
					isFriend = true
				end
				
				if isFriend then
					friendCount += 1
					table.insert(userIds, otherPlayer.UserId)
				end
			end
			
			player:SetAttribute("friends_in_game", friendCount)
			
			-- Update Quest Service progress for 2nd friend quest
			if friendCount >= 2 then
				QuestService.OnEvent(player, "SecondFriendOnline", 1)
			end
		end)
	end
end

function FriendService.TickFriendPlaytime(dtSeconds: number)
	for _, player in Players:GetPlayers() do
		local friendCount = (player:GetAttribute("friends_in_game") or 0) :: number
		if friendCount > 0 then
			local cur = (friendPlayTimeTracker[player] or 0) + dtSeconds
			if cur >= 60 then
				local elapsedMinutes = math.floor(cur / 60)
				friendPlayTimeTracker[player] = cur - (elapsedMinutes * 60)
				QuestService.OnEvent(player, "PlayWithFriendMinutes", elapsedMinutes)
			else
				friendPlayTimeTracker[player] = cur
			end
		end
	end
end

function FriendService.GetFriendCount(player: Player): number
	return (player:GetAttribute("friends_in_game") or 0) :: number
end

return FriendService
