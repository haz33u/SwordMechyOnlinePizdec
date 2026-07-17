# Мечи, редкости, дроп (все локации)

> **Статус цифр:** реконструкция / скелет под Cristalix-like loop.  
> Не HUD-дамп Cristalix. Тюнить: `WeaponConfig.LOCATION_BASE`, `RARITY_REL`, `LocationProgression`, `TierRarityWeights`.

---

## Философия

| Цель | Как |
|------|-----|
| Loc1 простая | `dropChanceMult=1`, `highRarityMult=1`, малые mult |
| Дальше дольше | каждый loc режет общий шанс и **Epic+** веса |
| Меч = уровень локации | каталог `location` + roll только с этой локации |
| Гнаться за топом | Mythic / Secret / Limited — flex, не «обязательный старт» |
| SAO / иконки | стабильные `id` + `iconKey` → NN-иконки позже |
| LIMITED | **не** с мобов; VFX showcase (`vfxProfile`) |

---

## Лестница редкостей

```
Common → Uncommon → Rare → Epic → Legendary → Mythic → Secret → Limited
```

| Rarity | Откуда | Роль |
|--------|--------|------|
| Common–Rare | trash / normal | фарм, ban-list мусора |
| Epic–Legendary | normal+ / elite / boss | основной прогресс локации |
| Mythic | elite (редко) / boss | chase |
| Secret | elite (крохи) / boss | lottery flex (как Secret на Cristalix) |
| **Limited** | ивент / сезон / спец-выдача | **не дроп** + красивые эффекты |

Цвета UI: `StarterPlayerScripts/Rarity.lua` (Limited = hot pink).

---

## Формула силы меча

```
powerMult ≈ LOCATION_BASE[loc] × RARITY_REL[rarity][variant]
sellPrice ≈ floor(powerMult × 45 × (1 + 0.35×(loc-1)))
```

### LOCATION_BASE (mid Common)

| Loc | База | Тема | Ощущение |
|-----|------|------|----------|
| 1 | 1.10 | Тёмный лес | лёгкий онбординг |
| 2 | 4.40 | Пиратский берег | ~4× |
| 3 | 19.0 | Земли шиноби | ~4.3× |
| 4 | 95.0 | Полярная тундра | ~5× |
| 5+ | `prev × (4.2 + 0.3×(n-1))` | шаблон | ещё жёстче |

### RARITY_REL (внутри локации)

| Rarity | Variant A | Variant B |
|--------|-----------|-----------|
| Common | 0.95 | 1.08 |
| Uncommon | 1.30 | 1.48 |
| Rare | 1.90 | 2.25 |
| Epic | 3.15 | 3.85 |
| Legendary | 5.40 | 6.70 |
| Mythic | 9.80 | 12.20 |
| Secret | 17.5 | 21.5 |
| Limited | 28.0 | — |

### Ориентир powerMult (после округления)

| Loc | C | U | R | E | L | M | S | Limited |
|-----|---|---|---|---|---|---|---|---------|
| 1 | ~1.05–1.19 | ~1.43–1.63 | ~2.1–2.5 | ~3.5–4.2 | ~5.9–7.4 | ~10.8–13.4 | ~19–24 | ~31 |
| 2 | ~4.2–4.8 | ~5.7–6.5 | ~8.4–9.9 | ~14–17 | ~24–29 | ~43–54 | ~77–95 | ~123 |
| 3 | ~18–21 | ~25–28 | ~36–43 | ~60–73 | ~103–127 | ~186–232 | ~333–409 | ~532 |
| 4 | ~90–103 | ~124–141 | ~181–214 | ~299–366 | ~513–637 | ~931–1159 | ~1663–2043 | ~2660 |

**Сшивка локаций:** лучший Secret Loc(N) конкурирует с mid–high Loc(N+1), но **не** заменяет топ следующей локации. Игрок *хочет* идти дальше.

---

## Дроп с моба

```
chance = TierDropChance[tier]
       × LocationProgression[loc].dropChanceMult
       × weaponDropScale          -- опционально с моба
       × (1 + luck)
       clamp ≤ 0.92

if roll OK:
  rarity = weighted(TierRarityWeights[tier] with highRarityMult on Epic+)
  weapon = random from catalog[loc][rarity] − banned − dropDisabled
```

### Базовый шанс (до luck / loc)

| Tier | Chance |
|------|--------|
| trash | 4.5% |
| normal | 7.5% |
| elite | 13% |
| boss | 48% |
| debug | 0 |

