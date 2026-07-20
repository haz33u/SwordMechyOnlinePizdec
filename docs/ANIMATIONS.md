# Анимации

## Атака

### A) Minecraft procedural swing + hold (optional)

| | |
|--|--|
| **Включить** | `AnimationConfig.UseMinecraftSwing = true` |
| How | Idle: raised-arm **READY** pose · Attack: Motor6D RightShoulder/LeftShoulder slash |
| Hold | `SM_Hilt` + palm tilt — see `docs/WEAPON_HOLD.md` |
| Code | `WeaponVisual.PlayAttack` на LMB (Tool не нужен) |
| Output | `[WeaponVisual] PlayAttack → MinecraftSwing` |

Если `RightShoulder not found` — rejoin; joint ищется на R15 `RightUpperArm`.

### B) Published AnimationId (default — right hand attack)

| Flag | `UseMinecraftSwing = false` (default) |
| Id | **`rbxassetid://131793860537357`** (right-hand attack) |
| Code | `WeaponVisual.PlayAttack` → `AnimationConfig.AttackMain` |
| Offhand | still procedural left-arm swing when dual-wield |

## Ходьба (не атака)

Idle / Walk / Run — публичные R15 (только locomotion).

## Персонаж

`Player.Character` (R15 аватар). Не в git.
