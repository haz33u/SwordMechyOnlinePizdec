# Prompt: diagnose why mobs still spawn underground

**Status:** unresolved after two fix attempts. Do **not** apply a third blind fix.
Measure first, then patch.

---

## The bug

Mobs in Loc1 spawn sunk into the terrain:

- Goblins / Dark Goblins stand buried up to the waist or thighs.
- At least one mob is almost fully buried — only its face (eyes + mouth parts)
  is visible lying flat on the grass.
- Affects both `MobTemplates` rigs and procedurally built mobs.

## What was already tried (and did NOT fix it)

1. **Marker exclusion** — spawn markers are real parts at the spawn point, so a
   downward raycast could hit the marker's own top face and report it as
   "ground". Markers are now excluded via `collectMarkerFolders()` **and** set to
   `CanQuery = false` in `MobSpawnMarkerService.Collect` (line ~100).
   → Did not fix it.

2. **Rotated-part half-extents** (commit `f8999ba`) — the feet calculation used
   `p.Position.Y - p.Size.Y/2`, which is only correct for axis-aligned parts.
   Replaced with a projection of the part's half-extents onto the world Y axis.
   → Did not fix it.

Both were real bugs worth fixing, but neither was the dominant cause. Something
else is driving the sink.

## Where the code lives

- `src/ServerScriptService/Services/MobVisualService.lua`
  - `snapModelToGround(model, targetPos)` — line ~492. The whole grounding math.
  - `GROUND_SKIN = 0.05` — line 19.
  - `buildPlaceholder` — line ~555, calls `snapModelToGround` at line ~564.
  - `MobVisualService.Spawn` — line ~597, sets `model.Parent` at line ~612.
  - `MobVisualService.SetAlive` — line ~677, respawn path, uses the cached
    `GroundedY` attribute.
  - `freezeStudioModel` — line ~458, anchors parts and kills the Humanoid state machine.
- `src/ServerScriptService/Services/MobSpawnMarkerService.lua`
  - `Collect(locationId)` — line ~87, marker positions are the spawn input.
- `src/ServerScriptService/Services/CombatService.lua`
  - `SpawnMob` — line 103; bulk spawn loop at line ~485.

## Prime suspects — verify each with real numbers

1. **Grounding runs before the model is in the Workspace.**
   `buildPlaceholder` calls `snapModelToGround` (line ~564) while the model is
   still parented to `nil` — `model.Parent` is only assigned later, in `Spawn`
   (line ~612). Confirm whether `GetBoundingBox()` / `GetPivot()` return what the
   math assumes at that moment, and whether the raycast is even meaningful yet.

2. **`Humanoid.HipHeight` on R6 rigs.**
   `MobTemplates` mobs are R6 rigs with a live Humanoid. A rig's `HumanoidRootPart`
   normally floats `HipHeight` studs above the feet. `freezeStudioModel` disables
   the state machine and anchors everything, but the grounding math never accounts
   for `HipHeight` — check whether the sink distance equals it.

3. **`GetBoundingBox()` includes non-body parts.**
   The feet scan skips parts named spear/sword/weapon/tool/handle, but
   `footOffset` falls back to `bboxSize.Y / 2` (line ~544), and the bounding box
   still includes HP-bar attachments, ClickDetector hosts, auras, capes, and any
   `BillboardGui` host part. Verify the fallback is not the branch actually being
   taken.

4. **The raycast hits the wrong surface.**
   `groundY` falls back to `targetPos.Y` when nothing is hit (line ~521). If the
   world floor is **Terrain** rather than parts, confirm the ray reaches it and
   that no excluded-by-name object (`tree`/`decor`/`fence`/`prop`, line ~510)
   is swallowing the actual floor.

5. **Something moves the mob after grounding.**
   `SetAlive` re-pivots from the cached `GroundedY` attribute. Confirm the sink is
   present at spawn, or only appears after the first death/respawn cycle — these
   point at different culprits.

## Required: measure before patching

Studio MCP was down when this was written, so no live numbers exist. Reconnect
Studio and run a probe that reports, **for 3–4 real mobs in `Workspace.Mobs`**:

- `model.Name`, `model.PrimaryPart.Name`
- `model:GetPivot().Position.Y`
- `model:GetBoundingBox()` → CFrame.Y and Size.Y
- the true lowest `BasePart` point (half-extents projected onto world Y)
- a downward raycast from `pivot + Vector3.new(0, 30, 0)`, reporting the hit
  `Instance:GetFullName()`, hit `Position.Y`, and whether it hit `Terrain`
- `Humanoid.HipHeight` and `Humanoid.RigType` if a Humanoid exists
- the `GroundedY` attribute
- **`sinkDepth` = hitY − lowestBodyPoint** ← the number that matters

Then compare `sinkDepth` against `HipHeight` and against `bboxSize.Y/2`. Whichever
it matches identifies the cause. Also confirm whether the marker Y and the actual
floor Y differ, and whether the buried "face-only" mob is a different mob type or
uses a different model source (`tryStudioModel` containers, line ~194–207).

## Constraints

- `--!strict` Luau. Rojo does **not** validate syntax — parse-check every edited
  file with `npx @johnnymorganz/stylua-bin@latest --check <file>` (formatting
  diffs are fine; only real parse errors matter).
- Do not delete or move anything in `Workspace` without explicit approval.
- Do not apply `stash@{0}` — it is stale (39 files, predates current code) and
  conflicts.
- Fix the root cause once it is measured. State plainly if a previous fix was
  wrong.
