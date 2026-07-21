--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AuraConfig = require(Shared.Config.AuraConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local AuraService = {}

function AuraService.Init()
	Remotes.Event("OpenAuraCase").OnServerEvent:Connect(function(player)
		AuraService.Open(player)
	end)
	Remotes.Event("EquipAura").OnServerEvent:Connect(function(player, auraUid)
		AuraService.Equip(player, auraUid)
	end)
	Remotes.Event("UnequipAura").OnServerEvent:Connect(function(player)
		AuraService.Unequip(player)
	end)
	Remotes.Event("UpgradeAura").OnServerEvent:Connect(function(player, auraUid)
		AuraService.Upgrade(player, auraUid)
	end)
end

local function fireCaseFail(player: Player, reason: string, needKeys: number?, needCoins: number?)
	Remotes.Event("CaseResult"):FireClient(player, {
		kind = "aura",
		success = false,
		reason = reason,
		needKeys = needKeys,
		needCoins = needCoins,
	})
end

function AuraService.Open(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	local keyCost = CaseConfig.AURA_KEY_COST or 1
	local coinCost = CaseConfig.AURA_COIN_COST or AuraConfig.OPEN_COST or 0
	local keys = profile.auraKeys or 0
	local coins = profile.coins or 0

	if keys < keyCost then
		Remotes.Event("Notify"):FireClient(player, {
			text = string.format("Need %d aura key(s) (have %d)", keyCost, keys),
			color = "red",
		})
		fireCaseFail(player, "need_keys", keyCost, coinCost)
		return
	end
	if coinCost > 0 and coins < coinCost then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Need " .. tostring(coinCost) .. " coins",
			color = "red",
		})
		fireCaseFail(player, "need_coins", keyCost, coinCost)
		return
	end

	profile.auraKeys = keys - keyCost
	if coinCost > 0 then
		profile.coins = coins - coinCost
	end

	local auraId = AuraConfig.Roll()
	profile.bannedAuraIds = profile.bannedAuraIds or {}
	for _ = 1, 5 do
		if not profile.bannedAuraIds[auraId] then
			break
		end
		auraId = AuraConfig.Roll()
	end

	local auid = ProfileService.NewUid()
	table.insert(profile.auras, { uid = auid, id = auraId, level = 1 })
	if not profile.equippedAura then
		profile.equippedAura = auid
	else
		local newDef = AuraConfig.Get(auraId)
		local newScore = 0
		if newDef then
			local e = AuraConfig.GetEffective(newDef, 1)
			newScore = e.powerPct + e.damagePct * 0.85
		end
		local curScore = 0
		for _, a in profile.auras do
			if a.uid == profile.equippedAura then
				local d = AuraConfig.Get(AuraConfig.ResolveId(a.id)) or AuraConfig.Get(a.id)
				if d then
					local e = AuraConfig.GetEffective(d, a.level or 1)
					curScore = e.powerPct + e.damagePct * 0.85
				end
			end
		end
		if newScore > curScore then
			profile.equippedAura = auid
		end
	end

	local def = AuraConfig.Get(auraId)
	local name = def and def.name or auraId
	local rarity = def and def.rarity or "Common"
	local eff = def and AuraConfig.GetEffective(def, 1)
		or { powerPct = 0, damagePct = 0, coinPct = 0, critPct = 0, multiCritPct = 0 }

	Remotes.Event("CaseResult"):FireClient(player, {
		kind = "aura",
		success = true,
		id = auraId,
		uid = auid,
		name = name,
		rarity = rarity,
		powerPct = eff.powerPct,
		damagePct = eff.damagePct,
		coinPct = eff.coinPct,
		critPct = eff.critPct,
		multiCritPct = eff.multiCritPct,
		level = 1,
		keysLeft = profile.auraKeys,
	})

	-- Toast is shown by CaseOpening AFTER the result card appears (not here).
	ProfileService.Push(player)
end

function AuraService.Equip(player: Player, auraUid: any)
	local profile = ProfileService.Get(player)
	if not profile or type(auraUid) ~= "string" then
		return
	end
	-- toggle off if already equipped
	if profile.equippedAura == auraUid then
		profile.equippedAura = nil
		ProfileService.Push(player)
		return
	end
	for _, a in profile.auras or {} do
		if a.uid == auraUid then
			profile.equippedAura = auraUid
			ProfileService.Push(player)
			return
		end
	end
end

function AuraService.Unequip(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	profile.equippedAura = nil
	ProfileService.Push(player)
end

function AuraService.GrantKeys(profile: any, amount: number)
	if amount <= 0 then
		return
	end
	profile.auraKeys = (profile.auraKeys or 0) + amount
end

function AuraService.GrantAura(player: Player, profile: any, auraId: string): string?
	local resolved = AuraConfig.ResolveId(auraId)
	if not AuraConfig.Get(resolved) and not AuraConfig.Get(auraId) then
		return nil
	end
	local id = AuraConfig.Get(resolved) and resolved or auraId
	profile.auras = profile.auras or {}
	local auid = ProfileService.NewUid()
	table.insert(profile.auras, { uid = auid, id = id, level = 1 })
	if not profile.equippedAura then
		profile.equippedAura = auid
	end
	return auid
end

--- Spend coins to raise aura level (dump has levels; L1 stats from screenshots).
function AuraService.Upgrade(player: Player, auraUid: any): boolean
	local profile = ProfileService.Get(player)
	if not profile or type(auraUid) ~= "string" then
		return false
	end
	for _, a in profile.auras or {} do
		if a.uid == auraUid then
			local def = AuraConfig.Get(AuraConfig.ResolveId(a.id)) or AuraConfig.Get(a.id)
			if not def then
				Remotes.Event("Notify"):FireClient(player, { text = "Unknown aura", color = "red" })
				return false
			end
			local lv = a.level or 1
			if lv >= AuraConfig.MAX_LEVEL then
				Remotes.Event("Notify"):FireClient(player, { text = "Aura already max level", color = "yellow" })
				return false
			end
			local cost = AuraConfig.UpgradeCost(def, lv)
			if (profile.coins or 0) < cost then
				Remotes.Event("Notify"):FireClient(player, {
					text = string.format("Need %d coins to upgrade", cost),
					color = "red",
				})
				return false
			end
			profile.coins -= cost
			a.level = lv + 1
			local eff = AuraConfig.GetEffective(def, a.level)
			Remotes.Event("Notify"):FireClient(player, {
				text = string.format(
					"%s → Lv%d  (P%.0f%% D%.0f%%)",
					def.name,
					a.level,
					eff.powerPct,
					eff.damagePct
				),
				color = "cyan",
			})
			ProfileService.Push(player)
			return true
		end
	end
	return false
end

return AuraService
