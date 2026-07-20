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
| Right (1-hand) | **`rbxassetid://131793860537357`** → `AttackMain` |
| Right (brutal, saved) | **`rbxassetid://86113662553657`** → `AttackPresets.brutalRight` / `AttackAlt` |
| Left (sequential fallback) | **`rbxassetid://97155624777350`** → `AttackOffhand` |
| **Dual both hands** | **`rbxassetid://81321426085093`** → `AttackDual` / `AttackPresets.dualBoth` |
| Dual unlock rule | **Only if** `profile.unlocks.offhand == true` **and** offhand sword equipped |
| Without Offhand purchase | always 1-hand `AttackMain` (dual ignored) |
| Fallback | dual fails → right-then-left sequential; left fails → procedural |
| Switch to brutal later | `AttackMain = AnimationConfig.AttackPresets.brutalRight` |

## Ходьба (не атака)

Idle / Walk / Run — публичные R15 (только locomotion).

## Персонаж

`Player.Character` (R15 аватар). Не в git.
