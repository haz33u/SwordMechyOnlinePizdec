--!strict
--[[
	DEBUG-only cheats for Studio / GameConfig.DEBUG.
	Client DevTools panel → DebugCommand remote.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local WeaponConfig = require(Shared.Config.WeaponConfig)
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local Remotes = require(Shared.Remotes)
local ProfileService = require(script.Parent.ProfileService)
local LootService = require(script.Parent.LootService)
local CombatService = require(script.Parent.CombatService)
local PetService = require(script.Parent.PetService)
local AuraService = require(script.Parent.AuraService)
local AnomalyService = require(script.Parent.AnomalyService)

local DebugService = {}

local function allowed(player: Player): boolean
	if GameConfig.DEBUG == true then
		return true
	end
	if RunService:IsStudio() then
		return true
	end
	return false
end

local function notify(player: Player, text: string, color: string?)
	Remotes.Event("Notify"):FireClient(player, { text = text, color = color or "gold" })
end

function DebugService.Init()
	Remotes.Event("DebugCommand").OnServerEvent:Connect(function(player, action, payload)
		if not allowed(player) then
			notify(player, "Dev tools disabled", "red")
			return
		end
		if type(action) ~= "string" then
			return
		end
		DebugService.Run(player, action, payload)
	end)
end

function DebugService.Run(player: Player, action: string, payload: any)
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end

	if action == "resetData" or action == "resetRebirths" then
		profile.rebirthLevel = 0
		profile.rebirthMult = 1
		profile.lifetimePower = 0
		profile.coins = 0
		profile.lifetimeDamage = 0
		ProfileService.Push(player)
		notify(player, "Profile & Rebirths reset to 0!", "gold")
		return
	end

	if action == "giveCoins" then
		local n = 100_000
		if type(payload) == "number" then
			n = math.clamp(math.floor(payload), 1, 1e12)
		end
		profile.coins = (profile.coins or 0) + n
		notify(player, string.format("Dev: +%s coins", tostring(n)), "green")
		ProfileService.Push(player)
		return
	end

	if action == "giveDust" then
		local n = 50
		if type(payload) == "number" then
			n = math.clamp(math.floor(payload), 1, 1e6)
		end
		profile.enchantDust = (profile.enchantDust or 0) + n
		notify(player, string.format("Dev: +%d enchant dust", n), "green")
		ProfileService.Push(player)
		return
	end

	if action == "giveKeys" then
		profile.petKeys = (profile.petKeys or 0) + 10
		profile.auraKeys = (profile.auraKeys or 0) + 10
		notify(player, "Dev: +10 pet keys, +10 aura keys", "green")
		ProfileService.Push(player)
		return
	end

	if action == "giveLoc1Weapons" then
		local granted = 0
		for id, def in WeaponConfig.Weapons do
			if def.location == 1 then
				LootService.GrantWeapon(player, profile, def)
				granted += 1
			end
		end
		notify(player, string.format("Dev: granted Loc1 weapons (%d tries)", granted), "green")
		ProfileService.Push(player)
		return
	end

	if action == "giveLoc1Pets" then
		local n = 0
		for id, def in PetConfig.Pets do
			if def.location == 1 and def.casePool == "loc1_500" then
				if PetService.GrantPet(player, profile, id) then
					n += 1
				end
			end
		end
		notify(player, string.format("Dev: Loc1 pets granted (%d)", n), "green")
		ProfileService.Push(player)
		return
	end

	if action == "givePet" then
		local id = if type(payload) == "string" then payload else "P1_L1"
		local uid = PetService.GrantPet(player, profile, id)
		if uid then
			local def = PetConfig.Get(id)
			notify(player, "Dev: pet " .. ((def and def.name) or id), "green")
		else
			notify(player, "Dev: pet grant failed (bag full?)", "red")
		end
		ProfileService.Push(player)
		return
	end

	if action == "giveAllAuras" then
		local n = 0
		for id in AuraConfig.Auras do
			if AuraService.GrantAura(player, profile, id) then
				n += 1
			end
		end
		notify(player, string.format("Dev: granted %d auras", n), "green")
		ProfileService.Push(player)
		return
	end

	if action == "giveAura" then
		local id = if type(payload) == "string" then payload else "A_E1"
		local uid = AuraService.GrantAura(player, profile, id)
		if uid then
			local def = AuraConfig.Get(id)
			notify(player, "Dev: aura " .. ((def and def.name) or id), "green")
		else
			notify(player, "Dev: aura grant failed", "red")
		end
		ProfileService.Push(player)
		return
	end

	if action == "forceAnomaly" then
		local id = if type(payload) == "string" then payload else nil
		if AnomalyService.Force(id, 120) then
			notify(player, "Dev: anomaly forced " .. tostring(id or "random"), "gold")
		else
			notify(player, "Dev: forceAnomaly failed", "red")
		end
		return
	end

	if action == "giveWeapon" then
		local id = if type(payload) == "string" then payload else nil
		if not id then
			return
		end
		local def = WeaponConfig.Get(id)
		if not def then
			notify(player, "Dev: unknown weapon " .. tostring(id), "red")
			return
		end
		LootService.GrantWeapon(player, profile, def)
		notify(player, "Dev: gave " .. (def.name or id), "green")
		ProfileService.Push(player)
		return
	end

	if action == "unlockOffhand" then
		profile.unlocks = profile.unlocks or {}
		profile.unlocks.offhand = true
		notify(player, "Dev: Offhand unlocked", "green")
		ProfileService.Push(player)
		return
	end

	if action == "unlockAuto" then
		profile.purchasedAutoClicker = true
		notify(player, "Dev: Auto-clicker unlocked", "green")
		ProfileService.Push(player)
		return
	end

	if action == "spawnDummy" then
		CombatService.DebugSpawnDummy(player)
		notify(player, "Dev: dummy spawned", "cyan")
		return
	end

	if action == "setLocation" then
		local loc = if type(payload) == "number" then math.floor(payload) else 1
		loc = math.clamp(loc, 1, 4)
		profile.currentLocation = loc
		local WorldService = require(script.Parent.WorldService)
		pcall(function()
			WorldService.TeleportToLocation(player, loc)
		end)
		notify(player, "Dev: location " .. tostring(loc), "cyan")
		ProfileService.Push(player)
		return
	end

	if action == "fullHealClear" then
		-- no player HP; just push profile
		notify(player, "Dev: profile pushed", "cyan")
		ProfileService.Push(player)
		return
	end

	notify(player, "Dev: unknown action " .. action, "red")
end

return DebugService
