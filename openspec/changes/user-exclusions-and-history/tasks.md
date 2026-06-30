> TDD rule: every group sequences **tests first (RED) → implement (GREEN) → refactor**, running `swift test` after each step. Exclusion membership, the planner change, and history records are pure (no I/O). The JSON store takes injected file read/write, so logic tests use an in-memory fake; one thin platform test touches a temp dir. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` is required for `swift test` locally.

## 1. Exclusion set (pure, ancestor-aware)

- [x] 1.1 RED: tests for `ExclusionSet` — add/remove/contains; ancestor-aware membership (a descendant of a member is excluded); unrelated path is not; adding a duplicate is idempotent
- [x] 1.2 GREEN: implement the pure ancestor-aware `ExclusionSet` in `CleanupCore` (reuse `PathNormalize`); `swift test` green
- [x] 1.3 REFACTOR: tidy; confirm value semantics + `Sendable`

## 2. Planner refuses user-excluded paths (MODIFIED behavior)

- [x] 2.1 RED: tests that `DeletionPlanner.plan(..., excluded:)` refuses a user-excluded path (and descendants) with a distinct "user-protected" reason; `NEVER` still refused with the system reason; an all-excluded selection → empty plan
- [x] 2.2 GREEN: thread an exclusion set into the planner; refuse matches before building items; `swift test` green
- [x] 2.3 RED: extend the safety invariant — for any selection and any exclusion set, no plan contains a `NEVER` item, AND exclusions never weaken `NEVER` protection
- [x] 2.4 GREEN/REFACTOR: ensure both invariants hold; keep the existing M2 planner tests green (default empty exclusion set preserves old behavior)

## 3. History records (pure)

- [x] 3.1 RED: tests for `HistoryEntry` (timestamp, kind, itemCount, reclaimedBytes, outcomeCounts) and an append+cap function — newest-first ordering; oldest dropped beyond the cap; timestamp is injected (core never reads the clock)
- [x] 3.2 GREEN: implement the record type + pure append/cap/sort in `CleanupCore`; `swift test` green
- [x] 3.3 REFACTOR: tidy; make entries `Codable` for persistence

## 4. Persistent store (platform layer, injectable I/O)

- [x] 4.1 RED: tests (in-memory fake read/write) for a `Store` over a codable `AppState` (exclusions + history) — save then load round-trips; a missing file loads defaults; an undecodable/corrupt payload loads defaults (no throw); a `version` field is present
- [x] 4.2 GREEN: implement the JSON `Store` with injected read/write; defaults-on-failure; `swift test` green
- [x] 4.3 RED: one platform test that the real file-backed store round-trips under a temp directory (and never targets the app's own container for deletion)
- [x] 4.4 GREEN: implement the real Application-Support file location (namespaced by bundle id); make the temp-dir test pass
- [x] 4.5 REFACTOR: extract the codable payload + version; confirm corrupt-file safety

## 5. UI integration (build-verified)

- [x] 5.1 Add a Protect / Unprotect affordance in the inspector (and an "excluded" badge on treemap tiles); wire it to the persisted exclusion set
- [x] 5.2 Feed the exclusion set into the deletion flow so protected paths are refused (shown in the plan's refused list with the user-protected reason)
- [x] 5.3 Append a history entry after each completed deletion and delegated cleanup
- [x] 5.4 Add a History panel (newest-first: date, kind, items, reclaimed) with a "Clear history" action
- [x] 5.5 Ensure the app never offers its own Application Support container for deletion (runtime protection)

## 6. Integration & verification

- [~] 6.1 Manual: protect a folder, confirm it is refused in a deletion plan with the user-protected reason and survives relaunch (GUI step; record result)
- [~] 6.2 Manual: perform a cleanup, confirm a history entry appears and persists across relaunch (GUI step; record result)
- [x] 6.3 Run full `swift build` + `swift test` from a clean `.build`; confirm green
- [x] 6.4 Run `openspec validate user-exclusions-and-history`; resolve issues
- [x] 6.5 Confirm every spec scenario maps to a task; update README (M4: personal protections + history) and roadmap
