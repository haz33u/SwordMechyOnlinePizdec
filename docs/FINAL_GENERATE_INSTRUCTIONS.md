# FINAL_GENERATE_INSTRUCTIONS

**Дата:** 2026-07-24  
**Цель:** Генерация 3 ключевых asset в лучшем виде (SVG + PNG, полный ресурс, чикпи)

**Референсы (из того, что ты кинул):**
- `main_accets` — для общего стиля и *icon
- `WORDMARKS_PureText` — для wordmarks
- `GAMEPASS_Cards/README_GamePass_Cards.txt` — для plate и contrast
- Figma (`*BUTTON`, `GamePass_Card_Background 2`) — только для вдохновения

**Генерация в формате SVG (не экономь токены и ресурсы)**

## 1. Tooltip Shell (пустая тарелка) — Primary Asset
**Пути:**
- `TOOLTIPS/Tooltip_Shell_Empty.svg`
- `TOOLTIPS/Tooltip_Shell_Empty.png` (~480×280 + ~640×360)

**Генерация:**
1. Взять базу `GamePass_Card_Background.svg` (muted версия)
2. Сделать navy-purple plate, gentle rim, deep empty center
3. Контраст: **тише** Weapons card
4. Empty center — для live TextLabel (pad ~16–20px)
5. Transparent outside
6. Сохранить SVG + PNG

## 2. Equipped Badges (EQUIPPED MAIN / OFFHAND)
**Пути:**
- `WORDMARK_EQUIPPED_MAIN.png`
- `WORDMARK_EQUIPPED_OFFhand.png`

**Генерация:**
- Использовать `_render_one` из WORDMARKS_PureText
- Exact strings: `EQUIPPED MAIN` и `EQUIPPED OFFHAND`
- Tier B, no sparkles

## 3. Inventory Panel Background
**Пути:**
- `INVENTORY_UI/Inventory_Panel_Background.svg`
- `INVENTORY_UI/Inventory_Panel_Background.png`

**Генерация:**
- Большая muted purple-navy panel
- Gentle vignette, very soft rim
- **No busy stars**, no competing logos
- Base: muted версия `GamePass_Card_Background 2` + Figma `*BUTTON` tonality
- Безопасные margins

## 4. Figma Mock + Contrast Check
Создать Figma файл с 4 вариантами:
1. Tooltip Shell only
2. Shell + sample live text layout
3. Shell + EQUIPPED MAIN wordmark
4. Shell + EQUIPPED OFFHAND wordmark

Side-by-side с INVENTORY_WEAPONS и текущими `*card`.

---

## STATUS (2026-07-24)

**GENERATION DONE.** Все картинки, фоны, wordmarks, tooltip shell, inventory panel — уже сгенерированы.  
**Не регенерировать.** Осталось только **подвязать** ассеты в Roblox UI (import → `rbxassetid` → ImageLabel/ImageButton / конфиги).