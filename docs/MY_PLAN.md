# MY PLAN — Tooltip Shell + Equipped Badges + Inventory Panel BG

**Date:** 2026-07-24  
**Task:** Generate clean, palette-matching assets for tooltip shells, equipped badges, and inventory panel background.  
**Style:** Strict adherence to Art Bible §5 (Tier A/B rules, Weapons standard, contrast rules, no glue).

## Разбивка на 4 трека

### 1. Tooltip Shell (пустая тарелка) — Primary Asset
**Цель:** Одна reusable plate, пустой глубокий центр, softer contrast vs Weapons cards.

**Assets needed:**
- `TOOLTIPS/Tooltip_Shell_Empty.svg` (main) + export PNGs (~480×280 + ~640×360)
- Soft navy-purple plate, gentle rim, deep empty center, light outer glow
- Transparent outside
- Empty center for dynamic TextLabels (pad ~16–20px)

**Generation steps:**
1. Start from existing `GamePass_Card_Background.svg` or `BUTTONBACKGROUND` (muted version)
2. Desaturate vs Weapons card (~lower saturation, softer rim)
3. Make center completely empty (no text, no glow inside)
4. Save as SVG + PNG export

**Check:** Side-by-side with `INVENTORY_WEAPONS.png` — shell должен сидеть **тише**.

---

### 2. Equipped Badges (status badges)
**Цель:** Короткие candy wordmarks только для EQUIPPED status.

**Assets needed:**
- `WORDMARK_EQUIPPED_MAIN.png` (no sparkles)
- `WORDMARK_EQUipped_OFFHAND.png`

**Generation:**
- Use existing `render_one` (Tier B candy, Luckiest Guy, no sparkles)
- Exact strings: `EQUIPPED MAIN` and `EQUIPPED OFFHAND`
- Optional: small chip variant if needed

**Placement:** Only for equipped items (bottom of tooltip or in badge)

---

### 3. Inventory Panel Background
**Цель:** Один большой thematic panel (drop-in and forget).

**Assets needed:**
- `INVENTORY_UI/Inventory_Panel_Background.svg` + PNG
- Soft muted purple-navy panel, gentle vignette, very soft rim
- No busy stars, no competing logos
- Safe margins for grid/slots/header

**Generation:**
- Base on Figma `GamePass_Card_Background 2` or muted version of tab cards
- Make it calmer than `*card` badges (lower saturation, softer glow)
- Perfect for drop-in under inventory chrome

---

### 4. Figma Mock + Contrast Check + Final Export
**Цель:** Mock для тебя + финальный пакет.

**Steps:**
1. Create Figma file with all 4 variants (shell only, shell+sample text, shell+EQUIPPED MAIN, shell+EQUIPPED OFFHAND)
2. Side-by-side comparison with current Weapons/Pets cards
3. Confirm contrast rules (shell + panel = тише, cards = герои)
4. Export all SVGs + PNGs to proper folders (`TOOLTIPS/`, `INVENTORY_UI/`, `WORDMARKS_PureText/`)

**Approval needed:** "Looks good" или правки цвета/плотности.

---

**Ready to generate.**  
Кидай референсы (INVENTORY_WEAPONS.png, GamePass cards, BUTTONBACKGROUND, etc.) — сразу подгоню под них и начну генерацию.

Готов? Кидай файлы.