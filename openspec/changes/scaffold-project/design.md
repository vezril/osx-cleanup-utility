## Context

This is the foundational change (Milestone 0) for a FOSS, macOS-only, safety-first disk-cleanup utility. macOS "System Data" regularly grows to 200+ GB and is hard to reclaim by design (APFS purgeable space, local snapshots, the cryptographically sealed read-only system volume). All existing GUI cleaners are closed-source/premium. See [research.md](research.md) for the full sourced breakdown of bloat locations, the 5-tier safety model, and the SIP / Full Disk Access constraints that shape the product.

M0 builds **no cleanup behavior**. It establishes the architecture, the test-first harness, and CI/CD so that every later milestone (M1 scan/visualize → M2 Mechanism-A deletion → M3 delegated cleanup) lands on a trustworthy, automatically-verified base. The hard requirement that **important system files must never be touched** is an architectural concern from day one, so the structure is chosen to make that guarantee testable in isolation.

Constraints carried from the project brief:
- macOS-only, native GUI required.
- TDD is non-negotiable: Red→Green→Refactor, tests written first, run after every implementation step.
- Functional programming favored over imperative; type annotations encouraged; clean code required.
- v1 ships **unsigned** (no Apple Developer account yet); notarization deferred.

## Goals / Non-Goals

**Goals:**
- A Swift Package Manager workspace that compiles cleanly with `swift build`.
- A two-target split — thin SwiftUI **app shell** + pure **functional-core library** — that makes the core unit-testable without touching the real filesystem.
- A passing **smoke test** proving `swift test` runs locally and in CI (the Red→Green seed).
- GitHub Actions CI that builds + tests on every PR and on pushes to `development`/`main`, going red on any failure.
- Release automation that, on a `vX.Y.Z` tag on `main`, publishes an unsigned `.app`/`.zip` to a GitHub Release.
- A documented branch model and a comprehensive root README.

**Non-Goals:**
- Any scanning, sizing, visualization, or deletion logic (M1+).
- Code signing, notarization, Mac App Store distribution / sandboxing.
- Full Disk Access onboarding flow (lands in M1 when scanning begins).
- Delegated cleanup integrations (tmutil/docker/brew/npm/pip/cargo) — M3.

## Decisions

### D1: Swift + SwiftUI, native, macOS-only
**Chosen** over Rust+Tauri, Go+Wails, Python+Qt, Electron+TS.
**Why:** A disk cleaner needs the smoothest possible access to macOS-specific plumbing it will rely on in later milestones — Full Disk Access, security-scoped bookmarks, `tmutil`, `NSWorkspace`, notarization. Apple's APIs for all of these are most direct from Swift, and SwiftUI gives a native, trustworthy GUI. Swift is also FP-friendly (value types, enums with associated values, `map`/`filter`/`reduce`, immutability) which satisfies the FP preference, and has a first-class type system and a built-in test runner.
**Alternatives considered:** Rust+Tauri (strong types/FP, future cross-platform, but macOS specifics need shelling out / `objc` bridging); Electron (easy but heavy/non-native, weak trust story for a tool asking for Full Disk Access); Python+Qt (great TDD, hostile macOS packaging/notarization).

### D2: Functional Core / Imperative Shell, as two SPM targets
The package is split into a pure **functional-core** library target (no I/O, deterministic, total functions over plain value types) and a thin **app-shell** executable/app target (SwiftUI views + the few side-effecting calls: `FileManager`, later `tmutil`/`NSWorkspace`).
**Why:** (1) TDD becomes cheap — the decision logic (future: size rollup, safety classification, deletion planning) is pure functions over fake records, so tests never risk real files; (2) FP falls out naturally; (3) the "never touch system files" guarantee can live in one pure, exhaustively-tested function rather than scattered through UI callbacks. M0 establishes the seam now so M1 logic drops into the core target with the test harness already proven.
**Alternative considered:** single app target with logic inline — rejected because it makes the core logic untestable without UI/filesystem and undermines the safety-auditability goal.

### D3: Smoke test as the TDD seed
M0 has no real behavior, but it ships one trivial passing test in the functional-core target (e.g. asserting a `version`/identity value). 
**Why:** It proves the entire Red→Green→Refactor loop and the CI test step work end-to-end before any feature exists, so M1's first real failing test has a known-good harness. Written test-first per the TDD rule (write failing assertion → add the value → green).
**Alternative considered:** no test until M1 — rejected; it would leave the CI test step unverified and violate the test-first mandate.

### D4: Branch & release model — `feature/* → development → main`, semver, conventional commits
`feature/*` branches PR into `development` (experimental CI builds); `development` PRs into `main` (the released line). Release versions are semantic (`vX.Y.Z`) and tags on `main` trigger the release workflow. Conventional commit prefixes (`feat:`, `fix:`, `feat!:`/`BREAKING CHANGE:`) communicate intended version bumps.
**Why:** Matches the brief's `main`/`development` request while adding the standard FOSS feature-branch front and a clear, automatable release trigger. Lightweight enough for a solo maintainer.
**Alternative considered:** trunk-based single-branch — rejected for not matching the brief's stated main/development separation.

### D5: Unsigned releases for M0 (notarize later)
The release workflow produces an unsigned `.app`/`.zip` (users right-click → Open on first launch). No Apple Developer secrets in CI yet.
**Why:** Unblocks shippable CI/CD without the $99/yr Apple Developer Program or signing-secret management. Signing/notarization is additive later (a workflow change + secrets), not a rework.
**Trade-off:** Gatekeeper friction for end users until notarization is added — documented in the README.

### D6: CI on GitHub-hosted macOS runners
Build + test workflow runs on `macos-latest`; canonical commands are `swift build` and `swift test`.
**Why:** Swift/SwiftUI requires macOS; GitHub provides hosted macOS runners. Keeps local and CI entry points identical.
**Trade-off:** macOS runner minutes cost more than Linux; acceptable for a small project, and PR-triggered runs keep volume low.

## Risks / Trade-offs

- **macOS runner minutes / queue times** → Mitigate by keeping M0 builds minimal, caching SPM dependencies, and only running release jobs on tags.
- **SwiftUI app target may be awkward to build/package head-less via pure SPM** (vs. an Xcode project) → Mitigate by validating the `swift build`/packaging path during M0; if pure-SPM app packaging proves brittle, fall back to an `xcodebuild`-based archive step in CI (decision recorded, revisit in implementation).
- **Unsigned artifact triggers Gatekeeper warnings** → Mitigate with clear README instructions; accept until the notarization milestone.
- **"Empty" milestone risks under-specifying the safety seam** → Mitigate by establishing the functional-core target and FCIS boundary now, even with no logic, so the safety classifier has a tested home in M1.
- **Conventional-commit → semver automation can mis-bump versions** → For M0, version bumps/tagging are manual and intentional; full automated bumping is deferred (Open Question).

## Migration Plan

Greenfield — no existing system to migrate. Rollout = land the scaffolding on `development`, verify CI green, open the first PR to `main`, cut `v0.1.0` to validate the release workflow produces an unsigned artifact. Rollback = revert the scaffolding PR; nothing depends on it yet.

## Open Questions

- Pure SPM app packaging vs. an Xcode project + `xcodebuild` for the release artifact — resolve during implementation based on which reliably produces a launchable `.app`.
- Whether to automate semver bumping from conventional commits in M0 or keep tagging manual until releases stabilize (leaning manual for M0).
- Minimum supported macOS deployment target (affects available APFS/`tmutil` APIs later) — pick a concrete floor before M1.
