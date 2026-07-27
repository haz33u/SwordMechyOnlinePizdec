const fs = require("fs");
const path = require("path");
const j = JSON.parse(fs.readFileSync(path.join(__dirname, "mf_assets_localstorage.json"), "utf8"));
const lua = fs.readFileSync(
	path.join(__dirname, "../src/ReplicatedStorage/Shared/Config/InventoryAssetConfig.lua"),
	"utf8",
);
const pot = fs.readFileSync(
	path.join(__dirname, "../src/ReplicatedStorage/Shared/Config/PotionIconConfig.lua"),
	"utf8",
);
let ok = 0;
let bad = 0;
const aliases = new Set(["GamePass card empty plate", "BTN_Confirm_Check 1", "SELLallUNLOCKED"]);
for (const [k, id] of Object.entries(j)) {
	if (aliases.has(k)) {
		ok++;
		continue;
	}
	const needle = `${k} = "rbxassetid://${id}"`;
	if (lua.includes(needle) || pot.includes(needle)) {
		ok++;
	} else {
		console.log("MISMATCH or missing", k, id);
		bad++;
	}
}
console.log(JSON.stringify({ ok, bad, keys: Object.keys(j).length }, null, 2));
console.log("spot checks:", {
	INVENTORYWEAPONcard: j.INVENTORYWEAPONcard,
	Slot_Secret: j.Slot_Secret,
	Toggle_Rainbow_ON: j.Toggle_Rainbow_ON,
	MAINBACKGROUD: j.MAINBACKGROUD,
	unequip: j.unequip,
	SmallCoin: j.SmallCoin,
});
process.exit(bad ? 1 : 0);
