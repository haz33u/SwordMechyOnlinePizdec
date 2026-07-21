# Rebirth ladder (60 ranks)

## Why 60, not 30?

| Goal | Math |
|------|------|
| ~2–3 rebirths per location × 25 locs | need **~50–75** ranks |
| **30** ranks | only ~**1.2** per loc average — cadence too thin |
| Power if keep old `×2.5` forever | R30 already ~**×1e12** rebirth alone — too spicy |

**Lock:** `MAX_LEVEL = 60` (~2.4 / loc). Mult growth **softens** after R3 (1.6 → 1.4 → 1.25).

---

## Can R30 reach Loc25 (with auras + pets)?

**Target wall** (design doc): Loc25 `combatWall` ≈ **1e48** (Qdt band).

### How power actually multiplies

```
TotalPower ≈ (BASE + lifetimePower)
  × rebirthMult
  × weaponMult          -- main + 0.5×offhand
  × petMult             -- see below
  × (1 + power%/100)    -- aura, relics, enchants, upgrades
  × (1 + damage%/100)
```

### Critical: pets are **additive**, not product

```
petMult = 1 + Σ (petPower×levelFactor − 1)   over equipped team
```

So **7× Triton (×290)** ≈ `1 + 7×289` ≈ **×2024**, **not** `290^7`.

Even max-fed Loc2 key mythics stay roughly **low thousands**, not 1e20.

### Ballpark at R30 (old ×2.5 curve ≈ ×1e12 rebirth)

| Setup | Approx TotalPower | vs Loc25 1e48 |
|-------|-------------------|---------------|
| R30 + mid Loc2 gear, weak pets | ~1e20–1e26 | **no** |
| R30 + best Loc1–2 pets (7 slots) + strong aura/relics + good sword | ~1e24–1e28 | **no** |
| R30 + **future** Loc15–25 weapons/pets (not in dump yet) | can be designed to reach | **yes, only with that content** |

### Soft mult curve (live config)

| Rank | ≈ rebirth mult |
|------|----------------|
| R3 | ×18 |
| R10 | ~×480 |
| R20 | ~×53k |
| R30 | ~×1.5M |
| R60 | ~×3.9B |

Even **R60** rebirth alone is only ~**×4e9**. Loc25 still needs **late weapons + pets** scaled with worlds.

### Honest answer

| Question | Answer |
|----------|--------|
| R30 + current Loc1–2 auras/pets → Loc25 comfortable? | **No** |
| R30 enough for **Loc2–4** with good pets/aura? | **Yes** (Loc2 wall is millions–billions, not Qdt) |
| When is Loc25 possible? | When Loc3–25 **weapon/pet ladders** exist and combatWalls are tuned together |
| Rebirth role | Cadence + strong **step** buff; **not** the whole climb to Qdt |

---

## Rank names (0–60)

See `RebirthConfig.RANK_NAME` — Ashborn → **The Unmade Law**.  
Styles: `GetRankStyle` bands Ash / Blood / Star / God / Abyss / End.

## UI

- Modal: full names + compact `×` mult  
- Inventory profile: `R# · RankName ×mult`  
- `Titles.PaintRank` for gradient/stroke labels  
