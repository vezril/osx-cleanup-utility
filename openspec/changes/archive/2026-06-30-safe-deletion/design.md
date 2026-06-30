## Context

M2 is the first milestone that *removes data*, so the whole design is about making deletion safe, reversible, and auditable. It builds directly on M1: the `SafetyClassifier` already gives every path a tier + reason, the scanner/`SizeTree` give sizes, and the treemap gives selection. M2 adds a pure deletion **planner** (the gate), a platform **executor** (Trash/permanent), and **curated presets**, plus the UI to drive them.

The non-negotiable rule — important system files must never be touched — is enforced here in two independent places: the planner refuses to include `NEVER`/blacklisted paths, and the executor **re-classifies every item again** immediately before removing it. Either layer alone would suffice; both together make an accidental protected-path deletion structurally impossible. Scope is **Mechanism A** (direct file/folder removal); delegated cleanup is M3.

## Goals / Non-Goals

**Goals:**
- A pure `DeletionPlan` that lists exactly what will be removed, totals reclaimable bytes per tier, excludes protected paths, and de-duplicates nested selections.
- A pure confirmation policy mapping a plan's highest tier to a required confirmation strength.
- Reversible-by-default execution (move to Trash), with permanent delete as an explicit opt-in.
- Execution that re-validates each item, tolerates per-item failure, and reports per-item results.
- Curated, classifier-backed safe presets plus manual multi-select.
- A dry-run preview shown before anything is deleted.

**Non-Goals:**
- Delegated cleanup / `tmutil` snapshots / pkg-manager prune (M3).
- Scheduling, exclusion lists, background cleaning (M4+).
- Permanent delete as a default or auto-selected option.
- Signing/notarization.

## Decisions

### D1: The `DeletionPlan` is a pure, mandatory gate
A selection never deletes directly. It is turned into a `DeletionPlan` (pure, in `CleanupCore`) which is the only thing the executor accepts. The plan carries, per item: path, tier, allocated size, and whether it will be trashed or permanently removed; plus aggregate totals and the required confirmation level.
**Why:** one pure, exhaustively-tested place where "what gets deleted" is decided makes the safety properties assertable in unit tests (e.g. "no plan ever contains a `NEVER` path"). 
**Alternative:** delete straight from UI selection — rejected; unauditable, and scatters safety checks.

### D2: Move-to-Trash by default; permanent delete is opt-in
Execution uses `FileManager.trashItem(at:resultingItemURL:)` by default, so every deletion is reversible via Finder's *Put Back*. Permanent removal (`removeItem`) is available only behind an explicit, separately-confirmed toggle.
**Why:** the cheapest possible "undo" for a destructive tool; dramatically lowers the cost of a mistake. 
**Trade-off:** Trash temporarily still occupies disk until emptied — documented in the UI; the app can surface "empty Trash" as a `SAFE` follow-up. 
**Alternative:** permanent delete by default — rejected as far too dangerous for v1.

### D3: Re-classify every item at execution time (defense in depth)
Immediately before removing an item, the executor calls `SafetyClassifier.classify` again and refuses (`refused`) anything that resolves to `NEVER`, regardless of what the plan said.
**Why:** the UI/plan could be stale or buggy; the executor must not trust its input for the one irreversible-in-spirit guarantee. 
**Alternative:** trust the plan — rejected; single point of failure for the core safety rule.

### D4: Confirmation strength is a pure function of the plan's highest tier
`requiredConfirmation(plan) -> ConfirmationLevel`: `SAFE` → `.simple`; `CACHE` → `.warning` (regeneration notice); `RISKY` → `.typeToConfirm`; a `NEVER` item can never appear, so it has no level. Permanent-delete mode escalates one step.
**Why:** friction scales with risk, deterministically and testably; the UI just renders the level. 
**Alternative:** fixed single confirmation — rejected; either too weak for risky data or too annoying for trivial caches.

### D5: De-duplicate nested selections in the plan
If a selected folder contains other selected items, the plan keeps only the ancestor (its subtree removal subsumes the descendants) and reports the reclaimable total without double-counting.
**Why:** correct byte accounting and avoids "delete child then parent" errors. 
**Alternative:** delete each selected path independently — rejected; double-counts sizes and risks confusing failures.

### D6: Execution tolerates partial failure and reports per item
The executor returns a result per item — `trashed` / `deleted` / `failed(reason)` / `refused(reason)` — and continues past failures rather than aborting the batch. The UI shows a summary and rescans.
**Why:** a single locked/vanished file must not strand the whole cleanup; users need to know exactly what happened. 
**Alternative:** all-or-nothing — rejected; brittle on real systems.

### D7: Tolerate races between scan and delete
Items may change between the M1 scan and the M2 delete. The executor re-stats each item; a vanished item is reported `failed(gone)` (non-fatal), and sizes are treated as best-effort estimates, not guarantees.
**Why:** the filesystem is live; the plan is a snapshot. 
**Alternative:** assume the scan is current — rejected; causes spurious hard failures.

## Risks / Trade-offs

- **User deletes something they needed** → Trash-by-default makes it recoverable; `RISKY` requires type-to-confirm; plan preview shows exactly what/how-much before acting.
- **Trash unavailable on some volume** → executor reports `failed`, never silently falls back to permanent delete; UI surfaces it.
- **Stale plan after a long gap** → re-stat at execution (D7); offer/encourage rescan; sizes shown as estimates.
- **Deleting a symlink vs its target** → remove the link only; the planner/executor operate on the path as-is and never follow links (consistent with the scanner).
- **Double-counting nested selections** → de-dup in the planner (D5).
- **Permanent-delete misuse** → opt-in toggle, escalated confirmation, distinct visual styling, and never remembered as a default.

## Migration Plan

Additive on top of M1; modifies the `disk-usage-treemap` capability (read-only → gated-deletion). No data migration. Land on `development` behind CI; the new behavior is destructive, so it ships gated behind the planner + confirmation from day one. Rollback = revert the change; M1 read-only visualizer remains intact.

## Open Questions

- Permanent-delete confirmation UX: type-to-confirm always, or a checkbox + escalated dialog — decide during UI build.
- Whether to offer "empty Trash" as an in-app `SAFE` action now or defer to M4 (leaning: surface it, since Trash-by-default makes it the natural next step).
- Folder deletion progress: a large subtree trash can be slow — show determinate progress vs spinner (prototype).
- Whether presets should be user-editable now or fixed in M2 (leaning fixed; editable exclusions are M4+).
