--!strict
--[[
	Soft shutdown: kick all players with save, then allow server close.
	BindToClose saves everyone; MessagingService optional cross-server warning stub.
]]

local Players = game:GetService("Players")

local ProfileService = require(script.Parent.ProfileService)

local ShutdownService = {}

--[[
	Roblox gives BindToClose ~30s and closes the server as soon as the callback
	returns. ProfileService.Save yields on SetAsync, so SaveAll already blocks
	until every write has landed — there is nothing left to wait for after it.

	Do NOT pad this out to the full budget: that stalls every restart by ~30s
	even when the saves took milliseconds.
]]
function ShutdownService.Init()
	game:BindToClose(function()
		local start = os.clock()
		ProfileService.SaveAll()
		for _, player in Players:GetPlayers() do
			pcall(function()
				player:Kick("Server is restarting. Your progress has been saved!")
			end)
		end
		-- Brief grace so the kick message reaches clients before the socket drops.
		task.wait(0.5)
		local elapsed = os.clock() - start
		if elapsed > 25 then
			warn(string.format("[ShutdownService] saves took %.1fs — close to the 30s budget", elapsed))
		end
	end)
end

return ShutdownService
