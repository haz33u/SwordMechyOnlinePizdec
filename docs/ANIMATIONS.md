# Анимации

## Атака

### A) Minecraft procedural swing (**default test ON**)
| | |
|--|--|
| Flag | `AnimationConfig.UseMinecraftSwing = true` |
| How | `Motor6D` RightShoulder / Waist `.Transform` each frame |
| Curve | cubic ease + sin raise/roll (ModelBiped-style) |
| Code | `WeaponVisual` — no Tool required; LMB already calls `PlayAttack` |
| Tune | `AnimationConfig.MinecraftSwing` (SwingTime, RaisePower, RollPower, SwingDir) |

**Pros:** no asset permission, works offline, feels like MC.  
**Cons:** fights Animator slightly; tune READY pose for R15; not a KeyframeSequence.

### B) Published AnimationId
| | |
|--|--|
| Flag | `UseMinecraftSwing = false` |
| Id | `rbxassetid://95040065182870` |

Toggle in `AnimationConfig.lua` only.

## Ходьба (не атака)

Idle / Walk / Run — публичные R15 (только locomotion).

## Персонаж

`Player.Character` (R15 аватар). Не в git.
