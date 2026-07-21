# Big number format (Cristalix-style)

Module: `ReplicatedStorage.Shared.NumberFormat`  
Client: `Format.Num` → same ladder.  
Server mob HP: `MobVisualService` uses `NumberFormat`.

## Why

Loc2 already hits **Billions** (Sailor 9M HP, Captain **4.75B**, coins 750K–46M).  
Late game (Loc25) needs **Qdt** (~10^48) and far beyond — not a hard cap at `Q` (10^15).

## Ladder (every ×1000)

| Tier | 10^ | Suffix | Example |
|------|-----|--------|---------|
| 1 | 3 | K | 1.5K |
| 2 | 6 | M | 9.0M |
| 3 | 9 | **B** | 4.75B |
| 4 | 12 | T | 1.2T |
| 5 | 15 | Qa | |
| 6 | 18 | Qi | |
| 7–10 | 21–30 | Sx Sp Oc No | |
| 11–14 | 33–42 | Dc Ud Dd Td | |
| 15 | 45 | Qd | |
| **16** | **48** | **Qdt** | Loc25 band |
| 17+ | 51+ | Qn Sxd Spd … Vg … Ct … | |
| after named | … | aa, ab, ac… | until ~1e308 → ∞ |

## API

```lua
NumberFormat.Num(4.75e9)  --> "4.75B"
NumberFormat.Num(1.2e48) --> "1.2Qdt"
NumberFormat.Num(250)    --> "250"
```

Combat math stays raw `number` (double). This is **display only**.
