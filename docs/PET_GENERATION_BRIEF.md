# Pet generation brief — how to make 53 pets that can't be confused

## Why the duplicates happened

Nereus and Nereid are both Greek sea deities, both Loc2, both high rarity. Fed to
a generator, that description produces the same creature twice. The problem was
never the generator — it was that two pets were described identically.

Every duplicate in this game has that shape: same theme, same location, adjacent
rarity, no stated difference. So the fix is not "generate more", it's "make the
brief for each pet differ along axes the eye actually reads".

## The four axes

Fill all four for every pet before generating. If two pets in the same location
match on **silhouette** and **signature detail**, they will read as the same pet
no matter how good the generation is.

**1. Silhouette** — the strongest cue, readable at 2 studs. Pick one per pet and
never repeat it within a location:
`quadruped` · `bird` · `serpent` · `humanoid` · `amorphous/blob` · `insectoid` ·
`aquatic (tail, no legs)` · `floating/no ground contact`

**2. Palette** — locked to rarity so a Common never out-glitters a Mythic. Use
`PetModelConfig.RarityColor` as the anchor hue:

| Rarity | Anchor | Treatment |
|---|---|---|
| Common | muted green/grey | flat, matte, no emissive |
| Rare | blue | one accent color, slight sheen |
| Epic | purple | two-tone, small emissive trim |
| Legendary | orange/gold | metallic accents, glowing eyes |
| Mythic | red/pink | emissive core, strongest contrast |

**3. Material** — `fur` · `scale` · `metal` · `crystal` · `neon` · `stone` ·
`cloth` · `slime`. Two pets sharing a silhouette must not share a material.

**4. Signature detail** — exactly one memorable feature, unique across all 53.
This is what a player names the pet by: *"the one with the pearl crown"*.

## Worked example — the pair that broke

| | Nereus (`P2_M1`, Mythic) | Nereid (`P2_K_L2`, Legendary) |
|---|---|---|
| Silhouette | humanoid, legs, upright | aquatic, single tail, no legs |
| Palette | red/pink emissive core | gold + pearl white |
| Material | scale | scale + iridescent fin membrane |
| Signature | trident and beard | pearl crown, split tail flukes |

Different silhouettes — impossible to confuse even in shadow.

**Nereid needs no generation.** `Workspace.Nereid` is already a unique 34-part
merfolk model matching this description. Install it with
`tools/install_pet_model_slot.lua`.

## Hard constraints

- **≤250 parts.** Every pet is scaled to `TargetExtent = 2.0` studs, so detail
  beyond this is invisible and costs framerate. `PetModels.F` (Charon) is 3003
  parts — roughly 12× the budget for something the size of a fist.
- **No scripts, sounds, or ForceFields.** `PetVisual.sanitizeParts` strips them,
  but shipping them wastes memory in ReplicatedStorage.
- **Model must have a PrimaryPart**, or the client picks an arbitrary part and
  the pet floats at an odd angle.
- **Build in ReplicatedStorage.PetModels, not the Workspace root.** Models left
  in the Workspace show up as unowned props standing on the map;
  `StrayPetModelService` now deletes them at boot, so a model generated there is
  a model you lose.

## Order of work

1. Run `tools/audit_pet_models.lua` from the Studio command bar → exact list of
   which pets look alike, which have no model, which blow the part budget.
2. Install `Workspace.Nereid` → slot `E-D` (`tools/install_pet_model_slot.lua`).
   Costs zero generations.
3. Fill in the four axes for each remaining pet the audit flagged.
4. Generate, one pet at a time, into its `PetModels` slot.
5. Re-run the audit. "Models to generate: 0" and no part-budget entries is the
   definition of pets being finished.

## Rename the Loc1–Loc2 slots

Loc3–Loc7 slots are named after the pet (`Kirin`, `PolarDrake`, `CyberValkyrie`).
Loc1–Loc2 use labels (`A`, `2-F`, `E-D`, `Waifu`). That naming is why three
copies of one model sat unnoticed under three different names — nobody can see a
wrong model in a slot called `E-D`.

Renaming them to pet names makes a future duplicate obvious in the Explorer and
in review. Do this after the audit, so slot names and content are corrected in
one pass rather than two.
