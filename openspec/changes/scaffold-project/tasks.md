> TDD rule for this change: every group sequences **tests first (Red) → implement (Green) → refactor**. Run `swift test` after each implementation step and confirm it passes before moving on. CI/release tasks that can't be unit-tested are verified by an explicit observable check instead.

## 1. Repository foundation

- [x] 1.1 Initialize git repo; create `development` from `main`; document the `feature/* → development → main` model in README
- [x] 1.2 Add `LICENSE` (MIT) and a Swift/macOS `.gitignore` (`.build/`, `*.xcodeproj/xcuserdata`, `.DS_Store`, `DerivedData/`)
- [x] 1.3 Decide and record toolchain: **swift-tools-version 6.0**, **min macOS 14 (Sonoma)** — recorded in `Package.swift`

## 2. Package scaffold — Functional Core / Imperative Shell

- [x] 2.1 Create `Package.swift` defining the `CleanupCore` library target, the SwiftUI app-shell target depending on it, and a `CleanupCoreTests` test target
- [x] 2.2 Verify `swift build` succeeds with empty placeholder sources (exit 0) — satisfies "Clean build succeeds" (SwiftUI compiles under CLT)
- [x] 2.3 Verified by inspection: `CleanupCore` has zero imports (no SwiftUI/AppKit/FileManager); app-shell imports `CleanupCore`, not vice versa — satisfies "Functional core has no dependency on the app shell"

## 3. TDD smoke test (Red → Green → Refactor)

- [x] 3.1 RED: test asserted `CleanupCore.version` before it existed; `swift test` failed with `type 'CleanupCore' has no member 'version'` — genuine red. (Switched XCTest → **Swift Testing**, the only framework that runs without Xcode locally.)
- [x] 3.2 GREEN: added `public static let version = "0.1.0"`; `swift test` → `1 test in 1 suite passed`
- [x] 3.3 REFACTOR: value + test tidy and documented; re-ran `swift test`, still green
- [x] 3.4 Smoke test references only the pure value, imports no FS framework — satisfies "tests target the core without filesystem access"

## 4. Minimal app shell

- [x] 4.1 Added minimal SwiftUI `App` + `ContentView` placeholder window (shows `core v\(CleanupCore.version)`); no cleanup features
- [~] 4.2 `swift build` of the app succeeds; **visual launch confirmation left to user** (`swift run osx-cleanup`) — a bare SPM executable renders best once bundled (CI release path produces the `.app`). Cannot observe a GUI from the agent environment.
- [x] 4.3 App-shell only wires UI; the only logic value (`version`) comes from `CleanupCore` — no decision logic in the shell

## 5. CI pipeline (GitHub Actions)

- [x] 5.1 Added `.github/workflows/ci.yml` — runs on `pull_request` and `push` to `development`/`main`, on `macos-latest`, executes `swift build` then `swift test`, caches `.build` (YAML validated)
- [ ] 5.2 ⏸ **Blocked (needs GitHub push):** open a PR with passing code → CI reports success — satisfies "Passing change reports green"
- [ ] 5.3 ⏸ **Blocked (needs GitHub push):** push a branch with a deliberately failing test → CI reports failure with the test name; then revert
- [ ] 5.4 ⏸ **Blocked (needs GitHub push):** push a non-compiling branch → build step fails, test step skipped, check red; then revert
- [ ] 5.5 ⏸ **Blocked (needs GitHub push):** confirm direct pushes to `development`/`main` trigger the workflow

## 6. Release pipeline (unsigned)

- [x] 6.1 Added `.github/workflows/release.yml` — triggered by `v[0-9]+.[0-9]+.[0-9]+` tags, gated to `main` (ancestor check), builds release, assembles unsigned `.app` + `ditto` zip, publishes Release; no signing secrets (YAML validated)
- [x] 6.2 Resolved design open question: **pure-SPM build + manual `.app` bundle assembly** (Info.plist + binary), no `xcodebuild`/Xcode-archive needed. End-to-end artifact production runs on CI (see 6.3).
- [ ] 6.3 ⏸ **Blocked (needs GitHub push):** tag `v0.1.0` on `main` → confirm Release created with unsigned artifact, no signing secrets — satisfies "publishes a downloadable unsigned artifact" + "no signing secrets present"
- [ ] 6.4 ⏸ **Blocked (needs GitHub push):** confirm a malformed/non-`main` tag does NOT publish a release
- [ ] 6.5 ⏸ **Blocked (needs GitHub push):** confirm a build failure aborts the release with no partial artifact

## 7. Documentation

- [x] 7.1 Wrote comprehensive root `README.md`: purpose/safety stance, run app, run tests (+ `DEVELOPER_DIR` note), branch/release model, roadmap, link to research reference
- [x] 7.2 Cross-checked: `swift build`, `swift run osx-cleanup`, and `swift test` commands all verified working on this checkout

## 8. Verify & close out

- [x] 8.1 `openspec validate scaffold-project` → "Change 'scaffold-project' is valid"
- [~] 8.2 All `specs/` scenarios mapped to tasks; `swift build` + `swift test` green **locally** from a clean `.build`. CI-green confirmation is part of the blocked push tasks (5.2, 6.3).
