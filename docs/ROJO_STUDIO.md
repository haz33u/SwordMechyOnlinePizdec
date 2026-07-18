# Rojo + Studio: почему удаляет Animations

## Почему

Rojo sync: **файлы на диске (`src/`) = истина**.

Если ты создал в Studio:

```
ReplicatedStorage.Shared.Animations   ← внутри зоны Rojo ($path Shared)
```

а в git **нет** `src/ReplicatedStorage/Shared/Animations/`, Rojo помечает папку 🗑️ **Delete**.

`$ignoreUnknownInstances` в project.json **на `$path` часто не спасает** (Live Sync всё равно показывает delete). Надёжнее:

1. **`.meta.json`** рядом с папкой path  
2. **Не класть анимации внутрь `Shared`**

---

## Куда класть анимации (правильно)

```
ReplicatedStorage
├── Shared/              ← только код из Rojo (lua)
├── Packages/
├── Animations/          ← Idle, Walk, Run, Swing  (Studio / Place)
└── CombatAnimations/    ← Swing1, Swing2 KeyframeSequences
```

**НЕ** `Shared.Animations` — Rojo считает это «лишним» в code tree.

### Перенос одной минутой

1. **Отключи Rojo** (Disconnect) или не жми Accept на delete  
2. В Explorer: `Shared.Animations` → **cut**  
3. Вставь в `ReplicatedStorage` → получится `ReplicatedStorage.Animations`  
4. То же для dummy packs → `ServerStorage` (уже ignore)  
5. **Save place**  
6. Снова Connect Rojo — delete на Animations **не должно** быть  

---

## После нашего фикса в git

- `src/**/init.meta.json` → `ignoreUnknownInstances: true`  
- `default.project.json` → явные папки `Animations` + `CombatAnimations` с ignore  

```powershell
git pull
# ПОЛНОСТЬЮ закрой rojo serve (Ctrl+C) и запусти снова
rojo serve
```

В Studio: **Disconnect → Connect** (не только reconnect sometimes).

---

## Если всё ещё 🗑️

| Действие | |
|----------|--|
| Не нажимай **Accept** / Sync all deletes | потеряешь анимации |
| **Reject** delete в Rojo diff | |
| Убедись, что serve из **папки репо** с новым `default.project.json` | |
| Анимации **вне** `Shared` | обязательно |

---

## CombatController

Если Rojo хочет удалить `Client.CombatController` — его нет в `src/StarterPlayerScripts`.  
Либо перенеси скрипт в git, либо оставь с meta ignore, либо в папку вне Client path.
