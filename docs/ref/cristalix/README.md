# Cristalix client reverse notes

## Location on this PC
`C:\Users\thisi\.cristalix\updates\Minigames\`

## What we found
- Client cache is **zstd-compressed** (magic `28 B5 2F FD`).
- Lang packs + addon JARs are decompressable.
- Minigame internal id: **`katana`** ("Мастера Катаны" / Katana Masters simulator).
- Extracted: `katana_lang_*.json`, key lists, balance-related UI strings.

## What is NOT in the client
- Exact HP / damage / sword power formulas (server-side only).
- Drop weight tables as numbers (only UI labels + % shown as placeholders like `%s`, `%d`).
- Mob spawn configs.

## Useful for our Roblox port
- UI vocabulary: stats (strength, rebirth, hits, kills, DNA, storage, chance)
- Boosters: money / exp / hits / kills (x2, timed)
- Pets: boosters x%s, max slots 5 (donate), chance slot on rebirth
- Runes with % abilities
- Katana upgrade / sell / crystals of preservation (+1 start level after rebirth)
- Lootbox keys (katana, pet, rune, title)
- Daily rewards structure
- Donate products mapping (pet slot, multi-case x5, speed perk)

## Files here
- katana_lang_a.json / katana_lang_b.json — full i18n pie
- katana_keys.txt — all 774 keys
- katana_key_prefixes.txt — grouped
- katana_balance_kv.txt — UI strings with balance hints
- katana_systems_kv.txt — systems-related strings
