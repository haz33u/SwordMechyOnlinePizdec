# Loc1 mob roster (active)

Exactly **4 combat mobs** + **1 boss** at the end of the location.

| Id | Name | Tier | HP | Coins | Zone | Notes |
|----|------|------|-----|-------|------|--------|
| `L1_Slime` | Goblin | T1 simple | 1 000 | 200 | A | starter; id kept for saves/quests |
| `L1_Skeleton` | Dark Goblin | T2 medium | 8 000 | 800 | B | blue mid farm |
| `L1_GoblinWarrior` | Goblin Warrior | T3 hard | 5 680 000 | 100 000 | C | dump warrior scale |
| `L1_Knight` | Goblin Scout | T4 elite | 300 000 | 12 500 | D | elite / secret table |
| `L1_Boss` | Forest Guardian | Boss | 1 200 000 | 25 000 | **Boss** | not a pack mob; end / portal area |

**Not world-spawned (Spare):** `L1_Wolf`, `L1_Elite`, `L1_GoblinScout`.

## Boss

- Spawned via `LocationConfig.bossId` + marker `MobId=L1_Boss` / zone `Boss`
- Respawn **600s** (10 min) in MobConfig
- Art/gate polish later — keep one marker far from spawn

## Studio markers

See `docs/MOB_SPAWNS_EDIT_MODE.md` and `tools/studio_loc1_spawns_v2.lua`.
