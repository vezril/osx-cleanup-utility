## Context

The app is a **pure Swift Package Manager** project — there is no Xcode project, no asset catalog, and no `.app` bundle except the one the release workflow hand-assembles (binary + inline `Info.plist`). So "add an app icon" is really two distinct jobs: produce a macOS `.icns` and reference it from the bundle (the Finder/Dock icon of the *distributed* app), and — because a bundled SPM executable run via `swift run` has no bundle at all — set the Dock icon at runtime from a bundled resource (the *development* Dock icon). A 1024×1024 master already exists; this change is asset + build-tooling, with little unit-testable logic.

## Goals / Non-Goals

**Goals:**
- One canonical 1024×1024 master drives the icon (no duplicated binaries).
- Deterministic, reproducible `.icns` generation from that master (`sips` + `iconutil`).
- The released `.app` shows the icon in Finder and the Dock.
- The release workflow and local dev share one bundle-assembly path (no drift).

**Non-Goals:**
- Signing/notarization (M5); dark-mode/alternate variants; in-app icon picker.
- Committing generated artifacts (`.iconset`/`.icns`) — they are build outputs.
- **Deferred:** a runtime Dock icon for raw `swift run` (see D5).

## Decisions

### D1: Single canonical master at `docs/app-icon/AppIcon.png`
The 1024×1024 PNG lives in its design folder, `docs/app-icon/`, as the single committed source of truth and build input; the `.icns` generator and bundle-assembly script read it by path. It is intentionally **not** inside a Swift target's source tree: with the runtime-resource icon descoped (D5), placing it under the app target would only trip SwiftPM's "unhandled resource" warning for no remaining consumer.
**Why:** one canonical asset co-located with its design spec/prompt; no duplication; no SPM resource declaration needed.
**Alternative:** place it under the app target as an SPM resource — rejected once the runtime icon was descoped.

### D2: Generate `.icns` from the master with `sips` + `iconutil`; don't commit it
`scripts/make-icns.sh` builds an `AppIcon.iconset` with the Apple-required sizes (16, 32, 128, 256, 512 at @1x and @2x) by downscaling the master with `sips`, then runs `iconutil -c icns`. The `.icns` is a build output, produced at package time, never committed.
**Why:** one master → all sizes deterministically; no stale binary in git; both tools ship with macOS so no new dependency.
**Alternative:** commit a prebuilt `.icns` — rejected; it can drift from the master and bloats history.

### D3: Wire the bundle icon via `Contents/Resources/AppIcon.icns` + `CFBundleIconFile`
The assembled `.app` gets `AppIcon.icns` in `Contents/Resources/`, and the `Info.plist` gains `<key>CFBundleIconFile</key><string>AppIcon</string>`. Finder and the Dock pick it up from the bundle.
**Why:** this is the standard, signing-independent way macOS resolves an app's icon; works for an unsigned hand-assembled bundle.

### D4: One reusable bundle-assembly script, called by CI and dev
Refactor the inline `.app` assembly currently embedded in `release.yml` into `scripts/make-app-bundle.sh <version>` (build release binary → generate `.icns` → assemble bundle with `Info.plist` incl. `CFBundleIconFile` → `ditto` zip). `release.yml` calls the script; developers can run it locally to produce an identical iconed `.app`.
**Why:** removes the duplicated inline plist/assembly, keeps CI and local output identical, and makes the bundle reproducible for the GUI verification still outstanding.
**Trade-off:** a workflow refactor; mitigated by keeping the script's behavior identical to today plus the icon.

### D5: Runtime Dock icon for `swift run` — DEFERRED
*Originally planned* (`resources: [.process("Resources")]` + set `applicationIconImage` from `Bundle.module` at launch), but **descoped during implementation.** Three problems make it disproportionate plumbing for a dev-only nicety: (1) SwiftPM's `Bundle.module` traps (`fatalError`) when its resource bundle is absent, which would *crash* rather than degrade — directly at odds with the no-crash intent; (2) the hand-assembled `.app` copies only the binary, so the SPM resource bundle would have to be copied in too for it to resolve there; (3) SwiftPM cannot unit-test an executable target's resources, so a real test would require re-layering the resource + accessor into a library target.
**Resolution:** the distributed `.app` already gets its icon from the `.icns` + `CFBundleIconFile` (D3), which is what users actually see. The raw-`swift run` Dock icon stays generic and is left as a future enhancement (a nil-safe accessor in a library target + copying the resource bundle into the `.app`).

## Risks / Trade-offs

- **Little to unit-test** → verification is concrete instead: the generator must emit every required iconset size (a scripted self-check fails loudly if a size is missing), the assembled bundle must contain `AppIcon.icns` and the `Info.plist` key, and a human confirms the icon renders in Finder/Dock.
- **Master not exactly 1024×1024 / missing** → `make-icns.sh` validates the input dimensions and exits non-zero with a clear message, so a bad master fails the build rather than shipping a broken icon.
- **Finder icon caching** → macOS caches icons aggressively; the README notes that a stale Finder icon after a rebuild is a cache artifact (`touch` the app / restart Dock), not a packaging bug.
- **`Bundle.module` availability** → adding resources makes SPM synthesize `Bundle.module` for the target; confirm the app still builds and that the resource URL resolves both in `swift run` and inside the assembled bundle.

## Migration Plan

Purely additive — no behavior changes, no data. Move the master into the app target, add the scripts, declare the resource, set the runtime icon, and update `release.yml` to call the bundle script. Land on `development`; verify the icon locally and on the next tagged release. Rollback = revert; the app simply returns to a generic icon.

## Open Questions

- Whether to also set a higher-resolution `AppIcon.png` master (2048²) for crisper large rendering — the 1024 master meets Apple's requirement, so defer unless it looks soft at 1024.
- Whether `make-app-bundle.sh` should `codesign --sign -` (ad-hoc) the bundle now — out of scope here (M5 distribution), but the script is the natural place to add it later.
