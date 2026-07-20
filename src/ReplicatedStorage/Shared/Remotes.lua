--!strict
--[[
	Creates / returns RemoteEvents & RemoteFunctions under ReplicatedStorage.Remotes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local FOLDER_NAME = "Remotes"

local function getFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	return folder :: Folder
end

function Remotes.Event(name: string): RemoteEvent
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = folder
	return ev
end

function Remotes.Function(name: string): RemoteFunction
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end
	local fn = Instance.new("RemoteFunction")
	fn.Name = name
	fn.Parent = folder
	return fn
end

function Remotes.InitAll()
	-- client -> server actions
	Remotes.Event("Swing") -- manual or auto click → attack
	Remotes.Event("ToggleAutoClicker")
	Remotes.Event("RequestRebirth")
	Remotes.Event("BuyUpgrade")
	Remotes.Event("EquipWeapon")
	Remotes.Event("SellWeapon")
	Remotes.Event("SellAllWeapons")
	Remotes.Event("EnchantWeapon")
	Remotes.Event("MergeWeapon") -- MMB inventory: 5×L1→L2, 3×L2→L3
	Remotes.Event("OpenPetCase")
	Remotes.Event("OpenAuraCase")
	Remotes.Event("EquipPet")
	Remotes.Event("UnequipPet")
	Remotes.Event("EquipAura")
	Remotes.Event("ClaimQuest")
	Remotes.Event("SetLocation")
	Remotes.Event("StartDungeon")
	Remotes.Event("BanDrop")
	Remotes.Event("FeedPet")
	Remotes.Event("DebugSpawnDummy") -- debug: spawn training dummy
	Remotes.Event("DebugCommand") -- DevTools panel (Studio / GameConfig.DEBUG)
	-- paid unlocks (stub until gamepass): "offhand" | "paidPetSlot"
	Remotes.Event("UnlockPaidFeature")

	-- server -> client
	Remotes.Event("ProfileUpdate")
	Remotes.Event("CombatFx")
	Remotes.Event("Notify")
	Remotes.Event("MobsUpdate") -- full/partial mob list for client visual sync
	-- case open result (spin accuracy — do not poll profile)
	Remotes.Event("CaseResult")
	Remotes.Event("OpenTravel") -- ferryman → open locations panel

	Remotes.Function("GetProfile")
	Remotes.Function("GetPublicProfile") -- inspect online player stats by @username
	Remotes.Function("GetMobCatalog") -- static mob definitions for UI/Studio
	Remotes.Function("GetMobDropInfo") -- Shift+RMB inspect: drop table + stats
end

return Remotes
