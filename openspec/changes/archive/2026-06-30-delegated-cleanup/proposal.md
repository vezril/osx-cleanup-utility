## Why

M1 sees the bloat and M2 deletes files, but the single largest contributors to a full disk — APFS local snapshots, Docker disk images, and package-manager caches — **cannot safely be reclaimed by deleting files**. Deleting `Docker.raw` destroys every container and volume; deleting snapshot blocks is impossible from the filesystem; `rm`-ing a Homebrew/npm cache corrupts the tool's index. The sourced research is explicit: these are `DELEGATED` — you reclaim them by running the **owner tool's own cleanup command**. M3 makes the app do exactly that: detect installed tools, show what each can reclaim, and run their vetted commands. This is also where the biggest real-world win lives — APFS local snapshots routinely pin tens of GB that nothing else can free.

## What Changes

- Add a **registry of delegated cleanup providers** — Homebrew (`brew cleanup`), Docker (`docker system prune`), npm/yarn/pnpm/pip cache cleaners — each defined by a binary to detect and a **fixed, vetted argument list**. The app detects which tools are installed (degrading gracefully when absent) and offers only those.
- Add a **safe command runner** in the platform layer that executes only these pre-defined commands as **argument arrays** (never shell strings, never interpolated user input — no injection surface), with a timeout, captured output, and exit status. It is injectable so the logic is testable without spawning real processes.
- Add **APFS local snapshot management** via `tmutil`: list local snapshots with their dates, and reclaim them (delete a specific snapshot, or thin to free a target amount). Snapshot blocks are never touched directly — only `tmutil` is used.
- Add a **dry-run / preview step** wherever the tool supports it (e.g. `brew cleanup --dry-run`, listing snapshots, `docker system prune` summary) so the user sees what will be reclaimed before anything runs.
- Extend the UI with a **Delegated Cleanup panel**: detected providers and their reclaimable estimates, the snapshot list, per-action run buttons with confirmation, and a result summary.

Non-goals (explicit): no `sudo`/privilege escalation — only commands the user can run unprivileged (the snapshot and cache operations covered here do not require root); no raw deletion of delegated data (M2 already allows that path with strong confirmation, but M3 provides the *correct* path); no scheduling/automation (M4+); no code signing/notarization. Cargo/other tools without a safe built-in cache command are out of scope for M3.

## Capabilities

### New Capabilities
- `delegated-cleanup`: a registry of known delegated providers (binary + vetted argument list + category), with installed-tool detection and graceful degradation, plus a model for a delegated action and its result.
- `command-execution`: a safe, injectable runner that executes only pre-defined commands as argument vectors — no shell, no interpolation — with timeout, captured stdout/stderr, and exit status.
- `snapshot-management`: `tmutil`-based listing and reclamation of APFS local snapshots (delete a specific snapshot or thin to a target amount), never touching snapshot blocks directly.

### Modified Capabilities
<!-- None. M3 adds a parallel delegated-cleanup flow; the M2 file-deletion path is unchanged. -->

## Impact

- **New `CleanupCore` code**: the delegated-provider registry and action/result model, and snapshot-parsing helpers — pure, with detection and execution injected, so the decision logic is unit-tested.
- **New `CleanupScan` (platform) code**: the `Process`-based command runner (argv-only) and the `tmutil` wrapper for snapshots.
- **App-shell changes**: a Delegated Cleanup panel — provider list with reclaimable estimates, snapshot list, dry-run previews, run buttons with confirmation, and a results summary.
- **Security posture**: only hardcoded commands are ever executed, always as argument arrays; no user input reaches a shell; tool paths are resolved from known locations (a GUI app does not inherit a shell `PATH`).
- **Specs**: three new capability specs; baseline updated on archive.
- **Dependencies**: none new (Foundation `Process` + `tmutil`/tool binaries already on the system).
