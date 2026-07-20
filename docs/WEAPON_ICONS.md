# Weapon inventory icons — pro guide

## Product rules (locked)

| Layer | Same size in bag? | Notes |
|-------|-------------------|--------|
| **Inventory icon** | **Yes** — equal card fill | 3D auto-card or authored PNG |
| **Hand / world** | No | `DefaultScale` free |
| **Stats** | N/A | `WeaponConfig` only |

## Runtime priority (current code)

```
1. WeaponModels mesh  →  ViewportFrame 3D card
2. IconConfig.WeaponAssetIds[id] non-empty  →  ImageLabel (NEW pro PNG only)
3. "?" placeholder
```

**Not used:** `LegacyWeaponAssetIds` (old Cristalix dump art).  
Those looked like “stubs” next to real Toolbox meshes — kept only as archive.

When you upload a **new** 512² icon, put it in `WeaponAssetIds`.  
Later you can flip inventory to **2D-first** for that id only (hybrid pro).

---

## How pro Roblox games do beautiful item previews

Research summary (DevForum + YouTube: Stewiepfing, BrawlDev, MonzterDEV, ByteBlox, Paul1Rb, Crusherfire):

| Approach | Used by | When |
|----------|---------|------|
| **A. Pre-rendered 2D ImageLabel** | Pet Sim–style, most big sims, hotbar | Full inventory grids (best look + perf) |
| **B. Live ViewportFrame** | Shops, single spin preview | 1–8 items, not 40 slots |
| **C. Hybrid** | Pro standard | Grid = 2D; detail panel = one Viewport |

DevForum consensus: many ViewportFrames in one bag = expensive; images win for grids.  
MonzterDEV-style pet UIs: polished games use **images** for inventory; viewport is optional showcase.

### Pro card standard (one law for every weapon)

| Spec | Value |
|------|--------|
| Size | 512×512 PNG (or 256×256) |
| Background | **Transparent** |
| Pose | Tip up, yaw ≈ −35° (same family as 3D card) |
| Fill | Silhouette ~75–85% of frame |
| Light | Same Key + Fill for **all** weapons |
| File | `weapon_<id>_icon.png` |

### Studio Icon Render Stage (no Blender required)

1. Folder `IconRenderStage` in a throwaway place (or Edit).
2. Fixed `IconCamera` + Key/Fill lights (never change between swords).
3. Clone mesh from `ReplicatedStorage.WeaponModels`.
4. Apply same tip-up + yaw as `WeaponModels` inventory code.
5. Fit height ~80% of view.
6. Capture:
   - Studio screenshot / free “icon render” plugin, **or**
   - Blender Cycles transparent PNG (same as beast totem workflow).
7. Creator Dashboard → upload **Image**.
8. `IconConfig.WeaponAssetIds.old_sword = "rbxassetid://…"`.

YouTube workflow references (search titles):

- *How to Make Icons of Objects (Easy & No Blender)* — Stewiepfing  
- *Viewport Frame GUI Tutorial 2025* — BrawlDev  
- *Shop GUI Viewport* — MonzterDEV  
- DevForum: *Are ViewportFrames more/less efficient than images?*

### UI polish around the icon

1. Rarity border (you already have stroke by rarity).
2. Dark slot plate (UI, not baked into PNG).
3. Equipped marker.
4. Optional: hover scale 1.05, soft `UIGradient` shine on ImageLabel.
5. Optional detail: **one** shared ViewportFrame on hover (spin), not 30 VFs.

---

## 3D auto-card (fallback / current Loc1)

See `WeaponModels.frameModelInViewport`:

- tip-up via grip / `hiltEnd`
- `iconInvert` one-bit QA
- icon-only lateral thicken (no near-clip black squares)
- camera fit height ~82%

Config knobs: `IconFillHeight`, `IconMinLateralStuds`, `IconYawDeg`.

---

## Adding a new sword

1. Mesh → `ReplicatedStorage.WeaponModels/<Name>`
2. `WeaponConfig` + `ModelByWeaponId`
3. Hand: `hiltEnd` if needed
4. Bag: auto-3D works immediately
5. Pro look: render PNG → `WeaponAssetIds[id]`
6. Bigger in world: world scale only — card stays 512²

---

## History / FAQ

| Symptom | Cause | Fix |
|---------|--------|-----|
| Old wooden/gray stubs in bag | `Prefer2DWhenAvailable` + legacy ids | Disabled; 3D first |
| Black/white square (Ardite) | Camera inside thin mesh | Lateral ScaleTo + height-only cam |
| Old Sword inverted | Wrong `iconInvert` | `IronSword.iconInvert = false` |
