# Промпт для доделки визуала мечей, аур и реликвий

> Использовать в новой сессии Claude / Roblox Studio Agent.
> Работаем поверх текущего состояния ветки `main` (есть незакоммиченные изменения в аурах и DungeonService).

## 0. Что УЖЕ сделано в прошлой сессии

Изменены файлы (не нужно повторять, только проверить в игре):

1. `src/ReplicatedStorage/Shared/Config/AuraModelConfig.lua`
   - `TargetExtent` 2.2 → 1.5
   - `OffsetByMode.feet` Y -2.2 → -1.5
   - `OffsetByMode.back` Y 0.3 → 0.2, Z 0.65 → 0.45
2. `src/StarterPlayerScripts/AuraVisual.lua`
   - `AuraLight.Range` 14 → 10, `Brightness` 2.0 → 1.2
   - Орбиты: `radius` 2.4 → 1.6, `bob` 0.3 → 0.2
3. `src/StarterPlayerScripts/WeaponVisual.lua`
   - `auraRoot.Size` multiplier 0.35 → 0.25
4. `src/ServerScriptService/Services/DungeonService.lua`
   - Реликвии с этажа ×10 теперь учитывают `source`: easy/medium/hard в зависимости от глубины.
   - В уведомление добавлена метка `(Easy/Medium/Hard Dungeon)`.

## 1. ЦЕЛИ (по приоритету)

### 1.1 Мечи второй локации выглядят "оборванными"

**Симптом:** мечи Loc2 (Pirate Shore) в руке/иконке выглядят как будто неполноценные, по деталям.

**Что проверить и исправить:**

- В `src/ReplicatedStorage/Shared/Config/WeaponModelConfig.lua` `ModelByWeaponId` для Loc2 смотрит на:
  - `PirateHook`, `PirateHammer`, `PirateSaber`, `GoldenPlatedSword`, `CaptainAxe`, `ElementBlade`, `EmeraldBlade`, `SeaDagger`.
- Генератор `tools/generate_loc2_weapons.lua` создаёт эти модели в `ReplicatedStorage.WeaponModels`.
- Проблема: модели могут быть слишком простыми (например, отсутствуют guard/gem/skull/hook-tip детали), или `TargetLengthStuds = 6.0` + `DefaultScale = 0.50` сжимает их так, что детали сливаются.

**Действия:**

1. Запустить `tools/generate_loc2_weapons.lua` в Studio Command Bar.
2. Проверить каждую модель в Edit mode: выделить, посмотреть bounding box, PrimaryPart, `SM_Hilt`.
3. Для каждого меча добавить недостающие детали:
   - `PirateHook` — крюк должен быть читаемым дугой, не просто палкой.
   - `PirateHammer` — боёк должен быть массивнее рукояти.
   - `PirateSaber` — корзина/гарда и изогнутое лезвие.
   - `GoldenPlatedSword` — крестовина и золотое лезвие.
   - `CaptainAxe` — двусторонний топор и череп.
   - `ElementBlade` — неоновое лезвие с гардой.
   - `EmeraldBlade` — кристальное лезвие.
   - `SeaDagger` — волнистое лезвие и раковина/жемчужина на гарде.
4. При необходимости добавить/поправить `HiltOverrides` для Loc2 в `WeaponModelConfig.lua` (если рукоять держит не за ту сторону).
5. Перегенерировать иконки для Loc2 либо через 3D Viewport (авто), либо отрендерить PNG в `art/icons/weapons/` и прописать `IconConfig.WeaponAssetIds`.

### 1.2 Inferno Blade, Volcano God Sword, Obsidian Glaive — нет модели и иконки

**Каталог:** `src/ReplicatedStorage/Shared/Config/WeaponConfig.lua` Loc5 (Ash Canyons):

- `obsidian_glaive` — Epic
- `inferno_blade` — Legendary
- `volcano_god_sword` — Mythic
- `phoenix_ash_blade` — Secret (тоже проверить, но приоритет ниже)

**Контракт в `WeaponModelConfig.lua`:**

```lua
obsidian_glaive = "ObsidianGlaive",
inferno_blade = "InfernoBlade",
volcano_god_sword = "VolcanoGodSword",
phoenix_ash_blade = "PhoenixAshBlade",
```

**Действия:**

1. Создать генератор `tools/generate_loc5_weapons.lua` по аналогии с `generate_loc2_weapons.lua`.
2. Построить в `ReplicatedStorage.WeaponModels`:
   - `ObsidianGlaive` — длинное древко + обсидиановое лезвие-кривизна, красные трещины.
   - `InfernoBlade` — двуручный меч с пылающим лезвием, гарда в форме клыков.
   - `VolcanoGodSword` — массивный меч с кристаллом-магмой в центре, лава стекает по лезвию.
   - `PhoenixAshBlade` — лезвие из пепла/пера, золотые акценты.
