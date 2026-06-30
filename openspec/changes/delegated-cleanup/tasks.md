> TDD rule: every group sequences **tests first (RED) → implement (GREEN) → refactor**, running `swift test` after each step. The provider registry, output parsing, and date validation are pure (no I/O). The command runner and tmutil wrapper take an **injectable** executor, so tests never spawn real `brew`/`docker`/`tmutil`. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` is required for `swift test` locally.

## 1. Provider registry + action model (pure)

- [x] 1.1 RED: tests for `DelegatedProvider` (id, binary, category, description, knownLocations, cleanupArgs, dryRunArgs?) and a `DelegatedResult` (provider, outcome, output); assert the built-in registry is non-empty
- [x] 1.2 GREEN: add the value types + the built-in provider registry (Homebrew, Docker, npm, yarn, pnpm, pip) to `CleanupCore`; `swift test` green
- [x] 1.3 RED: tests that every provider's cleanup/dry-run commands are literal argument vectors (no shell metacharacters interpreted) and that dry-run args ≠ cleanup args where present
- [x] 1.4 GREEN: encode commands as literal `[String]` arg vectors; make tests pass
- [x] 1.5 REFACTOR: keep the registry as legible data mirroring the research reference

## 2. Tool detection (pure logic, injected existence)

- [x] 2.1 RED: tests for `detect(provider, exists:)` — found when a known location holds an executable; not detected when absent; resolves from known locations (not PATH). Inject the existence/executability predicate so the test does no real I/O
- [x] 2.2 GREEN: implement detection over the provider's `knownLocations` using the injected predicate; `swift test` green
- [x] 2.3 REFACTOR: tidy; encode known locations (arm64 `/opt/homebrew`, Intel `/usr/local`, etc.) as data

## 3. Safe command runner (platform layer, injectable)

- [x] 3.1 RED: tests (with a fake executor) that the runner returns captured stdout/stderr/exit; a non-zero exit is reported as failure; arguments with shell metacharacters are passed through literally (the fake records argv, proving no shell/interpolation)
- [x] 3.2 GREEN: implement `CommandRunner` over an injectable executor; real impl uses `Process` with `arguments` (never `/bin/sh -c`); make tests pass
- [x] 3.3 RED: tests for timeout → reported timed-out; cancellation → reported cancelled (via the fake executor)
- [x] 3.4 GREEN: implement timeout + cancellation (terminate process); make tests pass
- [x] 3.5 REFACTOR: extract result types; assert the runner only ever launches a binary + argv

## 4. Snapshot management (tmutil, injectable)

- [x] 4.1 RED: tests for parsing `tmutil` snapshot-list output — lists dated snapshots on well-formed output; empty output → empty list; unparseable output → empty (fail safe), no crash
- [x] 4.2 GREEN: implement the pure `tmutil` output parser; `swift test` green
- [x] 4.3 RED: tests for snapshot-date validation — a well-formed date is accepted; a malformed/injected value is rejected and never used as an argument
- [x] 4.4 GREEN: implement date-format validation gating any `tmutil` delete/thin argument; make tests pass
- [x] 4.5 RED: tests (fake runner) that delete-by-date and thin-to-target invoke `tmutil` with the validated argv only
- [x] 4.6 GREEN: implement delete/thin over the injectable runner; make tests pass
- [x] 4.7 REFACTOR: tidy; ensure snapshot storage is never touched directly

## 5. Delegated cleanup UI (build-verified)

- [ ] 5.1 Build a Delegated Cleanup panel listing detected providers (with category/description) and a "not detected" state for absent ones
- [ ] 5.2 Add the snapshot list (dates, count) with per-snapshot delete and a "thin to free…" control
- [ ] 5.3 Wire dry-run/preview where supported (brew --dry-run, snapshot list, docker prune summary) shown before the destructive run
- [ ] 5.4 Wire run actions with confirmation, a running/cancel state, and a per-action result summary (output + exit)
- [ ] 5.5 Graceful degradation review: absent tools show "not detected"; nothing claims success on a non-zero exit

## 6. Integration & verification

- [ ] 6.1 Manual: on a machine with Homebrew/Docker, run a dry-run then a real cleanup; confirm output + reclaimed space are reported (GUI step; record result)
- [ ] 6.2 Manual: list real APFS local snapshots via `tmutil` and delete/thin one on a disposable snapshot (GUI step; record result)
- [ ] 6.3 Run full `swift build` + `swift test` from a clean `.build`; confirm green
- [ ] 6.4 Run `openspec validate delegated-cleanup`; resolve issues
- [ ] 6.5 Confirm every spec scenario maps to a task; update README (M3 usage, no-sudo, vetted-commands safety) and roadmap
