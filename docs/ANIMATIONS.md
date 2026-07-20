# Анимации

## Атака

### A) Minecraft procedural swing + hold (ON by default)

| | |
|--|--|
| **Включить** | `AnimationConfig.UseMinecraftSwing = true` (default) |
| How | Idle: raised-arm **READY** pose · Attack: Motor6D RightShoulder/LeftShoulder slash |
| Hold | `WeaponModelConfig.HoldMode = "minecraft"` — blade from **fist** up/diagonal (may clip hand like MC; not from shoulder) |
| Code | `WeaponVisual.PlayAttack` на LMB (Tool не нужен) |
| Tune swing | `MinecraftSwing.SwingTime / RaisePower / RollPower / SwingDir` |
| Tune grip | `MinecraftRightAngles / MinecraftHiltFactor / DefaultScale` |
| Output | `[WeaponVisual] PlayAttack → MinecraftSwing` |

Если `RightShoulder not found` — rejoin; joint ищется на R15 `RightUpperArm`.

### B) Published AnimationId
| Flag | `UseMinecraftSwing = false` |
| Id | `rbxassetid://95040065182870` |
| Note | Arms may hang unless READY hold still applied for equipped swords |

## Ходьба (не атака)

Idle / Walk / Run — публичные R15 (только locomotion).

## Персонаж

`Player.Character` (R15 аватар). Не в git.
