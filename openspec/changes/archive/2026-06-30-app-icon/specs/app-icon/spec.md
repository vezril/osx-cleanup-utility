## ADDED Requirements

### Requirement: A branded icon is generated from a single master and shown in the app bundle
The project SHALL maintain a single 1024×1024 master image as the canonical app icon and SHALL generate the macOS `.icns` from it deterministically (no prebuilt icon is committed). The assembled `.app` bundle SHALL contain the generated `AppIcon.icns` and reference it from its `Info.plist`, so Finder and the Dock display the icon. The released `.app` artifact SHALL include the icon.

#### Scenario: The assembled bundle carries the icon
- **WHEN** the `.app` bundle is assembled from the project
- **THEN** it contains `Contents/Resources/AppIcon.icns` and its `Info.plist` references that icon, so Finder and the Dock show the branded icon rather than a generic one

#### Scenario: The released artifact includes the icon
- **WHEN** the release workflow builds and publishes the `.app` for a version tag
- **THEN** the published bundle carries the generated icon

#### Scenario: Edge case — the icon set is generated at all required sizes
- **WHEN** the icon is generated from the master
- **THEN** the icon set includes every macOS-required size (16, 32, 128, 256, 512 px at @1x and @2x) derived from the single master

#### Scenario: Edge case — a missing or wrong-size master fails the build clearly
- **WHEN** the generation step runs without a valid 1024×1024 master present
- **THEN** it fails with a clear error and a non-zero exit, rather than producing a broken or empty icon
