# Weapon inventory icons (Minecraft-style cards)

## Product rule (locked)

| Layer | Same size in bag? | Notes |
|-------|-------------------|--------|
| **Inventory icon** | **Yes** — equal card fill | 2D art or auto 3D card |
| **Hand / world** | No | `DefaultScale` / mesh size free |
| **Stats** | N/A | `WeaponConfig` only |

World length does **not** drive bag icon size. A giant Loc3 sword still fills ~82% of the slot like a starter blade.

## Priority

1. **Authored 2D** — `IconConfig.HasWeaponImage` → `ImageLabel` Fit  
   - `WeaponAssetIds` first, else `LegacyWeaponAssetIds` when `Prefer2DWhenAvailable = true`
2. **Auto 3D card** — `WeaponModels.FillViewport` (tip-up, lateral floor, height-fit camera)
3. **"?"** placeholder

## 3D card pipeline

```
clone → tip-up (grip/hiltEnd) → iconInvert? → yaw −35°
     → icon-only ScaleTo if lateral < IconMinLateralStuds
     → camera: fit height to IconFillHeight, dist ≥ near-clip floor
```

**Do not** zoom the camera into thin MeshParts (causes black/white face squares).

## Config knobs (`WeaponModelConfig`)

| Field | Role |
|-------|------|
| `IconFillHeight` | Card fill (~0.82) |
| `IconMinLateralStuds` | Thicken needles for readability |
| `IconYawDeg` | Showcase angle |
| `iconInvert` (per model) | One-bit tip flip QA |

## Adding a new sword

1. Mesh → `ReplicatedStorage.WeaponModels/<Name>`
2. `WeaponConfig` + `ModelByWeaponId[id] = "<Name>"`
3. Hand: `hiltEnd = ±1` if palm wrong
4. Icon: upload 2D → `WeaponAssetIds[id]` **or** leave empty for auto 3D card
5. If 3D tip wrong: only set `iconInvert = true`
6. Bigger in world: change **hand/world scale only**, not icon

## Old Sword / Ardite history

- Black/white square: camera near-clipped into Kawashima thin face → fixed by lateral ScaleTo + height-only camera.
- Old Sword invert: `IronSword.iconInvert = false` (grip tip-up already correct).
