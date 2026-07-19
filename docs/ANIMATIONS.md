# Анимации атаки и мечи на руках

## Атака (сейчас)

| | |
|--|--|
| **Attack** | `rbxassetid://95040065182870` |
| Fallbacks | `522638767` lunge, `522635514` slash |
| Код | `src/ReplicatedStorage/Shared/Config/AnimationConfig.lua` |
| Плеер | `WeaponVisual.PlayAttack` → `character.Humanoid.Animator` |

### Где «персонаж»
Не в git. **Player.Character** = стандартный R15 аватар Roblox (Place Avatar settings).  
Анимация атаки **не** лежит на модели меча — на **Animator** персонажа.

### НЕ делай «Duplicate» в Creator
Только строка `rbxassetid://95040065182870`. Asset должен быть **твоим / group place** + access.

## Запрещённый id (не грузить)

`rbxassetid://12741376562` — **нет доступа** у place.  
Раньше стоял в Place `ReplicatedStorage.Animations` (Idle/Walk/Run/Swing).

**Код:** `AnimationConfig.BannedAssetIds` + `CombatController` всегда грузит **safe** locomotion:
- Idle `507766666`
- Walk `507777826`
- Run `507767714`

И **перезаписывает** banned `AnimationId` на Place-инстансах в runtime.

### В Studio (разово, чтобы в Explorer тоже чисто)

1. `ReplicatedStorage.Animations`
2. У **Idle / Walk / Run / Swing** (если есть) — Properties → AnimationId  
3. Удали `12741376562` или поставь safe ids выше / `522635514` для Swing  
4. Save place

## Grip мечей

| | |
|--|--|
| Main | `RightHand.RightGripAttachment` |
| Offhand | `LeftHand.LeftGripAttachment` |

## Сменить атаку

```lua
-- AnimationConfig.lua
AttackMain = "rbxassetid://522635514",
AttackAlt = "rbxassetid://522635514",
```
