# Sword Masters — полный план проекта

> Living doc. Snapshot 2026-07-19 (inventory polish + pixel fonts + bottom-left toasts).  
> Repo: https://github.com/haz33u/SwordMechyOnlinePizdec  
> Place: «Искусство меча онлайн» (Team Create + Rojo)  
> Icons: `docs/FIGMA_PROMPTS.md`  
> Cristalix dumps: `docs/ref/cristalix/DUMP_CATALOG.md` (+ `captures/`)  
> **World effects (eclipse/darkness/blast): PARKED — catalog only, no code yet.**  
> Loc2 full tables + Loc1 cases 50K/49 keys inventoried — **apply to code when asked**.  
> **LOCALE LOCK: English only** for every player-facing string (UI labels, buttons, Notify toasts, case result, configs shown to player). Comments in code may be RU/EN; **never ship RU text to players.**  
> **AI handoff:** local `CONTEXT_MEPC.md` (gitignored) — copy to other agents; not in repo.

> ### Agent / AI (навсегда)
> **Перед работой:** (1) `git pull` — версии с другом · (2) перечитать этот `MASTER_PLAN.md` · (3) только потом код.  
> **После работы:** сам **`commit` + `push`**, чтобы remote всегда был актуальным.  
> **Без commit/push** — только если пользователь явно сказал «не коммить / не пушь».  
> Подробно: корневой `AGENTS.md`.

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

### UI (SCREEENS + INVETAR inventory 2026-07-18…19)
- [x] GameUI: HUD, windows, modals — **repo-only**, no dual StarterGui
- [x] Theme charcoal + blue CTA + red close (SCREEENS / Cristalix-like)
- [x] **Pixel / Minecraft-like fonts** — `Theme.Fonts` = `Enum.Font.Arcade` (Title/Body/Num/Ui). Whole UIKit labels/buttons pick this up.
- [x] HUD: boosts top-left · **large** coins/power bottom bar (~380–560×112)  
  - Balance sector: **2 TextLabels** (Coins, Power — soft UIStroke glow, gold/power colors) + **2 ImageLabels** (Rebirth / Inventory icons from Creator Store)  
  - Key hints **Q** / **E** under icons; click = ImageButton hit area  
  - Rule: **do not make tiny HUD metrics** (FullHD readability)
- [x] **Attack = LMB + mobile tap** (screen-wide, not Space) — see §4
- [x] **English locale** for UI + configs + server Notify (see §12 UI string map)
- [x] CPS/DPS/clicks → **Profile** tab inside inventory (not main HUD)
- [x] **Unified inventory** (`src/StarterPlayerScripts/Inventory.lua`, panel id `weapons`)
  - Bottom tabs EN: **Weapons / Pets / Auras / Relics / Cases / Shop / Profile**
  - Fill-width slot grid; **soft hover** (scale ~1.06, neighbors ~0.97, delayed leave = no flash); gap ~14px
  - Structured tooltips (cursor edge glued); weapon action chips cartoon (fat radius + Arcade)
  - Panel open/close **bounce scale** on window frames
  - **No left preview strip**
  - Tab ImageButtons (soft rounded tiles + glyph fallback)
  - Sell all unequipped; profile AvatarBust + @username inspect (online)
  - Cases: **small fixed-width cards** (Pet Case / Aura Case), not full-page stretch
- [x] **Donate shop gamepasses** live: `GamePassConfig` + rbxthumb + R$ + PromptGamePass
- [x] UnlockService ownership + auto-clicker purchase flags
- [x] Case open spin: no dark dim; **result card center high Z**
- [x] **Weapon drop does NOT toast** on every drop (ProfileUpdate only). Dust/keys/kills still Notify.
- [x] **Toasts bottom-left** (`Toast.lua`): large Arcade ~18px, stack upward; all `Remotes.Notify`
- [x] Teleport location grid → `SetLocation`
- [x] Left rail only; rail opens inv tabs via `store._invTab`
- [ ] Floating damage / click pop polish
- [ ] Enchant dust counter top-right
- [ ] Boosts backend `profile.boosts` + timers
- [ ] Own group-uploaded tab icons if free Decals fail in place

