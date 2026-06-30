# snapshot-management Specification

## Purpose
TBD - created by archiving change delegated-cleanup. Update Purpose after archive.
## Requirements
### Requirement: List APFS local snapshots via tmutil
The app SHALL list APFS local snapshots by invoking `tmutil`, parsing each snapshot's identifier/date from its output. Parsing SHALL be defensive: unexpected or unparseable output SHALL yield no snapshots rather than malformed entries, and SHALL never crash.

#### Scenario: Existing snapshots are listed with their dates
- **WHEN** `tmutil` reports one or more local snapshots
- **THEN** the app lists each snapshot with its parsed date identifier

#### Scenario: Edge case — no snapshots yields an empty list
- **WHEN** `tmutil` reports no local snapshots
- **THEN** the app shows an empty snapshot list without error

#### Scenario: Edge case — unparseable tmutil output fails safe
- **WHEN** `tmutil` output does not match the expected format
- **THEN** the app yields no snapshots (offering nothing) rather than producing malformed entries or crashing

### Requirement: Reclaim snapshots via tmutil only, with validated arguments
The app SHALL reclaim local snapshots only through `tmutil` — deleting a specific snapshot by its date, or thinning to free a target amount — and SHALL never touch snapshot storage directly. Any snapshot date parsed from `tmutil` output SHALL be validated against the expected format before being passed back as an argument.

#### Scenario: A specific snapshot is deleted by date
- **WHEN** the user chooses to delete a listed snapshot
- **THEN** the app invokes `tmutil` to delete that snapshot by its validated date identifier

#### Scenario: Edge case — an invalid snapshot date is rejected
- **WHEN** a snapshot date does not match the expected format
- **THEN** the app refuses to use it as a `tmutil` argument, so malformed or injected values are never passed through

#### Scenario: Edge case — thinning targets a byte amount
- **WHEN** the user requests reclaiming a target amount of space from snapshots
- **THEN** the app invokes `tmutil` thinning with that target, leaving snapshot management to the OS tool

