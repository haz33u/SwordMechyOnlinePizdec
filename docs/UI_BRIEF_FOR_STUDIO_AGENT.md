# UI BRIEF — Sword Masters (compact number)  
## Для Roblox Studio Agent + художников UI

**Язык UI:** русский (как на reference game).  
**Стиль:** тёмный RPG / SAO-sim — полупрозрачные панели, чёткая иерархия, крупные цифры силы, без «детского симулятора».  
**Backend уже есть.** UI **не** считает геймплей сам — только показывает `ProfileUpdate` / `GetProfile` и шлёт remotes.

---

# 1. СУТЬ ЗАМЫСЛА (1 абзац)

Игрок — **мастер меча**: кликает (или включает автокликер), убивает мобов на локациях, копит **силу** и **монеты**, прокачивает персонажа, надевает **мечи** (две руки), **питомцев**, **ауры**, **реликвии**, делает **перерождения**, ходит в **подземелья** и закрывает **квесты**. UI должен ощущаться как **клиент мини-игры reference game**: постоянный HUD боя + модальные окна прогресса, инвентаря и карты, без перегруза одним экраном.

---

# 2. ГЛАВНЫЕ ПРИНЦИПЫ UI

1. **HUD всегда на экране** во время фарма (сила, CPS, монеты, клики, авто).  
2. **Окна по запросу** (кнопки на HUD / hotkeys) — не всё сразу.  
3. **Одно модальное окно поверх** (или вкладки внутри одного shell) — не 10 окон друг на друге.  
4. **Крупные числа:** сила, CPS, DPS, монеты — как на reference game (K / M / B).  
5. **Обратная связь:** toast/notify при дропе, квесте, rebirth, ошибке.  
6. **Клиент не читерит:** только remotes из backend.  
7. **Адаптив:** Scale на ScreenGui, якоря по краям (как в MM — инфо слева/сверху, слоты снизу/справа).

---

# 3. СЛОВАРЬ (как называть в UI)

| Термин в UI | Смысл |
|-------------|--------|
| **Сила** | TotalPower / урон за клик |
| **Клики** | totalClicks |
| **CPS** | кликов в секунду |
| **DPS** | сила × CPS |
| **Монеты** | soft currency (coins) |
| **Перерождение** | Rebirth |
| **Множитель** | rebirthMult (×1.25 …) |
| **Скорость удара** | ап / чар на CPS |
| **Скорость бега** | walk speed ап |
| **Рюкзак** | слоты инвентаря (ап) |
| **Удача** | luck ап / чар |
| **Крит** | шанс ×2 урона |
| **Меч (осн.)** | main hand |
| **Меч (втор.)** | offhand |
| **Зачарование** | roulette enchants |
| **Питомец** | pet |
| **Слот питомца** | petSlots |
| **Аура** | aura (1 экип) |
| **Реликвия** | relic / бижутерия |
| **Локация** | Loc 1–4 (позже больше) |
| **Подземелье** | лёгкое / среднее / сложное |
| **Квест** | задание NPC |
| **Автокликер** | auto farm toggle |
| **Бан дропа** | hide trash weapons/pets |

---

# 4. КОЛИЧЕСТВО ОКОН (иерархия)

## Уровень A — всегда (1 «слой»)

| # | Имя | Тип |
|---|-----|-----|
| **A1** | **HUD** | ScreenGui, не модальный |

## Уровень B — основные окна (открываются с HUD)

Рекомендуется **1 Shell + вкладки**, либо отдельные Frame.  
Итого **6–8 основных окон**:

| # | Окно | Приоритет |
|---|------|-----------|
| **B1** | **Персонаж / Улучшения** | must |
| **B2** | **Инвентарь оружия** | must |
| **B3** | **Питомцы** | must |
| **B4** | **Ауры** | must |
| **B5** | **Реликвии** | must mid |
| **B6** | **Квесты** | must |
| **B7** | **Локации / Карта** | must |
| **B8** | **Подземелья** | must mid |

## Уровень C — диалоги / подтверждения

| # | Окно |
|---|------|
| **C1** | **Перерождение** (confirm + прогресс-бар урона) |
| **C2** | **Зачарование меча** (результат ролла) |
| **C3** | **Кейс** (открытие пета / ауры — анимация) |
| **C4** | **Подтверждение продажи** |
| **C5** | **Toast / Notify** (не модалка, очередь 1–3) |

## Уровень D — опционально позже

| # | Окно |
|---|------|
| D1 | Настройки (звук, авто, качество) |
| D2 | Топ / лидерборд (когда backend даст) |
| D3 | Банда (нет в backend пока) |
| D4 | Battle Pass / донат (нет в backend — **не делать**) |

