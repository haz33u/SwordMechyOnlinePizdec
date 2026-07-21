# Progression walls + future events (design)

Status: **design** — not all wired. Parked world effects: `docs/ref/balance/captures/effects_parked/`.  
HUD boost pills exist; `profile.boosts` backend still TODO.

---

## 1. Location multipliers (feel “harder each world”)

**Not one formula for everything.** Three knobs stack:

| Knob | Role |
|------|------|
| **Mob HP / coins** (dump absolute) | Main “ouch” wall (Loc1 1K → Loc2 9M Sailor) |
| **combatWall** | Recommended TotalPower for ~2s T1 kills |
| **coinMult / powerMult** | Reward pace on that island |

### Target wall curve (F2P ~1–2 months → Loc25 ≈ Qdt)

Approximate **step mult vs previous loc** (combatWall ratio), not flat ×k forever:

| Loc | combatWall | ≈ step vs prev | UI scale |
|-----|------------|----------------|----------|
| 1 | 250 | — | 250 |
| 2 | 2e6 | **×8000** | 2M — huge first wall |
| 3 | 8e7 | ×40 | 80M |
| 4 | 2e9 | ×25 | 2B |
| 5 | 5e10 | ×25 | 50B |
| 6 | 1.2e12 | ×24 | 1.2T |
| 7 | 3e13 | ×25 | 30T |
| 8 | 8e14 | ×27 | 0.8Qa |
| 9 | 2e16 | ×25 | 20Qa |
| 10 | 5e17 | ×25 | 0.5Qi |
| 12 | 3e20 | ~×25/step | Sx band |
| 15 | 1e25 | | Sp band |
| **16** | **~3e26** | | **soft soft-cap for “no pets / no offhand”** |
| 18 | 5e30 | | No |
| 20 | 1e35 | | Dc |
| 22 | 5e40 | | Td |
| 24 | 2e45 | | Qd |
| 25 | 1e48 | | **Qdt** |

**After Loc4** simplified generator:

```
combatWall(n) ≈ 2e9 × 25^(n - 4)     -- tune 20…40 if too soft/hard
```

Loc1→2 stays a **special spike** (not 25×).

### What carries the wall

| System | Can break Loc15–16 alone? |
|--------|---------------------------|
| Weapons (main) | Partially |
| **Pets** | **Main late ×** — without them Loc15+ is intended pain |
| Offhand (50%) | Comfort / paid QoL |
| Aura + 2 relics (F2P) | Glue, not skip |
| 3rd relic (paid) | Comfort, not Loc20 free |
| Rebirth | Meta × |

**Design lock:**  
*Buy aura/relics + donate slots, but **no pet team and no offhand** → Loc15–16 should feel “very hard / soft wall”, not impossible forever, but slow enough that pets become the real unlock.*

---

## 2. Daily damage boss — not “too played” if we twist it

Classic “boss HP bar + damage race” is common. **Still good** for Sword Masters if:

1. **Not a second open-world** — short arena / sky island / void pad.  
2. Rewards scale on **your contribution %** (or damage tiers), not only kill.  
3. Loot is **systems we already need**: enchant dust/shards, potion stacks, chance sword, aura/relic key drip.  
4. **One personal entry** + optional **shared world boss** weekend later.

### Proposal: “Rift Herald” (daily)

| | |
|--|--|
| Spawn | 1× per player per day (UTC or server day) **or** global 24h window |
| HP | Scales to **your combatWall(currentLoc) × 80–200** so always a fight |
| Fail | Timer 3–5 min; no full wipe of progress — you keep **tier rewards** for damage dealt |
| Rewards | See table |

| Damage tier (of boss max HP) | Reward ideas |
|------------------------------|--------------|
| 5% | 1× common potion (power or coins 10 min) |
| 15% | Enchant dust / shards |
| 30% | Pet or aura key (small) |
| 50% | Loc-appropriate sword roll (low weight) |
| 75% | Rare potion / double dust |
| 100% kill | Bonus chest: dust + chance Secret weight bump for 1h |

**Why it fits us:** enchant economy + potions (new light system) + daily login loop without forcing Loc25.

Not stale if: **visual theme rotates weekly** (forest / sea / frost / void) and **one mechanic mutates** (reflect day, armor day, summon adds).

---

## 3. Anomalies (global / per-server events)

**Status: LIVE (Pool A + light Pool B).**  
Code: `AnomalyConfig` · `AnomalyService` · `Formulas.GetActiveAnomaly` · HUD banner.

