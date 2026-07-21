# Loc1 mob roster (active)

Exactly **4 goblins** + **1 boss** at the end of the location.

| Id | Display name | Tier | HP | Coins | Zone |
|----|--------------|------|-----|-------|------|
| `L1_Goblin` | Goblin | T1 | 1 000 | 200 | A (near spawn) |
| `L1_DarkGoblin` | Dark Goblin | T2 | 8 000 | 800 | B |
| `L1_GoblinWarrior` | Goblin Warrior | T3 | 5 680 000 | 100 000 | C |
| `L1_GoblinScout` | Goblin Scout | T4 | 300 000 | 12 500 | D (pre-boss) |
| `L1_Boss` | Forest Guardian | Boss | 1 200 000 | 25 000 | **Boss** end |

## Legacy ids (auto-resolve)

| Old | New |
|-----|-----|
| `L1_Slime` | `L1_Goblin` |
| `L1_Skeleton` | `L1_DarkGoblin` |
| `L1_Knight` | `L1_GoblinScout` |

`MobConfig.Get` / `ResolveId` map old → new. Spawn entries always store **new** id.

## Grey-box layout

Path: **Spawn → A → B → C → D → Boss**  
Script: `tools/studio_loc1_level_layout.lua` (or MCP run).  
Does **not** wipe `Loc01.Art`.
