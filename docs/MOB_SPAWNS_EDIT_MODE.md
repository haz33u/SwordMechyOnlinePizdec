# Mob spawn markers (Edit mode)

## How it works

1. In **Edit**, place Parts under:
   `Workspace.World.Locations.Loc01.MobSpawns`
2. Each Part needs Attribute **`MobId`** = one of the Loc1 ids below.
3. Optional Attribute **`Zone`** = `A` / `B` / `C` / `D` / `Boss`.
4. **Save place**.
5. **Play** → `CombatService` spawns killable mobs **on those positions**.

If folder empty → fallback math rings from `LocationConfig` + `WorldConfig`.

## Loc1 MobId list (only these for world)

| MobId | Role |
|-------|------|
| `L1_Slime` | T1 Goblin |
| `L1_Skeleton` | T2 Dark Goblin |
| `L1_GoblinWarrior` | T3 Warrior |
| `L1_Knight` | T4 Scout |
| `L1_Boss` | Boss (end of loc) |
| `DEBUG_Dummy` | debug only |

## One-shot setup

1. Open `tools/studio_loc1_spawns_v2.lua`
2. Studio → View → **Command Bar**
3. Paste all → Enter
4. Drag neon markers onto your art
5. Move **boss** marker to portal / end area
6. **Ctrl+S** save place

## Realtime / AI Assistant

| What | Visible without Play? | AI can move? |
|------|------------------------|--------------|
| Neon markers | **Yes** (Edit) | Yes (Assistant / MCP) |
| Live killable mobs | **Only in Play** | AI can start Play + move markers in Edit |
| Rojo configs | Not in 3D view | Edit via files / Rojo |

Assistant + MCP can relocate markers and folders; it will **not** invent working MobIds outside `MobConfig`.
