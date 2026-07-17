--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local QuestConfig = require(Shared.Config.QuestConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local GameConfig = require(Shared.Config.GameConfig)

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
	ProfileService.AddQuestProgress(profile, "power", nil, 0)
end

function QuestService.OnRebirth(profile: any)
	ProfileService.AddQuestProgress(profile, "rebirth", nil, 1)
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
	if r.petSlot then
		profile.petSlots = math.min(GameConfig.MAX_PET_SLOTS, profile.petSlots + r.petSlot)
	end
	if r.unlockLocation then
		ProfileService.UnlockLocation(profile, r.unlockLocation)
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = "Квест: " .. def.name .. " ✓",
		color = "cyan",
	})
	ProfileService.Push(player)
end

return QuestService
