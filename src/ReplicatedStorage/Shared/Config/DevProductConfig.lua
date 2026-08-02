--!strict
--[[
	Developer Products (one-time purchases, not gamepasses).
	Arena case: open one premium case for 49 R$.
]]

export type DevProductDef = {
	productId: number,
	key: string,
	title: string,
	desc: string,
	robux: number,
	grant: string, -- maps to purchase handler
}

local DevProductConfig = {
	Order = {
		"paidArenaCase",
	} :: { string },

	Products = {
		paidArenaCase = {
			productId = 3612491490,
			key = "paidArenaCase",
			title = "Arena Case",
			desc = "Open one premium arena case instantly",
			robux = 49,
			grant = "paidArenaCase",
		} :: DevProductDef,
	} :: { [string]: DevProductDef },
}

function DevProductConfig.Get(key: string): DevProductDef?
	return DevProductConfig.Products[key]
end

function DevProductConfig.ByProductId(id: number): DevProductDef?
	for _, def in DevProductConfig.Products do
		if def.productId == id then
			return def
		end
	end
	return nil
end

return DevProductConfig
