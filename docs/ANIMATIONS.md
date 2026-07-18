# Анимации атаки и мечи на руках

## Что сделано

| Фича | Где |
|------|-----|
| Меч **main** → `RightHand.RightGripAttachment` | `WeaponVisual.lua` |
| Меч **offhand** → `LeftHand.LeftGripAttachment` | то же |
| Анимация удара на Swing / CombatFx / Space / КЛИК | `WeaponVisual.PlayAttack` |
| **Swing1 / Swing2** с Combat Dummy | `ReplicatedStorage.CombatAnimations` (Place) |

## Опубликованная атака (сейчас в игре)

| | |
|--|--|
| Store | https://create.roblox.com/store/asset/133642421878218 |
| Config | `AttackMain` / `AttackAlt` = `rbxassetid://133642421878218` |
| Рука | правая (main swings) |

Если анимация **не играет** у других игроков: owner place должен иметь право на asset (твой аккаунт / group publish / Allow Copying).

## Откуда Swing1 / Swing2 (Keyframe, без publish)

Цифры в `Keyframe` — это **время кадра** (0, 0.05…), **не** asset id.

Источник:
```
ServerStorage.AnimPack_SwordFightingCombat["Combat Dummy"].AnimSaves.swing1
ServerStorage.AnimPack_SwordFightingCombat["Combat Dummy"].AnimSaves.swing2
```

Скопировано в Place:
```
ReplicatedStorage.CombatAnimations.Swing1   (KeyframeSequence)
ReplicatedStorage.CombatAnimations.Swing2
```

Клиент регистрирует их через `KeyframeSequenceProvider:RegisterKeyframeSequence`  
→ играет **без Publish**. Обе — удары **правой** руки, чередуются.

**Важно:** `CombatAnimations` живёт в **Place** (Team Create). В git/Rojo KeyframeSequence не лежит.  
Не удаляй папку в Studio. После клона place — если пропала, снова скопируй из AnimSaves.

## Fallback (если папки нет)

| | Asset |
|--|--------|
| Swing1 fallback | `rbxassetid://522635514` toolslash |
| Swing2 fallback | `rbxassetid://522638767` toollunge |

## Свои анимации

1. В Studio: Avatar → Animation Editor → R15 swing → **Publish to Roblox**
2. Скопируй Asset ID
3. В `AnimationConfig.lua`:

```lua
AttackMain = "rbxassetid://ТВОЙ_ID",
AttackAlt = "rbxassetid://ТВОЙ_ID_2",
```

4. `rojo serve` / pull → Play

**Важно:** анимация должна быть **R15** (или Rthro), owner = place creator / group, иначе не проиграется у игроков.

## Если slash не играет

- Персонаж R6 → эти ID могут не подойти (нужны R6 ids или R15 only place)
- Animation privacy
- Консоль: ошибки `LoadAnimation` / `Animation failed to load`

## Place check

В репо/Place **не** было своих Animation instances — Studio Agent только музей Parts.  
Grip points — дефолт R15.
