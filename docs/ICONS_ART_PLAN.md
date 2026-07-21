# План иконок: мечи + обводки редкости

> Цель: единый «reference game / SAO-lite» вид, читается в инвентаре 64–128px,  
> масштабируется на 60 мечей × Loc + pets/auras позже.  
> **Слои разделены:** `frame` (редкость) + `item` (меч) + опционально `fx` (Secret/Limited).

---

## 1. Архитектура (как собирать в UI)

```
┌─────────────────────────────┐
│  FRAME (обводка редкости)   │  ← одна на rarity, 8 штук на всю игру
│  ┌───────────────────────┐  │
│  │   ITEM ICON (меч)     │  │  ← уникальная на каждый weapon.id
│  │   (без текста, без    │  │
│  │    baked frame)       │  │
│  └───────────────────────┘  │
│  [ FX overlay optional ]    │  ← Secret spark / Limited aurora (UI particle или png)
└─────────────────────────────┘
```

| Слой | Сколько ассетов | Меняется когда |
|------|-----------------|----------------|
| **Rarity Frame** | **8** (+ empty slot) | почти никогда |
| **Weapon Item** | **60** (Loc1–4) | при добавлении меча |
| **FX badge** | 2–4 (Secret, Limited, NEW, BAN) | редко |
| **Loc accent** (опц.) | 4 маленьких corner mark | если хотим тему локации на common-карточке |

**Почему так:** обводка = мгновенное «насколько жирно», меч = «что именно».  
Не печём rarity в каждый меч — иначе 60× правки при смене стиля рамки.

В Roblox UI:
```
ImageLabel Frame  (Image = rbxassetid rarity frame, ScaleType Fit)
  ImageLabel Item (Image = weapon icon, padding 12–18%)
  optional UIGradient / UIStroke / particles for Limited
```

---

## 2. Style contract (один закон на весь сет)

| Параметр | Решение |
|----------|---------|
| Формат | **квадрат 512×512** master → downsample 256 / 128 |
| Фон item | **плоский keyable** `#00FF00` **или** чистый alpha PNG (предпочтительно transparent) |
| Фон frame | transparent center, ornament only on rim |
| Ракурс меча | **3/4 чуть сверху**, клинок **вверх-вправо ~1–2 часа**, рукоять низ-лево |
| Силуэт | читается в 32px (squint test) |
| Стиль | **anime game inventory icon** (SAO / reference game vibe): clean cel-shade, sharp silhouette, **не** мультяшный «овощной»/casual UI, **не** фото |
| Обводка меча | тонкий dark rim 2–3% canvas для отделения от любого UI-фона |
| Текст | **запрещён** на иконках |
| Отступы item | 12–15% padding от края (место под frame) |
| Освещение | сверху-слева, единое на весь сет |
| Тень | мягкая contact shadow под рукоятью, без «земли» |

**Якорь стиля (генерировать первым):**  
1 эталонный меч Loc1 Common (`W1_C1`) + 1 эталон Legendary → все остальные **edit-chain** от якоря.

### Style v3 (locked — procedural anime)

| Было плохо | Стало |
|------------|--------|
| `image_gen` → рынок/кот/маяк | **System.Drawing** silhouettes only |
| лезвие обрезалось | **pad 56px**, full tip→pommel |
| flat dull | **anime cel**: outline, shine, glow ladder |

**Источник правды:** `tools/gen_loc1_sword_icons.ps1` → `art/icons/weapons/W1_*.png`  

**Loc1:** ржавый / дуб-палка / разбойник / серебро / тень / волк / хранитель / изумруд / легенды / mythic / secret / limited.

---

## 3. Обводки редкости (8 + empty)

Прогрессия «от простого к космосу» — игрок **считывает tier без текста**.

