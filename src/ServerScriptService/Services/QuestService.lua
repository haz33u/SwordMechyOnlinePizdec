--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local QuestConfig = require(Shared.Config.QuestConfig)
local ClickConfig = require(Shared.Config.ClickConfig)
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

--- Sam click chain: only active sequential quest; credit scales with tier.
function QuestService.OnClick(profile: any)
	if not profile or not profile.quests then
		return
	end
	local activeId = QuestConfig.GetActiveSamQuestId(profile)
	if not activeId then
		return
	end
	local state = profile.quests[activeId]
	local def = QuestConfig.Get(activeId)
	if not state or not def or state.claimed or def.type ~= "clicks" then
		return
	end
	local credit = ClickConfig.GetSamClickCredit(profile)
	state.progress = math.min(def.amount, (state.progress or 0) + credit)
	if state.progress >= def.amount then
		state.completed = true
	end
end

--- Frost: pet case opens. count = 1, or 3/5 when multi-open gamepass used.
function QuestService.OnCaseOpen(profile: any, kind: string?, count: number?)
	if not profile or not profile.quests then
		return
	end
	local n = math.max(1, math.floor(count or 1))
	-- Only pet cases feed Frost chain (screenshot: pet cases any loc)
	if kind and kind ~= "pet" then
		return
	end
	local activeId = QuestConfig.GetActiveFrostQuestId(profile)
	if not activeId then
		return
	end
	local state = profile.quests[activeId]
	local def = QuestConfig.Get(activeId)
	if not state or not def or state.claimed or def.type ~= "case_open" then
		return
	end
	state.progress = math.min(def.amount, (state.progress or 0) + n)
	if state.progress >= def.amount then
		state.completed = true
	end
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

	-- Sequential chains: only claim active (lowest unclaimed)
	if def.chain == QuestConfig.SAM_CHAIN then
		local active = QuestConfig.GetActiveSamQuestId(profile)
		if active ~= questId then
			Remotes.Event("Notify"):FireClient(player, {
				text = "Finish earlier Sam quests first",
				color = "red",
			})
			return
		end
	end
	if def.chain == QuestConfig.FROST_CHAIN then
		local active = QuestConfig.GetActiveFrostQuestId(profile)
		if active ~= questId then
			Remotes.Event("Notify"):FireClient(player, {
				text = "Finish earlier Frost quests first",
				color = "red",
			})
			return
		end
	end

	state.claimed = true
	local r = def.rewards
	local note = "Quest: " .. def.name .. " ✓"

	if r.coins then
		profile.coins += r.coins
	end
	if r.power then
		profile.lifetimePower += r.power
	end
	if r.powerPct and r.powerPct > 0 then
		profile.questPowerPct = (profile.questPowerPct or 0) + r.powerPct
		note = string.format("Quest: %s ✓  (+%g%% Power permanent)", def.name, r.powerPct)
	end
	if r.luckPct and r.luckPct > 0 then
		profile.questLuckPct = (profile.questLuckPct or 0) + r.luckPct
		note = string.format("Frost ✓  ·  +%g luck (total +%g)", r.luckPct, profile.questLuckPct)
	end
	if r.petSlots and r.petSlots > 0 then
		profile.questPetSlots = (profile.questPetSlots or 0) + r.petSlots
		note = string.format("Frost ✓  ·  +%d pet slot!", r.petSlots)
	end
	if r.weaponId then
		local wuid = ProfileService.NewUid()
		table.insert(profile.weapons, { uid = wuid, id = r.weaponId, level = 1, enchants = {} })
	end
	if r.petKeys then
		profile.petKeys = (profile.petKeys or 0) + r.petKeys
	end
	if r.auraKeys then
		profile.auraKeys = (profile.auraKeys or 0) + r.auraKeys
	end
	if r.unlockLocation then
		ProfileService.UnlockLocation(profile, r.unlockLocation)
	end
	if r.samCpsTier and r.samCpsTier > 0 then
		profile.samClickTier = math.max(profile.samClickTier or 0, r.samCpsTier)
		local cps = ClickConfig.GetSamCpsCap(profile)
		if r.samCpsTier >= 21 then
			note = string.format("Sam Mastery ✓  ·  %d CPS unlocked!", cps)
		else
			note = string.format(
				"Sam (%d/21) ✓  ·  CPS cap %d",
				r.samCpsTier,
				cps
			)
		end
	end
	if r.frostTier and r.frostTier > 0 then
		profile.frostCaseTier = math.max(profile.frostCaseTier or 0, r.frostTier)
		if r.frostTier >= 21 then
			note = "Frost Mastery ✓  ·  case luck complete!"
		elseif not (r.petSlots and r.petSlots > 0) then
			note = string.format(
				"Frost (%d/21) ✓  ·  luck +%g",
				r.frostTier,
				r.luckPct or 0
			)
		end
	end

	PetService.SyncSlots(profile)

	Remotes.Event("Notify"):FireClient(player, {
		text = note,
		color = "cyan",
	})
	ProfileService.Push(player)
end

return QuestService
