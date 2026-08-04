--!strict
--[[
	Safety check before touching PetModels.

	Two things must be true before any slot is renamed or retired:

	 1. Nothing outside PetModelConfig looks up a slot by its letter name. A
	    stray FindFirstChild("F") somewhere would break silently.
	 2. There is a non-replicated place to park retired content, so nothing has
	    to be deleted to stop 3003 parts replicating to every client.

	Read only.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

print("--- ServerStorage (retirement target) ---")
for _, c in ServerStorage:GetChildren() do
	print(string.format("  %s (%s)", c.Name, c.ClassName))
end
if #ServerStorage:GetChildren() == 0 then
	print("  (empty)")
end
print("")

print("--- Other model sources PetVisual reads ---")
local inc = ReplicatedStorage:FindFirstChild("INCREMENTAL ASSETS")
if inc then
	for _, c in inc:GetChildren() do
		local n = 0
		for _, d in c:GetDescendants() do
			if d:IsA("BasePart") then
				n += 1
			end
		end
		print(string.format("  INCREMENTAL ASSETS.%s (%s, %d parts, %d children)", c.Name, c.ClassName, n, #c:GetChildren()))
	end
else
	print("  INCREMENTAL ASSETS: not present")
end
print("")

print("--- Total parts currently replicated by PetModels ---")
local total = 0
local worst: { { name: string, parts: number } } = {}
for _, c in ReplicatedStorage.PetModels:GetChildren() do
	local n = 0
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	total += n
	table.insert(worst, { name = c.Name, parts = n })
end
table.sort(worst, function(a, b)
	return a.parts > b.parts
end)
print(string.format("  %d parts across %d slots", total, #ReplicatedStorage.PetModels:GetChildren()))
for i = 1, math.min(6, #worst) do
	print(string.format("    %s: %d", worst[i].name, worst[i].parts))
end
