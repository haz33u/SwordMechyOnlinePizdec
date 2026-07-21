--!strict
--[[
	Roblox gamepasses for Donate Shop + paid unlocks.
	Icons: rbxthumb GamePass (no Studio upload required).
	Local PNG sources (optional art): Downloads/sword_slot.png, pet_slot_+1.png, etc.
]]

export type GamePassDef = {
	gamePassId: number,
	key: string,
	title: string,
	desc: string,
	feature: string?, -- maps to profile.unlocks / systems
	-- rbxthumb://type=GamePass&id=ID&w=150&h=150
}

local GamePassConfig = {
	Order = {
		"offhand",
		"paidPetSlot",
		"relicSlot",
		"autoClicker",
		"teleporter",
		"openChest3",
		"openChest5",
	},

	Passes = {
		offhand = {
			gamePassId = 1918407110,
			key = "offhand",
			title = "Second sword slot",
			desc = "Unlock offhand weapon (50% power)",
			feature = "offhand",
		},
		relicSlot = {
			gamePassId = 1918053131,
			key = "relicSlot",
			title = "3rd relic slot",
			desc = "Equip 3 relics (free players have 2)",
			feature = "relicSlot",
		},
		paidPetSlot = {
			gamePassId = 1918737139,
			key = "paidPetSlot",
			title = "1 pet slot",
			desc = "+1 pet team slot",
			feature = "paidPetSlot",
		},
		autoClicker = {
			gamePassId = 1918059138,
			key = "autoClicker",
			title = "AutoClicker",
			desc = "Unlock auto-clicker permanently",
			feature = "autoClicker",
		},
		teleporter = {
			gamePassId = 1918533136,
			key = "teleporter",
			title = "Teleporter",
			desc = "Fast travel between unlocked locations",
			feature = "teleporter",
		},
		openChest3 = {
			gamePassId = 1918725128,
			key = "openChest3",
			title = "Open 3 chest",
			desc = "Open 3 cases at once",
			feature = "openChest3",
		},
		openChest5 = {
			gamePassId = 1918377139,
			key = "openChest5",
			title = "Open 5 chest",
			desc = "Open 5 cases at once",
			feature = "openChest5",
		},
	} :: { [string]: GamePassDef },
}

function GamePassConfig.Get(key: string): GamePassDef?
	return GamePassConfig.Passes[key]
end

function GamePassConfig.ByPassId(id: number): GamePassDef?
	for _, def in GamePassConfig.Passes do
		if def.gamePassId == id then
			return def
		end
	end
	return nil
end

function GamePassConfig.ThumbUrl(gamePassId: number, size: number?): string
	local s = size or 150
	return string.format("rbxthumb://type=GamePass&id=%d&w=%d&h=%d", gamePassId, s, s)
end

return GamePassConfig
