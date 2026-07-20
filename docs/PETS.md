# Pets — backend + follow visuals

## What ships

| Piece | Status |
|-------|--------|
| Catalog (Мощь ×N, case pools) | `PetConfig` Loc1+Loc2 dump |
| Open case / equip / unequip / feed / sell | `PetService` |
| Combat stack | `Formulas.GetPetPowerMult` |
| Float behind player | `PetVisual` (client) |
| Mesh map | `PetModelConfig` + Place `ReplicatedStorage.PetModels` |

## Remotes

| Remote | Args |
|--------|------|
| `OpenPetCase` | `poolId?` (`loc1_500`, `loc1_50k`, `loc1_key49`, …) |
| `EquipPet` / `UnequipPet` | `petUid` |
| `FeedPet` | `petUid` |
| `SellPet` | `petUid` → coins `sellPrice` |

## Follow rules (PetVisual)

- Fan behind HRP: back ~4.2, height ~2.35, spread ~1.65  
- Lerp α ~0.16 + bob  
- Missing mesh → rarity-colored ball + name billboard  
- Local player only (v1)

## Place setup

1. Folder `ReplicatedStorage.PetModels`  
2. Models named as in `PetModelConfig.ModelByPetId` (Woodling, Lurk, …)  
3. Or rely on auto-placeholders  

### Test free meshes (temp)

Inserted free Creator Store models into `PetModels` for Loc1 testing (replace later with final art):

| Model name | Role |
|------------|------|
| Woodling / Lurk / Forestling / Hekata / Stiko | Loc1_500 map |
| Charon…Grommash | from free pet pack (50k-ish tiers) |

**Save the Place** after insert — assets live in Studio place, not git.

### Icons

- **World follow + inventory 3D slots** use the same meshes in `PetModels`.  
- No separate PNG required for testing.  
- Final polish: optional 512² `Image` uploads later (like weapons).

### Uniform size

All pets are scaled so max bounding-box extent ≈ `PetModelConfig.TargetExtent` (**2.0** studs).  
Free pack models no longer spawn 4× character size.  

## DEV

`DebugCommand`:

- `giveLoc1Pets` — all loc1_500 pets  
- `givePet` + id string — single pet  

## Inventory

- LMB equip/unequip  
- RMB feed  
- Case 500 / Case 50K  
- Sell selected  
