# Frost — pet case open chain (21 steps)

NPC **Frost** · open **pet cases on any location** · rewards **luck** + milestone **pet slot**.

Screenshot ref: step **13/21** at **~1M** opens (764K/1M progress).

## Rules (design lock)

1. Progress = number of **successful pet case opens** (not aura cases).
2. **x3 / x5 multi-open** (gamepass) counts as **3 / 5** toward the quest when multi-open is wired (`OnCaseOpen(profile, "pet", n)`).
3. Each claim: permanent **`questLuckPct`** (feeds `Formulas.GetLuck`).
4. **Step 5 = 10 000 opens → +1 pet equip slot** (`questPetSlots`).
5. **Location drop hardness still rises** with world (weapon rarity squeeze / HP). Luck from Frost **helps** but does **not** remove LocN drop tax — higher loc = harder good rolls even with high luck.

## Amounts

| Step | Opens | Note |
|------|-------|------|
| 1–4 | 0.5K–6K | intro |
| **5** | **10K** | **+1 pet slot** |
| 6–12 | 25K–750K | mid |
| **13** | **1M** | dump-like |
| 14–21 | 2M–200M | late |

## Related

- Sam = clicks → CPS (`docs/SAM_CLICK_QUEST.md`)
- Pet slots also from rebirth / dungeon / paid (`ProgressConfig`)
