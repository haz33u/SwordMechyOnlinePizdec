--!strict
--[[
	Inventory / Shop / Profile chrome assets (MechyForge uploads).

	Source: Figma LAYOUT screens + Asset Manager Decals/Images.
	Use: InventoryAssetConfig.Get("WEAPONSBUTTON") → "rbxassetid://…"

	Do not invent placeholder ids. Friend sees the same table via git.
]]

local InventoryAssetConfig = {
	-- ── Main shell ─────────────────────────────────────────────
	MAINBACKGROUD = "rbxassetid://109329669318137", -- duplicate upload 107206259216274 is identical
	BG_WeaponGrid = "rbxassetid://123475576029932",
	Divider_3_Minimal_1 = "rbxassetid://138707328688658",
	BTN_Close_3 = "rbxassetid://132260235436115",
	btn_neutral_2_1 = "rbxassetid://108887761303867",
	btn_neutral_2_2 = "rbxassetid://114045150215835",
	TOOLTIPshell = "rbxassetid://109491248361577",

	-- ── Left tab rail (Figma only — no Cases in inventory) ─────
	WEAPONSBUTTON = "rbxassetid://136377090198907",
	PETCBUTTON = "rbxassetid://101113775481696",
	AURABUTTON = "rbxassetid://136063134601854",
	RELICBUTTON = "rbxassetid://117117357631042",
	CONSUMABLESBUTTON = "rbxassetid://129101268564836",
	SHOPBUTTON = "rbxassetid://135128464657998",
	PROFILEBUTTON = "rbxassetid://100720332511542",
	SETTINGSBUTTON = "rbxassetid://116575452557598",
	TELEPORTERBUTTON = "rbxassetid://126074506618888",

	-- ── Tab headers ────────────────────────────────────────────
	INVENTORYWEAPONcard = "rbxassetid://126211504937247", -- INVENTORY • WEAPONS
	PETScard = "rbxassetid://72884475463606",
	AURAScard = "rbxassetid://118800405065464",
	RELICcard = "rbxassetid://119070556168608",
	CONSUMABLEScard = "rbxassetid://88760878142362",
	SHOPcard = "rbxassetid://83434406942933",
	PROFIILEcard = "rbxassetid://85842695837369", -- name as uploaded (typo double I)
	SETTINGcard = "rbxassetid://83535628737807",

	-- ── Presets ────────────────────────────────────────────────
	PRESETcard1 = "rbxassetid://86941158014314",
	PRESETcard2 = "rbxassetid://83511350467791",
	PRESETcard3 = "rbxassetid://131457201322451",
	PRESETcard4 = "rbxassetid://107099484545631",
	WORDMARK_presets__click_to_equip_1 = "rbxassetid://96826442437821",

	-- ── Slot frames by rarity (Empty → Mythic) ─────────────────
	Slot_Empty_3 = "rbxassetid://76615280390410",
	Slot_Common_5 = "rbxassetid://103700415507102",
	Slot_Uncommon_5 = "rbxassetid://93953189037997",
	Slot_Rare_5 = "rbxassetid://84138962317498",
	Slot_Epic_5 = "rbxassetid://112807372557856",
	Slot_Legendary_5 = "rbxassetid://116513949821988",
	Slot_Mythic_5 = "rbxassetid://115957829700251",
	Slot_Secret = "rbxassetid://73278259891657",
	Slot_Limited_Body = "rbxassetid://72397855713663",
	Slot_Limited_Rim = "rbxassetid://133165389836845",
	BTN_Confirm_Check_1 = "rbxassetid://138577700896730",

	-- ── Equip loadout (Panel_EquipInfo / EQUIPMENTbackground) ──
	MAINswordCARD = "rbxassetid://132958022184465",
	SECONDswordCARD = "rbxassetid://96746622934499",
	STARSdecoration = "rbxassetid://129088531898017",
	STARTSdecoration = "rbxassetid://118648420598705", -- alternate/typo upload; prefer STARSdecoration
	SELLbutton = "rbxassetid://119450831201453",
	SELLallUNLOCKEDbutton = "rbxassetid://100479667927713",
	EQUIPbestFORpowerBUTTON = "rbxassetid://92110616611889",
	EQUIPbestFORdamageBUTTON = "rbxassetid://119992767516552",
	MOUSEBINDScard = "rbxassetid://81765779098261",

	-- ── Shop ───────────────────────────────────────────────────
	SECONDswordShopcard = "rbxassetid://78812232411964",
	A_1PetslotShopcard = "rbxassetid://106650095356931", -- +1 Pet slot
	A_1RELICslotShopcard = "rbxassetid://88653189510344", -- +1 Relic slot
	x3CaseopenShopcard = "rbxassetid://73630542311124",
	WORDMARK___passes__1 = "rbxassetid://71332006772206",
	GamePass_card_empty_plate = "rbxassetid://114666751356961",

	-- ── Profile ────────────────────────────────────────────────
	AVATArcard = "rbxassetid://78902506751385",
	MAINtitle_NicKcard = "rbxassetid://140713367131416",
	MAINusernamexard = "rbxassetid://127412598914511", -- name as uploaded
	STATS1card = "rbxassetid://71756965092927",
	STATS2card = "rbxassetid://113745136851018",
	OPENtitlesLISTbutton = "rbxassetid://106386332533455", -- Image (prefer over older Decal)
	OPENtitlesLISTbutton_Decal = "rbxassetid://98780039814610", -- older MechyForge Decal
	WORDMARK_TITLE_NICK_1_1 = "rbxassetid://137281081458949",

	-- ── Settings toggles ───────────────────────────────────────
	Toggle_Rainbow_OFF = "rbxassetid://84770005695822",
	Toggle_Rainbow_ON = "rbxassetid://131748337490424",

	-- ── Demo / placeholder item cards (grid samples, not catalog) ─
	PETcard1 = "rbxassetid://112220293034062",
	PETcard2 = "rbxassetid://135302931893865",
	PETcard3 = "rbxassetid://72510814292504",
	PETcard4 = "rbxassetid://97907242455034",
	PETcard5 = "rbxassetid://104406946730115",
	PETcard6 = "rbxassetid://119562543615061",
	PETcard7 = "rbxassetid://96258350471905",
	PETcard8 = "rbxassetid://96436882959184",
	RELICcard1 = "rbxassetid://123453757016256",
	RELICcard2 = "rbxassetid://109752899922157",
	RELICcard3 = "rbxassetid://134174650334405",
}

