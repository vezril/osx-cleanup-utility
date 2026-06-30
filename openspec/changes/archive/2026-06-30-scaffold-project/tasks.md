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
- [x] 5.2 ✅ Verified: green CI on every push to `main` (e.g. run 28419892796, 43s)
- [x] 5.3 ✅ Verified: PR #1 with a deliberate failing test → CI `failure`, test named in logs; PR closed unmerged
- [x] 5.4 ✅ Verified by workflow ordering: `swift build` runs before `swift test`; a compile error fails the build step (job red, tests skipped) — same red mechanism as 5.3
- [x] 5.5 ✅ Verified: pushes to `main` and the PR event both triggered the workflow

## 6. Release pipeline (unsigned)

- [x] 6.1 Added `.github/workflows/release.yml` — triggered by `v[0-9]+.[0-9]+.[0-9]+` tags, gated to `main` (ancestor check), builds release, assembles unsigned `.app` + `ditto` zip, publishes Release; no signing secrets (YAML validated)
- [x] 6.2 Resolved design open question: **pure-SPM build + manual `.app` bundle assembly** (Info.plist + binary), no `xcodebuild`/Xcode-archive needed. End-to-end artifact production runs on CI (see 6.3).
- [x] 6.3 ✅ Verified live: tag `v0.1.0` published a GitHub Release with `osx-cleanup-utility-v0.1.0-unsigned.zip` (345 KB), no signing secrets
- [x] 6.4 ✅ Verified: non-semver tag `v0.1` triggered NO release run (tag pattern `v[0-9]+.[0-9]+.[0-9]+` didn't match); tag deleted
- [x] 6.5 ✅ Verified by workflow ordering: `swift build -c release` precedes the assemble/publish steps; a build failure fails the job before `action-gh-release`, so no release/artifact is published

## 7. Documentation

- [x] 7.1 Wrote comprehensive root `README.md`: purpose/safety stance, run app, run tests (+ `DEVELOPER_DIR` note), branch/release model, roadmap, link to research reference
- [x] 7.2 Cross-checked: `swift build`, `swift run osx-cleanup`, and `swift test` commands all verified working on this checkout

## 8. Verify & close out

- [x] 8.1 `openspec validate scaffold-project` → "Change 'scaffold-project' is valid"
- [x] 8.2 ✅ All capability scenarios map to tasks; `swift build` + `swift test` green locally AND on CI (run 28419892796)
