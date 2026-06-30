## Context

M1 turns the M0 scaffold into a working read-only disk visualizer. It builds on the established Functional Core / Imperative Shell split: pure decision logic in `CleanupCore` (classifier, blacklist, size roll-up, treemap layout), side effects in the app shell (`FileManager` enumeration, Full Disk Access detection, SwiftUI rendering). The sourced facts that drive classification live in [research.md](../scaffold-project/research.md) (or its archived copy) — the classifier is essentially that research table encoded as a pure ruleset.

Hard constraints carried forward: important system files must never be touched (M1 enforces this by never *surfacing* `NEVER`/blacklisted paths as cleanable); TDD is mandatory (the pure core is the bulk of the tests); FP favored; app stays unsandboxed + unsigned. M1 is strictly **read-only** — no code path deletes anything.

## Goals / Non-Goals

**Goals:**
- Enumerate a directory tree into size-attributed records, streaming and cancellable, robust to permission errors / symlinks / huge trees.
- Classify every path into one of 5 tiers with a human-readable reason; make `NEVER`/blacklist non-bypassable and exhaustively tested.
- Roll sizes up into a navigable folder tree rankable by reclaimable bytes.
- Detect Full Disk Access, guide the user to grant it, and degrade gracefully without it.
- Render a navigable treemap colored by tier with a read-only inspector.

**Non-Goals:**
- Any deletion / move-to-Trash / "clean" action (M2).
- Delegated cleanup (`tmutil`/`docker`/`brew`/pkg-managers) and APFS snapshot reclamation (M3).
- Reporting APFS *purgeable* space or snapshot internals (not visible to a file scanner).
- Signing/notarization, sandboxing, Mac App Store.

## Decisions

### D1: Scanner streams `FileRecord`s; the core never does I/O
The shell's scanner walks the tree with `FileManager.enumerator` (or low-level `fts`/`readdir` if needed for speed) and emits immutable `FileRecord` values (path, logical size, allocated size, isDirectory, isSymlink, mtime) over an `AsyncStream`. The core consumes these to build the size tree and classify. 
**Why:** keeps the core pure and testable with synthetic records (no real files in unit tests), and keeps the UI responsive — results stream in and the scan is cancellable. 
**Alternative:** synchronous full-walk returning an array — rejected; freezes the UI and can't cancel on a 200 GB volume.

### D2: Report allocated (on-disk) size as primary, keep logical size
Each record carries both **allocated size** (`st_blocks × 512`, the actual disk footprint) and **logical size** (`st_size`). The treemap and rankings use allocated size, since that is what reclaiming actually frees. 
**Why:** logical size overstates sparse files and understates block rounding; users care about reclaimable bytes. 
**Caveat (documented):** APFS clones can share blocks, so summed allocated size may exceed real unique usage; M1 does not deduplicate clones (notes this in the inspector). Hardlinks are counted once per inode within a scan (see D6). 
**Alternative:** logical size only — rejected as misleading for reclamation.

### D3: The classifier is data + a pure function
`classify(path) -> Classification` where `Classification = (tier, reason)`. Internally it matches a path against an ordered **ruleset** (longest/most-specific prefix or glob wins) derived from `research.md`, with the **hard blacklist checked first and unconditionally** (`/System`, `/usr` except `/usr/local`, `/bin`, `/sbin`, `/private/var/vm`, the sealed system volume). Unknown paths default to the most conservative sensible tier (`RISKY` for user data, never `SAFE`). 
**Why:** one pure, exhaustively-tested function is auditable — we can assert in tests that no input ever yields a deletable tier for a protected path. Encoding rules as data keeps the research↔code mapping legible. 
**Alternative:** scattering tier logic across scanner/UI — rejected; unauditable and unsafe.

