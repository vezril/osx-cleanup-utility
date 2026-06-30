## Why

M0–M3 made a working cleaner: scan, classify, delete (Trash-default), and delegated cleanup. But for *repeat, real-world* use two things are missing. First, the safety blacklist is hardcoded to system paths — a user has no way to mark **their own** important folders as off-limits (e.g. a project, a local-only archive, a working dataset under `~/Library/Application Support`). Second, after deleting things there is **no record** of what happened — no audit trail to answer "what did I clean last week, and how much did it free?" Both are about trust over time. M4 adds **user-managed exclusions** (personal protections that augment the built-in blacklist) and a **cleanup history** (a persisted audit log), with a small persistent store underneath.

## What Changes

- Add **user exclusions**: the user can mark any path as personally protected. Excluded paths are treated like the `NEVER` tier for *actions* — they are never offered for deletion and are refused by the planner — without changing the path's underlying classification/explanation. Exclusions are **persisted** across launches.
- Make the **deletion planner consult the user exclusion set** in addition to the hardcoded blacklist: a user-excluded path is refused (with a reason naming it as user-protected), exactly as a `NEVER` path is. This is a behavior change to the planner, so its spec is updated.
- Add a **cleanup history**: every completed deletion/delegated cleanup appends a timestamped record (what, how many items, bytes reclaimed, trash vs permanent vs delegated, outcome counts). History is **persisted** and viewable in-app, newest first.
- Add a small **persistent store** in the platform layer (JSON under the app's Application Support container) for exclusions and history, with reads/writes injectable so the decision logic stays pure and unit-tested.
- Extend the UI: a "Protect this path" / "Unprotect" affordance and an exclusions list; a History panel showing past cleanups with their reclaimed totals.

Non-goals (explicit): no editing of the hardcoded system blacklist (it remains absolute and separate); no scheduled/automatic cleaning (a later milestone); no cloud sync; no code signing/notarization. Exclusions augment protection — they can only *add* safety, never remove a `NEVER` protection.

## Capabilities

### New Capabilities
- `user-exclusions`: a persisted set of user-protected paths that augments the hardcoded blacklist, with pure membership logic (a path is excluded if it or an ancestor is in the set) and add/remove operations.
- `cleanup-history`: a persisted, append-only, timestamped log of completed cleanups (file deletions and delegated runs) with reclaimed totals and outcome counts, presented newest-first.

### Modified Capabilities
- `deletion-planning`: the planner additionally refuses any path that is user-excluded (treating it like `NEVER` for actions), recording it as refused with a "user-protected" reason. The requirement is updated to reflect that refusal now covers both the hardcoded blacklist and the user exclusion set.

## Impact

- **New `CleanupCore` code**: pure exclusion-set membership (ancestor-aware) and the history record model — unit-tested with injected state.
- **Modified `CleanupCore`**: the deletion planner gains an injected exclusion check; the existing `NEVER`-refusal invariant is preserved and a new "user-excluded ⇒ refused" property is added.
- **New `CleanupScan` (platform) code**: a small JSON persistence store under Application Support, with file read/write injectable for hermetic tests.
- **App-shell changes**: protect/unprotect affordances + an exclusions list; a History panel.
- **Safety posture**: exclusions can only increase protection; the hardcoded blacklist and the executor's independent `NEVER` re-check are unchanged, so the core guarantee is untouched.
- **Specs**: two new capability specs + a delta to `deletion-planning`; baseline updated on archive.
- **Dependencies**: none new (Foundation `FileManager`/`JSONEncoder`).
