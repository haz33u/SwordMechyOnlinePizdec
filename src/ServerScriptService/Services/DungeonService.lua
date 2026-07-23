--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Workspace = game:GetService("Workspace")

local DungeonConfig = require(Shared.Config.DungeonConfig)
local RelicConfig = require(Shared.Config.RelicConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)
local QuestService = require(script.Parent.QuestService)
local RelicService = require(script.Parent.RelicService)
local WorldService = require(script.Parent.WorldService)

local DungeonService = {}
DungeonService._gates = { easy = 0, medium = 0, hard = 0 }
DungeonService._runs = {} :: { [number]: any }

local DUNGEON_SPAWN_CF = CFrame.new(2000, 55, 0)
local DUNGEON_ARENA_CENTER = Vector3.new(2000, 50, 0)

local function ensureDungeonArena(): Folder
	local worldFolder = Workspace:FindFirstChild("World")
	if not worldFolder then
		worldFolder = Instance.new("Folder")
		worldFolder.Name = "World"
		worldFolder.Parent = Workspace
	end
	local dFolder = worldFolder:FindFirstChild("Dungeons")
	if not dFolder then
		dFolder = Instance.new("Folder")
		dFolder.Name = "Dungeons"
		dFolder.Parent = worldFolder

		-- Arena Platform
		local floor = Instance.new("Part")
		floor.Name = "DungeonFloor"
		floor.Size = Vector3.new(140, 4, 140)
		floor.Position = DUNGEON_ARENA_CENTER
		floor.Anchored = true
		floor.Material = Enum.Material.Cobblestone
		floor.Color = Color3.fromRGB(50, 40, 60)
		floor.Parent = dFolder

		-- Decorative Arena Pillars
		for _, side in { Vector3.new(-60, 10, -60), Vector3.new(60, 10, -60), Vector3.new(-60, 10, 60), Vector3.new(60, 10, 60) } do
			local pil = Instance.new("Part")
			pil.Name = "ArenaPillar"
			pil.Size = Vector3.new(6, 20, 6)
			pil.Position = DUNGEON_ARENA_CENTER + side
			pil.Anchored = true
			pil.Material = Enum.Material.Slate
			pil.Color = Color3.fromRGB(35, 25, 45)
			pil.Parent = dFolder

			local torch = Instance.new("PointLight")
			torch.Color = Color3.fromRGB(180, 50, 255)
			torch.Range = 24
			torch.Brightness = 3
			torch.Parent = pil
		end

		-- Arena Spawn Point
		local sp = Instance.new("SpawnLocation")
		sp.Name = "DungeonSpawn"
		sp.Size = Vector3.new(14, 1, 14)
		sp.CFrame = DUNGEON_SPAWN_CF
		sp.Anchored = true
		sp.CanCollide = false
		sp.Transparency = 0.5
		sp.Material = Enum.Material.Neon
		sp.Color = Color3.fromRGB(160, 40, 220)
		sp.Parent = dFolder
	end
	return dFolder
end

function DungeonService.Init()
	ensureDungeonArena()

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
		Remotes.Event("Notify"):FireClient(player, { text = "Dungeon portal ready in " .. left .. "s", color = "red" })
		return
	end

	if DungeonService._runs[player.UserId] then
		Remotes.Event("Notify"):FireClient(player, { text = "Already in a Dungeon!", color = "yellow" })
		return
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local returnCF = hrp.CFrame

	DungeonService._runs[player.UserId] = {
		tierId = tierId,
		endsAt = now + tier.durationSeconds,
		returnCFrame = returnCF,
	}

	-- Teleport Player to Dungeon Arena
	WorldService.TeleportToCFrame(player, DUNGEON_SPAWN_CF)

	Remotes.Event("Notify"):FireClient(player, {
		text = "Entered " .. tier.name .. "! (" .. tier.durationSeconds .. "s)",
		color = "cyan",
	})

	-- Auto-complete or return after duration
	task.delay(tier.durationSeconds, function()
		if DungeonService._runs[player.UserId] then
			DungeonService.Complete(player, tierId)
		end
	end)
end

function DungeonService.Complete(player: Player, tierId: string)
	local profile = ProfileService.Get(player)
	local tier = DungeonConfig.Tiers[tierId]
	local run = DungeonService._runs[player.UserId]
	if not profile or not tier or not run then
		return
	end

	-- Teleport player back to main map spawn / return location
	if run.returnCFrame then
		WorldService.TeleportToCFrame(player, run.returnCFrame)
	else
		WorldService.TeleportToLocation(player, profile.currentLocation or 1)
	end

	DungeonService._runs[player.UserId] = nil
	DungeonService._gates[tierId] = os.clock() + tier.gateSeconds

	profile.coins += tier.coinReward
	profile.lifetimePower += tier.powerReward
	profile.dungeonStage[tierId] = (profile.dungeonStage[tierId] or 0) + 1

	-- Case keys
	local petKeyGrant = if tierId == "hard" then 2 elseif tierId == "medium" then 1 else 1
	local auraKeyGrant = if tierId == "hard" then 1 else (if tierId == "medium" then 1 else 0)
	profile.petKeys = (profile.petKeys or 0) + petKeyGrant
	if auraKeyGrant > 0 then
		profile.auraKeys = (profile.auraKeys or 0) + auraKeyGrant
	end

	-- Relic reward
	local relicId = RelicConfig.ResolveId(RelicConfig.Roll(tier.relicSource))
	local ruid = ProfileService.NewUid()
	table.insert(profile.relics, { uid = ruid, id = relicId, stars = 0 })
	RelicService.TryAutoEquip(profile, ruid)

	-- Quests & Pet slot sync
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
			"Dungeon Cleared ✓ +%d coins, relic: %s%s",
			tier.coinReward,
			rdef and rdef.name or relicId,
			extra
		),
		color = "gold",
	})
	ProfileService.Push(player)
end

return DungeonService
