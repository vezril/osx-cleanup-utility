# osx-cleanup-utility

A **FOSS, macOS-native, safety-first disk cleanup utility**.

macOS "System Data" routinely balloons into hundreds of GB — caches, APFS local
snapshots, developer junk, old iOS backups, Docker images — and there is no
first-party way to inspect or reclaim it. Every existing GUI cleaner is
closed-source and/or paid. This project aims to be the open alternative: a
native SwiftUI app that **shows you what is taking up space** and lets you
**reclaim it safely**, with important system files protected as a hard,
non-negotiable rule.

> **Status: Milestone 0 (scaffold).** This is the foundation only — a buildable
> app, a test-first harness, and CI/CD. **There is no scanning or deletion
> behaviour yet.** See the roadmap below.

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
| `CleanupCore`   | pure library         | All decision logic (sizing, the safety classifier, deletion planning). No I/O, no UI — exhaustively unit-testable. |
| `OSXCleanupApp` | SwiftUI app (`osx-cleanup`) | Thin shell: UI + side effects (FileManager, later `tmutil`/`NSWorkspace`). Holds no decision logic. |

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
| **M0** ✅ | Scaffold: buildable app, TDD harness, CI/CD (this milestone)          |
| **M1**    | Read-only scanner + 5-tier safety classifier + treemap UI + Full Disk Access onboarding |
| **M2**    | Manual + curated-preset deletion (direct file/folder removal, "move to Trash" default) |
| **M3**    | Delegated cleanup: APFS snapshots (`tmutil`), Docker, Homebrew, npm/pip/cargo |
| **M4+**   | Scheduled scans, dry-run/undo, exclusions, signing + notarization, Homebrew cask |

## Development workflow

This project uses [OpenSpec](https://github.com/) for spec-driven development.
Change proposals, designs, specs, and task lists live under
`openspec/changes/`. The scaffold milestone is
[`openspec/changes/scaffold-project`](openspec/changes/scaffold-project).

## License

[MIT](LICENSE) © 2026 Calvin Ference