**Cadence:**

```
Every 35 min (DEBUG: 3 min cycle, 60s active, first after 45s):
  roll 1 anomaly
  active 10 min (DEBUG 60s)
  quiet rest of cycle
```

Dev: `DebugCommand` action `forceAnomaly` (optional id string, 120s).

### Pool A — economy / farm (safe, frequent)

| Id | Name | Effect | Duration |
|----|------|--------|----------|
| AN_GOLD | Gold Tide | Coins **×1.3** (or ×1.5 rare) | 10m |
| AN_POWER | Power Surge | Player power **×1.15** | 8m |
| AN_SPAWN | Swarm | Mob respawn **−30%** CD | 10m |
| AN_LUCK | Lucky Edge | Weapon drop weight **×1.25** | 10m |
| AN_DUST | Dust Rain | Enchant dust on kill **+50%** | 10m |
| AN_KEY | Key Spark | Small chance pet/aura key on elite kill | 10m |

### Pool B — risk / spice (less frequent weights)

| Id | Name | Effect |
|----|------|--------|
| AN_BLOOD | Blood Moon | Power **×1.25**, mob HP **×1.3** |
| AN_BLAST | Solar Blast* | Power up + mob HP +30% + better drops + case cost +30% (*dump) |
| AN_ECLIPSE | Solar Eclipse* | Faster spawn; enchanted gear drops; level>1 rolls (*dump) |
| AN_DARK | Darkness* | Extra “dark” mobs; secret drop table open (*dump) |
| AN_BROKE | Miser’s Fog | Coins **×0.7**, weapon drop **×1.4** (tradeoff) |
| AN_GLASS | Glass Cannon | Damage **×1.4**, player “effective” vs elite only if CPS high (or −armor ignore) |

\* Already in `effects_parked` — wire as anomaly skins, not separate systems.

### Pool C — social / map (later)

| Id | Name | Effect |
|----|------|--------|
| AN_PORTAL | Rift Peek | Temporary portal to **event pocket** (mini farm, 5m) |
| AN_FERRY | Free Ferry | Travel cost **0** for 10m |
| AN_BOSSLET | Herald Echo | Mini world boss spawns on **current loc** for everyone |

**Rules:**

- Max **1** global anomaly active.  
- Announce: Notify + HUD pill + optional sky tint.  
- F2P and paid both benefit (no paywall on anomalies).  
- Do **not** make anomalies required to beat Loc walls — only speed/comfort/spice.

---

## 4. Other diversifiers (future menu)

Beyond anomalies + daily boss — pick 2–3 later, not all at once:

| Idea | Loop | Effort | Note |
|------|------|--------|------|
| **Potion belt** | Craft/buy short buffs (power/coins/luck 5–15m) | M | Ties to daily boss shards |
| **Weekly contract** | “Kill 5k LocN / deal X to Herald” | S | BP-adjacent |
| **Location modifier day** | “Today Loc2 coins ×2” rotating | S | Simpler than full anomaly |
| **Combo / streak** | Kill streak → temp mult, breaks on death/idle | M | Skill expression for clicker |
| **Tower of auras** | Floors for aura XP / exclusive aura | L | Dump “tower for auras” vibe |
| **Co-op crystal** | Party channel damage to shared objective | L | Optional social |
| **Mutator weekend** | 48h ruleset (no offhand allowed challenge for title) | S | Cosmetic pride |

**Recommended order to build:**

1. `profile.boosts` + Formulas hooks (foundation).  
2. Anomaly scheduler (Pool A only).  
3. Daily Rift Herald (damage tiers → dust/potions).  
4. Wire parked Eclipse/Darkness/Blast as weighted Pool B.  
5. Potions as inventory consumables.

---

## 5. Soft gate checklist (design acceptance)

| Checkpoint | Free: main sword + aura + 2 relics, **no pets, no offhand** | With pets + offhand |
|------------|--------------------------------------------------------------|---------------------|
| Loc2 entry | Hard but after R2 + farm OK | Comfortable |
| Loc10 | Slow T1, bosses long | Normal |
| Loc15–16 | **Soft wall** — possible, bad time | Clear path |
| Loc20+ | Effectively needs pets | Intended |
| Loc25 | Qdt club | Endgame |

Anomalies may **shave** wall time; they should **not** replace pets for Loc20+.

---

## 6. One-line product pitch

> *Worlds get brutally harder by design; pets and dual swords are the real late engine.  
> Anomalies and the daily Herald keep the mid-game feeling alive between island unlocks.*
