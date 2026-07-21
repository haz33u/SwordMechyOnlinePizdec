# Mob spawn markers + Loc1 grey-box

## What you see in Edit

Neon pads + billboards under `Loc01.MobSpawns` are **spawn points**, not final art.

Labels should read:

- `Goblin · Zone A`
- `Dark Goblin · Zone B`
- `Goblin Warrior · Zone C`
- `Goblin Scout · Zone D`
- `BOSS · Forest Guardian`

## Layout

```
PlayerSpawn → Zone A → Zone B → Zone C → Zone D → Boss arena
```

Folders:

- `MobSpawns` — combat markers (`MobId` attribute)
- `ZoneGuides` — translucent plates (safe to delete later)
- `PathHints` — path strips (safe to delete later)
- `Art` — **yours**; tools never delete this

## One-shot rebuild

Agent/MCP runs level layout, or paste `tools/studio_loc1_level_layout.lua` into Command Bar (**full file**, not the filename).

Then **Save place**.

## Valid MobId

`L1_Goblin`, `L1_DarkGoblin`, `L1_GoblinWarrior`, `L1_GoblinScout`, `L1_Boss`, `DEBUG_Dummy`