| # | Rarity | Цвет ядра | Толщина / сложность | Эффект (в рамке или UI) |
|---|--------|-----------|---------------------|-------------------------|
| 0 | **Empty** | тёмно-серый 30% | 1 thin line, dashed optional | слот пустой |
| 1 | **Common** | `#AAB0B8` steel grey | 1 thin flat bevel | нет glow |
| 2 | **Uncommon** | `#3DBF6A` leaf green | 1 solid + soft inner | very soft green rim |
| 3 | **Rare** | `#3D7AE8` sapphire | 2-layer (outer+inner) | mild blue shine corners |
| 4 | **Epic** | `#9B4DE0` amethyst | double border + corner gems | purple vignette corners |
| 5 | **Legendary** | `#E8A020` gold | ornate corners, engraved | warm gold outer glow |
| 6 | **Mythic** | `#E83A6A` crimson-pink | jagged/energy notches | animated-ready hot spots |
| 7 | **Secret** | `#FFE066` + white core | runic notches, broken perfection | strong gold bloom + stars |
| 8 | **Limited** | `#FF4EC8` → cyan shift | asymmetric luxury + crystals | dual-tone (pink/cyan), max ornament |

### Визуальные правила рамок

```
Common     ████░░░░  flat metal
Uncommon   █████░░░  clean color
Rare       ██████░░  dual line
Epic       ███████░  gems + depth
Legendary  ████████  gold filigree
Mythic     ████████+ energy cracks
Secret     ████████++ runes + bloom
Limited    ████████+++ crystal + gradient rim (pink↔cyan)
```

- **9-slice safe:** орнамент в углах, ровные mid-edges (UIScale / разные cell sizes).  
- Внутреннее окно (safe area для item): **~78–82%** центра.  
- Внешний glow **не обрезать** — canvas 512 с padding ~6% снаружи ornament.  
- Имена файлов:

```
art/icons/frames/
  frame_empty.png
  frame_common.png
  frame_uncommon.png
  frame_rare.png
  frame_epic.png
  frame_legendary.png
  frame_mythic.png
  frame_secret.png
  frame_limited.png
```

---

## 4. Иконки мечей (item layer)

### 4.1 Именование = `iconKey` из WeaponConfig

```
art/icons/weapons/
  W1_C1.png … W1_X1.png
  W2_C1.png …
  W4_X1.png
```

Roblox: после upload → таблица `IconConfig` / `WeaponConfig.iconAssetId`.

### 4.2 Тематические палитры по локации (сила = rarity, характер = loc)

| Loc | Тема | Материалы / акценты |
|-----|------|---------------------|
| **1 Тёмный лес** | wood, dull iron, moss, violet shadow | leaf etch, wolf tooth, emerald |
| **2 Пиратский берег** | brass, salt steel, navy, coral | rope wrap, shark tooth, black flag |
| **3 Шиноби** | black lacquer, red wrap, pale steel | sakura petal, seal script (as *shape*, not letters), crescent |
| **4 Тундра** | ice crystal, bone white, deep blue | frost edge, aurora glint, polar fang |

**Важно:** rarity уже на frame → на самом мече **не** красить весь клинок «в цвет rarity».  
Вместо этого: качество металла / орнамент / VFX intensity растут с rarity **внутри** темы локации.

| Rarity band | Качество item-арта |
|-------------|-------------------|
| C–U | simple shape, matte metal, little ornament |
| R–E | better silhouette, etched fuller, gem pommel |
| L–M | unique silhouette, magical edge light |
| S | signature design, soft particle-ready glow on blade |
| X Limited | hero prop, dual-color energy, most detail (still 32px-readable) |

### 4.3 Силуэты (чтобы 2 меча одной rarity не путались)

На локацию минимум **2 формы** на rarity-tier (у нас A/B):
- straight longsword  
- curved saber / katana  
- heavy cleaver  
- dual-tone dagger-long  
- spear-sword hybrid (tundra)  

Checklist на каждый меч: **уникальный tip / guard / pommel**.

---

## 5. Порядок генерации (batch pipeline)

