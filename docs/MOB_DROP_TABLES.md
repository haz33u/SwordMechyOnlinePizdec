# Таблицы дропа мобов (по скринам reference game)

Источник: HUD «Возможная награда» (mob1 / mob2 / mob3) — **проценты на килл, сумма ≈ 100%**  
→ в нашем порте: **1 меч за убийство**, редкость по весам; Limited **не** падает.

---

## 3 типа мобов на локации

| Tier | RU | Зона | Аналог скрина |
|------|-----|------|----------------|
| **simple** | Простой | A | mob1 — много Common |
| **medium** | Средний | B | mob2 — mid-table |
| **hard** | Сложный | C | mob3 — Goblin Warrior wide table |
| **boss** | Босс | Boss / портал | сильный меч + **пыль зачарования** |

Алиасы в коде: `trash→simple`, `normal→medium`, `elite→hard`.

---

## Loc1 reference % (как на скринах)

### simple (mob1)
| Rarity | % |
|--------|---|
| Common | 54.998 |
| Uncommon | 34.999 |
| Rare | 8.000 |
| Epic | 2.003 |

### medium (mob2)
| Rarity | % |
|--------|---|
| Common | 24.998 |
| Uncommon | 31.997 |
| Rare | 21.998 |
| Epic | 15.998 |
| Legendary | 5.009 |

### hard (mob3)
| Rarity | % |
|--------|---|
| Common | 15.840 |
| Uncommon | 29.701 |
| Rare | 33.661 |
| Epic | 16.830 |
| Legendary | 2.877 |
| Mythic | 0.992 |
| Secret | 0.099 |

### boss
| Rarity | % |
|--------|---|
| Rare | 28 |
| Epic | 35 |
| Legendary | 25 |
| Mythic | 10 |
| Secret | 2 |

+ **Пыль зачарования** 2–5 шт., 100% (для `EnchantWeapon`).

---

## Локации 2–4 (squeeze)

Epic+ веса × `highRarityMult`, затем **нормализация к 100%**  
(шансы остаются «реальными», не уходят в ноль):

| Loc | highRarityMult |
|-----|----------------|
| 1 | 1.00 |
| 2 | 0.88 |
| 3 | 0.75 |
| 4 | 0.62 |

---

## Таблица мобов (текущий каталог)

| id | Имя | Loc | Tier | HP | Coins | Power | Notes |
|----|-----|-----|------|-----|-------|-------|-------|
| L1_Slime | Теневой слизень | 1 | simple | 40 | 3 | 1 | A |
| L1_GoblinScout | Гоблин-разведчик | 1 | simple | 70 | 4 | 2 | A quest |
| L1_Skeleton | Лесной скелет | 1 | medium | 120 | 6 | 3 | B |
| L1_Wolf | Тёмный волк | 1 | medium | 350 | 14 | 8 | B quest |
| L1_GoblinWarrior | Гоблин-воин | 1 | hard | 500 | 18 | 12 | C (как mob3) |
| L1_Knight | Проклятый рыцарь | 1 | hard | 1200 | 40 | 25 | C |
| L1_Boss | Хранитель леса | 1 | boss | 8000 | 300 | 200 | dust + gear · **respawn 10 мин** |
| L2_Sailor | Матрос | 2 | simple | 2500 | 60 | 40 | stub |
| L2_Captain | Капитан | 2 | hard | 8000 | 150 | 100 | stub |
| L2_Admiral | Адмирал | 2 | boss | 40000 | 800 | 600 | dust · **respawn 10 мин** |
| L3_Samurai | Самурай | 3 | medium | 15000 | 250 | 180 | stub |

---

## Inspect UI

**Shift + ПКМ** по модели моба (`Workspace.Mobs`)  
→ `GetMobDropInfo` → панель с % как на reference game + иконки из `IconConfig`.

---

## Код

| Файл | Роль |
|------|------|
| `WeaponConfig` | таблицы + `BuildDropPreview` |
| `LootService` | roll + dust + inspect payload |
| `MobConfig` | tier simple/medium/hard |
| `MobInspect.lua` | клиент UI |
| `EnchantConfig` / `WeaponService` | чар за пыль (1) или монеты (200) |
