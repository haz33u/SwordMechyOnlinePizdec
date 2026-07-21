# Art changelog

Пишите сюда после каждой сессии в Studio — так я вижу, что вы изменили.

Формат:

```
## YYYY-MM-DD — Loc0N — vX (автор)

- что сделали
- PlayerSpawn: где
- Scaffold: оставили / скрыли / удалили
- скрины: art/screenshots/...
```

---

## Template

## 2026-07-18 — Loc01 — v1 (имя)

- (пока пусто — первая сессия)

## 2026-07-21 — Loc01 — Dark Forest meshes v1

- 9 low-poly swords via Blender (`tools/blender/gen_loc1_dark_forest_swords.py`)
- Output: `art/meshes/loc1_dark_forest/DF_*.fbx` + `.blend` + `preview/*.png`
- Standard: `docs/MESH_STANDARD_LOC1.md` (+Y tip, ~4 studs, SM_Hilt origin)
- Config: `WeaponModelConfig` → DF_* names with LegacyModelNames fallback until Place import