### LocationProgression (дольше на дальних)

| Loc | dropChanceMult | highRarityMult (Epic+) | timeHint |
|-----|----------------|------------------------|----------|
| 1 | 1.00 | 1.00 | easy 15–45 min до solid Rare/Epic |
| 2 | 0.82 | 0.62 | medium — Legend+ дольше |
| 3 | 0.68 | 0.40 | long — Mythic chase |
| 4 | 0.55 | 0.26 | very long — Secret flex |
| 5+ | формула в `GetLocationProgression` | ещё жёстче | extended |

### Веса редкости (до highRarity squeeze)

**trash:** C 74 / U 22 / R 4  

**normal:** C 32 / U 34 / R 24 / E 8.5 / L 1.5  

**elite:** U 18 / R 36 / E 28 / L 13 / M 4 / S 1  

**boss:** R 18 / E 30 / L 32 / M 14 / S 6  

Limited **нет** в таблицах.

### Expected value (ориентир, luck=0)

| Событие | Loc1 | Loc4 (жёстче) |
|---------|------|----------------|
| Любой дроп с trash | ~22 килла | ~40 киллов |
| Rare с trash | ~550 | ~1000+ |
| Secret с boss (EV) | ~30–40 киллов босса | ~90–120 киллов босса |

Точные числа — Monte-Carlo при плейтесте; таблицы выше — старт.

---

## Каталог (id → для иконок)

Паттерн id: `W{loc}_{rarityCode}{n}`

| Code | Rarity |
|------|--------|
| C | Common |
| U | Uncommon |
| R | Rare |
| E | Epic |
| L | Legendary |
| M | Mythic |
| S | Secret |
| X | Limited |

На каждую из Loc1–4: **2** меча C/U/R/E/L/M/S + **1** Limited = **15** мечей × 4 = **60**.

Примеры Loc1:

| id | Имя | Rarity |
|----|-----|--------|
| W1_C1 | Ржавый клинок | Common |
| W1_U1 | Клинок разбойника | Uncommon |
| W1_R1 | Меч теней | Rare |
| W1_E1 | Клинок Хранителя | Epic |
| W1_L1 | Перворождённый | Legendary |
| W1_M1 | Тень Прародителя | Mythic |
| W1_S1 | Эхо Древнего Леса | Secret |
| W1_X1 | Арк Лесного Рассвета | Limited |

Полный список: `WeaponConfig.Weapons` / `GetPublicCatalog()`.

### Поля для арта / VFX

```lua
iconKey = "W1_S1"           -- ключ для NN-иконки
vfxProfile = "secret_glow"  -- Secret
vfxProfile = "limited_forest_dawn" -- Limited
dropDisabled = true         -- Limited
```

---

## Инвентарь (уже в backend)

| Фича | Статус |
|------|--------|
| `profile.weapons[]` uid/id/enchants | ✅ |
| Main + Offhand (50%) | ✅ |
| Sell / Enchant / BanDrop | ✅ |
| Auto-equip if better mult | ✅ |
| Стартовый `W1_C1` | ✅ |

API: `EquipWeapon`, `SellWeapon`, `EnchantWeapon`, `BanDrop` — см. `BACKEND_API.md`.

---

## Код

| Файл | Роль |
|------|------|
| `Config/WeaponConfig.lua` | каталог, rarity, progression, roll API |
| `Services/LootService.lua` | дроп на килле |
| `Services/WeaponService.lua` | экип/продажа/чары/бан |
| `Config/MobConfig.lua` | tier + `weaponDropScale`, pool allowlist |
| `Rarity.lua` (client) | цвета UI |

### Моб

```lua
weaponDropChance = 1  -- 0 = выкл; иначе template
weaponDropScale = 1.2 -- опционально
weaponPool = {}       -- пусто = весь каталог локации; иначе allowlist id
```

---

## Как добавить Loc5+

1. `WorldConfig.Locations` + meta unlockPower  
2. `WeaponConfig.LOCATION_BASE[5] = 95 * 5.5` (пример)  
3. 15 `add("W5_...", ...)` тематических имён  
4. `LocationProgression` можно не писать — сработает fallback  
5. Мобы tier trash→boss с `location = 5`  

---

## Limited pipeline (позже)

1. Выдача: квест / сезон / админ remote / кейс ивента  
2. Клиент: по `vfxProfile` — trail, bloom, particles  
3. UI: цвет Limited + бейдж «LIMITED»  
4. **Никогда** не класть Limited в `TierRarityWeights`
