--!strict
--[[
	Comprehensive Asset Scanner for Roblox Studio
	Run in Command Bar to count and list ALL pet models & folders in ReplicatedStorage!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== REPLICATEDSTORAGE ASSETS REPORT ===")

local function scanFolder(folder: Instance, prefix: string)
	print(prefix .. " Folder: " .. folder.Name .. " (" .. #folder:GetChildren() .. " items)")
	for _, child in folder:GetChildren() do
		if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
			print(prefix .. "   - " .. child.Name .. " [" .. child.ClassName .. "]")
		end
	end
end

for _, child in ReplicatedStorage:GetChildren() do
	if child:IsA("Folder") then
		scanFolder(child, "📁")
	end
end

local inc = ReplicatedStorage:FindFirstChild("INCREMENTAL ASSETS")
if inc then
	print("📁 INCREMENTAL ASSETS subfolders:")
	for _, child in inc:GetChildren() do
		if child:IsA("Folder") then
			scanFolder(child, "  📂")
		end
	end
end

print("=========================================")
