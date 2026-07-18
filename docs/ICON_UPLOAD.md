# Как загрузить иконки мечей в игру (Roblox)

Исходники: `art/icons/weapons/W1_*.png` (15 штук Loc1).  
Код смотрит на: `Shared.Config.IconConfig.WeaponAssetIds`.

Rojo **не** превращает PNG в рабочие `Image` для published place — нужен **upload → rbxassetid**.

---

## Способ A — Asset Manager (рекомендуется)

1. Открой Place в **Roblox Studio**
2. **View → Asset Manager** (или Toolbox → Creations → Images)
3. **Bulk Import** / перетащи все `W1_*.png` из  
   `D:\RobloxProject\САО БРАТ\art\icons\weapons\`
4. Дождись загрузки (статус Completed)
5. ПКМ по картинке → **Copy Id** (число)
6. Вставь в `src/ReplicatedStorage/Shared/Config/IconConfig.lua`:

```lua
WeaponAssetIds = {
  W1_C1 = "rbxassetid://1234567890", -- id из Studio
  W1_C2 = "rbxassetid://...",
  -- ...
}
```

7. `git pull` у тиммейтов → `rojo serve` → Connect  
8. Play → окно **Мечи** — иконки на карточках

Имя файла = id меча (`W1_R1.png` → ключ `W1_R1`).

---

## Способ B — один файл через Game Explorer

1. В Explorer: `ReplicatedStorage` → добавить Folder `DevIcons` (опционально)
2. Import each image as Decal/Image  
3. Всё равно скопируй **asset id** в `IconConfig` — клиент читает только оттуда

---

## Проверка

| Шаг | Ожидание |
|-----|----------|
| `IconConfig.WeaponAssetIds.W1_C1` пустой | generic меч (fallback) |
| id заполнен | твоя PNG на карточке |
| Publish place | иконки видны всем (asset must be **Creator of place** / group) |

Если id с **другого** аккаунта — поставь permissions **Use in experiences** / загружай с владельца place.

---

## Список Loc1 для paste

```
W1_C1  W1_C2
W1_U1  W1_U2
W1_R1  W1_R2
W1_E1  W1_E2
W1_L1  W1_L2
W1_M1  W1_M2
W1_S1  W1_S2
W1_X1
```

Переген PNG:
```powershell
powershell -ExecutionPolicy Bypass -File tools/gen_loc1_sword_icons.ps1
```

---

## Почему не «просто Rojo»?

| Rojo sync | Картинки |
|-----------|----------|
| `.lua` → scripts | да |
| `.png` → live Image для всех игроков | **нет** (нужен CDN asset id) |

После upload id **в git** — тиммейтам upload не нужен, только pull.
