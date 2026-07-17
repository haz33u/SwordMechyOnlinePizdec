# Sword Masters (скелет) — Roblox

Игровой **скелет** механик в духе «Мастера Мечей» (Cristalix), адаптированный под Roblox.

- **Без доната** на этом этапе  
- **Одна soft-валюта:** Coins  
- **R$ / gamepass** — не подключены (добавите позже)  
- Цель: быстро тестировать loop: **бей → сила/монеты → апы → rebirth → петы/ауры/чары → данж**

## Структура

```
src/
  ReplicatedStorage/Shared/
    Config/          — весь баланс (числа)
    Formulas.lua     — сила, урон, CD
    Remotes.lua
    Types.lua
  ServerScriptService/
    Main.server.lua
    Services/        — Profile, Combat, Rebirth, Upgrades, Weapons, Pets, Auras, Quests, Dungeons, Locations
  StarterPlayerScripts/
    ClientMain.client.lua  — HUD + auto-swing
default.project.json       — Rojo
```

## Как запустить в Roblox Studio

### Вариант A — Rojo (рекомендуется)
1. Установи [Rojo](https://rojo.space/)
2. В папке проекта: `rojo serve`
3. В Studio: плагин Rojo → Connect
4. Play (F5)

### Вариант B — вручную
1. Создай Place
2. Скопируй содержимое:
   - `Shared` → `ReplicatedStorage.Shared` (ModuleScripts)
   - `ServerScriptService/*` → ServerScriptService
   - `ClientMain.client.lua` → StarterPlayerScripts
3. Имена модулей = имена файлов без `.lua`
4. Папки Config / Services сохрани иерархию

## CORE: Клики = заработок

| Действие | Как |
|----------|-----|
| Ручной клик | кнопка **КЛИК** / Space / E |
| Автокликер | кнопка 🤖 или **T** (тоггл) |
| CPS / DPS / Клики | верхняя панель |
| Ап CPS | «Скорость удара» |

Сервер режет частоту по CPS — читы сверх капа не проходят.

Подробно: `docs/CORE_SYSTEMS.md`  
Мир (4 крупные локации): `docs/WORLD_SETUP.md`  
Коллаб с другом / версии арта: `docs/COLLAB.md`

## Что уже работает (тест)

| Механика | Как проверить в HUD |
|----------|---------------------|
| **Клики + автокликер** | Space / T / большая кнопка КЛИК |
| Сила/клик, CPS, DPS | топ-панель |
| Rebirth | кнопка ♻ (нужен lifetime damage) |
| Апы персонажа | Сила / Бег / Рюкзак / **Скорость удара** |
| Зачарование меча | ✨ (200 coins) |
| Питомцы | 🐾 кейс |
| Ауры | 🌀 кейс (500 coins) |
| Квесты | ✅ сдать готовые |
| Данжи easy/mid | 🏛 (таймер → награда + реликвия / слот пета) |
| Локация 2 | 🗺 (нужна сила / квест rebirth) |

## Игровые системы (скелет)

1. **Combat** — урон = TotalPower, CD от чар/апов  
2. **Rebirth** — soft, cost = lifetimeDamage, mult product  
3. **Upgrades** — RunSpeed, Backpack, Power, ClickSpeed, Crit, Luck  
4. **Weapons** — дроп, 2 слота (main + offhand 50%), sell, ban-list  
5. **Enchants** — рулетка % (сила/урон/скорость/крит/монеты)  
6. **Pets** — кейс, слоты 1→7, feed, team  
7. **Auras** — кейс, 1 экип, % силы  
8. **Relics** — из данжей  
9. **Quests** — kill/boss/power/rebirth  
10. **Dungeons** — easy/medium/hard (авто-клир по таймеру)  
11. **Locations** — 1 полная, 2–3 unlock stubs  

## Баланс

Все числа: `src/ReplicatedStorage/Shared/Config/*`  
Математика: `Formulas.lua`

## Дальше (не в скелете)

- 3D карта локаций / модели мобов  
- Визуал аур/мечей  
- Полный loot Loc 2–16  
- Банды  
- BattlePass + R$ магазин  
- Точная калибровка rebirth с HUD Cristalix  

## Управление

| Input | Действие |
|-------|----------|
| LMB | Удар |
| R | Rebirth |
| HUD buttons | все системы |

Версия: `0.1.0-skeleton`
