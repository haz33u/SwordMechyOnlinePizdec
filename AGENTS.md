# Agent rules (this repo) — permanent

## Before ANY work / every user request

1. **`git pull`** — sync teammate (friend) pushes; never edit a stale tree. Reconcile conflicts before overwriting.
2. **Read `docs/MASTER_PLAN.md`** — roadmap, shipped vs parked, next steps.
3. Only then plan and change code.

## After ANY work (default — forever)

4. **`git add` + `git commit` + `git push`** yourself so remote stays current.
   - Use a clear commit message (complete sentences).
   - Prefer: commit → `git pull --rebase` (or pull) if needed → `git push`.
   - **Do NOT wait for the user to ask for commit/push.**

### Exception (only when user says so)

Skip commit and/or push **only** if the user explicitly says e.g.:
- «не коммить»
- «не пушь»
- «don't commit»
- «don't push»
- «без пуша»

Until they say that, **always commit and push** finished work (including docs rule updates).

## Collaboration

- Friend may push anytime — **pull first** is non-negotiable.
- Do not force-push or rewrite published history without explicit approval.
- Prefer reviewable commits; ask before destructive git ops (`reset --hard`, force-push).

## Project docs

| Doc | Use |
|-----|-----|
| `docs/MASTER_PLAN.md` | Living roadmap — read every request |
| `docs/ref/cristalix/DUMP_CATALOG.md` | Loc1/Loc2 dump balance |
| `docs/COLLAB.md` | Git + Studio / Team Create |
