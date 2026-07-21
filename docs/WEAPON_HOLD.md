# Sword hold system (Minecraft-style + per-mesh hilt)

## How Minecraft holds a sword (what we copy)

| Minecraft | Our port |
|-----------|----------|
| Raised arm in third person | `WeaponVisual` READY pose + `UseMinecraftSwing` |
| Item has fixed transform vs arm | Same palm point for every sword |
| Handle is “authored” into the 2D sprite bottom | **`SM_Hilt` Attachment** on the 3D handle end |
| Blade may clip the hand | Allowed; clip through shoulder/chest = wrong axis |

Minecraft does **not** auto-detect arbitrary 3D hilts — the texture is drawn so the handle is at the hand.  
Our free Toolbox meshes need an explicit **hilt point** per model.

---

## Contract

```
Hand.RightGripAttachment / LeftGripAttachment
        │  RigidConstraint (+ small PalmOffset)
        ▼
PrimaryPart.Attachment "SM_Hilt"   ← palm on HANDLE (pommel end)
  attachment +Y ≈ blade tip direction
```

---

## Runtime (automatic)

`WeaponModels.PrepareClone` → strip Tool junk → scale → **`EnsureHiltAttachment`**  
`WeaponModels.AttachToHand` → RigidConstraint palm ↔ `SM_Hilt`

If Place models already have `SM_Hilt`, that is used (after `ScaleTo`).  
If not, client bakes on the **clone** every equip (same algorithm).

---

## Bake into Place (recommended, once)

1. **Stop Play** (Edit mode)  
2. Run `tools/bake_weapon_hilts.lua` in Command Bar (or paste contents)  
3. Check each model under `ReplicatedStorage.WeaponModels` has `SM_Hilt`  
4. If one sword still wrong: **move only that `SM_Hilt`** on the mesh (or set override)  
5. **Save Place**

Algorithm:

1. Longest axis of Handle / largest part = blade axis  
2. `Tool.Grip` side of center = **hilt**; opposite = **tip**  
3. Place attachment near hilt end (`HiltEndBias ≈ 0.92`)  
4. Orient so attachment up ≈ tip  

---

## Config

`WeaponModelConfig.lua`:

| Field | Role |
|-------|------|
| `ModelByWeaponId` | weaponId → Model name |
| `DefaultScale` | free sword size |
| `PalmOffsetRight/Left` | position only (into palm) |
| `PalmTiltRight/Left` | keep ~0 — do **not** use for edge vs flat |
| **`BladeRollRight/Left`** | **rotate around sword long axis** (cut vs slap). Default ±90 |
| `HiltEndBias` | how close to pommel end |
| `HiltOverrides.GoldSword.flipTip` | only if auto tip is inverted |

**Edge vs flat (режет / плашмя):** change **`BladeRollRight` / `BladeRollLeft`** only (±90 flip if wrong way).  
**One sword’s handle point:** move that model’s `SM_Hilt` only.  
**Do not** keep tweaking PalmTilt XYZ for blade spin — that was the wrong knob.

---

## Loc1 mesh map (Dark Forest DF_* — 2026-07-21)

See `docs/MESH_STANDARD_LOC1.md` and `art/meshes/loc1_dark_forest/`.

| weaponId | Model.Name | Rarity | Legacy fallback (until import) |
|----------|------------|--------|--------------------------------|
| starter_weapon | **DF_StarterStick** | Common | StarterSword |
| old_sword | **DF_MossRust** | Common | IronSword |
| bone_dagger | **DF_BoneThorn** | Common | PixelIronSword |
| wooden_mace | **DF_RootMace** | Rare | GoldSword |
| double_edged_sword | **DF_Twinleaf** | Epic | RubySword |
| forest_spirit_staff | **DF_SpiritBranch** | Epic | DiamondSword |
| ardite | **DF_Amberheart** | Legendary | KawashimaSword |
| forest_sword | **DF_CanopyFang** | Mythic | SupeSport |
| forest_shadow | **DF_UmbralBough** | Secret | LastSword |

`WeaponModels.GetTemplate` falls back to LegacyModelNames if DF_* is missing in Place.

## New sword checklist

1. Put Model in `ReplicatedStorage.WeaponModels.MySword`  
2. Map id in `ModelByWeaponId`  
3. Bake hilts (or equip once for runtime bake)  
4. Playtest dual wield  
5. Inventory icon: **auto 3D Viewport** if model mapped; optional Decal via `IconConfig`  
6. See `docs/ICON_UPLOAD.md`

---

## Do not

- Tune one global `HiltFactor` for all free meshes (that was the old bug)  
- Expect Minecraft 2D item matrix to map 1:1 onto random Unions  
- Hand-place every sword unless auto-bake is wrong for that one asset  