3. Для каждого добавить детали: guard, pommel, core gem, lava drips/embers (Part с Neon/ParticleEmitter не обязательны, но силуэт должен быть узнаваем).
4. Проверить `SM_Hilt` (рукоять должна держаться за рукоять, не за лезвие).
5. Обновить `IconConfig.WeaponAssetIds`:
   - либо оставить пустым `""` чтобы использовался 3D Viewport,
   - либо отрендерить 512×512 PNG и прописать `rbxassetid://...`.
6. Если используем 3D Viewport, убедиться что `WeaponModels.HasVisual(id)` возвращает `true` и иконка появляется в инвентаре.

### 1.3 Ауры слишком большие

**Уже уменьшены в конфиге. Нужно:**

1. Запустить Play и экипировать ауры разной редкости.
2. Убедиться, что `TargetExtent = 1.5` не делает mesh-ауру слишком маленькой (некоторые модели могут иметь невидимые хитбоксы).
3. Если конкретная аура всё ещё огромная (например, `A_Blackhole`, `A_Cosmic`, `A_Heavenly`), добавить пер-ауру мультипликатор в `AuraModelConfig` или уменьшить `normalizeExtent` для этой модели.
4. Проверить weapon-ауру: в `WeaponVisual.lua` `auraRoot.Size = auraRoot.Size * 0.25` — если aura root — весь PrimaryPart, это может искажать. Если VFX пропадает, увеличить до 0.30.

### 1.4 Relic — разобраться

**Уже сделано:**

- `RelicConfig.lua` — каталог реликвий с `source`.
- `RelicService.lua` — equip/unequip/upgrade stars.
- `DungeonService.lua` — выдача реликвии каждые 10 этажей с правильным `source`.

**Что проверить и доделать:**

1. **UI Relic слоты.** В `InventoryWeaponsLayout.lua` слоты `RELICcard1..3` сейчас пустые (`bindEquipHover(... false, nil, ...)`). Нужно:
   - отображать экипированные реликвии в слотах 1..3,
   - показывать иконку/имя/звёзды,
   - при наведении tooltip: имя, редкость, `POWER +X%`, `DAMAGE +Y%`, `COINS +Z%`.
2. **Реликвии в инвентаре.** В `Inventory.lua` / `InventoryWeaponsLayout.lua` вкладка `relics` либо отсутствует, либо не рендерит список. Нужно добавить grid со всеми `profile.relics`:
   - клик — equip/unequip,
   - кнопка upgrade star (если хватает coins),
   - locked-флаг (Ctrl+MMB) как у мечей.
3. **Auto-equip.** `RelicService.TryAutoEquip` уже работает, но после изменения `source` убедиться, что реликвия действительно экипируется при получении.
4. **Сохранение.** `ProfileService` должен сохранять `profile.relics` и `profile.equippedRelics`. Проверить, что `source` не ломает сериализацию (plain string OK).
5. **Баланс.** Убедиться, что `Formulas.GetMaxRelicSlots(profile)` возвращает 2 (или 3 с gamepass) — иначе auto-equip не сработает.

## 2. Рекомендуемый порядок работы

1. **Сначала Relic UI** — это чистый код, не требует Studio-генерации.
2. **Затем Loc2 модели** — запустить генератор, доработать детали.
3. **Затем Loc5 модели** — создать генератор, запустить, проверить hilts.
4. **Наконец ауры** — Play-тест и подгонка масштаба.

## 3. Что НЕ трогать

- Не менять баланс `WeaponConfig.powerMult` / `sellPrice`.
- Не менять дроп-шансы в `LootService`.
- Не удалять существующие модели Loc1/Loc3/Loc4.
- Не переписывать `WeaponModels.lua` / `WeaponVisual.lua` целиком — только конфиг/оверрайды.

## 4. Как проверить результат

- Play в Studio.
- Открыть инвентарь → мечи: у Loc2 мечей должны быть читаемые иконки и не быть "оборванными".
- Выдать себе `obsidian_glaive`, `inferno_blade`, `volcano_god_sword` через debug/команду — проверить модель в руке и иконку.
- Экипировать ауры Rare+ — убедиться, что аура не закрывает половину экрана.
- Пройти/симулировать Dungeon до этажа ×10 — получить реликвию, увидеть UI, auto-equip, tooltip.
