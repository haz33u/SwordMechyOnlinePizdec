# Backend API (for your UI / Studio Agent)

We only ship **server + Shared**.  
**No ScreenGui, no parts, no scaffold.**

---

## Remotes

All under `ReplicatedStorage.Remotes` (created at runtime).

### Client → Server (RemoteEvent)

| Name | Args | Effect |
|------|------|--------|
| `Swing` | `targetMobUid?, source?` | Click attack (`"manual"` / `"auto"`) |
| `ToggleAutoClicker` | — | Toggle auto farm |
| `RequestRebirth` | — | Rebirth if damage enough |
| `BuyUpgrade` | `upgradeId` | RunSpeed, Backpack, Power, ClickSpeed, CritChance, Luck |
| `EquipWeapon` | `weaponUid, slot?` | `"main"` / `"offhand"` |
| `SellWeapon` | `weaponUid` | |
| `EnchantWeapon` | `weaponUid` | Costs coins |
| `OpenPetCase` | — | |
| `EquipPet` / `UnequipPet` | `petUid` | |
| `FeedPet` | `petUid` | |
| `OpenAuraCase` | — | |
| `EquipAura` | `auraUid` | |
| `ClaimQuest` | `questId` | |
| `SetLocation` | `locId` 1–4 | Teleports **only if** `PlayerSpawn` exists on map |
| `StartDungeon` | `"easy"`/`"medium"`/`"hard"` | |
| `BanDrop` | `kind, id, banned` | weapon/pet/aura |

### Server → Client

| Name | Payload |
|------|---------|
| `ProfileUpdate` | `{ profile, stats }` |
| `CombatFx` | hit/crit numbers |
| `Notify` | `{ text, color }` — optional toast in **your** UI |

### RemoteFunction

| Name | Returns |
|------|---------|
| `GetProfile` | `{ profile, stats, mobs }` |

### Stats snapshot (useful for HUD)

```
totalPower, cps, dps, damagePerClick, totalClicks,
swingCd, crit, coins, rebirthLevel, rebirthMult,
nextRebirthCost, lifetimeDamage, autoClicker, location, ...
```

---

## Map convention (you build)

```
Workspace.World.Locations.Loc01.PlayerSpawn  -- BasePart
Workspace.World.Locations.Loc02.PlayerSpawn
...
```

Optional: put art under `Loc01.Art` — backend ignores it.

If no `PlayerSpawn` → teleport is skipped (no void).

---

## Balance / systems

All numbers: `ReplicatedStorage.Shared.Config.*`  
Math: `Shared.Formulas`

---

## Studio Agent prompt (copy-paste)

```
This place uses a BACKEND-only game framework.
Scripts are in ServerScriptService and ReplicatedStorage.Shared (synced via Rojo).
Do NOT create gameplay ScreenGui unless asked.
Do NOT put game logic in LocalScripts that bypass remotes.
Build map under Workspace.World.Locations.Loc01..Loc04.
Each Loc needs a BasePart named PlayerSpawn.
Client UI should FireServer remotes listed in docs/BACKEND_API.md
and listen to ProfileUpdate for stats.
```
