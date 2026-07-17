--!strict
--[[
	Fluency-style icon map (outline game UI).
	IDs are Roblox Image assets used as Fluency stand-ins.
	When you import Fluency Icon Library into Studio, replace rbxassetid values
	with Fluency IDs — keep the same keys.
]]

local Icons = {
	-- dock / nav
	character = "rbxassetid://6034287594",
	sword = "rbxassetid://6035056476",
	pet = "rbxassetid://6034287501",
	aura = "rbxassetid://6031097225",
	relic = "rbxassetid://6031068421",
	quest = "rbxassetid://6031094678",
	map = "rbxassetid://6034684930",
	dungeon = "rbxassetid://6034684937",
	settings = "rbxassetid://6031280882",

	-- actions
	auto = "rbxassetid://6031094670",
	rebirth = "rbxassetid://6031229361",
	click = "rbxassetid://6034509993",
	coins = "rbxassetid://6031068420",
	power = "rbxassetid://6031229358",
	close = "rbxassetid://6031094677",
	check = "rbxassetid://6031094667",
	case = "rbxassetid://6031068426",
	feed = "rbxassetid://6031094661",
	ban = "rbxassetid://6031094674",
	enchant = "rbxassetid://6031068428",
	sell = "rbxassetid://6031094679",
	equip = "rbxassetid://6031094668",
	upgrade = "rbxassetid://6031229350",
}

function Icons.Get(key: string): string
	return Icons[key] or Icons.character
end

return Icons
