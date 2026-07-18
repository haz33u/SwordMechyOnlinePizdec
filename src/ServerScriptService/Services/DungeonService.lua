--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DungeonConfig = require(Shared.Config.DungeonConfig)
local RelicConfig = require(Shared.Config.RelicConfig)
local GameConfig = require(Shared.Config.GameConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)
local QuestService = require(script.Parent.QuestService)

local DungeonService = {}
DungeonService._gates = { easy = 0, medium = 0, hard = 0 }
DungeonService._runs = {} :: { [number]: any }

function DungeonService.Init()
	Remotes.Event("StartDungeon").OnServerEvent:Connect(function(player, tierId)
		DungeonService.Start(player, tierId)
	end)
end

function DungeonService.Start(player: Player, tierId: string)
	local profile = ProfileService.Get(player)
	local tier = DungeonConfig.Tiers[tierId]
	if not profile or not tier then
		return
	end

	local now = os.clock()
	if now < (DungeonService._gates[tierId] or 0) then
		local left = math.ceil((DungeonService._gates[tierId] :: number) - now)
		Remotes.Event("Notify"):FireClient(player, { text = "Gates in " .. left .. "s", color = "red" })
		return
	end

	if DungeonService._runs[player.UserId] then
		return
	end

	DungeonService._runs[player.UserId] = {
		tierId = tierId,
		endsAt = now + tier.durationSeconds,
	}

	Remotes.Event("Notify"):FireClient(player, {
		text = "Dungeon: " .. tier.name .. " (" .. tier.durationSeconds .. "s)",
		color = "cyan",
	})

	-- skeleton: auto-complete after duration (no map fight yet)
	task.delay(tier.durationSeconds, function()
		DungeonService.Complete(player, tierId)
	end)
end

function DungeonService.Complete(player: Player, tierId: string)
	local profile = ProfileService.Get(player)
	local tier = DungeonConfig.Tiers[tierId]
	local run = DungeonService._runs[player.UserId]
	if not profile or not tier or not run or run.tierId ~= tierId then
		return
	end
	DungeonService._runs[player.UserId] = nil
	DungeonService._gates[tierId] = os.clock() + tier.gateSeconds

	profile.coins += tier.coinReward
	profile.lifetimePower += tier.powerReward
	profile.dungeonStage[tierId] = (profile.dungeonStage[tierId] or 0) + 1

	-- case keys (small guaranteed drip)
	local petKeyGrant = if tierId == "hard" then 2 elseif tierId == "medium" then 1 else 1
	local auraKeyGrant = if tierId == "hard" then 1 else (if tierId == "medium" then 1 else 0)
	profile.petKeys = (profile.petKeys or 0) + petKeyGrant
	if auraKeyGrant > 0 then
		profile.auraKeys = (profile.auraKeys or 0) + auraKeyGrant
	end

	-- relic
	local relicId = RelicConfig.Roll(tier.relicSource)
	local ruid = ProfileService.NewUid()
	table.insert(profile.relics, { uid = ruid, id = relicId, stars = 0 })
	if #profile.equippedRelics < GameConfig.START_RELIC_SLOTS then
		table.insert(profile.equippedRelics, ruid)
	end

	-- dungeon quests + pet slot thresholds (ProgressConfig, not every-N spam)
	QuestService.OnDungeon(profile, tierId)
	local slotsGrew = PetService.SyncSlots(profile)
	if slotsGrew then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("+1 pet slot! (now %d)", profile.petSlots or 0),
			color = "pink",
		})
	end

	local rdef = RelicConfig.Get(relicId)
	local extra = ""
	if petKeyGrant > 0 then
		extra ..= string.format(" +%d pet key", petKeyGrant)
	end
	Remotes.Event("Notify"):FireClient(player, {
		text = string.format(
			"Dungeon ✓ +%d coins, relic: %s%s",
			tier.coinReward,
			rdef and rdef.name or relicId,
			extra
		),
		color = "gold",
	})
	ProfileService.Push(player)
end

return DungeonService
