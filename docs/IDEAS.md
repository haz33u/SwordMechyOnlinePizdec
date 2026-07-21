# Ideas backlog (not scheduled)

Capture product ideas here so they are not lost. Implementation only when picked as a sprint.

---

## Progression walls (accepted direction)

- Each location uses **stepped `combatWall`**, not one smooth formula.
- Loc1→2 = huge spike; later ~×20–40 wall steps; Loc25 ≈ **Qdt** power band.
- **Pets + offhand** are late-game engines. Aura + 2 relics (F2P) glue mid-game.
- Soft wall: **no pets / no offhand → Loc15–16 very hard** even with paid aura/relic slots.
- Full table: `docs/PROGRESSION_EVENTS.md`.
- **Rebirth:** **60** ranks (~2.4/loc); hard EN names + styles — `docs/REBIRTH_LADDER.md`.
- **R30 ≠ free Loc25** under current Loc1–2 pet tables (additive pets).

---

## Anomalies (global timed events)

**Status: LIVE** — Pool A + Blood Moon / Miser / Glass.

- Prod: every **35 min**, active **10 min**.
- DEBUG: first ~45s, then 60s active / 3 min cycle.
- HUD banner + boost pills; Formulas/loot/respawn hooked.
- Parked skins later: Eclipse / Darkness / Blast (`effects_parked`).

---

## Daily Rift Herald (parked)

- Daily boss; rewards by **damage contribution tiers** (not only kill).
- Loot: enchant dust/shards, potions, sword chance, keys.
- HP scales to player `combatWall`.
- Weekly visual theme / one mutator.

---

## Potions (parked — icons only today)

- **Icons only:** `PotionIconConfig` — Coin / Damage / Luck / Power × Small|Mid|Big|Globall.
- **No** `PotionConfig` stats, inventory stack, use remote, or duration logic yet.
- When built: consumables → `profile.boosts` (local scope) stacking with global anomalies.

---

## Quest NPCs (compact number)

| NPC | Chain | Status |
|-----|-------|--------|
| **Click Quester** (ids `sam`) | 21 click quests → CPS 6–20 | LIVE |
| **Case Quester** (ids `frost`) | 21 pet-case opens → luck + pet slot @ 10K | LIVE |
| **Power Quester** (ids `grim`) | 21 kill-any → permanent +% Power (50K @ step 7) | LIVE |

Display names are temporary; replace with real NPC names later.

**Balance lock:** case-open **luck** rises with Frost, but **each new location still makes good weapon/pet rolls harder** (loc rarity squeeze). Luck softens grind; it does not flatten LocN loot.

**Grim** pushes **spawn rate** value (Swarm anomaly / future paid fast respawn).

**Multi-open:** x3/x5 gamepass should count **3/5** progress per request when multi-open ships.

## Other diversifiers (parked)

| Idea | Note |
|------|------|
| Potion belt | After potion data model |
| Weekly contracts | Kill N / Herald damage |
| Kill streak mult | Clicker skill expression |
| Aura tower | Floors for aura XP |
| Mutator weekend | Challenge rules + title |
| Location “hot day” | Single loc coin ×2 |
| Multi case open wiring | openChest3/5 → `OnCaseOpen(..., n)` |

---

## Build order (when resuming)

1. ~~Anomalies Pool A~~ (this sprint if coded)
2. Daily Herald
3. PotionConfig + use
4. Eclipse/Darkness/Blast as anomaly skins
