/**
 * Build mf_assets EXACTLY from game configs (InventoryAssetConfig).
 * No MechyForge overrides — IDs must match Studio / InventoryAssetConfig.lua 1:1.
 *
 * Usage:
 *   node tools/build_mf_assets_localstorage.js
 * Then paste tools/mf_assets_set_localstorage.js into DevTools on http://localhost:8765
 */
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");

function parseLuaAssetTable(filePath) {
	const lua = fs.readFileSync(filePath, "utf8");
	const out = {};
	const re = /^\s*([A-Za-z0-9_]+)\s*=\s*"rbxassetid:\/\/(\d+)"/gm;
	let m;
	while ((m = re.exec(lua))) {
		out[m[1]] = m[2];
	}
	return out;
}

const invPath = path.join(root, "src/ReplicatedStorage/Shared/Config/InventoryAssetConfig.lua");
const potPath = path.join(root, "src/ReplicatedStorage/Shared/Config/PotionIconConfig.lua");

const inv = parseLuaAssetTable(invPath);
const pot = parseLuaAssetTable(potPath);

// ── Game inventory chrome only (source of truth) ─────────────────
const out = { ...inv };

// Friendly aliases → SAME numeric id as game keys (editor key names only)
if (out.GamePass_card_empty_plate) {
	out["GamePass card empty plate"] = out.GamePass_card_empty_plate;
}
if (out.BTN_Confirm_Check_1) {
	out["BTN_Confirm_Check 1"] = out.BTN_Confirm_Check_1;
}
// Layout sometimes uses SELLallUNLOCKED without "button"
if (out.SELLallUNLOCKEDbutton) {
	out.SELLallUNLOCKED = out.SELLallUNLOCKEDbutton;
}

// Potions used by inventory items tab (same ids as PotionIconConfig)
for (const [k, id] of Object.entries(pot)) {
	out[k] = id;
}

// Meta for humans / editor (not asset ids)
out.__source = "InventoryAssetConfig.lua + PotionIconConfig.lua (game exact)";
out.__generatedAt = new Date().toISOString();
out.__note =
	"Do not hand-edit ids — re-run node tools/build_mf_assets_localstorage.js after git pull";

// Strip meta from runtime set (optional keep for debug)
const runtime = {};
for (const [k, v] of Object.entries(out)) {
	if (k.startsWith("__")) continue;
	runtime[k] = v;
}

const jsonPretty = JSON.stringify(runtime, null, 2);
const jsonOne = JSON.stringify(runtime);

fs.writeFileSync(path.join(__dirname, "mf_assets_localstorage.json"), jsonPretty);
fs.writeFileSync(
	path.join(__dirname, "mf_assets_set_localstorage.js"),
	[
		"// GAME-EXACT mf_assets — from InventoryAssetConfig + PotionIconConfig",
		"// Paste in Console on http://localhost:8765  then Enter",
		"(function () {",
		"  var data = " + jsonOne + ";",
		"  localStorage.setItem('mf_assets', JSON.stringify(data));",
		"  var n = Object.keys(data).length;",
		"  console.log('[mf_assets] wrote', n, 'keys (game exact)');",
		"  console.log('[mf_assets] sample INVENTORYWEAPONcard=', data.INVENTORYWEAPONcard);",
		"  console.log('[mf_assets] sample Slot_Secret=', data.Slot_Secret);",
		"  console.log('[mf_assets] sample Toggle_Rainbow_ON=', data.Toggle_Rainbow_ON);",
		"  location.reload();",
		"})();",
		"",
	].join("\n"),
);

// Diff report vs previous "editor" ids user had (so they see what changed)
const oldEditor = {
	INVENTORYWEAPONcard: "126211504937247",
	"GamePass card empty plate": "114666751356961",
	Toggle_Rainbow_OFF: "84770005695822",
	Toggle_Rainbow_ON: "131748337490424",
	Slot_Limited_Body: "72397855713663",
	Slot_Limited_Rim: "133165389836845",
	Slot_Secret: "73278259891657",
	"BTN_Confirm_Check 1": "138577700896730",
};
const diffs = [];
for (const [k, oldId] of Object.entries(oldEditor)) {
	const gameId = runtime[k] || runtime[k.replace(/ /g, "_")];
	const alt =
		runtime[k] ||
		(k === "GamePass card empty plate" && runtime.GamePass_card_empty_plate) ||
		(k === "BTN_Confirm_Check 1" && runtime.BTN_Confirm_Check_1);
	if (alt && String(alt) !== String(oldId)) {
		diffs.push({ key: k, was_editor: oldId, now_game: alt });
	}
}

fs.writeFileSync(
	path.join(__dirname, "mf_assets_diff_editor_vs_game.json"),
	JSON.stringify({ diffs, gameKeyCount: Object.keys(runtime).length }, null, 2),
);

console.log("GAME-EXACT keys:", Object.keys(runtime).length);
console.log("Editor→Game id fixes:", diffs.length);
for (const d of diffs) {
	console.log(" ", d.key, d.was_editor, "→", d.now_game);
}
console.log("wrote tools/mf_assets_localstorage.json");
console.log("wrote tools/mf_assets_set_localstorage.js");
console.log("wrote tools/mf_assets_diff_editor_vs_game.json");
