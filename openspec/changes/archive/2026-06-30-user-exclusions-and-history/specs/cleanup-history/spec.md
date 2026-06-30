## ADDED Requirements

### Requirement: Completed cleanups are recorded as timestamped history entries
After a deletion or delegated cleanup completes, the app SHALL append one history entry capturing its timestamp, kind (file deletion vs delegated), item count, estimated bytes reclaimed, and outcome counts. History SHALL be persisted across launches and presented newest-first.

#### Scenario: A completed cleanup is recorded
- **WHEN** a cleanup completes
- **THEN** a history entry is appended with its timestamp, kind, item count, reclaimed estimate, and outcome counts

#### Scenario: History is shown newest-first and persists
- **WHEN** the history is displayed after a relaunch
- **THEN** previously recorded entries are present and ordered with the most recent first

#### Scenario: Edge case — history is capped to bound growth
- **WHEN** the number of entries exceeds the retention cap
- **THEN** the oldest entries are dropped so the stored history stays within the cap

#### Scenario: Edge case — a corrupt or missing store loads empty history
- **WHEN** the persisted state is missing or cannot be decoded
- **THEN** the history loads as empty and the app does not crash
