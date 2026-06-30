## Context

M3 reclaims the bloat that file deletion can't safely touch: APFS local snapshots, Docker images, and package-manager caches. The research reference classifies all of these `DELEGATED` — reclaimed by running the **owner tool's** cleanup command, not by `rm`. So M3 introduces a new shape to the app: instead of removing paths, it **runs vetted external commands**. That makes command execution the new risk surface, so the design centers on it being safe (no shell, no interpolation, hardcoded commands only), testable (injectable runner), and honest (detect tools, dry-run first, degrade gracefully).

It builds on the existing layering: pure registry/decision logic in `CleanupCore`, the `Process`/`tmutil` side effects in `CleanupScan`, SwiftUI in the app. The classifier's `DELEGATED` tier already identifies these locations; M3 gives them the correct action. The M2 file-deletion path is untouched and parallel.

## Goals / Non-Goals

**Goals:**
- A registry of delegated providers (Homebrew, Docker, npm, yarn, pnpm, pip), each a binary to detect + a fixed argument list.
- Detect which tools are installed (from known locations, since a GUI app has no shell `PATH`) and offer only those; degrade gracefully when absent.
- A safe command runner: argv-only, no shell, timeout, captured output/exit, injectable for tests.
- `tmutil`-based APFS local snapshot listing and reclamation (delete one / thin to a target).
- A dry-run/preview before any destructive command runs.

**Non-Goals:**
- `sudo`/root — only unprivileged commands (the snapshot + cache operations here need none).
- Raw deletion of delegated data (that remains the M2 path with strong confirmation).
- Scheduling/automation (M4+); signing/notarization.
- Tools without a safe built-in cache command (e.g. cargo) — out of scope for M3.

## Decisions

### D1: Only vetted commands, always as argument vectors — never a shell
Every command the app can run is hardcoded in the provider registry as a binary path plus an array of literal arguments. The runner uses `Process` with `arguments`, never `/bin/sh -c` and never a constructed command string. No user input is ever interpolated into a command.
**Why:** this removes shell-injection entirely — there is no shell, and the argument list is fixed at compile time. For a tool that runs external processes, this is the core safety property. 
**Alternative:** building command strings / allowing custom commands — rejected; reintroduces injection risk for no benefit.

### D2: The command runner is injectable
`CommandRunner` is a protocol/closure with a real `Process`-based implementation and a fake for tests. Provider logic and result handling are exercised against the fake (deterministic exit/stdout), so no real `brew`/`docker` is spawned in CI.
**Why:** hermetic, fast, deterministic tests of the decision/result logic. 
**Alternative:** shelling out in tests — rejected; slow, non-deterministic, environment-dependent.

### D3: Detect tools from known locations, not `PATH`
A GUI app launched by `launchd` does not inherit the user's shell `PATH`, so `which brew` from inside the app is unreliable. Detection checks a fixed set of known install locations per tool (e.g. `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`, `/usr/local/bin/docker`, npm/pnpm/pip standard paths) and uses the first that exists and is executable.
**Why:** correctness inside a real `.app`; avoids "tool installed but app can't find it." 
**Alternative:** rely on `PATH`/`which` — rejected; silently fails in the bundled app.

### D4: APFS snapshots via `tmutil` only
Snapshots are listed with `tmutil listlocalsnapshots /` (and dates via `tmutil listlocalsnapshotdates`), and reclaimed with `tmutil deletelocalsnapshots <date>` or `tmutil thinlocalsnapshots <mount> <bytes> <urgency>`. Snapshot dates parsed from `tmutil` output are validated against an expected format before being passed back as arguments.
**Why:** snapshot blocks are invisible to the filesystem and only `tmutil` can manage them safely; this is the single biggest real-world reclaim. Validating parsed dates keeps even tmutil's own output from becoming an injection vector. 
**Alternative:** touching snapshot storage directly — impossible/unsafe; rejected.

### D5: Dry-run / preview before running
Where a tool supports it, the panel shows a preview first: `brew cleanup --dry-run`, the snapshot list with dates, `docker system prune` reports reclaimable space in its summary. The destructive command runs only after the user confirms.
**Why:** delegated commands can remove a lot at once; users should see scope first. 
**Alternative:** run immediately — rejected; surprising and risky.

### D6: No privilege escalation
M3 runs only commands the user can run unprivileged. Local-snapshot `tmutil` operations and all the cache cleaners do not require root, so M3 never invokes `sudo` or a privileged helper.
**Why:** keeps the trust and security surface minimal for a FOSS tool; avoids a privileged helper in v1. 
**Trade-off:** anything genuinely requiring root is deferred (none of M3's actions do).

### D7: Timeout, captured output, and cancellation
Every run has a timeout; stdout/stderr and exit status are captured and surfaced. Long-running commands (Docker prune, large `brew cleanup`) can be cancelled (terminate the process). A non-zero exit is reported, never silently ignored.
**Why:** external commands can hang or fail; the app must stay responsive and honest. 
**Alternative:** unbounded synchronous runs — rejected; can freeze the UI.

## Risks / Trade-offs

- **A delegated command removes more than expected** → dry-run/preview first; per-provider description of what it does; results summary after.
- **Tool present but unsupported version / changed flags** → capture non-zero exit + stderr and surface it; never assume success.
- **GUI `PATH` gaps** → known-location detection (D3); if a tool truly isn't found, it's shown as "not detected," not silently broken.
- **`tmutil` output format drift** → parse defensively, validate snapshot-date format before reuse, and fail safe (offer nothing) if parsing is unexpected.
- **Command hangs** → timeout + cancel (D7).
- **Security** → no shell, argv-only, hardcoded commands, validated parsed arguments (D1, D4) — the injection surface is designed out, not mitigated.

## Migration Plan

Additive parallel flow on top of M1/M2; no data migration, no changes to the file-deletion path. Land on `development` behind CI; destructive actions are gated behind detection + dry-run + confirmation. Rollback = revert the change; M1/M2 remain intact.

## Open Questions

- Reclaimable-size estimation per provider: some tools report it (Docker), others don't (npm) — show an estimate only where reliable, else "unknown until run".
- Snapshot UX: list-and-delete-individually vs a single "thin to free X GB" slider — prototype both; `thinlocalsnapshots` is the bulk path.
- Whether to also surface "empty Trash" here or keep it in the M2 presets (leaning: keep in M2).
- Exact known-location lists per tool to encode in detection (Homebrew arm64 vs Intel prefixes, asdf/nvm-managed npm) — finalize during implementation.
