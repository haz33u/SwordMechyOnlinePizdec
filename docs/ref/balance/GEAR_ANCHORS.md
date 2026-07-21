# Gear anchors (mid-late orientation)

Reference screenshots for dungeon relics & secret weapons (no external names).

## Mythic dungeon relic (hard dungeon)

| Field | Example |
|-------|---------|
| Name | Forester's Ring (Кольцо лесника) |
| Rarity | **Mythic** |
| Level | **42** (heavily upgraded) |
| XP bar | 751 (into next) |
| Power boost | **87.52K%** (~×875 on relic power line) |
| Source | Found on **stage 12** of **hard dungeon** |

Implication for us: dungeon relics should **level/star** high; late mythic power line is **thousands of %**, not the small early RelicConfig placeholders forever.

## Secret weapon (same band as mid-late loc)

| Field | Example |
|-------|---------|
| Name | Scythe of Fear (Коса страха) |
| Rarity | **Secret** |
| Level | 2 |
| Enchants | Attack Speed II, Tiny II |
| Damage boost | **−20%** (negative line) |
| Power boost | **−20%** |
| Attack speed | **+67.5%** |
| Speed boost | **+30%** |
| Power (Сила) | **47Ud** |
| Sell | **24.1Uvg** |

Implication: **Secret** can be **specialist** (speed over raw power), not always best DPS. Dual-wield / AS builds matter.

## Secret pet (mid-late loc band)

| Field | Example |
|-------|---------|
| Name | Asmodeus (Асмодей) |
| Rarity | **Secret** |
| Level | 2 |
| Enchants | Tiny II, Deity I |
| Attack speed | **+3%** |
| Pet power boost | **+20%** |
| Hunger / hunger lvl | 0 / 0 |
| Power (Мощь) | **×3.845** |

Implication: Secret pets can be **modest raw mult** but carry **unique enchants** (pet power %, AS). Not always the biggest ×N on the team.

## Loc band mobs (~fire / abyss tier, mid-late)

### T3-ish — Lucifer (Люцифер)

| Field | Value |
|-------|--------|
| Spawn | Always |
| HP | **22.59 Out** |
| Coin drop | **15.2 Dvg** |
| Kill time (strong kit) | **~48 s** |
| Drop example | Legendary **Sword of Fiery Passion** — power **58.24 Ud**, sell **8.69 Dvg**, **0.217%** |

Drop weights (row): ~3.8% · 0.92% · 0.51% · **0.22%** (leg) · **0.016%** · 0% (secret empty slot)

### T4-ish — elite of same loc (higher weapon tier)

| Field | Value |
|-------|--------|
| Kill time | ~**48 s** (same inspect band) |
| Drop example | Mythic **Staff of Fire Triumph** — power **203.89 Ud**, sell **13.99 Dvg**, **~0.016%** |

**Read:** T4 loot **Сила ~3–4×** legendary on T3; odds for top row stay **tiny**. TTK ~45–60s for “hard” open-world mob on a geared mid-late account.

### Earlier mid mob (for scale) — Grimlock band

| Field | Value |
|-------|--------|
| HP | **3.22 Unt** |
| Coins | **21.1 Vg** |
| TTK | **~13 s** |
| Rare sword | **~40c** power |

TTK jumps **13s → ~48s** between “easy open farm” and “loc hard tier” on same account class.

## Design lock

- Higher locations: better base loot, **harder** high-rarity odds (luck helps, does not erase loc tax).
- Hard dungeon = path to **mythic relics** with deep upgrade.
- Secret pets/weapons = **specialist** lines, not always pure max DPS.
- Quest UI labels: **Click / Case / Power Quester** (temp; real NPC names later).
