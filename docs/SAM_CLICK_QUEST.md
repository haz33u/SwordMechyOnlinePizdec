# Sam Click Mastery (Loc2+)

NPC **Sam** · **21** sequential click quests · free **CPS 6 → 20**.

## Display targets

| Step | Clicks | Step | Clicks |
|------|--------|------|--------|
| 1 | 1K | 12 | 9M |
| 2 | 2.5K | 13 | 20M |
| 3 | **5K** | 14 | 45M |
| 4 | 12K | 15 | 100M |
| 5 | 28K | 16 | 220M |
| 6 | 65K | 17 | 450M |
| 7 | 150K | 18 | 800M |
| 8 | 350K | 19 | 1.2B |
| 9 | 800K | 20 | 1.6B |
| 10 | 1.8M | **21** | **2B** |
| 11 | 4M | | |

## Click credit (progress per swing)

Tier = claims done. Credit makes 2B finishable (not multi-year pure swings).

| Tier | Credit |
|------|--------|
| 0–2 | ×1 |
| 3–5 | ×2 |
| 6–8 | ×5 |
| 9–11 | ×15 |
| 12–14 | ×40 |
| 15–16 | ×100 |
| 17–18 | ×300 |
| 19 | ×800 |
| 20–21 | ×2000 |

Final step effective ≈ **1M** swings @ ×2000.

## CPS by Sam tier

`ClickConfig.SAM_CPS_BY_TIER` · Loc1 stays **4** until Sam progress / Loc2.

## Code

- `QuestConfig` `Q_SAM_01`…`Q_SAM_21`
- `QuestService.OnClick` + claim `samCpsTier`
- `ClickConfig.GetMaxCPS` / `GetSamClickCredit`
