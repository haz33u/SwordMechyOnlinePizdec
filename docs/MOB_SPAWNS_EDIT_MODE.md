# Mob spawn markers + Loc1 Goblin City

## What you see in Edit

Neon pads + billboards under `Loc01.MobSpawns` are **spawn points**, not final art.

Labels:

- `Goblin · Zone A` — Camp A (entrance)
- `Dark Goblin · Zone B` — Camp B (mid city)
- `Goblin Warrior · Zone C` — Camp C (hard)
- `Goblin Scout · Zone D` — Camp D (elite gate)
- `BOSS · Forest Guardian` — far end arena

## Design (city scale)

Loc1 is one **goblin city** map (`Loc01.Art` ≈ 1300×700 studs).  
Combat is **four camps** of different goblin tiers + boss — not a postage stamp near origin.

```
PlayerSpawn (west)
  → Camp A (Goblin ×12)
  → Camp B (Dark Goblin ×8)
  → Camp C (Goblin Warrior ×5)
  → Camp D (Goblin Scout ×4)
  → Boss arena (Forest Guardian ×1)
```

**DoD for layout**

| Check | Target |
|-------|--------|
| Source of positions | `Loc01.Art` world AABB |
| Adjacent camp centers | ≥ ~200 studs |
| Camp footprint | ~50–70 studs radius |
| MobSpawns span | hundreds of studs (majority of Art X) |
| Never wipe | `Loc01.Art` |

## Folders

| Folder | Role |
|--------|------|
| `MobSpawns` | Combat markers (`MobId`, `Zone`, `DisplayName`) |
| `ZoneGuides` | Translucent camp plates + camp labels (safe to delete later) |
| `PathHints` | Path strips between camps (safe to delete later) |
| `Art` | **Yours** — tools never delete this |

## Config vs markers

- **LocationConfig** = who / how many / zone id (not world XYZ).
- **WorldConfig.ZONE_FRACTIONS** = math **fallback** only if markers missing (city-scale).
- **Studio markers** = primary positions for Loc1.

## One-shot rebuild

Agent/MCP runs `tools/studio_loc1_level_layout.lua`, or paste the **full file** into Command Bar  
(not the filename — that causes `Incomplete statement`).

Then **Save place** (Team Create).

## Valid MobId

`L1_Goblin`, `L1_DarkGoblin`, `L1_GoblinWarrior`, `L1_GoblinScout`, `L1_Boss`, `DEBUG_Dummy`