### Анимации / визуал
- [x] CombatController: Idle/Walk/Run + sprint Shift
- [x] WeaponVisual: мечи на Right/Left grip
- [x] Attack id `134636926386401` (Attack2 only)
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
| Питомцы / ауры / кейсы economy | keys + CaseResult (v0.5.4); roster still thin |
| CaseResult remote (spin accuracy) | ✅ `CaseResult` + profile fallback |
| Данжи Easy/Mid/Hard | timer AFK complete, не бой |
| Реликвии equip/stars | auto-grant only, no Equip/Upgrade remote |
| Enchant transfer / pet enchants | config constants only |
| Boosts `profile.boosts` | HUD empty pills, no backend |
| Wings (equip cosmetic + % ) | **idea parked** — see §11 |
| Сезоны / топы / банды / BP | нет |
| Донат R$ wire | Gamepasses wired (IDs in GamePassConfig); DEBUG_FREE_PAID=false |
| Точный Cristalix HP/coins | playtest-скейл |
| Босс unlock Loc2 квест «у портала» | частично Q3_Boss |
| Dual-wield отдельные анимки L/R | один AttackMain |
| DataStore prod-ready | skeleton |
| Оффлайн-фарм | нет |

### Code gaps vs plan (what to build next)

| Priority | Missing in code | Why | Depends on |
|----------|-----------------|-----|------------|
| **P1 NEXT** | `profile.boosts` + timers in Formulas | HUD top-left dead; Cristalix/katana x2 money/hits | — |
| P1 | Dust/gems strip in HUD | economy visible | dust already in profile |
| P1 | Enchant polish (slot pick, no coin abuse, TransferEnchant) | config has TRANSFER_*; not wired | dust economy |
| P1 | Boss → Loc2 unlock UX | Q5 gives unlockLocation; soft gate polish | quests |
| P1 | Real dungeon fight (HP dummy) + **per-player** gate | now global timer AFK | DungeonService |
| P1 | EquipRelic / UnequipRelic / UpgradeRelic(stars) | Formulas read stars; no remotes | RelicConfig |
| P2 | Loc2–4 mobs + markers Place | only Loc1 combat | World/MobConfig stubs |
| P2 | IconConfig Loc2+ / UI currency icons | empty rbxassetid | FIGMA_PROMPTS |
| P3 | Pets/auras content depth + CaseResult polish | thin roster; economy ok | CaseConfig |
| P3 | Leaderboard OrderedDataStore | no service | stable stats |
| P3 | Battle Pass season XP | none | boosts + quests |
| P3 | **Wings system** (see §11) | none | pets/auras pattern + visual |
| P4 | DataStore versioning, anti-cheat, soft launch | skeleton | soft launch |

**Already shipped (do not re-do):** clicks/CPS/rebirth dual-cost · upgrades · weapons drop/enchant/ban · case keys + CaseResult · pet slots 3→7 + paid offhand · Loc1 quests skeleton · cristalix lang dump · **INVETAR inventory shell** · **gamepass donate shop + auto unlock** · case open no-dim center result.

---

## 7. Дорожная карта (что делать)

### P0 — stabilization (sprint 1) ✅/→
1. ~~Toast nil~~  
2. ~~English locale + LMB/touch attack~~  
3. Confirm attack anim `134636926386401` (Attack2) in Play  
4. Playtest Loc1: kill → drop → inventory → enchant dust → rebirth  
5. Save place + git sync (`COLLAB.md`)  
6. `FIGMA_PROMPTS.md` + first UI icon batch  

### P1 — UI polish + Loc1 content (спринты 2–3)
1. Dust/gems strip top-right; rebirth polish  
2. ~~CaseResult remote + case keys (не free-infinite)~~ ✅  
2b. ~~Pet slots 3→8 + paid offhand~~ ✅  
2c. ~~Loc1 cristalix stats + pets 500 coins~~ ✅  
2d. ~~Loc2 buy 500K + Ferryman + weapon L1/L2/L3 merge~~ ✅  
2e. ~~INVETAR inventory + gamepass shop + structured tooltips + case no-dim~~ ✅  
3. Boosts data model for top-left pills  ← **NEXT**  
4. Mesh swords, hit VFX, balance pass  
5. Boss quest → Loc2 unlock UX  
6. Dungeon real fight + relic equip/upgrade remotes  
7. Enchant transfer remote (config ready)  
8. Verify all tab Image IDs load in live place; upload owned icons if needed

