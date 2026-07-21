# Иконки мечей (инвентарь)

## Порядок в UI (live)

```
WeaponModels has mesh for weaponId?
  YES → ViewportFrame 3D (WeaponModels.TryFillInventoryIcon)
        fail → "?" glyph (not legacy reference game PNG)
  NO  → IconConfig Decal / FallbackWeapon
```

Код: `Inventory.lua` · `WeaponModels.FillViewport` (resets Place WorldPivot, frames camera).  
Viewport **Active=false**, ZIndex 40 — клики equip ок.

### Debug
- Success: slot shows 3D sword (slight dark plate behind mesh while tuning).  
- Fail: `?` + Output `[WeaponModels] 3D icon failed for <id>`.  
- Old pink/grey PNGs only if `IconConfig.PreferLegacyDecals = true`.

---

## Опционально: Decal PNG (IconConfig)

Если нужен «плоский» арт поверх 3D — заполни `IconConfig` и при желании
поставь приоритет Decal в Inventory (сейчас 3D побеждает, когда mesh есть).

---

## Цепочка

```
1. PNG 256–512 (прозрачный фон, меч по центру)
2. Studio → Asset Manager → Bulk Import (Images)
3. ПКМ → Copy Id  →  rbxassetid://ЧИСЛО
4. Вписать в IconConfig.WeaponAssetIds[weaponId]
5. git commit + push  (тиммейтам upload не нужен)
6. rojo serve → Play → слот Weapons
```

Rojo **не** публикует PNG сам — только `rbxassetid` из git.

---

## Куда писать id

Файл: `src/ReplicatedStorage/Shared/Config/IconConfig.lua`

Ключ = **dump weapon id** (snake_case), не имя модели Studio:

| weaponId (код / IconConfig) | Model в WeaponModels (3D) | Иконка сейчас |
|-----------------------------|---------------------------|---------------|
| `starter_weapon` | StarterSword | ✅ rbxassetid |
| `old_sword` | IronSword | ✅ |
| `bone_dagger` | PixelIronSword | ✅ |
| `wooden_mace` | GoldSword | ✅ |
| `double_edged_sword` | RubySword | ✅ |
| `forest_spirit_staff` | DiamondSword | ✅ |
| `ardite` | *(позже)* | ✅ (старый арт) |
| `forest_sword` | *(позже)* | ✅ |
| `forest_shadow` | *(позже)* | ✅ |
| Loc2 `pirate_*` … | — | ❌ пусто → FallbackWeapon |

Новый меч:

```lua
WeaponAssetIds = {
  starter_weapon = "rbxassetid://116982617153585",
  -- ...
  my_new_blade = "rbxassetid://НОВОЕ_ЧИСЛО",
}
```

И **тот же** id в `WeaponConfig` + (если есть 3D) `WeaponModelConfig.ModelByWeaponId`.

---

## Как сделать PNG

| Способ | Как | Когда |
|--------|-----|--------|
| **A. AI / Figma** | Промпт в `docs/FIGMA_PROMPTS.md`, стиль как `art/icons/weapons/` | красивый единый стиль |
| **B. Скрин 3D** | Studio: модель на нейтральном фоне → скрин → вырезать фон | 1:1 с мечом в руке |
| **C. Viewport export** | Не в runtime-слоте; оффлайн скрин Viewport | ок для черновика |
| **D. Fallback** | Пустой id → `FallbackWeapon` generic | временно |

Рекомендация для **новых 6 free-мечей**:  
старые Loc1 иконки в IconConfig **уже есть** (compact number арт).  
Если хочешь иконку **точно как free mesh** — сделай скрин каждого из `WeaponModels` и перезапиши id.

Имя файла удобно = weaponId: `starter_weapon.png`, `old_sword.png`, …

---

## Studio upload (детали)

1. Place открыт, ты/группа = владелец  
2. **View → Asset Manager → Images → Bulk Import**  
3. Дождись Completed  
4. Copy Id → в `IconConfig`  
5. Permissions: asset usable in experiences (обычно авто для creator)

---

## Проверка

| Симптом | Причина |
|---------|---------|
| Generic меч в слоте | id пустой / опечатка в ключе |
| Картинка не грузится | id чужого аккаунта / не Image |
| 3D в руке ок, слот другой | нормально: разные пайплайны |
| Rojo Connect, id в git, слот пустой | Ctrl+Shift+R rejoin / asset moderation |

---

## Не путать

| Вещь | Где |
|------|-----|
| Иконка UI | `IconConfig` + Decal |
| 3D в руке | `WeaponModels` + `WeaponModelConfig` |
| Баланс / дроп | `WeaponConfig` |
