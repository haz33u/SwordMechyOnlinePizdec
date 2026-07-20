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

### B) Published AnimationId (default — dual attack)

| Flag | `UseMinecraftSwing = false` (default) |
| Right (active) | **`rbxassetid://131793860537357`** → `AttackMain` |
| Right (brutal, saved) | **`rbxassetid://86113662553657`** → `AttackPresets.brutalRight` / `AttackAlt` — not active yet |
| Left / offhand | **`rbxassetid://97155624777350`** → `AttackOffhand` (when offhand sword equipped) |
| Code | `WeaponVisual.PlayAttack`: **right first**, then **left** after right track ends |
| Fallback | if left id fails → procedural left shoulder swing |
| Switch to brutal later | `AttackMain = AnimationConfig.AttackPresets.brutalRight` in `AnimationConfig.lua` |

## Ходьба (не атака)

Idle / Walk / Run — публичные R15 (только locomotion).

## Персонаж

`Player.Character` (R15 аватар). Не в git.
