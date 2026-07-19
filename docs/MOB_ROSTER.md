# Active mob roster (dump-aligned)

> Source: Cristalix screenshots / `DUMP_CATALOG.md`  
> Spare (not spawned): `src/ReplicatedStorage/Shared/Config/Spare/MobConfigSpare.lua`  
> Melee: `GameConfig.HIT_RANGE = 10` studs (+0.75 ε) for **manual and auto**.

## Loc1 — Dark Forest

| id | Name | Tier | HP | Coins | Spawn | Features to test |
|----|------|------|-----|-------|-------|------------------|
| `L1_Slime` | Goblin | simple T1 | **1 000** | **200** | 10 × A | starter kills, common drops, Q1 goblins |
| `L1_Skeleton` | Skeleton | medium T2 | **8 000** | **800** | 8 × B | mid farm, quest |
| `L1_Wolf` | Wolf | medium T2 | **12 000** | **1 200** | 7 × B | mid farm, quest + wooden mace reward |
| `L1_GoblinWarrior` | Goblin Warrior | hard T3 | **5 680 000** | **100 000** | 6 × C | dump warrior scale, hard table |
| `L1_Knight` | Goblin Scout | elite T4 | **300 000** | **12 500** | 4 × D | elite + secret 0.0001% path |
| `L1_Elite` | Forest Warden | elite T4 | **450 000** | **18 000** | 3 × D | elite density |
| `L1_Boss` | Forest Guardian | boss | **1 200 000** | **25 000** | 1 | boss dust, boss quest, top drops |

**Removed from world spawn:** `L1_GoblinScout` (Runner) → Spare.  
**DEBUG_Dummy:** only `DebugSpawnDummy` remote, not location tables.

## Loc2 — Pirate Ship

| id | Name | Tier | HP | Coins | Spawn | Features to test |
|----|------|------|-----|-------|-------|------------------|
| `L2_Sailor` | Sailor | simple | **9 000 000** | **750 000** | 10 × A | dump drops Hook/Hammer/Saber/Gold |
| `L2_Gunner` | Gunner | medium | **70 640 000** | **5 770 000** | 6 × B | mid Loc2 + Axe/Element drops |
| `L2_Captain` | Captain | hard | **4 750 000 000** | **46 400 000** | 2 × C | Sea Dagger / Emerald path |

No Loc2 boss in dump (Admiral removed earlier).

## Melee range (anti kill-aura)

| | Old (broken) | Now |
|--|--------------|-----|
| Auto pick radius | **40** studs | **`HIT_RANGE` 10** |
| Hit accept radius | **48** studs | **10 + 0.75** |
| No HRP | still hit random mob | **no hit** |
| Auto vs manual | same huge range | **same melee range** |

Stand roughly **within ~10 studs** of a mob (Minecraft-close for Roblox avatars).
