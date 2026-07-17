# UI — один источник правды

## Правило

**Только репозиторий (Rojo).**

| Делать | Не делать |
|--------|-----------|
| UI в `src/StarterPlayerScripts/*` | ScreenGui в `StarterGui` |
| `rojo serve` → Play | Edit-preview + runtime вместе |
| Один `GameUI` в PlayerGui | `GameUI_EditPreview` / дубли |

## Почему ломалось

1. В **StarterGui** лежал `GameUI_EditPreview`  
2. В **Play** клонировался в PlayerGui  
3. Код из **репо** монтировал ещё один `GameUI`  
4. **Два HUD** друг на друге (кнопки/чипы «сбежали»)

## Как смотреть UI

**Только Play (F5)** после `rojo serve` + Connect.  
Edit-preview **не используем** — preview = та же игра.

## Если опять два слоя

В Studio → StarterGui: удали всё с именами `GameUI*`, `*Preview*`.  
Сохрани Place.  
`git pull` + Rojo Connect + Play.

## Файлы

- `App.lua` — mount + wipe чужих GUI  
- `Hud.lua` / `Windows.lua` / `Layout.lua` — layout  
- `ClientBootstrap.client.lua` — единственный вход  
