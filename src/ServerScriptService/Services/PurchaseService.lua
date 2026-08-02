--!strict
--[[
	Roblox Developer Product purchases.
	Only real product IDs are processed; stub IDs (0) are rejected unless DEBUG_FREE_PAID.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DevProductConfig = require(Shared.Config.DevProductConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)
local PetService = require(script.Parent.PetService)

local PurchaseService = {}

local function grant(productKey: string, player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end
	if productKey == "paidArenaCase" then
		PetService.OpenCase(player, nil, 1)
		return true
	end
	return false
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local def = DevProductConfig.ByProductId(receiptInfo.ProductId)
	if not def then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok = grant(def.grant, player)
	if ok then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Purchased: " .. def.title,
			color = "gold",
		})
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
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
		if def.productId == 0 and ProgressConfig.DEBUG_FREE_PAID then
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
