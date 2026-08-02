--!strict
--[[
	Roblox Developer Product purchases.
	Only real product IDs are processed; stub IDs (0) are rejected unless DEBUG_FREE_PAID.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DevProductConfig = require(Shared.Config.DevProductConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)

local PurchaseService = {}

--[[
	Grant the product's content.

	MUST return true only when the player actually received something — the return
	value decides whether Roblox is told PurchaseGranted (money kept) or
	NotProcessedYet (receipt retried later).

	Paid products are granted `free = true` so the player is not charged game
	currency on top of the Robux they already spent.
]]
local function grant(productKey: string, player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end
	if productKey == "paidArenaCase" then
		return PetService.OpenCase(player, nil, 1, { free = true }) == true
	end
	warn(string.format("[PurchaseService] no grant handler for %q", productKey))
	return false
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before we could grant; Roblox retries on their next join.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local def = DevProductConfig.ByProductId(receiptInfo.ProductId)
	if not def then
		-- Unknown/retired product: retrying forever would spam ProcessReceipt on
		-- every join. Consume the receipt and log it for manual refund instead.
		warn(string.format(
			"[PurchaseService] unmapped ProductId %s bought by %s — receipt consumed, refund manually",
			tostring(receiptInfo.ProductId),
			player.Name
		))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local ok = grant(def.grant, player)
	if ok then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Purchased: " .. def.title,
			color = "gold",
		})
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- Grant failed (e.g. pet bag full). Keep the receipt open so the player gets
	-- their content on a later attempt rather than losing the Robux.
	Remotes.Event("Notify"):FireClient(player, {
		text = "Purchase pending — make room and rejoin to receive it",
		color = "yellow",
	})
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function PurchaseService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	Remotes.Event("PromptDevProduct").OnServerEvent:Connect(function(player, key)
		if type(key) ~= "string" then
			return
		end
		local def = DevProductConfig.Get(key)
		if not def then
			return
		end
		-- Studio-only free grant. Guarded by RunService so shipping with
		-- DEBUG_FREE_PAID enabled can never hand out paid content in a live server.
		if def.productId == 0 and ProgressConfig.DEBUG_FREE_PAID and RunService:IsStudio() then
			grant(key, player)
			return
		end
		local ok, price = pcall(function()
			return MarketplaceService:GetProductInfo(def.productId, Enum.InfoType.Product).PriceInRobux
		end)
		if not ok or type(price) ~= "number" then
			Remotes.Event("Notify"):FireClient(player, {
				text = "Product not configured",
				color = "red",
			})
			return
		end
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, def.productId)
		end)
	end)
end

return PurchaseService
