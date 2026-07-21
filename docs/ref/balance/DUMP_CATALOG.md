# balance dump catalog (player screenshots)

> Source folders (2026-07-19):  
> `C:\Users\thisi\Downloads\1я локация`  
> `C:\Users\thisi\Downloads\2я локаци я`  
> `C:\Users\thisi\Downloads\Эффекты`  
> Local copies: `docs/ref/balance/captures/`  
> **Effects: PARKED — know they exist, do not implement yet.**

---

## Folder map (source → captures)

### Loc1 — `1я локация`
| Source subfolder / file | Captures | Content |
|-------------------------|----------|---------|
| `Мечи статы1ЯЛОКА/` | `cap_01…`, `LOC1_STATS.md` | Loc1 weapons + mob inspects |
| `Питомцы кейс 500/` | `pets_loc1/` | Coin pet case **500** |
| `2йкейс1лока/` | `loc1_case2_offhand/` | Coin pet case **50K** (2nd case) |
| `Донаткейс1й лок/` | `loc1_case_donate/` (+ old `relics_loc1/`) | Key pet case **49** (premium) |
| Aura tooltips (player folder) | `auras_dump/` | Full aura L1 stats → `AuraConfig` |
| `1й ребитх .png` / `2й ребитх.png` | `REBIRTH.md` | R1 / R2 |
| `Переход на локу2.png` | `LOC2_GATE.md` | Loc2 unlock UI |

### Loc2 — `2я локаци я`
| Source subfolder / file | Captures | Content |
|-------------------------|----------|---------|
| `Мобы/` | `loc2_mobs/` | Sailor / Gunner / Captain |
| `Мечи2ялока/` | `loc2_weapons/` | Loc2 weapon catalog |
| `ОбычныйКейс2ялока/` | `loc2_case_pets/` | Coin pet case **3.75M** |
| `ДонатКейс2ялока/` | `loc2_case_donate/` | Key pet case **54** (premium) |
| `3й ребитх.png` | `REBIRTH.md` | R3 |
| `Квестовик.txt` | `loc2_notes.txt` | Click quests |

### Effects — `Эффекты` (**PARKED**)
| Source file | Captures | Status |
|-------------|----------|--------|
| `СолнечЗатмение.png` | `effects_parked/fx_01.png` | Document only |
| `Тьма.png` | `effects_parked/fx_02.png` | Document only |
| `Солнечный Удар.png` | `effects_parked/fx_03.png` | Document only |

---

## 0. Effects (PARKED — later)

Timed world modifiers. **Do not code until events/boosts sprint.**

| Effect | RU | Mechanics (tooltip) | Example timer |
|--------|-----|---------------------|---------------|
| **Solar Eclipse** | Солнечное затмение | Shorter mob spawn; enchanted swords can drop; enchanted pets can drop; chance weapon / pet / relic / aura **above level 1** | ~29m |
| **Darkness** | Тьма | Extra **Darkness** enemies; secret swords & pets possible | ~14m |
| **Solar Blast** | Солнечный взрыв | Power boost; mob HP **+30%**; case price **+30%**; higher drop odds; secret swords & pets possible | ~14m |

Wire later as world modifiers on spawn / loot / case cost / power.

---

## 1. Loc1

### Gate Loc1 → Loc2
- Starter Village: free **Teleport**
- Pirate Ship (Loc2): **Buy 500K** once + need **R2**

### Rebirth
| R | From → To | Damage need | Mult |
|---|-----------|-------------|------|
| 1 | Novice×1 → Beginner×3 | **75K** | ×3 |
| 2 | Beginner×3 → Amateur×7 | **2.5M** | ×7 |
| 3 | Amateur×7 → Strong×18 | **87.5M** | ×18 |

After rebirth: wipe coins + lifetime damage progress; weapons/pets stay. ETA = ideal time with current gear.

### Weapons Loc1 (strength / sell)
| Name | id (code) | Rarity | Сила | Sell |
|------|-----------|--------|------|------|
| Starter Weapon | `starter_weapon` | Common | 1 | 10 |
| Old Sword | `old_sword` | Common | 2 | 40 |
| Bone Dagger | `bone_dagger` | Common | 3 | 50 |
| Wooden Mace | `wooden_mace` | Rare | 10 | 150 |
| Double-edged Sword | `double_edged_sword` | Epic | 17 | 200 |
| Forest Spirit Staff | `forest_spirit_staff` | Epic | 28 | 250 |
| Ardite | `ardite` | Legendary | 50 | 500 |
| Forest Sword | `forest_sword` | Mythic | 125 | 1K |
| Forest Shadow | `forest_shadow` | Secret | 150 | 1.5K |

> Internal ids are **readable slugs** (not `W1_U2`). Old codes migrate via `WeaponConfig.LegacyIdMap`.

