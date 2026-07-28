# Loc1 Dark Forest — 3D swords

Low-poly stylized meshes for Roblox (`1 unit = 1 stud`, **+Y tip**, origin ≈ grip).

| File | weaponId | Concept |
|------|----------|---------|
| DF_StarterStick | starter_weapon | Oak stick-sword |
| DF_MossRust | old_sword | Moss / rust short blade |
| DF_BoneThorn | bone_dagger | Bone thorn dagger |
| DF_RootMace | wooden_mace | Root mace |
| DF_Twinleaf | double_edged_sword | Twinleaf double edge |
| DF_SpiritBranch | forest_spirit_staff | Spirit branch staff |
| DF_Amberheart | ardite | Amberheart legendary |
| DF_CanopyFang | forest_sword | Canopy fang mythic |
| DF_UmbralBough | forest_shadow | Umbral bough secret |

## Regenerate

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --python tools/blender/gen_loc1_dark_forest_swords.py
```

## Studio import

1. For each `DF_*.fbx` → import into place  
2. Parent as **Model** named exactly `DF_*` under `ReplicatedStorage.WeaponModels`  
3. Set PrimaryPart, run `tools/bake_weapon_hilts.lua`  
4. Playtest equip (DefaultScale 0.52 applies in code)

See `docs/MESH_STANDARD_LOC1.md`.
