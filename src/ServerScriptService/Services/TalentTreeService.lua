--!strict
--[[
	TALENT TREE SERVICE
	
	Server validation for unlocking nodes on the hexagonal talent tree.
	Applies Coin or TalentPoint costs and updates profile.unlockedTalents.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TalentTreeConfig = require(Shared.Config.TalentTreeConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local TalentTreeService = {}

function TalentTreeService.Init()
	Remotes.Event("UnlockTalentNode").OnServerEvent:Connect(function(player, nodeId)
		TalentTreeService.UnlockNode(player, nodeId)
	end)
end

function TalentTreeService.UnlockNode(player: Player, nodeId: any)
	if type(nodeId) ~= "string" then
		return
	end
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local node = TalentTreeConfig.Get(nodeId)
	if not node then
		Remotes.Event("Notify"):FireClient(player, { text = "Invalid talent node", color = "red" })
		return
	end

	profile.unlockedTalents = profile.unlockedTalents or { C_Core = 1 }

	local currentVal = profile.unlockedTalents[nodeId]
	local currentLvl = if type(currentVal) == "number" then currentVal else (if currentVal == true then 1 else 0)

	if currentLvl >= node.maxLevel then
		Remotes.Event("Notify"):FireClient(player, { text = "Node already at MAX level", color = "yellow" })
		return
	end

	-- Check parent prerequisites (must have at least Level 1 of parent)
	if #node.parents > 0 then
		local hasParent = false
		for _, parentId in ipairs(node.parents) do
			local pVal = profile.unlockedTalents[parentId]
			local pLvl = if type(pVal) == "number" then pVal else (if pVal == true then 1 else 0)
			if pLvl > 0 then
				hasParent = true
				break
			end
		end
		if not hasParent then
			Remotes.Event("Notify"):FireClient(player, {
				text = "Prerequisite talent node not unlocked yet",
				color = "red",
			})
			return
		end
	end

	-- Check NPC Quest Gating
	if node.reqSamTier and (profile.samClickTier or 0) < node.reqSamTier then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Requires Click Quester Step %d completed!", node.reqSamTier),
			color = "red",
		})
		return
	end
	if node.reqFrostTier and (profile.frostTier or 0) < node.reqFrostTier then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Requires Case Quester Step %d completed!", node.reqFrostTier),
			color = "red",
		})
		return
	end
	if node.reqGrimTier and (profile.grimTier or 0) < node.reqGrimTier then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Requires Power Quester Step %d completed!", node.reqGrimTier),
			color = "red",
		})
		return
	end
	if node.reqLocation and (profile.currentLocation or 1) < node.reqLocation then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Requires Location %d unlocked!", node.reqLocation),
			color = "red",
		})
		return
	end

	-- Check costs for current level -> next level
	local cost = TalentTreeConfig.GetUpgradeCost(node, currentLvl)

	if node.costType == "talentPoints" then
		local pts = profile.talentPoints or 0
		if pts < cost then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("Need %d Talent Point(s) (have %d)", cost, pts),
				color = "red",
			})
			return
		end
		profile.talentPoints = pts - cost
	else
		local coins = profile.coins or 0
		if coins < cost then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("Need %s coins", require(Shared.Format).Num(cost)),
				color = "red",
			})
			return
		end
		profile.coins = coins - cost
	end

	-- Upgrade node level!
	profile.unlockedTalents[nodeId] = currentLvl + 1

	-- Broadcast notification & update
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("%s Upgraded to Lv.%d! (%s)", node.name, currentLvl + 1, node.desc),
		color = "gold",
	})

	ProfileService.Push(player)
end

return TalentTreeService
