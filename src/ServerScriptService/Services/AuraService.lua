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
		local curPower = 0
		for _, a in profile.auras do
			if a.uid == profile.equippedAura then
				local d = AuraConfig.Get(a.id)
				if d then
					curPower = d.powerPct
				end
			end
		end
		if newDef and newDef.powerPct > curPower then
			profile.equippedAura = auid
		end
	end

	local def = AuraConfig.Get(auraId)
	local name = def and def.name or auraId
	local rarity = def and def.rarity or "Common"
	local powerPct = def and def.powerPct or 0
	local damagePct = def and def.damagePct or 0
	local coinPct = def and def.coinPct or 0

	Remotes.Event("CaseResult"):FireClient(player, {
		kind = "aura",
		success = true,
		id = auraId,
		uid = auid,
		name = name,
		rarity = rarity,
		powerPct = powerPct,
		damagePct = damagePct,
		coinPct = coinPct,
		keysLeft = profile.auraKeys,
	})

	Remotes.Event("Notify"):FireClient(player, {
		text = string.format("Aura: %s +%d%% power  (keys left: %d)", name, powerPct, profile.auraKeys or 0),
		color = "blue",
	})
	ProfileService.Push(player)
end

function AuraService.Equip(player: Player, auraUid: string)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	for _, a in profile.auras do
		if a.uid == auraUid then
			profile.equippedAura = auraUid
			ProfileService.Push(player)
			return
		end
	end
end

function AuraService.GrantKeys(profile: any, amount: number)
	if amount <= 0 then
		return
	end
	profile.auraKeys = (profile.auraKeys or 0) + amount
end

return AuraService
