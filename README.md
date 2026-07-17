# SwordMechy / Sword Masters — **Backend only**

Репозиторий: https://github.com/haz33u/SwordMechyOnlinePizdec

## Зона ответственности

| Мы (этот repo / я) | Вы + Studio Agent |
|--------------------|-------------------|
| Server services | Карта, terrain, модели |
| Config / Formulas | Весь UI (ScreenGui) |
| Remotes API | VFX, звук, анимации |
| Профиль, клики, rebirth… | Team Create коллаб |

**Никакого** клиентского HUD и **никакой** генерации построек в Workspace.

## Rojo

```bash
rojo serve
```

Синкается только:

- `ReplicatedStorage.Shared`
- `ServerScriptService.Server`

`Workspace` / `StarterGui` — **ваши**, Rojo не трогает.

## Документы

| Файл | Зачем |
|------|--------|
| **[docs/UI_BRIEF_FOR_STUDIO_AGENT.md](docs/UI_BRIEF_FOR_STUDIO_AGENT.md)** | **Бриф UI (Cristalix) — для Studio Agent** |
| [docs/BACKEND_API.md](docs/BACKEND_API.md) | Remotes для UI |
| [docs/STUDIO_AGENT.md](docs/STUDIO_AGENT.md) | Как стыковать Studio Agent |
| [docs/COLLAB.md](docs/COLLAB.md) | Git + друг |
| [docs/CORE_SYSTEMS.md](docs/CORE_SYSTEMS.md) | Игровые системы |
| [docs/WORLD_SETUP.md](docs/WORLD_SETUP.md) | Масштабы локаций (числа) |
| [docs/MOBS_LOC1.md](docs/MOBS_LOC1.md) | Мобы Loc1 + Debug Dummy |

## Карта (ваша)

```
Workspace.World.Locations.Loc01.PlayerSpawn  -- Part
```

Без `PlayerSpawn` телепорт локаций просто не сработает (безопасно).

## Версия

`0.3.0-backend-only`
