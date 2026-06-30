> This change is asset + build-tooling, so it has little unit-testable behavior. The TDD rule still applies where there *is* behavior (the runtime icon-load guard); the icon generation and bundle wiring are verified by explicit scripted checks and a visual confirmation instead of RED/GREEN unit tests. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` is required for `swift build`/`swift test` locally.

## 1. Adopt the canonical master

- [x] 1.1 Move `docs/app-icon/icon-1024.png` → `docs/app-icon/AppIcon.png` (the single committed master); update `docs/app-icon/README.md` to the final concept (external drive + broom sweeping files/folders) and point it at the new path
- [x] 1.2 Verify the master is exactly 1024×1024 PNG (`sips -g pixelWidth -g pixelHeight`)

## 2. Icon generation script

- [x] 2.1 Add `scripts/make-icns.sh <master.png> <out.icns>`: validate the input is 1024×1024 (else exit non-zero with a clear message), build an `AppIcon.iconset` with sizes 16/32/128/256/512 @1x and @2x via `sips`, then `iconutil -c icns`
- [x] 2.2 Run it on the master and confirm a valid `AppIcon.icns` is produced AND the iconset contains all 10 required size files (scripted check) — satisfies "generated at all required sizes"
- [x] 2.3 Confirm the script exits non-zero with a clear error when given a missing/non-1024 input — satisfies "missing or wrong-size master fails clearly"

## 3. Reusable bundle assembly

- [x] 3.1 Add `scripts/make-app-bundle.sh <version>`: build the release binary, generate `AppIcon.icns` (via `make-icns.sh`), assemble `osx-cleanup-utility.app` (binary in `Contents/MacOS`, `AppIcon.icns` in `Contents/Resources`, `Info.plist` with the existing keys **plus** `CFBundleIconFile = AppIcon`), and `ditto`-zip it — behaviour identical to today's inline assembly plus the icon
- [x] 3.2 Run it locally; confirm the produced `.app` contains `Contents/Resources/AppIcon.icns` and the `Info.plist` `CFBundleIconFile` key — satisfies "assembled bundle carries the icon"
- [~] 3.3 Open the assembled `.app` in Finder and confirm the branded icon renders (GUI step; record result; note Finder icon caching if stale)

## 4. Runtime Dock icon — DEFERRED

Descoped during implementation (see design D5): `Bundle.module` traps when its
resource bundle is absent, the hand-assembled `.app` would need the bundle copied
in, and an executable target's resources aren't unit-testable. The distributed
`.app` gets its icon from the `.icns` (Group 3), which is what users see; the raw
`swift run` Dock icon is left as a future enhancement.

## 5. Release pipeline

- [x] 5.1 Update `.github/workflows/release.yml` to call `scripts/make-app-bundle.sh "${VERSION}"` instead of the inline assembly (same output + icon); keep the unsigned, no-secrets behaviour
- [x] 5.2 Validate the workflow YAML; confirm the assemble step still produces the `${ZIP}` artifact name the publish step expects

## 6. Verify & close out

- [x] 6.1 Run full `swift build` + `swift test` from a clean `.build`; confirm green
- [x] 6.2 Run `openspec validate app-icon`; resolve issues
- [x] 6.3 Confirm every spec scenario maps to a task; update README if the icon is worth a mention; (optional) cut a tag to confirm the released `.app` carries the icon end-to-end
