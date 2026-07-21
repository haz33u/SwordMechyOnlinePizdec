# Auras + Relics balance (F2P 1–2 months / ~25 rungs)

## Goals

- Each **new location feels harder** — not one smooth formula; **combatWall jumps** (see Loc1→Loc2).
- **Weapons + pets + rebirth** carry the big leaps.
- **Auras** (1 equipped) + **relics** (2 free / 3 paid) are **% glue** so mid gaps are playable, not free clears.
- F2P: clear content in **~1–2 months** of regular play.
- Donate: 3rd relic slot (+ offhand, pet slot, auto, chests) → **faster**, not required.

## Auras (dump L1)

- Full catalog: `AuraConfig` + `docs/ref/cristalix/captures/auras_dump/`.
- **1 active** aura.
- **Upgrade** with coins → max **Lv10** (`LEVEL_STAT_BONUS = 12%` of base per level).
- Crit / multicrit from aura feed `Formulas.GetCritChance` / `GetMultiCritChance`.

Example L1 peak mythic: Bone Aura **+100% power +100% damage** (before level).

## Relics

| Mode | Equip slots |
|------|-------------|
| Free | **2** |
| Paid `relicSlot` gamepass | **3** |

Stars: +20% of base per star, max 5. Coin upgrade via `UpgradeRelic`.

Bands (designed, not Cristalix dump):

| Band | When | Example power% each (0★) |
|------|------|---------------------------|
| 1 | Loc1 / easy dungeon | 12–22 |
| 2 | Loc2 / medium | 28–55 |
| 3 | Loc3 / hard | 60–90 |
| 4 | Loc4+ | 110–130 |
| 5 | endgame rungs | 120–150 |

**2-slot free mid** ≈ 80–180% power pool before stars.  
**3-slot paid** ≈ ×1.5 that contribution.  
Soft budgets in `RelicConfig.BUDGET_POWER_SOFT_CAP`.

## Location walls (not flat scaling)

| Loc | combatWall (rec. power for ~2s T1) | Why hard |
|-----|-------------------------------------|----------|
| 1 | 250 | starter |
| 2 | 2e6 | Sailor 9M HP — gear wall |
| 3 | 8e7 | next step |
| 4 | 2e9 | late F2P |

Future Loc5–25: set **new** `combatWall` each time (×4…×40-ish vs previous), keep dump HP absolute.

## Time budget (target, playtest)

| Phase | Real time F2P | What unlocks wall |
|-------|---------------|-------------------|
| Loc1 full + R2 | days 1–7 | weapons, pets, easy relics, aura L3–5 |
| Loc2 comfortable | weeks 2–4 | mid weapons, medium relics, better aura |
| Loc3–4 | weeks 4–8 | hard relics, mythic aura, rebirth |
| Rungs 5–25 | month 2 | band 4–5 relics, stars, paid optional |

Donate shortens by **slot + QoL**, not by skipping walls entirely.

## Remotes

| Remote | Action |
|--------|--------|
| `UpgradeAura` | coins → aura level+1 |
| `EquipRelic` / `UnequipRelic` | 2 or 3 slots |
| `UpgradeRelic` | coins → star+1 |

## Kill-time check (when tuning)

```
hits ≈ HP / (TotalPower × critAvg)
time ≈ hits / CPS
```

On **new loc entry** with previous-loc best gear: zone A should feel **slow/tough** (wall), not 0.1s.  
After farming that loc’s weapons/pets: zone A ~1–3s.
