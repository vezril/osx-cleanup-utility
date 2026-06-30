## Why

macOS "System Data" routinely balloons into hundreds of GB (caches, APFS snapshots, dev junk, old iOS backups) with no first-party way to inspect or reclaim it, and every existing GUI cleaner is closed-source/premium. We are building a FOSS, macOS-native, safety-first cleanup utility. Before any cleanup feature exists, we need a trustworthy foundation: a buildable native app, a test-first harness, and CI/CD that proves every change compiles and passes tests. This change establishes that Milestone 0 foundation — no cleanup behavior yet, just a project that builds, tests, and ships.

## What Changes

- Establish a Swift Package Manager workspace with two targets: a thin SwiftUI macOS **app shell** (imperative shell) and a pure, dependency-free **functional-core library** (the future home of scanning/classification logic), following the Functional Core / Imperative Shell pattern.
- Add a single passing **smoke test** in the functional-core target to prove the TDD harness (`swift test`) is wired and runs in CI — the Red→Green seed for all future test-first work.
- Add **GitHub Actions CI** that builds the app and runs `swift test` on every pull request and on pushes to `development` and `main`; a failing build or test fails the check (red).
- Add **release automation**: tagging a semantic version (`vX.Y.Z`) on `main` builds and attaches an **unsigned** `.app`/`.zip` artifact to a GitHub Release. (Code signing & notarization are explicitly deferred to a later milestone.)
- Establish the **branching strategy**: `feature/*` → `development` (experimental builds) → `main` (released, semver-tagged), with conventional commits driving version bumps.
- Add a comprehensive root **README.md** documenting how to run the app and how to run the tests.
- Capture the sourced macOS bloat/SIP/Full-Disk-Access research and the 5-tier safety model as design reference, so future cleanup work is grounded and not hallucinated.

Non-goals (explicit): no file scanning, no visualization, no deletion, no code signing/notarization, no Mac App Store sandboxing. Those land in later milestones (M1 scan/visualize, M2 Mechanism-A deletion, M3 delegated cleanup).

## Capabilities

### New Capabilities
- `project-structure`: A Swift Package Manager workspace with a SwiftUI macOS app shell and a pure functional-core library that compiles cleanly and runs a passing smoke test via `swift test`.
- `ci-pipeline`: GitHub Actions that builds the project and runs the test suite on pull requests and on pushes to `development`/`main`, failing the check on any build or test failure.
- `release-pipeline`: Semantic-versioned, branch-based release automation that, on a `vX.Y.Z` tag on `main`, produces and publishes an unsigned `.app`/`.zip` build artifact to a GitHub Release.

### Modified Capabilities
<!-- None — this is the first change; no existing specs. -->

## Impact

- **New repository scaffolding**: `Package.swift`, `Sources/` (app shell + functional-core), `Tests/`, `.github/workflows/`, root `README.md`, `LICENSE`, `.gitignore`.
- **CI/CD**: GitHub Actions workflows on macOS runners (build + test on PR/push; release on tag). Consumes GitHub-hosted macOS runner minutes; no Apple Developer secrets required for M0 (unsigned).
- **Toolchain dependency**: Swift toolchain / Xcode on CI runners; `swift build` + `swift test` as the canonical local and CI entry points.
- **Conventions**: semantic versioning + conventional commits + the `feature/* → development → main` branch model become project rules going forward.
- **Design reference**: a `research.md` (sourced folder/SIP/FDA findings) and the 5-tier safety model recorded in `design.md` to anchor all subsequent milestones.
