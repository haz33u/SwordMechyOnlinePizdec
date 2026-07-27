/**
 * Compare a user-pasted mf_assets JSON (file path arg) to game-exact export.
 * Usage: node tools/check_user_mf_assets.js tools/_user_paste.json
 */
const fs = require("fs");
const path = require("path");

const game = JSON.parse(
	fs.readFileSync(path.join(__dirname, "mf_assets_localstorage.json"), "utf8"),
);

const arg = process.argv[2];
if (!arg) {
	console.error("Usage: node tools/check_user_mf_assets.js <user.json>");
	process.exit(2);
}

let raw = fs.readFileSync(arg, "utf8").trim();
// strip markdown fences
if (raw.startsWith("```")) {
	raw = raw.replace(/^```[a-z]*\n?/i, "").replace(/\n?```$/, "");
}

let user;
try {
	user = JSON.parse(raw);
} catch (e) {
	// try repair truncated tail
	console.log("JSON parse failed:", e.message);
	// if ends mid-value, report incomplete
	const lastKey = raw.match(/"([^"]+)":\s*"[^"]*$/);
	console.log("Looks TRUNCATED (incomplete paste). Last incomplete key-ish:", lastKey && lastKey[1]);
	// parse what we can with regex
	user = {};
	const re = /"([^"]+)":"(\d+)"/g;
	let m;
	while ((m = re.exec(raw))) user[m[1]] = m[2];
	console.log("Recovered complete pairs:", Object.keys(user).length);
}

const mismatches = [];
const missingInUser = [];
const extraInUser = [];
const ok = [];

for (const [k, id] of Object.entries(game)) {
	if (user[k] === undefined) missingInUser.push(k);
	else if (String(user[k]) !== String(id)) mismatches.push({ key: k, user: user[k], game: id });
	else ok.push(k);
}
for (const k of Object.keys(user)) {
	if (game[k] === undefined) extraInUser.push(k);
}

console.log(
	JSON.stringify(
		{
			status:
				mismatches.length === 0 && missingInUser.length === 0
					? "PERFECT_MATCH"
					: mismatches.length === 0 && missingInUser.length > 0
						? "PARTIAL_OK_IDS_MATCH_BUT_INCOMPLETE"
						: "HAS_MISMATCHES",
			okCount: ok.length,
			gameKeyCount: Object.keys(game).length,
			userKeyCount: Object.keys(user).length,
			mismatchCount: mismatches.length,
			missingCount: missingInUser.length,
			extraCount: extraInUser.length,
			mismatches,
			missingInUser,
			extraInUser,
		},
		null,
		2,
	),
);