Levels: L1/L2/L3 = strength **×1 / ×2 / ×3** (17→34→51). Merge **5×L1→L2**, **3×L2→L3** (MMB).

### Pets Loc1 — coin case **500** (`Питомцы кейс 500`)
| Pet | Rarity | % | Мощь |
|-----|--------|---|------|
| Woodling (Древесник) | Common | 39.972 | ×1.1 |
| Lurk (Лурк) | Common | 29.979 | ×1.2 |
| Forestling (Лесной) | Rare | 15.02 | ×1.35 |
| Hekata (Геката) | Rare | 10.013 | ×1.5 |
| Stiko (Стико) | Legendary | 5.017 | ×1.75 |

Sum ≈ 100%. `Мощь xN` → `powerPct = (N−1)×100`.

### Pets Loc1 — coin case **50K** (`2йкейс1лока`) — **not coded**
| Pet | Rarity | % | Мощь |
|-----|--------|---|------|
| Charon (Харон) | Rare | 39.996 | ×1.75 |
| Morpheus (Морфей) | Rare | 29.997 | ×2.5 |
| Torn (Торн) | Epic | 14.999 | ×3.33 |
| Nifel (Нифель) | Epic | 9.999 | ×4.5 |
| Nightmare (Кошмарик) | Legendary | 4.008 | ×6 |
| Grommash (Громмаш) | Mythic | 1.002 | ×8 |

Sum ≈ 100%. (Previously mislabeled as “offhand” — this is a **second pet case**, not offhand weapons.)

### Pets Loc1 — key case **49** (`Донаткейс1й лок`) — **not coded**
| Pet | Rarity | % | Мощь |
|-----|--------|---|------|
| Nocturne (Ноктюрн) | Rare | 43.995 | ×14.5 |
| Moron (Морон) | Epic | 34.996 | ×18.85 |
| Heka (Хека) | Legendary | 14.998 | ×31.9 |
| Monster (Чудовище) | Legendary | 5.009 | ×50.75 |
| Freya (Фрея) | Mythic | 1.002 | ×72.5 |

Sum = 100%. (Same pool as old `relics_loc1/` — these are **premium pets**, not separate relic shop rows.)

### Loc1 mobs (spawn counts + tiers)
| Tier | Count | Examples | Notes |
|------|-------|----------|--------|
| T1 | 13 | Goblin 1K HP / 200 coins | |
| T2 | 15 | Skeleton / Wolf | |
| T3 | 11 | Dark Goblin / Goblin-warrior | Dump warrior **5.68M HP / 100K coins** (older sheet had 18K — both recorded) |
| T4 | 9 | Scout 300K + Elite | Secret **0.0001%** |
| Boss | 1 | Guardian 1.2M | |

**Live roster (code):** see `docs/MOB_ROSTER.md` — dump ids only; Runner filler → Spare; melee range 10 studs.

### Other Loc1 systems (from HUD dumps, applied)
- Loc1 CPS cap **4** without auto purchase; game max **20** without purchase
- Bags base **32** each (weapons / pets / items), +1 per backpack level
- Crit / MultiCrit locked until Loc3+
- Power upgrade L1–L9 costs in `CPS_AND_UPGRADES.md`

---

## 2. Loc2 — Pirate Ship

### Unlock
- **R2** + **500K coins** once

### Rebirth R3 (on Loc2 folder)
- Amateur ×7 → Strong ×18  
- Need **87.5M** damage  
- ETA example ~43m  

### Quests (`Квестовик.txt` / `loc2_notes.txt`)
> All quests start only after you **accept** them.

| # | Goal | Reward |
|---|------|--------|
| 1 | **100 clicks** | **+1M coins** |
| 2 | **500 clicks** | **+40% attack speed** (treat as permanent until proven otherwise) |

### Mobs Loc2 (`Мобы/`)
| Mob | HP | Coins | Kill time (their gear) | Drop table (approx) |
|-----|-----|-------|------------------------|---------------------|
| **Матрос** Sailor | **9M** | **750K** | ~4s | Hook 54.998 / Hammer 34.999 / Saber 8 / Gold 2.004 |
| **Канонир** Gunner | **70.64M** | **5.77M** | ~10s | Hook 18.182 / Hammer 36.363 / Saber 31.818 / Gold 10.454 / Axe 2.727 / Element 0.456 |
| **Капитан** Captain | **4.75B** | **46.4M** | ~3m 11s | Hook 2.997 / Hammer 21.98 / Saber 29.973 / Gold 26.976 / Axe 13.388 / Element 3.996 / Emerald 0.59 / Sea 0.1 |