**Итого для MVP UI:**  
**1 HUD + 8 окон B + 5 лёгких C ≈ 14 UI-сущностей**, но на экране одновременно: **HUD + 1 окно B + toast**.

---

# 5. СТРУКТУРА КАЖДОГО ОКНА

## A1. HUD (постоянный)

**Раскладка (reference game-like):**

```
┌─ TOP BAR ─────────────────────────────────────────────┐
│ Сила: 1.2M   CPS: 12.5   DPS: 15M   Монеты: 50K      │
│ Клики: 1.5M  Локация: Тёмный лес   R: 3 (×2.19)      │
└───────────────────────────────────────────────────────┘

┌ LEFT QUICK ─┐                    ┌ RIGHT EQUIP ──────┐
│ [Авто ВКЛ]  │                    │ Меч1 icon         │
│ [Перерожд.] │                    │ Меч2 icon         │
│ [Квесты 2!] │                    │ Аура icon         │
└─────────────┘                    │ Петы 3/5          │
                                   └───────────────────┘

┌────────── BOTTOM DOCK ────────────────────────────────┐
│ [Персонаж] [Оружие] [Питомцы] [Ауры] [Реликвии]       │
│ [Квесты] [Локации] [Подземелья]                       │
└───────────────────────────────────────────────────────┘

         [ большая кнопка КЛИК — опционально на мобиле ]
```

**Данные:** `stats` из `ProfileUpdate` / `GetProfile`.  
**Кнопки:**
- Авто → `ToggleAutoClicker`
- Клик (если есть) → `Swing(nil, "manual")`
- Перерождение → открыть **C1**
- Док → открыть B1–B8

**Hotkeys (PC):**
| Клавиша | Действие |
|---------|----------|
| Space / E | Swing manual |
| T | Toggle auto |
| R | Open rebirth |
| I | Оружие |
| P | Питомцы |
| J | Квесты |
| M | Локации |
| Esc | Закрыть окно |

---

## B1. Персонаж / Улучшения

**Заголовок:** «Улучшение персонажа»  
**Вкладки (внутри):** Обзор | Улучшения  

**Обзор:**
- Сила, CPS, DPS, Крит %, Удача %
- Уровень перерождения + множитель
- Прогресс до след. rebirth (lifetimeDamage / nextRebirthCost)

**Улучшения** — список карточек:

| ID ап | Название UI | Remote |
|-------|-------------|--------|
| RunSpeed | Скорость бега | BuyUpgrade("RunSpeed") |
| Backpack | Рюкзак | BuyUpgrade("Backpack") |
| Power | Сила | BuyUpgrade("Power") |
| ClickSpeed | Скорость удара | BuyUpgrade("ClickSpeed") |
| CritChance | Крит | BuyUpgrade("CritChance") |
| Luck | Удача | BuyUpgrade("Luck") |

Каждая карточка: уровень, эффект, **цена в монетах**, кнопка «Улучшить».

---

## B2. Инвентарь оружия

**Заголовок:** «Оружие»  
**Слоты экипа (верх):**
- Основная рука (main)
- Вторая рука (offhand)

**Сетка инвентаря:** все `profile.weapons`  
Карточка меча: имя, rarity цвет, mult, чары (короткий список).

**Действия по клику на меч:**
- Надеть (осн.) → `EquipWeapon(uid, "main")`
- Надеть (втор.) → `EquipWeapon(uid, "offhand")`
- Зачаровать → `EnchantWeapon(uid)` + окно C2
- Продать → confirm C4 → `SellWeapon(uid)`
- Бан дропа этого id → `BanDrop("weapon", id, true)`

**Цвета rarity:**  
Common серый · Uncommon зелёный · Rare синий · Epic фиолет · Legendary оранж · Mythic розовый · **Secret** золотой glow · **Limited** hot pink + анимированный бейдж (VFX).

---

## B3. Питомцы

**Заголовок:** «Питомцы»  
**Слоты команды:** `petSlots` ячеек (1…7) — `petTeam`  
**Инвентарь:** все `pets`  
**Кнопки:**
- Открыть кейс → `OpenPetCase` (+ C3 анимация)
- Надеть → `EquipPet`
- Снять → `UnequipPet`
- Покормить → `FeedPet`
- Бан → `BanDrop("pet", id, true)`

Показ: имя, rarity, % силы / монет / speed, level.

---

## B4. Ауры

