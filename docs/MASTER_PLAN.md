# Sword Masters — полный план проекта

> Living doc. Snapshot 2026-07-19 (Figma UI track: CharacterUpgrade → Main Inventory → BattlePass; worlds = one place).  
> Repo: https://github.com/haz33u/SwordMechyOnlinePizdec  
> Place: «Искусство меча онлайн» (Team Create + Rojo)  
> Icons: `docs/FIGMA_PROMPTS.md`  
> Cristalix dumps: `docs/ref/cristalix/DUMP_CATALOG.md` (+ `captures/`)  
> **World effects (eclipse/darkness/blast): PARKED — catalog only, no code yet.**  
> Loc1+Loc2 dump balance applied in configs (see DUMP_CATALOG).  
> **LOCALE LOCK: English only** for every player-facing string (UI labels, buttons, Notify toasts, case result, configs shown to player). Comments in code may be RU/EN; **never ship RU text to players.**  
> **AI handoff:** local `CONTEXT_MEPC.md` (gitignored) — copy to other agents; not in repo.  
> **Next UI sprint:** Figma → game. **Start test:** Character Upgrade only, then Main Inventory, then Battle Pass.  
> **Worlds:** stay **one Roblox place**, multiple islands + teleport pads (see §13). Not Minecraft Realms / multi-universe by default.

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
  - Balance: **4 separate chips** in a row — Rebirth icon · Coins card · Power card · Inventory icon (not one merged rectangle)  
  - Coins/Power = TextLabel + soft glow; Q/E = ImageLabel icons (Creator Store) + key hints  
  - Inventory full rebuild throttled (only when bag/equip signature changes or tab switch); no bounce re-fire if already open  
  - Weapons bar: **Equip best** (top power → main; 2nd → offhand if unlock/pass)  
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
- [x] **WeaponModels Place folder** + ladder map (6 free swords → bottom Loc1 rarities); Tool.Grip weld; fallback placeholder Part
- [x] Inventory weapon slots: ViewportFrame when model exists, else IconConfig
- [x] Attack id `522635514` (Tool Slash; banned Place id 12741376562 sanitized)
- [x] Rojo не сносит Place Animations (meta + папки вне Shared)

### Документы
- CORE_SYSTEMS, WEAPONS_LOOT, MOB_DROP_TABLES, ANIMATIONS, ICON_UPLOAD, UI_BRIEF  
- **NEW:** `FIGMA_PROMPTS.md` — промпты/очередь иконок для Figma + AI

---

## 6. Чего нет / слабо ⚠️

