## ADDED Requirements

### Requirement: Curated safe presets select only known-safe categories
The app SHALL offer curated one-click presets (e.g. empty Trash, Xcode `DerivedData`, user caches) that select known-safe categories backed by the classifier. A preset SHALL only include paths classified `SAFE` or `CACHE`; it SHALL never include `RISKY`, `DELEGATED`, or `NEVER` paths. Paths in a preset that are absent on the current machine SHALL be skipped.

#### Scenario: Selecting a preset selects its known-safe paths
- **WHEN** the user activates a curated preset
- **THEN** the present, matching paths for that category are added to the selection, ready to be planned

#### Scenario: Edge case — a preset never includes risky or protected paths
- **WHEN** a preset is evaluated
- **THEN** every path it contributes is classified `SAFE` or `CACHE`, and no `RISKY`, `DELEGATED`, or `NEVER` path is included

#### Scenario: Edge case — absent preset paths are skipped
- **WHEN** a preset references a location that does not exist on this machine
- **THEN** that location is skipped without error and the rest of the preset still applies

### Requirement: Manual multi-selection of files and folders
The app SHALL allow the user to manually select multiple individual files and folders for deletion, in addition to or instead of presets. A mixed selection SHALL be planned as a whole, with the required confirmation driven by the highest tier present.

#### Scenario: Multiple items can be selected and planned together
- **WHEN** the user selects several files and folders manually
- **THEN** all selected items are included in a single deletion plan

#### Scenario: Edge case — a mixed-tier selection uses the highest tier for confirmation
- **WHEN** a manual selection mixes `SAFE` and `RISKY` items
- **THEN** the plan's required confirmation reflects the `RISKY` item (type-to-confirm)
