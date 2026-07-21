# Loc1 Pet Case — from dumps (`питомцы кейс 500`)

## Case price
**500 coins** — HUD: «Кейс с питомцами»

## Pets (chance + Мощь)

| Dump name | EN id name | Rarity | Chance % | Мощь | → powerPct | coinPct (soft) | sell |
|-----------|------------|--------|----------|------|------------|----------------|------|
| Древесник | Woodling P1_C1 | Common | **39.972** | x1.1 | +10% | +5% | 50 |
| Лурк | Lurk P1_C2 | Common | **29.979** | x1.2 | +20% | +8% | 80 |
| Лесной | Forestling P1_R1 | Rare | **15.02** | x1.35 | +35% | +12% | 150 |
| Геката | Hekata P1_R2 | Rare | **10.013** | x1.5 | +50% | +18% | 250 |
| Стико | Stiko P1_L1 | Legendary | **5.017** | x1.75 | +75% | +25% | 500 |

Sum of chances ≈ **100%**.

## Mapping
- reference game `Мощь xN` → `powerMult = N`, `powerPct = (N-1)*100` for Formulas.
- `coinPct` not on tooltips — small soft values scaled with power tier.
- Feed base cost **500** (Loc1 coin scale).
- Case: `CaseConfig.PET_COIN_COST = 500`, `PET_KEY_COST = 0`.

## Also in Loc1 dumps (not applied yet)
- **2йкейс 50K** — second coin pet case (Charon…Grommash) → `../loc1_case2_offhand/`
- **Донаткейс 49 keys** — premium pets (Nocturne…Freya) → `../loc1_case_donate/` (was mislabeled “relics”)
- swords already applied in LOC1_STATS.md
