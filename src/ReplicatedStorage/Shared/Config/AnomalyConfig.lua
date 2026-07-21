--!strict
--[[
	Global timed anomalies (server-wide).
	Every INTERVAL_SECONDS roll one; ACTIVE_SECONDS duration; rest of interval quiet.

	mods (all optional):
	  coinMult      — multiplies GetCoinMult result
	  powerMult     — multiplies TotalPower
	  damagePct     — additive to damage % pool
	  luckAdd       — additive luck (same units as GetLuck)
	  spawnMult     — multiplies respawn delay (<1 = faster)
	  dropMult      — multiplies weapon drop chance
	  dustMult      — multiplies enchant dust grants
	  keyChanceMult — multiplies pet/aura key roll chances
	  mobHpMult     — multiplies mob max HP (Blood Moon style; applied on spawn/refresh if used)

	hud: keys for top-left pills { money|power|damage|luck = fraction e.g. 0.3 = +30% }
]]

export type AnomalyMods = {
	coinMult: number?,
	powerMult: number?,
	damagePct: number?,
	luckAdd: number?,
	spawnMult: number?,
	dropMult: number?,
	dustMult: number?,
	keyChanceMult: number?,
	mobHpMult: number?,
}

export type AnomalyDef = {
	id: string,
	name: string,
	blurb: string,
	weight: number,
	durationSeconds: number?,
	mods: AnomalyMods,
	hud: { [string]: number }?, -- money/power/damage/luck → pct fraction for HUD
	color: string?, -- notify color
}

local AnomalyConfig = {
	-- Full cycle between rolls (active sits inside this window)
	INTERVAL_SECONDS = 35 * 60, -- 35 min
	DEFAULT_DURATION = 10 * 60, -- 10 min
	-- Studio / DEBUG: first anomaly sooner so you can see it
	DEBUG_FIRST_DELAY = 45,
	DEBUG_INTERVAL_SECONDS = 3 * 60,
	DEBUG_DURATION = 60,

	WORLD_FOLDER = "WorldState",
	ATTR_ID = "AnomalyId",
	ATTR_NAME = "AnomalyName",
	ATTR_ENDS = "AnomalyEndsAt", -- unix time
	ATTR_STARTS = "AnomalyStartsAt",

	List = {
		----------------------------------------------------------------------
		-- Pool A — safe farm
		----------------------------------------------------------------------
		{
			id = "AN_GOLD",
			name = "Gold Tide",
			blurb = "Coins ×1.3",
			weight = 22,
			mods = { coinMult = 1.3 },
			hud = { money = 0.30 },
			color = "gold",
		},
		{
			id = "AN_POWER",
			name = "Power Surge",
			blurb = "Power ×1.15",
			weight = 18,
			mods = { powerMult = 1.15 },
			hud = { power = 0.15 },
			color = "orange",
		},
		{
			id = "AN_SWARM",
			name = "Swarm",
			blurb = "Mobs respawn 30% faster",
			weight = 16,
			mods = { spawnMult = 0.70 },
			hud = { damage = 0.05 }, -- weak pill so something shows
			color = "cyan",
		},
		{
			id = "AN_LUCK",
			name = "Lucky Edge",
			blurb = "Weapon drops ×1.25",
			weight = 16,
			mods = { dropMult = 1.25, luckAdd = 0.10 },
			hud = { luck = 0.25 },
			color = "green",
		},
		{
			id = "AN_DUST",
			name = "Dust Rain",
			blurb = "Enchant dust +50%",
			weight = 12,
			mods = { dustMult = 1.5 },
			hud = { luck = 0.10 },
			color = "pink",
		},
		{
			id = "AN_KEY",
			name = "Key Spark",
			blurb = "Case key chances ×1.5",
			weight = 10,
			mods = { keyChanceMult = 1.5 },
			hud = { money = 0.08 },
			color = "cyan",
		},
		----------------------------------------------------------------------
		-- Pool B — tradeoff / spice
		----------------------------------------------------------------------
		{
			id = "AN_BLOOD",
			name = "Blood Moon",
			blurb = "Power ×1.25, mob HP ×1.3",
			weight = 6,
			mods = { powerMult = 1.25, mobHpMult = 1.3 },
			hud = { power = 0.25, damage = 0.10 },
			color = "red",
		},
		{
			id = "AN_MISER",
			name = "Miser's Fog",
			blurb = "Coins ×0.7, weapon drops ×1.4",
			weight = 5,
			mods = { coinMult = 0.7, dropMult = 1.4 },
			hud = { money = -0.30, luck = 0.40 },
			color = "yellow",
		},
		{
			id = "AN_GLASS",
			name = "Glass Cannon",
			blurb = "Damage +40% (power pool)",
			weight = 5,
			mods = { damagePct = 40 },
			hud = { damage = 0.40 },
			color = "orange",
		},
	} :: { AnomalyDef },
}

local byId: { [string]: AnomalyDef } = {}
for _, def in AnomalyConfig.List do
	byId[def.id] = def
end

function AnomalyConfig.Get(id: string): AnomalyDef?
	return byId[id]
end

function AnomalyConfig.Roll(): AnomalyDef
	local total = 0
	for _, def in AnomalyConfig.List do
		total += def.weight
	end
	local r = math.random() * math.max(total, 1)
	local acc = 0
	for _, def in AnomalyConfig.List do
		acc += def.weight
		if r <= acc then
			return def
		end
	end
	return AnomalyConfig.List[1]
end

function AnomalyConfig.EmptyMods(): AnomalyMods
	return {}
end

return AnomalyConfig
