# Project Status — Sword Masters Online

## 1. Pets

### Config
- `PetConfig` defines **42 pets** across 7 locations.
- `PetModelConfig` maps each pet to a model name in `ReplicatedStorage.PetModels`.

### Models in `ReplicatedStorage.PetModels` — 52 models
- **Loc1 (500 coins):** A, B, C, D, E (Woodling, Lurk, Forestling, Hekata, Stiko)
- **Loc1 (50K coins):** 2-A (Torn), 2-B (Nifel), 2-C (Nightmare), 2-D (Grommash), F (Charon), G (Morpheus)
- **Loc1 (49 keys):** 2-E (Nocturne), 2-F (Moron), 2-G (Heka), 3-A (Monster), 3-B (Freya)
- **Loc2 (3.75M coins):** 3-C (Proteus), 3-D (Atlas), 3-E (Hermes), 3-F (Arix), 3-G (Ceres), Waifu (Nereus)
- **Loc2 (54 keys):** E-A (Eridan), E-B (Calypso), E-C (Argus), E-D (Nereid placeholder), S-A (Nereid Mythic placeholder)
- **Loc3:** Kirin, ShinobiFox, ShadowRaven, DragonKin, SamuraiTiger, KitsuneGod
- **Loc4:** FrostBunny, IceBear, GlacierPenguin, TundraWolf, PolarDrake, YetiKing
- **Loc5:** Scarab, AnubisGuard, Sphinx, SunDrake, PharaohGod
- **Loc6:** CyberCat, NeonHawk, MechaWolf, PlasmaDragon, CyberValkyrie
- **Loc7:** StarlightSpirit, Seraphim, SolarPhoenix, CelestialDragon, ArchangelPrime

### Status
- All 42 config pets have a model.
- `E-D` and `S-A` are placeholders (cloned from Waifu) until generator rate limit resets.
- Auras are applied to pets by rarity in `PetVisual.lua`.

## 2. Auras

### Config
- `AuraConfig` defines **36 auras** (28 rollable + 8 place-only extracted).
- `AuraModelConfig` maps aura IDs to model names in `ReplicatedStorage.AuraVfx`.

### Extracted / Added Today
- `HinataAura`, `ItachiAura` from Workspace EVO models.
- `CharAura_1`, `CharAura_2`, `CharAura_3`, `CharAura_104699`, `CharAura_196179`, `CharAura_Vampire` from Workspace.Characters.
- New aura IDs: `A_HinataEVO`, `A_ItachiEVO`, `A_Character1..Vampire` (Secret/Limited, dropWeight=0).

### Status
- Player auras work via `AuraVisual.lua`.
- Pet auras added today.
- Mob auras added via new `MobAura.client.lua`.

## 3. Weapons

### Config
- `WeaponConfig` defines weapons by location/rarity.
- `WeaponModelConfig` maps weapon IDs to model names in `ReplicatedStorage.WeaponModels`.

### Models in `ReplicatedStorage.WeaponModels` — 57 models
All weapon IDs from Loc1-7 have matching models, plus legacy incremental weapons.

### VFX
- `WeaponVisual.lua` attaches:
  - Colored sword trail on attack.
  - Idle sparks on tip for Rare+ weapons.
  - Blade glow particles for Rare+.
  - Full aura model for Epic+ weapons.

## 4. Mobs

### Config
- `MobConfig` defines **28 active mobs** across 7 locations + 1 debug dummy + 1 disabled boss.

### Models in `ReplicatedStorage.MobTemplates` — 34 models
All active mobs except `DEBUG_Dummy` have a model. `Supreme Shadow Lord` exists but is used only by disabled L1_Boss.

### Status
- Mob auras added today (`MobAura.client.lua`).
- Mobs do NOT fly; the screenshot shows pets following the player.

## 5. Talent Tree

### Config
- `TalentTreeConfig` with 5 branches and ~50 nodes.
- `TalentTreeService` validates unlocks server-side.
- Integrated into `Formulas`, `ClickConfig`, `ProgressConfig`, `OfflineFarmService`.

### Fix Today
- `reqLocation` for damage nodes capped at 7 (was `math.min(19, i*2)`).

## 6. Still Missing / To Do

- Unique models for `E-D` and `S-A` pets (pending generator rate limit).
- Final pet placement tuning (height/back distance already reduced).
- Map/landscape/decor/lighting (your area).
- UI polish (your area).
- Sound design.
- Final animation tuning.
- Possible `UIUpgradeTree` module reference bug if module does not exist (wrapped in pcall).
- Need to verify `ComputeStats` UIUpgradeTree branch logic for raw vs multiplier values.
