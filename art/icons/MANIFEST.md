# Icon art — Loc1 swords v3 (anime + full blade)

## Rules

- **Subject:** only a sword (no photos / scenes)
- **Full weapon in frame:** pad ≥ 56px — tip and pommel never clipped
- **Anime inventory:** thick outline, cel shine, flat plate, glow scales with rarity

## Generate

```powershell
powershell -ExecutionPolicy Bypass -File tools/gen_loc1_sword_icons.ps1
```

Output: `art/icons/weapons/W1_*.png` (15 files)

## Glow ladder

| Rarity | Glow | Example |
|--------|------|---------|
| Common | 0 | W1_C1, W1_C2 (oak stick-sword) |
| Uncommon | 1 | W1_U1, W1_U2 |
| Rare | 2 | W1_R1 violet, W1_R2 cyan |
| Epic | 3 | W1_E1, W1_E2 |
| Legendary | 4 | W1_L1 gold sparks |
| Mythic / Secret / Limited | 5 | W1_M*, W1_S*, W1_X1 pink-cyan |

## Failed neural batch

`art/icons/_failed_v1/` — do not use (markets/cats/lighthouses).

## Next for game

1. Upload PNGs in Roblox → copy asset ids  
2. Wire `IconConfig` / UI ImageLabels  
3. Optional: rarity frame PNGs (separate layer)
