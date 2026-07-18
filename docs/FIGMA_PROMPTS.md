# FIGMA / AI icon prompts — Sword Masters

Живой пайплайн иконок. Не коммитить тяжёлые PNG без нужды — в git только id + промпты.  
Upload: `docs/ICON_UPLOAD.md` → `Shared.Config.IconConfig`.

---

## 1. Правила арта

| Параметр | Значение |
|----------|----------|
| Canvas | **512×512** PNG, прозрачный фон |
| Display | 64–128 px в UI |
| Стиль | pixel-clean / Minecraft-adjacent + SAO metal |
| Outline | тёмный 2–4 px, читаемость на charcoal HUD |
| Запрет | watermark, мелкий текст на иконке, фото-реализм |
| Naming | `W2_C1.png` = id в WeaponConfig / IconConfig |

**Workflow**
```
FIGMA_PROMPTS → Imagine / Figma AI / game-icons → art/icons/... → Studio Asset Manager → IconConfig
```

**Где искать готовое**
- [game-icons.net](https://game-icons.net/) — силуэты, потом перекраска
- [lucide.dev](https://lucide.dev/icons/) — UI glyphs (бусты, меню)
- Figma Community: «inventory icon», «RPG item icon», «pixel sword»
- SCREEENS folder — референс композиции HUD, не копипаст ассетов

---

## 2. Шаблоны промптов

### 2.1 Weapon (меч)
```
Game inventory icon, square 512x512, transparent background,
[RARITY] [WEAPON NAME], anime sword masters style, SAO metal,
clean silhouette centered, slight rim light, dark 3px outline,
pixel-readable edges, no text, no watermark, no background scene
```

**Rarity append:**
| Rarity | Добавить в промпт |
|--------|-------------------|
| Common | dull iron gray, no glow |
| Uncommon | soft green tint metal |
| Rare | blue steel, soft blue rim |
| Epic | purple steel, soft purple glow |
| Legendary | gold metal, warm gold glow |
| Mythic | black-red metal, red ember glow |
| Secret | white-gold, bright sparkles |
| Limited | hot pink and cyan dual rim light |

**Пример Loc2:**
```
Game inventory icon, square 512x512, transparent background,
Rare pirate cutlass "Клык капитана", anime sword masters style,
blue steel, soft blue rim, clean silhouette centered, dark 3px outline,
no text, no watermark
```

### 2.2 Pet
```
Cute game pet inventory icon, square 512x512, transparent background,
[PET NAME / SPECIES], chibi, [RARITY] soft aura color, dark outline,
centered, no text, no watermark
```

### 2.3 Aura orb
```
Energy aura orb inventory icon, square 512x512, transparent background,
[THEME: fire/shadow/nature/...], glowing ring, [RARITY] color,
game UI style, dark outline, no text
```

### 2.4 Case / crate
```
Loot crate inventory icon, wooden chest with metal straps,
game UI, transparent background, slight gold trim, dark outline, no text
```

### 2.5 Currencies / UI badges
```
Flat game UI icon 128px feel on 512 canvas, transparent background,
[coin | purple enchant dust crystal | gem | power fist],
clean, dark outline, no text
```

### 2.6 Boost strip icons
```
Small flat UI badge icon, transparent background,
[money pouch | flexed arm | lightning bolt | four-leaf clover],
saturated color, dark outline, inventory style
```

---

## 3. Очередь генерации (приоритет)

1. **UI currency:** coin, enchant_dust, gem_stub, power  
2. **Boosts:** money / power / damage / luck  
3. **Case:** crate + mystery cube  
4. **Loc2 weapons** batch (все id из WeaponConfig Loc2)  
5. **Loc3 / Loc4** weapons  
6. **Pets Loc1** set  
7. **Auras** set  
8. Optional: rarity frame overlays  

Loc1 weapons — уже в IconConfig (не перегенерировать без нужды).

---

## 4. Tracking table

Заполняй по мере upload. Пустой rbxassetid = ещё не в игре.

| id | type | prompt_ver | path | rbxassetid | IconConfig |
|----|------|------------|------|------------|------------|
| coin | ui | v1 | art/icons/ui/coin.png | | no |
| enchant_dust | ui | v1 | art/icons/ui/dust.png | | no |
| gem_stub | ui | v1 | art/icons/ui/gem.png | | no |
| boost_money | ui | v1 | art/icons/ui/boost_money.png | | no |
| boost_power | ui | v1 | art/icons/ui/boost_power.png | | no |
| boost_damage | ui | v1 | art/icons/ui/boost_damage.png | | no |
| boost_luck | ui | v1 | art/icons/ui/boost_luck.png | | no |
| case_crate | ui | v1 | art/icons/ui/case_crate.png | | no |
| W2_C1 | weapon | v1 | art/icons/weapons/W2_C1.png | | no |
| … | | | | | |

*(допиши строки под полный WeaponConfig Loc2–4 при генерации)*

---

## 5. Figma / desktop tips

- Figma MCP: искать компоненты, экспортировать PNG 2x  
- Imagine / image gen: один предмет = один промпт, seed lock если серия  
- После upload **только** `IconConfig` / будущий `UiIconConfig` — не хардкодить id в Windows.lua  
- Не класть Keyframe/анимации в Shared  

---

## 6. Связанные доки

- `ICON_UPLOAD.md` — как залить в Studio  
- `ICONS_ART_PLAN.md` — старый art plan (если есть)  
- `MASTER_PLAN.md` — roadmap  
- `WEAPONS_LOOT.md` — имена/редкости мечей  
