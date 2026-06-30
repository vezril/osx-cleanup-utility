# osx-cleanup-utility

A **FOSS, macOS-native, safety-first disk cleanup utility**.

macOS "System Data" routinely balloons into hundreds of GB — caches, APFS local
snapshots, developer junk, old iOS backups, Docker images — and there is no
first-party way to inspect or reclaim it. Every existing GUI cleaner is
closed-source and/or paid. This project aims to be the open alternative: a
native SwiftUI app that **shows you what is taking up space** and lets you
**reclaim it safely**, with important system files protected as a hard,
non-negotiable rule.

> **Status: Milestone 4 (personal protections + history).** On top of scan (M1),
> safe deletion (M2), and delegated cleanup (M3), you can now mark **your own**
> paths as protected (they're refused by the deletion planner, just like system
> paths) and review a persisted **cleanup history** of everything you've
> reclaimed. See the roadmap below.

## Safety stance (non-negotiable)

Important system files **must never be touched.** The architecture is built
around a 5-tier safety classifier — `SAFE` · `CACHE` · `DELEGATED` · `RISKY` ·
`NEVER` — and a hard blacklist of SIP-protected paths (`/System`, `/usr`,
`/bin`, `/sbin`, `/private/var/vm`, the sealed system volume). The sourced
research that grounds these classifications lives in
[`openspec/changes/scaffold-project/research.md`](openspec/changes/scaffold-project/research.md).

## Requirements

- **macOS 14 (Sonoma) or later**
- **Xcode** installed (not just Command Line Tools). The Swift testing
  libraries ship with Xcode, so `swift test` needs Xcode's toolchain selected.

If `swift test` reports `no such module 'Testing'` / `'XCTest'`, your active
developer directory is pointed at the Command Line Tools. Point it at Xcode:

```bash
# Option A: select Xcode globally (persistent; requires sudo)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Option B: select it just for the current shell (no sudo)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Build & run the app

```bash
# Build everything (functional core + app shell)
swift build

# Run the app (Milestone 0: shows a placeholder window)
swift run osx-cleanup
```

A release build of the app bundle is produced by CI on tagged releases (see
below). Released artifacts are currently **unsigned**: on first launch,
right-click the app and choose **Open**, then confirm in the Gatekeeper dialog.

### Using it (Milestone 1)

1. Launch the app and click **Choose Folder…** (or the **Scan ~/Library/Caches**
   shortcut). A native picker grants the app access to that folder.
2. The folder is scanned and rendered as a **treemap**: each tile's area is its
   share of disk usage, and its color is its safety tier (green Safe · teal
   Cache · blue Delegated · orange Risky · red Never — see the legend).
3. **Single-click** a tile to inspect it (path, size, tier, and the reason for
   that tier). **Double-click** a directory tile to drill in; use **Up**/**Root**
   to navigate back out.
4. **Full Disk Access:** to also see protected areas (Mail, Messages, iOS
   backups), grant Full Disk Access when prompted — the app deep-links you to the
   right Settings pane. Without it, those areas are clearly marked as *hidden*,
   never reported as empty, and everything else still scans.

### Deleting safely (Milestone 2)

1. **Select** what to remove: ⌘-click tiles to mark several, use the **Mark for
   deletion** button in the inspector, or click a **preset** (Empty Trash, Xcode
   DerivedData, User Caches, Developer Caches) to bulk-select known-safe items.
2. Click **Review & Delete…** for a **dry-run preview**: exactly what will be
   removed, the per-tier breakdown, the reclaimable total, and any **refused**
   (protected) paths — nothing has happened yet.
3. Choose **Move to Trash** (default, reversible) or **Delete permanently**.
   Confirmation scales with risk:

   | Highest tier in selection | Confirmation required          |
   | ------------------------- | ------------------------------ |
   | Safe                      | a single click                 |
   | Cache                     | click + "will regenerate" note |
   | Risky / Delegated         | **type `DELETE`** to confirm   |
   | (Permanent mode)          | escalates one step further     |

4. After deletion you get a **result summary** (trashed / deleted / failed /
   refused) and the folder is rescanned automatically.

**Safety guarantees:** protected/system (`NEVER`) paths are excluded by the
planner *and* re-checked by the executor immediately before removal — they can
never be deleted. Trash-by-default means mistakes are recoverable via Finder's
**Put Back**. A locked or vanished file is reported but never aborts the batch.

### Delegated cleanup (Milestone 3)

Some of the biggest space hogs — **APFS local snapshots**, **Docker** images,
and **package-manager caches** (Homebrew, npm, yarn, pnpm, pip) — must NOT be
deleted as files: doing so corrupts the tool or is outright impossible
(snapshot blocks aren't on the filesystem). Instead, open **Delegated
Cleanup…** from the toolbar:

- **Snapshots** — lists APFS local snapshots (often the single biggest reclaim)
  and lets you delete one or **thin to free ~N GB**, all via `tmutil`.
- **Tools** — shows which of Homebrew/Docker/npm/yarn/pnpm/pip are installed
  (others show *not detected*). **Preview** runs a dry-run where supported
  (e.g. `brew cleanup --dry-run`); **Clean** runs the real command and reports
  its output.

**Safety:** every command is a **fixed, vetted argument vector** run directly
(never through a shell, never built from your input — no injection surface),
no `sudo` is ever used, and even snapshot dates parsed from `tmutil` are
validated before being passed back as arguments. Tools are found at known
install locations because a bundled app doesn't inherit your shell `PATH`.

### Personal protections & history (Milestone 4)

- **Protect your own paths** — in the inspector, click **Protect this path** to
  mark any folder/file off-limits. Protected paths get a 🔒 badge and are
  **refused by the deletion planner** with a "protected by you" reason, exactly
  like system paths. Protection is *monotonic*: it can only ever add safety —
  nothing here can expose a system (`NEVER`) path.
- **Cleanup history** — open **History** from the toolbar to see every past
  deletion and delegated run (newest first) with how much each reclaimed, plus
  the list of your protected paths. Clear it any time.

These persist across launches in a small JSON file under
`~/Library/Application Support/dev.vezril.osx-cleanup-utility/` — which the app
pointedly refuses to offer for deletion (it won't eat its own state).

## Run the tests

Tests use the **Swift Testing** framework and live in the pure functional-core
target, so they run anywhere without touching the real filesystem.

```bash
# Run the full test suite
swift test

