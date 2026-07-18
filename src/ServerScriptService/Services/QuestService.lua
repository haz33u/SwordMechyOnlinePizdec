--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local QuestConfig = require(Shared.Config.QuestConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)

local QuestService = {}

function QuestService.Init()
	Remotes.Event("ClaimQuest").OnServerEvent:Connect(function(player, questId)
		QuestService.Claim(player, questId)
	end)
end

function QuestService.OnKill(player: Player, profile: any, mobId: string, isBoss: boolean)
	ProfileService.AddQuestProgress(profile, "kill", mobId, 1)
	if isBoss then
		ProfileService.AddQuestProgress(profile, "boss", mobId, 1)
	end
	-- power quests: sync from lifetimePower (not +0 on kill)
	local power = math.floor(profile.lifetimePower or 0)
	for id, state in profile.quests do
		if not state.completed and not state.claimed then
			local def = QuestConfig.Get(id)
			if def and def.type == "power" then
				state.progress = math.min(def.amount, power)
				if state.progress >= def.amount then
					state.completed = true
				end
			end
		end
	end
end

function QuestService.OnRebirth(profile: any)
	ProfileService.AddQuestProgress(profile, "rebirth", nil, 1)
	PetService.SyncSlots(profile)
end

function QuestService.OnDungeon(profile: any, tierId: string)
	ProfileService.AddQuestProgress(profile, "dungeon", tierId, 1)
	PetService.SyncSlots(profile)
end

function QuestService.Claim(player: Player, questId: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local state = profile.quests[questId]
	local def = QuestConfig.Get(questId)
	if not state or not def or not state.completed or state.claimed then
		return
	end

	state.claimed = true
	local r = def.rewards
	if r.coins then
		profile.coins += r.coins
	end
	if r.power then
		profile.lifetimePower += r.power
	end
	if r.weaponId then
		local wuid = ProfileService.NewUid()
		table.insert(profile.weapons, { uid = wuid, id = r.weaponId, enchants = {} })
	end
	if r.petKeys then
		profile.petKeys = (profile.petKeys or 0) + r.petKeys
	end
	if r.auraKeys then
		profile.auraKeys = (profile.auraKeys or 0) + r.auraKeys
	end
	-- petSlot reward ignored — ProgressConfig.SyncSlots is source of truth
	if r.unlockLocation then
		ProfileService.UnlockLocation(profile, r.unlockLocation)
	end

	PetService.SyncSlots(profile)

	Remotes.Event("Notify"):FireClient(player, {
		text = "Quest: " .. def.name .. " ✓",
		color = "cyan",
	})
	ProfileService.Push(player)
end

return QuestService
