--!strict
--[[
	In-memory profiles + optional DataStore (skeleton uses memory if DS fails).
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local LocationConfig = require(Shared.Config.LocationConfig)
local QuestConfig = require(Shared.Config.QuestConfig)
local Remotes = require(Shared.Remotes)
local Formulas = require(Shared.Formulas)

local ProfileService = {}
ProfileService._profiles = {} :: { [number]: any }
ProfileService._store = nil :: DataStore?

local function uid(): string
	return HttpService:GenerateGUID(false)
end

local function defaultProfile()
	local starterUid = uid()
	local quests = {}
	for id, _ in QuestConfig.Quests do
		quests[id] = { id = id, progress = 0, completed = false, claimed = false }
	end

	return {
		coins = 0,
		enchantDust = 0, -- boss drop → weapon enchant
		petKeys = 0, -- OpenPetCase
		auraKeys = 0, -- OpenAuraCase
		questPowerPct = 0, -- permanent +% power from main quests
		lifetimePower = 0,
		lifetimeDamage = 0,
		totalClicks = 0, -- CORE metric: every successful attack
		rebirthLevel = 0,
		rebirthMult = 1,
		autoClicker = false, -- needs purchased auto
		autoClickerUnlocked = false,
		purchasedAutoClicker = false, -- donat later; without it CPS capped (Loc1=4, max=20)
		upgradeLevels = {
			RunSpeed = 0,
			Backpack = 0,
			Power = 0,
			ClickSpeed = 0,
			CritChance = 0,
			MultiCrit = 0,
			Luck = 0,
		},
		weapons = {
			{
				uid = starterUid,
				id = WeaponConfig.STARTER_WEAPON,
				level = 1,
				enchants = {},
			},
		},
		equippedMain = starterUid,
		equippedOffhand = nil,
		pets = {},
		petTeam = {},
		petSlots = ProgressConfig.START_PET_SLOTS,
		-- paid unlocks (offhand + extra pet slot)
		unlocks = {
			offhand = false,
			paidPetSlot = false,
		},
		auras = {},
		equippedAura = nil,
		relics = {},
		equippedRelics = {},
		locationsUnlocked = { 1 },
		currentLocation = 1,
		quests = quests,
		dungeonStage = { easy = 0, medium = 0, hard = 0 },
		bannedWeaponIds = {},
		bannedPetIds = {},
		bannedAuraIds = {},
	}
end

function ProfileService.Init()
	pcall(function()
		ProfileService._store = DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)
	end)

	Players.PlayerAdded:Connect(function(player)
		ProfileService.Load(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		ProfileService.Save(player)
		ProfileService._profiles[player.UserId] = nil
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(ProfileService.Load, p)
	end

	task.spawn(function()
		while true do
			task.wait(GameConfig.AUTOSAVE_SECONDS)
			for _, player in Players:GetPlayers() do
				ProfileService.Save(player)
			end
		end
	end)
end

function ProfileService.Load(player: Player)
	local data = defaultProfile()
	if ProfileService._store then
		local ok, result = pcall(function()
			return ProfileService._store:GetAsync("p_" .. player.UserId)
		end)
		if ok and typeof(result) == "table" then
			for k, v in result do
				data[k] = v
			end
		end
	end

	-- migrate missing key fields (old DataStore rows)
	if data.petKeys == nil then
		data.petKeys = 0
	end
	if data.auraKeys == nil then
		data.auraKeys = 0
	end
	if data.enchantDust == nil then
		data.enchantDust = 0
	end
	if data.questPowerPct == nil then
		data.questPowerPct = 0
	end
	if data.purchasedAutoClicker == nil then
		data.purchasedAutoClicker = false
	end
	if type(data.unlocks) ~= "table" then
		data.unlocks = { offhand = false, paidPetSlot = false }
	else
		if data.unlocks.offhand == nil then
			data.unlocks.offhand = false
		end
		if data.unlocks.paidPetSlot == nil then
			data.unlocks.paidPetSlot = false
		end
		if data.unlocks.autoClicker == nil then
			data.unlocks.autoClicker = false
		end
	end
	-- migrate: gamepass unlocks → purchase flags (do NOT wipe owned auto)
	if data.unlocks.autoClicker == true or data.autoClickerUnlocked == true then
		data.purchasedAutoClicker = true
		data.autoClickerUnlocked = true
		data.unlocks.autoClicker = true
	elseif data.purchasedAutoClicker ~= true then
		-- old free-auto saves without purchase
		data.autoClickerUnlocked = false
		if data.autoClicker == true then
			data.autoClicker = false
		end
	end
	if type(data.dungeonStage) ~= "table" then
		data.dungeonStage = { easy = 0, medium = 0, hard = 0 }
	end
	-- merge new quests into old saves
	if type(data.quests) ~= "table" then
		data.quests = {}
	end
	for id, _ in QuestConfig.Quests do
		if data.quests[id] == nil then
			data.quests[id] = { id = id, progress = 0, completed = false, claimed = false }
		end
	end
	-- strip offhand if not paid-unlocked
	if not ProgressConfig.IsOffhandUnlocked(data) then
		data.equippedOffhand = nil
	end
	-- pet slots always derived from progress (migration from old START=1)
	local PetService = require(script.Parent.PetService)
	PetService.SyncSlots(data)

	-- Weapons: rename legacy W1_U2 / W1_C1 codes → dump slugs; drop unknown
	do
		local kept = {}
		local mainUid = data.equippedMain
		local offUid = data.equippedOffhand
		for _, w in ipairs(data.weapons or {}) do
			if type(w) == "table" and type(w.id) == "string" then
				local resolved = WeaponConfig.ResolveId(w.id)
				if WeaponConfig.Get(resolved) then
					w.id = resolved
					if type(w.level) ~= "number" then
						w.level = 1
					end
					table.insert(kept, w)
				end
			end
		end
		if #kept == 0 then
			local starterUid = uid()
			table.insert(kept, {
				uid = starterUid,
				id = WeaponConfig.STARTER_WEAPON,
				level = 1,
				enchants = {},
			})
			data.equippedMain = starterUid
			data.equippedOffhand = nil
		else
			data.weapons = kept
			local function stillOwns(uidVal: any): boolean
				if type(uidVal) ~= "string" then
					return false
				end
				for _, w in kept do
					if w.uid == uidVal then
						return true
					end
				end
				return false
			end
			if not stillOwns(mainUid) then
				data.equippedMain = kept[1].uid
			end
			if offUid and not stillOwns(offUid) then
				data.equippedOffhand = nil
			end
		end
		data.weapons = kept
		-- banned list: remap keys
		if type(data.bannedWeaponIds) == "table" then
			local nb = {}
			for id, banned in data.bannedWeaponIds do
				if banned then
					local r = WeaponConfig.ResolveId(id)
					if WeaponConfig.Get(r) then
						nb[r] = true
					end
				end
			end
			data.bannedWeaponIds = nb
		end
	end

	if GameConfig.GIVE_STARTER_KIT and data.coins == 0 and data.lifetimePower == 0 then
		data.coins = GameConfig.STARTER_COINS or 1000
		-- only brand-new profiles get starter keys
		if (data.petKeys or 0) == 0 and #(data.pets or {}) == 0 then
			data.petKeys = CaseConfig.STARTER_PET_KEYS or 5
		end
		if (data.auraKeys or 0) == 0 and #(data.auras or {}) == 0 then
			data.auraKeys = CaseConfig.STARTER_AURA_KEYS or 2
		end
	end

	ProfileService._profiles[player.UserId] = data
	ProfileService.Push(player)
	ProfileService.ApplyWalkSpeed(player)
end

function ProfileService.Save(player: Player)
	local profile = ProfileService._profiles[player.UserId]
	if not profile or not ProfileService._store then
		return
	end
	pcall(function()
		ProfileService._store:SetAsync("p_" .. player.UserId, profile)
	end)
end

function ProfileService.Get(player: Player): any?
	return ProfileService._profiles[player.UserId]
end

function ProfileService.Push(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local snap = Formulas.Snapshot(profile)
	Remotes.Event("ProfileUpdate"):FireClient(player, {
		profile = profile,
		stats = snap,
	})
end

function ProfileService.ApplyWalkSpeed(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = Formulas.GetWalkSpeed(profile)
	end
end

function ProfileService.NewUid(): string
	return uid()
end

function ProfileService.IsLocationUnlocked(profile: any, locId: number): boolean
	for _, id in profile.locationsUnlocked do
		if id == locId then
			return true
		end
	end
	return false
end

function ProfileService.UnlockLocation(profile: any, locId: number)
	if not ProfileService.IsLocationUnlocked(profile, locId) then
		table.insert(profile.locationsUnlocked, locId)
	end
end

function ProfileService.AddQuestProgress(profile: any, questType: string, targetId: string?, amount: number)
	for id, state in profile.quests do
		if not state.completed and not state.claimed then
			local def = QuestConfig.Get(id)
			if def and def.type == questType then
				local targetOk = true
				if def.targetId and targetId and def.targetId ~= targetId and def.targetId ~= "any" then
					targetOk = false
				end
				if targetOk then
					state.progress = math.min(def.amount, state.progress + amount)
					if state.progress >= def.amount then
						state.completed = true
					end
				end
			end
		end
	end

	-- power quests
	if questType == "power" then
		for id, state in profile.quests do
			local def = QuestConfig.Get(id)
			if def and def.type == "power" and not state.claimed then
				state.progress = math.min(def.amount, profile.lifetimePower)
				if state.progress >= def.amount then
					state.completed = true
				end
			end
		end
	end
end

return ProfileService