--- Map rarity name → slot frame asset (Secret/Limited fall back to Mythic frame).
local SLOT_BY_RARITY: { [string]: string } = {
	Empty = InventoryAssetConfig.Slot_Empty_3,
	Common = InventoryAssetConfig.Slot_Common_5,
	Uncommon = InventoryAssetConfig.Slot_Uncommon_5,
	Rare = InventoryAssetConfig.Slot_Rare_5,
	Epic = InventoryAssetConfig.Slot_Epic_5,
	Legendary = InventoryAssetConfig.Slot_Legendary_5,
	Mythic = InventoryAssetConfig.Slot_Mythic_5,
	Secret = InventoryAssetConfig.Slot_Secret,
	Limited = InventoryAssetConfig.Slot_Limited_Body,
}

function InventoryAssetConfig.Get(key: string): string
	local id = InventoryAssetConfig[key]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return ""
end

function InventoryAssetConfig.GetSlotFrame(rarity: string?): string
	if rarity and SLOT_BY_RARITY[rarity] then
		return SLOT_BY_RARITY[rarity]
	end
	return InventoryAssetConfig.Slot_Empty_3
end

function InventoryAssetConfig.GetLimitedLayers(): (string, string)
	return InventoryAssetConfig.Slot_Limited_Body, InventoryAssetConfig.Slot_Limited_Rim
end

return InventoryAssetConfig
