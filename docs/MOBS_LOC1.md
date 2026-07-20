# Мобы Loc1 + Debug Dummy

## Loc1 — Тёмный лес

| ID | Имя | Tier | Zone | HP | Power | Coins | Respawn |
|----|-----|------|------|-----|-------|-------|---------|
| `L1_Slime` | Теневой слизень | simple | A | 40 | 1 | 3 | 3s |
| `L1_GoblinScout` | Гоблин-разведчик | simple | A | 70 | 2 | 4 | 3.2s |
| `L1_Skeleton` | Лесной скелет | medium | B | 120 | 3 | 6 | 3.5s |зс
| `L1_Wolf` | Тёмный волк | medium | B | 350 | 8 | 14 | 4s |
| `L1_GoblinWarrior` | Гоблин-воин | hard | C | 500 | 12 | 18 | 5s |
| `L1_Knight` | Проклятый рыцарь | hard | C | 1200 | 25 | 40 | 8s |
| `L1_Boss` | Хранитель леса | boss | Boss | 8000 | 200 | 300 | **10 мин** |

### Debug

| ID | Имя | HP | Loot / quests |
|----|-----|-----|----------------|
| `DEBUG_Dummy` | Тренировочный манекен | 1_000_000 | **нет** (только урон/клики) |

- Respawn dummy: 1s  
- Remote: `DebugSpawnDummy`  
- Spawn zone: `Debug` (рядом со спавном локации)

---

## Для Studio / UI

### Каталог (статика)
```lua
Remotes.GetMobCatalog:InvokeServer()
-- { id, name, location, tier, defaultZone, hp, isBoss, isDebug, visual, description }
```

### Живые инстансы
```lua
-- в GetProfile → .mobs
-- или Remotes.MobsUpdate
-- { uid, mobId, name, tier, hp, maxHp, position, zone, visual, isDebug, isBoss }
```

### Visual hint (для модели)
```lua
visual = {
  preferredModelName = "L1_Slime", -- имя модели в ReplicatedStorage/Workspace
  color = "#5B2C6F",
  scale = 0.7,
  shape = "ball" | "r6" | "quad" | "humanoid",
}
```

## Placeholders (сейчас)

Сервер **спавнит** простые модели в `Workspace.Mobs`:
- цвет по tier / visual.color
- подпись «нуб» на humanoid-голове
- Billboard: имя + HP
- **ClickDetector** — клик по мобу = удар (UI друга не нужен)

Убийство:
- HP падает → 0 → смерть (модель прячется) → respawn
- Dummy: без лута/квестов
- Обычные: сила + монеты + дроп + квесты

Автокликер: `profile.autoClicker = true` по умолчанию → серверный loop бьёт ближайших в радиусе 40.

---

## Квесты Loc1

| id | Цель |
|----|------|
| Q1_Slimes | 25× L1_Slime |
| Q1_GoblinScouts | 15× L1_GoblinScout |
| Q2_Wolves | 15× L1_Wolf |
| Q2_GoblinWarriors | 10× L1_GoblinWarrior |
| Q3_Boss | 1× L1_Boss |
| Q4_Power | 200 lifetime power |
| Q5_Rebirth | 1 rebirth |

Dummy **не** качает квесты.
