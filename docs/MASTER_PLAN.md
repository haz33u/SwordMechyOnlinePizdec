# Sword Masters — полный план проекта

> Живой документ. Сводка на 2026-07-18 (UI sprint + roadmap).  
> Репо: https://github.com/haz33u/SwordMechyOnlinePizdec  
> Place: «Искусство меча онлайн» (Team Create + Rojo)  
> Детальный backlog: session plan / `docs/FIGMA_PROMPTS.md` (иконки)

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

### UI (SCREEENS pass 2026-07-18)
- [x] GameUI: HUD, окна, модалки (Fusion) — **repo-only**, без dual StarterGui
- [x] Theme charcoal + blue CTA + red close (как Cristalix-like SCREEENS)
- [x] HUD: бусты top-left · coins/power bottom · **Q**=rebirth · **E**=инвентарь · Space=удар
- [x] CPS/DPS/клики → панель **Профиль** (не на main HUD)
- [x] Инвентарь оружия: 32 слота + IconConfig Loc1
- [x] Телепорт: сетка локаций → `SetLocation`
- [x] Кейсы: spin open + odds 1/rarity; донат-магазин **stubs only**
- [x] Left rail only (правый text-menu Cristalix — **не** делаем)
- [x] Toast nil fix (`T.TopH` removed)
- [ ] Floating damage / click pop polish
- [ ] Enchant dust counter top-right
- [ ] Boosts backend `profile.boosts` + timers

### Анимации / визуал
- [x] CombatController: Idle/Walk/Run + sprint Shift
- [x] WeaponVisual: мечи на Right/Left grip
- [x] Attack id `133642421878218` (нужна проверка in-game)
- [x] Rojo не сносит Place Animations (meta + папки вне Shared)

### Документы
- CORE_SYSTEMS, WEAPONS_LOOT, MOB_DROP_TABLES, ANIMATIONS, ICON_UPLOAD, UI_BRIEF  
- **NEW:** `FIGMA_PROMPTS.md` — промпты/очередь иконок для Figma + AI

---

## 6. Чего нет / слабо ⚠️

| Тема | Статус |
|------|--------|
| Loc2–4 мобы/контент | stubs |
| Реальные 3D модели мечей | placeholder Parts |
| Иконки Loc2+ / UI currency | пустые id → FIGMA_PROMPTS |
| Питомцы / ауры / кейсы economy | skeleton (free open risk) |
| CaseResult remote (spin accuracy) | нет — poll profile |
| Данжи Easy/Mid/Hard | skeleton UI only |
| Сезоны / топы / банды / BP | нет |
| Донат R$ wire | UI stubs only |
| Точный Cristalix HP/coins | playtest-скейл |
| Босс unlock Loc2 квест «у портала» | частично Q3_Boss |
| Dual-wield отдельные анимки L/R | один AttackMain |
| DataStore prod-ready | skeleton |
| Оффлайн-фарм | нет |

---

## 7. Дорожная карта (что делать)

### P0 — stabilization (спринт 1) ✅/→
1. ~~Toast nil~~  
2. Добить **атаку**: confirm `133642421878218` in Play  
3. Playtest Loc1: kill → drop → inventory → enchant dust → rebirth  
4. Save place + git sync (`COLLAB.md`)  
5. `FIGMA_PROMPTS.md` + первая очередь UI icons  

### P1 — UI polish + Loc1 content (спринты 2–3)
1. Dust/gems strip top-right; inventory UX; case/rebirth polish  
2. CaseResult remote + case keys (не free-infinite)  
3. Boosts data model for top-left pills  
4. Mesh swords, hit VFX, balance pass  
5. Boss quest → Loc2 unlock UX  

### P2 — Loc2–4 + icons
1. Мобы + маркеры Place  
2. Иконки Loc2–4 по FIGMA_PROMPTS → IconConfig  
3. Drop tables уже есть (squeeze)

### P3 — meta
1. Pets/auras/dungeons real  
2. Leaderboard / BP (после stable)  
3. LIMITED events + VFX  

### P4 — live
1. DataStore versioning + migrations  
2. Anti-cheat Swing  
3. Donat R$ (если решите)  
4. Soft launch  

**Не сейчас:** правый Cristalix bind-list, gangs, full R$ shop, Loc5+.

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
| `FIGMA_PROMPTS.md` | промпты AI/Figma + tracking иконок |
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
