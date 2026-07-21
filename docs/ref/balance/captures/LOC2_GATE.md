# Loc2 gate + systems (2026-07-19)

## Transition dump (`Переход на локу2.png`)
| Location | Button |
|----------|--------|
| Starter Village | Free **Teleport** |
| Pirate Ship | **Buy for 500K** coins (one-time unlock) |

## Weapon levels
| From | Need | Result |
|------|------|--------|
| L1 | **5** same sword id | L2 |
| L2 | **3** same sword id L2 | L3 |

Input: inventory **MMB (MouseButton3)** on a sword, or **Merge** button.

Power (from Loc1 double-edged dump): `baseStrength × {1, 2, 3}` for L1/L2/L3.

## Pets
- Equip max **8** (ProgressConfig)
- Bags / storage separate (base 32 + backpack levels)
- Loc2 coin case **3.75M**; Loc2 key case **54** (see DUMP_CATALOG)

## Ferryman
NPC near each spawn (`Workspace.NPCs`) — ProximityPrompt **Travel** → `OpenTravel` → locations panel.
