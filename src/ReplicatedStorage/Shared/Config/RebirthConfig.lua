--!strict
--[[
	Rebirth ladder — 60 ranks (~2.4 per planned location on a 25-loc map).

	Power vs cadence:
	  - Early R1–R3 keep dump mults (×3 / ×7 / ×18).
	  - Later growth softens so R60 stays finite (not old ×2.5 bomb).
	  - Cadence: more ranks to chase across worlds; pets/weapons still carry Loc walls.

	UI: English rank names only. Style via GetRankStyle (color / stroke / gradient).
]]

export type RankStyle = {
	band: string,
	color: Color3,
	stroke: Color3,
	strokeThickness: number,
	gradientFrom: Color3?,
	gradientTo: Color3?,
}

local RebirthConfig = {
	MAX_LEVEL = 60,

	----------------------------------------------------------------------
	-- Power thresholds (level = next rebirth index)
	----------------------------------------------------------------------
	POWER_COST = {
		[1] = 5_000, -- dump R1 (Power requirement)
		[2] = 150_000, -- dump R2
		[3] = 2_500_000, -- dump R3
	} :: { [number]: number },

	-- R4+: geometric from R3
	GROWTH_AFTER_R3 = 28,

	COIN_COST = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
	} :: { [number]: number },
	WIPE_COINS_ON_REBIRTH = true,
	WIPE_POWER_ON_REBIRTH = true,

	----------------------------------------------------------------------
	-- Mult: fixed early, then banded growth (NOT flat ×2.5 forever)
	----------------------------------------------------------------------
	RANK_MULT = {
		[0] = 1,
		[1] = 3,
		[2] = 7,
		[3] = 18,
	} :: { [number]: number },

	-- Applied when stepping to level L (from L-1), for L >= 4
	GROWTH_BANDS = {
		{ maxLevel = 20, growth = 1.60 }, -- R4–R20
		{ maxLevel = 40, growth = 1.40 }, -- R21–R40
		{ maxLevel = 60, growth = 1.25 }, -- R41–R60
	},

	----------------------------------------------------------------------
	-- Names 0..60 (souls-like energy, original EN strings)
	----------------------------------------------------------------------
	RANK_NAME = {
		[0] = "Ashborn",
		[1] = "Tarnished Blade",
		[2] = "Bloodsworn",
		[3] = "Oathbreaker",
		[4] = "Gravecaller",
		[5] = "Nightpiercer",
		[6] = "Stormbane",
		[7] = "Iron Wraith",
		[8] = "Cinder Lord",
		[9] = "Doomherald",
		[10] = "Starscourge",
		[11] = "Eclipse Knight",
		[12] = "Voidmarked",
		[13] = "Rift Sovereign",
		[14] = "Godsbane",
		[15] = "Red Omen",
		[16] = "Blight Monarch",
		[17] = "War Eternal",
		[18] = "Scarlet Oath",
		[19] = "Crimson End",
		[20] = "Demigod",
		[21] = "World Eater",
		[22] = "Throne of Ash",
		[23] = "Sundered King",
		[24] = "Eternal Scourge",
		[25] = "Starfallen",
		[26] = "Astral Tyrant",
		[27] = "Moonless Crown",
		[28] = "Fate Render",
		[29] = "Celestial Ruin",
		[30] = "Abyss Walker",
		[31] = "Nameless Horror",
		[32] = "Outer Flame",
		[33] = "Crown of Night",
		[34] = "Fated End",
		[35] = "Godfall",
		[36] = "Heavenbreaker",
		[37] = "Thronebreaker",
		[38] = "Divine Sorrow",
		[39] = "Apex Scourge",
		[40] = "Lord of Ruin",
		[41] = "Cataclysm",
		[42] = "Worldscar",
		[43] = "Last Remnant",
		[44] = "Unmade",
		[45] = "Null Sovereign",
		[46] = "Depths Eternal",
		[47] = "Silence Incarnate",
		[48] = "Void Emperor",
		[49] = "Abyss Absolute",
		[50] = "Beyond Fate",
		[51] = "Final Remnant",
		[52] = "World's Edge",
		[53] = "Unwritten",
		[54] = "Omega Scar",
		[55] = "Last Light",
		[56] = "Zero Covenant",
		[57] = "End of Names",
		[58] = "Absolute Ruin",
		[59] = "Ecliptic Zero",
		[60] = "The Unmade Law",
	} :: { [number]: string },

	ETA_COINS_PER_DAMAGE = 0.12,
}

local function growthForStep(toLevel: number): number
	for _, band in RebirthConfig.GROWTH_BANDS do
		if toLevel <= band.maxLevel then
			return band.growth
		end
	end
	return 1.2
end

function RebirthConfig.GetPowerCost(level: number): number
	if level < 1 then
		return 0
	end
	local fixed = RebirthConfig.POWER_COST[level]
	if fixed then
		return fixed
	end
	local base = RebirthConfig.POWER_COST[3] or 2_500_000
	local g = RebirthConfig.GROWTH_AFTER_R3 or 28
	return math.floor(base * (g ^ (level - 3)))
