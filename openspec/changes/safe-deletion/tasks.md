> TDD rule: every group sequences **tests first (RED) → implement (GREEN) → refactor**, running `swift test` after each implementation step. Pure-core groups (1–2) are unit-tested with synthetic data — no real filesystem. Executor (group 3) uses a temp-dir sandbox and deletes only inside it. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` is required for `swift test` locally.

## 1. Deletion plan model + planner (pure gate)

- [ ] 1.1 RED: tests for `DeletionItem` (path, tier, allocatedSize, mode) and `DeletionPlan` (items, refused[], reclaimableTotal, perTierTotals); a `DeletionMode` of `.trash`/`.permanent`
- [ ] 1.2 GREEN: add the value types to `CleanupCore`; `swift test` green
- [ ] 1.3 RED: tests for `plan(selection:sizes:mode:)` — lists removable items with tier+size; totals reclaimable bytes; **excludes NEVER/blacklisted into `refused` with reason**; empty/all-refused → empty plan (no-op)
- [ ] 1.4 GREEN: implement the pure planner (consults `SafetyClassifier`); make tests pass
- [ ] 1.5 RED: tests for nested-selection de-duplication — a selected ancestor subsumes selected descendants; reclaimable counted once
- [ ] 1.6 GREEN: implement de-duplication; make tests pass
- [ ] 1.7 REFACTOR: tidy; add an invariant test asserting no plan ever contains a `NEVER` item for any selection

## 2. Confirmation policy (pure)

- [ ] 2.1 RED: tests for `requiredConfirmation(plan) -> ConfirmationLevel` — safe→`.simple`; cache→`.warning`; risky→`.typeToConfirm`; highest tier wins on mixed plans; empty plan → no confirmation/no-op
- [ ] 2.2 GREEN: implement the pure policy; `swift test` green
- [ ] 2.3 RED: tests that permanent mode escalates the level by one step vs trash mode
- [ ] 2.4 GREEN: implement escalation; make tests pass
- [ ] 2.5 REFACTOR: tidy level enum + ordering

## 3. Deletion executor (platform layer)

- [ ] 3.1 RED: temp-dir integration tests — `.trash` mode moves items to Trash and reports `trashed` (recoverable); items still removed from original location
- [ ] 3.2 GREEN: implement executor using `FileManager.trashItem(at:resultingItemURL:)`; make tests pass
- [ ] 3.3 RED: tests for permanent mode (`removeItem`) only when explicitly requested; Trash failure reported as `failed`, never silently permanent
- [ ] 3.4 GREEN: implement permanent mode + no-silent-fallback; make tests pass
- [ ] 3.5 RED: tests for re-validation + partial failure — item re-classifying as `NEVER` is `refused`; vanished item is `failed(gone)` and batch continues; a per-item result exists for every item
- [ ] 3.6 GREEN: implement re-classification, per-item results, partial-failure tolerance; make tests pass
- [ ] 3.7 REFACTOR: extract result types; ensure executor never deletes outside the plan

## 4. Safe presets (pure definitions + resolution)

- [ ] 4.1 RED: tests that each curated preset resolves only to `SAFE`/`CACHE` paths (never RISKY/DELEGATED/NEVER); absent paths are skipped
- [ ] 4.2 GREEN: implement preset definitions + resolution against the classifier and the filesystem (existence check); make tests pass
- [ ] 4.3 REFACTOR: keep preset definitions as legible data

## 5. Deletion UI (build-verified)

- [ ] 5.1 Add multi-selection to the treemap/inspector (select multiple tiles; show running selected count + reclaimable total)
- [ ] 5.2 Add a curated-presets bar (one-click safe selections) wired to the resolver
- [ ] 5.3 Build the plan-preview sheet: removable items, per-tier breakdown, reclaimable total, refused items with reasons; Trash vs Permanent toggle
- [ ] 5.4 Build the tiered confirmation flow: simple / warning / type-to-confirm per `requiredConfirmation`; escalate for permanent
- [ ] 5.5 Wire execution + post-deletion result summary (trashed/deleted/failed/refused counts) and trigger a rescan
- [ ] 5.6 Assert NEVER-tier nodes expose no delete affordance (UI review + checklist)

## 6. Integration & verification

- [ ] 6.1 End-to-end on a disposable temp folder: select → preview → confirm → items move to Trash → rescan reflects the change (no real user data touched)
- [ ] 6.2 Run full `swift build` + `swift test` from a clean `.build`; confirm green
- [ ] 6.3 Run `openspec validate safe-deletion`; resolve issues
- [ ] 6.4 Confirm every scenario in the specs maps to a task; update README (M2 usage, Trash-default + permanent opt-in, confirmation tiers) and roadmap
