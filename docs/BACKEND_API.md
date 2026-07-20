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
| `RequestRebirth` | — | Needs **lifetimeDamage + coins** (RebirthConfig); spends coins |
| `BuyUpgrade` | `upgradeId` | RunSpeed, Backpack, Power, ClickSpeed, CritChance, Luck |
| `EquipWeapon` | `weaponUid, slot?` | `"main"` / `"offhand"` |
| `SellWeapon` | `weaponUid` | |
| `EnchantWeapon` | `weaponUid` | Costs coins |
| `OpenPetCase` | `poolId?` | Pool e.g. `loc1_500` / `loc1_50k` / `loc1_key49`. Coins and/or keys per `PetConfig.CasePools`. Fires `CaseResult` |
| `EquipPet` / `UnequipPet` | `petUid` | Team slots |
| `FeedPet` | `petUid` | Coins → level up |
| `SellPet` | `petUid` | Coins = `sellPrice`; unequips if on team |
| `OpenAuraCase` | — | Spends **auraKeys** (`CaseConfig.AURA_KEY_COST`). Fires `CaseResult` |
| `EquipAura` | `auraUid` | |
| `ClaimQuest` | `questId` | |
| `SetLocation` | `locId` 1–4 | Teleports **only if** `PlayerSpawn` exists on map |
| `StartDungeon` | `"easy"`/`"medium"`/`"hard"` | |
| `BanDrop` | `kind, id, banned` | weapon/pet/aura |
| `DebugSpawnDummy` | — | Spawn training dummy on current location |
| `UnlockPaidFeature` | `"offhand"` \| `"paidPetSlot"` | Paid unlocks (DEBUG free if `ProgressConfig.DEBUG_FREE_PAID`) |

### Pet slots & offhand (`ProgressConfig`)

| Slots | Source |
|-------|--------|
| 3 | start free |
| 4 | rebirth **R2** |
| 5 | rebirth **R6** |
| 6 | easy dungeon **5 clears** |
| 7 | paid `paidPetSlot` |
| Offhand 50% | paid `offhand` only |

### Server → Client

| Name | Payload |
|------|---------|
| `ProfileUpdate` | `{ profile, stats }` |
| `CombatFx` | hit/crit numbers |
| `Notify` | `{ text, color }` — optional toast in **your** UI |
| `CaseResult` | `{ kind: "pet"\|"aura", success, id?, uid?, name?, rarity?, powerPct?, keysLeft?, reason? }` — accurate spin result |

### Case keys (profile)

| Field | Meaning |
|-------|---------|
| `petKeys` | Opens pet case (1 key / open by default) |
| `auraKeys` | Opens aura case |
| Drop | Kill mobs — chance by tier in `CaseConfig` |
| Starter | New profile: `STARTER_PET_KEYS` / `STARTER_AURA_KEYS` |
| Stats | `stats.petKeys`, `stats.auraKeys` in Snapshot |

### RemoteFunction

| Name | Returns |
|------|---------|
| `GetProfile` | `{ profile, stats, mobs }` |
| `GetMobCatalog` | static mob defs (name, tier, hp, visual hints) |

### Server → Client (mobs)

| Name | Payload |
|------|---------|
| `MobsUpdate` | array of live mob instances for current loc |

### Stats snapshot (useful for HUD)

```
totalPower, cps, dps, damagePerClick, totalClicks,
swingCd, crit, coins, rebirthLevel, rebirthMult,
nextRebirthCost (damage), nextRebirthCoinCost, rebirthProgress,
lifetimeDamage, autoClicker, location, ...
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
