--!strict
--[[
	Inventory / Shop / Profile chrome assets (MechyForge uploads).

	Source: Figma LAYOUT screens + Asset Manager Decals/Images.
	Use: InventoryAssetConfig.Get("WEAPONSBUTTON") -> "rbxassetid://..."

	IDs are IMAGE ids (converted from Open Cloud decal uploads 2026-07-26
	via Studio GetObjects resolver). Do not paste raw decal ids here —
	run decal2image first. Friend sees the same table via git.
]]

local InventoryAssetConfig = {
	-- ── Main shell ─────────────────────────────────────────
	MAINBACKGROUD = "rbxassetid://92865560197091", -- was decal 109329669318137 (duplicate 107206259216274)
	BG_WeaponGrid = "rbxassetid://89117847220468",
	Divider_3_Minimal_1 = "rbxassetid://120415832747105",
	BTN_Close_3 = "rbxassetid://72455930867410",
	btn_neutral_2_1 = "rbxassetid://74404628605222",
	btn_neutral_2_2 = "rbxassetid://71855129271456",
	TOOLTIPshell = "rbxassetid://92658191065501",

	-- ── Bottom tab rail (Figma only — no Cases in inventory) ───
	WEAPONSBUTTON = "rbxassetid://124423602280041",
	PETCBUTTON = "rbxassetid://72145053886893",
	AURABUTTON = "rbxassetid://124836568025437",
	RELICBUTTON = "rbxassetid://117114899360020",
	CONSUMABLESBUTTON = "rbxassetid://101740999000329",
	SHOPBUTTON = "rbxassetid://104501192850058",
	PROFILEBUTTON = "rbxassetid://103096630967071",
	SETTINGSBUTTON = "rbxassetid://72658043228119",
	TELEPORTERBUTTON = "rbxassetid://125419182346918",

	-- ── Tab headers ────────────────────────────────────────
	INVENTORYWEAPONcard = "rbxassetid://90473285925317", -- INVENTORY • WEAPONS
	PETScard = "rbxassetid://103573093369521",
	AURAScard = "rbxassetid://130409439244534",
	RELICcard = "rbxassetid://117029557776846",
	CONSUMABLEScard = "rbxassetid://75177270795264",
	SHOPcard = "rbxassetid://84796182593075",
	PROFIILEcard = "rbxassetid://112860676886389", -- name as uploaded (typo double I)
	SETTINGcard = "rbxassetid://114095500677799",

	-- ── Presets ───────────────────────────────────────────
	PRESETcard1 = "rbxassetid://97212429687032",
	PRESETcard2 = "rbxassetid://102298755754238",
	PRESETcard3 = "rbxassetid://71302406947711",
	PRESETcard4 = "rbxassetid://74373931018247",
	WORDMARK_presets__click_to_equip_1 = "rbxassetid://72992356938065",

	-- ── Slot frames by rarity (Empty → Mythic) ─────────────────
	Slot_Empty_3 = "rbxassetid://93019228783497",
	Slot_Common_5 = "rbxassetid://77107427791922",
	Slot_Uncommon_5 = "rbxassetid://83826659711881",
	Slot_Rare_5 = "rbxassetid://73913709307435",
	Slot_Epic_5 = "rbxassetid://125802780104168",
	Slot_Legendary_5 = "rbxassetid://110504679708488",
	Slot_Mythic_5 = "rbxassetid://138634223640319",
	Slot_Secret = "rbxassetid://125029706914658",
	Slot_Limited_Body = "rbxassetid://75311528289040",
	Slot_Limited_Rim = "rbxassetid://83892126340335",
	BTN_Confirm_Check_1 = "rbxassetid://130276735253420",

	-- ── Equip loadout (Panel_EquipInfo / EQUIPMENTbackground) ──
	EQUIPMENTbackground = "rbxassetid://98803634847964",
	MAINswordCARD = "rbxassetid://107165883488202",
	SECONDswordCARD = "rbxassetid://89369544061968",
	STARSdecoration = "rbxassetid://95489469723485",
	STARTSdecoration = "rbxassetid://140091678452076", -- alternate/typo upload; prefer STARSdecoration
	SELLbutton = "rbxassetid://132238377502752",
	SELLallUNLOCKEDbutton = "rbxassetid://130648772284458",
	EQUIPbestFORpowerBUTTON = "rbxassetid://92110616611889", -- already an Image id
	EQUIPbestFORdamageBUTTON = "rbxassetid://119992767516552", -- already an Image id
	MOUSEBINDScard = "rbxassetid://76392032081380",

	-- ── Shop ───────────────────────────────────────────────
	SECONDswordShopcard = "rbxassetid://87981370801253",
	A_1PetslotShopcard = "rbxassetid://97807859243530", -- +1 Pet slot
	A_1RELICslotShopcard = "rbxassetid://130943106845504", -- +1 Relic slot
	x3CaseopenShopcard = "rbxassetid://76561942008226",
	WORDMARK___passes__1 = "rbxassetid://134304693967257",
	GamePass_card_empty_plate = "rbxassetid://83871405491605",

	-- ── Profile ───────────────────────────────────────────
	AVATArcard = "rbxassetid://123858310682978",
	MAINtitle_NicKcard = "rbxassetid://90764636942941",
	MAINusernamexard = "rbxassetid://125069362428324", -- name as uploaded
	STATS1card = "rbxassetid://86941981848785",
	STATS2card = "rbxassetid://82386813907730",
	OPENtitlesLISTbutton = "rbxassetid://106386332533455", -- already an Image id
	OPENtitlesLISTbutton_Decal = "rbxassetid://106386332533455", -- old decal, resolves to same image as OPENtitlesLISTbutton
	WORDMARK_TITLE_NICK_1_1 = "rbxassetid://128577696714849",

	-- ── Settings toggles ──────────────────────────────────
	Toggle_Rainbow_OFF = "rbxassetid://111522661732585",
	Toggle_Rainbow_ON = "rbxassetid://86770309543198",

	-- ── Demo / placeholder item cards (grid samples, not catalog) ─
	PETcard1 = "rbxassetid://81512403260701",
	PETcard2 = "rbxassetid://102890033531349",
	PETcard3 = "rbxassetid://74393234989307",
	PETcard4 = "rbxassetid://113960553603442",
	PETcard5 = "rbxassetid://84765769197391",
	PETcard6 = "rbxassetid://88560000877223",
	PETcard7 = "rbxassetid://84603345544587",
	PETcard8 = "rbxassetid://124036977196447",
	RELICcard1 = "rbxassetid://73081644016490",
	RELICcard2 = "rbxassetid://86565354659702",
	RELICcard3 = "rbxassetid://82865823499587",
}

--- Map rarity name -> slot frame asset.
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
