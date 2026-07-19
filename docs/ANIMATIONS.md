# Анимации атаки и мечи на руках

## Атака (сейчас)

| Роль | ID | Что это |
|------|-----|---------|
| **Main (prefer)** | `rbxassetid://522638767` | R15 **Tool Lunge** |
| **Alt (toggle)** | `rbxassetid://522635514` | R15 **Tool Slash** |
| Fallback same | `http://www.roblox.com/asset/?id=…` | тот же asset, другой URL |
| Last resort | `rbxassetid://507768375` | Tool None (hold) |

Код: `AnimationConfig.AttackCandidates` → `WeaponVisual` пробует **по списку**, пока LoadAnimation не успеет.  
`AlternateDual = true` → клики чередуют lunge / slash.

### НЕ делай «Duplicate» в Creator / Toolbox
Дубликат = **новый** asset, часто **пустой** или private → «пропал / не работает».  
Нужен только **голый id** в строке `rbxassetid://ЧИСЛО`, без копирования asset.

Мечи main/offhand на grips — визуал; анимация одна на Humanoid (официальный tool swing).

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
