# SwordMechy / Sword Masters

Репозиторий: https://github.com/haz33u/SwordMechyOnlinePizdec

## Зона ответственности

| Repo / код | Studio (Place) |
|------------|----------------|
| Server + Shared + remotes | Карта, terrain, модели |
| **Client UI** (GameUI) | Art, VFX, Team Create |
| Packages: Fusion + OnyxUI | PlayerSpawn на локациях |

## UI stack (утверждён)

- **Fusion** 0.3 — стейт  
- **OnyxUI** — тема / компоненты (Themer gold RPG)  
- **Fluency-style Icons** — `Client/Icons.lua` (подмени ID после импорта Fluency)  
- **Brief:** `docs/UI_BRIEF_FOR_STUDIO_AGENT.md`

## Rojo

```bash
# deps (если Packages пустой)
wally install

rojo serve
```

Синкается:

- `ReplicatedStorage.Shared`
- `ReplicatedStorage.Packages`
- `ServerScriptService.Server`
- `StarterPlayer.StarterPlayerScripts.Client` → GameUI

`Workspace` Rojo **не** трогает.

## Документы

| Файл | Зачем |
|------|--------|
| **[docs/UI_BRIEF_FOR_STUDIO_AGENT.md](docs/UI_BRIEF_FOR_STUDIO_AGENT.md)** | **Бриф UI (reference game) — для Studio Agent** |
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
