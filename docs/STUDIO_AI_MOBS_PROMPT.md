# Промпт для Roblox Studio AI — мобы Sword Masters

Скопируй блок ниже целиком в Studio AI / Assistant.  
Backend уже спавнит сущности; AI только делает **красивые модели**.

---

## PROMPT (copy-paste)

```
You are building COMBAT MOB MODELS for a Roblox game "Sword Masters" (dark fantasy / reference game idle-combat vibe).

CRITICAL RULES:
1) Do NOT rewrite ServerScriptService gameplay, remotes, or Shared configs.
2) Put finished Models under ReplicatedStorage.MobTemplates (or Workspace.MobTemplates).
3) Name each Model EXACTLY after preferredModelName below — backend will clone them if present.
4) Each Model must have a PrimaryPart (or a Part named Root). Anchored is fine.
5) Keep collision simple: PrimaryPart/Root CanCollide=true; decorations CanCollide=false.
6) Do NOT remove existing ClickDetector/MobHud if the runtime already attaches them — models are pure visuals.
7) Style: readable silhouettes from 30–60 studs, not hyper-detailed mush. Dark forest palette (purples, greens, bone, ember red for boss).
8) Scale roughly human-ish (1–2.5 studs wide) unless boss (~1.6–2×).

CREATE THESE MODELS:

1) L1_Slime — "Теневой слизень"
   - purple/black translucent slime blob, googly eyes optional
   - low-poly, cute-but-hostile, scale ~0.7–1

2) L1_GoblinScout — "Гоблин-разведчик"
   - small green humanoid, ragged cloth, pointy ears, simple spear optional (welded, non-collide)

3) L1_Skeleton — "Лесной скелет"
   - bone white R6-ish humanoid, hollow eyes, maybe wooden shield/sword props

4) L1_Wolf (if used) / similar quad predators
   - dark fur quadruped silhouette, clear head + legs + tail

5) L1_Knight / elite humanoids
   - darker armor plates, taller torso, red accents

6) L1_Boss — forest guardian boss
   - large, crown/antlers, red highlight, imposing silhouette, scale ~1.8–2.2

7) Dummy — training dummy
   - wooden post + sack body + painted face, orange/yellow accents, clearly “practice”

For each model:
- Group as Model, set PrimaryPart
- Optional: Attribute MobId = matching id
- Optional Attachment "HudAttach" on head for future billboards
- Keep polycount reasonable for many spawns (10–40 parts max per mob)

After building:
- Parent all under ReplicatedStorage.MobTemplates
- Print a short checklist of names created
```

---

## Как backend подхватит

`MobVisualService` сначала ищет:

```
Workspace.MobTemplates.<preferredModelName>
или
ReplicatedStorage.MobTemplates.<preferredModelName>
```

Имена в `MobConfig.visual.preferredModelName` (например `L1_Slime`, `Dummy`).  
Если модели нет — спавнится улучшенный placeholder (силуэт из частей).

## Чеклист после AI

- [ ] `ReplicatedStorage.MobTemplates` существует  
- [ ] Имена совпадают 1:1 с `preferredModelName`  
- [ ] У каждой модели есть `PrimaryPart`  
- [ ] Play → мобы выглядят как модели, HP bar сверху, клик бьёт  
