# CPS caps + upgrade cost formula + weapon levels

## CPS without purchased auto-clicker
| Rule | Value |
|------|--------|
| **Loc1** | **4 CPS** hard cap |
| **Whole game max** | **20 CPS** without purchase |
| Loc2… | 6, 8, 10… ramp in `ClickConfig.LOC_CPS_CAP` |
| With purchased auto | up to **50** (`MAX_CPS_PURCHASED`) |

Manual and auto share the same server rate limit.

## Power upgrade costs (dump L1–L9)
| Lv | Cost |
|----|------|
| 1 | 500 |
| 2 | 2_250 |
| 3 | 15_000 |
| 4 | 50_000 |
| 5 | 125_000 |
| 6 | **1_950_000** (1.95M) |
| 7 | **8_770_000** (8.77M) |
| 8 | **58_500_000** (58.5M) |
| 9 | **195_000_000** (195M) |

**L10+:** `Cost(n) = 195_000_000 × 3.33^(n − 9)`

Effect: **+5%** permanent power / level (global).

## Other upgrades
| Upgrade | Per level | Notes |
|---------|-----------|--------|
| Attack Speed | **+1%** | CPS (still clamped by loc CPS cap) |
| Backpack | **+1 slot** | **Each** bag: weapons / pets / items |
| Base bags | **32** | separate for swords, pets, items |
| Crit | +1% | **Locked until Loc3+** |
| Multi Crit | +1% multi on crit (×3 dmg) | **Locked until Loc3+** |

## Weapon levels (double-edged dump)
| Level | Strength if base 17 |
|-------|---------------------|
| L1 | 17 (= base × 1) |
| L2 | 34 (= base × 2) |
| L3 | 51 (= base × 3) |

`effectivePower = powerMult × level`  
Merge: 5×L1→L2, 3×L2→L3 (MMB).
