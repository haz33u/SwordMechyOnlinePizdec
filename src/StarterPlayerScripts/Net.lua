--!strict
--[[ Thin remotes wrapper — UI only fires listed backend remotes. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local function folder(): Folder
	return ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Net.Event(name: string): RemoteEvent
	return folder():WaitForChild(name) :: RemoteEvent
end

function Net.Fn(name: string): RemoteFunction
	return folder():WaitForChild(name) :: RemoteFunction
end

function Net.Swing(source: string?)
	Net.Event("Swing"):FireServer(nil, source or "manual")
end

function Net.ToggleAuto()
	Net.Event("ToggleAutoClicker"):FireServer()
end

function Net.Rebirth()
	Net.Event("RequestRebirth"):FireServer()
end

function Net.BuyUpgrade(id: string)
	Net.Event("BuyUpgrade"):FireServer(id)
end

function Net.EquipWeapon(uid: string, slot: string?)
	Net.Event("EquipWeapon"):FireServer(uid, slot or "main")
end

function Net.SellWeapon(uid: string)
	Net.Event("SellWeapon"):FireServer(uid)
end

function Net.SellAllWeapons()
	Net.Event("SellAllWeapons"):FireServer()
end

function Net.EnchantWeapon(uid: string)
	Net.Event("EnchantWeapon"):FireServer(uid)
end

function Net.MergeWeapon(uid: string)
	Net.Event("MergeWeapon"):FireServer(uid)
end

function Net.OpenPetCase()
	Net.Event("OpenPetCase"):FireServer()
end

function Net.OpenAuraCase()
	Net.Event("OpenAuraCase"):FireServer()
end

function Net.EquipPet(uid: string)
	Net.Event("EquipPet"):FireServer(uid)
end

function Net.UnequipPet(uid: string)
	Net.Event("UnequipPet"):FireServer(uid)
end

function Net.FeedPet(uid: string)
	Net.Event("FeedPet"):FireServer(uid)
end

function Net.EquipAura(uid: string)
	Net.Event("EquipAura"):FireServer(uid)
end

function Net.ClaimQuest(id: string)
	Net.Event("ClaimQuest"):FireServer(id)
end

function Net.SetLocation(id: number)
	Net.Event("SetLocation"):FireServer(id)
end

function Net.StartDungeon(tier: string)
	Net.Event("StartDungeon"):FireServer(tier)
end

function Net.BanDrop(kind: string, id: string, banned: boolean)
	Net.Event("BanDrop"):FireServer(kind, id, banned)
end

--- featureId: "offhand" | "paidPetSlot" | ... (DEBUG free if ProgressConfig.DEBUG_FREE_PAID)
function Net.UnlockPaidFeature(featureId: string)
	Net.Event("UnlockPaidFeature"):FireServer(featureId)
end

function Net.PromptGamePass(gamePassId: number)
	local MarketplaceService = game:GetService("MarketplaceService")
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	if lp and type(gamePassId) == "number" then
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(lp, gamePassId)
		end)
	end
end

function Net.GetProfile(): any
	return Net.Fn("GetProfile"):InvokeServer()
end

--- @username of online player → public stats for inventory Profile tab
function Net.GetPublicProfile(username: string): any
	return Net.Fn("GetPublicProfile"):InvokeServer(username)
end

return Net