### D4: Full Disk Access detected by probe, never requested programmatically
Detect FDA by attempting a lightweight read of a known TCC-protected path (e.g. `~/Library/Application Support/MobileSync` or the Mail container) and catching the permission error. If absent, show onboarding that explains why, deep-links to `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles`, and the scan **degrades gracefully**: it scans everything reachable and marks protected, unreadable regions distinctly (e.g. a "needs Full Disk Access" placeholder node) rather than silently omitting them. 
**Why:** macOS forbids requesting FDA via API; the only honest path is guide + degrade. 
**Alternative:** demanding FDA before any scan — rejected; the biggest easy wins (caches, DerivedData, Trash, pkg caches) need no FDA, so we must deliver value without it.

### D5: Treemap layout is a pure, testable function; SwiftUI only renders
A **squarified treemap** algorithm in `CleanupCore` maps `(node sizes, rect) -> [placed rects]`; SwiftUI draws the returned rectangles (Canvas/shapes) colored by tier and handles hit-testing/drill-in. To stay renderable on trees with millions of nodes, the layout **aggregates** children below a pixel/byte threshold into a synthetic "Other (N items)" node and bounds drill depth. 
**Why:** the gnarly geometry becomes unit-testable (assert areas ∝ sizes, no overlaps, stable ordering); the view stays thin. 
**Alternative:** computing layout inside the view body — rejected; untestable and conflates layout with rendering.

### D6: Scan safety rules — don't follow symlinks, count inodes once, never cross into blacklisted trees
The walker does **not** follow symlinks (prevents cycles and double-counting), tracks seen `(device, inode)` to count hardlinked files once, and **prunes** descent into hard-blacklisted/`NEVER` subtrees entirely (they are never enumerated, sized, or shown as cleanable). Permission-denied and vanished nodes are recorded as skipped, not fatal. 
**Why:** correctness on real macOS volumes and a structural guarantee that protected trees are never even traversed. 
**Alternative:** follow symlinks / best-effort — rejected; causes cycles, inflated sizes, and risks surfacing protected content.

## Risks / Trade-offs

- **Very large volumes scan slowly** → stream + show progress + cancel; do classification lazily on visible nodes; aggregate tiny nodes.
- **APFS clones/snapshots make "size" ambiguous** (summed allocated > unique) → document in inspector; do not claim exact reclaimable totals; snapshots handled in M3 via `tmutil`.
- **Classifier false-confidence** (marking something `SAFE` that holds user data) → conservative default (`RISKY`), reason shown for every tier, and `~/Library/Application Support` treated as `RISKY` per-subfolder rather than blanket-`SAFE`.
- **FDA probe false negative/positive** across macOS versions → probe more than one protected path; treat ambiguous results as "not granted" and degrade.
- **Treemap unreadable with millions of nodes** → byte/pixel-threshold aggregation + depth bound; verify on a synthetic deep tree.
- **GUI launch/packaging without Xcode locally** (from M0) → core + algorithms are testable headless; UI verified via build + manual run / CI bundle.

## Migration Plan

Additive feature milestone on a greenfield app — no data migration. Land on `development` behind normal CI; the read-only nature means no destructive risk. Rollback = revert the change; M0 scaffold remains functional. Ship as part of the next `0.x` release once the treemap renders a real scan.

## Open Questions

- Enumeration backend: `FileManager.enumerator` (simple, Foundation-only) vs `fts(3)`/`readdir` (faster, more code) — start with `FileManager`, measure, optimize only if needed.
- Exact allocated-size source: `URLResourceValues.totalFileAllocatedSize` vs `stat.st_blocks` — pick the most reliable on APFS during implementation.
- Treemap interaction model: drill-in via zoom vs breadcrumb navigation — prototype both, choose by feel.
- Which concrete probe path(s) most reliably indicate FDA across macOS 14/15/26 — verify empirically.
- Minimum set of scan roots for the first cut (likely `~/Library/Caches`, `~/Library/Developer`, `~/Library/Application Support`, `~/Downloads`, `~/.Trash`, pkg-manager caches) — finalize in tasks.