**Заголовок:** «Ауры»  
**Активная аура** — 1 слот крупно  
**Коллекция** — сетка  
- Открыть кейс → `OpenAuraCase`  
- Экип → `EquipAura`  
Показ: % силы, % урона, % монет, rarity.

---

## B5. Реликвии

**Заголовок:** «Реликвии»  
Слоты экипа (3–6) + инвентарь `relics`  
Пока backend без отдельного EquipRelic remote — **только отображение** `equippedRelics` / список;  
*(если нужно экипировать — попросить backend добавить remote; пока UI read-only или заглушка)*.

Показ: % силы, % урона, stars.

---

## B6. Квесты

**Заголовок:** «Задания»  
Список `profile.quests` + имена из конфига (можно захардкодить словарь id→название на клиенте).

Состояния:
- В процессе: progress / amount + progress bar  
- Готово: кнопка «Сдать» → `ClaimQuest(id)`  
- Сдано: серым  

Фильтры: Активные | Завершённые.

---

## B7. Локации / Карта

**Заголовок:** «Локации»  
**4 карточки (Phase 1):**

| # | Название |
|---|----------|
| 1 | Тёмный лес |
| 2 | Пиратский берег |
| 3 | Земли шиноби |
| 4 | Полярная тундра |

На карточке:
- Название, статус (открыта / закрыта)
- Требуемая сила (`unlockPower`)
- Кнопка «Отправиться» → `SetLocation(id)`
- Текущая локация — рамка «Вы здесь»

Опционально: мини-схема 2×2.

---

## B8. Подземелья

**Заголовок:** «Подземелья»  
3 карточки:

| id | Название UI |
|----|-------------|
| easy | Лёгкое |
| medium | Среднее |
| hard | Сложное |

Показ: стадия `dungeonStage[id]`, кнопка «Войти» → `StartDungeon(id)`  
Сообщение о кулдауне врат — из `Notify`.

---

## C1. Перерождение

**Модалка по центру**  
- Текст: «Переродиться?»  
- Прогресс: `lifetimeDamage / nextRebirthCost`  
- Текущий R и будущий mult (примерно)  
- Кнопки: «Переродиться» → `RequestRebirth` | «Отмена»  

---

## C2. Результат зачарования

После `EnchantWeapon` — toast или мини-окно:  
«Бустер силы +91% (Мощный)» — данные лучше слать через `Notify` / будущий remote; пока парсить Notify text или ждать `ProfileUpdate` и diff enchants.

---

## C3. Кейс (пет / аура)

Короткий reveal 1–2 сек (blur → icon rarity) → обновить из ProfileUpdate.

---

## C5. Toast

Очередь снизу/сверху, 2–3 сек, цвета:  
green успех · red ошибка · gold дроп · purple rebirth · cyan локация · pink питомец  

Слушать: `Remotes.Notify`.

---

# 6. ПОТОК ДАННЫХ (для Agent)

```
Start:
  data = Remotes.GetProfile:InvokeServer()
  bind UI to data.profile / data.stats

On Remotes.ProfileUpdate:
  refresh all open panels + HUD

On Remotes.CombatFx:
  optional floating damage number (world or screen)

Buttons:
  only FireServer listed remotes — no local power math
```

**Формат больших чисел:**  
`1234` → `1.2K`, `1.5e6` → `1.5M`, `2e9` → `2.0B`.

---

# 7. ВИЗУАЛЬНЫЙ СТИЛЬ (reference game vibe)

| Элемент | Рекомендация |
|---------|----------------|
| Фон панелей | Тёмно-синий/уголь, transparency 0.15–0.3 |
| Обводка | Тонкая светлая / золотая на legendary |
| Шрифт | Gotham / Montserrat-like, title bold |
| Акцент | Бирюза / золото / фиолет для epic |
| Иконки | Меч, лапка, аура-круг, сундук, череп данжа |
| Анимации | Tween open 0.15s, hover scale 1.02 |
| Не | Яркий rainbow UI, огромный текст «FREE ROBUX» |

Референс-ощущение: **панель мини-игры reference game + SAO HUD**, не Pet Simulator.

---

# 8. ПОРЯДОК СБОРКИ UI (спринты)

### Sprint 1 — играбельно
1. HUD (сила, монеты, CPS, авто, клик)  
2. Toast Notify  
3. Окно Улучшения  
4. Окно Перерождение  

### Sprint 2 — лут
5. Оружие  
6. Питомцы  
7. Ауры  

### Sprint 3 — мир
8. Локации  
9. Квесты  
10. Подземелья + реликвии (read-only)  

### Sprint 4 — полиш
11. Анимации кейсов  
12. Floating damage  
13. Mobile layout  