```
PHASE 0 — Style anchors (2–3 images)
  A0_style_ref_sword_common_forest
  A0_style_ref_sword_legendary_forest
  A0_frame_board_all_rarities (optional sheet)

PHASE 1 — Rarity frames (8 + empty)     ← СНАЧАЛА, дешёво, UI уже живой
  edit-chain from frame_common → up the ladder

PHASE 2 — Loc1 weapons (15)            ← playable loop
  base W1_C1 from style anchor
  edit-chain per rarity; swap silhouette for _2 variants

PHASE 3 — Loc2 / Loc3 / Loc4 (45)
  keep same camera + lighting contract
  only materials / silhouette theme change

PHASE 4 — FX badges (optional)
  badge_secret_star, badge_limited_crystal, badge_banned

PHASE 5 — Upload + wire
  IconConfig.lua maps iconKey → rbxassetid
  UI: Frame.Image + Item.Image
```

**Не делать:** 60 независимых «с нуля» промптов — сет разъедется.  
**Делать:** 1 якорь → image_edit цепочка с freeze-list (camera, padding, lighting fixed).

---

## 6. Промпт-шаблоны (Imagine)

### 6.1 Style anchor — меч

```
Game inventory item icon, single stylized fantasy sword centered on flat pure
green #00FF00 background, three-quarter view blade pointing upper-right,
soft cel-shaded PBR, clean dark rim light, readable silhouette, generous
padding, no text, no frame, no floor, no particles, mobile game UI quality.
```

+ 1–2 предложения темы (ржавый / золотой лесной / и т.д.).

### 6.2 Frame — редкость

```
Square game UI rarity item frame, transparent center window, ornate border only,
[COLOR DESCRIPTION], corners detailed mid-edges clean for 9-slice, no text,
no sword inside, soft outer glow matching rarity, 512 style, dark fantasy
RPG inventory frame.
```

### 6.3 Edit-chain freeze (меч → следующий)

```
Same camera angle, same padding, same lighting direction, same icon style,
same green key background, same sword scale in frame — change ONLY blade
shape, guard, materials, and glow intensity to match: [NAME / RARITY / LOC].
```

---

## 7. Интеграция в код (после upload)

```lua
-- ReplicatedStorage.Shared.Config.IconConfig.lua (план)
IconConfig.Frames = {
  Common = "rbxassetid://…",
  …,
  Limited = "rbxassetid://…",
}
IconConfig.Weapons = {
  W1_C1 = "rbxassetid://…",
  …
}
-- fallback
function IconConfig.GetWeapon(id)
  return IconConfig.Weapons[id] or IconConfig.Placeholder
end
function IconConfig.GetFrame(rarity)
  return IconConfig.Frames[rarity] or IconConfig.Frames.Common
end
```

UI карточка:
```
Frame (rarity) 
  Item (weapon)
  optional UIStroke color = Rarity.Of(rarity)  -- fallback until frames upload
```

Пока арта нет: `UIStroke` + цвет из `Rarity.lua` (уже есть).

---

## 8. Объём работ (реалистично)

| Пакет | Кол-во | Приоритет | Зачем |
|-------|--------|-----------|--------|
| Frames 8+1 | 9 | **P0** | весь инвентарь сразу «дорогой» |
| Loc1 weapons | 15 | **P0** | playtest |
| Loc2–4 | 45 | P1 | контент |
| FX badges | 3 | P2 | Secret/Limited flex |
| Pets/Auras frames reuse | 0 new frames | — | те же frame_* |

**MVP красоты = 9 frames + 15 Loc1 swords.**  
Остальное — конвейер без смены стиля.

---

## 9. QA checklist

- [ ] Все item на одном key-color / alpha  
- [ ] Рамки: центр пустой, 9-slice углы  
- [ ] 32px: отличить C vs L vs S vs X  
- [ ] Нет текста / водяных знаков  
- [ ] Limited не похож на Secret (pink-cyan vs gold)  
- [ ] Два варианта одной rarity (\_1/\_2) — разный силуэт  
- [ ] Manifest `art/icons/MANIFEST.md`: file → iconKey → status  

---

## 10. Следующий шаг (исполнение)

1. Сгенерировать **sheet всех 8 frames** (пример) + отдельные PNG  
2. Утвердить стиль с тобой  
3. Якорь `W1_C1` + `W1_L1`  
4. Batch Loc1  
5. `IconConfig` + подключить в Windows/UI друга  

Файлы-план рядом: `docs/WEAPONS_LOOT.md` (id мечей), `Rarity.lua` (цвета).