### P2 — Loc2–4 + icons
1. Мобы + маркеры Place  
2. Иконки Loc2–4 по FIGMA_PROMPTS → IconConfig  
3. Drop tables уже есть (squeeze)

### P3 — meta
1. Pets/auras/dungeons real content  
2. Leaderboard / BP (после stable)  
3. LIMITED events + VFX  
4. **Wings** (equip layer — parked design in §11)  

### P4 — live
1. DataStore versioning + migrations  
2. Anti-cheat Swing  
3. Donat R$ (если решите)  
4. Soft launch  

**Не сейчас:** правый Cristalix bind-list, gangs, full R$ shop, Loc5+, Wings implementation.

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
# Агент после работы сам:
git add … ; git commit -m "…" ; git pull --rebase ; git push
# Place: Save to Roblox (Team Create)
# Исключение: пользователь сказал «не пушь» / «не коммить»
```

---

## 10. Principles

1. **Backend truth** in git; Place = map + assets  
2. Cristalix numbers = reconstruction, tune in playtest  
3. Loc1 easy → LocN longer (drop squeeze + HP)  
4. Limited not from mobs  
5. Boss 10 min respawn — enchant dust is strong  
6. No Keyframe/Animations inside `Shared`  
7. **Player-facing language = English** (UI, configs, Notify, new features) — see §12  
8. **Combat click = LMB / touch**, not Space; GUI clicks do not swing  
9. **Pixel font** = `Enum.Font.Arcade` in Theme (Minecraft-adjacent, built-in)  
10. **Toasts** = bottom-left only; no per-weapon-drop spam  
11. **No tiny UI** — primary metrics (coins/power), slots, toasts stay large on FullHD  
12. Inventory hover: soft scale only; never thrash UIStroke thickness (breaks outlines)

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
| **Case / gacha polish** | Odds + spin + multi-open + pity | Spin + CaseResult + keys done; multi-open / pity later |
| **Session goals / “wins”** | Short goals → chest | Overlaps quests; daily-style later |
| **Power fantasy readability** | Big numbers, equip VFX, limited flex | Mesh/VFX pass; icons via FIGMA_PROMPTS |
| **Premium train boost** | Gamepass +% | Only after donat R$ decision (P4) |
| **Wings** | Classic Roblox sim flex layer | Full design below — **do not code until P3** |

---

### 🪽 Wings (parked idea — Roblox sim style)

> Like Pet Simulator / Anime Fighting / sword sims: **back cosmetic + small stats**, rarity ladder, case or craft, 1 equipped.

**Why:** power fantasy + vertical progress without new maps; flex in screenshots; monetize later (keys / Limited wings) without touching main combat feel if % stay small.

**Player-facing loop**
```
kill / quest / dungeon → wing keys or wing shards
  → open Wing Case (or craft)
  → equip 1 pair of Wings
  → +% power / coins / speed (small) + back VFX
