--!strict
--[[
	Soft shutdown: kick all players with save, then allow server close.
	BindToClose saves everyone; MessagingService optional cross-server warning stub.
]]

local Players = game:GetService("Players")

local ProfileService = require(script.Parent.ProfileService)

local ShutdownService = {}

function ShutdownService.Init()
	game:BindToClose(function()
		local start = os.clock()
		ProfileService.SaveAll()
		for _, player in Players:GetPlayers() do
			pcall(function()
				player:Kick("Server is restarting. Your progress has been saved!")
			end)
		end
		local elapsed = os.clock() - start
		local budget = 29 -- Roblox allows up to 30s for BindToClose
		if elapsed < budget then
			task.wait(budget - elapsed)
		end
	end)
end

return ShutdownService
