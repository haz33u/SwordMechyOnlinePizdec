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

`ReplicatedStorage.AuraVfx` — **active templates** (names must match `AuraModelConfig`):

| Name | Role | Source (free Creator Store, test) |
|------|------|-----------------------------------|
| Spark | yellow RNG spark aura | Magic Particle VFX Pack |
| Foliage | green toxic/nature aura | Magic Aura Pack Premium |
| WolfMist | snow/mist | Magic Aura Pack |
| ShadowRing | dark aura | Magic Aura Pack DarkRoger |
| Flame | big fire particles | Magic Aura Pack RainbFlame |
| GuardianWings | white wing FX | Magic Aura Pack WhiteWings |
| Rift | purple energy | Magic Aura Pack Purp |

Also kept for browsing: `AuraVfx/_SourcePacks/`  
- Axoie's Auras and VFX Pack  
- Magic Aura Pack  
- Yona VFX Pack  
- Blue Orb VFX  
- Magic Particle Pack  
- Angelic Wings  

**Save Place** after any AuraVfx change.

Missing template → procedural ring + particles.

## DEV

- `giveAllAuras`  
- `giveAura` + id (`A_E1` Flame)

## Replace art later

Drop better mesh/VFX into `AuraVfx` with **same name** → no code change.  
Paid packs: buy → insert → rename to Spark/Flame/…
