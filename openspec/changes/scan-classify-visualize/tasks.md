> TDD rule: every group sequences **tests first (RED) → implement (GREEN) → refactor**, running `swift test` after each implementation step. Pure-core groups (2–4) are unit-tested with synthetic data — no real filesystem. Shell groups (5–7) use a temp-dir sandbox or behavior checks. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` is required for `swift test` locally (see README).

## 1. Core data model

- [x] 1.1 RED: write tests for immutable `FileRecord` (path, isDirectory, isSymlink, logicalSize, allocatedSize, mtime) and the `SafetyTier` enum (`safe/cache/delegated/risky/never`) and `Classification` (tier + reason)
- [x] 1.2 GREEN: add the value types to `CleanupCore` (pure, no I/O); `swift test` green
- [x] 1.3 REFACTOR: tidy naming/equatability; confirm types are `Sendable`/value semantics

## 2. Safety classifier (the spine)

- [x] 2.1 RED: write the hard-blacklist tests first — `/System`, `/usr` (not `/usr/local`), `/bin`, `/sbin`, `/private/var/vm`, sealed volume → `never`; blacklist beats any other match; `..`/trailing-slash normalization cannot bypass; `/usr/local` is NOT never. Run `swift test`, confirm red
- [x] 2.2 GREEN: implement `classify(path) -> Classification` with the blacklist checked first and unconditionally; make blacklist tests pass
- [x] 2.3 RED: write ruleset tests for known locations from research.md (Trash/DerivedData→safe; Caches→cache; snapshots/Docker.raw/Homebrew→delegated; App Support/iOS backups/Downloads→risky) plus edge cases: unknown path → conservative (never `safe`); most-specific rule wins
- [x] 2.4 GREEN: implement the ordered ruleset (most-specific wins) + conservative default; make tests pass
- [x] 2.5 REFACTOR: extract the ruleset as legible data mirroring research.md; add an invariant test asserting no input yields a deletable tier for any blacklisted path; `swift test` green

## 3. Size roll-up tree

- [x] 3.1 RED: write tests for building a navigable tree from a stream/array of `FileRecord`s — parent size = sum of descendants' allocated sizes; hardlinked inode counted once; ranking children by size
- [x] 3.2 GREEN: implement the pure roll-up (records → tree) in `CleanupCore`; `swift test` green
- [x] 3.3 REFACTOR: ensure roll-up is incremental-friendly (can fold streamed records); tidy

## 4. Treemap layout (pure squarified)

- [x] 4.1 RED: write tests for `layout(nodes, rect) -> [PlacedRect]` — areas proportional to sizes; no overlaps; within bounds; single node fills bounds; zero-size nodes occupy no area and cause no divide-by-zero; tiny nodes aggregate into one "Other"
- [x] 4.2 GREEN: implement the squarified treemap algorithm + threshold aggregation + depth bound; `swift test` green
- [x] 4.3 REFACTOR: clean the geometry code; property-style assertions (sum of areas ≈ bounds area)

## 5. Filesystem scanner (imperative shell)

- [ ] 5.1 RED: write integration tests over a temp-dir fixture — nested files/folders enumerated with allocated+logical sizes; empty root reports zero; permission-denied/vanished entry skipped (not fatal); cancellation stops promptly
- [ ] 5.2 GREEN: implement the streaming, cancellable scanner (`FileManager.enumerator`, `AsyncStream<FileRecord>`); make tests pass
- [ ] 5.3 RED: write tests for scan-safety rules — symlinks not followed; symlink loop does not hang; hardlink counted once; descent into blacklisted subtree is pruned (no records emitted)
- [ ] 5.4 GREEN: implement no-follow-symlinks, `(device,inode)` dedupe, and blacklist pruning (consult the classifier); make tests pass
- [ ] 5.5 REFACTOR: extract resource-value reading (allocated size source) behind a small seam; measure on a large real dir, keep `FileManager` unless too slow (design open question)

## 6. Full Disk Access detection + onboarding

- [ ] 6.1 RED: write tests for FDA detection logic — readable probe → granted; permission error → not granted; non-existent/ambiguous probe → not granted (treat as ungranted). Inject the probe result so the unit test does no real I/O
- [ ] 6.2 GREEN: implement detection over injectable probe(s); `swift test` green
- [ ] 6.3 Implement onboarding UI: explanation + button deep-linking to `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles`
- [ ] 6.4 Implement graceful degradation: scan all FDA-free roots; represent unreadable protected regions as a distinct "needs Full Disk Access" node; never report hidden regions as empty/clean; rescan picks up a newly-granted permission
- [ ] 6.5 Manually verify the deep link opens the correct Settings pane and that degradation shows the placeholder (record result; GUI step)

## 7. Treemap UI + inspector (read-only)

- [ ] 7.1 Build the SwiftUI treemap view that renders `PlacedRect`s (Canvas/shapes) colored by tier, with a tier legend
- [ ] 7.2 Implement drill-in/drill-out navigation preserving parent context
- [ ] 7.3 Implement the inspector panel: selected node's path, allocated size, tier, and classification reason
- [ ] 7.4 Assert read-only: no delete/trash/clean affordance exists on any node, including `safe`-tier (UI review + checklist)
- [ ] 7.5 Wire the app shell: pick scan root(s) → run scanner → roll up → classify → layout → render; show scan progress + cancel

## 8. Integration & verification

- [ ] 8.1 End-to-end on a real user directory (e.g. `~/Library/Caches`): scan → classify → treemap renders, inspector shows correct tiers/reasons, no deletion controls present
- [ ] 8.2 Run full `swift build` + `swift test` from a clean `.build`; confirm green
- [ ] 8.3 Run `openspec validate scan-classify-visualize`; resolve issues
- [ ] 8.4 Confirm every scenario in the four specs maps to a task above; update README (M1 usage, FDA note) and roadmap
