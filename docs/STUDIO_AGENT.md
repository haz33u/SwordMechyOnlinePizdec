# Я (Grok / backend) + Agent в Roblox Studio

## Можно ли «совместить» в одного агента?

**Нет как один процесс.**  
Studio Agent и я — разные среды.

| | Я (этот чат / repo) | Studio Agent |
|--|---------------------|--------------|
| Код сервисов, баланс, remotes | ✅ | ❌ (лучше не дублировать) |
| Terrain, модели, lighting | ❌ | ✅ |
| ScreenGui / ваш UI | ❌ (мы убрали) | ✅ |
| GitHub `src/` | ✅ | через Rojo sync |

**Рабочая схема:**

```
Ты / друг ──► Studio Agent: карта + UI
         ──► Rojo ◄── GitHub (backend от меня)
```

1. Я пушу backend в GitHub.  
2. Вы `git pull` + Rojo Connect.  
3. Studio Agent строит мир/UI и **только вызывает remotes**.  

---

## Правила для Studio Agent (чтобы не ломал backend)

1. **Не переписывать** `ServerScriptService/Server` и `ReplicatedStorage.Shared` вручную вразрез с Git.  
2. UI → `FireServer` / `OnClientEvent` из `BACKEND_API.md`.  
3. Карта → `Workspace.World.Locations.Loc0N` + `PlayerSpawn`.  
4. Не спамить свои DataStores — профиль уже в `ProfileService`.  

---

## Минимальный UI от Agent (пример логики)

```lua
-- LocalScript (пишет Agent)
local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
Remotes.Swing:FireServer(nil, "manual")
Remotes.ToggleAutoClicker:FireServer()
Remotes.ProfileUpdate.OnClientEvent:Connect(function(data)
  -- update YOUR labels from data.stats
end)
```

---

## Если Agent и я конфликтуют

- **Источник правды по геймплею** = GitHub `src/`  
- **Источник правды по арту** = Place / Team Create  
- Конфликт скриптов → откат Place scripts, Rojo заново  
