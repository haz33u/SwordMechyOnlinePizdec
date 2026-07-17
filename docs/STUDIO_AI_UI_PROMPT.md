# Промпт для Roblox Studio AI — выровнять UI (Edit preview)

Скопируй блок в Studio Assistant. Цель: **ровная сетка**, читаемый контраст, превью **без Play**.

---

## PROMPT (copy-paste)

```
You are fixing the VISUAL LAYOUT of Sword Masters HUD in Roblox Studio EDIT mode.

CONTEXT:
- Runtime UI is code-driven under StarterPlayerScripts (Rojo). Do NOT delete gameplay remotes/backend.
- Create OR update a ScreenGui named "GameUI_EditPreview" in StarterGui so designers see layout WITHOUT pressing Play.
- Mark preview with Attribute IsPreview = true. Runtime LocalScripts can ignore it.
- High contrast: almost-white text on mid-dark slate panels. Never dark text on dark fill.
- One gold accent only. No rainbow neon.

GRID RULES (strict):
- Use 8px spacing grid: pad=12, gap=10 between major blocks.
- Left rail: fixed width ~72px, 8 equal square icon buttons (56×56), same gap, centered in rail.
- Top stats: horizontal row of equal-height chips (H=44). Same width ~108 for most chips; location chip may be 1.25× wide.
- Bottom action bar: centered, width ~40% of screen (min 360 max 480). Height fits 52px buttons + 12 pad.
- Three action buttons SAME HEIGHT (52). Width ratio Auto:Click:Rebirth ≈ 1 : 1.35 : 1 with equal gaps.
- Rebirth progress bar: same width as action bar, 8px tall, 10px above the bar.
- Windows (if shown): single centered modal 0.46×0.58 scale, 16px corner, gold 2px top accent line.
- Align left edge of top chips to right of rail + 12px gap. Bottom bar center-X of screen.
- No overlapping frames. No random absolute offsets that break on 1280/1920.

CONTENT (preview static labels OK):
Rail glyphs: UP SW PT AU RL QS MP DG
Chips: СИЛА / CPS / DPS / МОНЕТЫ / КЛИКИ / ЛОКАЦИЯ / REBIRTH
Actions: АВТО | КЛИК | R↑

After building:
1) Parent under StarterGui.GameUI_EditPreview
2) List hierarchy in Output
3) Do not start Play mode
```

---

## Что уже делает код (Rojo)

- `Layout.lua` — 8px grid, equal chip widths, equal action heights  
- `Hud.lua` — rail / chips / actions alignment  
- Runtime: `GameUI` в Play  
- **Play:** `App.lua` удаляет `GameUI_EditPreview` / `IsPreview` из PlayerGui, чтобы **не было двойного HUD**  
- **Edit:** preview живёт в `StarterGui.GameUI_EditPreview` (смотри без Play)

## Workflow

1. В Edit смотри `StarterGui.GameUI_EditPreview` (макет, без remotes)  
2. `rojo serve` + Play → один живой `GameUI`  
3. Не дублируй preview вручную в PlayerGui  
4. Если правишь preview — переноси отступы в `Layout.lua` / `Hud.lua` (источник правды = git)  
