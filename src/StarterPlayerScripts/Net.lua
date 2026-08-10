--!strict
--[[ Thin remotes wrapper — UI only fires listed backend remotes. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local function folder(): Folder
	return ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Net.Event(name: string): RemoteEvent
	local f = folder()
	local existing = f:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	-- Timeout so a half-booted server cannot hang the entire client UI forever
	local ev = f:WaitForChild(name, 20)
	if not ev or not ev:IsA("RemoteEvent") then
		error(string.format("[Net] RemoteEvent '%s' missing after 20s (server failed to Init remotes?)", name))
	end
	return ev :: RemoteEvent
end

function Net.Fn(name: string): RemoteFunction
	local f = folder()
	local existing = f:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end
	local fn = f:WaitForChild(name, 20)
	if not fn or not fn:IsA("RemoteFunction") then
		error(string.format("[Net] RemoteFunction '%s' missing after 20s (server failed to Init remotes?)", name))
	end
	return fn :: RemoteFunction
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

function Net.UnlockTalentNode(nodeId: string)
	Net.Event("UnlockTalentNode"):FireServer(nodeId)
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

function Net.RollEnchant(weaponUid: string)
	Net.Event("RollEnchant"):FireServer(weaponUid)
end

function Net.ApplyEnchant(weaponUid: string)
	Net.Event("ApplyEnchant"):FireServer(weaponUid)
end

function Net.TransferEnchant(fromUid: string, toUid: string, enchantIndex: number)
	Net.Event("TransferEnchant"):FireServer(fromUid, toUid, enchantIndex)
end

function Net.UsePotion(potionId: string)
	Net.Event("UsePotion"):FireServer(potionId)
end

function Net.ExitDungeon()
	Net.Event("ExitDungeon"):FireServer()
end

function Net.MergeWeapon(uid: string)
	Net.Event("MergeWeapon"):FireServer(uid)
end

function Net.OpenPetCase(poolId: string?, count: number?)
	Net.Event("OpenPetCase"):FireServer(poolId, count or 1)
end

function Net.OpenAuraCase(count: number?)
	Net.Event("OpenAuraCase"):FireServer(count or 1)
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

function Net.SellPet(uid: string)
	Net.Event("SellPet"):FireServer(uid)
end

function Net.EquipAura(uid: string)
	Net.Event("EquipAura"):FireServer(uid)
end

function Net.UnequipAura()
	Net.Event("UnequipAura"):FireServer()
end

function Net.UpgradeAura(uid: string)
	Net.Event("UpgradeAura"):FireServer(uid)
end

function Net.EquipRelic(uid: string)
	Net.Event("EquipRelic"):FireServer(uid)
end

function Net.UnequipRelic(uid: string)
	Net.Event("UnequipRelic"):FireServer(uid)
end

function Net.UpgradeRelic(uid: string)
	Net.Event("UpgradeRelic"):FireServer(uid)
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
