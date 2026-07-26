--!strict
--[[
	Server service for Title selection & validation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local TitleConfig = require(Shared.Config.TitleConfig)
local ProfileService = require(script.Parent.ProfileService)

local TitleService = {}

function TitleService.Init()
	Remotes.Event("SelectTitle").OnServerEvent:Connect(function(player, titleId)
		TitleService.SelectTitle(player, titleId)
	end)
end

function TitleService.SelectTitle(player: Player, titleId: any)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	if type(titleId) ~= "string" or titleId == "" or titleId == "none" then
		profile.title = nil
		Remotes.Event("Notify"):FireClient(player, {
			text = "Title unequipped (showing Rebirth rank)",
			color = "yellow",
		})
		ProfileService.Push(player)
		return
	end

	local def = TitleConfig.Get(titleId)
	if not def then
		Remotes.Event("Notify"):FireClient(player, { text = "Unknown Title", color = "red" })
		return
	end

	if not TitleConfig.IsUnlocked(profile, def.id) then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Title locked (requires Rebirth %d)", def.minRebirth),
			color = "red",
		})
		return
	end

	profile.title = def.name
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Equipped Title: %s (+%.0f%% Power)", def.name, def.powerPct * 100),
		color = "gold",
	})
	ProfileService.Push(player)
end

return TitleService
