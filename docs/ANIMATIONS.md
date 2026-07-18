# Анимации атаки и мечи на руках

## Что сделано

| Фича | Где |
|------|-----|
| Меч **main** → `RightHand.RightGripAttachment` | `WeaponVisual.lua` |
| Меч **offhand** → `LeftHand.LeftGripAttachment` | то же |
| Анимация удара на Swing / CombatFx / Space / КЛИК | `WeaponVisual.PlayAttack` |
| ID анимаций | `Shared.Config.AnimationConfig` |

## ID по умолчанию (Roblox R15, upload **не** нужен)

Это стандартные анимации из default `Animate` (Tool):

| Ключ | Asset | Смысл |
|------|-------|--------|
| `AttackMain` | `rbxassetid://522635514` | R15 **toolslash** |
| `AttackAlt` | `rbxassetid://522638767` | R15 **toollunge** |
| `ToolHold` | `rbxassetid://522696694` | R15 **toolnone** (пока не крутится постоянно) |

При dual wield удары **чередуются** slash / lunge.

## Свои анимации

1. В Studio: Avatar → Animation Editor → R15 swing → **Publish to Roblox**
2. Скопируй Asset ID
3. В `AnimationConfig.lua`:

```lua
AttackMain = "rbxassetid://ТВОЙ_ID",
AttackAlt = "rbxassetid://ТВОЙ_ID_2",
```

4. `rojo serve` / pull → Play

**Важно:** анимация должна быть **R15** (или Rthro), owner = place creator / group, иначе не проиграется у игроков.

## Если slash не играет

- Персонаж R6 → эти ID могут не подойти (нужны R6 ids или R15 only place)
- Animation privacy
- Консоль: ошибки `LoadAnimation` / `Animation failed to load`

## Place check

В репо/Place **не** было своих Animation instances — Studio Agent только музей Parts.  
Grip points — дефолт R15.