| Тема | Статус |
|------|--------|
| Loc2–4 мобы/контент | stubs |
| Реальные 3D модели мечей | **9 Loc1** meshes + **`SM_Hilt`** / BladeRoll (`docs/WEAPON_HOLD.md`); Loc2 still empty |
| Иконки weapons | Loc1 IconConfig Decals; pipeline `docs/ICON_UPLOAD.md`. Loc2 empty → fallback |
| Character Upgrade icons | ✅ `UpgradeIconConfig` + **§8.1** (strength/bag/speed/crit/multicrit/coin/close/**shop**) |
| Quest + CoinShop 1–5 icons | ✅ `UiIconConfig` + **§8.3** |
| Питомцы / ауры / кейсы economy | **Pets v1:** catalog+case+equip+feed+sell+`PetVisual` follow; auras still thin |
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
| **P1 NEXT** | **Figma Character Upgrade UI** → live window | First UI test slice; upgrade buy already server-side | Figma export + `Windows`/`UpgradeConfig` |
| P1 | Figma **Main Inventory** port (full shell polish) | INVETAR skeleton exists; match Figma layout/tokens | Character Upgrade pass |
| P1 | Figma **Battle Pass** shell + XP track | No BP yet; design-first then data | inventory UI pattern |
| P1 | `profile.boosts` + timers in Formulas | HUD top-left dead | — |
| P1 | Dust/gems strip in HUD | economy visible | dust already in profile |
| P1 | Enchant polish / TransferEnchant | config ready; not wired | dust |
| P1 | Boss → Loc2 unlock UX | soft gate polish | quests |
| P1 | Real dungeon fight + **per-player** gate | AFK timer only | DungeonService |
| P1 | EquipRelic / UpgradeRelic | no remotes | RelicConfig |
| P2 | World pads + polish Ferryman / `SetLocation` UX | backend exists; map pads + UI | Place art |
| P2 | Loc2–4 content + IconConfig Loc2+ | Loc2 dump in configs; art/markers | Place + FIGMA_PROMPTS |
| P3 | Leaderboard / full BP economy / Wings | meta | stable core |
| P4 | DataStore versioning, anti-cheat, soft launch | skeleton | soft launch |

**Already shipped (do not re-do):** clicks/CPS/rebirth dual-cost · upgrades · weapons drop/enchant/ban · case keys + CaseResult · pet slots 3→7 + paid offhand · Loc1 quests skeleton · cristalix lang dump · **INVETAR inventory shell** · **gamepass donate shop + auto unlock** · case open no-dim center result.

---

## 7. Дорожная карта (что делать)

### P0 — stabilization (sprint 1) ✅/→
1. ~~Toast nil~~  
2. ~~English locale + LMB/touch attack~~  
3. Confirm attack anim `522635514` (tool slash) in Play  
4. Playtest Loc1: kill → drop → inventory → enchant dust → rebirth  
5. Save place + git sync (`COLLAB.md`)  
6. `FIGMA_PROMPTS.md` + first UI icon batch  

### P1 — Figma UI track + Loc1 content (спринты 2–3)

**Order (locked):** Character Upgrade → Main Inventory → Battle Pass.  
Do not start BP implementation until inventory Figma pass is testable.

1. **Character Upgrade (START HERE — first Figma → game test)**  
   - **Debug open now:** rail **UP** · key **U** / **K** → panel `character`  
   - See `docs/UI_FIGMA_PORT.md`  
   - Source: Figma screen for character upgrades (power, CPS, bag, crit locks, etc.)  
   - Wire to existing `UpgradeConfig` + `BuyUpgrade` remote + `Windows` upgrades body  
   - Match layout / tokens from Figma; keep EN strings; Arcade/theme as agreed  
   - Acceptance: open panel → see levels/costs → buy → profile updates  
2. **Main Inventory (Figma port)**  
   - Source: Figma main inventory (weapons/pets/auras/… shell)  
   - Evolve `Inventory.lua` (INVETAR base) to match Figma 1:1 where possible  
   - No inventory layout experiments mid-BP  
3. **Battle Pass (Figma → shell → data)**  
   - First: static UI from Figma (track, free/premium rows, claim buttons disabled)  
   - Then: `profile.battlePass` XP, tiers, claim remotes  
4. Dust/gems strip; rebirth polish  
5. Boosts data model for top-left pills  
6. Mesh swords, hit VFX  
7. Boss → Loc2 unlock UX · dungeon real fight · relic equip · enchant transfer  
8. ~~Verify Character Upgrade icon asset ids~~ (filled in `UpgradeIconConfig`) · still verify in live Play

### P2 — Worlds map + Loc2–4 content
1. **Teleport pads / portal art** at each island (see §13) + Ferryman polish  
2. Loc2 markers Place · icons Loc2+ · content pass  
3. Drop tables Loc2 dump already in MobConfig/WeaponConfig  

### P3 — meta
1. Pets/auras/dungeons real content  
2. Leaderboard · full BP rewards live  
3. LIMITED events + VFX · **Wings** (§11 parked)  

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
| `ICON_UPLOAD.md` | rbxassetid иконок оружия |
| **§8.1 this file** | **UI Asset Registry** (upgrade/HUD icons) |
| **§8.2 this file** | **Potion Asset Registry** (idle + hover Open) |
| **§8.3 this file** | **UI extras** (QuestIcon + CoinShop 1–5) |
| `FIGMA_PROMPTS.md` | промпты AI/Figma + tracking иконок |
| `COLLAB.md` | Git + Team Create |
| `AGENT_MCP.md` | gh CLI + GitHub / Studio / Figma MCP for agents |
| **§13 this file** | Figma UI order + Roblox worlds/teleport design |

### 8.1 UI Asset Registry (LOCKED — remember & reuse)

Canonical rbxassetid for Figma UI icons. **Code source of truth:**  
`src/ReplicatedStorage/Shared/Config/UpgradeIconConfig.lua`  
PNG sources: `art/icons/upgrades/` · upload via Studio Asset Manager (see `ICON_UPLOAD.md` pattern).

| Key (config) | File / note | rbxassetid |
|--------------|-------------|------------|
| `Power` | icon_strength | `rbxassetid://93071491476836` |
| `Backpack` | icon_backpack | `rbxassetid://113695116998745` |
| `ClickSpeed` / `WalkSpeed` | icon_speed | `rbxassetid://101300421089207` |
| `CritChance` | icon_crit | `rbxassetid://94418234037518` |
| `MultiCrit` | icon_multicrit | `rbxassetid://75432680898371` |
| `Coin` | coin | `rbxassetid://80023959014102` |
| `Close` | close | `rbxassetid://94627396642381` |
| `Shop` | shop | `rbxassetid://133565026221740` |

```lua
-- paste-ready (UpgradeIconConfig)
Power = "rbxassetid://93071491476836",      -- icon_strength
Backpack = "rbxassetid://113695116998745",   -- icon_backpack
WalkSpeed = "rbxassetid://101300421089207", -- icon_speed (also ClickSpeed)
CritChance = "rbxassetid://94418234037518", -- icon_crit
MultiCrit = "rbxassetid://75432680898371",  -- icon_multicrit
Coin = "rbxassetid://80023959014102",
Close = "rbxassetid://94627396642381",
Shop = "rbxassetid://133565026221740",
```

**Agent rule:** when wiring Character Upgrade / HUD / Shop chrome, **use these IDs** via `UpgradeIconConfig.Get(key)` — do not invent placeholders or Creator Store free decals for these keys.

### 8.2 Potion Asset Registry (LOCKED — remember & reuse)

**Code source of truth:** `src/ReplicatedStorage/Shared/Config/PotionIconConfig.lua`  
Source PNGs: `ACCETSPOTIONS` batch (Big / Mid / Small / Globall).

#### Usage rule (UI)
| Asset suffix | When to show |
|--------------|----------------|
| `*Potion` (closed) | **Default** texture — player inventory + shop |
| `*PotionOpen` | **Only on hover** in inventory (swap `Image` on MouseEnter → Open, MouseLeave → closed) |

Shop always uses **closed** (`*Potion`). Never show Open permanently in grids.

#### Sizes / stats
- **Size:** `Small` · `Mid` · `Big` · `Globall` (global / server-wide)
- **Stat:** `Coin` · `Damage` · `Luck` · `Power`
- **Backgrounds:** plates for cards; Mid = solid black (park); Small cover = `Group 1261154050`

#### Full ID table

| # | File | Config key | rbxassetid |
|---|------|------------|------------|
| 1 | BigBackGroundPotion.png | `BigBackground` | `rbxassetid://87813480175029` |
| 2 | BigCoinPotion.png | `BigCoin` | `rbxassetid://123525448642522` |
| 3 | BigCoinPotionOpen.png | `BigCoinOpen` | `rbxassetid://85471490348637` |
| 4 | BigDamagePotion.png | `BigDamage` | `rbxassetid://77976545014734` |
| 5 | BigDamagePotionOpen.png | `BigDamageOpen` | `rbxassetid://100846431333192` |
| 6 | BigLuckPotion.png | `BigLuck` | `rbxassetid://93921132820014` |
| 7 | BigLuckPotionOpen.png | `BigLuckOpen` | `rbxassetid://114236597813508` |
| 8 | BigPowerPotion.png | `BigPower` | `rbxassetid://81684258283596` |
| 9 | BigPowerPotionOpen.png | `BigPowerOpen` | `rbxassetid://112355517693170` |
| 10 | GloballBackgroundPotion.png | `GloballBackground` | `rbxassetid://124907509434472` |
| 11 | GloballCoinPotion.png | `GloballCoin` | `rbxassetid://128739216534711` |
| 12 | GloballCoinPotionOpen.png | `GloballCoinOpen` | `rbxassetid://85854368587544` |
| 13 | GloballDamagePotion.png | `GloballDamage` | `rbxassetid://74581058727863` |
| 14 | GloballDamagePotionopen.png | `GloballDamageOpen` | `rbxassetid://87264874596741` |
| 15 | GloballLuckPotion.png | `GloballLuck` | `rbxassetid://138279482261455` |
| 16 | GloballLuckPotionOpen.png | `GloballLuckOpen` | `rbxassetid://113062484961240` |
| 17 | GloballPowerPotion.png | `GloballPower` | `rbxassetid://109834286119069` |
| 18 | GloballPowerPotionOpen.png | `GloballPowerOpen` | `rbxassetid://120037569836057` |
| 19 | Group 1261154050.png | `SmallCover` | `rbxassetid://71540050000210` (black cover for Small) |
| 20 | MidBackgroundPotion.png | `MidBackground` | `rbxassetid://83821392234258` (solid black plate — park) |
| 21 | MidCoinPotion.png | `MidCoin` | `rbxassetid://92630530796611` |
| 22 | MidCoinPotionOpen.png | `MidCoinOpen` | `rbxassetid://73785912682549` |
| 23 | MidDamagePotion.png | `MidDamage` | `rbxassetid://109446287175098` |
| 24 | MidDamagePotionOpen.png | `MidDamageOpen` | `rbxassetid://132235301402853` |
| 25 | MidLuckPotion.png | `MidLuck` | `rbxassetid://76287598017023` |
| 26 | MidLuckPotionOpen.png | `MidLuckOpen` | `rbxassetid://115289485411140` |
| 27 | MidPowerPotion.png | `MidPower` | `rbxassetid://98113276595328` |
| 28 | MidPowerPotionOpen.png | `MidPowerOpen` | `rbxassetid://85900601718525` |
| 29 | SmallCoinPotion.png | `SmallCoin` | `rbxassetid://129754362855584` |
| 30 | SmallCoinPotionOpen.png | `SmallCoinOpen` | `rbxassetid://135452551473185` |
| 31 | SmallDamagePotion.png | `SmallDamage` | `rbxassetid://126425760044867` |
| 32 | SmallDamagePotionOPen.png | `SmallDamageOpen` | `rbxassetid://131125671762922` |
| 33 | SmallLuckPotion.png | `SmallLuck` | `rbxassetid://97002801957265` |
| 34 | SmallLuckPotionOpen.png | `SmallLuckOpen` | `rbxassetid://127967918786290` |
| 35 | SmallPowerPotion.png | `SmallPower` | `rbxassetid://115507101515088` |
| 36 | SmallPowerPotionOpen.png | `SmallPowerOpen` | `rbxassetid://81848929788674` |

**Agent rule:** wire potions via `PotionIconConfig.GetIdle(size, stat)` / `GetHover(size, stat)` — do not hardcode free decals. Hover swap Open **only in inventory**.

### 8.3 Quest + Coin Shop icons (LOCKED — remember & reuse)

**Code source of truth:** `src/ReplicatedStorage/Shared/Config/UiIconConfig.lua`  
Recorded 2026-07-20 from Studio upload — **do not lose these IDs**.

| Key (config) | Note | rbxassetid |
|--------------|------|------------|
| `QuestIcon` | Quest UI / rail / panel | `rbxassetid://111972532166796` |
| `CoinShop` / `CoinShop1` | Coin shop tier 1 | `rbxassetid://126265387260987` |
| `CoinShop2` | Coin shop tier 2 | `rbxassetid://92652371656965` |
| `CoinShop3` | Coin shop tier 3 | `rbxassetid://122342766899212` |
| `CoinShop4` | Coin shop tier 4 | `rbxassetid://107120449770577` |
| `CoinShop5` | Coin shop tier 5 | `rbxassetid://70679769514889` |

```lua
-- paste-ready (UiIconConfig)
QuestIcon = "rbxassetid://111972532166796",
CoinShop  = "rbxassetid://126265387260987", -- also CoinShop1
CoinShop2 = "rbxassetid://92652371656965",
CoinShop3 = "rbxassetid://122342766899212",
CoinShop4 = "rbxassetid://107120449770577",
CoinShop5 = "rbxassetid://70679769514889",
```

**Agent rule:** wire via `UiIconConfig.Get("QuestIcon")` / `UiIconConfig.GetCoinShop(1..5)` — do not invent placeholders.

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

## 13. Figma UI track + how “worlds” / teleports work in Roblox

### 13.1 Figma → game (what we need next)

| Screen (Figma) | In game today | Target | When |
|----------------|---------------|--------|------|
| **Character Upgrade** | Basic upgrades list in `Windows` + `UpgradeConfig` / `BuyUpgrade` | Full Figma layout, same remotes | **FIRST test** |
| **Main Inventory** | `Inventory.lua` INVETAR shell (E/I) | Figma main bag 1:1 polish | After Character Upgrade OK |
| **Battle Pass** | None | Figma shell → then XP/tiers/claim | After Main Inventory |

**Pipeline (every screen):**
1. Figma frame(s) + EN copy (or translate to EN before code)  
2. Agent/dev maps components → Fusion/`UIKit`/`Theme`  
3. Bind **existing** remotes/configs first; new remotes only if needed  
4. Playtest one screen end-to-end before the next  

**Character Upgrade test checklist:**
- [ ] Open from HUD/rail (same bind as upgrades / character)  
- [ ] Rows match upgrade defs (Power, ClickSpeed, Backpack, Crit locked Loc3+, …)  
- [ ] Cost + level + Locked state from `UpgradeConfig.IsUnlocked`  
- [ ] Click Upgrade → `Net.BuyUpgrade` → coins down, level up, toast  
- [ ] No RU player strings  

---

### 13.2 Minecraft Realms vs Roblox “worlds” (важно)

| | Minecraft Realms / multi-world | Typical popular Roblox sim |
|--|-------------------------------|----------------------------|
| Worlds | Separate dimensions/servers | **Usually one Place** (one universe map) |
| Travel | Portal → other dimension | **Teleport player CFrame** to another island/zone |
| Data | Different world files | **Same DataStore profile** always |
| Loading | Chunk/dimension load | Instant (or short fade UI) |

**What big clicker / sword / pet sims do (Pet Sim, Anime Fighting, Blade Ball hubs, etc.):**

1. **One place, many “maps”**  
   - Loc1 forest, Loc2 ship, Loc3… built far apart in **Workspace** (islands, skyboxes, walls).  
   - Player walks to a **pad / portal / NPC** → ProximityPrompt **Travel** → server checks unlock →  
     `character:PivotTo(spawnCFrame)` (we already do this via `WorldService.TeleportToLocation` + `SetLocation`).  

2. **Optional: TeleportService to another Place**  
   - Only when map is huge or you need separate game instances (raid place, trading hub).  
   - Harder: same profile must load in place B; more Studio places to maintain.  
   - **Not recommended for Loc1–4 now.**  

**Our decision (locked for Loc1–4):**  
→ **One Roblox place**, locations = zones/islands.  
→ Travel = **in-place teleport**, not a new universe.

---

### 13.3 How travel works *in our project already*

```
Player near Ferryman / Travel UI
  → client OpenTravel / locations panel
  → Net.SetLocation(locId)
  → LocationService.Set (R2 + 500K for Loc2 first time, etc.)
  → profile.currentLocation = locId
  → WorldService.TeleportToLocation(player, locId)  -- CFrame to spawn
  → mobs for that location already exist / markers
```

| Piece | Role |
|-------|------|
| `WorldConfig` | Island centers, spawn CFrames, zone math |
| `LocationConfig` | Unlocks, mob spawns per loc |
| `LocationService` | Gate + set current location |
| `FerrymanService` | NPC + ProximityPrompt “Travel” → `OpenTravel` |
| Place art (you/friend) | Portal mesh, pad, VFX at each island |

**Player fantasy “подхожу к телепортеру → открывается другой мир”:**
1. Build a **portal prop** on Loc1 near spawn (Place).  
2. Put **ProximityPrompt** *Travel* (or reuse Ferryman).  
3. On trigger → open locations UI **or** auto `SetLocation(2)` if unlocked.  
4. Server teleports character to Loc2 spawn CFrame — looks like a new world, same server.  
5. Optional: black fade ScreenGui 0.3s so jump feels like loading a realm.

**Do not** create a second Roblox experience/place for Loc2 unless we outgrow one map.

---

### 13.4 Place checklist (friend / map)

- [ ] Loc1 island + spawn `PlayerSpawn` / WorldConfig spawn  
- [ ] Loc2 island far enough (no see Loc1)  
- [ ] Portal pad on each island (prompt → travel UI)  
- [ ] Optional: `OpenTravel` only; never free-teleport locked locs  
- [ ] Ferryman can stay as alternate entry  

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
