# Анимации

## Атака

### A) Minecraft procedural swing (OFF by default)

| | |
|--|--|
| **Включить** | `AnimationConfig.UseMinecraftSwing = true` |
| **Сейчас** | `false` → **`rbxassetid://95040065182870`** |
| How | `Motor6D` RightShoulder / Waist `.Transform` |
| Code | `WeaponVisual.PlayAttack` на LMB (Tool не нужен) |
| Tune | `MinecraftSwing.SwingTime / RaisePower / RollPower / SwingDir` |
| Output | `[WeaponVisual] PlayAttack → MinecraftSwing` |

Если `RightShoulder not found` — rejoin; joint ищется на R15 `RightUpperArm`.

### B) Published AnimationId
| Flag | `UseMinecraftSwing = false` |
| Id | `rbxassetid://95040065182870` |

## Ходьба (не атака)

Idle / Walk / Run — публичные R15 (только locomotion).

## Персонаж

`Player.Character` (R15 аватар). Не в git.
