--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local LootService = {}

function LootService.TryWeaponDrop(player: Player, profile: any, mobDef: any)
	local luck = Formulas.GetLuck(profile)
	local chance = mobDef.weaponDropChance * (1 + luck)
	if math.random() > chance then
		return
	end

	local pool = {}
	for _, wid in mobDef.weaponPool do
		if not profile.bannedWeaponIds[wid] then
			table.insert(pool, wid)
		end
	end
	if #pool == 0 then
		return
	end

	local weaponId = pool[math.random(1, #pool)]
	local def = WeaponConfig.Get(weaponId)
	if not def then
		return
	end

	local wuid = ProfileService.NewUid()
	table.insert(profile.weapons, {
		uid = wuid,
		id = weaponId,
		enchants = {},
	})

	-- auto equip if better
	local cur = nil
	for _, w in profile.weapons do
		if w.uid == profile.equippedMain then
			cur = w
			break
		end
	end
	local curMult = 1
	if cur then
		local cdef = WeaponConfig.Get(cur.id)
		if cdef then
			curMult = cdef.powerMult
		end
	end
	if def.powerMult > curMult then
		profile.equippedMain = wuid
	end

	Remotes.Event("Notify"):FireClient(player, {
		text = "Дроп: " .. def.name .. " (" .. def.rarity .. ")",
		color = "gold",
	})
end

function LootService.TryPetKey(_player: Player, _profile: any)
	-- skeleton: reserved for key drops
end

return LootService
