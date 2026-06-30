## Why

Milestone 0 gave us a buildable, tested, CI/CD-backed shell with no behavior. Now the app needs to do its first real job: **show the user where their disk space went, and how safe each location is to reclaim** — without deleting anything yet. This is the "SEE THE BLOAT" milestone. It delivers the core value users currently pay closed-source cleaners for (a visual disk map) while establishing the safety-critical classifier that every future deletion will route through. Deletion itself is deliberately deferred to M2; M1 is strictly read-only so we can build and trust the scanner, classifier, and permission model before anything can be removed.

## What Changes

- Add a **recursive filesystem scanner** (imperative shell) that enumerates a directory tree and produces size-attributed records, streaming results so a multi-hundred-GB scan stays responsive and cancellable, and skipping (not crashing on) permission errors, symlinks, and unreadable nodes.
- Add the **5-tier safety classifier** (`SAFE` · `CACHE` · `DELEGATED` · `RISKY` · `NEVER`) and the **hard blacklist** as pure functions in `CleanupCore`, encoding the sourced rules from `research.md`. This is the safety spine: every path gets a tier, and `NEVER`/blacklisted paths can never be surfaced as cleanable.
- Add a pure **size roll-up** that aggregates file sizes into a navigable folder tree (allocated on-disk size, with logical size available), so folders can be ranked by reclaimable bytes.
- Add **Full Disk Access onboarding**: detect whether the app can read TCC-protected locations (Mail, Messages, `MobileSync` backups, Time Machine), guide the user to grant Full Disk Access (deep-link to the Settings pane), and **degrade gracefully** — scanning everything reachable and clearly marking what is hidden without the grant. (FDA cannot be requested programmatically.)
- Add a **treemap visualization** (SwiftUI) that renders the scanned tree as nested rectangles sized by bytes and colored by safety tier, navigable (drill in/out) with an inspector showing path, size, tier, and the *reason* for that tier. Read-only: selection and inspection only, no delete affordance yet.

Non-goals (explicit): no deletion, move-to-Trash, or "clean" action (M2); no delegated cleanup via `tmutil`/`docker`/`brew` (M3); no APFS snapshot reclamation; no code signing/notarization.

## Capabilities

### New Capabilities
- `filesystem-scanner`: streaming, cancellable recursive enumeration of a directory tree into size-attributed records, robust to permission errors, symlinks, and very large trees.
- `safety-classifier`: pure 5-tier classification of any path plus a hard, non-bypassable blacklist of SIP/system paths, grounded in the sourced research, with a human-readable reason per classification.
- `full-disk-access`: detection of Full Disk Access state, user onboarding/guidance to grant it, and graceful degradation when it is absent.
- `disk-usage-treemap`: a navigable treemap UI that renders the scanned tree sized by bytes and colored by safety tier, with a read-only inspector.

### Modified Capabilities
<!-- None. M1 adds new capabilities; the M0 project-structure/ci-pipeline/release-pipeline specs are unchanged. -->

## Impact

- **New `CleanupCore` modules**: classifier (rules + `classify`), blacklist, size roll-up tree, treemap layout algorithm (squarified) — all pure and unit-tested.
- **New app-shell code**: `FileManager`-based scanner, FDA detection/deep-link, SwiftUI treemap + inspector views.
- **Performance/UX**: streaming scan with progress + cancel; aggregation of tiny nodes to keep the treemap renderable on trees with millions of files.
- **Permissions**: introduces the Full Disk Access requirement and onboarding; app remains unsandboxed and unsigned.
- **Specs baseline**: four new capability specs added under `openspec/specs/` on archive.
- **Dependencies**: none new expected (Foundation `FileManager` + SwiftUI only); to be confirmed in design.
