--!strict
--[[
	CleanLegacySoundsService.lua
	Automatically purges legacy unowned sound assets (172154904, 157167205)
	from Workspace, PoseTexture, and legacy models on game boot.
]]

local CleanLegacySoundsService = {}

local BANNED_SOUND_IDS = {
	["172154904"] = true,
	["157167205"] = true,
}

local function checkAndDestroy(inst: Instance)
	pcall(function()
		if inst:IsA("Sound") then
			local soundId = inst.SoundId
			for badId in pairs(BANNED_SOUND_IDS) do
				if string.find(soundId, badId) then
					inst:Destroy()
					return
				end
			end
		elseif inst.Name == "PoseTexture" or inst.Name == "FlayoDev Admin Messages" then
			inst:Destroy()
		end
	end)
end

function CleanLegacySoundsService.Init()
	for _, desc in ipairs(game:GetDescendants()) do
		checkAndDestroy(desc)
	end

	game.DescendantAdded:Connect(checkAndDestroy)
end

CleanLegacySoundsService.Init()

return CleanLegacySoundsService