# If swift test can't find the Testing module, select Xcode's toolchain first:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## Architecture

The project follows **Functional Core / Imperative Shell**:

| Target          | Kind                 | Responsibility                                                                 |
| --------------- | -------------------- | ------------------------------------------------------------------------------ |
| `CleanupCore`   | pure library         | All decision logic — sizing/roll-up, the safety classifier, squarified treemap layout. No I/O, no UI — exhaustively unit-tested. |
| `CleanupScan`   | platform library     | Foundation-backed I/O: the recursive `lstat` scanner and Full Disk Access detection. Integration-tested against temp dirs. |
| `OSXCleanupApp` | SwiftUI app (`osx-cleanup`) | Thin shell: treemap/inspector/onboarding views + side effects (`NSOpenPanel`, `NSWorkspace`). Holds no decision logic. |

The functional core imports no UI or filesystem framework, which keeps the
"never touch system files" guarantee testable in one place rather than scattered
through UI callbacks.

## Branching & releases

```
feature/*  ──PR──▶  development  ──PR──▶  main
                    (experimental CI)     (released, semver-tagged)
```

- `main` holds released versions; `development` holds experimental changes.
- **CI** (`.github/workflows/ci.yml`) builds and tests on every pull request and
  on pushes to `development`/`main`. A failing build or test fails the check.
- **Releases** (`.github/workflows/release.yml`) are cut by pushing a semantic
  version tag `vX.Y.Z` to a commit on `main`. The workflow builds the app,
  assembles an **unsigned** `.app`/`.zip`, and attaches it to a GitHub Release.
  No Apple Developer secrets are required. Code signing and notarization are
  planned for a later milestone.

Versioning follows [Semantic Versioning](https://semver.org/); commit messages
follow [Conventional Commits](https://www.conventionalcommits.org/)
(`feat:`, `fix:`, `feat!:` / `BREAKING CHANGE:`).

## Roadmap

| Milestone | Scope                                                                 |
| --------- | --------------------------------------------------------------------- |
| **M0** ✅ | Scaffold: buildable app, TDD harness, CI/CD                            |
| **M1** ✅ | Read-only scanner + 5-tier safety classifier + treemap UI + Full Disk Access onboarding |
| **M2** ✅ | Manual + curated-preset deletion (Mechanism A, "move to Trash" default, tiered confirmation) |
| **M3** ✅ | Delegated cleanup: APFS snapshots (`tmutil`), Docker, Homebrew, npm/yarn/pnpm/pip |
| **M4** ✅ | Personal protections (user exclusions) + persisted cleanup history (this milestone) |
| **M5+**   | Scheduled scans, signing + notarization, Homebrew cask distribution |

## Development workflow

This project uses [OpenSpec](https://github.com/) for spec-driven development.
Change proposals, designs, specs, and task lists live under
`openspec/changes/`. The scaffold milestone is
[`openspec/changes/scaffold-project`](openspec/changes/scaffold-project).

## License

[MIT](LICENSE) © 2026 Calvin Ference