### Weapons Loc2 (`Мечи2ялока/`)
| Name | RU | Rarity | % (catalog) | Сила | Sell |
|------|-----|--------|-------------|------|------|
| Pirate Hook | Пиратский крюк | Common | 54.998 | **50** | 50K |
| Pirate Hammer | Пиратский молот | Common | 34.999 | **100** | 100K |
| Pirate Saber | Пиратская сабля | Common | 8 | **150** | 250K |
| Golden-plated Sword | Златоплетный меч | Rare | 2.004 | **300** | 500K |
| Captain Axe | Топор капитана | Rare | 2.727 | **500** | 1M |
| Element Blade | Лезвие стихий | Epic | 0.456 | **800** | 25M |
| Emerald Blade | Изумрудный клинок | Epic | 0.59 | **1.5K** | 50M |
| Sea Dagger | Морской кинжал | Legendary | 0.1 | **4.25K** | 120M |

Scale: Loc2 strength 50–4250 vs Loc1 1–150.  
Note: % on weapon tooltips = **example drop chance** from a table, not a single global pool (mob tables differ).

### Pets Loc2 — coin case **3.75M** (`ОбычныйКейс2ялока/`)
| Pet | Rarity | % | Мощь |
|-----|--------|---|------|
| Proteus (Протей) | Common | 44.995 | ×4.5 |
| Atlas (Атлант) | Common | 34.999 | ×6.75 |
| Hermes (Гермес) | Rare | 14 | ×12 |
| Arix (Арикс) | Epic | 4.87 | ×18 |
| Ceres (Церера) | Legendary | 1.002 | ×31 |
| Nereus (Нереус) | Mythic | 0.1303 | ×89.9 |

Sum ≈ 100%.

### Pets Loc2 — key case **54** (`ДонатКейс2ялока/`, file `Платныйкейс54робукса.png`) — **not coded**
| Pet | Rarity | % | Мощь |
|-----|--------|---|------|
| Eridan (Эридан) | Rare | 43.995 | ×50.75 |
| Calypso (Калипса) | Epic | 34.996 | ×65.25 |
| Argus (Аргус) | Legendary | 14.998 | ×100.05 |
| Nereid (Нереид) | Legendary | 5.009 | ×150.8 |
| Triton (Тритон) | Mythic | 1.002 | ×290 |

Sum = 100%. (Previously listed as “pets alt set” — this is the **premium key case**, not the coin pool.)

---

## 3. Status vs our code (2026-07-19 dump-only pass)

| Content | In dumps | In game code |
|---------|----------|--------------|
| Loc1 weapons (9, pure Сила) | ✅ | ✅ **only these, no fillers** |
| Loc2 weapons (8, pure Сила) | ✅ | ✅ **exact sell + strength** |
| Loc1 pets 500 / 50K / 49 keys | ✅ | ✅ all pools in PetConfig |
| Loc2 pets 3.75M / 54 keys | ✅ | ✅ |
| Loc1 mobs HP/coins | ✅ | ✅ warrior **5.68M/100K** |
| Loc2 mobs + exact drop % | ✅ | ✅ Sailor/Gunner/Captain |
| Combat math | — | **Сила + Мощь pure mults** (no % for weapons/pets) |
| Loc2 click quests | ✅ | ⚠️ notes only |
| **World effects** | ✅ | **PARKED** |
| Loc3/Loc4 weapons/mobs | — | **removed** (no dump) |

---

## 4. When implementing later

### Loc2 (gameplay next)
1. `MobConfig` L2_Sailor / L2_Gunner / L2_Captain — dump HP/coins + drop tables  
2. `WeaponConfig` Loc2 catalog absolute Сила + sell  
3. `PetConfig` Loc2 coin pool + CaseConfig open cost **3.75M**  
4. Quest types: `clicks` 100 / 500 → coins / attackSpeedPct  
5. Optional: Loc2 key case 54 (donate)

### Loc1 remaining cases
1. Pet case **50K** pool (Charon → Grommash)  
2. Pet key case **49** pool (Nocturne → Freya)

### Effects (after boosts system)
World event service: spawn rate, enchanted loot, HP+30%, case+30%, secret chance, Darkness extra spawns.

---

## 5. Capture tree (this inventory)

```
captures/
  LOC1_STATS.md, LOC1_PETS.md, REBIRTH.md, LOC2_GATE.md, CPS_AND_UPGRADES.md
  pets_loc1/          # 500 coin pets
  loc1_case2_offhand/ # 50K coin pets (name legacy)
  loc1_case_donate/   # 49 key pets
  relics_loc1/        # same premium pets (legacy name)
  offhand_loc1/       # same as case2 (legacy name)
  loc2_mobs/
  loc2_weapons/
  loc2_case_pets/     # 3.75M coin pets
  loc2_case_donate/   # 54 key pets
  loc2_notes.txt
  effects_parked/     # PARKED only
```

---

*Last full inventory: 2026-07-19 — all three Downloads folders re-read; effects parked only.*
