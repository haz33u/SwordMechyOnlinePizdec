# Rebirth dumps (Loc1)

## R1 — `1й ребитх .png`
| Field | Value |
|-------|--------|
| From | Novice **×1** |
| To | Beginner **×3** |
| Progress | **75K** (shown 76.81K/75K ready) |
| ETA | **0s** |

## R2 — `2й ребитх.png`
| Field | Value |
|-------|--------|
| From | Beginner **×3** |
| To | Amateur **×7** |
| Progress | **2.5M** (1.29M/2.5M) |
| ETA | **~24m 7s** (ideal click, current gear) |

## R3 — `2я локация/3й ребитх.png`
| Field | Value |
|-------|--------|
| From | Amateur **×7** |
| To | Strong **×18** (Сильный) |
| Progress | **87.5M** (25.2K/87.5M) |
| ETA | **~43m 24s** |

## Rules
- One bar = damage dealt toward next rebirth
- After rebirth: **damage progress + coin balance wiped**
- Weapons / pets stay
- Right-side ETA = time if player always clicks with current power×CPS (crit averaged)

## Our config (`RebirthConfig`)
- DAMAGE_COST[1]=75000, [2]=2500000
- RANK_MULT 1 → 3 → 7
- COIN_COST 0 (requirement); WIPE_COINS_ON_REBIRTH = true
- `Formulas.EstimateRebirthEta` → `stats.rebirthEtaSeconds`
