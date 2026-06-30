## Why

The app currently ships with a generic executable icon — in Finder and the Dock it looks unfinished and anonymous, which matters for a tool people download and then trust with Full Disk Access. A 1024×1024 master icon has been designed (an external drive with a broom sweeping files and folders away, on a blue→teal squircle) and dropped at `docs/app-icon/icon-1024.png`. This change turns that master into a real macOS app icon: generated `.icns`, wired into the app bundle so Finder/Dock show it, included in the released `.app`, and shown in the Dock during local development too.

## What Changes

- Adopt a **single canonical master** for the icon at `Sources/OSXCleanupApp/Resources/AppIcon.png` (moved from `docs/app-icon/icon-1024.png`), so one image drives both the bundle icon and the runtime icon with no duplication.
- Add a **generation script** (`scripts/make-icns.sh`) that derives a full `AppIcon.iconset` (16→1024 px at @1x/@2x) and `AppIcon.icns` from the master using `sips` + `iconutil`. Generated artifacts are not committed — they are produced at package time.
- Wire the icon into the **assembled `.app`**: place `AppIcon.icns` in `Contents/Resources/` and add `CFBundleIconFile` to the bundle's `Info.plist` so Finder and the Dock display it.
- Update the **release workflow** so released `.app` bundles carry the icon (refactor the inline bundle assembly into a reusable `scripts/make-app-bundle.sh` that both CI and local dev call, to avoid drift).
- **Show the icon in the Dock during `swift run`** too: bundle the master as an SPM resource (`resources: [.process("Resources")]`) and set `NSApplication.shared.applicationIconImage` at launch (a bundled SPM executable has no `.app`, so without this the dev Dock icon stays generic).
- Update `docs/app-icon/README.md` to the **final concept** (external drive + broom sweeping files/folders) and point it at the canonical master path.

Non-goals (explicit): no code signing/notarization (M5); no dark-mode / alternate icon variants; no in-app icon chooser; no change to any app behavior beyond the displayed icon.

## Capabilities

### New Capabilities
- `app-icon`: the application has a branded icon generated from a single 1024×1024 master — shown in Finder and the Dock (both the released `.app` and local `swift run`) and included in the release artifact.

### Modified Capabilities
<!-- None. The release workflow change is an implementation detail of delivering this capability; the release-pipeline requirements (build + publish an unsigned artifact) are unchanged in intent — the artifact simply now carries an icon. -->

## Impact

- **New committed asset**: `Sources/OSXCleanupApp/Resources/AppIcon.png` (the 1024 master). `docs/app-icon/icon-1024.png` is moved here; `docs/app-icon/README.md` keeps the design spec + prompt and references it.
- **New scripts**: `scripts/make-icns.sh` (master → `.icns`) and `scripts/make-app-bundle.sh` (binary + icns + Info.plist → `.app` + zip), the latter reused by `release.yml`.
- **Package.swift**: the app target declares `resources: [.process("Resources")]`.
- **App-shell**: a few lines at launch to set the Dock icon from the bundled resource.
- **CI**: `release.yml` calls the bundle script so the published `.app` includes the icon; no new secrets, still unsigned.
- **Dependencies**: none new — `sips` and `iconutil` ship with macOS.
