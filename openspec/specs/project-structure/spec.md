# project-structure Specification

## Purpose
Defines the buildable foundation of the cleanup utility: a Swift Package Manager workspace organized as a Functional Core / Imperative Shell — a pure, dependency-free `CleanupCore` library that holds all decision logic and a thin SwiftUI app shell that depends on it — together with a test-first harness whose passing smoke test proves the Red→Green→Refactor loop runs locally and in CI before any feature exists.

## Requirements

### Requirement: Buildable Swift package workspace
The project SHALL be a Swift Package Manager workspace that compiles cleanly with `swift build` and has no source-code dependencies required to build the core. The workspace MUST define two targets following Functional Core / Imperative Shell: a pure `CleanupCore` library target containing no I/O, and a SwiftUI macOS app-shell target that depends on `CleanupCore`.

#### Scenario: Clean build succeeds
- **WHEN** a developer runs `swift build` on a fresh checkout with a supported Swift toolchain
- **THEN** the build completes with exit code 0 and produces both the `CleanupCore` library and the app-shell products with no errors or warnings-as-errors

#### Scenario: Functional core has no dependency on the app shell
- **WHEN** the package manifest and target dependency graph are inspected
- **THEN** `CleanupCore` declares no dependency on the app-shell target and imports no UI/SwiftUI or filesystem-I/O frameworks, so it can be built and tested in isolation

#### Scenario: Edge case — missing or unsupported toolchain
- **WHEN** `swift build` is run with no Swift toolchain available or one below the project's declared minimum
- **THEN** the build fails fast with a clear toolchain/version error and a non-zero exit code (no partial or misleading artifacts are produced)

#### Scenario: Edge case — app-shell references a symbol not exported by the core
- **WHEN** the app-shell target references a type or function that is not `public` in `CleanupCore`
- **THEN** `swift build` fails with a visibility/linker error, proving the target boundary is enforced rather than silently bypassed

### Requirement: Passing smoke test proves the TDD harness
The project SHALL include at least one test in the `CleanupCore` test target that passes via `swift test`, establishing that the Red→Green→Refactor harness runs locally and in CI before any feature exists.

#### Scenario: Test suite runs green
- **WHEN** a developer runs `swift test` on a fresh checkout
- **THEN** the test runner discovers and executes the smoke test, all tests pass, and the command exits 0

#### Scenario: Edge case — a deliberately failing assertion reports red
- **WHEN** an assertion in the smoke test is temporarily inverted to fail
- **THEN** `swift test` reports the failing test by name and exits non-zero, confirming failures are actually surfaced (the Red half of Red→Green)

#### Scenario: Edge case — tests target the core without filesystem access
- **WHEN** the smoke test executes
- **THEN** it exercises only pure `CleanupCore` code and performs no real filesystem reads, writes, or deletions, so the suite is safe to run anywhere
