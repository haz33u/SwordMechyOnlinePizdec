--!strict
--[[
	FerrymanService — no NPC. Keeps the OpenTravel remote alive so the HUD / L key
	can open the locations panel. Also scrubs any leftover Ferryman models from
	Workspace (legacy place state or old Rojo runs).
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local FerrymanService = {}

local function cleanupFerryman()
	for _, desc in Workspace:GetDescendants() do
		if desc:IsA("Model") and string.find(string.lower(desc.Name), "ferryman") then
			pcall(function()
				desc:Destroy()
			end)
		end
	end
	local npcs = Workspace:FindFirstChild("NPCs")
	if npcs and npcs:IsA("Folder") then
		for _, child in npcs:GetChildren() do
			if child:IsA("Model") and string.find(string.lower(child.Name), "ferryman") then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end
end

function FerrymanService.Init()
	Remotes.Event("OpenTravel") -- ensure remote exists for client travel panel
	task.defer(function()
		task.wait(1)
		cleanupFerryman()
		print("[FerrymanService] OpenTravel remote ready; no Ferryman NPC spawned.")
	end)
end

return FerrymanService