---

# 9. СТРУКТУРА ИНСТАНСОВ В STUDIO (рекомендация)

```
StarterGui
└── GameUI (ScreenGui, ResetOnSpawn=false)
    ├── HUD
    │   ├── TopBar
    │   ├── LeftQuick
    │   ├── RightEquip
    │   └── BottomDock
    ├── Windows (Folder)
    │   ├── CharacterWindow
    │   ├── WeaponsWindow
    │   ├── PetsWindow
    │   ├── AurasWindow
    │   ├── RelicsWindow
    │   ├── QuestsWindow
    │   ├── LocationsWindow
    │   └── DungeonsWindow
    ├── Modals
    │   ├── RebirthModal
    │   ├── EnchantResult
    │   ├── CaseReveal
    │   └── ConfirmSell
    ├── ToastLayer
    └── Controllers (LocalScripts or ModuleScripts)
        ├── UIBootstrap
        ├── HudController
        ├── WindowManager
        ├── WeaponsController
        └── ...
```

**WindowManager:** только одно B-окно Visible=true; Esc закрывает.

---

# 10. ЧЕГО НЕ ДЕЛАТЬ

- Не считать силу/CPS на клиенте «от себя» — только stats с сервера.  
- Не делать донат-магазин / BP (backend не готов).  
- Не плодить 15 модалок одновременно.  
- Не дублировать DataStore.  
- Не ломать `ReplicatedStorage.Shared` / Server scripts.

---

# 11. ПРОМПТ ДЛЯ STUDIO AGENT (скопировать целиком)

```
You are building the CLIENT UI only for a Roblox game "Sword Masters" (reference game minigame style).

BACKEND is already implemented. Do NOT rewrite ServerScriptService or ReplicatedStorage.Shared.
Use remotes under ReplicatedStorage.Remotes (created at runtime by server).

GOAL: reference game-like dark RPG UI in Russian.

ALWAYS ON:
- HUD: Power (Сила), CPS, DPS, Coins (Монеты), total Clicks, Location name, Rebirth level + mult, Auto-clicker toggle, dock buttons.

MAIN WINDOWS (open one at a time from dock):
1) Персонаж/Улучшения — upgrades RunSpeed, Backpack, Power, ClickSpeed, CritChance, Luck via BuyUpgrade
2) Оружие — list weapons, equip main/offhand, sell, enchant
3) Питомцы — team slots, inventory, OpenPetCase, Equip/Unequip/Feed
4) Ауры — one equipped, OpenAuraCase, EquipAura
5) Реликвии — display relics (read-only if no equip remote)
6) Квесты — progress + ClaimQuest
7) Локации — Loc1–4 cards, SetLocation
8) Подземелья — easy/medium/hard, StartDungeon

MODALS: Rebirth confirm, enchant result, case reveal, sell confirm.
TOASTS: listen to Notify remote.

DATA:
- On start Invoke GetProfile
- Listen ProfileUpdate { profile, stats }
- CombatFx for optional damage numbers
- Manual click: Swing(nil, "manual"); Auto: ToggleAutoClicker; auto loop may FireServer Swing(nil,"auto") at stats.swingCd

STYLE: dark panels, rarity colors, big numbers with K/M/B, Russian labels, smooth tweens.
NO donate UI. NO world building. Map is separate.

Structure under StarterGui.GameUI as HUD + Windows + Modals + ToastLayer + LocalScript controllers.
```

---

# 12. СВЯЗЬ С BACKEND (краткий remote map)

| UI действие | Remote |
|-------------|--------|
| Клик | Swing(nil, "manual") |
| Авто вкл/выкл | ToggleAutoClicker |
| Авто тик | Swing(nil, "auto") |
| Ап | BuyUpgrade(id) |
| Rebirth | RequestRebirth |
| Экип меча | EquipWeapon(uid, slot) |
| Продажа | SellWeapon(uid) |
| Чар | EnchantWeapon(uid) |
| Кейс пета | OpenPetCase |
| Кейс ауры | OpenAuraCase |
| Пет экип | EquipPet / UnequipPet / FeedPet |
| Аура | EquipAura |
| Квест | ClaimQuest(id) |
| Локация | SetLocation(n) |
| Данж | StartDungeon(tier) |
| Обновление UI | ProfileUpdate, GetProfile |

Полный список: `docs/BACKEND_API.md`.

---

**Конец брифа.**  
Agent: собери UI по Sprint 1→4.  
Backend-owner: при нехватке remote (экип реликвий) — добавить в GitHub, не костылить на клиенте.
