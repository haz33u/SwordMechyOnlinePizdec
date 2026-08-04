--!strict
--[[
	TALENT TREE SERVICE
	
	Server validation for unlocking nodes on the talent tree.
	Supports both:
	  - Our custom hex TalentTreeConfig nodes (C_Core, C_Dmg_1, etc.)
	  - Original UIUpgradeTree nodes from Noob Incremental (TheStart, PrismGenerationSpeed, etc.)
	
	Applies Coin or TalentPoint costs and updates profile.unlockedTalents.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TalentTreeConfig = require(Shared.Config.TalentTreeConfig)
local NumberFormat = require(Shared.NumberFormat)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

-- Try to load UIUpgradeTree for Noob Incremental nodes
local UIUpgradeTree = nil
pcall(function()
	UIUpgradeTree = require(Shared.Modules.UIUpgradeTree)
end)

local TalentTreeService = {}

function TalentTreeService.Init()
	Remotes.Event("UnlockTalentNode").OnServerEvent:Connect(function(player, nodeId)
		TalentTreeService.UnlockNode(player, nodeId)
	end)
end

-- Resolve a node from either TalentTreeConfig or UIUpgradeTree
local function resolveNode(nodeId: string)
	-- Try our custom config first
	local hexNode = TalentTreeConfig.Get(nodeId)
	if hexNode then
		return {
			source = "hex",
			node = hexNode,
			maxLevel = hexNode.maxLevel,
			name = hexNode.name,
			desc = hexNode.desc,
			costType = hexNode.costType, -- "coins" or "talentPoints"
			getCost = function(lvl)
				return TalentTreeConfig.GetUpgradeCost(hexNode, lvl)
			end,
			getParents = function()
				return hexNode.parents or {}
			end,
		}
	end

	-- Try UIUpgradeTree (Noob Incremental nodes)
	if UIUpgradeTree and UIUpgradeTree.Nodes and UIUpgradeTree.Nodes[nodeId] then
		local uiNode = UIUpgradeTree.Nodes[nodeId]
		return {
			source = "uitree",
			node = uiNode,
			maxLevel = uiNode.maxLevel or 1,
			name = uiNode.title or nodeId,
			desc = uiNode.desc or "",
			costType = "coins", -- All UIUpgradeTree nodes use coins in our game (mapped from Prisms)
			getCost = function(lvl)
				if uiNode.getCost then
					local ok, val = pcall(uiNode.getCost, lvl)
					if ok and type(val) == "number" then
						return math.max(0, math.floor(val))
					end
				end
				return 0
			end,
			getParents = function()
				-- Parents = nodes whose "unlocks" list contains this nodeId
				if UIUpgradeTree.GetRequirements then
					return UIUpgradeTree.GetRequirements(nodeId)
				end
				return {}
			end,
		}
	end

	return nil
end

function TalentTreeService.UnlockNode(player: Player, nodeId: any)
	if type(nodeId) ~= "string" then
		return
	end
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local resolved = resolveNode(nodeId)
	if not resolved then
		Remotes.Event("Notify"):FireClient(player, { text = "Invalid talent node", color = "red" })
		return
	end

	profile.unlockedTalents = profile.unlockedTalents or { C_Core = 1, TheStart = 1 }

	local currentVal = profile.unlockedTalents[nodeId]
	local currentLvl = if type(currentVal) == "number" then currentVal else (if currentVal == true then 1 else 0)

	if currentLvl >= resolved.maxLevel then
		Remotes.Event("Notify"):FireClient(player, { text = "Node already at MAX level", color = "yellow" })
		return
	end

	-- Check parent prerequisites (must have at least Level 1 of a parent)
	local parents = resolved.getParents()
	if #parents > 0 then
		local hasParent = false
		for _, parentId in ipairs(parents) do
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

	-- Hex-specific NPC quest gating (only for hex nodes)
	if resolved.source == "hex" then
		local node = resolved.node
		if node.reqSamTier and (profile.samClickTier or 0) < node.reqSamTier then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("Requires Click Quester Step %d completed!", node.reqSamTier),
				color = "red",
			})
			return
		end
		if node.reqFrostTier and (profile.frostCaseTier or 0) < node.reqFrostTier then
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format("Requires Case Quester Step %d completed!", node.reqFrostTier),
				color = "red",
			})
			return
		end
		if node.reqGrimTier and (profile.grimKillTier or 0) < node.reqGrimTier then
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
	end

	-- Calculate cost
	local cost = resolved.getCost(currentLvl)

	-- Deduct cost
	if resolved.costType == "talentPoints" then
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
				text = string.format("Need %s coins (have %s)", NumberFormat.Num(cost), NumberFormat.Num(coins)),
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
		text = string.format("%s Upgraded to Lv.%d!", resolved.name, currentLvl + 1),
		color = "gold",
	})

	ProfileService.Push(player)
end

return TalentTreeService
