# Sword Masters — полный план проекта

> Живой документ. Сводка на 2026-07-18.  
> Репо: https://github.com/haz33u/SwordMechyOnlinePizdec  
> Place: «Искусство меча онлайн» (Team Create + Rojo)

---

## 1. Что это за игра

**Roblox-порт** мини-игры Cristalix **«Мастера Мечей» / Sword Masters** (#sao vibe):

- Кликай по мобам → урон → киллы → **монеты + сила + мечи**
- Мечи main + offhand (50%), чары, петы, ауры, rebirth
- Локации по силе, босс у «портала» → дальше
- **Без доната** в скелете (одна soft-валюта Coins + enchant dust)

**Не 1:1 Cristalix:** таблицы реконструированы (скриншоты + логика), не HUD-дамп.

---

## 2. Кто что делает

| Зона | Кто |
|------|-----|
| Backend (сервер, конфиги, лут, мобы) | Мы (git + Rojo) |
| Client UI (HUD, окна) | Мы + итерации; друг / Studio Agent по brief |
| Карта, art, модели | Place / Studio / вы |
| Иконки мечей | NN + upload → IconConfig |
| Анимации | Place `ReplicatedStorage.Animations` + AnimationConfig |

---

## 3. Архитектура

```
git (Rojo)                          Place (Studio)
─────────────────                   ─────────────────
src/ReplicatedStorage/Shared        World / карта / MobSpawns
src/ServerScriptService             ReplicatedStorage.Animations
src/StarterPlayerScripts (UI)       CombatAnimations / dummy packs
Packages (Fusion, OnyxUI)           Art, VFX, Team Create
```

- **Rojo** синкает код; Workspace карту **не** трогает  
- Анимации **не** класть в `Shared` → `ReplicatedStorage.Animations`  
- См. `docs/ROJO_STUDIO.md`, `docs/COLLAB.md`

---

## 4. Игровой loop (core)

```
Клик → Swing (rate limit CPS) → урон мобу
  → kill → coins + power + оружие (1 меч, таблица %)
  → апы / чары / rebirth → сильнее
```

**TotalPower** = (base + lifetimePower) × rebirth × weapons × (петы/ауры/чар/апы)

---

## 5. Что уже сделано ✅

### Backend / прогрессия
- [x] Клики, автокликер, CPS, крит
- [x] TotalPower / формулы
- [x] **Rebirth = урон + монеты** (dual cost)
- [x] Апы персонажа (RunSpeed, Power, ClickSpeed, Crit, Luck…)
- [x] Профиль + DataStore skeleton
- [x] Remotes API (`docs/BACKEND_API.md`)

### Мечи / лут
- [x] Каталог мечей Loc1–4 (60 id, rarity до Secret + Limited)
- [x] Дроп Cristalix-style: simple / medium / hard / boss
- [x] Loc2+ high-tier squeeze
- [x] Main + offhand, sell, enchant, ban drop
- [x] **Enchant dust** с босса (2–5), респавн босса **10 мин**
- [x] IconConfig + Loc1 rbxassetid иконки
- [x] Shift+ПКМ inspect дропа (`MobInspect`)

### Мобы / мир
- [x] Loc1 roster + HP + zones A/B/C/Boss
- [x] Placeholders + ClickDetector + HP bar
- [x] Mob spawn markers Edit mode
- [x] DEBUG_Dummy
- [x] WorldConfig 4 локации (meta)
- [x] Квесты Loc1 skeleton

### UI
- [x] GameUI: HUD, окна, модалки (Fusion)
- [x] UI brief для Studio Agent
- [x] Toast / floating damage / click pop (частично баги)

### Анимации / визуал
- [x] CombatController: Idle/Walk/Run + sprint Shift
- [x] WeaponVisual: мечи на Right/Left grip
- [x] Attack id `133642421878218` (нужна проверка in-game)
- [x] Rojo не сносит Place Animations (meta + папки вне Shared)

### Документы (много мелких, не один файл раньше)
- CORE_SYSTEMS, WEAPONS_LOOT, MOB_DROP_TABLES, ANIMATIONS, ICON_UPLOAD, UI_BRIEF, …

---

## 6. Чего нет / слабо ⚠️

| Тема | Статус |
|------|--------|
| Loc2–4 мобы/контент | stubs |
| Реальные 3D модели мечей | placeholder Parts |
| Иконки Loc2+ | пустые id |
| Питомцы / ауры / кейсы | skeleton |
| Данжи Easy/Mid/Hard | skeleton |
| Сезоны / топы / банды | нет |
| Донат / R$ | сознательно нет (фаза 2) |
| Точный Cristalix HP/coins (миллионы) | playtest-скейл |
| Босс unlock Loc2 квест «у портала» | частично Q3_Boss |
| Dual-wield отдельные анимки L/R | один AttackMain |
| Toast UI bug (nil arithmetic) | open |
| DataStore prod-ready | skeleton |
| Оффлайн-фарм | нет |

---

## 7. Дорожная карта (что делать)

### P0 — playable core (сейчас)
1. Добить **атаку**: подтвердить `133642421878218` в Play (F9 `PlayAttack`) или R15 re-publish  
2. Починить **Toast** nil  
3. Один **CombatController**, путь `RS.Animations`  
4. Playtest Loc1: килл → дроп → rebirth coins → чар пылью  
5. Save place + git sync ритуал (`COLLAB.md`)

### P1 — контент Loc1 polish
1. Модели мечей (mesh) вместо Part  
2. VFX удара / hit  
3. Баланс HP/монет «приятные минуты»  
4. Босс: квест → unlock Loc2 + portal UX  
5. UI друга: инвентарь с IconConfig

### P2 — Loc2–4
1. Мобы + зоны + маркеры  
2. Мечи/иконки по шаблону WeaponConfig  
3. Drop tables уже есть (squeeze)

### P3 — meta systems
1. Петы/ауры/кейсы polish  
2. Данжи  
3. Сезон / лидерборд  
4. LIMITED ивенты + VFX

### P4 — live
1. DataStore версия + миграции  
2. Античит Swing  
3. Донат (если решите)  
4. Маркетинг / soft launch

---

## 8. Где что читать

| Документ | Содержание |
|----------|------------|
| **Этот файл** | Сводка + roadmap |
| `CORE_SYSTEMS.md` | Loop, формулы |
| `WEAPONS_LOOT.md` | Мечи, rarity, power |
| `MOB_DROP_TABLES.md` | % дропа Cristalix |
| `BACKEND_API.md` | Remotes |
| `UI_BRIEF_FOR_STUDIO_AGENT.md` | UI для агента/друга |
| `ANIMATIONS.md` | Атаки / grips |
| `ROJO_STUDIO.md` | Rojo vs Place |
| `ICON_UPLOAD.md` | rbxassetid иконок |
| `COLLAB.md` | Git + Team Create |

---

## 9. Ежедневный workflow

```powershell
cd "D:\RobloxProject\САО БРАТ"
git pull
rojo serve          # Connect в Studio
# ...работа...
git add -A ; git commit ; git pull --rebase ; git push
# Place: Save to Roblox (Team Create)
```

---

## 10. Принципы

1. **Backend truth** в git; Place = карта + ассеты  
2. Цифры Cristalix — **реконструкция**, тюним playtest  
3. Loc1 easy → LocN дольше (drop squeeze + HP)  
4. Limited не с мобов  
5. Босс не спамится (10 мин) — чары сильные  
6. Не класть Keyframe/Animations внутрь `Shared`
