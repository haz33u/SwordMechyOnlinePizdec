--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AuraConfig = require(Shared.Config.AuraConfig)
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

function AuraService.Open(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	if profile.coins < AuraConfig.OPEN_COST then
		Remotes.Event("Notify"):FireClient(player, { text = "Нужно " .. AuraConfig.OPEN_COST .. " монет", color = "red" })
		return
	end
	profile.coins -= AuraConfig.OPEN_COST

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
		-- equip if better power
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
	Remotes.Event("Notify"):FireClient(player, {
		text = "Аура: " .. (def and def.name or auraId) .. " +" .. (def and def.powerPct or 0) .. "% силы",
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

return AuraService
