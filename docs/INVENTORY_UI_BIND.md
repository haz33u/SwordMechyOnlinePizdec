# Inventory UI bind (Figma LAYOUT → Roblox)

**Status:** source of truth for controls + tooltip + sell mode.  
**Assets:** `InventoryAssetConfig.lua` · **Chrome:** Figma `*LAYOUT` on Welcome page.

---

## Text style (ALL UI — mandatory)

- Font: `LuckiestGuy` via `Font.fromEnum(Enum.Font.LuckiestGuy)` (fallback GothamBold if font missing)
- `TextColor3 = white` (gradient paints it)
- `BackgroundTransparency = 1`, `TextScaled = true` where appropriate
- Every text: `UIStroke` (`#0a0824`, thickness 2–4) + `UIGradient` rotation 90
- Gradients: purple / gold / green / red / gray — see `UIKit.StyleText`
- **ALL CAPS ENGLISH only** (no Cyrillic)
- Static screen titles = PNG wordmarks; live numbers/names = TextLabel

Helper: `UIKit.StyleText(label, gradientName)`

---

## Tooltip (`TOOLTIPshell`)

- **Fixed** panel (not free-follow cursor) — inspect dock on inventory body
- Real tooltip background asset, not baked layout mock
- Text **centered**
- Order (top → bottom):
  1. `EQUIPPED MAIN` or `EQUIPPED OFFHAND` (if equipped)
  2. Item name
  3. Rarity (under name)
  4. `POWER:` · `SELL PRICE:` · `LEVEL:`
- Hover slot → fill fixed tooltip; leave → clear/hide

---

## Slot grid

- Hover: smooth scale ~**1.06** (only hovered card; neighbors static)
- Gap between cards: **larger** than legacy tight grid (`SLOT_GAP` ≥ 20)
- Frames by rarity: Empty→Mythic single PNG; **Secret** one layer; **Limited** = Body + Rim + rim gradient anim
- Locked items: card **slightly greyed**

---

## Mouse binds (weapons tab)

| Input | Action |
|-------|--------|
| **LMB** | Equip main if not equipped; **unequip** if already on main/offhand |
| **RMB** | Enter **Sell Mode** + mark that sword red (select) — does not sell immediately |
| **MMB** | **Merge** (`Net.MergeWeapon` — existing 5×L1→L2 / 3×L2→L3) |
| **Ctrl + MMB** | **Lock / Unlock** item (`w.locked`) |

No plain EQUIP button — LMB only.

### Sell Mode

1. Enter via **RMB** on a sword (or SELL chrome button).
2. Bottom-left of weapon grid: confirm check `BTN_Confirm_Check_1`.
3. **LMB** while in Sell Mode = toggle red select filter (not equip).
4. Confirm check → modal **above all** (plate like `STATS1card`/`STATS2card`):
   - Text: `ARE YOU SURE?`
   - Buttons: check (confirm sell selected) + X (cancel, same close art as inv)
5. Confirm sells only **selected unlocked** swords (skip locked + equipped rules as server enforces).

### Lock rules

- Locked items **cannot** be sold by **Sell all unlocked**.
- Single **SELL** / Sell Mode can still target them only if design allows — **current rule:** Sell Mode **skips locked**; grey locked cards never join multi-sell.
- Locked card visual: grey overlay / desaturate.

### Sell all unlocked

- Server skips `w.locked == true` and equipped weapons.

---

## Profile titles

- `OPENtitlesLISTbutton` opens titles list (Figma `PROFILE LAYOUT (open titles list)` / `TITILESlistcard`)
- Scrolling list: title name + how to unlock (live text)
- Plate style like STATS cards

## Settings

- Rainbow toggle ON/OFF assets + short on/off animation

## Cases

- **Not** in inventory tab rail (Figma has no Cases button)

---

## Stubs / later

- RMB sell-mode UX may expand (filters, bulk rules)
- Secret/Limited frame polish
- Full Figma shell swap (MAINBACKGROUD, tab PNG rail) incremental

---

## Code map

| Piece | Where |
|-------|--------|
| Asset ids | `Config/InventoryAssetConfig.lua` |
| Style helper | `UIKit.StyleText` |
| Lock / sell all | `WeaponService` + `Remotes.ToggleWeaponLock` |
| Grid binds / sell mode | `Inventory.lua` weapons tab |
| Merge | existing `MergeWeapon` |