```

**Rules (target design)**
| Rule | Value |
|------|--------|
| Equipped | **1** active pair (`profile.equippedWings`) |
| Inventory | list of wing instances `{ uid, id, level? }` |
| Stats | stack into Formulas like aura: `powerPct`, `coinPct`, optional `speedPct` / `luckPct` |
| Rarity ladder | Common → … → Mythic → Secret → **Limited** (event) |
| Obtain | Wing Case keys (from elite/boss/dungeon) **or** seasonal BP |
| Level (optional v2) | feed coins → +tiny % (same as pets) |
| Visual | Accessory / Model on character back (Place assets); client `WingVisual` like `WeaponVisual` |
| Ban drop | `bannedWingIds` like weapons/pets |

**What it gives (balance intent)**
- **Not** a second weapon — weaker than main sword mult  
- Similar weight to **aura** (single slot cosmetic power)  
- Example skeleton: Common +3–8% power; Legendary +40–70%; Limited flex + VFX, hand-tuned  
- Coins % secondary so farm feels better without breaking DPS

**Code we would need later (not now)**
| Piece | Work |
|-------|------|
| `WingConfig.lua` | defs id/name/rarity/powerPct/coinPct/vfxKey |
| `profile.wings`, `equippedWings` | ProfileService + Types |
| `WingService` | OpenWingCase, EquipWing, UnequipWing |
| Remotes | + CaseResult kind `"wing"` |
| `Formulas.GetWingPct` | into TotalPower + coin mult |
| Client | Wings window + `WingVisual` attach to torso/back |
| Economy | wing keys in CaseConfig / LootService drops |

**Do not confuse with**
- **Auras** — body glow / circle; already skeleton  
- **Pets** — team slots, follow  
- Wings = **back equip**, 1 slot, visual heavy  

**When to build:** after boosts + Loc1 stable + pets/auras feel real (P3). Until then: only this doc.

---

### Explicitly do **not** copy blindly
- Wheel-spin / code spam economy  
- Heavy P2W before Loc1 is fun  
- Asset theft from those places  
- Wings before core combat/economy works  

### When to reopen this section
After: Loc1 playtest clean · case economy not free-infinite · boosts live · UI SCREEENS polish.  
Then pick **one** parked idea (recommended: onboarding **or** aura tower; **Wings** after equip layers solid).

### Figma / art pipeline (tools)
- Prompts: `docs/FIGMA_PROMPTS.md`  
- Upload: `docs/ICON_UPLOAD.md` → IconConfig  
- Agent can use **Figma MCP** (when connected) + local Imagine; cannot “see” your desktop Figma window as a human unless MCP/API exposes the file.

---

## 12. UI map for friend / Studio agent (English strings + where code lives)

> Use this section to wire art, i18n, or Studio-only UI without reading the whole repo.  
> **All labels below are English in code.** Do not reintroduce Russian player strings.

### 12.1 Locale rule
| Rule | Detail |
|------|--------|
| Player-facing language | **English only** |
| Scope | Buttons, titles, tabs, tooltips, toasts (`Notify`), case result, modals, HUD chips, config `name` fields shown in UI |
| Comments / dumps | RU notes OK in comments and docs only |
| If you add a string | Write it in English; mirror existing tone (short, game-y) |

### 12.2 Fonts
| Token | Value | File |
|-------|--------|------|
| Title / Body / Num / Ui | `Enum.Font.Arcade` | `Theme.lua` → `Theme.Fonts` |
| UIKit.Label / Button | uses `T.Font.*` | `UIKit.lua` |
| Inventory labels/actions | Arcade | `Inventory.lua` |

### 12.3 Toasts / notifications
| Item | Value |
|------|--------|
| Client | `src/StarterPlayerScripts/Toast.lua` |
| Mount | `App.lua` → `Toast.Mount(gui)` |
| Server fire | `Remotes.Event("Notify"):FireClient(player, { text = "...", color = "green"\|"red"\|"gold"\|"orange"\|"pink"\|"cyan"\|"yellow" })` |
| Position | **Bottom-left** of screen (`Anchor 0,1`, pad ~16,‑24), stack upward |
| Font size | ~18 Arcade |
| **Do not toast** | Every weapon drop (disabled on purpose in `LootService.GrantWeapon`) |
| Still toast | Bag full, enchant dust, pet/aura keys, kills, auto on/off, case fail, unlocks, pet open result |

Example server texts (EN):
- `Weapon bag full (32) — sell or upgrade Backpack`
- `Enchant dust +3 (total 12)`
- `Pet key +1 (total 2)` / `Aura key +1 …`
- `Auto-clicker: ON` / `OFF`
- `Auto-clicker not purchased (manual CPS cap: Loc1=4, max=20)`
- `Pet: Name [Rarity]  Power x1.25  (−1 keys)`
- `Aura: Name +12% power  (keys left: 3)`
- Kill line: `{mobName} ✕  +{power} power  +{coins} coins`

### 12.4 Inventory shell (`Inventory.lua`, panel `weapons`)
| UI name (EN) | Role | Notes |
|--------------|------|--------|
| **Inventory — Weapons** | Header title weapons tab | Also Pets/Auras/Relics/Cases; Shop = **Donate Shop**; Profile = **Player Profile** |
| Count `N OF 32` | Bag fill | Cap from Backpack upgrade |
| Info bar | `● {Name} \| R{n} x{mult} ● Loc {id}` | Live stats |
| Close **✕** | Closes panel | |
| **Weapons** tab | Grid of swords | Icons via `IconConfig.GetWeaponImage` |
| **Pets** tab | Pet slots | Equip / Unequip |
| **Auras** tab | Aura slots | Equip |
| **Relics** tab | Read-only | Dungeon drops |
| **Cases** tab | Pet Case / Aura Case | Small cards, button **Open** |
| **Shop** tab | Gamepasses | Image + **R$** / **OWNED** |
| **Profile** tab | Stats + search | AvatarBust; `@username` search online |
| Tooltip | Title, Rarity, Power/Sell/Level, Equipped | Cursor edge glue |
| Actions | **Equip main**, **Equip off** / **Off 🔒**, **Enchant**, **Sell**, **Sell all unequipped** | Cartoon chips |
| Cases open | Opens `CaseOpening` modal | Not a separate window id |

**Hotkeys → inventory tab** (`App.lua` / rail `Hud.lua`):
| Key / rail | Tab |
|------------|-----|
| E / I | weapons |
| P | pets |
| C | cases |
| B | shop |
| U | profile |
| Rail weapons/pets/auras/relics/cases/shop/character | same shell via `_invTab` |

### 12.5 Other windows (`Windows.lua` titles)
| Panel id | Title (EN) | Notes |
|----------|------------|--------|
| character | Profile | Legacy window still exists; primary profile is inv **Profile** tab |
| weapons | Inventory | INVETAR shell (chrome header hidden) |
| pets / auras / cases / relics | Pets / Auras / Cases / Relics | May still refresh stubs; prefer inv tabs |
| quests | Quests | |
| locations | Teleport | |
| dungeons | Dungeons | |
| shop | Donate Shop | Standalone also has gamepass grid |

### 12.6 HUD (`Hud.lua`)
| Element | EN / meaning |
|---------|----------------|
| Rail icons | Open panels / inv tabs |
| Coins / Power chips | Currency + strength |
| Q rebirth | Opens rebirth modal |
| Boosts row | Top-left (backend boosts still TODO) |

### 12.7 Case opening (`CaseOpening.lua`)
| UI | EN |
|----|-----|
| Title | Pet Case / Aura Case |
| Subtitle | Opening… / Drop received! |
| Result | You got! · name · RARITY · sub stats |
| Buttons | Claim · ✕ close |
| Dim | Transparent (no dark overlay) |
| Result position | Center screen, high Z |

### 12.8 Gamepasses (`GamePassConfig.lua` titles shown in Shop)
| key | Title (EN) |
|-----|------------|
| offhand | Second sword slot |
| paidPetSlot | 1 pet slot |
| relicSlot | 1 relic slot |
| autoClicker | AutoClicker |
| teleporter | Teleporter |
| openChest3 | Open 3 chest |
| openChest5 | Open 5 chest |

### 12.9 Key files (friend wiring)
| Concern | File |
|---------|------|
| Fonts / colors | `StarterPlayerScripts/Theme.lua` |
| Labels / buttons primitives | `StarterPlayerScripts/UIKit.lua` |
| Toasts | `StarterPlayerScripts/Toast.lua` |
| Inventory | `StarterPlayerScripts/Inventory.lua` |
| All windows | `StarterPlayerScripts/Windows.lua` |
| HUD / rail | `StarterPlayerScripts/Hud.lua` |
| Case spin | `StarterPlayerScripts/CaseOpening.lua` |
| Mount + hotkeys | `StarterPlayerScripts/App.lua` |
| Notify from server | any Service + `Remotes.Event("Notify")` |
| Drop no-toast | `ServerScriptService/Services/LootService.lua` `GrantWeapon` |

### 12.10 Recent UI decisions (do not reverse without ask)
1. English only for players  
2. Arcade pixel font globally  
3. Toasts **bottom-left**, not top-center  
4. No toast spam on weapon drop  
5. Inventory left strip removed  
6. Hover slots push neighbors; larger gap  
7. Case cards compact fixed width  
8. Unified inventory on `weapons` panel only for main bag UX
