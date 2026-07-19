# Анимации атаки и мечи на руках

## Атака (сейчас)

| | |
|--|--|
| **Attack (main + alt)** | `rbxassetid://522635514` (Roblox Tool Slash) |
| Config | `AttackMain` = `AttackAlt` = slash |
| Код | `AnimationConfig` + `WeaponVisual.PlayAttack` |

Одна character-анимация на клик (R15 tool slash). Мечи main/offhand на grips — визуал, не отдельные anim tracks.

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
