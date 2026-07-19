# Figma → Game UI port

## Order (locked)
1. **Character Upgrade** ← start / debug now  
2. Main Inventory  
3. Battle Pass  

## Character Upgrade — debug open (now)

| Input | Action |
|-------|--------|
| **Rail left: UP** | Open `character` panel |
| **Key U** | Same |
| **Key K** | Same (debug alias) |
| Escape | Close panel |

Panel: `Windows.refreshCharacter` — PROFILE/STATS + UPGRADES cards → `Net.BuyUpgrade(id)`.  
Backend already live (`UpgradeService` / `UpgradeConfig`).

This is the **existing code UI** for testing buys. Full Figma look comes next (layout/tokens), same remotes.

### Figma source (live)

https://www.figma.com/design/WhLWwV1ZttJfjbvxKhSve2/Untitled?node-id=1-122  

- Frame: **MainCharacterUpgrader** (`1:122`)  
- **Ported** into `Windows.refreshCharacter` (panel `character`, open UP / U / K)  
- Layout: header (title + coins + close) · 5 cards (Strength/Backpack/Speed/Crit/Multi-Crit) · footer Next Level + Price + Upgrade  
- Data: `Power` `Backpack` `ClickSpeed` `CritChance` `MultiCrit` via `UpgradeConfig` / `BuyUpgrade`  
- Icons: emoji placeholders (Figma PNGs in `art/icons/upgrades/` — upload to Studio → IconConfig later)

---

## How to load from Figma (parts, not all at once)

### Part 1 — Character Upgrade only
1. In Figma: frame **Character Upgrade** (or export link / screenshots of each section).  
2. List components: header, currency, upgrade card (icon, name, level, cost, button), locked state.  
3. Map to code:
   - Window chrome → `UIKit.Window` / Theme  
   - Card row → already in `Windows.lua` refreshCharacter upgrades loop  
   - Data → `UpgradeConfig.Defs` + profile `upgradeLevels`  
4. Restyle **one card type** to match Figma, then clone for all upgrades.  
5. Playtest: open UP → buy Power → coins/level change.

### Part 2 — Main Inventory
1. Figma inventory frame(s).  
2. Port onto `Inventory.lua` shell (tabs, grid, tooltips).  
3. Don’t redesign BP yet.

### Part 3 — Battle Pass
1. Static Figma shell (track + free/premium).  
2. Then `profile.battlePass` + remotes.

### What “parts” means technically
| Part | Deliverable |
|------|-------------|
| A | Open/close + wire data (done for upgrades) |
| B | Visual tokens (colors, fonts, spacing from Figma) |
| C | Exact layout (grid vs scroll, positions) |
| D | Icons/assets upload → rbxassetid |

Send Figma link or PNG of **Character Upgrade** first → we do Part B/C without touching inventory.

---

## NPC later
Portal/NPC ProximityPrompt → `store:OpenPanel("character")` same as UP button.  
Not required for debug.
