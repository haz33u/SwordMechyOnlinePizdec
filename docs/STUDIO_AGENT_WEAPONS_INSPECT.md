# Промпт для Roblox Studio Agent — осмотр системы мечей

Скопируй блок **PROMPT** целиком в Studio Agent (после `git pull` + Rojo sync / Play sync).

Коммит: `753e088` — weapon catalog Loc1–4, weighted drops, Limited.

---

## PROMPT (copy below)

```
You are Roblox Studio Agent for the game "Sword Masters" (SwordMechy).

GOAL
Make the WEAPON / INVENTORY / LOOT system VISIBLE and TOUCHABLE in Studio so a human can walk around, click things, read labels, and understand how swords work — WITHOUT rewriting backend balance.

DO NOT
- Do not delete World Art / player maps
- Do not rewrite WeaponConfig balance numbers
- Do not break CombatService / ProfileService / Rojo source of truth under src/
- If Rojo is connected: prefer reading scripts under ReplicatedStorage.Shared and ServerScriptService — do not duplicate logic into orphan scripts that will be wiped
- Limited swords must NOT drop from normal mobs (already dropDisabled)

CONTEXT (read these ModuleScripts first)
1) ReplicatedStorage.Shared.Config.WeaponConfig
   - Full catalog Loc1–4 (60 swords)
   - Rarities: Common → Uncommon → Rare → Epic → Legendary → Mythic → Secret → Limited
   - LOCATION_BASE, RARITY_REL, LocationProgression, TierDropChance, TierRarityWeights
   - API: Get, GetByLocation, GetDropCandidates, RollRarity, GetBaseDropChance, GetPublicCatalog
2) ReplicatedStorage.Shared.Config.MobConfig — tier, location, weaponDropScale, weaponPool allowlist
3) ServerScriptService.Services.LootService — drop on kill
4) ServerScriptService.Services.WeaponService — equip / sell / enchant / ban
5) StarterPlayerScripts.Rarity — UI colors including Limited

RARITY COLORS (use for parts / BillboardGui)
- Common #AAAFB9
- Uncommon #48B464
- Rare #4682E6
- Epic #A050DC
- Legendary #E6A032
- Mythic #E6466E
- Secret #FFE678
- Limited #FF50C8 (extra neon / ParticleEmitter OK)

══════════════════════════════════════
PART A — EDIT MODE INSPECT WORLD
══════════════════════════════════════

Create under Workspace (Edit mode, must persist when Play stops):

Workspace.DebugInspect.Weapons
  Loc01_DarkForest
  Loc02_Pirate
  Loc03_Shinobi
  Loc04_Tundra
  _Legend (how to read)
  _DropTables (optional posters)

For EACH weapon in WeaponConfig.Weapons (or hardcode from catalog if require fails in edit):
- Spawn a small handle Part or MeshPart (size ~0.4, 0.4, 3) standing vertical
- Name = weapon.id (e.g. W1_R2)
- Color / Material by rarity (Limited = Neon + light pink PointLight)
- Attributes on the Part:
    WeaponId, NameRU, Rarity, PowerMult, Location, SellPrice, IconKey, VfxProfile, DropDisabled
- BillboardGui above each sword (AlwaysOnTop):
    Line1: id + rarity
    Line2: name
    Line3: ×powerMult | sell
- Layout: grid per location folder
    X spaced 6 studs, rarities in rows (Common front → Limited back)
    Or circle ring per rarity
- Secret: subtle yellow PointLight
- Limited: pink PointLight + simple ParticleEmitter (sparkles) — showcase only

Also create ONE big board near Loc1 spawn (or Workspace.DebugInspect.Weapons._Legend):
  SurfaceGui or Billboard with short Russian text:

  «МЕЧИ
  Дроп = шанс(tier)×loc×(1+luck) → редкость → случайный меч ЭТОЙ локации
  Loc1 лёгкий; Loc2+ дольше (реже Epic+)
  Limited НЕ с мобов — только ивент/VFX
  Кликни меч = Print attributes in Output
  Play: убей моба → toast дропа; открой UI мечей»

Add ClickDetector on each sword Part:
  On click → print full attributes to Output (and optional ephemeral Billboard "copied")

If Workspace.World.Locations.Loc01 exists, put a portal Part "WeaponMuseum" near PlayerSpawn that teleports player camera/character to DebugInspect.Weapons (Play only OK).

══════════════════════════════════════
PART B — DROP TABLE POSTERS (Edit)
══════════════════════════════════════

Under DebugInspect.Weapons._DropTables create 4 Parts with SurfaceGui text (readable):

Poster 1 — TierDropChance
  trash 4.5% | normal 7.5% | elite 13% | boss 48%

Poster 2 — LocationProgression
  Loc1 ×1.00 drop / ×1.00 high
  Loc2 ×0.82 / ×0.62
  Loc3 ×0.68 / ×0.40
  Loc4 ×0.55 / ×0.26

Poster 3 — Boss rarity weights (base before high squeeze)
  Rare 18 | Epic 30 | Legend 32 | Mythic 14 | Secret 6

Poster 4 — How LootService works (3 lines)
  1 chance roll  2 rarity roll  3 pick from loc catalog
  weaponPool empty = full catalog; non-empty = allowlist
  weaponDropChance==0 → no drop (Dummy)

══════════════════════════════════════
PART C — PLAY MODE TOUCH / VERIFY
══════════════════════════════════════

When user presses Play (or if you can run a Command Bar snippet):

1) Ensure Rojo synced scripts are live.
2) In Command Bar (server), optional debug helpers — ONLY if safe:

   -- list catalog count
   local WC = require(game.ReplicatedStorage.Shared.Config.WeaponConfig)
   print("weapons", #WC.GetPublicCatalog())
   for _,w in WC.GetByLocation(1, true) do
     print(w.id, w.rarity, w.powerMult, w.dropDisabled)
   end

3) Kill Loc1 trash mobs / boss — expect Notify toast with drop name+rarity.
4) Dummy (DEBUG_Dummy) must NOT drop weapons.
5) If inventory UI exists (friend UI): open weapons window, equip main/offhand, see rarity colors.
6) Optional server debug: grant each rarity once for inspection:

   ONLY if a debug remote already exists; otherwise create TEMPORARY ServerScript under ServerScriptService.Debug ONLY for studio:
   "WeaponDebugGrant" — when player chats "/giveswords" (studio only, GameConfig.DEBUG):
     give one of each rarity from Loc1 into profile.weapons (not Limited auto-equip spam)
   Remove or gate behind DEBUG flag.

══════════════════════════════════════
PART D — REPORT BACK TO HUMAN
══════════════════════════════════════

After setup, reply in Russian with:
1) Path to museum: Workspace.DebugInspect.Weapons
2) Count of sword props spawned per loc
3) How to test drop in Play (3 steps)
4) Confirmation Limited parts are DropDisabled / no mob drop
5) Any scripts you created and whether they conflict with Rojo
6) Screenshot description of layout

PRIORITY ORDER
1) Museum props + billboards + click print (Edit, persistent)
2) Legend + drop posters
3) Play verify drops
4) Optional /giveswords debug gated by DEBUG
```

---

## Как пользоваться (ты)

1. `git pull` в репо  
2. Rojo → Connect to Studio (или sync place)  
3. Studio → Agent → вставь **PROMPT**  
4. После Agent: Edit — музей мечей; Play — бей мобов Loc1, смотри тосты дропа  
5. Не коммить Place-арт в git, если не договорились (музей можно оставить только в Place)

## Быстрый Command Bar (без Agent)

```lua
local WC = require(game.ReplicatedStorage.Shared.Config.WeaponConfig)
print("VERSION catalog", #WC.GetPublicCatalog())
for _, w in WC.GetByLocation(1, true) do
	print(w.id, w.rarity, ("×%.2f"):format(w.powerMult), w.dropDisabled and "NO_DROP" or "drop")
end
print("Loc1 boss secret EV ~35 kills @ luck0 — see docs/WEAPONS_LOOT.md")
```
