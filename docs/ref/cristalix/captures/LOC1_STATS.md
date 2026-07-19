# Loc1 stats from Cristalix dumps (player folder «Мечи статы»)

Source images copied as `cap_01`…`cap_12`. Applied in game `0.5.6-loc1-cristalix-stats`.

## Weapons (tooltip)

| Name | Rarity | Сила (powerMult) | Sell | Our id |
|------|--------|------------------|------|--------|
| Starter Weapon | Common | 1 | 10 | W1_C1 |
| Old Sword | Common | 2 | 40 | W1_C2 |
| Bone Dagger | Common | 3 | 50 | W1_C3 |
| Wooden Mace | Rare | 10 | 150 | W1_R1 |
| Double-Edged Sword | Epic | 17 | 200 | W1_E1 |
| Forest Spirit Staff | Epic | 28 | 250 | W1_E2 |
| Ardite | Legendary | 50 | 500 | W1_L1 |
| Forest Sword | Mythic | 125 | 1000 | W1_M1 |
| Forest Shadow | Secret | 150 | 1500 | W1_S1 |

Extra Loc1 fillers (not on screenshots): U1/U2, R2, L2, M2, S2, X1 Limited.

## Mobs (inspect) + spawn counts

| Tier | Count | Dump / role | HP | Coins | Our ids |
|------|-------|-------------|-----|-------|---------|
| **T1** simple | **13** | Goblin | 1K | 200 | L1_Slime 7 + Runner 6 |
| **T2** medium | **15** | mid | 8–12K | 0.8–1.2K | Skeleton 8 + Wolf 7 |
| **T3** hard | **11** | Dark Goblin | 18K | 1.5K | L1_GoblinWarrior ×11 |
| **T4** elite | **9** | Scout + Warden | 300–450K | 12.5–18K | Knight 5 + Elite 4 |
| Boss | 1 | Guardian | 1.2M | 25K | L1_Boss |

### T4 Secret drop
`Secret = 0.0001%` on elite table (UI may show `0.0001%` / ≈0).

### Loc2 gate
- **Rebirth ≥ 2** + **500K coins** (one-time).

## Our math

```
TotalPower ≈ (BASE_POWER + lifetimePower) × weaponMult × rebirth × (1+%)
BASE_POWER = 250
weaponMult = Cristalix «Сила» on main (+ 0.5× offhand if unlocked)
dmg/hit avg = power × (1 − crit + 2×crit)
hits = ceil(HP / (dmg − armor))
seconds = hits / CPS
```

Starter: ~250 power → Goblin 1K ≈ 4 hits ≈ 2s at 2 CPS (matches dump vibe).

## Inspect UI

Shift+RMB shows: your sword strength, power, CPS, dmg/hit, **hits + kill time**.
