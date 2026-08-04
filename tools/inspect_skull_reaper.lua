--!strict
--[[
	Full read of the Skull Reaper model before it is promoted to Charon's slot.

	Two things can ruin a pet that otherwise looks right: an opaque "Root" marker
	part that was invisible only because the pack author never showed it, and a
	"HatPlacement" helper that renders as a solid blue box once cloned. Print
	transparency and CanCollide for every part so neither surprises us in game.

	Read only.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local m = ReplicatedStorage.PetModels.F:FindFirstChild("Skull Reaper")
if not m then
	print("Skull Reaper not found")
	return
end

print(string.format("Skull Reaper: %d children, primary=%s", #m:GetChildren(), m.PrimaryPart and m.PrimaryPart.Name or "NONE"))
for _, d in m:GetDescendants() do
	if d:IsA("BasePart") then
		local c = d.Color
		print(
			string.format(
				"  %-16s %-14s transparency=%.2f collide=%s size=%.2f,%.2f,%.2f rgb(%d,%d,%d)%s",
				d.Name,
				d.ClassName,
				d.Transparency,
				tostring(d.CanCollide),
				d.Size.X,
				d.Size.Y,
				d.Size.Z,
				math.round(c.R * 255),
				math.round(c.G * 255),
				math.round(c.B * 255),
				d:IsA("MeshPart") and (" mesh=" .. tostring((d :: MeshPart).MeshId)) or ""
			)
		)
	else
		print(string.format("  [%s] %s", d.ClassName, d.Name))
	end
end
