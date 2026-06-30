> TDD rule for this change: every group sequences **tests first (Red) → implement (Green) → refactor**. Run `swift test` after each implementation step and confirm it passes before moving on. CI/release tasks that can't be unit-tested are verified by an explicit observable check instead.

## 1. Repository foundation

- [ ] 1.1 Initialize git repo; create `development` from `main`; document the `feature/* → development → main` model in README
- [ ] 1.2 Add `LICENSE` (FOSS, e.g. MIT) and a Swift/macOS `.gitignore` (`.build/`, `*.xcodeproj/xcuserdata`, `.DS_Store`, `DerivedData/`)
- [ ] 1.3 Decide and record the minimum macOS deployment target and Swift tool version (resolves a design Open Question)

## 2. Package scaffold — Functional Core / Imperative Shell

- [ ] 2.1 Create `Package.swift` defining the `CleanupCore` library target, the SwiftUI app-shell target depending on it, and a `CleanupCoreTests` test target
- [ ] 2.2 Verify `swift build` succeeds with empty placeholder sources (exit 0) — satisfies "Clean build succeeds"
- [ ] 2.3 Verify (test or manifest assertion) that `CleanupCore` imports no SwiftUI/filesystem framework and the app-shell depends on `CleanupCore`, not vice versa — satisfies "Functional core has no dependency on the app shell"

## 3. TDD smoke test (Red → Green → Refactor)

- [ ] 3.1 RED: write a failing test in `CleanupCoreTests` asserting a pure `CleanupCore` identity value (e.g. `CleanupCore.version`) that does not yet exist; run `swift test` and confirm it fails by name
- [ ] 3.2 GREEN: add the minimal `public` value to `CleanupCore` to make the test pass; run `swift test` and confirm green (exit 0)
- [ ] 3.3 REFACTOR: tidy naming/structure of the value and test; re-run `swift test` to confirm still green
- [ ] 3.4 Confirm the smoke test performs no filesystem I/O — satisfies "tests target the core without filesystem access"

## 4. Minimal app shell

- [ ] 4.1 Add a minimal SwiftUI `App` + single window/view that launches and displays a placeholder (no cleanup features)
- [ ] 4.2 Build and launch the app locally; confirm it opens a window without crashing
- [ ] 4.3 REFACTOR: ensure the app-shell only wires UI and holds no decision logic (logic belongs in `CleanupCore`)

## 5. CI pipeline (GitHub Actions)

- [ ] 5.1 Add `.github/workflows/ci.yml` running on `pull_request` and on `push` to `development`/`main`, on a macOS runner, executing `swift build` then `swift test` (cache SPM where possible)
- [ ] 5.2 Verify green path: open a PR with passing code → CI reports success — satisfies "Passing change reports green"
- [ ] 5.3 Verify red path: push a branch with a deliberately failing test → CI reports failure with the test name — satisfies "Failing test blocks the change"; then revert
- [ ] 5.4 Verify compile-error path: push a branch that doesn't compile → build step fails, test step skipped, check red — satisfies that edge case; then revert
- [ ] 5.5 Confirm direct pushes to `development`/`main` also trigger the workflow — satisfies "push to a protected branch is verified"

## 6. Release pipeline (unsigned)

- [ ] 6.1 Add `.github/workflows/release.yml` triggered by `v*.*.*` tags, gated to `main`, that builds and packages the app as an unsigned `.zip` and attaches it to a GitHub Release
- [ ] 6.2 Validate the packaging path produces a launchable `.app`/`.zip` via pure SPM; if unreliable, switch to an `xcodebuild` archive step (resolves a design Open Question)
- [ ] 6.3 Tag `v0.1.0` on `main` → confirm a GitHub Release is created with the unsigned artifact attached and no signing secrets required — satisfies "Release publishes a downloadable unsigned artifact" and "no signing secrets present"
- [ ] 6.4 Verify a malformed/non-`main` tag does NOT publish a release — satisfies "non-semver or non-main tag does not release"
- [ ] 6.5 Verify a build failure during release aborts with no partial artifact attached — satisfies "build failure aborts the release"

## 7. Documentation

- [ ] 7.1 Write the comprehensive root `README.md`: project purpose/safety stance, how to run the app (incl. unsigned right-click→Open Gatekeeper note), how to run tests (`swift test`), branch/release model, and a link to the research reference
- [ ] 7.2 Cross-check README commands against a fresh clone to ensure run/test instructions actually work

## 8. Verify & close out

- [ ] 8.1 Run `openspec validate scaffold-project` and resolve any issues
- [ ] 8.2 Confirm all capability scenarios in `specs/` are satisfied by a task above; confirm `swift build` + `swift test` are green on CI
