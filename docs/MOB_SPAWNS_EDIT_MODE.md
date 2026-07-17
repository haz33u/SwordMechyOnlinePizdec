# Спавн мобов в Edit Mode (контроль в Studio)

## Проблема

Раньше мобы появлялись **только в Play** из математики — неудобно двигать.

## Решение

1. **В Edit** стоят **маркеры** (неоновые платформы) в:
   ```
   Workspace.World.Locations.Loc01.MobSpawns
   ```
2. У каждой: Attribute **`MobId`** = `L1_Slime` / `DEBUG_Dummy` / …
3. Ты **перетаскиваешь** Part в Edit → **Save Place**
4. В **Play** сервер читает маркеры и спавнит killable-мобов **ровно там**

Fallback: если маркеров нет — старая математика (warning в Output).

---

## Как поставить маркеры один раз

### Вариант A — Command Bar (рекомендуется)

1. Studio **Edit** (не Play)
2. **View → Command Bar**
3. Открой файл `tools/studio_command_place_loc1_mob_spawns.lua`
4. Вставь **весь** код → Enter
5. Появится `World.Locations.Loc01.MobSpawns` + `PlayerSpawn`
6. **Ctrl+S / Publish** place

### Вариант B — MCP (когда Studio MCP connected)

Попросить агента: «выполни command bar script для Loc01 MobSpawns»  
через `execute_luau` datamodel **Edit**.

### Вариант C — вручную

Создай Part → Attribute `MobId` = `L1_Slime` → в папку `MobSpawns`.

---

## Правила

| Можно | Нельзя |
|--------|--------|
| Двигать / крутить маркеры | Удалять Attribute `MobId` |
| Копировать маркер (новый spawn) | Ждать Play, чтобы «увидеть» точки |
| Менять цвет/размер маркера | Класть combat-модели в MobSpawns (это якоря) |

В **Play** combat-модели идут в `Workspace.Mobs` (отдельно от маркеров).

---

## Список MobId (Loc1)

`L1_Slime`, `L1_GoblinScout`, `L1_Skeleton`, `L1_Wolf`, `L1_GoblinWarrior`, `L1_Knight`, `L1_Boss`, `DEBUG_Dummy`
