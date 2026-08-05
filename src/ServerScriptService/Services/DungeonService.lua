--!strict
--[[
	DungeonService — Endless Tower of God Dungeon System.
	- Players step into physical entrance model on base map -> teleported to Tower Arena.
	- Endless floor climbing (Floor 1, 2, 3...). Mobs get progressively stronger.
	- Defeating floor mobs awards Coins, Dust, Keys, BP XP, and Relics.
	- Tracks player's record (profile.dungeons.maxFloor).
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local DungeonConfig = require(Shared.Config.DungeonConfig)
local RelicConfig = require(Shared.Config.RelicConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)
local QuestService = require(script.Parent.QuestService)
local RelicService = require(script.Parent.RelicService)
local WorldService = require(script.Parent.WorldService)
local BattlePassService = require(script.Parent.BattlePassService)

local DungeonService = {}
DungeonService._sessions = {} :: { [number]: any }
DungeonService._portalBound = false

local DUNGEON_SPAWN_CF = CFrame.new(2000, 55, 0)
local DUNGEON_ARENA_CENTER = Vector3.new(2000, 50, 0)
local DUNGEON_MOB_SPAWN_CF = CFrame.new(2000, 53, -25)

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
		floor.Color = Color3.fromRGB(40, 30, 55)
		floor.Parent = dFolder

		-- Decorative Arena Pillars
		for _, side in { Vector3.new(-60, 10, -60), Vector3.new(60, 10, -60), Vector3.new(-60, 10, 60), Vector3.new(60, 10, 60) } do
			local pil = Instance.new("Part")
			pil.Name = "ArenaPillar"
			pil.Size = Vector3.new(8, 24, 8)
			pil.Position = DUNGEON_ARENA_CENTER + side
			pil.Anchored = true
			pil.Material = Enum.Material.Slate
			pil.Color = Color3.fromRGB(30, 20, 40)
			pil.Parent = dFolder

			local torch = Instance.new("PointLight")
			torch.Color = Color3.fromRGB(190, 60, 255)
			torch.Range = 30
			torch.Brightness = 4
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

--- Bind physical portal model in Workspace (ProximityPrompt & TouchPart)
function DungeonService.BindPortalModel(object: Instance)
	local part: BasePart? = nil
	if object:IsA("BasePart") then
		part = object
	elseif object:IsA("Model") then
		part = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
	end
	if not part then return end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Endless Tower"
		prompt.ActionText = "Enter Dungeon [E]"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end

	prompt.Triggered:Connect(function(player)
		DungeonService.EnterTower(player)
	end)

	part.Touched:Connect(function(other)
		local char = other.Parent
		if char and char:FindFirstChildOfClass("Humanoid") then
			local player = Players:GetPlayerFromCharacter(char)
			if player then
				DungeonService.EnterTower(player)
			end
		end
	end)
end

--- Ensure a physical fallback Portal model exists near Central Hub if map has none
function DungeonService.EnsurePhysicalPortal()
	local portalModel = Workspace:FindFirstChild("DungeonPortal", true) or Workspace:FindFirstChild("DungeonEntrance", true) or Workspace:FindFirstChild("Dungeon", true)
	if portalModel then
		DungeonService.BindPortalModel(portalModel)
		return
	end

	-- Create Fallback Portal Model near Hub (X = 28, Z = 22)
	local hubFolder = Workspace:FindFirstChild("NPCs") or Workspace
	local pModel = Instance.new("Model")
	pModel.Name = "DungeonPortal"

	local pFrame = Instance.new("Part")
	pFrame.Name = "Arch"
	pFrame.Size = Vector3.new(8, 12, 2)
	pFrame.CFrame = CFrame.new(28, 6, 22)
	pFrame.Anchored = true
	pFrame.Material = Enum.Material.Cobblestone
	pFrame.Color = Color3.fromRGB(60, 40, 80)
	pFrame.Parent = pModel

	local pGate = Instance.new("Part")
	pGate.Name = "PortalGate"
	pGate.Size = Vector3.new(6, 10, 0.5)
	pGate.CFrame = CFrame.new(28, 6, 22)
	pGate.Anchored = true
	pGate.CanCollide = false
	pGate.Material = Enum.Material.Neon
	pGate.Color = Color3.fromRGB(160, 50, 240)
	pGate.Transparency = 0.3
	pGate.Parent = pModel

	pModel.PrimaryPart = pFrame
	pModel.Parent = hubFolder

	DungeonService.BindPortalModel(pGate)
end

function DungeonService.Init()
	print("[DungeonService] Dungeons disabled per user request")
	return
end

function DungeonService.EnterTower(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then return end

	if DungeonService._sessions[player.UserId] then
		Remotes.Event("Notify"):FireClient(player, { text = "Already inside the Endless Tower!", color = "yellow" })
		return
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local returnCF = hrp.CFrame
	local startingFloor = math.max(1, profile.dungeons and profile.dungeons.currentFloor or 1)

	DungeonService._sessions[player.UserId] = {
		floor = startingFloor,
		returnCFrame = returnCF,
		mob = nil,
	}

	WorldService.TeleportToCFrame(player, DUNGEON_SPAWN_CF)

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("🏰 Entered Endless Tower! Floor %d", startingFloor),
		color = "pink",
	})

	DungeonService.SpawnTowerMob(player, startingFloor)
end

function DungeonService.SpawnTowerMob(player: Player, floor: number)
	local session = DungeonService._sessions[player.UserId]
	if not session then return end

	if session.mob and session.mob.Parent then
		session.mob:Destroy()
		session.mob = nil
	end

	local arena = ensureDungeonArena()

	-- Scaled Stats
	local maxHp = math.floor(120 * (1.32 ^ (floor - 1)))
	local damage = math.floor(10 * (1.15 ^ (floor - 1)))
	local isBoss = (floor % 5 == 0)
	if isBoss then
		maxHp = math.floor(maxHp * 2.2)
		damage = math.floor(damage * 1.5)
	end

	local mobModel = Instance.new("Model")
	mobModel.Name = if isBoss then string.format("Floor %d BOSS Guardian", floor) else string.format("Floor %d Guardian", floor)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = if isBoss then Vector3.new(5, 10, 5) else Vector3.new(3, 7, 3)
	root.CFrame = DUNGEON_MOB_SPAWN_CF
	root.Anchored = true
	root.CanCollide = true
	root.Material = Enum.Material.SmoothPlastic
	root.Color = if isBoss then Color3.fromRGB(220, 40, 50) else Color3.fromRGB(150, 40, 200)
	root.Parent = mobModel

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 32
	cd.Parent = root

	local curHp = maxHp
	root:SetAttribute("Health", curHp)
	root:SetAttribute("MaxHealth", maxHp)
	root:SetAttribute("MobId", "TowerGuardian")

	cd.MouseClick:Connect(function(attacker)
		if attacker == player then
			Remotes.Event("Swing"):FireClient(player)
		end
	end)

	mobModel.PrimaryPart = root
	mobModel.Parent = arena
	session.mob = mobModel
	session.currentHp = curHp
	session.maxHp = maxHp
	session.isBoss = isBoss
	session.isClearing = false
end

function DungeonService.DamageTowerMob(player: Player, dmg: number)
	local session = DungeonService._sessions[player.UserId]
	if not session or not session.mob or session.isClearing then return end

	session.currentHp = math.max(0, session.currentHp - dmg)
	local root = session.mob.PrimaryPart
	if root then
		root:SetAttribute("Health", session.currentHp)
	end

	if session.currentHp <= 0 then
		session.isClearing = true
		DungeonService.OnFloorCleared(player, session.floor)
	end
end

function DungeonService.OnFloorCleared(player: Player, floor: number)
	local profile = ProfileService.Get(player)
	local session = DungeonService._sessions[player.UserId]
	if not profile or not session then return end

	local coinsGained = math.floor(80 * (1.25 ^ (floor - 1)))
	local powerGained = math.floor(35 * (1.22 ^ (floor - 1)))

	profile.coins += coinsGained
	profile.lifetimePower += powerGained

	-- BP XP
	BattlePassService.AddXP(player, 15 + floor * 2)

	-- Dust milestone
	local dustGrant = 0
	if floor % 5 == 0 then
		dustGrant = math.floor(floor / 5) * 2
		profile.enchantDust = (profile.enchantDust or 0) + dustGrant
	end

	-- Relic milestone — source scales with tower depth
	local relicGrantedName = nil
	local relicSource = nil
	if floor % 10 == 0 then
		local source = if floor <= 20 then "easy" elseif floor <= 50 then "medium" else "hard"
		relicSource = source
		local relicId = RelicConfig.ResolveId(RelicConfig.Roll(source))
		local ruid = ProfileService.NewUid()
		table.insert(profile.relics, { uid = ruid, id = relicId, stars = 0, source = source })
		RelicService.TryAutoEquip(profile, ruid)
		local rdef = RelicConfig.Get(relicId)
		relicGrantedName = if rdef then rdef.name else relicId
	end

	-- Record Max Floor
	profile.dungeons = profile.dungeons or { maxFloor = 0, currentFloor = 0 }
	profile.dungeons.currentFloor = floor + 1
	if floor > (profile.dungeons.maxFloor or 0) then
		profile.dungeons.maxFloor = floor
	end

	local extraMsg = ""
	if dustGrant > 0 then extraMsg ..= string.format(" +%d Dust", dustGrant) end
	if relicGrantedName then
		local srcLabel = if relicSource == "easy" then "Easy" elseif relicSource == "medium" then "Medium" else "Hard"
		extraMsg ..= string.format(" +Relic: %s (%s Dungeon)", relicGrantedName, srcLabel)
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("✓ Floor %d Cleared! +%d coins%s", floor, coinsGained, extraMsg),
		color = "gold",
	})
	ProfileService.Push(player)

	session.floor = floor + 1
	task.delay(1.5, function()
		if DungeonService._sessions[player.UserId] == session then
			DungeonService.SpawnTowerMob(player, session.floor)
		end
	end)
end

function DungeonService.ExitTower(player: Player)
	local profile = ProfileService.Get(player)
	local session = DungeonService._sessions[player.UserId]
	if not session then return end

	if session.mob then
		session.mob:Destroy()
	end
	DungeonService._sessions[player.UserId] = nil

	if session.returnCFrame then
		WorldService.TeleportToCFrame(player, session.returnCFrame)
	else
		WorldService.TeleportToLocation(player, profile and profile.currentLocation or 1)
	end

	Remotes.Event("Notify"):FireClient(player, { text = "Exited Tower of God. Returned to base.", color = "gold" })
end

return DungeonService