end

function RebirthConfig.GetCoinCost(level: number): number
	if level < 1 then
		return 0
	end
	local fixed = RebirthConfig.COIN_COST[level]
	if fixed ~= nil then
		return fixed
	end
	return 0
end

function RebirthConfig.GetCost(level: number): number
	return RebirthConfig.GetPowerCost(level)
end

function RebirthConfig.GetCosts(level: number): (number, number)
	return RebirthConfig.GetPowerCost(level), RebirthConfig.GetCoinCost(level)
end

function RebirthConfig.GetMultAfter(level: number): number
	if level <= 0 then
		return 1
	end
	local fixed = RebirthConfig.RANK_MULT[level]
	if fixed then
		return fixed
	end
	local m = RebirthConfig.RANK_MULT[3] or 18
	for L = 4, level do
		m *= growthForStep(L)
	end
	return m
end

function RebirthConfig.GetBonus(level: number): number
	local prev = RebirthConfig.GetMultAfter(level - 1)
	local cur = RebirthConfig.GetMultAfter(level)
	if prev <= 0 then
		return 0
	end
	return (cur / prev) - 1
end

function RebirthConfig.GetRankName(level: number): string
	local lv = math.clamp(math.floor(level or 0), 0, RebirthConfig.MAX_LEVEL)
	local n = RebirthConfig.RANK_NAME[lv]
	if n then
		return n
	end
	return "Rank " .. tostring(lv)
end

function RebirthConfig.GetRankBand(level: number): string
	local lv = math.clamp(math.floor(level or 0), 0, RebirthConfig.MAX_LEVEL)
	if lv <= 9 then
		return "Ash"
	elseif lv <= 19 then
		return "Blood"
	elseif lv <= 29 then
		return "Star"
	elseif lv <= 39 then
		return "God"
	elseif lv <= 49 then
		return "Abyss"
	end
	return "End"
end

function RebirthConfig.GetRankStyle(level: number): RankStyle
	local band = RebirthConfig.GetRankBand(level)
	if band == "Ash" then
		return {
			band = band,
			color = Color3.fromRGB(180, 175, 165),
			stroke = Color3.fromRGB(40, 38, 35),
			strokeThickness = 1.2,
			gradientFrom = Color3.fromRGB(200, 190, 170),
			gradientTo = Color3.fromRGB(120, 110, 95),
		}
	elseif band == "Blood" then
		return {
			band = band,
			color = Color3.fromRGB(220, 70, 80),
			stroke = Color3.fromRGB(60, 10, 15),
			strokeThickness = 1.6,
			gradientFrom = Color3.fromRGB(255, 90, 90),
			gradientTo = Color3.fromRGB(120, 20, 40),
		}
	elseif band == "Star" then
		return {
			band = band,
			color = Color3.fromRGB(120, 220, 255),
			stroke = Color3.fromRGB(20, 40, 80),
			strokeThickness = 1.8,
			gradientFrom = Color3.fromRGB(255, 220, 120),
			gradientTo = Color3.fromRGB(80, 200, 255),
		}
	elseif band == "God" then
		return {
			band = band,
			color = Color3.fromRGB(255, 200, 80),
			stroke = Color3.fromRGB(120, 50, 10),
			strokeThickness = 2.0,
			gradientFrom = Color3.fromRGB(255, 240, 160),
			gradientTo = Color3.fromRGB(255, 120, 40),
		}
	elseif band == "Abyss" then
		return {
			band = band,
			color = Color3.fromRGB(180, 120, 255),
			stroke = Color3.fromRGB(25, 10, 50),
			strokeThickness = 2.2,
			gradientFrom = Color3.fromRGB(220, 160, 255),
			gradientTo = Color3.fromRGB(40, 20, 90),
		}
	end
	-- End
	return {
		band = "End",
		color = Color3.fromRGB(255, 250, 240),
		stroke = Color3.fromRGB(80, 60, 20),
		strokeThickness = 2.6,
		gradientFrom = Color3.fromRGB(255, 255, 255),
		gradientTo = Color3.fromRGB(255, 200, 80),
	}
end

function RebirthConfig.GetProgress(power: number, coins: number, level: number): number
	local powerCost, coinCost = RebirthConfig.GetCosts(level)
	local pPower = if powerCost > 0 then math.clamp(power / powerCost, 0, 1) else 1
	local pCoin = if coinCost > 0 then math.clamp(coins / coinCost, 0, 1) else 1
	return math.min(pPower, pCoin)
end

function RebirthConfig.CanAfford(power: number, coins: number, level: number): (boolean, string?)
	local powerCost, coinCost = RebirthConfig.GetCosts(level)
	if power < powerCost then
		return false, string.format("Need %s Power (have %s)", tostring(powerCost), tostring(math.floor(power)))
	end
	if coinCost > 0 and coins < coinCost then
		return false, string.format("Need %s coins (have %s)", tostring(coinCost), tostring(math.floor(coins)))
	end
	return true, nil
end

return RebirthConfig
