# Sword Masters — полный план проекта

> Living doc. Snapshot 2026-07-18 (UI + EN locale + input).  
> Repo: https://github.com/haz33u/SwordMechyOnlinePizdec  
> Place: «Искусство меча онлайн» (Team Create + Rojo)  
> Icons: `docs/FIGMA_PROMPTS.md`  
> **Locale: English** for all player-facing strings (UI, configs, Notify). New work stays in EN.

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

## 4. Core loop + input

```
LMB / mobile tap (anywhere not on GUI) → Swing (CPS rate limit) → damage mob
  → kill → coins + power + weapon drop
  → upgrades / enchants / rebirth → stronger
```

**Attack input (locked decision):**
- **No Space** for combat
- **MouseButton1** and **Touch** fire manual swing when `gameProcessed == false` (not on UI buttons)
- ClickDetectors on mobs still work; server swing CD prevents double-hit spam
- **Q** = rebirth modal · **E** / **I** = weapon inventory · **T** = auto-clicker · **U** = profile

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
- [x] GameUI: HUD, windows, modals (Fusion) — **repo-only**, no dual StarterGui
- [x] Theme charcoal + blue CTA + red close (SCREEENS / Cristalix-like)
- [x] HUD: boosts top-left · coins/power bottom · **Q**=rebirth · **E**=inventory
- [x] **Attack = LMB + mobile tap** (screen-wide, not Space) — see §4
- [x] **English locale** for UI + configs + server Notify (commit `d36756e`)
- [x] CPS/DPS/clicks → **Profile** panel (not main HUD)
- [x] Weapon inventory: 32 slots + IconConfig Loc1
- [x] Teleport location grid → `SetLocation`
- [x] Cases: spin open + odds 1/rarity; donate shop **stubs only**
- [x] Left rail only (no right-side Cristalix bind list)
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

### P0 — stabilization (sprint 1) ✅/→
1. ~~Toast nil~~  
2. ~~English locale + LMB/touch attack~~  
3. Confirm attack anim `133642421878218` in Play  
4. Playtest Loc1: kill → drop → inventory → enchant dust → rebirth  
5. Save place + git sync (`COLLAB.md`)  
6. `FIGMA_PROMPTS.md` + first UI icon batch  

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

## 10. Principles

1. **Backend truth** in git; Place = map + assets  
2. Cristalix numbers = reconstruction, tune in playtest  
3. Loc1 easy → LocN longer (drop squeeze + HP)  
4. Limited not from mobs  
5. Boss 10 min respawn — enchant dust is strong  
6. No Keyframe/Animations inside `Shared`  
7. **Player-facing language = English** (UI, configs, Notify, new features)  
8. **Combat click = LMB / touch**, not Space; GUI clicks do not swing

---

## 11. Ideas / could-do later (NOT now)

> Inspiration from public Roblox sword sims (2026-07-18).  
> Refs opened: [Discover «Sword Masters»](https://www.roblox.com/discover/?Keyword=Sword%20Masters),  
> [Swordmaster Simulator](https://www.roblox.com/games/15501353806/Swordmaster-Simulator),  
> [Reborn As Swordsman](https://www.roblox.com/games/16981421605/Reborn-As-Swordsman).  
> **Do not implement until P0–P1 core is stable.** Parked ideas only.

### What those games lean on
| Source | Loop highlights |
|--------|-----------------|
| Swordmaster Simulator | Kill brutes → legendary swords; pets; gems; loot boxes / wheel / armor (classic sim gacha) |
| Reborn As Swordsman | Train for strength; fight for swords; **rebirth**; **tower for auras**; wins + pets; premium train boost |

### Ideas we might steal (parked)
| Idea | Why interesting | Notes for us |
|------|-----------------|--------------|
| **Onboarding 0–2 min** | Clear first path without wiki | Toasts + first quest highlight; not full tutorial UI yet |
| **Train pad vs fight zone** | Soft AFK power near spawn; risk elsewhere | Optional later; we are fight-only now |
| **Aura tower / floor climb** | Vertical content without full Loc2 map | Strong from Reborn; after cases economy real |
| **Case / gacha polish** | Odds + spin + multi-open + pity | We have spin + 1/rarity odds; need CaseResult + keys first |
| **Session goals / “wins”** | Short goals → chest | Overlaps quests; daily-style later |
| **Power fantasy readability** | Big numbers, equip VFX, limited flex | Mesh/VFX pass; icons via FIGMA_PROMPTS |
| **Premium train boost** | Gamepass +% | Only after donat R$ decision (P4) |

### Explicitly do **not** copy blindly
- Wheel-spin / code spam economy  
- Heavy P2W before Loc1 is fun  
- Asset theft from those places  

### When to reopen this section
After: Loc1 playtest clean · case economy not free-infinite · UI SCREEENS polish.  
Then pick **one** parked idea (recommended first: onboarding **or** aura tower slice).

### Figma / art pipeline (tools)
- Prompts: `docs/FIGMA_PROMPTS.md`  
- Upload: `docs/ICON_UPLOAD.md` → IconConfig  
- Agent can use **Figma MCP** (when connected) + local Imagine; cannot “see” your desktop Figma window as a human unless MCP/API exposes the file.
