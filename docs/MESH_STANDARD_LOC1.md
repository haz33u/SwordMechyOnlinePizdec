# Loc1 Dark Forest — mesh standard (Roblox)

Authoring contract for 3D swords. Matches `WeaponModelConfig` + `docs/WEAPON_HOLD.md`.

## Units & axes (Blender)

| Rule | Value |
|------|-------|
| Unit | 1 Blender unit = **1 stud** |
| Long axis | **+Y = tip**, **−Y = pommel** |
| Origin | Grip point (`SM_Hilt`) at palm |
| Blade flat | roughly on **X** |

## Authored size (before `DefaultScale = 0.52`)

| Spec | Studs |
|------|-------|
| Total length (most swords) | **4.0** ±0.15 |
| Handle / grip zone | **1.0–1.15** |
| Dagger total | **2.8–3.2** |
| Staff total | **4.4–4.6** |
| Blade width Common | **0.22–0.30** |
| Blade width Rare+ | **0.30–0.50** |
| Thickness | **0.08–0.14** |

World length ≈ authored × 0.52 (~2.08 studs for a 4.0 sword).

## Poly budget

| Tier | Tris |
|------|------|
| Common | 120–350 |
| Rare | 350–700 |
| Epic | 600–1200 |
| Legendary+ | 900–2000 |

## Loc1 map (Dark Forest set)

| weaponId | Model.Name | Concept |
|----------|------------|---------|
| starter_weapon | DF_StarterStick | Oak stick-sword |
| old_sword | DF_MossRust | Moss rust blade |
| bone_dagger | DF_BoneThorn | Bone thorn dagger |
| wooden_mace | DF_RootMace | Root mace |
| double_edged_sword | DF_Twinleaf | Twinleaf blade |
| forest_spirit_staff | DF_SpiritBranch | Spirit branch staff |
| ardite | DF_Amberheart | Amberheart |
| forest_sword | DF_CanopyFang | Canopy fang |
| forest_shadow | DF_UmbralBough | Umbral bough |

## Export

```
art/meshes/loc1_dark_forest/
  DF_*.fbx
  DF_*.blend
  preview/
```

Generate:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --python tools/blender/gen_loc1_dark_forest_swords.py
```

## Studio

1. Import each FBX into `ReplicatedStorage.WeaponModels` (model name from table)
2. PrimaryPart = mesh / Handle
3. Run `tools/bake_weapon_hilts.lua` or equip once for `SM_Hilt`
4. `WeaponModelConfig.ModelByWeaponId` maps DF_* names
