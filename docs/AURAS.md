# Auras — backend + visual

## Loop

1. Open **Aura Case** (keys) → random aura in bag  
2. Equip → **one** active aura (`profile.equippedAura`)  
3. Client `AuraVisual` shows mesh/VFX on character  
4. Click again / Unequip → clear  

## Stats (`AuraConfig`)

| Id | Name | Power% | Dmg% | Coins% |
|----|------|--------|------|--------|
| A_C1 | Spark | 5 | 0 | 0 |
| A_C2 | Foliage | 3 | 0 | 5 |
| A_U1 | Wolf Mist | 12 | 5 | 0 |
| A_R1 | Shadow Ring | 25 | 10 | 5 |
| A_E1 | Flame | 45 | 20 | 0 |
| A_L1 | Guardian Wings | 80 | 30 | 10 |
| A_M1 | Rift | 140 | 50 | 15 |

Combat: `Formulas.GetAuraPct` → total power.

## Place folder

`ReplicatedStorage.AuraVfx` models named:

`Spark`, `Foliage`, `WolfMist`, `ShadowRing`, `Flame`, `GuardianWings`, `Rift`

Missing → procedural ring + particles (still works).

Map: `AuraModelConfig.ModelByAuraId`.

## DEV

- `giveAllAuras`  
- `giveAura` + id (`A_E1` Flame)

## Replace art later

Drop new mesh/VFX into `AuraVfx` with **same name** → no code change.
