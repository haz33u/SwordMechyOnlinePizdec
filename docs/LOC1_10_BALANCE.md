# Loc 1–10 balance lock (approx ±)

**Status:** systems live; Loc1–2 combat numbers from dumps; Loc3–10 **gates + combatWall locked** here / `WorldConfig`. Full mob/weapon tables for 3–10 = art pass next.

---

## 1. Systems inventory (what we have)

| System | State | Notes |
|--------|--------|--------|
| Combat / CPS | LIVE | Free **20** via Click Quester; Loc1 **4**; donat **50** |
| Click Quester | LIVE | 21 steps, step3=5K, step15=**75M**, step21=**2B** + credit |
| Case Quester | LIVE | Pet cases, step5=10K→+pet slot, step13=1M, step14=**2.5M**, luck |
| Power Quester | LIVE | Kill any, step7=50K, permanent +% power |
| Rebirth | LIVE | **60** ranks, soft mult curve, hard EN names |
| Relics | LIVE skeleton | 2 free / 3 paid slots; dungeon mythic can be huge (see anchors) |
| Auras | LIVE | 34 dump L1 + upgrade |
| Pets / weapons | LIVE Loc1–2 | Loc3+ tables still stub |
| Anomalies | LIVE | 35m cycle, coin/power/spawn/drop |
| Worlds | **10** in WorldConfig | 11–25 later |
| Dungeons | LIVE skeleton | AFK timer; real fight later |

### Quest UI labels (temp)

| Label | Role |
|-------|------|
| **Click Quester** | CPS |
| **Case Quester** | Cases → luck / pet slot |
| **Power Quester** | Kills → power % |

---

## 2. Live ref updates (screenshots)

| Track | Step | Amount on UI | We use |
|-------|------|--------------|--------|
| Clicks | 15/21 | 56M / **75M** | `75_000_000` |
| Cases | 14/21 | 103K / **2.5M** | `2_500_000` |

### Relic — Miner’s Ring (Rare)

| Field | Value |
|-------|--------|
| Rarity | Rare |
| Level | 1 |
| Damage boost | **13.4K%** |
| Source | **Hard dungeon stage 24** |

→ Hard dungeon deep stages still drop **usable mid relics**, not only endgame mythics. Mythic forester L42 / 87K% remains the high bar.

### Secret pet / mobs (fire loc band)

See `docs/ref/balance/GEAR_ANCHORS.md` — Asmodeus secret pet; Lucifer ~48s TTK; mythic staff 0.016%.

---

## 3. Loc 1–10 gates (LOCKED approx)

| Loc | Name | unlock R | Travel cost | combatWall | T1 TTK target* |
|-----|------|----------|-------------|------------|----------------|
| 1 | Goblin City | 0 | 0 | **250** | ~1–3 s starter |
| 2 | Pirate Ship | **2** | **500K** | **2M** | ~2–5 s after kit |
| 3 | Shinobi Lands | 4 | 5M | **80M** | ~2–5 s |
| 4 | Polar Tundra | 6 | 50M | **2B** | ~2–5 s |
| 5 | Ash Canyons | 8 | 500M | **50B** | ~2–5 s |
| 6 | Neon Docks | 10 | 5B | **1.2T** | ~2–5 s |
| 7 | Bone Cathedral | 12 | 50B | **30T** | ~3–8 s (soft wall start) |
| 8 | Storm Spire | 14 | 500B | **800T** | ~3–8 s |
| 9 | Mirror Marshes | 16 | 5T | **20Qa** | ~5–12 s |
| 10 | Obsidian Gate | 18 | 50T | **500Qa** | ~5–15 s |

\*TTK for **on-band** player (pets+weapon of that loc, Click/Power questers mid).  
Full donat mid-late (Loc18 ref) used **~13s easy / ~48s hard** open-world — we use **softer** targets on Loc1–10 for F2P feel.

**Rebirth density:** ~**2 ranks per location** through Loc10 (R0→R18) → matches “2–3 per loc” toward 25 with room to R60.

---

## 4. Mob HP recipe (for when you place final mobs)

Given `combatWall` W and target hits H at ~CPS C:

```
HP_T1 ≈ W × (1.0 … 1.5)     -- zone A, ~1–3s at C≈4–8 early / higher later
HP_T2 ≈ HP_T1 × 6…10
HP_T3 ≈ HP_T1 × 40…80       -- Loc1 warrior is spiky dump; later smoother
HP_T4 ≈ HP_T1 × 200…400
HP_Boss ≈ HP_T1 × 80…150
```

**Coins:** scale so ~**30–90s of farm** pays a meaningful fraction of **next travelCost** (not full price in 1 minute).

**Drops:** top rarity **≤1%**, secret **≪0.1%**; higher loc = **tighter** odds even with Case Quester luck.

---

## 5. Can we “finally approve” Loc1–10?

| Piece | Final? | Confidence |
|-------|--------|------------|
| CPS path (4→20 free / 50 donat) | **Yes** | High |
| 3 long quests | **Yes** (amounts tunable) | High |
| Rebirth 60 + names | **Yes** | High |
| Loc1–2 HP/coins/weapons/pets | **Yes** (dump) | High |
| Loc3–10 combatWall + R + travel | **Yes** + `SCALE_LOCS.md` | Medium–high |
| Loc3 mobs T-scale (B→T) | **LIVE stubs** | Playtest ±×2 |
| Loc3–10 final mob/weapon/pet IDs | **No** — need art + drop tables | Stub |
| Relic full mythic curve | Skeleton only | Medium (anchors known) |
| Real dungeon stages 1–24 | Skeleton | Low–medium |

**Verdict:**  
**Loc1–10 progression skeleton is solid enough to treat as locked** for gates, CPS, quests, rebirth, walls.  
**Final mobs** for 3–10 can be filled using the HP recipe without rewriting systems.  
Loc11–25 wait until Loc1–10 playtest feels right.

---

## 6. Player path (F2P sketch Loc1–10)

```
Loc1: learn combat, Sam not yet (CPS 4), Power/Case questers start
  → R1–R2, 500K → Loc2
Loc2: Click Quester opens (CPS 6↑), pirate dump farm
  → R3–R4, 5M → Loc3
Loc3–6: walls ×~25–40/step, pets/weapons of each loc, quests mid-chain
Loc7–10: soft walls, Click toward 15–20 CPS, Case luck, Power % stack
  → R18-ish at Obsidian Gate → late worlds
```

Donat: auto 50 CPS, 3 relics, offhand, multi-case → **faster**, same walls.

---

## 7. Next build priorities (after this lock)

1. Playtest Loc1–2 kill times + quest progress  
2. Fill Loc3 mob stubs (4 tiers + boss) from HP recipe  
3. Weapon/pet catalog Loc3–5  
4. Hard dungeon stages → real relic XP  
5. Multi-open cases → Case Quester count ×3/×5  
