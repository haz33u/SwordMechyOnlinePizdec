# MY_GENERATE_PLAN — Tooltip Shell + Equipped Badges + Inventory Panel BG

**Дата:** 2026-07-24  
**Цель:** Генерация 3 ключевых asset в лучшем виде (SVG + PNG, полный ресурс, чикпи)

**Цветопалитра:** Только из `--main` + WORDMARKS_PureText + GamePass_Cards + *BUTTON и *card из Figma (ты загузишь)

## 1. Tooltip Shell (пустая тарелка) — Primary Asset

**Пути:**
- `TOOLTIPS/Tooltip_Shell_Empty.svg` (главный файл)
- `TOOLTIPS/Tooltip_Shell_Empty.png` (~480×280 + ~640×360)

**Правила:**
- Использовать `GamePass_Card_Background.svg` как базу (muted версия)
- Сделать soft navy-purple plate, gentle rim, deep empty center
- Контраст: **тише** Weapons card (lower saturation, softer rim)
- Empty center — для live TextLabel (pad ~16–20px)
- Transparent outside

## 2. Equipped Badges (EQUIPPED MAIN / OFFHAND)

**Пути:**
- `WORDMARK_EQUIPPED_MAIN.png`
- `WORDMARK_EQUIPPED_OFFHAND.png`

**Правила:**
- Tier B candy wordmarks (использовать `_render_one` из WORDMARKS_PureText)
- Exact strings: `EQUIPPED MAIN` и `EQUIPPED OFFHAND`
- Размер и плотность как текущие wordmarks

## 3. Inventory Panel Background

**Пути:**
- `INVENTORY_UI/Inventory_Panel_Background.svg` (главный)
- `INVENTORY_UI/Inventory_Panel_Background.png`

**Правила:**
- Большая мягкая панель (muted purple-navy, gentle vignette, very soft rim)
- **No busy stars**, no competing logos
- Безопасные margins для grid/slots/header
- Base: muted версия `GamePass_Card_Background 2` + Figma `*BUTTON` tonality

## 4. Figma Mock (для тебя)

Создать один Figma файл с 4 вариантами:
1. Tooltip Shell only
2. Shell + sample live text layout (как в plan)
3. Shell + EQUIPPED MAIN wordmark
4. Shell + EQUIPPED OFFHAND wordmark

Сравнить side-by-side с INVENTORY_WEAPONS и текущими `*card`.

**Экспорт:** Все SVGs + PNG в папки `TOOLTIPS/`, `INVENTORY_UI/`, `WORDMARKS_PureText/`

---

**Генерация** — начинаем с референсов.  
Кидай файлы из `--main` + WORDMARKS_PureText + README_GamePass_Cards.txt + Figma (*BUTTON, GamePass_Card_Background 2).

Я сразу подгоню под них и начну генерацию в лучшем виде. 

Готов? Кидай рефы.